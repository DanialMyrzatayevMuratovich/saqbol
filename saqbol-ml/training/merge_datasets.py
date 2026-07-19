"""Merge the labelled corpora into the single file training reads.

Sources keep their own shape, so this is the one place that knows how to line
them up. Rerun after adding or updating any source:

    python training/merge_datasets.py
"""

import csv
import os

SEED = os.getenv("SEED_CSV", "data/seed.csv")
CORPUS = os.getenv("CORPUS_CSV", "data/saqbol_sms_dataset_v1.csv")
OUT = os.getenv("TRAIN_CSV", "data/train.csv")

# Categories the rules engine does not emit — they describe non-scam rows and
# would otherwise leak a label into the category column.
NON_SCAM_CATEGORIES = {"legitimate", "grey_marketing"}

FIELDS = ["text", "label", "category", "lang", "source"]


def main() -> None:
    rows: list[dict[str, str]] = []
    seen: set[str] = set()

    with open(SEED, encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            text = row["text"].strip()
            if not text or text in seen:
                continue
            seen.add(text)
            rows.append({
                "text": text,
                "label": row["label"],
                "category": row.get("category", ""),
                "lang": "",
                "source": "seed",
            })

    seed_count = len(rows)

    with open(CORPUS, encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            text = row["text"].strip()
            # Exact duplicates only: near-duplicates are real signal here, and
            # the trainer handles them by grouping folds on the template.
            if not text or text in seen:
                continue
            seen.add(text)
            category = row.get("category", "")
            rows.append({
                "text": text,
                "label": row["label"],
                "category": "" if category in NON_SCAM_CATEGORIES else category,
                "lang": row.get("lang", ""),
                "source": row.get("source", ""),
            })

    with open(OUT, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"{OUT}: {len(rows)} rows ({seed_count} seed + {len(rows) - seed_count} corpus)")


if __name__ == "__main__":
    main()
