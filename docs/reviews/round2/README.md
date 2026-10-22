# SAQ-13 round-two review diagnostics

These small probes reproduce specific review findings. They do not connect to a database,
run migrations, train a model, reproduce published latency measurements, or print SMS text.
The latency probe starts a local fake HTTP server. The Windows probe runs only `npm --version`.
No probe installs dependencies or fetches missing commits; prepare the required environment first.

Use clean worktrees at the reviewed revisions. Commands below run from the checkout containing
this directory; replace the example sibling-worktree paths with your local paths.

| Probe | Reviewed PR and commit | Requirements |
|---|---|---|
| [ML grouping audit](audit_ml_grouping_readonly.py) | #14 `7f7dec98aee586ae3f46ddec294af3ce26d723bc`; also compatible with #25 `1d6a0f928e4257d27051bab7486fbdb578bea714` | Python 3.10+, NumPy, scikit-learn, Git; notebook-pinned commit `66575f3839f0a03d6871920c9ebc24d900388335` present locally |
| [Database guard parser](pr21_database_guard_probe.go) | #21 `f1063966f25c1ccd5e491a8b8020dbd5f66bb038` | Python 3.10+ launcher, installed Go 1.25+, cached modules from the reviewed `go.mod`/`go.sum` (pgx v5.7.1) |
| [Latency probes](latency_review_test.go), [batch rejection](latency_batch_review_test.go) | #23 `2f66a958827ec262313b6da47e0bcc433677d4bb` | Python launcher, installed Go 1.25+, cached reviewed modules, permission to open a loopback HTTP listener |
| [Windows wrapper probe](probe_pipeline_windows.py) | #28 `2bfa12be3abfdb450d938d039bd49e74393961eb` | Windows, Python 3.10+, Git, installed npm resolving to `.cmd` or `.bat` on PATH |

## ML grouping and provenance edges

```text
python -B docs/reviews/round2/audit_ml_grouping_readonly.py ../review-pr14
```

The audit imports `load_dataset`, `template_of`, `evaluate_real.load` and the merge function
from the supplied reviewed worktree. It checks the existing `text`, `label`, `source`,
`translated_from` and translation-table `text_en` columns. It is pinned to the two compatible
heads above; adapt it deliberately if the schema or function contracts change.

The merge function's output is intercepted in memory and compared with the committed rows.
No fitting/evaluation entry point is invoked. Output contains counts, hashes and row indexes,
not message text, credentials or authenticated received-SMS data.

Observed with Python 3.12.15, NumPy 1.26.4 and scikit-learn 1.5.2:

- 4,457 rows; 1,214 groups; zero stored-template buckets span folds.
- Of 2,248 source/translation pairs, 39 parent edges were dropped during deduplication;
  30 pairs have different group IDs and 28 cross folds. The zero stored-bucket count alone
  therefore does not establish complete source/translation separation.
- Protocol C has 4,001 training rows and 228 diagnostic rows, with zero audited translation
  edges crossing that boundary. The 228 rows are not verified received SMS.
- Twelve notebook code cells parse; no saved outputs; the pinned dataset hash matches.

Exit 0 means the audit completed, not that leakage is absent. Counts describe these commits
and this splitter version; they are not model-quality results or proof of receipt provenance.

## Connection-free database guard probe

```text
python -B docs/reviews/round2/run_go_probes.py ../review-pr21 database
```

The launcher copies only the parser probe and reviewed Go dependency files to a disposable
directory. The probe contains the exact historical guard from `setup_test.go:87–96` and calls
`pgxpool.ParseConfig`; it never invokes `TestMain`, `Connect`, migrations or SQL.

Expected output:

```text
guard_accepted=true actual_pgx_database="saqbol_test"
guard_accepted=true actual_pgx_database="saqbol"
guard_accepted=true actual_pgx_database="saqbol"
```

The latter two dummy URLs use `dbname` and `database` query overrides. The historical path-only
guard accepts them although pgx selects a different database. This reproduces the parser
mismatch; because the guard is copied, it does not automatically test a later guard fix.

## Latency calculation and failed-item handling

```text
python -B docs/reviews/round2/run_go_probes.py ../review-pr23 latency
```

The launcher copies the reviewed latency command and these test files into a disposable
module. Nearest-rank p50/p95/p99 and single-check failure accounting should pass. The batch
probe returns HTTP 200 with 100 error entries; the reviewed head incorrectly records one
successful duration, so `TestReviewBatchItemFailuresRejected` fails and the launcher exits 1.
This expected failure is the reproduced defect, not a rerun of the published stack benchmark.

The batch diagnostic accepts either an empty successful-duration list or the command's
explicit `latency: batch:` exit-1 error convention. It does not require `os.Exit` as the fix.
Panics, timeouts and unrecognised outcomes fail the diagnostic rather than counting as valid
rejection. It assumes the reviewed function signature; adapt it if a fix changes that API or
error-reporting convention. It is not comprehensive batch validation coverage.

The Go launcher disables automatic module/toolchain downloads (`GOPROXY=off`,
`GOTOOLCHAIN=local`), limits `GOMAXPROCS` to 2 and removes test-service URLs from its child
environment. It respects caller-supplied `GOCACHE` and `GOMODCACHE`. Missing cached dependencies
are an environment/setup failure, not evidence for or against the reviewed defect.

## Windows executable resolution

```text
python -B docs/reviews/round2/probe_pipeline_windows.py ../review-pr28
```

The probe loads that worktree's `scripts/pipeline.py` through `importlib`, then compares its
`npm --version` step with execution using the fully resolved npm wrapper. It does not run the
project pipelines, install packages, train ML or build an app.

Observed on Windows: npm resolved to `npm.CMD`; the reviewed pipeline reported `exit 127`
with `FileNotFoundError`, while the explicit wrapper returned version `11.11.0` and exit 0.
The JSON field `wrapper_resolution_mismatch` is true in that environment. Other platforms or
a PATH without an npm wrapper report `skip`. Exit 0 means the diagnostic completed; inspect
the JSON result. The report omits workstation paths, and wrapper logs are separate artifacts.

Both launchers use standard temporary directories by default. An optional
`--scratch-dir ../review-output/new-directory` retains logs/copies outside the reviewed
worktree, including in environments where the default temporary directory is restricted.
The named directory must not already exist. Neither launcher deletes or edits the reviewed tree.
