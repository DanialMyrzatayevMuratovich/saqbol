# Review evidence and companion corrections

- [First review round, 22 October](2026-10-22-pre-defense-review.md)
- [Second review round, 23 October](2026-10-23-round-two-review.md)
- [Reproducible second-round diagnostics](round2/README.md)

## SAQ-86 companion corrections for pending documents

The main SAQ-86 change corrects the documentation and diagrams already present in `main`.
Two related files belong to unmerged PRs, so their corrections are supplied as exact patches
instead of adding conflicting duplicate documents or editing another author's branch.

| Patch | Target document and reviewed head | Correction |
|---|---|---|
| [SAQ-86-requirements.patch](SAQ-86-requirements.patch) | PR #8, `docs/06-requirements.md`, `46a3364f95f81ab53cd0bc5b658a921ec53547db` | Keep the bilingual goal and requirement IDs; clarify configured Russian STT versus device proof, the future received-SMS test set, and SaqBol text transport versus OS-provider audio processing |
| [SAQ-86-dataset-card.patch](SAQ-86-dataset-card.patch) | PR #25, `docs/12-dataset-card.md`, `37305a21be70045ef60fb8e6d8077b6aea99690b` | Treat the source-prefix selection as metadata, not proof of received SMS or human authorship; remove the unmeasured claim that the subset is closer to real use |

Both patches passed `git apply --check --whitespace=error` and actual application to disposable
copies of the exact target files. Applied content matched the expected corrected documents;
unrelated requirement rows, dataset rows and metric values were preserved. These checks establish
patch applicability at the named revisions, not that the corrections have merged.

## Apply through review

After the corresponding target document is available in a reviewed baseline, create a task
branch from fresh `main`, verify the target has not changed incompatibly, and run from the
repository root:

```bash
git apply --check docs/reviews/SAQ-86-requirements.patch
git apply docs/reviews/SAQ-86-requirements.patch
git diff --check
git diff -- docs/06-requirements.md
```

Use the same sequence for `SAQ-86-dataset-card.patch` after the dataset card is available.
Commit the actual document changes under SAQ-86 and submit them for peer review. If the author
already incorporated the correction, verify the final text instead of applying it twice.
If a target changed, adapt and recheck the patch; do not force it onto a different revision.
The original PR author may also incorporate the proposed text in their own branch before merge.

## Related ML documentation changes

PR #14 and the stacked PR #25 also update `docs/02-relevance-evidence.md`,
`docs/03-literature-review.md` and `docs/09-verification-plan.md`. Keep the revised PR #25
metric values and evaluation procedure when integrating these changes; SAQ-86 intentionally
uses that revised table with an explicit source-version and provenance limitation. Do not
restore the earlier 0.973 full-corpus recall as the current grouped result, and do not relabel
the 228 diagnostic examples as received SMS. Recheck this overlap when `main` advances.

See [implementation and evidence status](../implementation-evidence.md) for what is established
and what remains pending. The patch artifacts alone do not complete the requirements merge,
human interviews, supervisor feedback, or device validation.
