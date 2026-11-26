#!/usr/bin/env bash
# test-transcripts.sh — tests for bin/transcripts.py and commands/pr-tokens.
#
# Claude Code keeps every session as JSONL under <config dir>/projects/<key>/, and each
# assistant record carries cwd, gitBranch, the model and message.usage. pr-tokens sums them for
# one branch of one repo; /mine-sessions reads the per-session usage summary. A streamed reply
# is several records with one message id, so each id counts once. The fixtures here are
# shaped like real records; nothing reads the host's own transcripts.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TX="$ROOT/bin/transcripts.py"
PRT="$ROOT/commands/pr-tokens"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected to contain: $3 | got: $2" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1" "expected NOT to contain: $3 | got: $2" ;; *) ok "$1" ;; esac; }
eq()    { [ "$2" = "$3" ] && ok "$1" || bad "$1" "expected $3, got $2"; }

echo "test-transcripts.sh"
if [ ! -f "$TX" ]; then
  echo "  FAIL bin/transcripts.py is missing"; echo; echo "0 passed, 1 failed"; exit 1
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/transcripts.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd -P "$WORK" && pwd -P)"
G=(-c user.email=t@t -c user.name=t -c init.defaultBranch=main)
R="$WORK/repo"; git "${G[@]}" init -q "$R"; git -C "$R" "${G[@]}" commit -q --allow-empty -m init
git -C "$R" remote add origin git@github.com:acme/repo.git
git -C "$R" checkout -q -b feat/x
git -C "$R" worktree add -q -b feat/y "$WORK/wt" 2>/dev/null
mkdir -p "$R/sub" "$WORK/other"
H="$WORK/home"

python3 - "$WORK" <<'EOF'
import json, re, sys
from pathlib import Path
work = Path(sys.argv[1])
repo, wt, other, home = work / "repo", work / "wt", work / "other", work / "home"
key = lambda p: re.sub(r"[^A-Za-z0-9]", "-", str(p))

def asst(mid, sid, cwd, branch, model, i, o, cw, cr, ts="2026-11-20T10:00:00.000Z", skill=None):
    content = [{"type": "text", "text": "x"}]
    if skill:
        content.append({"type": "tool_use", "id": "t" + mid, "name": "Skill", "input": {"skill": skill}})
    return {"type": "assistant", "sessionId": sid, "cwd": str(cwd), "gitBranch": branch,
            "timestamp": ts, "message": {"id": mid, "model": model, "role": "assistant",
            "content": content, "usage": {"input_tokens": i, "output_tokens": o,
            "cache_creation_input_tokens": cw, "cache_read_input_tokens": cr}}}

def user(sid, cwd, branch, text, ts="2026-11-20T09:59:00.000Z"):
    return {"type": "user", "sessionId": sid, "cwd": str(cwd), "gitBranch": branch,
            "timestamp": ts, "message": {"role": "user", "content": text}}

def write(path, records):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join((r if isinstance(r, str) else json.dumps(r, separators=(",", ":"))) + "\n"
                            for r in records))   # a str is written as the raw line

ss = home / ".claude-profiles" / "ss" / ".claude" / "projects"
al = home / ".claude-profiles" / "al" / ".claude" / "projects"
m1 = asst("m1", "s1", repo, "feat/x", "claude-opus-5-5", 10, 100, 1000, 5000, skill="testing")
write(ss / key(repo) / "s1.jsonl", [
    user("s1", repo, "feat/x", "<command-message>lets-go</command-message>\n<command-name>/lets-go</command-name>"),
    m1, m1,                                                   # one streamed reply, two records
    asst("m2", "s1", repo / "sub", "feat/x", "claude-sonnet-5-5", 1, 20, 0, 300),
    asst("m3", "s1", repo, "main", "claude-opus-5-5", 9999, 9999, 0, 0),       # another branch
    asst("mx", "s1", work / "scratch", "feat/x", "claude-opus-5-5", 0, 7, 0, 0),  # cwd left the repo
    {"type": "user", "sessionId": "s1", "cwd": str(repo), "gitBranch": "feat/x",
     "timestamp": "2026-11-20T10:02:00.000Z", "message": {"role": "user", "content": [
        {"type": "tool_result", "tool_use_id": "t1",
         "content": "grep found <command-name>/session-cleanup</command-name> in a log"}]}},
    "null", 42, "not json",                                  # odd lines must not crash a scan
])
write(ss / key(work / "repo-old") / "s7.jsonl", [       # a sibling whose key shares the prefix
    asst("my", "s7", work / "repo-old", "feat/x", "claude-opus-5-5", 6666, 6666, 0, 0)])
write(ss / key(repo) / "s1" / "subagents" / "agent-a.jsonl", [
    asst("m5", "s1", repo, "feat/x", "claude-haiku-5-5", 2, 30, 0, 0),
])
write(ss / key(wt) / "s2.jsonl", [asst("m4", "s2", wt, "feat/y", "claude-opus-5-5", 4, 40, 0, 0)])
write(ss / key(other) / "s3.jsonl", [                   # same branch name, unrelated repo
    asst("m9", "s3", other, "feat/x", "claude-opus-5-5", 8888, 8888, 0, 0)])
write(ss / key(home) / "s4.jsonl", [                    # worked on the PR from elsewhere
    {"type": "pr-link", "sessionId": "s4", "prNumber": 7, "prRepository": "acme/repo",
     "prUrl": "https://github.com/acme/repo/pull/7", "timestamp": "2026-11-20T10:00:00.000Z"},
    asst("m6", "s4", home, "main", "claude-opus-5-5", 5, 50, 0, 0),
    {"type": "pr-link", "sessionId": "s4", "prNumber": 8, "prRepository": "acme/repo",
     "prUrl": "https://github.com/acme/repo/pull/8", "timestamp": "2026-11-20T10:01:00.000Z"},
])
write(ss / key(home) / "s8.jsonl", [                    # linked to PR 7 and to another repo's PR
    {"type": "pr-link", "sessionId": "s8", "prNumber": 7, "prRepository": "acme/repo",
     "prUrl": "https://github.com/acme/repo/pull/7", "timestamp": "2026-11-20T10:00:00.000Z"},
    {"type": "pr-link", "sessionId": "s8", "prNumber": 1, "prRepository": "acme/other",
     "prUrl": "https://github.com/acme/other/pull/1", "timestamp": "2026-11-20T10:00:00.000Z"},
    asst("m10", "s8", home, "main", "claude-opus-5-5", 1, 1, 0, 0),
])
write(al / key(repo) / "s5.jsonl", [                    # a second profile
    asst("m7", "s5", repo, "feat/x", "claude-opus-5-5", 3, 300, 0, 0),
    user("s5", repo, "feat/x", "<command-name>/review-pr</command-name>"),
])
write(al / key(repo) / "s6.jsonl", [                    # outside a usage window
    user("s6", repo, "feat/x", "<command-name>/lets-go</command-name>", ts="2026-09-01T09:00:00.000Z"),
    asst("m8", "s6", repo, "feat/x", "claude-opus-5-5", 0, 0, 0, 0, ts="2026-09-01T09:00:01.000Z"),
])
EOF

tx() { env -u CLAUDE_CONFIG_DIR TRANSCRIPTS_HOME="$H" python3 "$TX" "$@" 2>&1; }
j()  { python3 -c 'import json,sys; d=json.load(sys.stdin); print(eval(sys.argv[1], {}, {"d": d}))' "$1"; }

# --- tokens for a branch ----------------------------------------------------
out="$(tx tokens --repo "$R" --branch feat/x --format json)"
eq "tokens: sessions that worked on the branch, across profiles" "$(printf '%s' "$out" | j 'sorted(d["sessions"])')" "['s1', 's5', 's6']"
eq "tokens: a streamed reply counts once, subagents count" "$(printf '%s' "$out" | j 'd["total"]["output"]')" "457"
eq "tokens: cache reads are summed" "$(printf '%s' "$out" | j 'd["total"]["cache_read"]')" "5300"
eq "tokens: split by model" "$(printf '%s' "$out" | j 'sorted(d["models"])')" "['claude-haiku-5-5', 'claude-opus-5-5', 'claude-sonnet-5-5']"
lacks "tokens: another branch of the same repo is left out" "$out" "9999"
lacks "tokens: the same branch name in another repo is left out" "$out" "8888"
eq "tokens: a record whose cwd left the repo still counts: gitBranch is the session's branch" \
  "$(tx tokens --repo "$R" --branch feat/x --format json | j 'd["total"]["output"]')" "457"
lacks "tokens: a sibling repo sharing the key prefix is left out" "$out" "6666"

out="$(tx tokens --repo "$R" --branch feat/y --format json)"
eq "tokens: a worktree of the repo counts for its branch" "$(printf '%s' "$out" | j 'd["total"]["output"]')" "40"

out="$(tx tokens --repo "$R" --branch feat/x --pr 7 --format json)"
eq "tokens: --pr adds sessions linked to the PR from anywhere" "$(printf '%s' "$out" | j 'sorted(d["sessions"])')" "['s1', 's4', 's5', 's6', 's8']"
eq "tokens: and names the ones shared with other PRs, in any repo" "$(printf '%s' "$out" | j 'd["shared"]')" "['s4', 's8']"

out="$(tx tokens --repo "$R" --branch nope --format json)"
eq "tokens: an unknown branch has no sessions" "$(printf '%s' "$out" | j 'd["sessions"]')" "[]"

# --- the PR snippet -----------------------------------------------------------
out="$( (cd "$R" && env -u CLAUDE_CONFIG_DIR TRANSCRIPTS_HOME="$H" python3 "$PRT") 2>&1)"
has "pr-tokens: a collapsible block" "$out" "<details>"
has "pr-tokens: names the branch" "$out" '`feat/x`'
has "pr-tokens: counts sessions" "$out" "**Sessions:** 3"
has "pr-tokens: one row per model" "$out" "| claude-sonnet-5-5 |"
has "pr-tokens: a total row" "$out" "| Total |"
has "pr-tokens: says where the numbers come from" "$out" "transcripts"
out="$( (cd "$WORK/wt" && git checkout -q -b empty && env -u CLAUDE_CONFIG_DIR TRANSCRIPTS_HOME="$H" python3 "$PRT"); echo "rc=$?")"
has "pr-tokens: a branch with no records says so" "$out" "No Claude Code transcript records"
has "pr-tokens: and exits 0" "$out" "rc=0"

# --- per-session usage for /mine-sessions ---------------------------------------
out="$(tx usage --since 2026-11-01 --format json)"
eq "usage: sessions in the window" "$(printf '%s' "$out" | j 'd["sessions"]')" "7"
eq "usage: typed commands, by sessions using them" "$(printf '%s' "$out" | j 'd["commands"]')" "{'lets-go': 1, 'review-pr': 1}"
eq "usage: skills Claude invoked" "$(printf '%s' "$out" | j 'd["skills"]')" "{'testing': 1}"
lacks "usage: a command name inside tool output is not a typed command" "$out" "session-cleanup"
out="$(tx usage --since 2026-08-01 --format json)"
eq "usage: a wider window reaches older sessions" "$(printf '%s' "$out" | j 'd["commands"]["lets-go"]')" "2"
out="$(tx usage --since 2026-11-01)"
has "usage: a readable table by default" "$out" "| lets-go | 1 |"

# --- what this replaces -------------------------------------------------------
[ ! -e "$ROOT/hooks/log-session-tokens" ] && ok "the ledger hook is retired" || bad "the ledger hook is retired"
[ ! -e "$ROOT/skills/pr-token-tracking" ] && [ ! -e "$ROOT/guidelines/pr-token-tracking.md" ] \
  && ok "the token-tracking skill is retired" || bad "the token-tracking skill is retired"
has "the git-workflow skill keeps the PR token rule" "$(cat "$ROOT/skills/git-workflow/SKILL.md")" "pr-tokens"
has "/mine-sessions reads the transcripts" "$(cat "$ROOT/commands/mine-sessions.md")" "transcripts.py usage"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
