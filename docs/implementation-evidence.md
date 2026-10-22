# Implementation and evidence status for pre-defense 1

Task: [SAQ-86](https://saqbol.youtrack.cloud/issue/SAQ-86). Reviewed on 22 October 2026.
This record corrects capability and dataset claims; it does not implement a new recogniser,
collect SMS, or report new model experiments. The project title and bilingual research aim remain
unchanged. A complete application is not required for the 24 October analysis/design submission.

## Versions covered

| Material | Pinned version | Meaning |
|---|---|---|
| Reviewed `main` baseline | [`91862dc`](https://github.com/DanialMyrzatayevMuratovich/saqbol/tree/91862dcca5d218887db7fd57fc1e88c4f3d2bf21) | Starting point for this documentation correction; 2,248 training rows |
| Requirements draft, PR #8 | [`46a3364`](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/46a3364f95f81ab53cd0bc5b658a921ec53547db/docs/06-requirements.md) | Unmerged draft; its updated FR-10 already distinguishes Russian recognition from pending Kazakh support |
| ML changes, PR #14 | [`7f7dec9`](https://github.com/DanialMyrzatayevMuratovich/saqbol/tree/7f7dec98aee586ae3f46ddec294af3ce26d723bc/saqbol-ml) | Unmerged data/evaluation implementation with English translations and revised grouping |
| Dataset card, PR #25 | [`37305a2`](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/37305a21be70045ef60fb8e6d8077b6aea99690b/docs/12-dataset-card.md) | Stacked on PR #14; source of the team's provenance clarification and revised, author-reported evaluation table |
| Mobile redesign, PR #20 | [`f361a8f`](https://github.com/DanialMyrzatayevMuratovich/saqbol/tree/f361a8f4be8712851442adaf14b1f9144cac8198/saqbol-mobile) | Unmerged; selecting Kazakh still requests Russian speech recognition |

These references identify reviewed snapshots, not a claim that their changes have merged or that
all their acceptance checks passed. Recheck the submission commit and record its tag before handing
materials to the committee. Do not present an aggregate preview branch as reviewed `main`.

## Speech recognition and transcript classification

| Layer | Evidence | Correct interpretation |
|---|---|---|
| SMS / transcript text | The backend accepts text and calls the ML classifier | Kazakh text inference can be evaluated independently of a microphone or recogniser; its real-world quality still needs an authentic test set |
| Mobile recogniser in `main` | [`VoiceController._startListening`](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/91862dcca5d218887db7fd57fc1e88c4f3d2bf21/saqbol-mobile/lib/src/features/voice/voice_controller.dart#L104) requests `ru_RU` | A Russian recognition path is implemented; neither successful Kazakh recognition nor a Kazakh accuracy result follows from it |
| Localised mobile branch | [`PR #20 voice controller`](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/f361a8f4be8712851442adaf14b1f9144cac8198/saqbol-mobile/lib/src/features/voice/voice_controller.dart#L122) selects `en_US` for English and `ru_RU` otherwise | Kazakh UI selection does not select a Kazakh recogniser |
| Audio processing | The app uses the OS speech service and does not enforce offline recognition | SaqBol sends transcript text to its backend; the OS provider may process audio remotely. Do not promise that audio always stays on the phone |
| History | Calls are stored in `call_sessions`; `/history` reads `messages` | Server persistence of call transcripts is distinct from the currently visible message-check history |

Before claiming Kazakh live-speech support, enumerate the target device's supported locales,
select a Kazakh locale explicitly, and record the recogniser/provider, device, OS and network mode.
If no suitable recogniser is available, show an unsupported-language explanation and offer a
clearly labelled transcript-text path or evaluate an alternative recogniser. Do not silently use
Russian and report the result as Kazakh recognition. Only then measure Kazakh WER and end-to-end
call detection/latency using the [verification protocol](09-verification-plan.md#95-real-time-call-evaluation).
These are acceptance steps still to perform, not completed checks.

The [speech_to_text package documentation](https://pub.dev/packages/speech_to_text) describes
device-dependent language availability and possible remote recognition. The
[Android SpeechRecognizer reference](https://developer.android.com/reference/android/speech/SpeechRecognizer)
also distinguishes the default speech service from an explicitly on-device recogniser.

## Dataset provenance and versions

| Source group | Reviewed `main` | PR #25 snapshot | Provenance interpretation |
|---|---:|---:|---|
| Project template examples | 2,020 | 2,020 | Generated examples; not observed SMS traffic |
| `Yerassyl04/Spam-kazakh` examples | 184 | 184 | Deduplicated examples from a student-project repository; received-message provenance and authorship are not verified |
| Team seed messages | 44 | 44 | Written by the team to model scenarios; not collected received SMS |
| Deduplicated English translations | 0 | 2,209 | Derived examples in the unmerged ML branch; not independent observations |
| **Total training rows** | **2,248** | **4,457** | Two different dataset versions |

The 184 course examples and 44 seeds form the 228-row diagnostic cohort, with 47 `scam`,
75 `suspicious` and 106 `safe` labels. A `source` value without the prefix `synthetic` does not
prove that a row is authentic, independently human-written, or a message a participant received.
No authenticated received-SMS test cohort has been established by these files.

The values in [§9.3](09-verification-plan.md#93-current-baseline) are explicitly attributed to the
revised PR #25 experiment snapshot. For example, C3's 0.511 recall concerns the 228 course/seed
examples. It is not a claim of 51.1% recall on actual user SMS or a result independently rerun by
this documentation change. Preserve the experiment code/data revision, exclusion rules, thresholds
and prediction outputs when reproducing it. The final real-world comparison must use a separately
collected, consented and held-out cohort, with source families and translations kept out of its
training partition.

## Evidence still required from people

| Deliverable | Actual status | What completes it |
|---|---|---|
| User relevance evidence | No completed interviews or substantive client agreement supplied | Conduct 3–5 discussions using the [guide](02-relevance-evidence.md#23-interviews-with-potential-users), record anonymised findings and resulting requirement decisions, or document a substantive actual-client agreement |
| Supervisor feedback | No substantive feedback supplied | Obtain the supervisor's review of key deliverables and record comments, decisions and resulting changes in the [log](11-supervisor-feedback.md) |
| Physical Android checks | Asylbek confirmed no suitable phone is available | Arrange a borrowed device and separate caller/SMS sender; execute SAQ-45/46 and the device screenshot task SAQ-65 with test data |
| Kazakh speech quality | No supported-locale/device test supplied | Establish a genuine Kazakh recognition path, then record WER and call detection conditions/results |
| Real-world model quality | No authenticated received-SMS test cohort established | Collect and label with provenance/consent, freeze a held-out set, then evaluate the baseline and candidate model on the same set |

Empty tables, an interview guide, planned milestones, authored scenarios, emulator demonstrations
and peer/AI-assisted review do not substitute for the corresponding human or device evidence.
Record actual dates and contributions; do not backfill findings or approvals that did not occur.
