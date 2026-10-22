import csv
import os
import sys
from collections import defaultdict

from sklearn.model_selection import GroupKFold

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "training"))
from train_baseline import load_dataset, template_families, template_of  # noqa: E402

DATA = os.path.join(os.path.dirname(__file__), "..", "data", "train.csv")


def test_translations_that_collapse_together_join_their_originals():
    texts = [
        "Ваш код 1234, никому не говорите",
        "Сіздің кодыңыз 5678, ешкімге айтпаңыз",
        "Your code is 1234, do not tell anyone",
        "Your code is 9999, do not tell anyone",
        "Привет, встречаемся завтра",
    ]
    originals = ["", "", texts[0], texts[1], ""]

    groups = template_families(texts, originals)

    # The two English rows share a template, so both originals end up together.
    assert len({groups[0], groups[1], groups[2], groups[3]}) == 1
    assert groups[4] != groups[0]


def test_no_template_family_spans_folds_in_the_committed_corpus():
    texts, labels, groups = load_dataset(DATA)
    with open(DATA, encoding="utf-8") as handle:
        originals = [row.get("translated_from") or "" for row in csv.DictReader(handle)]

    fold = [0] * len(texts)
    for k, (_, test_index) in enumerate(GroupKFold(n_splits=5).split(texts, labels, groups)):
        for i in test_index:
            fold[i] = k

    folds_of = defaultdict(set)
    for i, text in enumerate(texts):
        folds_of[template_of(text)].add(fold[i])
        if originals[i]:
            folds_of[template_of(originals[i])].add(fold[i])

    spanning = [template for template, folds in folds_of.items() if len(folds) > 1]
    assert spanning == [], f"{len(spanning)} template families span folds"
