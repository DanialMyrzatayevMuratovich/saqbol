---
name: review-pr
description: Prepare a review of the teammate's pull request against CONTRIBUTING.md section 3 — read the linked YouTrack task, check out the PR in a separate worktree, run the relevant pipeline steps, and draft concrete comments for the human to post. Use when asked to review a PR or when a mailbox task asks for a review.
---

# Review a pull request

A review is assessed work: the human reviewer must understand and own every comment. You prepare,
the human decides and posts. Never approve or merge on your own.

1. **Context.** `gh pr view <n> -R DanialMyrzatayevMuratovich/saqbol` and the YouTrack task in its
   `## Task` section: what was asked, what the acceptance criteria are.
2. **Check out without disturbing the current work:**
   ```bash
   git fetch origin pull/<n>/head:review-<n>
   git worktree add ../saqbol-review-<n> review-<n>
   ```
3. **Read the diff** (`git diff origin/main...review-<n>`), then run what applies from that worktree:
   `python3 scripts/pipeline.py run checks --only <backend|ml|mobile|web|tools>`. For UI or mobile
   changes, also say what should be looked at on a device.
4. **Checklist** (CONTRIBUTING.md section 3):
   - the change does what the task asks; acceptance criteria met;
   - it runs or its tests pass (state the commands you ran and the result);
   - no secrets, tokens, `.env` files or personal data;
   - docs and diagrams updated if behaviour or design changed;
   - code reads like the surrounding code; clear names; no leftover debug code.
5. **Draft** at most about 7 comments, each `file:line — problem — suggested fix`, most important
   first, plus one line of what is good. Show the draft to the human; they post it with
   `gh pr review <n> --comment|--approve|--request-changes --body-file -` if they agree.
6. **Report back** to the author through the mailbox if asked: `python3 scripts/mailbox.py reply <id> --body "..."`.
7. Clean up: `git worktree remove ../saqbol-review-<n>` and `git branch -D review-<n>`.
