"""Orchestrator logic: step selection, skipping, failure handling and exit codes (no real toolchains run)."""

import sys
import tempfile
import unittest
from pathlib import Path

from _load import load

pl = load("saq_pipeline", "scripts/pipeline.py")


def fake_pipeline(fail_fast=False):
    return pl.Pipeline("demo", "test pipeline", (
        pl.Step("backend:vet", ("go", "vet"), "backend", needs=("go",), hint="install Go"),
        pl.Step("backend:test", ("go", "test"), "backend", needs=("go",)),
        pl.Step("web:test", ("npm", "test"), "web", needs=("npm",), needs_paths=("node_modules",), hint="npm ci"),
        pl.Step("ml:test", ("python", "-m", "pytest"), "ml", probe=("python", "-c", "import pytest")),
    ), fail_fast=fail_fast)


class Recorder:
    """Fake runner: records the steps it was asked to run and returns preset exit codes."""

    def __init__(self, codes=None):
        self.codes = codes or {}
        self.ran = []

    def __call__(self, step, cwd, log_path):
        self.ran.append(step.name)
        code = self.codes.get(step.name, 0)
        log_path.write_text("".join(f"line {i}\n" for i in range(40)) + f"exit {code}\n", encoding="utf-8")
        return code


class PipelineTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        for d in ("backend", "web/node_modules", "ml"):
            (self.root / d).mkdir(parents=True)
        self.logs = self.root / "logs"
        self.logs.mkdir()
        self.lines = []

    def tearDown(self):
        self.tmp.cleanup()

    def run_it(self, pipeline, steps=None, runner=None, which=lambda tool: f"/usr/bin/{tool}",
               probe=lambda cmd, cwd: True, **kw):
        runner = runner or Recorder()
        results = pl.run_pipeline(pipeline, list(steps or pipeline.steps), self.root, self.logs, runner=runner,
                                  which=which, probe=probe, out=self.lines.append, **kw)
        return results, runner

    def statuses(self, results):
        return {r.step: r.status for r in results}

    def test_all_steps_pass(self):
        results, runner = self.run_it(fake_pipeline())
        self.assertEqual(runner.ran, ["backend:vet", "backend:test", "web:test", "ml:test"])
        self.assertEqual(set(self.statuses(results).values()), {"ok"})
        self.assertEqual(pl.exit_code(results), 0)

    def test_missing_tool_is_skipped_with_hint_not_failed(self):
        results, runner = self.run_it(fake_pipeline(), which=lambda tool: None if tool == "go" else "/bin/x")
        st = self.statuses(results)
        self.assertEqual(st["backend:vet"], "skip")
        self.assertEqual(st["backend:test"], "skip")
        self.assertIn("go not found (install Go)", results[0].detail)
        self.assertEqual(runner.ran, ["web:test", "ml:test"])
        self.assertEqual(pl.exit_code(results), 0)

    def test_missing_path_and_failed_probe_skip(self):
        (self.root / "web/node_modules").rmdir()
        results, _ = self.run_it(fake_pipeline(), probe=lambda cmd, cwd: False)
        st = self.statuses(results)
        self.assertEqual(st["web:test"], "skip")
        self.assertIn("node_modules missing", results[2].detail)
        self.assertEqual(st["ml:test"], "skip")
        self.assertIn("dependencies not installed", results[3].detail)

    def test_missing_app_directory_skips(self):
        (self.root / "ml").rmdir()
        results, _ = self.run_it(fake_pipeline())
        self.assertEqual(self.statuses(results)["ml:test"], "skip")

    def test_failure_keeps_going_by_default_and_exits_1(self):
        results, runner = self.run_it(fake_pipeline(), runner=Recorder({"backend:test": 2}))
        self.assertEqual(runner.ran, ["backend:vet", "backend:test", "web:test", "ml:test"])
        failed = [r for r in results if r.status == "fail"]
        self.assertEqual([r.step for r in failed], ["backend:test"])
        self.assertEqual(failed[0].detail, "exit 2")
        self.assertEqual(len(failed[0].tail), pl.TAIL_LINES)
        self.assertEqual(failed[0].tail[-1], "exit 2")
        self.assertTrue(any("FAIL" in line and "backend:test" in line for line in self.lines))
        self.assertEqual(pl.exit_code(results), 1)

    def test_fail_fast_pipeline_stops_after_first_failure(self):
        results, runner = self.run_it(fake_pipeline(fail_fast=True), runner=Recorder({"backend:vet": 1}))
        self.assertEqual(runner.ran, ["backend:vet"])
        self.assertEqual(self.statuses(results)["ml:test"], "not-run")
        self.assertEqual(pl.exit_code(results), 1)

    def test_command_line_flag_overrides_pipeline_default(self):
        _, runner = self.run_it(fake_pipeline(fail_fast=True), runner=Recorder({"backend:vet": 1}),
                                fail_fast=False)
        self.assertEqual(len(runner.ran), 4)

    def test_timeout_is_reported(self):
        results, _ = self.run_it(fake_pipeline(), runner=Recorder({"ml:test": 124}))
        self.assertEqual(results[-1].detail, "timed out")

    def test_runner_os_error_is_a_failure_not_a_crash(self):
        def broken(step, cwd, log_path):
            raise FileNotFoundError("go")
        results, _ = self.run_it(fake_pipeline(), runner=broken)
        self.assertEqual(results[0].status, "fail")
        self.assertEqual(results[0].detail, "exit 127")

    def test_dry_run_runs_nothing(self):
        results, runner = self.run_it(fake_pipeline(), dry_run=True)
        self.assertEqual(runner.ran, [])
        self.assertEqual(pl.exit_code(results), 0)
        self.assertTrue(all(line.lstrip().startswith("would") for line in self.lines))

    def test_select_by_group_and_step(self):
        p = fake_pipeline()
        self.assertEqual([s.name for s in pl.select(p, {"backend"}, set())], ["backend:vet", "backend:test"])
        self.assertEqual([s.name for s in pl.select(p, set(), {"backend", "ml:test"})], ["web:test"])
        self.assertEqual([s.name for s in pl.select(p, {"backend"}, {"backend:vet"})], ["backend:test"])
        with self.assertRaises(ValueError):
            pl.select(p, {"frontend"}, set())

    def test_summary_counts(self):
        rs = [pl.Result("a", "ok"), pl.Result("b", "fail"), pl.Result("c", "skip"), pl.Result("d", "not-run")]
        self.assertEqual(pl.summary(rs, 1.0), "1 ok, 1 failed, 1 skipped, 1 not run in 1.0s")


class RealProcessTest(unittest.TestCase):
    """run_process with the current Python interpreter: exit codes, logs and timeouts."""

    def test_exit_code_output_and_timeout(self):
        with tempfile.TemporaryDirectory() as tmp:
            log = Path(tmp) / "x.log"
            step = pl.Step("t:ok", (sys.executable, "-c", "print('hello'); raise SystemExit(3)"))
            self.assertEqual(pl.run_process(step, Path(tmp), log), 3)
            self.assertIn("hello", log.read_text(encoding="utf-8"))
            slow = pl.Step("t:slow", (sys.executable, "-c", "import time; time.sleep(30)"), timeout=1)
            self.assertEqual(pl.run_process(slow, Path(tmp), log), 124)


class DefinitionsTest(unittest.TestCase):
    def test_repo_pipelines_are_well_formed(self):
        ps = pl.pipelines(pl.ROOT, env={"API_BASE_URL": "http://10.0.2.2:8080"})
        self.assertEqual(set(ps), {"checks", "ml", "apk"})
        self.assertEqual([s.name for s in ps["ml"].steps], ["ml:merge", "ml:train", "ml:evaluate"])
        self.assertTrue(ps["ml"].fail_fast)
        self.assertEqual(ps["apk"].required_env, ("API_BASE_URL",))
        self.assertIn("--dart-define=API_BASE_URL=http://10.0.2.2:8080", ps["apk"].steps[-1].cmd)
        for p in ps.values():
            names = [s.name for s in p.steps]
            self.assertEqual(len(names), len(set(names)), p.name)
            for s in p.steps:
                self.assertTrue((pl.ROOT / s.cwd).is_dir(), s.name)

    def test_cli_rejects_unknown_pipeline_and_missing_env(self):
        self.assertEqual(pl.main(["run", "nope"]), 2)
        import os
        old = os.environ.pop("API_BASE_URL", None)
        try:
            self.assertEqual(pl.main(["run", "apk"]), 2)
        finally:
            if old is not None:
                os.environ["API_BASE_URL"] = old
        self.assertEqual(pl.main(["run", "checks", "--only", "frontend"]), 2)


if __name__ == "__main__":
    unittest.main()
