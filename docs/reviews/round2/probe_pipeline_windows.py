"""Compare reviewed pipeline execution with an explicitly resolved Windows npm wrapper.

Only runs npm --version; no installation, dependency fetch or application build.
"""

import argparse
from contextlib import nullcontext, redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path, help="worktree containing reviewed scripts/pipeline.py")
    parser.add_argument("--scratch-dir", type=Path,
                        help="optional new directory outside the reviewed worktree; keeps logs")
    args = parser.parse_args()
    root = args.repo.resolve()
    scratch = args.scratch_dir.resolve() if args.scratch_dir else None
    if scratch is not None and (scratch == root or root in scratch.parents):
        parser.error("Choose a scratch directory outside the reviewed worktree")
    if sys.platform != "win32":
        print(json.dumps({"status": "skip", "reason": "Windows-specific wrapper diagnostic"}))
        return 0
    resolved = shutil.which("npm")
    if resolved is None or Path(resolved).suffix.lower() not in {".cmd", ".bat"}:
        print(json.dumps({"status": "skip", "reason": "npm does not resolve to a .cmd/.bat wrapper"}))
        return 0
    source = root / "scripts/pipeline.py"
    spec = importlib.util.spec_from_file_location("saq13_reviewed_pipeline", source)
    if spec is None or spec.loader is None:
        parser.error("Cannot import scripts/pipeline.py from the supplied worktree")
    pipeline = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = pipeline  # Required by dataclasses during module execution.
    spec.loader.exec_module(pipeline)
    head = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=root, check=True, capture_output=True, text=True
    ).stdout.strip()
    step = pipeline.Step("web:version", ("npm", "--version"), needs=("npm",), timeout=30)
    if scratch is not None:
        scratch.mkdir(parents=True, exist_ok=False)
    directory = nullcontext(scratch) if scratch is not None else tempfile.TemporaryDirectory(prefix="saq13-wrapper-")
    with directory as log_dir, redirect_stdout(io.StringIO()):
        results = pipeline.run_pipeline(
            pipeline.Pipeline("probe", "", (step,)), [step], root, Path(log_dir)
        )
    # Omit workstation/scratch paths from the shareable report.
    observed = [
        {"step": r.step, "status": r.status, "detail": r.detail,
         "file_not_found": any("FileNotFoundError" in line for line in r.tail)}
        for r in results
    ]
    control = subprocess.run(
        [resolved, "--version"], cwd=root, capture_output=True, text=True,
        stdin=subprocess.DEVNULL, timeout=30
    )
    report = {
        "head": head, "platform": sys.platform, "npm_wrapper": Path(resolved).name,
        "pipeline": observed, "resolved_control_exit": control.returncode,
        "resolved_control_stdout": control.stdout.strip(),
        "wrapper_resolution_mismatch": control.returncode == 0 and
            any(r["status"] == "fail" for r in observed),
    }
    print(json.dumps(report, indent=2))
    return 0  # Diagnostic output, not a CI pass/fail policy.


if __name__ == "__main__":
    raise SystemExit(main())
