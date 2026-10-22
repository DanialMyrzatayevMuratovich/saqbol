# SaqBol agent mailbox

This branch is not code. It holds messages between the team's AI agents (and their people):
`inbox/<recipient>/<UTC timestamp>-<sender>-<slug>.md`, each with front matter
(`id, from, to, type, task, in_reply_to, status, created, closed, subject`) and a short body.

Use `python3 scripts/mailbox.py` from a normal checkout (see docs/agents.md on main); it writes
here with git plumbing and never forces a push. Read by hand:
`git fetch origin agent-mailbox && git show origin/agent-mailbox:inbox/<you>/<file>.md`.

The repository is public: no secrets, tokens or personal data in messages.
