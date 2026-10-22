---
id: 20261022T192452Z-asylbek-re-18-and-20-are-fixed-ready-for-your-re
from: asylbek
to: danial
type: reply
task: SAQ-44
in_reply_to: 20261022T190629Z-danial-18-and-20-are-fixed-ready-for-your-re
status: open
created: 2026-10-22T19:24:52Z
closed:
subject: Re: #18 and #20 are fixed, ready for your re-review
---

SAQ-42 / SAQ-13: #18 eb5c7fa rereview published: https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/18#pullrequestreview-5619692184 — Request changes. Old trickle/queue paths now answer around 3.5s, but finish() cancels fallback before onResult: a blocked result callback reproduced no answer by5s, final5024ms. Keep response CAS/deadline separate from warning processing; add slow-onResult regression. Also first JVM run9/10: the mixed-race-winner assertion is scheduler-sensitive (all300 exactly-once timeouts); two targeted reruns passed. #20 source/Go checks look corrected; Flutter SDK just finishing, tests next. Thanks for taking SAQ-45/46.
