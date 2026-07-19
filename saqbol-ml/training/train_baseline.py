import csv
import json
import os
from datetime import datetime, timezone

import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report
from sklearn.model_selection import cross_val_predict
from sklearn.pipeline import Pipeline

DATA_PATH = os.getenv("SEED_DATA", "data/seed.csv")
MODEL_DIR = os.getenv("MODEL_DIR", "models")
MODEL_VERSION = os.getenv("MODEL_VERSION", "baseline-tfidf-logreg-v1")


def load_dataset(path: str) -> tuple[list[str], list[int]]:
    texts: list[str] = []
    labels: list[int] = []
    with open(path, encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            texts.append(row["text"])
            labels.append(1 if row["label"] == "scam" else 0)
    return texts, labels


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

    predictions = cross_val_predict(pipeline, texts, labels, cv=5)
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
