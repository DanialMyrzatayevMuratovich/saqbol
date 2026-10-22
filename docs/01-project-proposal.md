# 1. Project Proposal

| | |
|---|---|
| **Project title** | Development of an Intelligent System for Detecting Fraudulent SMS Messages and Telephone Calls in the Kazakh and Russian Languages Using Machine Learning Methods |
| **Short name** | SaqBol (*сақ бол* — Kazakh for "stay alert") |
| **Team** | Danial Myrzatayev (SE-2412), Asylbek Abdibay (SE-2427) |
| **Supervisor** | Zhibek Nurzhanovna Sarsenova |
| **Repository** | https://github.com/DanialMyrzatayevMuratovich/saqbol |
| **Task tracker** | YouTrack project [`SAQ`](https://saqbol.youtrack.cloud/issues/SAQ) |

## 1.1 Problem statement

Telephone and SMS fraud based on social engineering is one of the most widespread
cybercrimes in Kazakhstan (figures and sources: [Relevance evidence](02-relevance-evidence.md)).
Typical schemes are local: a fake "bank security service" asking for an SMS code, fake
police or prosecutors pressuring the victim to move money to a "safe account", fake Kaspi
payment links, fake prizes and compensations, and phishing domains imitating `kaspi.kz`,
`egov.kz` or banks.

Existing protection does not cover this situation well:

- Caller-ID and spam-blocking apps rely mainly on number blacklists. Fraudsters change
  numbers quickly, and a blacklist says nothing about *what* the caller or message is asking for.
- Content-aware scam detectors are built mostly for English and for other markets
  (comparison: [Existing systems](04-existing-systems-comparison.md)).
- Kazakh is a low-resource language. The public Kazakh spam corpus that exists was translated
  from English advertising spam, and the published Kazakhstan fraud datasets are either a
  189-message pilot or synthetic. These reviewed sources do not establish a sufficiently large,
  documented authentic bilingual fraud-SMS corpus for our evaluation
  ([Literature review](03-literature-review.md#35-gaps-the-project-addresses)).
- A victim under pressure from a caller rarely stops to analyse the conversation. A warning
  is useful only if it arrives *during* the message or the call and explains *why* it is dangerous.

## 1.2 Target users

| User group | Need |
|---|---|
| **Mobile user (primary)**: an adult resident of Kazakhstan who receives SMS and calls in Kazakh and/or Russian | Get a clear verdict and an explanation before acting on a suspicious message or call |
| **Relative / guardian**: helps an elderly or less tech-savvy family member | Install and configure protection for someone else (older people are the most vulnerable group) |
| **Administrator / analyst**: operates the service | Monitor detection quality, review flagged messages, track model versions |
| *Bank or mobile operator (future, out of scope)* | *Integrate the detector through an API* |

## 1.3 Aim

Design, implement and evaluate a platform (mobile app, backend, ML service and web dashboard)
that detects fraudulent SMS and phone conversations in Kazakh and Russian with high recall,
and explains each verdict to the user in time to prevent the loss.

## 1.4 Objectives

| # | Objective | Measurable target |
|---|---|---|
| O1 | Build a labelled Kazakh/Russian corpus of authenticated received messages, keeping collected, course-example, seed, template and translated data distinct | Collect ≥ 500 messages in total, including ≥ 150 scams; freeze about 30% for a held-out test set before tuning, as specified in §9.4; document provenance and labelling rules |
| O2 | Train and compare detection models: TF-IDF baseline vs fine-tuned XLM-RoBERTa | Metrics on a **real-only** held-out test set; target recall (scam) ≥ 0.90 at false-positive rate ≤ 0.10 |
| O3 | Implement the backend API and ML inference service | SMS check p95 latency < 1 s end-to-end on the demo server |
| O4 | Implement real-time analysis of a phone conversation (speech-to-text → sliding-window classification) | Verify recogniser availability and selected locale per language before measuring WER; report unsupported Kazakh recognition explicitly; target alert < 3 s after the trigger phrase is recognised |
| O5 | Implement a cross-platform mobile app (Android and iOS) with explanation of verdicts | All *Must* requirements pass their acceptance criteria ([requirements draft in PR #8](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/46a3364f95f81ab53cd0bc5b658a921ec53547db/docs/06-requirements.md), pending review/merge) |
| O6 | Implement a web dashboard for metrics, flagged messages and model versions | Admin scenarios UC-12 … UC-14 pass |
| O7 | Evaluate the system with users and document the scientific results | Usability test with ≥ 5 participants; experiment report in the thesis |

## 1.5 Expected outcomes

1. A working, deployable system: Flutter app, Go backend, Python ML service, Next.js dashboard,
   started with one `docker compose` command (Kubernetes/k3s manifests included).
2. A corpus of authentic Kazakh/Russian scam messages (with a separate synthetic training part)
   and a documented collection and labelling protocol.
3. An experimental comparison of a classical baseline and a multilingual transformer on real
   Kazakh/Russian data, with honest reporting of how synthetic data affects the metrics.
4. A real-time call-analysis pipeline for a low-resource language, measured for latency.
5. The diploma thesis and a defence demo.

## 1.6 Scope

**In scope**

- Classification of SMS text in Kazakh, Russian and mixed Kazakh–Russian into
  *safe / suspicious / scam*, with a probability.
- Scam category (fake bank, fake police, Kaspi scam, fake prize, phishing, other), trigger-phrase
  highlighting and a short piece of advice.
- Sender-number reputation built from verdicts and user feedback.
- Android: scanning the SMS inbox and incoming SMS, warning on incoming calls from high-risk
  numbers (with user permission).
- Live call analysis in speakerphone mode: OS speech-recognition service → transcript → backend
  → classifier → alert. The current mobile implementation requests `ru_RU`; Kazakh speech support
  is pending. Recognition may use an OS-provider network service; offline processing is not enforced.
- User feedback ("confirmed scam" / "false alarm"), check history, Kazakh and Russian interface.
- Web dashboard for administrators.
- Containerised deployment (Docker Compose, Kubernetes manifests), CI on GitHub Actions.

**Out of scope**

- Recording or intercepting the cellular call audio stream. Android 10+ and iOS do not allow it,
  so the app works through the speakerphone and the microphone.
- Automatic reading of SMS on iOS (the platform does not allow it). Only the iOS SMS filter
  extension is planned.
- Voice deepfake detection, messengers (WhatsApp, Telegram), e-mail.
- Integration with real banks or mobile operators.
- Blocking calls or messages. SaqBol warns and explains; the user decides.

## 1.7 Engineering complexity

- **Distributed system**: four applications in three languages (Dart, Go, Python, plus TypeScript
  for the web), connected by REST, WebSocket and gRPC.
- **Machine learning for a low-resource language**: data collection from scratch, code-switching,
  separation of real and synthetic data, baseline vs transformer, explainability.
- **Real-time constraints**: streaming transcript over WebSocket, sliding-window classification,
  end-to-end latency budget.
- **Mobile platform integration**: Android `CallScreeningService`, SMS inbox and broadcast access,
  background work, notifications, iOS platform limits.
- **Security and privacy**: JWT with refresh tokens, role-based admin access, rate limiting,
  handling of sensitive message text, secrets kept out of the repository.
- **Operations**: Docker, Kubernetes/k3s manifests, Prometheus metrics, CI pipeline.

## 1.8 Current status (October 2026)

| Area | Status |
|---|---|
| Backend (Go): auth, SMS check (single and batch), number reputation, feedback, history, admin, WebSocket call stream | Implemented |
| ML service: TF-IDF + LogReg baseline with rule engine, gRPC + REST | Implemented; XLM-RoBERTa notebook prepared, not yet trained |
| Mobile (Flutter): SMS check, guard, live call analysis, message history | Prototype implementation available; Russian recognition locale requested, Kazakh speech unsupported/unverified; physical-device checks pending |
| Web dashboard (Next.js): metrics, flagged messages, model versions | Implemented |
| Dataset in reviewed `main` | 2,248 rows: 2,020 template examples, 184 student-project examples and 44 team-authored seeds; no verified received-SMS evaluation cohort |
| Dataset in the unmerged ML branch | 4,457 rows including 2,209 English translations; a different version, not evidence of authentic received SMS |
| Analysis and design documentation | This pre-defense |
| Primary user evidence | Two informal conversations recorded (§2.3.4); structured interviews and client agreement pending |
| Supervisor review | Feedback pending; the log does not establish that review has happened |

These are prototype and planning deliverables for 24 October, not a claim that all final-project
objectives have been achieved. See the pinned [implementation/evidence record](implementation-evidence.md)
and [Project management](10-project-management.md) for the remaining work.
