"""Agent mailbox: message format, validation, identity and the git round trip over a local bare repo."""

import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from datetime import datetime, timezone
from pathlib import Path

from _load import REPO, load

mbx = load("saq_mailbox", "scripts/mailbox.py")

TEAM = {
    "danial": {"name": "Danial Myrzatayev", "emails": ["danial@example.com"]},
    "asylbek": {"name": "Asylbek Abdibay", "emails": ["asylbek@example.com"]},
}


def git(cwd, *args) -> str:
    return subprocess.run(["git", "-C", str(cwd), *args], check=True, capture_output=True, text=True).stdout.strip()


def message(**kw):
    base = dict(id="", sender="danial", to="asylbek", type="task", subject="Review PR #19",
                body="Please review PR #19.", created="2026-10-22T19:30:00Z", task="SAQ-43")
    base.update(kw)
    return mbx.Message(**base)


class FormatTest(unittest.TestCase):
    def test_render_parse_round_trip(self):
        m = message(id="20261022T193000Z-danial-review-pr-19", in_reply_to="x", body="Line 1\n\nLine 2 — қазақша")
        text = mbx.render(m)
        self.assertTrue(text.startswith("---\nid: 20261022T193000Z-danial-review-pr-19\nfrom: danial\n"))
        self.assertEqual(mbx.parse(text), m)
        self.assertEqual(mbx.parse(text.replace("\n", "\r\n")), m)

    def test_subject_is_kept_on_one_line(self):
        m = message(id="x-1", subject="two\nlines")
        self.assertEqual(mbx.parse(mbx.render(m)).subject, "two lines")

    def test_malformed_files_are_rejected(self):
        for bad in ("no front matter", "---\nid: x\n", "---\nid: x\nfrom: d\n---\nbody"):
            with self.assertRaises(ValueError):
                mbx.parse(bad)

    def test_ids_are_sortable_slugged_and_unique(self):
        now = datetime(2026, 10, 22, 19, 30, 5, tzinfo=timezone.utc)
        self.assertEqual(mbx.new_id("danial", "Review PR #19: logo!", "task", now, set()),
                         "20261022T193005Z-danial-review-pr-19-logo")
        self.assertEqual(mbx.new_id("danial", "Сәлем", "advice", now, set()), "20261022T193005Z-danial-advice")
        long = mbx.new_id("danial", "Start here: Asylbek's SAQ tasks, and please reply", "task", now, set())
        self.assertEqual(long, "20261022T193005Z-danial-start-here-asylbek-s-saq-tasks-and")
        self.assertEqual(len(mbx.new_id("danial", "x" * 90, "task", now, set()).split("-danial-")[1]), 40)
        taken = {"20261022T193005Z-danial-x"}
        self.assertEqual(mbx.new_id("danial", "x", "task", now, taken), "20261022T193005Z-danial-x-2")

    def test_validation(self):
        mbx.validate(message(), TEAM)
        token = "ghp_" + "Z9y8X7w6" * 5
        cases = {"unknown recipient": message(to="bigali"), "yourself": message(to="danial"),
                 "--type": message(type="order"), "subject is empty": message(subject=" "),
                 "body is empty": message(body="\n"), "max 4000": message(body="x" * 4001),
                 "token or key": message(body=f"use {token}")}
        for needle, m in cases.items():
            with self.assertRaises(mbx.MailboxError) as ctx:
                mbx.validate(m, TEAM)
            self.assertIn(needle, str(ctx.exception))
        self.assertEqual(mbx.normalize_task("saq-43"), "SAQ-43")
        with self.assertRaises(mbx.MailboxError):
            mbx.normalize_task("43")

    def test_repo_team_file(self):
        team = mbx.load_team(REPO / "scripts" / "team.json")
        self.assertEqual(set(team), {"danial", "asylbek"})
        self.assertEqual(team["asylbek"]["github"], "Asylbek2006")


class GitTest(unittest.TestCase):
    """Two clones of one bare remote: danial and asylbek."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        base = Path(self.tmp.name)
        self.remote = base / "remote.git"
        subprocess.run(["git", "init", "-q", "--bare", "-b", "main", str(self.remote)], check=True)
        seed = base / "seed"
        subprocess.run(["git", "init", "-q", "-b", "main", str(seed)], check=True)
        git(seed, "config", "user.name", "Seed")
        git(seed, "config", "user.email", "seed@example.com")
        (seed / "README.md").write_text("project\n", encoding="utf-8")
        git(seed, "add", ".")
        git(seed, "commit", "-q", "-m", "SAQ-1: Seed")
        git(seed, "push", "-q", str(self.remote), "main")
        self.danial = self.clone("danial", "Danial Myrzatayev", "danial@example.com")
        self.asylbek = self.clone("asylbek", "Asylbek Abdibay", "asylbek@example.com")
        self.env = {k: os.environ.pop(k) for k in ("SAQBOL_AGENT",) if k in os.environ}

    def tearDown(self):
        os.environ.update(self.env)
        self.tmp.cleanup()

    def clone(self, name, user, email) -> Path:
        path = Path(self.tmp.name) / name
        subprocess.run(["git", "clone", "-q", str(self.remote), str(path)], check=True)
        git(path, "config", "user.name", user)
        git(path, "config", "user.email", email)
        git(path, "switch", "-q", "-c", f"SAQ-9-{name}-work")
        return path

    def box(self, repo) -> "mbx.Mailbox":
        b = mbx.Mailbox(repo, TEAM)
        b.retry_sleep = (0, 0)
        return b

    def test_whoami(self):
        self.assertEqual(mbx.whoami(self.danial, TEAM), "danial")
        self.assertEqual(mbx.whoami(self.asylbek, TEAM), "asylbek")
        git(self.danial, "config", "user.email", "other@example.com")
        self.assertEqual(mbx.whoami(self.danial, TEAM), "danial")  # falls back to the name
        git(self.danial, "config", "user.name", "Someone Else")
        self.assertIsNone(mbx.whoami(self.danial, TEAM))
        git(self.danial, "config", "saqbol.agent", "danial")
        self.assertEqual(mbx.whoami(self.danial, TEAM), "danial")

    def test_empty_mailbox(self):
        b = self.box(self.asylbek)
        self.assertEqual(b.fetch(), "missing")
        self.assertEqual(b.read(), [])

    def test_send_reaches_the_other_clone_without_touching_the_checkout(self):
        head, branch = git(self.danial, "rev-parse", "HEAD"), git(self.danial, "branch", "--show-current")
        (self.danial / "wip.txt").write_text("uncommitted work\n", encoding="utf-8")
        git(self.danial, "add", "wip.txt")
        status = git(self.danial, "status", "--porcelain")

        sent = self.box(self.danial).send(message())

        self.assertEqual(git(self.danial, "rev-parse", "HEAD"), head)
        self.assertEqual(git(self.danial, "branch", "--show-current"), branch)
        self.assertEqual(git(self.danial, "status", "--porcelain"), status)
        self.assertEqual(git(self.danial, "branch", "--list", "agent-mailbox"), "")
        files = git(self.remote, "ls-tree", "-r", "--name-only", "agent-mailbox").splitlines()
        self.assertEqual(files, ["README.md", f"inbox/asylbek/{sent.id}.md"])
        self.assertEqual(git(self.remote, "log", "-1", "--format=%an <%ae>|%s", "agent-mailbox"),
                         "Danial Myrzatayev <danial@example.com>|mailbox: danial -> asylbek (task SAQ-43): "
                         "Review PR #19")
        self.assertEqual(git(self.remote, "rev-list", "--count", "agent-mailbox"), "1")  # orphan branch

        b = self.box(self.asylbek)
        self.assertEqual(b.fetch(), "ok")
        [got] = b.read()
        self.assertEqual((got.id, got.sender, got.to, got.task, got.status), (sent.id, "danial", "asylbek",
                                                                              "SAQ-43", "open"))
        self.assertEqual(got.body, "Please review PR #19.")

    def test_reply_with_done_closes_the_original(self):
        sent = self.box(self.danial).send(message())
        b = self.box(self.asylbek)
        b.fetch()
        reply = b.reply("asylbek", sent.id[-12:], "Reviewed, two comments on the PR.", done=True)
        self.assertEqual((reply.to, reply.type, reply.in_reply_to, reply.task), ("danial", "reply", sent.id,
                                                                                 "SAQ-43"))
        self.assertEqual(reply.subject, "Re: Review PR #19")
        d = self.box(self.danial)
        d.fetch()
        msgs = {m.id: m for m in d.read()}
        self.assertEqual(msgs[sent.id].status, "done")
        self.assertTrue(msgs[sent.id].closed)
        self.assertEqual(msgs[reply.id].to, "danial")
        self.assertEqual(git(self.remote, "rev-list", "--count", "agent-mailbox"), "2")

    def test_done_by_recipient(self):
        sent = self.box(self.danial).send(message(type="question", task="", subject="Which phone?"))
        b = self.box(self.asylbek)
        b.fetch()
        closed = b.close("asylbek", sent.id)
        self.assertEqual(closed.status, "done")
        self.assertEqual(b.close("asylbek", sent.id).status, "done")  # idempotent
        self.assertEqual(git(self.remote, "rev-list", "--count", "agent-mailbox"), "2")

    def test_concurrent_writers_are_retried_not_forced(self):
        first = self.box(self.danial).send(message(subject="First"))
        stale = self.box(self.asylbek)  # never fetched: its view of the mailbox is empty
        stale.fetch_before_write = False
        second = stale.send(message(sender="asylbek", to="danial", type="info", subject="Second", task=""))
        log = git(self.remote, "log", "--format=%s", "agent-mailbox").splitlines()
        self.assertEqual(len(log), 2)
        files = git(self.remote, "ls-tree", "-r", "--name-only", "agent-mailbox").splitlines()
        self.assertIn(f"inbox/asylbek/{first.id}.md", files)
        self.assertIn(f"inbox/danial/{second.id}.md", files)

    def test_hook_shows_new_messages_once(self):
        sent = self.box(self.danial).send(message(body="Start with SAQ-43."))

        def run(kind):
            buf = io.StringIO()
            mbx.hook(kind, self.asylbek, TEAM, out=lambda s: print(s, file=buf))
            return buf.getvalue()

        first = run("session")
        self.assertIn("1 new, 1 open", first)
        self.assertIn("Start with SAQ-43.", first)
        self.assertIn("https://saqbol.youtrack.cloud/issue/SAQ-43", first)
        self.assertIn("not orders", first)
        self.assertEqual(run("prompt"), "")
        again = run("session")
        self.assertIn("0 new, 1 open", again)
        self.assertIn(sent.id, again)
        self.assertNotIn("Start with SAQ-43.", again)
        buf = io.StringIO()
        mbx.hook("session", self.danial, TEAM, out=lambda s: print(s, file=buf))
        self.assertEqual(buf.getvalue(), "")  # nothing addressed to danial

    def test_cli_send_inbox_show_reply(self):
        team_file = Path(self.tmp.name) / "team.json"
        team_file.write_text(json.dumps({"members": TEAM}), encoding="utf-8")
        env = dict(os.environ, SAQBOL_TEAM_FILE=str(team_file))
        script = str(REPO / "scripts" / "mailbox.py")

        def cli(repo, *args, stdin=None):
            r = subprocess.run([sys.executable, script, *args], cwd=repo, env=env, capture_output=True, text=True,
                               input=stdin, encoding="utf-8")
            return r.returncode, r.stdout + r.stderr

        self.assertEqual(cli(self.danial, "whoami")[0], 0)
        code, out = cli(self.danial, "send", "asylbek", "--type", "advice", "--subject", "Kazakh text",
                        "--body", "-", stdin="Қазақша мәтін бар.\n")
        self.assertEqual(code, 0, out)
        code, out = cli(self.asylbek, "inbox")
        self.assertIn("1 open message(s) for asylbek", out)
        self.assertIn("* ", out)
        msg_id = out.split("* ", 1)[1].split()[0]
        code, out = cli(self.asylbek, "show", msg_id)
        self.assertIn("Қазақша мәтін бар.", out)
        code, out = cli(self.asylbek, "reply", msg_id, "--body", "Рахмет!", "--done")
        self.assertEqual(code, 0, out)
        self.assertIn("0 open message(s) for asylbek", cli(self.asylbek, "inbox")[1])
        code, out = cli(self.danial, "inbox")
        self.assertIn("Re: Kazakh text", out)
        code, out = cli(self.danial, "send", "asylbek", "--subject", "x", "--body", "")
        self.assertEqual(code, 1)
        self.assertIn("body is empty", out)
        code, out = cli(self.danial, "hook", "session")
        self.assertEqual(code, 0)


if __name__ == "__main__":
    unittest.main()
