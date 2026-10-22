---
id: 20261022T192440Z-danial-12-more-small-code-tasks-saq-87-98-in-an
from: danial
to: asylbek
type: task
task: SAQ-87
in_reply_to:
status: open
created: 2026-10-22T19:24:40Z
closed:
subject: 12 more small code tasks (SAQ-87..98), in an order that avoids conflicts
---

Danial added 12 small code tasks for you in YouTrack (SAQ-87..SAQ-98, assigned to you, details and acceptance criteria in each). None touches a file changed by an open PR, so each can go straight into main. One task = one branch from fresh main = one PR (reviewer DanialMyrzatayevMuratovich); small, clear commits "SAQ-<id>: ...". Danial reviews and merges with a merge commit.

Order (later items touch the same files as earlier ones, so open the next PR after the previous is merged):
Backend (independent, can be parallel):
 1. SAQ-90 gofmt calls/service.go + store/metrics.go (5 min)
 2. SAQ-88 tests for the 600-rune call window
 3. SAQ-87 tests for config loading
 4. SAQ-89 tests for Auth/RequireAdmin middleware
Web:
 5. SAQ-91 tests for src/lib/api.ts (mocked fetch)
 6. SAQ-58 accent colour → logo blue
 7. SAQ-62 mask user phones in Messages, then 8. SAQ-61 pagination (same file)
 9. SAQ-92 page titles, 10. SAQ-93 "Обновлено HH:MM" on the dashboard
Android:
 11. SAQ-84 app name "SaqBol", then 12. SAQ-94 allowBackup=false (same manifest)
Repo:
 13. SAQ-97 .editorconfig, 14. SAQ-95 dependabot.yml, 15. SAQ-96 CI badge in README
 16. SAQ-98 ML health check in docker-compose (needs Docker to verify)
Docs: 17. SAQ-63 SUS questionnaire, 18. SAQ-64 user guide. Plus SAQ-83 (issue to Yerassyl04, no commit).

Run the checks for what you change (go vet/test, npm lint/test/build, flutter build apk) and list them in each PR. Reply here with PR numbers as you go; first still please re-approve #17 and #16.
