import csv
import json
import os
import re
from datetime import datetime, timezone

import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report
from sklearn.model_selection import GroupKFold, cross_val_predict
from sklearn.pipeline import Pipeline

DATA_PATH = os.getenv("SEED_DATA", "data/train.csv")
MODEL_DIR = os.getenv("MODEL_DIR", "models")
MODEL_VERSION = os.getenv("MODEL_VERSION", "baseline-tfidf-logreg-v1")


def load_dataset(path: str) -> tuple[list[str], list[int]]:
    texts: list[str] = []
    labels: list[int] = []
    with open(path, encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            texts.append(row["text"])
            # Binary task: scam vs the rest. The `suspicious` rows land on 0 and
            # surface through the mid probability band, which is where the
            # service's SUSPICIOUS_THRESHOLD picks them up.
            labels.append(1 if row["label"] == "scam" else 0)
    return texts, labels


def template_of(text: str) -> str:
    """Collapse a message to the template it was generated from.

    Most of the corpus is synthetic: many rows differ only in digits, so a
    random split puts siblings on both sides and the score comes out far too
    high. Grouping by template keeps a family inside one fold.
    """
    collapsed = re.sub(r"\d+", "#", text.lower())
    collapsed = re.sub(r"[^\w\s#]", "", collapsed)
    return re.sub(r"\s+", " ", collapsed).strip()


def build_pipeline() -> Pipeline:
    return Pipeline(
        steps=[
            ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=1, sublinear_tf=True)),
            ("clf", LogisticRegression(max_iter=1000, class_weight="balanced")),
        ]
    )


def main() -> None:
    texts, labels = load_dataset(DATA_PATH)
    pipeline = build_pipeline()

    groups = [template_of(text) for text in texts]
    predictions = cross_val_predict(
        pipeline, texts, labels, cv=GroupKFold(n_splits=5), groups=groups
    )
    report = classification_report(
        labels, predictions, target_names=["safe", "scam"], output_dict=True, zero_division=0
    )
    print(classification_report(labels, predictions, target_names=["safe", "scam"], zero_division=0))

    pipeline.fit(texts, labels)

    os.makedirs(MODEL_DIR, exist_ok=True)
    joblib.dump(pipeline, os.path.join(MODEL_DIR, "baseline.joblib"))

    metadata = {
        "model_version": MODEL_VERSION,
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "samples": len(texts),
        "templates": len(set(groups)),
        "metrics": {
            "scam_precision": report["scam"]["precision"],
            "scam_recall": report["scam"]["recall"],
            "scam_f1": report["scam"]["f1-score"],
        },
    }
    with open(os.path.join(MODEL_DIR, "baseline.json"), "w", encoding="utf-8") as handle:
        json.dump(metadata, handle, ensure_ascii=False, indent=2)

    print(f"saved model to {MODEL_DIR}/baseline.joblib")


if __name__ == "__main__":
    main()
