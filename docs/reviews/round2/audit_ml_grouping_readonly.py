"""Read-only SAQ-13 review: no model fitting, source text output or dataset writes.

Usage: python -B audit_ml_grouping_readonly.py PATH_TO_PR_WORKTREE
"""

import argparse
import ast
import csv
import hashlib
import io
import json
import subprocess
import sys
from collections import Counter, defaultdict
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

sys.dont_write_bytecode = True
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("repo", type=Path, help="pinned PR #14 or #25 repository worktree")
root = parser.parse_args().repo.resolve()
head = subprocess.run(
    ["git", "rev-parse", "HEAD"], cwd=root, check=True, capture_output=True, text=True
).stdout.strip()
compatible_heads = {
    "7f7dec98aee586ae3f46ddec294af3ce26d723bc",  # PR #14
    "1d6a0f928e4257d27051bab7486fbdb578bea714",  # PR #25, same reviewed ML implementation
}
if head not in compatible_heads:
    parser.error("This diagnostic imports reviewed functions and is pinned to PR #14/#25 "
                 "heads listed in README.md. Inspect compatibility before adapting it.")
ml = root / "saqbol-ml"
sys.path.insert(0, str(ml / "training"))

import numpy as np
from sklearn.model_selection import GroupKFold
from train_baseline import load_dataset, template_of
from evaluate_real import load
import merge_datasets


def read_rows(path):
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def git_blob(ref, path):
    return subprocess.run(
        ["git", "show", f"{ref}:{path}"], cwd=root, check=True, capture_output=True
    ).stdout


rows = read_rows(ml / "data/train.csv")
translations = read_rows(ml / "data/translations_en.csv")
assert rows and {"text", "label", "source", "translated_from"} <= rows[0].keys()
assert translations and {"text", "text_en"} <= translations[0].keys()

# Execute the reviewed merge function with all output intercepted in memory.
# This verifies the missing edges arise from the real merge path, without writes.
class CapturedOutput(io.StringIO):
    def close(self):
        pass


merged_output = CapturedOutput()
normal_open = open


def read_or_capture(path, mode="r", **kwargs):
    if mode == "w":
        assert str(path) == merge_datasets.OUT
        return merged_output
    assert mode == "r", f"Unexpected mode: {mode}"
    return normal_open(ml / path, mode, **kwargs)


with patch.object(merge_datasets, "open", read_or_capture, create=True), redirect_stdout(io.StringIO()):
    merge_datasets.main()
merged_rows = list(csv.DictReader(io.StringIO(merged_output.getvalue())))
assert merged_rows == rows, "In-memory reviewed merge must reproduce committed rows exactly"

texts, labels, groups = load_dataset(str(ml / "data/train.csv"))
index = {row["text"]: i for i, row in enumerate(rows)}
assert len(index) == len(rows), "Expected unique training texts"
fold = {}
for k, (_, held_out) in enumerate(GroupKFold(5).split(texts, labels, groups)):
    for i in held_out:
        fold[int(i)] = k

stored_templates = defaultdict(set)
for i, row in enumerate(rows):
    stored_templates[template_of(row["text"])].add(fold[i])
    if row.get("translated_from"):
        stored_templates[template_of(row["translated_from"])].add(fold[i])

# Audit every source edge, including edges dropped when English texts deduplicate.
assert all(row["text"] in index and row["text_en"].strip() in index for row in translations)
pairs = [(index[row["text"]], index[row["text_en"].strip()]) for row in translations]
dropped = [(a, b) for a, b in pairs if rows[b].get("translated_from") != rows[a]["text"]]
different_group = [(a, b) for a, b in pairs if groups[a] != groups[b]]
different_fold = [(a, b) for a, b in pairs if fold[a] != fold[b]]
assert set(different_group).issubset(set(dropped))

_, y, cohort, family_ids = load(str(ml / "data/train.csv"))
test_indices = set(int(i) for i in np.flatnonzero(cohort))
test_families = set(family_ids[list(test_indices)])
train_indices = {
    int(i) for i in np.flatnonzero(~cohort) if family_ids[i] not in test_families
}
c_leaks = [(a, b) for a, b in pairs if a in test_indices and b in train_indices]

nb = json.loads((ml / "training/colab_train_xlmr.ipynb").read_text(encoding="utf-8"))
code_cells = [(i, "".join(cell["source"])) for i, cell in enumerate(nb["cells"]) if cell["cell_type"] == "code"]
for i, source in code_cells:
    ast.parse(source, filename=f"notebook-cell-{i}")
config = {}
for node in ast.parse("".join(nb["cells"][4]["source"])).body:
    if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name):
        name = node.targets[0].id
        if name in {"DATA_COMMIT", "DATA_SHA256"}:
            config[name] = ast.literal_eval(node.value)
pinned_data = git_blob(config["DATA_COMMIT"], "saqbol-ml/data/train.csv")
current_data = git_blob("HEAD", "saqbol-ml/data/train.csv")
counts = defaultdict(Counter)
for row in rows:
    counts[row["source"]][row["label"]] += 1

summary = {
    "head": head,
    "row_count": len(rows),
    "reviewed_merge_reproduces_committed_rows_in_memory": merged_rows == rows,
    "source_labels": {source: dict(values) for source, values in counts.items()},
    "connected_groups": len(set(groups)),
    "stored_template_buckets_spanning_folds": sum(len(values) > 1 for values in stored_templates.values()),
    "source_translation_pairs": len(pairs),
    "deduplicated_parent_edges_missing_from_train_csv": len(dropped),
    "source_translation_pairs_in_different_groups": len(different_group),
    "source_translation_pairs_in_different_folds": len(different_fold),
    "source_translation_label_mismatches": sum(rows[a]["label"] != rows[b]["label"] for a, b in pairs),
    "example_record_indices_zero_based_no_source_text": [
        {"source_index": a, "english_index": b, "retained_parent_index": index[rows[b]["translated_from"]],
         "source_fold": fold[a], "english_fold": fold[b]}
        for a, b in different_fold[:5]
    ],
    "C_train_rows": len(train_indices),
    "C_test_rows": len(test_indices),
    "C_test_scam_labels": int(y[cohort].sum()),
    "C_source_translation_pairs_crossing_train_test": len(c_leaks),
    "notebook_syntax_valid_code_cells": len(code_cells),
    "notebook_saved_outputs": sum(len(cell.get("outputs", [])) for cell in nb["cells"]),
    "notebook_data_commit": config["DATA_COMMIT"],
    "notebook_expected_sha256": config["DATA_SHA256"],
    "notebook_pin_sha256_matches": hashlib.sha256(pinned_data).hexdigest() == config["DATA_SHA256"],
    "pinned_dataset_equals_reviewed_dataset": pinned_data == current_data,
}
print(json.dumps(summary, indent=2))
