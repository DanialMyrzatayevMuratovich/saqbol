"""The PreToolUse guard (.claude/hooks/guard.py): sample hook JSON in, allow (0) or block (2) out."""

import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

from _load import REPO, load

guard = load("saq_guard", ".claude/hooks/guard.py")
HOOK = REPO / ".claude" / "hooks" / "guard.py"
# Built at runtime so this file itself never contains a token-shaped string.
FAKE_GH_TOKEN = "ghp_" + "A1b2C3d4" * 5
FAKE_YT_TOKEN = "perm-" + "YWRtaW4=" + ".NDMtMA==." + "x9" * 15


def sh(cwd, *args):
    subprocess.run(args, cwd=cwd, check=True, capture_output=True)


def make_repo(path: Path, branch: str) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    sh(path, "git", "init", "-q", "-b", "main")
    sh(path, "git", "config", "user.name", "Test User")
    sh(path, "git", "config", "user.email", "test@example.com")
    (path / ".gitignore").write_text(".env\n", encoding="utf-8")
    (path / "README.md").write_text("hello\n", encoding="utf-8")
    sh(path, "git", "add", ".")
    sh(path, "git", "commit", "-q", "-m", "SAQ-1: Initial")
    if branch != "main":
        sh(path, "git", "switch", "-q", "-c", branch)
    return path


def run_hook(payload, timeout=10):
    data = payload if isinstance(payload, str) else json.dumps(payload)
    started = time.monotonic()
    r = subprocess.run([sys.executable, str(HOOK)], input=data, capture_output=True, text=True, timeout=timeout)
    return r.returncode, r.stderr, time.monotonic() - started


def bash(command, cwd):
    return {"session_id": "t", "hook_event_name": "PreToolUse", "tool_name": "Bash", "cwd": str(cwd),
            "tool_input": {"command": command, "description": "test"}}


class GuardTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        base = Path(cls.tmp.name)
        cls.task = make_repo(base / "task", "SAQ-85-agent-tooling")
        cls.main = make_repo(base / "on-main", "main")

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def blocked(self, command, cwd=None):
        return guard.check_command(command, str(cwd or self.task))

    def assertAllowed(self, command, cwd=None):
        self.assertEqual(self.blocked(command, cwd), [], command)

    def assertBlocked(self, command, needle, cwd=None):
        problems = self.blocked(command, cwd)
        self.assertTrue(any(needle in p for p in problems), f"{command!r} -> {problems}")

    # ---- push
    def test_normal_pushes_are_allowed(self):
        self.assertAllowed("git push -u origin SAQ-85-agent-tooling")
        self.assertAllowed("git push")
        self.assertAllowed("git push origin HEAD")
        self.assertAllowed("git push origin --delete SAQ-12-old-branch")
        self.assertAllowed("git push origin 5f3c2a1:refs/heads/agent-mailbox")

    def test_push_to_main_is_blocked(self):
        self.assertBlocked("git push origin main", "never push to main")
        self.assertBlocked("git push origin HEAD:main", "never push to main")
        self.assertBlocked("git push origin SAQ-1-x:refs/heads/master", "never push to master")
        self.assertBlocked("cd /tmp && git -C '%s' push origin HEAD" % self.main, "never push to main")
        self.assertBlocked("git push", "you are on main", cwd=self.main)
        self.assertBlocked("git push origin", "you are on main", cwd=self.main)
        self.assertBlocked("git push origin --delete main", "never delete main")
        self.assertBlocked("git push origin :main", "never delete main")
        self.assertBlocked("git push --all origin", "--all/--mirror")

    def test_force_push_is_blocked(self):
        for cmd in ("git push --force origin SAQ-85-agent-tooling", "git push -f",
                    "git push -uf origin SAQ-85-x", "git push --force-with-lease",
                    "git push --force-with-lease=SAQ-85-x:abc origin SAQ-85-x", "git push origin +SAQ-85-x"):
            self.assertBlocked(cmd, "force push")

    # ---- commit
    def test_good_commit_messages_are_allowed(self):
        self.assertAllowed('git commit -m "SAQ-85: Add the mailbox CLI" -m "Body text."')
        self.assertAllowed("git commit -am 'SAQ-85: Fix the hook'")
        self.assertAllowed("git commit --message='SAQ-7: Update requirements'")
        self.assertAllowed('git commit -m "Merge branch main into SAQ-85-agent-tooling"')
        self.assertAllowed("git commit --amend --no-edit")
        self.assertAllowed("git commit -F /tmp/msg.txt")
        self.assertAllowed('git commit -m "$MSG"')
        heredoc = "git commit -m \"$(cat <<'EOF'\nSAQ-85: Add guard\n\nWhy it matters.\nEOF\n)\""
        self.assertAllowed(heredoc)

    def test_bad_commit_messages_are_blocked(self):
        self.assertBlocked('git commit -m "Add the mailbox"', "must start with 'SAQ-<id>: '")
        self.assertBlocked('git commit -m "saq-85: lower case"', "must start with")
        self.assertBlocked('git commit -m "SAQ-85 missing colon"', "must start with")
        heredoc = "git add x && git commit -m \"$(cat <<'EOF'\nAdd guard\nEOF\n)\""
        self.assertBlocked(heredoc, "must start with")

    def test_ai_attribution_is_blocked(self):
        msg = "SAQ-85: Add guard\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
        self.assertBlocked(f'git commit -m "{msg}"', "AI attribution")
        self.assertBlocked('git commit -m "SAQ-1: x" -m "Generated with Claude Code"', "AI attribution")
        self.assertBlocked('git commit -m "SAQ-1: x" --trailer "Co-authored-by: Copilot <x@y>"', "co-author")

    def test_commit_on_main_is_blocked(self):
        self.assertBlocked('git commit -m "SAQ-1: x"', "you are on main", cwd=self.main)

    def test_secrets_in_staged_files_are_blocked(self):
        repo = make_repo(Path(self.tmp.name) / "secrets", "SAQ-2-x")
        (repo / "config.txt").write_text(f"token = {FAKE_GH_TOKEN}\n", encoding="utf-8")
        sh(repo, "git", "add", "config.txt")
        self.assertBlocked('git commit -m "SAQ-2: Add config"', "config.txt:1", cwd=repo)
        sh(repo, "git", "reset", "-q")
        # not staged yet, but added in the same command
        self.assertBlocked('git add -A && git commit -m "SAQ-2: Add config"', "config.txt:1", cwd=repo)
        self.assertAllowed('git commit -m "SAQ-2: Nothing staged"', cwd=repo)
        (repo / "config.txt").write_text(f"yt = {FAKE_YT_TOKEN}\n", encoding="utf-8")
        self.assertBlocked('git add config.txt; git commit -m "SAQ-2: Add config"', "config.txt:1", cwd=repo)
        # a tracked file that gains a token, committed with -a
        (repo / "config.txt").write_text("clean = 1\n", encoding="utf-8")
        sh(repo, "git", "add", "config.txt")
        sh(repo, "git", "commit", "-q", "-m", "SAQ-2: Clean config")
        self.assertAllowed('git commit -am "SAQ-2: Nothing new"', cwd=repo)
        (repo / "config.txt").write_text(f"clean = 1\ntoken = {FAKE_GH_TOKEN}\n", encoding="utf-8")
        self.assertBlocked('git commit -am "SAQ-2: Add token"', "config.txt:2", cwd=repo)

    def test_secret_files_are_blocked(self):
        repo = make_repo(Path(self.tmp.name) / "envfiles", "SAQ-3-x")
        (repo / ".env").write_text("JWT_ACCESS_SECRET=abc\n", encoding="utf-8")
        self.assertBlocked("git add -f .env", "do not stage secret files", cwd=repo)
        self.assertBlocked("git add saqbol-backend/.env.local", "do not stage", cwd=repo)
        self.assertBlocked("git add android/key.properties", "do not stage", cwd=repo)
        self.assertAllowed("git add .env.example saqbol-ml/.env.example", cwd=repo)
        sh(repo, "git", "add", "-f", ".env")
        self.assertBlocked('git commit -m "SAQ-3: Oops"', "secret files must never be committed", cwd=repo)

    # ---- gh
    def test_merging_prs_is_blocked(self):
        self.assertBlocked("gh pr merge 28 --merge", "never merge pull requests")
        self.assertBlocked("gh -R DanialMyrzatayevMuratovich/saqbol pr merge 28", "never merge")
        self.assertBlocked("gh api -X PUT repos/o/r/pulls/28/merge", "never merge")
        self.assertAllowed("gh pr create --base main --title 'SAQ-85: x' --body-file -")
        self.assertAllowed("gh pr view 28")

    # ---- parsing
    def test_unrelated_and_quoted_text_is_allowed(self):
        self.assertAllowed("ls -la && echo 'git push --force origin main' > notes.txt")
        self.assertAllowed("python3 scripts/mailbox.py send asylbek --body 'never git push -f to main'")
        self.assertAllowed("go test ./... 2>&1 | tail -5")
        self.assertAllowed("git status && git log --oneline -3")
        self.assertAllowed("git push origin SAQ-85-x 2>&1 | tail -3")

    def test_segments(self):
        self.assertEqual(guard.segments("cd a && git push origin x 2>&1 | tail -3; echo ok"),
                         [["cd", "a"], ["git", "push", "origin", "x"], ["tail", "-3"], ["echo", "ok"]])
        self.assertEqual(guard.segments("git add .\ngit status"), [["git", "add", "."], ["git", "status"]])


class HookProcessTest(unittest.TestCase):
    """The hook as Claude Code runs it: JSON on stdin, exit code and stderr out, fast, fail-open."""

    def test_block_allow_and_fail_open(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = make_repo(Path(tmp) / "r", "SAQ-9-x")
            code, err, seconds = run_hook(bash("git push --force origin SAQ-9-x", repo))
            self.assertEqual(code, 2)
            self.assertIn("force push", err)
            self.assertLess(seconds, 3)
            code, err, _ = run_hook(bash('git commit -m "SAQ-9: Fine"', repo))
            self.assertEqual((code, err), (0, ""))
        for odd in ("", "not json", "[]", json.dumps({"tool_name": "Read", "tool_input": {"file_path": "x"}}),
                    json.dumps({"tool_name": "Bash", "tool_input": {}}),
                    json.dumps({"tool_name": "Bash", "tool_input": {"command": "echo 'unbalanced"}}),
                    json.dumps({"tool_name": "Bash", "cwd": "/definitely/missing",
                                "tool_input": {"command": "git push"}})):
            code, err, _ = run_hook(odd)
            self.assertEqual(code, 0, odd)


class GitHookTest(unittest.TestCase):
    def test_commit_msg_strips_ai_lines_and_checks_subject(self):
        with tempfile.TemporaryDirectory() as tmp:
            msg = Path(tmp) / "COMMIT_EDITMSG"
            msg.write_text("SAQ-4: Add x\n\nBody\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n# comment\n",
                           encoding="utf-8")
            self.assertEqual(guard.git_hook(["commit-msg", str(msg)]), 0)
            self.assertNotIn("Co-Authored-By", msg.read_text(encoding="utf-8"))
            msg.write_text("Add x without task\n", encoding="utf-8")
            self.assertEqual(guard.git_hook(["commit-msg", str(msg)]), 1)
            msg.write_text('Revert "SAQ-4: Add x"\n', encoding="utf-8")
            self.assertEqual(guard.git_hook(["commit-msg", str(msg)]), 0)

    def test_pre_commit_blocks_main_and_secrets(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = make_repo(Path(tmp) / "r", "main")
            old = os.getcwd()
            os.chdir(repo)
            try:
                self.assertEqual(guard.git_hook(["pre-commit"]), 1)
                sh(repo, "git", "switch", "-q", "-c", "SAQ-5-x")
                self.assertEqual(guard.git_hook(["pre-commit"]), 0)
                (repo / "a.txt").write_text(FAKE_GH_TOKEN + "\n", encoding="utf-8")
                sh(repo, "git", "add", "a.txt")
                self.assertEqual(guard.git_hook(["pre-commit"]), 1)
            finally:
                os.chdir(old)


if __name__ == "__main__":
    unittest.main()
