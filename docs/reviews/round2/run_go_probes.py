"""Run a selected Go review probe in a disposable copy, without database connections.

Requires an installed compatible Go toolchain and an already populated module cache.
Automatic toolchain/module downloads are disabled. The reviewed worktree is not edited.
"""

import argparse
from contextlib import nullcontext
from pathlib import Path
import os
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path, help="pinned PR worktree (see README.md)")
    parser.add_argument("probe", choices=("database", "latency"))
    parser.add_argument("--scratch-dir", type=Path,
                        help="optional new directory outside the reviewed worktree; keeps the copy")
    args = parser.parse_args()
    root = args.repo.resolve()
    backend = root / "saqbol-backend"
    scratch = args.scratch_dir.resolve() if args.scratch_dir else None
    if scratch is not None and (scratch == root or root in scratch.parents):
        parser.error("Choose a scratch directory outside the reviewed worktree")
    artifacts = Path(__file__).resolve().parent
    go = shutil.which("go")
    if go is None:
        parser.error("Go is not installed or is missing from PATH")
    env = os.environ.copy()
    env.update(GOPROXY="off", GOTOOLCHAIN="local", GOTELEMETRY="off", GOMAXPROCS="2")
    # Go caches may be supplied through GOCACHE/GOMODCACHE by the caller.
    for name in ("TEST_DATABASE_URL", "TEST_REDIS_URL", "SAQ23_REVIEW_BATCH_ERROR_CHILD"):
        env.pop(name, None)
    if scratch is not None:
        scratch.mkdir(parents=True, exist_ok=False)
    directory = nullcontext(scratch) if scratch is not None else tempfile.TemporaryDirectory(prefix="saq13-go-")
    with directory as name:
        working = Path(name)
        for filename in ("go.mod", "go.sum"):
            shutil.copyfile(backend / filename, working / filename)
        if args.probe == "database":
            shutil.copyfile(artifacts / "pr21_database_guard_probe.go", working / "main.go")
            command = [go, "run", "-mod=readonly", "-buildvcs=false", "."]
        else:
            shutil.copyfile(backend / "cmd/latency/main.go", working / "main.go")
            for filename in ("latency_review_test.go", "latency_batch_review_test.go"):
                shutil.copyfile(artifacts / filename, working / filename)
            command = [go, "test", "-mod=readonly", "-count=1", "-timeout=60s", "-v", "."]
        result = subprocess.run(command, cwd=working, env=env, timeout=90)
        return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
