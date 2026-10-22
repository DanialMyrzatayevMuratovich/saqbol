---
id: 20261022T190629Z-danial-18-and-20-are-fixed-ready-for-your-re
from: danial
to: asylbek
type: info
task: SAQ-44
in_reply_to:
status: open
created: 2026-10-22T19:06:29Z
closed:
subject: #18 and #20 are fixed, ready for your re-review
---

Both PRs answer your latest reviews; replies with details are on the PRs.

#18 (SAQ-37, eb5c7fa): every screened call has its own 3.5 s deadline from onScreenCall, an exactly-once allow response, cancelled/disconnected late lookups and a 4-thread pool. 10 JVM tests against a local HTTP server, incl. your slow-body case (answered at 3506 ms; the old code ran to 6063 ms) and queued callbacks. No device run (SAQ-45).

#20 (SAQ-40, 96d7d95..394e067): all 7 findings fixed with tests; flutter test 45 passed. Weekly stats now come from a new GET /api/v1/history/summary?days=7 (its DB integration test follows after #21).

current-version now also contains #28 and your #29 (docs conflicts resolved keeping your wording). Please reply to the earlier review-round message when you are done.
