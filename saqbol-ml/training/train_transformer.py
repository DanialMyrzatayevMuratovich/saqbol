import csv
import os

import numpy as np
from datasets import Dataset
from sklearn.metrics import f1_score, precision_score, recall_score
from sklearn.model_selection import train_test_split
from transformers import (
    AutoModelForSequenceClassification,
    AutoTokenizer,
    Trainer,
    TrainingArguments,
)

DATA_PATH = os.getenv("SEED_DATA", "data/seed.csv")
BASE_MODEL = os.getenv("BASE_MODEL", "xlm-roberta-base")
OUTPUT_DIR = os.getenv("TRANSFORMER_DIR", "models/xlm-roberta")


def load_rows() -> tuple[list[str], list[int]]:
    texts: list[str] = []
    labels: list[int] = []
    with open(DATA_PATH, encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            texts.append(row["text"])
            labels.append(1 if row["label"] == "scam" else 0)
    return texts, labels


def compute_metrics(prediction):
    logits, labels = prediction
    preds = np.argmax(logits, axis=1)
    return {
        "precision": precision_score(labels, preds, zero_division=0),
        "recall": recall_score(labels, preds, zero_division=0),
        "f1": f1_score(labels, preds, zero_division=0),
    }


def main() -> None:
    texts, labels = load_rows()
    train_texts, eval_texts, train_labels, eval_labels = train_test_split(
        texts, labels, test_size=0.2, stratify=labels, random_state=42
    )

    tokenizer = AutoTokenizer.from_pretrained(BASE_MODEL)

    def tokenize(batch):
        return tokenizer(batch["text"], truncation=True, padding="max_length", max_length=128)

    train_dataset = Dataset.from_dict({"text": train_texts, "label": train_labels}).map(tokenize, batched=True)
    eval_dataset = Dataset.from_dict({"text": eval_texts, "label": eval_labels}).map(tokenize, batched=True)

    model = AutoModelForSequenceClassification.from_pretrained(BASE_MODEL, num_labels=2)

    args = TrainingArguments(
        output_dir=OUTPUT_DIR,
        num_train_epochs=4,
        per_device_train_batch_size=8,
        per_device_eval_batch_size=8,
        learning_rate=2e-5,
        eval_strategy="epoch",
        save_strategy="epoch",
        logging_steps=10,
    )

    trainer = Trainer(
        model=model,
        args=args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        compute_metrics=compute_metrics,
    )

    trainer.train()
    print(trainer.evaluate())

    trainer.save_model(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)
    print(f"saved transformer to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
