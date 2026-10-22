# 10. Project Management and Risks

## 10.1 Team and responsibilities

| Member | Group | Responsibilities |
|---|---|---|
| **Danial Myrzatayev** | SE-2412 | Team lead; backend (Go); ML service, data pipeline and experiments; infrastructure and CI; architecture and documentation |
| **Asylbek Abdibay** | SE-2427 | Mobile app (Flutter) features; web dashboard; user research (interviews, usability test); real-data collection; testing on devices; code review |

**Supervisor:** Zhibek Nurzhanovna Sarsenova. The supervisor is not a team member and reviews key
deliverables and decisions at the checkpoints in §10.3; feedback is logged in
[Supervisor feedback](11-supervisor-feedback.md).

## 10.2 Tools and workflow

| What | Where |
|---|---|
| Code, documents, diagrams | GitHub: https://github.com/DanialMyrzatayevMuratovich/saqbol |
| Tasks | YouTrack project [`SAQ`](https://saqbol.youtrack.cloud/issues/SAQ), [Kanban board](https://saqbol.youtrack.cloud/agiles/204-1/current) |
| CI | GitHub Actions (`.github/workflows/ci.yml`) |
| Model training | Google Colab (`saqbol-ml/training/colab_train_xlmr.ipynb`) |

**Workflow**

1. Every meaningful piece of work is a YouTrack task. It has an assignee, an expected outcome,
   acceptance criteria and a due date.
2. A branch is named after the task, e.g. `SAQ-21-xlmr-finetune`.
3. Commit messages start with the task ID: `SAQ-21: Add XLM-R fine-tuning notebook`.
4. Changes go to `main` only through a pull request. The PR follows the template in
   `.github/pull_request_template.md`: what changed, task link, how it was checked.
5. The other team member reviews the PR before merging. The supervisor reviews selected PRs at
   checkpoints.
6. The YouTrack task links to the PR and is closed only when its acceptance criteria are met.
7. Each submission is tagged: `pre-defense-1`, `pre-defense-2`, `final-pre-defense`. Tags are
   never moved.

## 10.3 Milestones

| # | Milestone | Target date | Content |
|---|---|---|---|
| M0 | Working prototype | 2026-07-19 ✅ | Backend, ML baseline, mobile and web prototypes, Docker Compose (initial commits) |
| M1 | **Pre-defense 1** | **2026-10-24** | Analysis and design documentation, current baseline, YouTrack plan (tag `pre-defense-1`) |
| M2 | Real data and evaluation harness | 2026-11-30 | ≥ 500 real messages, frozen real test set, integration tests in CI, TLS on the demo server |
| M3 | **Pre-defense 2** | date set by the department | XLM-R vs baseline, STT WER and latency measurements, consent screen (tag `pre-defense-2`) |
| M4 | Feature-complete | before the final pre-defense | iOS filter extension, push notifications, usability study |
| M5 | **Final pre-defense** | date set by the department | Full results, thesis draft, demo (tag `final-pre-defense`) |

## 10.4 Task plan

Priorities follow YouTrack: Critical, Major, Normal, Minor. The table mirrors the YouTrack project.
YouTrack is the source of truth for the current state.

### M1 — Pre-defense 1

| ID | Task | Assignee | Priority | Due |
|---|---|---|---|---|
| SAQ-1 | Project proposal and scope | Danial | Critical | 2026-10-24 |
| SAQ-2 | Interview guide and data-handling rules | Danial | Critical | 2026-10-24 |
| SAQ-3 | Conduct 3–5 user interviews and record findings | Asylbek | Critical | 2026-10-24 |
| SAQ-4 | Literature review (≥ 12 sources, ≥ 8 scientific) | Danial | Critical | 2026-10-24 |
| SAQ-5 | Existing systems comparison | Danial | Critical | 2026-10-24 |
| SAQ-6 | Technology comparison | Danial | Major | 2026-10-24 |
| SAQ-7 | Requirements and acceptance criteria | Danial | Critical | 2026-10-24 |
| SAQ-8 | Prototype description and API examples | Danial | Major | 2026-10-24 |
| SAQ-9 | Architecture diagrams with editable sources | Danial | Critical | 2026-10-24 |
| SAQ-10 | Verification and evaluation plan, exploratory baseline with provenance limits | Danial | Critical | 2026-10-24 |
| SAQ-11 | Project plan, risks, PR template | Danial | Major | 2026-10-24 |
| SAQ-12 | Complete the README | Danial | Critical | 2026-10-24 |
| SAQ-13 | Review the pre-defense-1 pull requests | Asylbek | Critical | 2026-10-24 |
| SAQ-14 | Supervisor review of pre-defense-1 deliverables | Danial | Critical | 2026-10-24 |
| SAQ-16 | Tag the pre-defense-1 submission | Danial | Critical | 2026-10-24 |
| SAQ-35 | Capture prototype screenshots (mobile and web) | Danial | Major | 2026-10-24 |
| [SAQ-86](https://saqbol.youtrack.cloud/issue/SAQ-86) | Correct speech-recognition and dataset-provenance claims across pre-defense materials | Asylbek | Critical | 2026-10-24 |

### M2 — Real data and evaluation harness

| ID | Task | Assignee | Priority | Due |
|---|---|---|---|---|
| SAQ-15 | Hands-on test of Truecaller and Who Calls with KZ/RU scam SMS | Asylbek | Normal | 2026-11-07 |
| SAQ-17 | Commit pending ML data pipeline and rule updates | Danial | Major | 2026-10-31 |
| SAQ-18 | Commit pending mobile localisation (KZ/RU) and app icon | Danial | Major | 2026-10-31 |
| SAQ-19 | Collect ≥ 500 real messages (≥ 150 scams) | Asylbek | Critical | 2026-11-30 |
| SAQ-20 | Dataset card and labelling guideline | Danial | Major | 2026-11-07 |
| SAQ-22 | Evaluation harness: frozen real test set, bootstrap CIs, slices | Danial | Major | 2026-11-14 |
| SAQ-26 | Store the model version in `detections` | Danial | Minor | 2026-11-14 |
| SAQ-29 | TLS and domain for the demo server | Danial | Major | 2026-11-30 |
| SAQ-31 | In-app consent screen for message processing | Asylbek | Major | 2026-11-30 |
| SAQ-33 | Run unit tests in CI | Danial | Major | 2026-10-31 |
| SAQ-34 | Backend API integration tests | Danial | Major | 2026-11-14 |
| SAQ-36 | Bug: incoming-SMS check does not run in the Android release build | Danial | Major | 2026-11-07 |
| SAQ-37 | Bug: call warning is lost because the lookup is cancelled | Danial | Major | 2026-11-07 |
| SAQ-38 | Guard and history usability issues | Asylbek | Normal | 2026-11-21 |

### M3 — Pre-defense 2

| ID | Task | Assignee | Priority | Due |
|---|---|---|---|---|
| SAQ-21 | Fine-tune XLM-RoBERTa and compare with the baseline | Danial | Critical | 2026-12-15 |
| SAQ-23 | STT word error rate test in Kazakh and Russian on target phones | Asylbek | Major | 2026-12-01 |
| SAQ-24 | Latency benchmark: SMS p95 and call time-to-alert | Danial | Major | 2026-12-08 |
| SAQ-25 | Kazakh advice texts; filter single-word triggers | Asylbek | Normal | 2026-12-08 |

### M4–M5 — Feature-complete and final

| ID | Task | Assignee | Priority |
|---|---|---|---|
| SAQ-27 | Remote push notifications (FCM) | Asylbek | Normal |
| SAQ-28 | iOS SMS filter extension | Asylbek | Normal |
| SAQ-30 | Usability test with ≥ 5 participants (SUS) | Asylbek | Major |
| SAQ-32 | History filters by verdict and date | Asylbek | Minor |

## 10.5 Risks

Probability (P) and impact (I): H = high, M = medium, L = low.

| # | Risk | P | I | Mitigation | Owner |
|---|---|---|---|---|---|
| R1 | No authenticated received-SMS evaluation cohort; 47 scam labels among 228 course/seed examples do not establish real-world quality | H | H | Consent-based collection (SAQ-19/50), provenance records and held-out evaluation; keep authored examples and public warnings distinct from received SMS | Asylbek |
| R2 | Model fails the recall target on real data | M | H | Rules as a safety net; XLM-R; threshold tuning on validation data; honest reporting of the trade-off | Danial |
| R3 | Kazakh speech recognition is not implemented/verified: the current voice path selects `ru_RU`; OS recognition may use a remote service | H | H | Verify supported locales and select Kazakh explicitly before WER testing (SAQ-23); present unsupported-language behavior clearly; evaluate an alternative recogniser and its data handling if needed | Asylbek |
| R4 | Users won't put calls on speakerphone (assumption A3) | M | M | Check in interviews; offline transcript analysis (FR-13) as an alternative; focus the evaluation on the SMS module | Asylbek |
| R5 | Google Play policy restricts SMS permissions to default SMS apps | H | M | The diploma demo uses a sideloaded APK; manual check and share-to-app work without SMS permission | Danial |
| R6 | False alarms reduce trust | M | M | "Suspicious" band below the scam threshold; feedback button; FPR as a constraint in evaluation | Danial |
| R7 | Personal data in collected messages | M | H | Consent, anonymisation before storing, no real personal SMS in the public repository | Both |
| R8 | Free Colab GPU limits or disconnects | M | L | Checkpoints to Google Drive; `xlm-roberta-base` instead of large | Danial |
| R9 | Two-person team, parallel coursework | M | M | Scope fixed in the proposal; MoSCoW priorities; Could items dropped first | Danial |
| R10 | iOS platform limits (no SMS access, no call screening) | H | L | Documented as out of scope; iOS covers manual check and live call | Asylbek |

## 10.6 Dependencies

| Dependency | Needed for | Status |
|---|---|---|
| Interview participants (pensioners, relatives, young adults) | SAQ-3, SAQ-30 | To recruit |
| Supervisor availability for reviews | SAQ-14 and each milestone | To agree with the supervisor |
| Google Colab (free T4 GPU) | SAQ-21 | Available |
| Android devices (Android 10+) for testing; one iPhone | SAQ-23, SAQ-45/46/65, device tests | Asylbek confirmed no suitable Android phone on 22 October; borrowed devices and a second caller/SMS sender needed; emulator checks do not replace physical tests |
| OS speech-recognition locales and provider behavior | Live call module | Russian locale selected; Kazakh selection/support and local/remote processing must be verified per device |
| Demo server (VPS) and a domain | SAQ-29, final demo | To confirm |
| Public dataset `Yerassyl04/Spam-kazakh` | Exploratory course-example cohort, not authenticated received SMS | 184 deduplicated examples used; provenance/permission follow-up in SAQ-20/83; do not count these as collected real traffic |
