import csv
import json
import os
from datetime import datetime, timezone

import numpy as np
from sklearn.calibration import CalibratedClassifierCV
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    confusion_matrix,
    precision_recall_fscore_support,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, cross_val_predict
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.svm import LinearSVC

DATA_PATH = os.getenv("SEED_DATA", "data/seed.csv")
OUTPUT_DIR = os.getenv("EXPERIMENTS_DIR", "experiments")
FOLDS = 5


def load_dataset(path):
    texts, labels = [], []
    with open(path, encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            texts.append(row["text"])
            labels.append(1 if row["label"] == "scam" else 0)
    return texts, np.array(labels)


def vectorizer():
    return TfidfVectorizer(ngram_range=(1, 2), min_df=1, sublinear_tf=True)


def candidates():
    return {
        "TF-IDF + LogReg": LogisticRegression(max_iter=1000, class_weight="balanced"),
        "TF-IDF + LinearSVM": CalibratedClassifierCV(LinearSVC(class_weight="balanced"), cv=3),
        "TF-IDF + NaiveBayes": MultinomialNB(),
    }


def evaluate(texts, labels):
    splitter = StratifiedKFold(n_splits=FOLDS, shuffle=True, random_state=42)
    results = {}

    for name, estimator in candidates().items():
        pipeline = Pipeline([("tfidf", vectorizer()), ("clf", estimator)])
        predictions = cross_val_predict(pipeline, texts, labels, cv=splitter)
        probabilities = cross_val_predict(
            pipeline, texts, labels, cv=splitter, method="predict_proba"
        )[:, 1]

        precision, recall, f1, _ = precision_recall_fscore_support(
            labels, predictions, average=None, labels=[0, 1], zero_division=0
        )
        matrix = confusion_matrix(labels, predictions, labels=[0, 1])

        results[name] = {
            "scam_precision": round(float(precision[1]), 4),
            "scam_recall": round(float(recall[1]), 4),
            "scam_f1": round(float(f1[1]), 4),
            "roc_auc": round(float(roc_auc_score(labels, probabilities)), 4),
            "confusion_matrix": matrix.tolist(),
        }

    return results


def render_report(results, sample_count):
    lines = [
        "# SaqBol — эксперименты по детекции скама (baseline)",
        "",
        f"Датасет (seed): {sample_count} сообщений KZ/RU, {FOLDS}-fold стратифицированная кросс-валидация.",
        "Акцент на recall по классу «скам» (пропуск мошенничества критичнее ложной тревоги, NFR-2).",
        "",
        "## Сравнение моделей",
        "",
        "| Модель | Precision (scam) | Recall (scam) | F1 (scam) | ROC-AUC |",
        "|---|---|---|---|---|",
    ]
    for name, metrics in results.items():
        lines.append(
            f"| {name} | {metrics['scam_precision']:.3f} | {metrics['scam_recall']:.3f} "
            f"| {metrics['scam_f1']:.3f} | {metrics['roc_auc']:.3f} |"
        )

    best = max(results, key=lambda key: results[key]["scam_recall"])
    matrix = results[best]["confusion_matrix"]
    lines += [
        "",
        f"## Confusion matrix — {best}",
        "",
        "| | предсказано safe | предсказано scam |",
        "|---|---|---|",
        f"| **факт safe** | {matrix[0][0]} | {matrix[0][1]} |",
        f"| **факт scam** | {matrix[1][0]} | {matrix[1][1]} |",
        "",
        "> Baseline. Сравнение с fine-tuned XLM-RoBERTa проводится после сбора полного корпуса "
        "(training/train_transformer.py).",
        "",
    ]
    return "\n".join(lines)


def main():
    texts, labels = load_dataset(DATA_PATH)
    results = evaluate(texts, labels)

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "samples": len(texts),
        "folds": FOLDS,
        "models": results,
    }
    with open(os.path.join(OUTPUT_DIR, "metrics.json"), "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)

    report = render_report(results, len(texts))
    with open(os.path.join(OUTPUT_DIR, "results.md"), "w", encoding="utf-8") as handle:
        handle.write(report)

    print(report)


if __name__ == "__main__":
    main()
