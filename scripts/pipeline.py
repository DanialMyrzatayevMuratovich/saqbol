#!/usr/bin/env python3
"""Run named pipelines of repo steps with one clear summary. Stdlib only, Python 3.10+.

  python3 scripts/pipeline.py list
  python3 scripts/pipeline.py run checks                 # vet, lint and test every app
  python3 scripts/pipeline.py run checks --only backend,ml
  python3 scripts/pipeline.py run checks --skip mobile
  python3 scripts/pipeline.py run ml                     # merge datasets -> train baseline -> evaluate
  python3 scripts/pipeline.py run checks --dry-run       # show what would run
  API_BASE_URL=http://192.168.1.5:8080 python3 scripts/pipeline.py run apk   # only when asked for an APK

A step whose toolchain is missing (no `go`, no `flutter`, no node_modules, Python packages not
installed) is skipped with a hint, not failed. Each step prints one line; its full output goes to
a log file, and on failure the last lines and the log path are printed. Exit code: 0 when nothing
failed, 1 when a step failed, 2 on a usage error.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TAIL_LINES = 25


@dataclass(frozen=True)
class Step:
    name: str                       # "<group>:<action>", e.g. "backend:test"
    cmd: tuple[str, ...]
    cwd: str = "."                  # relative to the repo root
    needs: tuple[str, ...] = ()     # executables that must be on PATH
    needs_paths: tuple[str, ...] = ()  # paths (relative to cwd) that must exist
    probe: tuple[str, ...] = ()     # command that must succeed, e.g. an import check
    hint: str = ""                  # how to get what is missing
    timeout: int = 900              # seconds

    @property
    def group(self) -> str:
        return self.name.split(":", 1)[0]


@dataclass(frozen=True)
class Pipeline:
    name: str
    help: str
    steps: tuple[Step, ...]
    fail_fast: bool = False         # stop at the first failure (later steps need earlier output)
    required_env: tuple[str, ...] = ()


@dataclass
class Result:
    step: str
    status: str                     # ok | fail | skip | not-run
    seconds: float = 0.0
    detail: str = ""
    log: str = ""
    tail: list[str] = field(default_factory=list)


def ml_python(root: Path) -> str:
    """The ML service's virtualenv if it exists, else the interpreter running this script."""
    for rel in (".venv/bin/python", ".venv/Scripts/python.exe"):
        candidate = root / "saqbol-ml" / rel
        if candidate.exists():
            return str(candidate)
    return sys.executable


def pipelines(root: Path = ROOT, env: dict[str, str] | None = None) -> dict[str, Pipeline]:
    env = os.environ if env is None else env
    py = ml_python(root)
    ml_hint = "cd saqbol-ml && python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt"
    ml_probe = (py, "-c", "import sklearn, numpy, joblib")
    web_hint = "cd saqbol-web && npm ci"
    checks = (
        Step("backend:vet", ("go", "vet", "./..."), "saqbol-backend", needs=("go",), hint="install Go 1.25+"),
        Step("backend:test", ("go", "test", "./..."), "saqbol-backend", needs=("go",), hint="install Go 1.25+"),
        Step("ml:test", (py, "-m", "pytest", "-q"), "saqbol-ml",
             probe=(py, "-c", "import pytest, sklearn, numpy, joblib"), hint=ml_hint),
        Step("mobile:analyze", ("flutter", "analyze"), "saqbol-mobile", needs=("flutter",),
             hint="install Flutter 3.41+"),
        Step("mobile:test", ("flutter", "test"), "saqbol-mobile", needs=("flutter",), hint="install Flutter 3.41+"),
        Step("web:lint", ("npm", "run", "lint"), "saqbol-web", needs=("npm",), needs_paths=("node_modules",),
             hint=web_hint),
        Step("web:test", ("npm", "test"), "saqbol-web", needs=("npm",), needs_paths=("node_modules",),
             hint=web_hint),
        Step("tools:test", (sys.executable, "-m", "unittest", "discover", "-s", "scripts/tests")),
    )
    ml = (
        Step("ml:merge", (py, "training/merge_datasets.py"), "saqbol-ml", probe=ml_probe, hint=ml_hint),
        Step("ml:train", (py, "training/train_baseline.py"), "saqbol-ml", probe=ml_probe, hint=ml_hint,
             timeout=1800),
        Step("ml:evaluate", (py, "training/evaluate.py"), "saqbol-ml", probe=ml_probe, hint=ml_hint,
             timeout=1800),
    )
    api = env.get("API_BASE_URL", "")
    apk = (
        Step("mobile:pub-get", ("flutter", "pub", "get"), "saqbol-mobile", needs=("flutter",),
             hint="install Flutter 3.41+"),
        Step("mobile:apk", ("flutter", "build", "apk", f"--dart-define=API_BASE_URL={api}"), "saqbol-mobile",
             needs=("flutter",), hint="install Flutter 3.41+ and the Android SDK", timeout=1800),
    )
    return {
        "checks": Pipeline("checks", "vet, lint and test every app (run before opening a PR)", checks),
        "ml": Pipeline("ml", "merge datasets -> train the baseline -> evaluate (rewrites data/train.csv, "
                       "models/ and experiments/)", ml, fail_fast=True),
        "apk": Pipeline("apk", "release APK; needs API_BASE_URL; only when the user asks for an APK", apk,
                        fail_fast=True, required_env=("API_BASE_URL",)),
    }


Runner = Callable[[Step, Path, Path], int]


def run_process(step: Step, cwd: Path, log_path: Path, verbose: bool = False) -> int:
    """Run one step, writing stdout+stderr to log_path. Returns the exit code (124 on timeout)."""
    with log_path.open("w", encoding="utf-8", errors="replace") as log:
        log.write(f"$ {' '.join(step.cmd)}\n# cwd: {cwd}\n\n")
        log.flush()
        if not verbose:
            try:
                return subprocess.run(step.cmd, cwd=cwd, stdout=log, stderr=subprocess.STDOUT,
                                      stdin=subprocess.DEVNULL, timeout=step.timeout).returncode
            except subprocess.TimeoutExpired:
                log.write(f"\n# timed out after {step.timeout}s\n")
                return 124
        proc = subprocess.Popen(step.cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                stdin=subprocess.DEVNULL, text=True, encoding="utf-8", errors="replace")
        timer = threading.Timer(step.timeout, proc.kill)
        timer.start()
        try:
            assert proc.stdout is not None
            for line in proc.stdout:
                log.write(line)
                print(f"      {line}", end="", flush=True)
            code = proc.wait()
        finally:
            timed_out = not timer.is_alive()
            timer.cancel()
        if timed_out:
            log.write(f"\n# timed out after {step.timeout}s\n")
            return 124
        return code


def probe_ok(cmd: tuple[str, ...], cwd: Path) -> bool:
    try:
        return subprocess.run(cmd, cwd=cwd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                              stdin=subprocess.DEVNULL, timeout=60).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def missing(step: Step, root: Path, which: Callable[[str], str | None] = shutil.which,
            probe: Callable[[tuple[str, ...], Path], bool] = probe_ok) -> str:
    """Why the step cannot run here ('' when it can)."""
    cwd = root / step.cwd
    if not cwd.is_dir():
        return f"{step.cwd}/ not found"
    for tool in step.needs:
        if which(tool) is None:
            return f"{tool} not found"
    for rel in step.needs_paths:
        if not (cwd / rel).exists():
            return f"{step.cwd}/{rel} missing"
    if step.probe and not probe(step.probe, cwd):
        return "dependencies not installed"
    return ""


def select(pipeline: Pipeline, only: set[str], skip: set[str]) -> list[Step]:
    known = {s.group for s in pipeline.steps} | {s.name for s in pipeline.steps}
    unknown = sorted((only | skip) - known)
    if unknown:
        raise ValueError(f"unknown step or group {', '.join(unknown)}; known: {', '.join(sorted(known))}")
    picked = []
    for s in pipeline.steps:
        if only and s.group not in only and s.name not in only:
            continue
        if s.group in skip or s.name in skip:
            continue
        picked.append(s)
    return picked


def tail(path: Path, n: int = TAIL_LINES) -> list[str]:
    try:
        return path.read_text(encoding="utf-8", errors="replace").splitlines()[-n:]
    except OSError:
        return []


def run_pipeline(pipeline: Pipeline, steps: list[Step], root: Path, log_dir: Path, *,
                 fail_fast: bool | None = None, dry_run: bool = False,
                 runner: Runner | None = None, which: Callable[[str], str | None] = shutil.which,
                 probe: Callable[[tuple[str, ...], Path], bool] = probe_ok,
                 out: Callable[[str], None] = print) -> list[Result]:
    stop_early = pipeline.fail_fast if fail_fast is None else fail_fast
    runner = runner or run_process
    width = max((len(s.name) for s in steps), default=0)
    results: list[Result] = []
    failed = False
    for step in steps:
        if failed and stop_early:
            results.append(Result(step.name, "not-run", detail="an earlier step failed"))
            out(f"  {'-':<5} {step.name:<{width}}  not run: an earlier step failed")
            continue
        why = missing(step, root, which, probe)
        if why:
            detail = f"{why}" + (f" ({step.hint})" if step.hint else "")
            results.append(Result(step.name, "skip", detail=detail))
            out(f"  {'skip':<5} {step.name:<{width}}  {detail}")
            continue
        if dry_run:
            results.append(Result(step.name, "skip", detail="dry run"))
            out(f"  {'would':<5} {step.name:<{width}}  (cd {step.cwd} && {' '.join(step.cmd)})")
            continue
        log_path = log_dir / f"{step.name.replace(':', '-')}.log"
        started = time.monotonic()
        try:
            code = runner(step, root / step.cwd, log_path)
        except OSError as exc:  # e.g. the executable vanished between the check and the run
            code = 127
            log_path.write_text(f"{type(exc).__name__}: {exc}\n", encoding="utf-8")
        seconds = time.monotonic() - started
        if code == 0:
            results.append(Result(step.name, "ok", seconds, log=str(log_path)))
            out(f"  {'ok':<5} {step.name:<{width}}  {seconds:.1f}s")
            continue
        failed = True
        detail = "timed out" if code == 124 else f"exit {code}"
        lines = tail(log_path)
        results.append(Result(step.name, "fail", seconds, detail, str(log_path), lines))
        out(f"  {'FAIL':<5} {step.name:<{width}}  {seconds:.1f}s  {detail} -> {log_path}")
        for line in lines:
            out(f"        | {line}")
    return results


def summary(results: list[Result], seconds: float) -> str:
    count = {k: sum(r.status == k for r in results) for k in ("ok", "fail", "skip", "not-run")}
    parts = [f"{count['ok']} ok", f"{count['fail']} failed", f"{count['skip']} skipped"]
    if count["not-run"]:
        parts.append(f"{count['not-run']} not run")
    return f"{', '.join(parts)} in {seconds:.1f}s"


def exit_code(results: list[Result]) -> int:
    return 1 if any(r.status == "fail" for r in results) else 0


def _split(values: list[str]) -> set[str]:
    return {v.strip() for raw in values for v in raw.split(",") if v.strip()}


def main(argv: list[str] | None = None) -> int:
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(prog="pipeline.py", description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list", help="show pipelines and their steps")
    run = sub.add_parser("run", help="run a pipeline")
    run.add_argument("pipeline")
    run.add_argument("--only", action="append", default=[], help="groups or steps to run, e.g. backend,ml:test")
    run.add_argument("--skip", action="append", default=[], help="groups or steps to leave out")
    run.add_argument("--fail-fast", dest="fail_fast", action="store_true", default=None,
                     help="stop at the first failure")
    run.add_argument("--keep-going", dest="fail_fast", action="store_false", help="run every step")
    run.add_argument("--dry-run", action="store_true", help="print the commands without running them")
    run.add_argument("-v", "--verbose", action="store_true", help="stream step output")
    args = parser.parse_args(argv)

    available = pipelines()
    if args.cmd == "list":
        for p in available.values():
            print(f"{p.name}: {p.help}")
            for s in p.steps:
                print(f"  {s.name:<16} (cd {s.cwd} && {' '.join(s.cmd)})")
        return 0

    pipeline = available.get(args.pipeline)
    if pipeline is None:
        print(f"unknown pipeline {args.pipeline!r}; choose one of: {', '.join(available)}", file=sys.stderr)
        return 2
    absent = [name for name in pipeline.required_env if not os.environ.get(name)]
    if absent:
        print(f"pipeline {pipeline.name} needs {', '.join(absent)} (see CLAUDE.md section 7), "
              f"e.g. API_BASE_URL=http://<LAN_OR_SERVER_IP>:8080", file=sys.stderr)
        return 2
    try:
        steps = select(pipeline, _split(args.only), _split(args.skip))
    except ValueError as exc:
        print(f"pipeline {pipeline.name}: {exc}", file=sys.stderr)
        return 2

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_dir = Path(tempfile.gettempdir()) / "saqbol-pipeline" / f"{stamp}-{pipeline.name}"
    log_dir.mkdir(parents=True, exist_ok=True)
    print(f"pipeline {pipeline.name}: {len(steps)} step(s) in {ROOT}")
    started = time.monotonic()
    runner = (lambda step, cwd, log: run_process(step, cwd, log, verbose=True)) if args.verbose else None
    results = run_pipeline(pipeline, steps, ROOT, log_dir, fail_fast=args.fail_fast, dry_run=args.dry_run,
                           runner=runner)
    print(f"pipeline {pipeline.name}: {summary(results, time.monotonic() - started)}; logs in {log_dir}")
    return exit_code(results)


if __name__ == "__main__":
    sys.exit(main())
