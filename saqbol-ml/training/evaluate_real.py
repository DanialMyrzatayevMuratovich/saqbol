"""Reproduce the baseline table in docs/09-verification-plan.md §9.3.

Binary task on data/train.csv: scam vs the rest.

    A   5-fold cross-validation grouped by template family, all rows, model only, threshold 0.5
    B   the same predictions as A, scored on the non-template rows only
    C1  train on synthetic rows (templates and translations), test on all non-template rows,
        model only, threshold 0.5
    C2  as C1 at the deployed threshold, model only
    C3  as C1, deployed pipeline: max(model, rules) at the deployed threshold

"Non-template" rows are the ones docs/09 calls real: every source that does not start with
`synthetic` (the 44 seed messages and 184 Yerassyl04/Spam-kazakh sentences). They are human-written,
but none of them is a confirmed received SMS. For C1-C3 the training set leaves out every row in the
same template family as a test row, so English translations of the test messages are never trained on.

Run from saqbol-ml/:

    python training/evaluate_real.py
"""

import csv
import os
import sys

import numpy as np
from sklearn.metrics import confusion_matrix, precision_recall_fscore_support, roc_auc_score
from sklearn.model_selection import GroupKFold, cross_val_predict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.dirname(HERE))

from app.classifier import rules  # noqa: E402
from train_baseline import build_pipeline, template_families  # noqa: E402

DATA_PATH = os.getenv("TRAIN_CSV", "data/train.csv")
DEPLOYED_THRESHOLD = float(os.getenv("SCAM_THRESHOLD", "0.8"))
FOLDS = 5
BOOTSTRAP = 2000
SEED = 42


def load(path: str):
    with open(path, encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    texts = [row["text"] for row in rows]
    labels = np.array([1 if row["label"] == "scam" else 0 for row in rows])
    non_template = np.array([not row["source"].startswith("synthetic") for row in rows])
    groups = np.array(template_families(texts, [row.get("translated_from") or "" for row in rows]))
    return texts, labels, non_template, groups


def recall_interval(labels: np.ndarray, predicted: np.ndarray) -> tuple[float, float]:
    """95% bootstrap interval of the scam recall, resampling the scams."""
    hits = predicted[labels == 1]
    rng = np.random.default_rng(SEED)
    samples = [rng.choice(hits, size=len(hits), replace=True).mean() for _ in range(BOOTSTRAP)]
    return float(np.percentile(samples, 2.5)), float(np.percentile(samples, 97.5))


def score(labels: np.ndarray, probabilities: np.ndarray, threshold: float) -> dict:
    predicted = (probabilities >= threshold).astype(int)
    precision, recall, f1, _ = precision_recall_fscore_support(
        labels, predicted, average=None, labels=[0, 1], zero_division=0
    )
    tn, fp, _, _ = confusion_matrix(labels, predicted, labels=[0, 1]).ravel()
    return {
        "n": len(labels),
        "precision": precision[1],
        "recall": recall[1],
        "interval": recall_interval(labels, predicted),
        "f1": f1[1],
        "fpr": fp / (fp + tn) if fp + tn else 0.0,
        "roc_auc": roc_auc_score(labels, probabilities),
    }


def rule_probability(text: str) -> float:
    _, triggers, _ = rules.match(text)
    return rules.score(len(triggers))


def main() -> None:
    texts, labels, non_template, groups = load(DATA_PATH)

    # A and B: grouped cross-validation over everything.
    cv_probabilities = cross_val_predict(
        build_pipeline(), texts, labels, cv=GroupKFold(n_splits=FOLDS), groups=groups, method="predict_proba"
    )[:, 1]
    results = {
        "A": score(labels, cv_probabilities, 0.5),
        "B": score(labels[non_template], cv_probabilities[non_template], 0.5),
    }

    # C: train on synthetic rows that share no family with any test row.
    test_index = np.flatnonzero(non_template)
    test_families = set(groups[test_index])
    train_index = np.array([i for i in np.flatnonzero(~non_template) if groups[i] not in test_families])
    model = build_pipeline().fit([texts[i] for i in train_index], labels[train_index])
    test_texts = [texts[i] for i in test_index]
    model_probabilities = model.predict_proba(test_texts)[:, 1]
    deployed_probabilities = np.maximum(model_probabilities, [rule_probability(t) for t in test_texts])
    test_labels = labels[test_index]
    results["C1"] = score(test_labels, model_probabilities, 0.5)
    results["C2"] = score(test_labels, model_probabilities, DEPLOYED_THRESHOLD)
    results["C3"] = score(test_labels, deployed_probabilities, DEPLOYED_THRESHOLD)

    excluded = int((~non_template).sum()) - len(train_index)
    print(f"Data: {len(texts)} rows, {len(set(groups))} template families, {int(non_template.sum())} non-template rows "
          f"({int(labels[non_template].sum())} scams).")
    print(f"C1-C3 train on {len(train_index)} synthetic rows; {excluded} rows in the test rows' families are left out.\n")
    print("| Protocol | n | Precision | Recall (scam) | F1 | FPR | ROC-AUC |")
    print("|---|---|---|---|---|---|---|")
    for name, r in results.items():
        low, high = r["interval"]
        print(f"| {name} | {r['n']:,} | {r['precision']:.3f} | {r['recall']:.3f} ({low:.2f}–{high:.2f}) | "
              f"{r['f1']:.3f} | {r['fpr']:.3f} | {r['roc_auc']:.3f} |")


if __name__ == "__main__":
    main()
