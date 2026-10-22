# 9. Verification and Evaluation Plan

## 9.1 What we must demonstrate

The project aim ([proposal](01-project-proposal.md#13-aim)) is reached when we can show four things:

| Claim | Evidence | Section |
|---|---|---|
| The system works as specified | Every *Must* requirement passes its acceptance criterion | 9.2, 9.8 |
| It detects authentic received scam messages well | Recall (scam) ≥ 0.90 at FPR ≤ 0.10 on the **planned authentic held-out test set**, and better than the baseline evaluated on the same split | 9.3, 9.4 |
| It warns in time | SMS p95 < 1 s; call alert < 3 s after the trigger phrase is recognised | 9.5, 9.6 |
| Users understand and accept it | Usability test: task success, SUS ≥ 68, and the explanation is understood | 9.7 |

## 9.2 Test levels

| Level | What | Tools | Exists today | To add |
|---|---|---|---|---|
| Unit | Token issuing / validation, mock classifier (Go); rule engine and pipeline thresholds (Python); highlighted triggers and locale behavior (Flutter); verdict labels (web) | `go test`, `pytest`, `flutter test`, `vitest` | Test sources exist in all four components; record executed counts and results against the submitted commit, rather than combining counts from pending branches | Store layer, reputation updates, batch check |
| API integration | Every `/api/v1` endpoint: status codes, validation, auth (401), admin role (403), ownership (404 on another user's message) | Go `httptest` + mock classifier + test Postgres | — | SAQ-34 |
| End-to-end | Fresh clone → `docker compose up` → register → SMS check → verdict `scam` with `model_version` | Smoke script from `CLAUDE.md` | Manual | Run in CI on pull requests |
| ML evaluation | Protocol in 9.4 | `training/evaluate.py`, Colab notebook | Partial (9.3) | SAQ-22 |
| Real-time call | Protocol in 9.5 | Scripted calls, device logs | — | SAQ-23, SAQ-24 |
| Performance | Protocol in 9.6 | `hey` or a Go/Python load script; backend Prometheus metrics | — | SAQ-24 |
| Device | Android: SMS permission, inbox scan, incoming SMS notification, call screening on at least 2 devices (Android 10+); iOS: manual check; live-call path subject to per-locale capability tests | Physical devices | No versioned physical-device result is recorded here; Asylbek has no suitable Android phone available as of 22 October | Borrowed devices and a checklist per release, including unavailable-locale behaviour |
| Usability | Protocol in 9.7 | SUS questionnaire, observation notes | — | SAQ-30 |
| Security | Secrets not in Git, JWT secrets required, rate limit, admin role, input limits | Code review, `gitleaks`, manual API checks | Partly | Before each pre-defense |

CI builds, lints and runs the unit tests of all four apps on every push and pull request since
PR #17 (SAQ-33). Before it, at `main` `91862dc`, CI only built and linted the components.

## 9.3 Current baseline

The baseline approach is `baseline-tfidf-logreg-v1`: TF-IDF word 1–2-grams and Logistic Regression
with balanced class weights, combined with the rule engine. Its model-version name alone does
not identify a particular training corpus or saved model artifact.

**Version boundary.** The reviewed main checkout `91862dc` contains **2,248** training rows:
2,020 template-generated Kazakh/Russian examples, 184 unique examples from the
`Yerassyl04/Spam-kazakh` student course project, and 44 Russian seeds written by the team.
The latter two sources form the **228 course/seed examples**, of which 47 are labelled `scam`.
The experiment code calls this source-filtered cohort "non-template"; that label establishes
neither human authorship of the 184 imported examples nor receipt as an SMS. None of the 228 has
established provenance as an SMS somebody actually received. They are not the authentic test
set proposed in §9.4.

The table below preserves the **revised author-reported exploratory results** in
[PR #25 at `37305a21be70045ef60fb8e6d8077b6aea99690b`](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/37305a21be70045ef60fb8e6d8077b6aea99690b/docs/09-verification-plan.md#93-current-baseline),
reported on 22 October 2026. That branch includes PR #14's expanded **4,457-row** corpus: the
2,248 originals plus 2,209 deduplicated English translations. It also contains revised grouping
and an evaluator that are **not present in main `91862dc`**. These numbers supersede the earlier
documented table; they were not rerun or independently reproduced for this documentation change
and must not be attributed to the 2,248-row checkout or presented as real-world performance.

| Protocol | n | Precision | Recall (scam) | F1 | FPR | ROC-AUC |
|---|---|---|---|---|---|---|
| A. 5-fold CV grouped by connected original/translation/template family; all expanded-corpus rows; model only, threshold 0.5 | 4,457 | 0.935 | 0.958 (0.95–0.97) | 0.946 | 0.053 | 0.976 |
| B. Same predictions as A, scored only on the non-template examples | 228 | 1.000 | 0.468 (0.32–0.62) | 0.638 | 0.000 | 0.942 |
| C1. Train on synthetic rows outside the test examples' families; test on all non-template examples; model only, threshold 0.5 | 228 | 0.677 | 0.447 (0.30–0.60) | 0.538 | 0.055 | 0.821 |
| C2. As C1; configured threshold 0.8; model only | 228 | 1.000 | 0.021 (0.00–0.06) | 0.042 | 0.000 | 0.821 |
| C3. As C1; combined pipeline: max(model, rules), threshold 0.8 | 228 | 1.000 | **0.511 (0.36–0.66)** | **0.676** | 0.000 | 0.876 |

The author reports 95% bootstrap intervals for scam recall: 2,000 resamples, seed 42, using the
labelled scam rows of each cohort (47 for B and C1–C3). The binary task is `scam` versus the rest;
`suspicious` and `safe` are both in the negative class.

**Reproduction and isolation.** The pinned branch's
[evaluator](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/37305a21be70045ef60fb8e6d8077b6aea99690b/saqbol-ml/training/evaluate_real.py)
defines A–C3 and can be invoked as `python training/evaluate_real.py` from `saqbol-ml/` in that
revision after installing its dependencies. It groups connected source/translation/template
families and explicitly excludes C1–C3 test families from training. Its variable name `real`
or source-prefix test identifies the non-template cohort; it does not authenticate received SMS.
These safeguards must be assessed against the data and retained split records; they are not a
claim that all semantic duplicates are detected. To accept a reproduced result, record the exact
commit, input-data hash, model/rule configuration, split membership, overlap checks, environment,
command and output. Running main's older trainer does not reproduce this whole table.

**Reading the table**

- In the reported experiments, the template-heavy full corpus scores much higher than the
  non-template diagnostic (A versus B). C1–C3 use a different training protocol. This motivates
  testing on authentic data; it does not quantify the gap to real-world use.
- At threshold 0.8 the model alone rarely marks these course/seed examples as scam (C2); the
  combined model/rules diagnostic performs differently (C3). Neither establishes field quality.
- Only 47 examples are labelled scam, so the diagnostic is small and its intervals are wide.
  Collecting authentic messages with documented provenance (SAQ-19) remains a priority.

**C3 is an exploratory diagnostic reference**, not the final real-world baseline score. For the
success comparison, rerun the baseline and each candidate on the same new held-out authentic
test set under §9.4; never compare a new model's authentic-data score to C3's different cohort.

## 9.4 ML experiment protocol

**Data split**

1. Collect **at least 500 authentic received messages in total, including at least 150 labelled
   scams** (SAQ-19). Record collection permission, source/provenance and anonymisation, and label
   them using the agreed guideline (SAQ-20). A second member independently re-labels at least
   20% (at least 100 at the minimum collection size); report Cohen's κ and resolve disagreements.
   The existing 228 course/seed examples do not count toward this collection target.
2. Freeze an **authentic held-out test set of about 30% of the collected messages**, stratified by
   label, language and category where counts permit. At the minimum collection size this is
   about 150 total test messages, not a promise of 150 test scams. Freeze it before model/rule
   tuning; never use its examples or translations for training or threshold selection.
3. Use the remaining authentic messages plus allowed templates/translations for training.
   Explicitly link each translation to its original and keep connected template/near-duplicate
   families in one partition. Validate and export split membership and overlap checks. Main's
   current text-normalisation grouping alone does not establish source/translation isolation;
   the newer implementation referenced in §9.3 still needs verification for each dataset.
4. Select thresholds on a validation split from the training side, not on the held-out test set.
   Preserve the split, dataset hash and configurations so baseline and candidate runs are comparable.

**Models compared**

| Model | Role |
|---|---|
| TF-IDF + LR (+ rules) | Baseline approach from C3, rerun on the new shared authentic-data split |
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

**Success criterion (NFR-2).** The selected model reaches recall ≥ 0.90 at FPR ≤ 0.10 on the planned
authentic held-out test set, and its recall CI lies above the baseline's on that same split.
This criterion is not met by any claim about the 228-example diagnostic. If no model reaches
0.90, we report the best achieved point and the precision–recall trade-off honestly.

## 9.5 Real-time call evaluation

**Status and test boundary.** These are planned evaluations. The reviewed main mobile code at
`91862dc` requests Russian (`ru_RU`); Kazakh speech recognition has not been demonstrated.
Classifying typed or prepared Kazakh transcripts can test the inference path without ASR, but
cannot demonstrate Kazakh audio recognition, capture of a telephone conversation, or end-to-end
call detection. Keep transcript-only and audio-to-alert results in separate reports.

**Capability check before audio testing.** For each device, record OS, recogniser/provider,
available locale IDs and network/offline mode. Verify that the requested Kazakh or Russian locale
is actually supported and selected; an app-interface language switch is not proof. If no supported
locale exists or recognition cannot start, record **unavailable** and require a visible failure
message or an explicitly selected, labelled fallback (for example, manual transcript input).
Do not silently switch Kazakh speech to Russian or count a transcript fallback as a successful
audio test. Report unavailable devices/scenarios separately so supported-subset scores do not
imply full coverage. Device APIs may use remote recognition services; record the processing
destination and consent rather than assuming audio stays on the device.

**Material.** 20 scam scripts and 20 benign scripts, 10 + 10 in each language. Scam scripts follow
the documented local schemes (fake bank, eGov → "Стоп-кредит", fake operator, police). Benign
scripts include real-sounding bank and delivery calls that use the same keywords. Each script marks
the **trigger utterance**, the first sentence after which a careful listener should be alarmed.

**Procedure.** First inject prepared transcripts to check classification and the alert interface.
For devices/locales that pass the capability check, two team members then read each script as a
staged phone call on speakerphone, with the SaqBol app listening on a second phone. Record actual
utterances for the reference transcript and log timestamps for speech, recognised fragments,
server responses and the alert. The second-phone arrangement is a controlled prototype condition,
not proof of direct access to live-call audio on one phone.

**Measures**

| Measure | Definition | Target |
|---|---|---|
| STT word error rate | Against the reference transcript of what was actually spoken, per supported device/locale; report capability failures separately | Report; investigate fallback if WER > 30% |
| Detection rate | Share of scam scenarios that raise an alert; report transcript-only and audio-to-alert paths separately with denominators and unavailable cases | ≥ 0.90 target for the intended audio path |
| False alarm rate | Share of benign scenarios that raise an alert, separately for each test path | ≤ 0.10 |
| Time to alert | From the end of the trigger utterance being recognised to the alert on screen | p95 < 3 s (NFR-1) |
| Speech-to-alert delay | From the spoken trigger ending to the alert; includes recognition and network delays | Report separately from the post-recognition target |
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

A requirement is accepted when its criterion in the [requirements draft](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/46a3364f95f81ab53cd0bc5b658a921ec53547db/docs/06-requirements.md)
(PR #8, pending review/merge) is met by the
listed verification method. Results are recorded per pre-defense in
`docs/results/` (test report, ML metrics, latency and usability results) and linked from the
YouTrack task that closes the requirement.

## 9.9 Schedule

| When | What |
|---|---|
| Pre-defense 1 (24 Oct 2026) | Plan; versioned, author-reported exploratory baseline (9.3); explicit data and Kazakh ASR limitations |
| Pre-defense 2 | Authentic test set frozen; XLM-R vs baseline on that split; API integration tests in CI; first latency measurements |
| Final pre-defense | Call evaluation (9.5), performance (9.6), usability study (9.7), full results |
