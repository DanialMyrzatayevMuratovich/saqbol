# Pre-defense review record — 22 October 2026

Task: [SAQ-13](https://saqbol.youtrack.cloud/issue/SAQ-13). Reviewer account:
[Asylbek2006](https://github.com/Asylbek2006). Review work used automated checks
and AI-assisted source/document inspection. Decisions and comments were published
from Asylbek's account with his authorization.

This is a dated review record, not a statement that the submission is complete.
The reviewed `main` was `91862dcca5d218887db7fd57fc1e88c4f3d2bf21`. The combined
`current-version` snapshot was `09af87b90f55109b4a4c64994b19274037a0eed8`;
features found there were not treated as already merged into `main`.

## Published reviews

Earlier merged PRs received explicitly **retrospective** comments. These do not
establish that peer review happened before their merges. Open-PR reviews identify
the exact reviewed commit; new changes need another review.

| PR | Deliverable | Review result / follow-up | Evidence |
|---|---|---|---|
| #1 | Prototype description | Correct call-history coverage and distinguish working UI from device validation | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/1#issuecomment-6346891003) |
| #2 | Proposal | Use the university topic wording; reconcile collection and held-out test targets | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/2#issuecomment-6346892758) |
| #3 | Relevance evidence | Record actual user evidence; qualify risk-group, market-gap and dataset claims | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/3#issuecomment-6346895267) |
| #4 | Technology comparison | Correct speech-processing privacy assumptions and compare REST with OpenAPI fairly | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/4#issuecomment-6346898039) |
| #5 | README | Install ML runtime dependencies in the fresh-environment test instructions; update provenance wording | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/5#issuecomment-6346900598) |
| #6 | Evaluation plan | Supply reproducible splits/results; distinguish development examples from authentic received SMS | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/6#issuecomment-6346902302) |
| #7 | Existing systems | Reduce 11 criteria to the required 6–10; preserve uncertainty in language/region comparisons | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/7#issuecomment-6346905929) |
| #8 | Requirements | **Changes requested:** Kazakh STT, trigger minimum, test dependencies and call-history status | [Review](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/8#pullrequestreview-5618114672) |
| #9 | Architecture | Correct speech-service boundary and call persistence/history narrative; update affected exports | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/9#issuecomment-6346907857) |
| #10 | Literature | Qualify current dataset provenance, early-warning precision trade-off and corpus-gap claim | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/10#issuecomment-6346910432) |
| #11 | Management and supervision | Preserve actual review chronology and keep missing supervisor evidence open | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/11#issuecomment-6346912332) |
| #12 | YouTrack links | Project access verified from the team account; committee access still needs checking | [Comment](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/12#issuecomment-6346914039) |
| #13 | Team workflow | **Approved:** documentation-only review; `main` reports protected | [Review](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/13#pullrequestreview-5618092146) |
| #14 | ML English support/notebook | **Changes requested:** translated template families cross folds; make evaluation reproducible | [Review](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/14#pullrequestreview-5618138800) |
| #15 | Mobile localization/remember me | **Changes requested:** opting out must delete stored credentials immediately | [Review](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/15#pullrequestreview-5618142592) |
| #16 | Prototype screenshots | **Changes requested:** qualify the historical "real-only" metric label and record capture revisions | [Review](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/16#pullrequestreview-5618116439) |

Related task [SAQ-41](https://saqbol.youtrack.cloud/issue/SAQ-41) was completed:
[PR #17 approved](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/17#pullrequestreview-5617956439)
at `fbfd6960f7a0a8b0539d3f70c41e26f2b4156e0d`. No PR was merged by the assistant.

## Checks actually performed

| Check | Snapshot / environment | Result and limit |
|---|---|---|
| Go build, vet, tests | `main@91862dc`, Go 1.25.3, Windows | Passed; 7 tests across auth and mock-ML packages; no DB/API integration run |
| Web lint and tests | `main@91862dc`, Node 24.14.1 | Passed; 2 label tests; no browser/full-stack coverage implied |
| Fresh-clone protobuf generation | PR #17 exact head, Python 3.12 and Git Bash | Output directory initially absent; script and generated-module imports passed; tracked files remained unchanged |
| ML unit tests | PR #17 exact head | 6 passed; pytest cache permission warnings did not prevent execution |
| ML unit tests | PR #14 `66575f3839f0a03d6871920c9ebc24d900388335` | 12 passed; no XLM-R training performed |
| CI | PR #17 exact head | Backend, ML, mobile and web jobs passed in [push](https://github.com/DanialMyrzatayevMuratovich/saqbol/actions/runs/39771953499) and [PR](https://github.com/DanialMyrzatayevMuratovich/saqbol/actions/runs/39771958522) runs |
| Mobile PR #15 CI | `cf7c422a5e994d141c1e4b605dfa68bef957b15f` | `flutter analyze` passed; that workflow did not run Flutter tests or build an APK |
| Diagrams | PR #9 deliverables | Six editable source/export pairs; SVG XML checked; three mandatory PNGs visually inspected |
| Screenshots | PR #16 deliverables | All 7 mobile and 3 web images visually inspected; visible numbers match documented demo ranges |
| Research sources | Documentation PRs | Representative primary publication/vendor sources checked; no claim of an exhaustive bibliography audit or hands-on competitor testing |

Backend and web tree hashes are identical between `main@91862dc` and PR #17,
so those local checks cover the same application/test files. CI uses Node 20,
which differs from the local Node version. A Flutter SDK was unavailable for
local mobile checks. No physical-device, call-STT accuracy or complete Docker
demonstration is claimed by this record.

## Reproducing the ML split observation

The included [read-only diagnostic](check_ml_split.py) prints counts and a data
hash, not message text. Run it with the existing ML runtime dependencies and
point it at a checkout of PR #14's reviewed commit:

```bash
python docs/reviews/check_ml_split.py --ml-dir /path/to/pr-14/saqbol-ml
```

At that commit, 99 normalized English template families cross held-out folds,
involving 839 of 2,209 English rows. Source/translation pairs remain together,
but different source groups can translate into the same normalized English
family. All 228 non-synthetic originals also have synthetic-tagged translations.
This last fact identifies a leakage risk for a source-prefix-only holdout; it
does not prove what an uncommitted C1–C3 evaluation script actually did.

The inspected `data/train.csv` SHA-256 is
`ef174ba126cbb880461212b8c411cabfe5dc0932a588489b75657360ebeecd29`.

## Work still required before claiming completion

- Resolve requested changes and re-review the changed commits. SAQ-13 also
  requires the relevant PRs to be merged; published comments alone do not meet
  all its acceptance criteria.
- Obtain 3–5 actual user discussions **or** a substantive agreement with an
  actual client. The interview guide and empty findings table are preparation,
  not primary evidence.
- Obtain and record the supervisor's actual comments, decisions and resulting
  changes. The feedback log is currently an empty template.
- Propagate [PR #25's provenance correction](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/25)
  across proposal, README, relevance, literature, evaluation and screenshot
  captions. The 228 examples are not verified SMS received by real users.
- Arrange a physical Android phone for SAQ-45, SAQ-46 and SAQ-65. Asylbek
  confirmed on 22 October that a suitable phone is currently unavailable.
  An emulator can support SAQ-44's UI review, but does not satisfy those
  physical-device acceptance criteria.
- Verify committee access and tag the exact reviewed submission only when its
  intended content and known limitations have been agreed. Do not move a
  previously submitted tag.

Existing dependency advisories were also reported by `npm audit` on the web
lockfile (20 package findings). They were not changed during this review and
are not evidence of demonstrated exploitation. Dependency remediation needs a
separate scoped task and verification.
