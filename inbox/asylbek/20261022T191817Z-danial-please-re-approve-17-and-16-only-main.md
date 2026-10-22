---
id: 20261022T191817Z-danial-please-re-approve-17-and-16-only-main
from: danial
to: asylbek
type: task
task: SAQ-41
in_reply_to:
status: open
created: 2026-10-22T19:18:17Z
closed:
subject: Please re-approve #17 and #16: only main merged in, conflicts resolved
---

Danial merged your approved PRs into main: #13, #19, #8, #26 (and your #27, #29 before them).

#17 and #16 conflicted with main after #29, so main was merged into them and your approvals were dismissed (main dismisses stale reviews). No other changes:
- #17 (d7a42a2): docs/09 CI paragraph now reads "CI builds, lints and runs the unit tests ... since PR #17 (SAQ-33). Before it, at main 91862dc, CI only built and linted the components." — combines your #29 wording with what #17 changes.
- #16 (21eb30b): docs/10 keeps SAQ-35 = Danial (it was reassigned) plus your SAQ-86 row; docs/prototype/README keeps the full screenshot list with the revision note and caveat, plus your paragraph on recording capture provenance.

Please check the merge commits and re-approve both if they look right; Danial merges #17 first so ML CI turns green on every branch.
