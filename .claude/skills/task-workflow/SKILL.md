---
name: task-workflow
description: Do a piece of work the SaqBol way — YouTrack task SAQ-<id>, branch SAQ-<id>-<slug> from origin/main, small SAQ-<id> commits, `scripts/pipeline.py run checks`, pull request reviewed by the other member, Stage moved to Review. Use when starting, committing, checking or finishing any change in this repository.
---

# Task workflow

Rules: `CONTRIBUTING.md` and `CLAUDE.md` section 8. The guard hook (`.claude/hooks/guard.py`)
blocks the worst mistakes, but follow the rules on purpose, not by trial and error.

## 1. Start

1. Which task? Every change belongs to a YouTrack task `SAQ-<id>`
   (https://saqbol.youtrack.cloud/issues/SAQ). If the user has not named one, ask.
2. Check the identity: `git config user.name` / `user.email` must be the person you work for
   (`python3 scripts/mailbox.py whoami` tells which team member that is).
3. Branch from an up-to-date main, in a separate worktree if another agent works in this checkout:
   ```bash
   git fetch origin
   git switch -c SAQ-<id>-<short-slug> origin/main
   git branch --unset-upstream          # so a bare `git push` can never target main
   ```
4. Look at the mailbox (`python3 scripts/mailbox.py inbox`) for anything about this task.

## 2. Work and commit

- Small, coherent commits: `SAQ-<id>: <Imperative summary in English>` plus a short body (why).
- No `Co-Authored-By` or "Generated with" lines: the human author answers for every line.
- Never commit `.env`, keys, tokens or personal data (real SMS with names or numbers, interview notes).

## 3. Check

```bash
python3 scripts/pipeline.py run checks                 # everything that is installed here
python3 scripts/pipeline.py run checks --only backend  # just the part you changed (backend, ml, mobile, web, tools)
python3 scripts/pipeline.py run ml                     # after changing data or training code
```

Steps whose toolchain is missing are skipped, not failed: say which ones were skipped. Only claim
in the PR what actually ran. Do not run the `apk` pipeline unless the user asks for an APK.

## 4. Pull request

```bash
git push -u origin SAQ-<id>-<short-slug>
gh pr create --base main --title "SAQ-<id>: <summary>" --body-file - --reviewer <other member's GitHub login>
```

Body sections (`.github/pull_request_template.md`): `## Task` (link
https://saqbol.youtrack.cloud/issue/SAQ-<id>), `## What changed`, `## How it was checked` (checkboxes,
only what you ran), `## Reviewer`. Then move the task's Stage to Review and comment the PR link
on the task. If the reviewer should know something, send a short `info` through the mailbox skill.

## Never

Push or commit to `main`, force-push, rewrite pushed history, merge a pull request (a human
merges after the other member approves), or close a YouTrack task whose acceptance criteria are not met.
