"""Merge the labelled corpora into the single file training reads.

Sources keep their own shape, so this is the one place that knows how to line
them up. Every row that has an English rendering in translations_en.csv
(`text` -> `text_en`) is also added in English, pointing back at its original
through `translated_from`. Rerun after adding or updating any source:

    python training/merge_datasets.py
"""

import csv
import os

SEED = os.getenv("SEED_CSV", "data/seed.csv")
CORPUS = os.getenv("CORPUS_CSV", "data/saqbol_sms_dataset_v1.csv")
TRANSLATIONS = os.getenv("TRANSLATIONS_CSV", "data/translations_en.csv")
OUT = os.getenv("TRAIN_CSV", "data/train.csv")

# Categories the rules engine does not emit — they describe non-scam rows and
# would otherwise leak a label into the category column.
NON_SCAM_CATEGORIES = {"legitimate", "grey_marketing"}

# The `synthetic` prefix matters: evaluation treats every other source as a
# real message, and a translation of one is not.
TRANSLATION_SOURCE = "synthetic_translation_en"

FIELDS = ["text", "label", "category", "lang", "source", "translated_from"]


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

    original_count = len(rows)

    with open(TRANSLATIONS, encoding="utf-8") as handle:
        english = {row["text"]: row["text_en"].strip() for row in csv.DictReader(handle)}

    for row in rows[:original_count]:
        text = english.get(row["text"], "")
        # Siblings of one template can collapse into the same English sentence.
        if not text or text in seen:
            continue
        seen.add(text)
        rows.append({
            "text": text,
            "label": row["label"],
            "category": row["category"],
            "lang": "en",
            "source": TRANSLATION_SOURCE,
            "translated_from": row["text"],
        })

    with open(OUT, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS, restval="")
        writer.writeheader()
        writer.writerows(rows)

    print(
        f"{OUT}: {len(rows)} rows ({seed_count} seed + {original_count - seed_count} corpus"
        f" + {len(rows) - original_count} translated to English)"
    )


if __name__ == "__main__":
    main()
