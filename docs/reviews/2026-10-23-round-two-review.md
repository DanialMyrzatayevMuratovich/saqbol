# Pre-defense review: second round

Task: [SAQ-13](https://saqbol.youtrack.cloud/issue/SAQ-13). Reviewer: Asylbek Abdibay
(`Asylbek2006`), with AI-assisted source inspection and reproducible checks.
The round started on 22 October UTC and continued on 23 October in Asia/Qyzylorda.
This record distinguishes local execution, independently inspected CI logs,
author-reported results and checks that remain pending.

## Reviewed revisions and decisions

Decisions apply to the exact commits below. New commits require another review;
approval of a change does not override branch protection or approve an unsafe base.

| PR | Reviewed head | Decision | Main result |
|---|---|---|---|
| [#8](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/8#pullrequestreview-5619393392) | `cf1e1857fa7c9c8b00f47b6002507f6a4c1917c0` | Approve | Previous requirements/status findings resolved; planned Kazakh STT, received-SMS evaluation and privacy evidence remain clearly distinguished from implemented paths |
| [#14](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/14#pullrequestreview-5619416430) | `7f7dec98aee586ae3f46ddec294af3ce26d723bc` | Request changes | Deduplication drops additional translation-parent edges before grouping; 28 mapped pairs cross CV folds |
| [#15](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/15#pullrequestreview-5619829876) | `16314169d6493bfe07b6bc2ae42c67629d891aed` | Approve source | Immediate remember-me opt-out and localized errors corrected; local Flutter dependency setup blocked, author reports 13 passing tests |
| [#16](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/16#pullrequestreview-5619675747) | `21eb30b2df7dc17ff705c5297ad401ecfe38a042` | Approve renewed | Capture versions and historical dataset-label caveat corrected; all ten images inspected; merge retains provenance guidance and SAQ-86 row |
| [#17](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/17#pullrequestreview-5619674948) | `d7a42a228a6fdc92dd06a953e0127a90caf9a9db` | Approve renewed | Documentation conflict resolution preserves before/after CI behavior; workflow and proto generation unchanged; all four jobs pass in both current suites |
| [#18](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/18#pullrequestreview-5619692184) | `eb5c7fabb31f955045851f9d5ccca5c4bb75a111` | Request changes | Original network/queue problem fixed, but blocking result handling disables the response fallback; one race test also assumes nondeterministic winner diversity |
| [#20](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/20#pullrequestreview-5619830793) | `394e067731770473a8f492c9c0a863fbe68ba2a9` | Approve source | Seven source corrections inspected; three history tests, backend build and vet pass; local Flutter setup blocked |
| [#21](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/21#pullrequestreview-5619419093) | `f1063966f25c1ccd5e491a8b8020dbd5f66bb038` | Request changes | URL path validation does not validate the effective pgx database before migrations/table resets |
| [#22](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/22#pullrequestreview-5619434880) | `50784a767185303b7bef6dc3022d76944b36e3b1` | Approve delta | Model-version ID reaches new detections; base #21 must be corrected before merging |
| [#23](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/23#pullrequestreview-5619437746) | `2f66a958827ec262313b6da47e0bcc433677d4bb` | Request changes | Batch timing accepts HTTP 200 envelopes containing failed item classifications |
| [#24](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/24#pullrequestreview-5619436387) | `9df8b38d2566c7127200562403ed8001375c9765` | Approve delta | Protected-route authentication now precedes per-user rate limiting; base #21 must be corrected |
| [#25](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/25#pullrequestreview-5619417674) | `1d6a0f928e4257d27051bab7486fbdb578bea714` | Request changes | Dataset card improved, but its verification-plan delta still asserts unverified human authorship |
| [#26](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/26#pullrequestreview-5619475173) | `6c719463aa0052ee38a84bdab0f9c8586fb3845a` | Approve | Receiver registration matches the pinned plugin contract; Android device execution remains separate |
| [#28](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/28#pullrequestreview-5619395905) | `2bfa12be3abfdb450d938d039bd49e74393961eb` | Request changes | Process runner detects npm.CMD but cannot launch the unresolved bare command on Windows |

PR #21 is stacked on #17. Both #22 and #24 are based on #21; #24 is not based on #22.
PR #25 is based on #14. These bases were used to distinguish each PR's own changes
from inherited issues.

The #16 and #17 approvals were renewed after Danial merged main into those branches;
the manual conflict resolutions were inspected separately from inherited changes.

## Reproducible findings

The [round-two diagnostic sources and instructions](round2/README.md) accompany this
record. They are review probes, not evidence of deployed application behavior.

### Translation families: PR #14

The first review's retained-template defect is fixed: no stored normalized-template
bucket spans folds at this head. A separate audit of **all** 2,248 original/English
mappings shows that English-text deduplication discards 39 additional parent edges.
Thirty original/English pairs acquire different group IDs; 28 cross the five CV folds.
The actual merge function reproduced the committed rows with output captured in
memory, without rewriting a dataset or exposing message text.

The correction must preserve the full parent graph before deduplication and cover
discarded parent links in the regression. A/B results must be recomputed after the
fold correction. No change in metric magnitude or direction has been measured here.
The separate C1-C3 audit found **zero** original-to-English crossings between its
4,001 training rows and 228 test rows; this CV finding is not evidence that C1-C3 leaks.

### Call response deadline: PR #18

The original trickled-body and queued-lookup cases now answer at approximately
3,502-3,509 ms. However, `ScreeningGate.finish` claims the answer and cancels the
fallback before invoking the result callback. A bounded latch probe using the
unchanged production gate receives no answer within five seconds of callback entry;
after release, it receives exactly one answer at 5,024 ms from entry. Keep the
deadline eligible until the actual response and cover slow result handling.

The first ten-test JVM run passed nine tests. Its race test's exactly-once checks
passed for all 300 calls, but its assumption that both lookup and deadline must win
at least once failed; two focused reruns passed. Make winner coverage deterministic.
Validation used Java 22 and Kotlin 2.0.21/JVM target 17, whereas the project pins
Kotlin 2.2.20. This is neither an Android build nor a device notification measurement.

### Effective database: PR #21

The test guard inspects only the URL path. pgx also accepts `dbname` and `database`
query parameters that override that path. The safe parser-only probe demonstrates
that `/saqbol_test?dbname=saqbol` passes the old guard while the effective database
is `saqbol`; the `database=` form behaves the same way. No connection, migration,
table reset or other SQL was executed by the probe. Validate the effective parsed
connection configuration before destructive setup and cover both override forms.

### Failed batch timing: PR #23

The API can return HTTP 200 with per-item errors. A local fake HTTP server returned
100 such errors; the benchmark still accepted a successful scan duration. Validate
the decoded item errors/verdicts and distinguish incomplete runs from successful
scan latency. This does not establish that the author's published run contained
failed items. Its M4/Compose timings were not independently reproduced.

### Windows executable wrappers: PR #28

All 44 tooling unit tests passed on Windows. A separate real-process probe showed
that `shutil.which('npm')` finds `npm.CMD`, but the runner passes the unresolved
`npm` command to `subprocess` and fails with WinError 2. Invoking the resolved path
succeeds with npm 11.11.0. Resolve command wrappers consistently in normal and
verbose execution, including Flutter's launcher, and cover that path in regression
tests. Mailbox read/reply operation itself was successfully exercised.

## What was actually checked

| Area | Evidence | Limits |
|---|---|---|
| Requirements and screenshots | Pinned-source inspection; count checks; links; ten screenshots visually inspected | No recreated capture environment, device evidence or authenticity claim |
| ML | 14 pytest tests passed; read-only full-mapping audit; notebook syntax and pinned dataset hash checked | No XLM-R training or new metric run |
| Call response #18 | Actual gate, HTTP adapter and ten JVM tests compiled; 9 passed, one scheduler-sensitive assertion failed; separate blocked-callback counterexample reproduced | Kotlin 2.0.21 instead of project 2.2.20; no Android build/device test |
| Redesign backend #20 | Three history tests, full build and vet passed; all seven original source findings addressed | Aggregate SQL was inspected, not executed against PostgreSQL |
| Flutter #15/#20 | Official Flutter 3.47.7 archive SHA256 verified, paths checked before extraction, SDK startup passed (Dart 3.13.5); source/tests inspected | Two PR15 locked dependency attempts failed with Windows cache rename/access denied; no local analyze/test ran for either PR; author reports 13/45 tests respectively |
| Backend #21/#22/#24 | Build/vet passed at each head; seven shared unit tests passed; affected packages compiled | PostgreSQL/Redis integration explicitly skipped locally |
| Backend integration CI | Exact-head backend logs independently show integration execution: #21 1.637 s, #22 1.941 s, #24 1.293 s | Successful intended-database runs do not cover the unsafe URL override |
| Latency tool | Build/vet; nearest-rank and single-request failure probes passed; failed-batch probe reproduced defect | Fake-server checks do not reproduce published system latency |
| SMS receiver | XML/registration inspection; official another_telephony 0.4.1 archive hash matches pubspec.lock; actual class/example checked | Author's API-36 emulator run not reproduced; no physical phone available |
| Agent tools | 44 local tests passed; real mailbox exchange; Windows wrapper probe | No full ML pipeline/data regeneration or APK build |

Integration CI logs: [#21](https://github.com/DanialMyrzatayevMuratovich/saqbol/actions/runs/39821141798/job/119972418294),
[#22](https://github.com/DanialMyrzatayevMuratovich/saqbol/actions/runs/39821175233/job/119972539193),
[#24](https://github.com/DanialMyrzatayevMuratovich/saqbol/actions/runs/39821183330/job/119972566862).
Receiver contract: [official plugin version](https://pub.dev/packages/another_telephony/versions/0.4.1).

Flutter validation stopped after the repeated setup error, including execution outside the
sandbox. Neither reviewed worktree nor its exported source copy was changed. The local-test
checklist item remains unfulfilled for these mobile changes; source approval is not a claim
of locally passing Flutter tests. Required CI and later device evidence remain separate.

## Outstanding handoffs

- PR #18's new revision still needs the response-budget and flaky-test corrections
  described above. Danial received the review and reproduction details by mailbox.
- No suitable Android phone is available to Asylbek. Danial confirmed by mailbox
  that he takes SAQ-45/46. This is an accepted handoff, not completed testing;
  SAQ-65 also needs real-device evidence.
- At the reviewed revisions, several main-based PRs inherit the missing `app/generated` CI setup fixed by
  already-reviewed PR #17. Content approval is not a claim that those checks pass.
- The current review neither supplies interviews nor substitutes for supervisor
  feedback. Those human-evidence deliverables remain separate.
- No PR was merged by the assistant. SAQ-13 cannot be marked Done while requested
  changes or its required integrations remain outstanding.
