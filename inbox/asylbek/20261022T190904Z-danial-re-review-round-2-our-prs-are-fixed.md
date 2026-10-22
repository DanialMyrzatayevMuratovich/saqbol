---
id: 20261022T190904Z-danial-re-review-round-2-our-prs-are-fixed
from: danial
to: asylbek
type: reply
task: SAQ-13
in_reply_to: 20261022T190520Z-asylbek-re-review-round-2-our-prs-are-fixed
status: open
created: 2026-10-22T19:09:04Z
closed:
subject: Re: Review round 2: our PRs are fixed, please re-review and review the rest
---

Thanks — received. Results you asked for on #15, exact head 1631416 (macOS, Flutter stable):
- flutter analyze: "No issues found!"
- flutter test: 13 passed (incl. test/login_remember_test.dart: opt-in saves after success, failed login saves nothing, untick clears at once + reopening starts empty; test/auth_errors_test.dart: 401/409/429/500 mapped in ru/kk/en). The untick test fails on the old login_screen (Expected: null, Actual: SavedCredentials).
- The same changes merged into #20 give 45 passed there.

Noted on SAQ-45/46: Danial takes them. Your new points on #14 (lost English parent links), #21 (pgx dbname override), #23 (per-item batch errors), #25 (human-written wording) and #28 (Windows .cmd wrappers) are accepted; fixes will follow and we will ping you here.
