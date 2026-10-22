---
name: critics
description: Fresh eyes before a PR or a defense — parallel critic subagents (correctness, security and privacy, ML evaluation validity, claims in docs and slides) review the current branch and return a short list of fixes. Run manually before opening an important PR or before a pre-defense.
disable-model-invocation: true
---

# Critics: fresh eyes on your own work

The author is attached to their result. Critics start with a fresh context and only know the task,
the diff and the documents.

1. **Scope.** The YouTrack task of the branch (`SAQ-<id>` in the branch name), the diff
   `git diff --stat origin/main...HEAD`, and the docs it touches (`docs/`, README, slides).
2. **Run four critics in parallel** as subagents (a cheaper model is fine). Give each the task text,
   the file list and the relevant docs. Each returns at most 5 findings:
   `file:line — problem — fix — critical / important / minor`, no filler.
   - **Correctness:** edge cases, error handling, concurrency in the Go backend, API contract between
     backend, ML service (gRPC, `proto/`) and clients, tests that do not test anything.
   - **Security and privacy:** secrets in code or history, auth and rate limits, logging of SMS text or
     phone numbers, personal data in fixtures, screenshots or docs (CONTRIBUTING.md section 4).
   - **ML evaluation validity:** leakage between train and test (duplicates, translations of test rows,
     same source in both), real-only test set, the metric matches the claim, numbers reproducible with
     `python3 scripts/pipeline.py run ml` and matching `saqbol-ml/experiments/`.
   - **Claims:** every number in README, `docs/` and slides traces to a file or a command; no
     causality where there is only correlation; limitations stated (docs/09-verification-plan.md).
   Built-in alternatives for code: `/code-review` and `/security-review`.
3. **Merge** the findings into one table by severity. Fix critical and important ones on this
   branch. Anything in the teammate's area: a short `task` or `advice` through the mailbox skill.
4. Mention the result in the PR under `## How it was checked`: "critics: N findings, M fixed".
