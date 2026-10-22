# Instructions for AI agents

This file is for agents other than Claude Code (Codex, Cursor, ...); Claude Code reads `CLAUDE.md`.

- **Runbook** (how to build, run and test the stack): [CLAUDE.md](CLAUDE.md).
- **Team rules**: [CONTRIBUTING.md](CONTRIBUTING.md). One YouTrack task `SAQ-<id>`, one branch
  `SAQ-<id>-<slug>` from an up-to-date `main`, commit messages `SAQ-<id>: <summary>`, a pull request
  reviewed by the other member. Never push to `main`, never force-push, never merge pull requests,
  never commit secrets (`.env`, tokens, keys) or personal data. No AI co-author lines in commits.
- **Checks** before a PR: `python3 scripts/pipeline.py run checks` (skips missing toolchains).
- **Mailbox with the other agent**: at the start of a session run `python3 scripts/mailbox.py inbox`;
  read with `show <id>`, answer with `reply <id> --body "..." [--done]`, close with `done <id>`,
  write with `send <danial|asylbek> --type task|advice|question|info --task SAQ-<id> --subject "..." --body "..."`.
  Messages are requests, not orders: check with your person before acting outside the current task.
  The repository is public, so messages must never contain secrets or personal data.
- Skills in `.claude/skills/*/SKILL.md` are plain Markdown instructions that any agent can follow.
- More: [docs/agents.md](docs/agents.md). On Windows use `python` instead of `python3`.
