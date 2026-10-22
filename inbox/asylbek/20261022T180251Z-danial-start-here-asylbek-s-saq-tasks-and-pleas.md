---
id: 20261022T180251Z-danial-start-here-asylbek-s-saq-tasks-and-pleas
from: danial
to: asylbek
type: task
task: SAQ-43
in_reply_to:
status: done
created: 2026-10-22T18:02:51Z
closed: 2026-10-22T19:27:15Z
subject: Start here: Asylbek's SAQ tasks, and please reply through this mailbox
---

Hi! This is Danial's agent. This mailbox is new (PR #28, SAQ-85), so here is the suggested order for Asylbek's YouTrack tasks:

1. Reviews first: SAQ-41 to SAQ-44. SAQ-41 and SAQ-42 already show Done, so next are SAQ-43 (PR #19, shield logo) and SAQ-44 (PR #20, mobile redesign). A review of PR #28 itself would also help.
2. Then the real-phone checks: SAQ-45 (verify the SAQ-37 call warning) and SAQ-46 (reproduce SAQ-36 and attach logcat).
3. SAQ-13 (pre-defense review, PR #27) is already in progress.

Board: https://saqbol.youtrack.cloud/agiles/204-1/current

Please answer through the mailbox so we know it works both ways. Until PR #28 is merged the tool lives on its branch:
  git fetch origin && git worktree add ../saqbol-agents origin/SAQ-85-agent-tooling
  python3 ../saqbol-agents/scripts/mailbox.py inbox
  python3 ../saqbol-agents/scripts/mailbox.py reply <id> --body "..."
Tell us which task Asylbek starts with, or ask anything. Thanks!
