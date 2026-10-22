"""Report template overlap in an existing ML checkout without modifying data."""

import argparse
from collections import defaultdict
import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

from sklearn.model_selection import GroupKFold


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ml-dir", type=Path, required=True)
    args = parser.parse_args()
    ml_dir = args.ml_dir.resolve()
    data_path = ml_dir / "data" / "train.csv"
    trainer_path = ml_dir / "training" / "train_baseline.py"

    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("reviewed_trainer", trainer_path)
    trainer = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(trainer)
    with data_path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    texts, labels, groups = trainer.load_dataset(str(data_path))
    if len(rows) != len(texts):
        raise ValueError("Trainer row count differs from the input CSV")

    folds = {}
    for fold, (_, indexes) in enumerate(
        GroupKFold(n_splits=5).split(texts, labels, groups)
    ):
        for index in indexes:
            folds[index] = fold

    english_families = defaultdict(list)
    originals = {row["text"]: row for row in rows}
    for index, row in enumerate(rows):
        if row.get("lang") == "en":
            english_families[trainer.template_of(row["text"])].append(index)
    crossing = [
        indexes
        for indexes in english_families.values()
        if len({folds[index] for index in indexes}) > 1
    ]
    linked_non_synthetic = sum(
        bool(row.get("translated_from"))
        and row["translated_from"] in originals
        and not originals[row["translated_from"]].get("source", "").startswith("synthetic")
        for row in rows
    )
    print(json.dumps({
        "dataset_sha256": hashlib.sha256(data_path.read_bytes()).hexdigest(),
        "rows": len(rows),
        "english_rows": sum(row.get("lang") == "en" for row in rows),
        "english_template_families_crossing_folds": len(crossing),
        "english_rows_in_crossing_families": sum(map(len, crossing)),
        "translations_of_non_synthetic_originals": linked_non_synthetic,
    }, indent=2))


if __name__ == "__main__":
    main()
