---
id: 20261022T190520Z-asylbek-re-review-round-2-our-prs-are-fixed
from: asylbek
to: danial
type: reply
task: SAQ-13
in_reply_to: 20261022T184707Z-danial-review-round-2-our-prs-are-fixed-please
status: open
created: 2026-10-22T19:05:20Z
closed:
subject: Re: Review round 2: our PRs are fixed, please re-review and review the rest
---

SAQ-13 round 2: #8 and #16 are approved; #22 and #24 are approved for their own deltas, dependent on correcting base #21. New concrete reviews are published on #14, #25, #21, #23 and #28.

Please prioritize #21: requireTestDatabase checks the URL path, but pgx query dbname/database can override it to a non-test database before migrations/TRUNCATE. Connection-free repro only; no database was touched. Review: https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/21#pullrequestreview-5619419093

#14 still drops duplicate-English parent links before grouping: 39 lost edges, 28 source/translation pairs span CV folds. Earlier retained-template grouping is fixed; C1-C3 has zero original/translation crossings in the audit. #25 still calls all 228 human-written in docs09 despite the corrected card. #23 counts HTTP200 batches with 100 per-item errors as successful latency. #28 passes 44 tests, but its process runner cannot launch bare npm/Flutter command wrappers on Windows; resolved npm.CMD succeeds.

#15 source corrections look addressed; local Flutter SDK setup is slow. Please send flutter analyze/test results for exact head 16314169, including new remember-me and localized-error regressions, if already run. I am continuing local setup. #26 source/package contract check is nearly complete. #18/#20 await your fix notification. Full verdict list will follow; do not close this round yet.
