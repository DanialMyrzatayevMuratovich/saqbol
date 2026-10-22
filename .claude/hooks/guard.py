#!/usr/bin/env python3
"""Team rules (CONTRIBUTING.md, CLAUDE.md section 8) as a guard for AI agents and, optionally, for git.

Claude Code PreToolUse hook for Bash: reads the hook JSON on stdin and blocks the command (exit 2,
reason on stderr) when it would
  - push to main/master, force-push (--force, --force-with-lease, +refspec), push --all/--mirror,
    or delete main;
  - commit while main/master is checked out;
  - commit with a -m message that does not start with "SAQ-<id>: " or that carries AI attribution
    (Co-Authored-By: Claude, "Generated with Claude Code", ...);
  - add or commit .env files, private keys, keystores, key.properties, or text that looks like a token;
  - merge a pull request (gh pr merge).
Anything it cannot parse is allowed (fail-open): the hook must never get in the way of normal work.

Git hooks for people (opt-in, once per clone: git config core.hooksPath .githooks):
  guard.py --git-hook commit-msg <file>   strips AI attribution lines, then checks the subject
  guard.py --git-hook pre-commit          blocks commits on main and staged secrets
Stdlib only, Python 3.10+.
"""

from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

PROTECTED = {"main", "master"}
SUBJECT = re.compile(r"^SAQ-\d+: \S")
EXEMPT_SUBJECT = re.compile(r'^(Merge |Revert "|fixup! |squash! |amend! )')
AI_ATTRIBUTION = re.compile(
    r"^\s*co-authored-by:.*\b(claude|anthropic|codex|openai|chatgpt|copilot|cursor|gemini|devin|aider|windsurf)\b"
    r"|generated (with|by)\b.*\b(claude|codex|chatgpt|copilot|cursor|gemini)\b",
    re.IGNORECASE,
)
# Token shapes (from the datathon secret scan, plus YouTrack permanent tokens). Only file:line is ever printed.
SECRET = re.compile("|".join([
    r"(^|[^A-Za-z0-9_-])sk-(proj-|svcacct-|admin-|ant-)?[A-Za-z0-9_-]{20,}",
    r"gh[pousr]_[A-Za-z0-9]{36,}",
    r"github_pat_[A-Za-z0-9_]{40,}",
    r"perm-[A-Za-z0-9+/=_-]{4,}\.[A-Za-z0-9+/=_-]{4,}\.[A-Za-z0-9]{20,}",
    r"-----BEGIN ([A-Z]+ )?PRIVATE KEY-----",
    r"AKIA[0-9A-Z]{16}",
    r"AIza[0-9A-Za-z_-]{35}",
    r"xox[abpr]-[A-Za-z0-9-]{10,}",
    r"(sk|rk)_live_[0-9A-Za-z]{20,}",
    r"(^|[^A-Za-z0-9_])hf_[A-Za-z0-9]{30,}",
    r"[0-9]{8,10}:AA[A-Za-z0-9_-]{33}",
    r"eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}",
]))
SAFE_ENV = {".env.example", ".env.sample", ".env.template"}
SECRET_SUFFIXES = (".pem", ".p12", ".pfx", ".jks", ".keystore")
SECRET_NAMES = {"id_rsa", "id_ed25519", "id_ecdsa", "key.properties"}
MAX_SCAN_BYTES = 4_000_000
SEPARATORS = {";", "&", "&&", "|", "||", "|&", "(", ")", "\n"}


def git(cwd: str, *args: str, timeout: float = 5) -> str | None:
    try:
        r = subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True, encoding="utf-8",
                           errors="replace", timeout=timeout, stdin=subprocess.DEVNULL)
    except (OSError, subprocess.SubprocessError):
        return None
    return r.stdout if r.returncode == 0 else None


def current_branch(cwd: str) -> str | None:
    out = git(cwd, "symbolic-ref", "--short", "-q", "HEAD")
    return out.strip() if out else None


def is_secret_file(path: str) -> bool:
    name = os.path.basename(path.rstrip("/"))
    if name in SAFE_ENV:
        return False
    return (name == ".env" or name.startswith(".env.") or name.endswith(".env")
            or name.endswith(SECRET_SUFFIXES) or name in SECRET_NAMES)


# ---------------------------------------------------------------- shell parsing

def segments(command: str) -> list[list[str]]:
    """Split a shell command into simple commands, dropping redirections. Raises ValueError if unparsable."""
    lex = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>\n")
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    out: list[list[str]] = [[]]
    tokens = list(lex)
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in SEPARATORS:
            out.append([])
        elif tok and set(tok) <= set("<>&") and ("<" in tok or ">" in tok):
            i += 1  # redirection operator: skip its target too
        elif tok.isdigit() and i + 1 < len(tokens) and tokens[i + 1][:1] in ("<", ">"):
            pass  # file descriptor number of a redirection, e.g. the 2 in 2>&1
        else:
            out[-1].append(tok)
        i += 1
    return [s for s in out if s]


def strip_prefix(words: list[str]) -> list[str]:
    """Drop VAR=value assignments and wrappers like `env`, `command`, `time`."""
    i = 0
    while i < len(words):
        w = words[i]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", w) or w in ("env", "command", "time", "nohup", "exec"):
            i += 1
            continue
        break
    return words[i:]


def parse_git(words: list[str], cwd: str) -> tuple[str, str, list[str]] | None:
    """(directory, subcommand, args) for a git invocation, else None."""
    if not words or os.path.basename(words[0]) not in ("git", "git.exe"):
        return None
    i, where = 1, cwd
    while i < len(words) and words[i].startswith("-"):
        opt = words[i]
        if opt == "-C" and i + 1 < len(words):
            where = os.path.join(where, os.path.expanduser(words[i + 1]))
            i += 2
        elif opt in ("-c", "--git-dir", "--work-tree", "--namespace", "--exec-path") and i + 1 < len(words):
            i += 2
        else:
            i += 1
    if i >= len(words):
        return None
    return where, words[i], words[i + 1:]


# ---------------------------------------------------------------- checks

def check_push(args: list[str], where: str) -> list[str]:
    opts: list[str] = []
    positional: list[str] = []
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--":
            positional += args[i + 1:]
            break
        if a in ("--repo", "-o", "--push-option", "--receive-pack", "--exec"):
            i += 2
            continue
        (opts if a.startswith("-") else positional).append(a)
        i += 1
    short = "".join(o[1:] for o in opts if o.startswith("-") and not o.startswith("--"))
    problems = []
    if "f" in short or any(o == "--force" or o.startswith("--force-") for o in opts):
        problems.append("force push is not allowed (never rewrite shared history); push new commits instead")
    if "--mirror" in opts or "--all" in opts:
        problems.append("push --all/--mirror would push main too; push your SAQ-<id>-<slug> branch only")
    delete = "--delete" in opts or "d" in short
    refspecs = positional[1:]
    if not refspecs and not delete:
        branch = current_branch(where)
        if branch in PROTECTED:
            problems.append(f"you are on {branch}; never push to {branch} - work on a SAQ-<id>-<slug> branch "
                            "and open a pull request")
    for spec in refspecs:
        if spec.startswith("+"):
            problems.append(f"force push via '+{spec[1:]}' is not allowed")
            spec = spec[1:]
        dst = spec.split(":", 1)[1] if ":" in spec else spec
        if dst in ("HEAD", "@"):
            dst = current_branch(where) or dst
        dst = dst.removeprefix("refs/heads/")
        if dst in PROTECTED:
            verb = "delete" if delete or spec.startswith(":") else "push to"
            problems.append(f"never {verb} {dst} - it is protected; open a pull request from your task branch")
    return problems


def commit_messages(args: list[str]) -> tuple[list[str], list[str], bool]:
    """(-m messages, --trailer values, whether -a/--all was given)."""
    messages: list[str] = []
    trailers: list[str] = []
    all_flag = False
    i = 0
    while i < len(args):
        a = args[i]
        nxt = args[i + 1] if i + 1 < len(args) else ""
        if a == "--":
            break
        if a.startswith("--message="):
            messages.append(a.split("=", 1)[1])
        elif a == "--message":
            messages.append(nxt)
            i += 1
        elif a.startswith("--trailer="):
            trailers.append(a.split("=", 1)[1])
        elif a == "--trailer":
            trailers.append(nxt)
            i += 1
        elif a == "--all":
            all_flag = True
        elif a.startswith("-") and not a.startswith("--"):
            for j, ch in enumerate(a[1:]):
                if ch == "a":
                    all_flag = True
                elif ch in "mFCct":
                    value = a[2 + j:]
                    if not value:
                        value = nxt
                        i += 1
                    if ch == "m":
                        messages.append(value)
                    break
        i += 1
    return messages, trailers, all_flag


def resolve_heredoc(message: str) -> str | None:
    """The real text of -m "$(cat <<'EOF' ... EOF)"; None when the shell builds the message some other way."""
    m = re.search(r"<<-?\s*(['\"]?)(\w+)\1[^\n]*\n(.*?)\n\s*\2\s*(\n|\)|$)", message, re.DOTALL)
    if m:
        return m.group(3)
    if "$(" in message or "`" in message or re.search(r"\$\{?[A-Za-z_]", message):
        return None
    return message


def check_message(message: str) -> list[str]:
    problems = []
    lines = [ln for ln in message.strip().splitlines()]
    subject = lines[0].strip() if lines else ""
    if not EXEMPT_SUBJECT.match(subject) and not SUBJECT.match(subject):
        problems.append(f"commit message must start with 'SAQ-<id>: ' (got: {subject[:60]!r}); "
                        "e.g. 'SAQ-35: Add mobile screenshots'")
    if any(AI_ATTRIBUTION.search(ln) for ln in lines):
        problems.append("no AI attribution in commits (no Co-Authored-By: Claude / 'Generated with ...'); "
                        "the human author is responsible for the change")
    return problems


def secret_hits_in_diff(diff: str) -> list[str]:
    hits, path, line_no = [], "", 0
    for line in diff.splitlines():
        if line.startswith("+++ "):
            path = line[6:] if line.startswith("+++ b/") else line[4:]
        elif line.startswith("@@"):
            m = re.search(r"\+(\d+)", line)
            line_no = int(m.group(1)) if m else 0
        elif line.startswith("+"):
            if SECRET.search(line[1:]):
                hits.append(f"{path}:{line_no}")
            line_no += 1
    return hits


def secret_hits_in_files(root: str, paths: list[str]) -> list[str]:
    hits, budget = [], MAX_SCAN_BYTES
    for rel in paths:
        p = Path(root, rel)
        try:
            if not p.is_file() or p.stat().st_size > 1_000_000:
                continue
            data = p.read_bytes()
        except OSError:
            continue
        budget -= len(data)
        if budget < 0:
            break
        if b"\0" in data[:8192]:
            continue
        for n, line in enumerate(data.decode("utf-8", "replace").splitlines(), 1):
            if SECRET.search(line):
                hits.append(f"{rel}:{n}")
    return hits


def check_staged(where: str, include_worktree: bool = False, explicit: list[str] | None = None) -> list[str]:
    """Secret files and token-like text in what is (or, with include_worktree, is about to be) committed."""
    root = (git(where, "rev-parse", "--show-toplevel") or "").strip()
    if not root:
        return []
    names = (git(root, "diff", "--cached", "--name-only", "--diff-filter=ACMR") or "").split("\n")
    hits = secret_hits_in_diff((git(root, "diff", "--cached", "-U0", "--no-color", "--no-ext-diff",
                                    "--diff-filter=ACMR") or "")[:MAX_SCAN_BYTES])
    if include_worktree:  # `git add ... && git commit` or `commit -a`: also what is about to be staged
        real_root = os.path.realpath(root)
        scope = [os.path.relpath(os.path.realpath(os.path.join(where, p)), real_root) for p in explicit or []]
        scope = [p for p in scope if not p.startswith("..")]
        spec = ["--", *scope] if scope else []
        names += (git(root, "diff", "--name-only", "--diff-filter=ACMR", *spec) or "").split("\n") + scope
        hits += secret_hits_in_diff((git(root, "diff", "-U0", "--no-color", "--no-ext-diff", "--diff-filter=ACMR",
                                         *spec) or "")[:MAX_SCAN_BYTES])
        untracked = [p for p in (git(root, "ls-files", "--others", "--exclude-standard", *spec) or "").split("\n")
                     if p]
        names += untracked
        hits += secret_hits_in_files(root, untracked)
    problems = []
    bad = sorted({n for n in names if n and is_secret_file(n)})
    if bad:
        problems.append(f"secret files must never be committed: {', '.join(bad)} (use .env.example placeholders)")
    if hits:
        problems.append("text that looks like a token/key (file:line): " + ", ".join(sorted(set(hits))[:10])
                        + " - move the value to .env and rotate it if it was ever pushed")
    return problems


def check_add(args: list[str]) -> list[str]:
    paths = [a for a in args if not a.startswith("-")]
    bad = [p for p in paths if is_secret_file(p)]
    return [f"do not stage secret files: {', '.join(bad)}"] if bad else []


def check_command(command: str, cwd: str) -> list[str]:
    if "git" not in command and "gh" not in command:
        return []
    try:
        parts = segments(command)
    except ValueError:
        return []  # unbalanced quotes etc.: fail open
    problems: list[str] = []
    where = cwd
    adding: list[str] | None = None  # paths of a `git add` earlier in the same command ([] = everything)
    for words in parts:
        words = strip_prefix(words)
        if not words:
            continue
        if words[0] == "cd":
            target = words[1] if len(words) > 1 else "~"
            if target != "-":
                where = os.path.join(where, os.path.expanduser(target))
            continue
        if os.path.basename(words[0]) in ("gh", "gh.exe"):
            pr_merge = any(a == "pr" and b == "merge" for a, b in zip(words, words[1:]))
            if pr_merge or re.search(r"pulls/\d+/merge", " ".join(words)):
                problems.append("never merge pull requests - a human merges after the other member approves")
            continue
        parsed = parse_git(words, where)
        if not parsed:
            continue
        repo, sub, args = parsed
        if sub == "push":
            problems += check_push(args, repo)
        elif sub == "add":
            problems += check_add(args)
            explicit = [a for a in args if not a.startswith("-") and a not in (".", ":/")]
            if not explicit or any(a in (".", ":/", "-A", "--all", "-u", "--update") for a in args):
                adding = []  # everything
            elif adding != []:
                adding = (adding or []) + explicit
        elif sub == "commit":
            branch = current_branch(repo)
            if branch in PROTECTED:
                problems.append(f"you are on {branch}; create a task branch first: "
                                "git switch -c SAQ-<id>-<slug> origin/main")
            messages, trailers, all_flag = commit_messages(args)
            if messages:
                text = resolve_heredoc("\n\n".join(messages))
                if text is not None:
                    problems += check_message(text)
            if any(AI_ATTRIBUTION.search(t) for t in trailers):
                problems.append("no AI co-author trailers in commits")
            problems += check_staged(repo, include_worktree=all_flag or adding is not None, explicit=adding or None)
    return list(dict.fromkeys(problems))


# ---------------------------------------------------------------- entry points

def git_hook(args: list[str]) -> int:
    kind = args[0] if args else ""
    if kind == "commit-msg" and len(args) > 1:
        path = Path(args[1])
        try:
            raw = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            return 0
        kept = [ln for ln in raw.splitlines() if not AI_ATTRIBUTION.search(ln)]
        if len(kept) != len(raw.splitlines()):
            path.write_text("\n".join(kept).rstrip() + "\n", encoding="utf-8")
        body = "\n".join(ln for ln in kept if not ln.startswith("#"))
        problems = [p for p in check_message(body) if "AI attribution" not in p]
    elif kind == "pre-commit":
        branch = current_branch(".")
        problems = [f"committing on {branch} is not allowed; git switch -c SAQ-<id>-<slug>"] \
            if branch in PROTECTED else []
        problems += check_staged(".")
    else:
        return 0
    for p in problems:
        print(f"saqbol {kind}: {p}", file=sys.stderr)
    return 1 if problems else 0


def main(argv: list[str]) -> int:
    if len(argv) > 1 and argv[1] == "--git-hook":
        try:
            return git_hook(argv[2:])
        except Exception:  # noqa: BLE001 - a broken check must not block the commit
            return 0
    try:
        data = json.loads(sys.stdin.read() or "{}")
        if not isinstance(data, dict) or data.get("tool_name") != "Bash":
            return 0
        command = (data.get("tool_input") or {}).get("command")
        if not isinstance(command, str) or not command.strip():
            return 0
        cwd = data.get("cwd") if isinstance(data.get("cwd"), str) else os.getcwd()
        problems = check_command(command, cwd)
    except Exception:  # noqa: BLE001 - fail open on anything unexpected
        return 0
    if not problems:
        return 0
    print("Blocked by the SaqBol team-rules hook (.claude/hooks/guard.py):", file=sys.stderr)
    for p in problems:
        print(f"- {p}", file=sys.stderr)
    print("Rules: CONTRIBUTING.md and CLAUDE.md section 8. If the user really wants this, they run it themselves.",
          file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
