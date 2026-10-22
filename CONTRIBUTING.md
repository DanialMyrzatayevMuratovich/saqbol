# Contributing to SaqBol

These rules apply to both team members and to any AI assistant working in this repository.
They follow the department's Git repository requirements for the diploma project.

Roles and the task plan: [docs/10-project-management.md](docs/10-project-management.md).
Tasks: [YouTrack project SAQ](https://saqbol.youtrack.cloud/issues/SAQ) ·
[Kanban board](https://saqbol.youtrack.cloud/agiles/204-1/current).

## 1. One-time setup

Each student commits from their **own** account. Shared accounts are not allowed. Set your
identity in this repository so that commits link to your GitHub profile:

```bash
git config user.name  "Your Name"
git config user.email "the-email-of-your-github-account@example.com"
```

## 2. Workflow for every change

1. **Task.** Pick a YouTrack task assigned to you (`SAQ-<id>`). Move its *Stage* from
   Backlog to Develop. Every meaningful piece of work needs a task; if there is none, create one
   with an assignee, expected outcome, acceptance criteria and due date.
2. **Branch** from an up-to-date `main`:
   ```bash
   git switch main && git pull
   git switch -c SAQ-<id>-<short-slug>        # e.g. SAQ-35-prototype-screenshots
   ```
3. **Commit** small, coherent changes. Every message starts with the task ID and says what changed:
   ```
   SAQ-35: Add mobile screenshots of the SMS check scenario
   ```
4. **Pull request** into `main`:
   ```bash
   git push -u origin SAQ-<id>-<short-slug>
   gh pr create --base main --title "SAQ-<id>: <summary>" --reviewer <other-member>
   ```
   Fill in the template: link to the task, what changed, how you checked it. Move the task to
   *Review* and add the PR link to the task.
5. **Review.** The other team member reviews (see §3). Fix the comments with new commits.
   New commits reset the approval, so the reviewer approves again.
6. **Merge** only after approval, with **"Create a merge commit"** so that the individual commits
   stay visible in the history. Delete the branch.
7. **Close the task.** Move it to *Done* only when all of its acceptance criteria are met.

`main` is protected. Direct pushes and force pushes are rejected, and a PR cannot be merged
without one approval from someone other than its author. This also applies to the repository owner.

## 3. Reviewing a pull request

A review is part of the assessed work, so leave real comments, not just a click on "Approve".

- [ ] The change does what the YouTrack task asks, and its acceptance criteria are met.
- [ ] You ran it or its tests locally (commands in the README), or checked the document against
      its sources.
- [ ] No secrets, tokens, `.env` files or personal data (see §4).
- [ ] Docs and diagrams are updated if behaviour or design changed.
- [ ] Code reads like the surrounding code; names are clear; no leftover debug code.

Then choose **Approve** or **Request changes**, with at least one concrete comment.

## 4. Secrets and personal data

- Never commit `.env`, tokens, passwords, keys or server credentials. Use `.env.example` with
  placeholders.
- Never commit personal data: real SMS that contain names, phone numbers or card numbers;
  interview notes with names; screenshots with real contacts. Anonymise first
  (participants are P1…P5, phone numbers are replaced by `+7XXXXXXXXXX`).
- If a secret was committed by mistake, tell the team and revoke it immediately. Deleting the file is
  not enough, because it stays in the Git history.

## 5. Before opening a PR

```bash
cd saqbol-backend && go build ./... && go vet ./... && go test ./...
cd saqbol-ml && python -m pytest -q
cd saqbol-mobile && flutter analyze && flutter test
cd saqbol-web && npm run lint && npm test
```

Run the commands for the parts you changed.

## 6. Using AI assistants

AI assistants (Claude Code, ChatGPT, Copilot…) may help. The author of the commit is responsible
for every line: you must understand the change and be able to explain it at the pre-defense.
An assistant must follow this file: one task, one branch, `SAQ-<id>:` commit messages, never push
to `main`, never merge pull requests, never commit secrets or personal data.
