# 9. Verification and Evaluation Plan

## 9.1 What we must demonstrate

The project aim ([proposal](01-project-proposal.md#13-aim)) is reached when we can show four things:

| Claim | Evidence | Section |
|---|---|---|
| The system works as specified | Every *Must* requirement passes its acceptance criterion | 9.2, 9.8 |
| It detects real scams well | Recall (scam) ≥ 0.90 at FPR ≤ 0.10 on a **real-only** test set, and better than the baseline | 9.3, 9.4 |
| It warns in time | SMS p95 < 1 s; call alert < 3 s after the trigger phrase is recognised | 9.5, 9.6 |
| Users understand and accept it | Usability test: task success, SUS ≥ 68, and the explanation is understood | 9.7 |

## 9.2 Test levels

| Level | What | Tools | Exists today | To add |
|---|---|---|---|---|
| Unit | Token issuing / validation, mock classifier (Go); rule engine and pipeline thresholds (Python); highlighted triggers, strings in both languages, locale switch (Flutter); verdict labels (web) | `go test`, `pytest`, `flutter test`, `vitest` | ~30 tests: Go 7, Python 12, Flutter 9, web 2 | Store layer, reputation updates, batch check |
| API integration | Every `/api/v1` endpoint: status codes, validation, auth (401), admin role (403), ownership (404 on another user's message) | Go `httptest` + mock classifier + test Postgres | — | SAQ-34 |
| End-to-end | Fresh clone → `docker compose up` → register → SMS check → verdict `scam` with `model_version` | Smoke script from `CLAUDE.md` | Manual | Run in CI on pull requests |
| ML evaluation | Protocol in 9.4 | `training/evaluate.py`, Colab notebook | Partial (9.3) | SAQ-22 |
| Real-time call | Protocol in 9.5 | Scripted calls, device logs | — | SAQ-23, SAQ-24 |
| Performance | Protocol in 9.6 | `hey` or a Go/Python load script; backend Prometheus metrics | — | SAQ-24 |
| Device | Android: SMS permission, inbox scan, incoming SMS notification, call screening on at least 2 devices (Android 10+); iOS: manual check and live call | Physical devices | Manual on one device | Checklist per release |
| Usability | Protocol in 9.7 | SUS questionnaire, observation notes | — | SAQ-30 |
| Security | Secrets not in Git, JWT secrets required, rate limit, admin role, input limits | Code review, `gitleaks`, manual API checks | Partly | Before each pre-defense |

CI currently builds and lints all four apps but does not run the unit tests (task SAQ-33).

## 9.3 Current baseline

The baseline solution for comparison is the deployed model `baseline-tfidf-logreg-v1`
(TF-IDF word 1–2-grams + Logistic Regression with balanced class weights), combined with the rule
engine. Measured on 2026-10-22 on `saqbol-ml/data/train.csv` (binary task: scam vs the rest).

**Data:** 4,457 rows. 2,020 are Kazakh templates, 2,209 are English machine translations, and only
**228 are real messages** (184 from the public `Yerassyl04/Spam-kazakh` dataset, 44 hand-collected
seed messages). Of the real messages, 47 are scams.

| Protocol | n | Precision | Recall (scam) | F1 | FPR | ROC-AUC |
|---|---|---|---|---|---|---|
| A. 5-fold cross-validation grouped by template family (an original, its translation and every template they share), all rows (the number in `models/baseline.json`) | 4,457 | 0.935 | 0.958 (0.95–0.97) | 0.946 | 0.053 | 0.976 |
| B. Same predictions as A, scored on real rows only | 228 | 1.000 | 0.468 (0.32–0.62) | 0.638 | 0.000 | 0.942 |
| C1. Train on synthetic rows outside the test rows' families, test on all real rows, threshold 0.5 | 228 | 0.677 | 0.447 (0.30–0.60) | 0.538 | 0.055 | 0.821 |
| C2. As C1, deployed threshold 0.8, model only | 228 | 1.000 | 0.021 (0.00–0.06) | 0.042 | 0.000 | 0.821 |
| C3. As C1, deployed pipeline: max(model, rules), threshold 0.8 | 228 | 1.000 | **0.511 (0.36–0.66)** | **0.676** | 0.000 | 0.876 |

The intervals are 95% bootstrap intervals of the scam recall (2,000 resamples of the scams, seed 42).
`python training/evaluate_real.py` reproduces the whole table. C1–C3 leave out of training every row in
the same template family as a test row; that removes the 228 English translations of the test messages.
The table was re-measured after the fold grouping was fixed in the PR #14 review: grouping only by the
original's template had let 99 English template families (839 rows) span folds, which put A at 0.973 recall.

**Reading the table**

- The template-heavy corpus makes the task look solved (A). On real messages recall drops by about half
  (B, C1). This is the same effect reported by Radolda et al. (2026) and Shen et al. (2025)
  ([literature review](03-literature-review.md)).
- At the deployed threshold the model alone almost never says "scam" on real data (C2). The rule
  engine carries the system (C3).
- With only 47 real scams the confidence intervals are wide. The first priority is therefore
  more real data (SAQ-19), not a bigger model.

**C3 is the reference point** that XLM-R and every later change must beat on the same real test set.

## 9.4 ML experiment protocol

**Data split**

1. Collect real messages (target ≥ 500, of which ≥ 150 are scams; SAQ-19) and label them using the
   labelling guideline (SAQ-20). A second team member re-labels 20% of them, and we report Cohen's κ.
2. Freeze a **real-only test set** (about 30% of real messages, stratified by label, language and
   category) before any model is tuned on it. The test set is never used for training or threshold
   selection.
3. Training data = the remaining real messages + templates + translations. A translation always sits
   in the same fold as its source, and template families are grouped (as `train_baseline.py` already does).
4. Select thresholds on a validation split of real messages (from the training side), not on the test set.

**Models compared**

| Model | Role |
|---|---|
| TF-IDF + LR (+ rules) | Baseline (C3) |
| TF-IDF + LinearSVM, TF-IDF + Naive Bayes | Classical alternatives |
| XLM-RoBERTa-base, fine-tuned (Colab T4) | Main candidate |
| XLM-R + rules | Deployed configuration candidate |

**Metrics.** Recall (scam) is primary. We also report precision, F1, FPR, ROC-AUC and PR-AUC, each
with 95% bootstrap confidence intervals, plus a confusion matrix per scam category.

**Slices.** Results are broken down by:
- language: Kazakh, Russian, code-switched;
- category: fake bank, fake police, Kaspi, prize, phishing;
- hard negatives: genuine bank, OTP and delivery messages that contain scam keywords.

**Robustness.** We re-score the test set after automatic perturbations:
- Latin ↔ Cyrillic look-alike letters;
- inserted spaces or dots in keywords;
- obfuscated links such as `kaspi-kz[.]com`;
- removed Kazakh-specific letters (қ→к, ү→у…).

**Success criterion (NFR-2).** The selected model reaches recall ≥ 0.90 at FPR ≤ 0.10 on the real
test set, and its recall CI lies above the baseline's. If no model reaches 0.90, we report the best
achieved point and the precision–recall trade-off honestly.

## 9.5 Real-time call evaluation

**Material.** 20 scam scripts and 20 benign scripts, 10 + 10 in each language. Scam scripts follow
the documented local schemes (fake bank, eGov → "Стоп-кредит", fake operator, police). Benign
scripts include real-sounding bank and delivery calls that use the same keywords. Each script marks
the **trigger utterance**, the first sentence after which a careful listener should be alarmed.

**Procedure.** Two team members read each script as a phone call on speakerphone, with the SaqBol
app listening on a second phone. The app logs timestamps for each recognised fragment, each server
response and the alert.

**Measures**

| Measure | Definition | Target |
|---|---|---|
| STT word error rate | Against the script text, per language | Report; investigate fallback if WER > 30% |
| Detection rate | Share of scam calls that raise an alert | ≥ 0.90 |
| False alarm rate | Share of benign calls that raise an alert | ≤ 0.10 |
| Time to alert | From the end of the trigger utterance being recognised to the alert on screen | p95 < 3 s (NFR-1) |
| Early detection | Share of the call elapsed when the alert fires | Report (compare with Cho & Seo, 2025) |

**Conditions.** Quiet room, phones 30 cm apart, Wi-Fi to the demo server. We also run one noisy
repetition. Device models, OS versions and the network are recorded with the results.

## 9.6 Performance

- **SMS check latency:** 100 sequential and 100 concurrent (10 workers) requests to
  `/api/v1/sms/check` with a fixed set of messages on the demo server. Report p50, p95 and p99 from
  the client side, plus backend and ML timings (`detections.latency_ms`, Prometheus).
  Target: p95 < 1 s.
- **Inbox scan:** time to check 100 messages through `/sms/check/batch`.
- **Conditions:** the deployment configuration (Docker Compose or k3s), CPU and RAM of the server,
  model version and network are recorded for every run.

## 9.7 Usability evaluation

- **Participants:** ≥ 5, including at least 2 people aged 55+ and 1 relative who would set it up
  for someone else (matches the interview profiles in [relevance evidence](02-relevance-evidence.md)).
- **Tasks:** (1) check a suspicious SMS; (2) explain in their own words why it is dangerous and
  what to do; (3) turn on automatic protection; (4) run live analysis during a staged call;
  (5) mark a false alarm.
- **Measures:** task success without help, time on task, errors, SUS questionnaire (target ≥ 68),
  and comprehension of the explanation in task 2.
- **Explanation check (assumption A4):** half of the participants first see a verdict card without
  trigger phrases or advice, the other half with them. We compare the answers to task 2.

## 9.8 Acceptance

A requirement is accepted when its criterion in [Requirements](06-requirements.md) is met by the
listed verification method. Results are recorded per pre-defense in
`docs/results/` (test report, ML metrics, latency and usability results) and linked from the
YouTrack task that closes the requirement.

## 9.9 Schedule

| When | What |
|---|---|
| Pre-defense 1 (24 Oct 2026) | Plan, current baseline (9.3) |
| Pre-defense 2 | Real test set frozen; XLM-R vs baseline; API integration tests in CI; first latency measurements |
| Final pre-defense | Call evaluation (9.5), performance (9.6), usability study (9.7), full results |
