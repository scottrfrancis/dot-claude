#!/usr/bin/env bash
# install.sh — set a host's Claude Code config up from this checkout, or check it.
#
# Claude Code reads its config from a config dir: ~/.claude, a HOME-swapped profile's
# ~/.claude, or $CLAUDE_CONFIG_DIR. For each config dir that takes its CLAUDE.md from this
# checkout, the installer
#   - links bin/, rules/, doctrine/, memory/, host.md and each skill into it, unless the
#     config dir is the checkout itself;
#   - enables the hooks plugin (marketplace/plugins/hooks) in its settings.json, and removes
#     the hand-written registrations the plugin replaces, after a backup.
# Once per host it creates host.md in the checkout, from --doctrine.
#
#   install.sh [--apply | --check] [--doctrine NAME|none] [CONFIG_DIR...]
#
# A dry run unless --apply. --check only reads: it prints each problem with the command that
# fixes it, and exits 1 if there is one; bin/session-status.sh runs it at session start.
# With no CONFIG_DIR, every config dir of this checkout is found: <home>/.claude, and each
# <home>/.claude-profiles/*/.claude or <home>/.claude-* whose CLAUDE.md links here. Nothing
# the installer did not create is replaced, and only dangling links into skills/ are removed.
#
#   --doctrine NAME   create host.md importing doctrine/NAME.md (a homelab host: homelab)
#   --doctrine none   create an empty host.md (a host outside the homelab)
#
#   INSTALL_HOME   the login home to search (default: the real one, not a profile's $HOME)
set -uo pipefail

MODE=dry
DOCTRINE=""
DIRS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) MODE=apply; shift ;;
    --check) MODE=check; shift ;;
    --doctrine)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        printf 'install.sh: --doctrine needs a value: a name from doctrine/, or none\n' >&2; exit 2
      fi
      DOCTRINE="$2"; shift 2 ;;
    --doctrine=*) DOCTRINE="${1#--doctrine=}"; shift ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) printf 'install.sh: unknown option %s (see --help)\n' "$1" >&2; exit 2 ;;
    *) DIRS+=("$1"); shift ;;
  esac
done

REPO="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fix_for() { printf '%s' "$REPO/bin/install.sh --apply $1"; } # the command that fixes config dir $1
# Top-level items a config dir needs: bin/ for scripts, rules/ for the path-scoped rules,
# doctrine/ and host.md for the host import, memory/ for the universal memory import.
TOP_ITEMS=(bin rules doctrine memory host.md)

phys() { (cd -P "$1" 2>/dev/null && pwd -P); }

# The login home, which is not $HOME in a HOME-swapped profile. /Users comes first because
# dscl returns nothing under the macOS sandbox.
real_home() {
  local u h
  u="$(id -un 2>/dev/null || printf '%s' "${USER:-}")"
  if [ -n "$u" ] && [ -d "/Users/$u" ]; then printf '%s\n' "/Users/$u"; return; fi
  h="$( { getent passwd "$u" | cut -d: -f6; } 2>/dev/null || true)"
  [ -z "$h" ] && h="$( { dscl . -read "/Users/$u" NFSHomeDirectory | awk '{print $2}'; } 2>/dev/null || true)"
  printf '%s\n' "${h:-$HOME}"
}
H="${INSTALL_HOME:-${LINK_CONFIG_HOME:-$(real_home)}}"

# The HOME a session using config dir $1 runs with, which is what ~ means in its CLAUDE.md
# imports and hook commands: a HOME-swapped profile's <home>/.claude has its own, and a
# CLAUDE_CONFIG_DIR dir runs under the login home.
tilde_home() {
  if [ "$(basename "$1")" = .claude ]; then dirname "$1"; else printf '%s\n' "$H"; fi
}

if [ -n "$DOCTRINE" ] && [ "$DOCTRINE" != none ] && [ ! -f "$REPO/doctrine/$DOCTRINE.md" ]; then
  names=""
  for f in "$REPO"/doctrine/*.md; do [ -f "$f" ] && names="$names$(basename "$f" .md) "; done
  printf 'install.sh: there is no doctrine/%s.md; choose one of: %snone\n' "$DOCTRINE" "$names" >&2
  exit 2
fi

ours() { # $1 = config dir: is it this checkout, or does its CLAUDE.md come from it?
  local t
  [ "$(phys "$1")" = "$REPO" ] && return 0
  [ -L "$1/CLAUDE.md" ] || return 1
  t="$(readlink -f "$1/CLAUDE.md" 2>/dev/null)" || return 1
  [ -n "$t" ] && [ "$(phys "$(dirname "$t")")" = "$REPO" ]
}

EXPLICIT=0
if [ "${#DIRS[@]}" -gt 0 ]; then
  # A config dir named on the command line that does not use this checkout is left alone:
  # its skills, rules and hooks are somebody else's.
  EXPLICIT=1; named=("${DIRS[@]}"); DIRS=()
  for d in "${named[@]}"; do
    if ours "$d"; then DIRS+=("$d")
    elif [ "$MODE" != check ]; then
      printf 'skip %s (its CLAUDE.md does not come from %s; link it to %s/CLAUDE.md first)\n' "$d" "$REPO" "$REPO"
    fi
  done
else
  seen=" "
  for d in "$H/.claude" "$H"/.claude-profiles/*/.claude "$H"/.claude-*; do
    if [ ! -d "$d" ] || ! ours "$d"; then continue; fi
    p="$(phys "$d")"
    case "$seen" in *" $p "*) continue ;; esac
    seen="$seen$p "
    DIRS+=("$d")
  done
fi
# Nothing to do: stop before host.md is written. bash 3.2 also treats "${DIRS[@]}" of an empty
# array as unset under set -u.
if [ "${#DIRS[@]}" -eq 0 ]; then
  [ "$EXPLICIT" -eq 1 ] && { [ "$MODE" = check ] && exit 0; exit 1; }
  printf 'install.sh: no config dir of %s found under %s; name one, or set INSTALL_HOME\n' "$REPO" "$H" >&2
  exit 1
fi

verb() { if [ "$MODE" = apply ]; then printf '%s' "$1"; else printf 'would %s' "$1"; fi; }
changes=0; problems=0; errors=0
problem() { problems=$((problems + 1)); printf '%s\n' "$1"; }

# --- host.md --------------------------------------------------------------------------------
HOSTMD="$REPO/host.md"
if [ "$MODE" != check ] && [ ! -e "$HOSTMD" ]; then
  if [ -z "$DOCTRINE" ]; then
    printf 'host.md: %s is missing; re-run with --doctrine homelab on a homelab host, or --doctrine none elsewhere\n' "$HOSTMD"
  else
    line=""; [ "$DOCTRINE" = none ] || line="@~/.claude/doctrine/$DOCTRINE.md"
    printf '%s %s (%s)\n' "$(verb create)" "$HOSTMD" "${line:-empty}"
    changes=$((changes + 1))
    if [ "$MODE" = apply ]; then
      if [ -n "$line" ]; then printf '%s\n' "$line" > "$HOSTMD"; else : > "$HOSTMD"; fi
    fi
  fi
fi

# --- links ----------------------------------------------------------------------------------
link_item() { # $1 = link path, $2 = target
  if [ -L "$1" ]; then
    # Already there, however the link is spelled (relative, through another symlink).
    [ "$(readlink "$1")" = "$2" ] && return
    [ "$(readlink -f "$1" 2>/dev/null)" = "$(readlink -f "$2" 2>/dev/null)" ] && return
  fi
  if [ -e "$1" ] || [ -L "$1" ]; then
    printf 'skip %s (exists and is not a link to %s)\n' "$1" "$2"
    return
  fi
  printf '%s %s -> %s\n' "$(verb link)" "$1" "$2"
  changes=$((changes + 1))
  if [ "$MODE" = apply ]; then mkdir -p "$(dirname "$1")" && ln -s "$2" "$1"; fi
}

link_dir() { # $1 = config dir
  local d="$1" item s name l
  for item in "${TOP_ITEMS[@]}"; do
    if [ -e "$REPO/$item" ] || { [ "$item" = host.md ] && [ -n "$DOCTRINE" ]; }; then
      link_item "$d/$item" "$REPO/$item"
    fi
  done
  for s in "$REPO"/skills/*/; do
    name="$(basename "$s")"
    [ "$name" = synced ] && continue
    [ -f "$s/SKILL.md" ] || continue
    link_item "$d/skills/$name" "$REPO/skills/$name"
  done
  # A skill removed from the repo leaves a dangling link behind. Remove only those.
  for l in "$d"/skills/*; do
    [ -L "$l" ] && [ ! -e "$l" ] || continue
    case "$(readlink "$l")" in
      "$REPO/skills/"*)
        printf '%s %s (its skill is gone)\n' "$(verb unlink)" "$l"
        changes=$((changes + 1))
        [ "$MODE" = apply ] && rm "$l"
        ;;
    esac
  done
}

check_links() { # $1 = config dir
  local d="$1" s name total=0 unlinked=0 item missing=""
  for s in "$REPO"/skills/*/; do
    name="$(basename "$s")"
    [ "$name" = synced ] && continue
    [ -f "$s/SKILL.md" ] || continue
    total=$((total + 1))
    [ -f "$d/skills/$name/SKILL.md" ] || unlinked=$((unlinked + 1))
  done
  [ "$unlinked" -gt 0 ] && \
    problem "skills: $unlinked of $total dot-claude skills are not linked into $d, so they never load there; run $(fix_for "$d")"
  [ -d "$REPO/rules" ] && [ ! -d "$d/rules" ] && \
    problem "rules: $d has no rules/, so the file-type rules never load there; run $(fix_for "$d")"
  for item in bin doctrine memory; do
    [ -e "$REPO/$item" ] && [ ! -e "$d/$item" ] && missing="${missing:+$missing, }$item/"
  done
  [ -n "$missing" ] && problem "links: $d has no $missing; run $(fix_for "$d")"
  return 0
}

# CLAUDE.md imports ~/.claude/host.md, and Claude Code skips a missing import without a word.
hostmd_reported=0
check_hostmd() { # $1 = config dir
  local home f imp ip
  home="$(tilde_home "$1")"; f="$home/.claude/host.md"
  if [ ! -f "$f" ]; then
    if [ ! -f "$HOSTMD" ]; then
      [ "$hostmd_reported" -eq 1 ] && return 0
      hostmd_reported=1
      problem "host.md: $HOSTMD is missing, so this host loads no host doctrine; run $REPO/bin/install.sh --doctrine homelab --apply on a homelab host, or --doctrine none elsewhere"
    else
      problem "host.md: $f is missing, so $1 loads no host doctrine; run $(fix_for "$1")"
    fi
    return 0
  fi
  while IFS= read -r imp; do
    ip="${imp#@}"
    case "$ip" in \~/*) ip="$home/${ip:2}" ;; esac
    [ -e "$ip" ] || problem "host.md: $f imports $ip, which does not exist; run $(fix_for "$1")"
  done < <(grep -E '^@[^[:space:]]+' "$f" 2>/dev/null | sed 's/[[:space:]].*$//')
  return 0
}

# --- settings.json --------------------------------------------------------------------------
# Python reads and writes the JSON. Exit status: 0 nothing to do, 10 changes planned or made,
# 20 problems found (--check), 30 an error.
read -r -d '' SETTINGS_PY <<'PY'
import json, os, re, shlex, shutil, sys, time
if sys.version_info < (3, 8):
    print("hooks: install.sh needs Python 3.8 or later to read settings.json")
    sys.exit(30)
mode, path, repo, home, fix = sys.argv[1:6]
KEY, MKT = "hooks@dot-claude", "dot-claude"
mkt_path = os.path.join(repo, "marketplace")
spec = os.path.join(mkt_path, "plugins", "hooks", "hooks", "hooks.json")
try:
    with open(spec) as f:
        spec_hooks = json.load(f)["hooks"]
    plugin = {}  # script name -> (event, matcher) as the plugin registers it
    for ev, groups in spec_hooks.items():
        for g in groups:
            for h in g["hooks"]:
                for name in re.findall(r"/hooks/([\w.-]+)", h["command"]):
                    plugin[name] = (ev, g.get("matcher"))
except (OSError, ValueError, KeyError, TypeError, AttributeError) as e:
    print(f"hooks: cannot read the plugin's {spec}: {e}")
    sys.exit(30)
# Retired scripts a hand-written entry may still name: the old name of session-status.sh, and
# the skill gate, which is gone (None: on any event).
RETIRED = {"load-handoff-context.sh": plugin.get("session-status.sh", ("SessionStart", None)),
           "skill-gate.py": (None, None)}
hooks_dir = os.path.realpath(os.path.join(repo, "hooks"))

def words(cmd):
    try:
        lx = shlex.shlex(cmd, posix=True, punctuation_chars=True)
        lx.whitespace_split = True
        return list(lx)
    except ValueError:
        return None

def expand(w):
    """A word with ~ or $HOME resolved against the config dir's home, and whether it had one."""
    for pre in ("~/", "$HOME/", "${HOME}/"):
        if w.startswith(pre):
            return os.path.join(home, w[len(pre):]), True
    return w, False

def own(event, matcher, cmd):
    """The script name when a hand-written entry is one the plugin replaces, else None.

    Only an entry that runs the script alone (behind an interpreter at most), from
    ~/.claude/hooks/ or this checkout's hooks/, on the plugin's event and with no narrower or
    different matcher. A same-named script elsewhere, a chained or wrapped command (shlex
    splits ; && | into words of their own), or a registration for another event or matcher
    is somebody's own and stays."""
    if not isinstance(cmd, str) or "CLAUDE_PLUGIN_ROOT" in cmd:
        return None
    ws = words(cmd)
    if not ws:
        return None
    if ws[0] in ("bash", "sh", "python3", "python"):
        ws = ws[1:]
    if len(ws) != 1:
        return None
    p, tilde = expand(ws[0])
    name = os.path.basename(p)
    want = plugin.get(name) or RETIRED.get(name)
    if not want:
        return None
    std = tilde and ws[0].split("/", 1)[1] == f".claude/hooks/{name}"
    if not std and os.path.realpath(os.path.dirname(p)) != hooks_dir:
        return None
    ev, m = want
    if ev is not None and event != ev:
        return None
    if m and matcher not in (None, "", "*", m):
        return None
    return name

exists = os.path.lexists(path)
d = {}
if exists:
    try:
        with open(path) as f:
            d = json.load(f)
        if not isinstance(d, dict):
            raise ValueError("not a JSON object")
    except (OSError, ValueError) as e:
        print(f"hooks: {path} is not valid JSON ({e}); fix it by hand, then re-run")
        sys.exit(30)

src = ((d.get("extraKnownMarketplaces") or {}).get(MKT) or {}).get("source") or {}
where = src.get("path") if src.get("source") == "directory" else None
mkt_ok = bool(where) and os.path.realpath(where) == os.path.realpath(mkt_path)
enabled = (d.get("enabledPlugins") or {}).get(KEY) is True
hooks = d.get("hooks") if isinstance(d.get("hooks"), dict) else {}
entries = []  # (event, matcher, hook)
for ev, groups in hooks.items():
    for g in groups if isinstance(groups, list) else []:
        if isinstance(g, dict):
            entries += [(ev, g.get("matcher"), h) for h in (g.get("hooks") or []) if isinstance(h, dict)]
owned = [own(ev, m, h.get("command")) for ev, m, h in entries]
manual = sorted({n for n in owned if n in plugin})
retired = sorted({n for n in owned if n in RETIRED})

if mode == "check":
    out = []
    if not exists:
        out.append(f"hooks: no {path}, so no dot-claude hooks run in this config; run {fix}")
    elif not enabled:
        also = f"; it registers {', '.join(manual)} by hand" if manual else ""
        out.append(f"hooks: the dot-claude hooks plugin ({KEY}) is not enabled in {path}{also}; run {fix}")
    else:
        if not mkt_ok:
            out.append(f"hooks: {path} enables {KEY} but serves the {MKT} marketplace from "
                       f"{where or 'nowhere'}, not {mkt_path}; run {fix}")
        if manual:
            out.append(f"hooks: {path} registers {', '.join(manual)} by hand as well as through "
                       f"the plugin, so each runs twice; run {fix}")
    if retired:
        out.append(f"hooks: {path} registers the retired {', '.join(retired)}; run {fix} to remove it")
    # A registered script that is gone fails on every event it is registered for, and
    # `python3 gone.py` exits 2, which in PreToolUse blocks every tool call. Only paths that
    # resolve here are checked: ~, $HOME and absolute ones.
    gone = set()
    for _, _, h in entries:
        cmd = h.get("command")
        if not isinstance(cmd, str) or "CLAUDE_PLUGIN_ROOT" in cmd:
            continue
        for w in words(cmd) or []:
            p, tilde = expand(w)
            if (tilde or w.startswith("/")) and "/hooks/" in p and not os.path.exists(p):
                gone.add(w)
    out += [f"hooks: {path} registers {t}, which does not exist; remove that entry" for t in sorted(gone)]
    if out:
        print("\n".join(out))
    sys.exit(20 if out else 0)

plan = []
if not exists:
    plan.append(f"create {path}")
if not mkt_ok:
    plan.append(f"declare the {MKT} marketplace at {mkt_path} in {path}")
if not enabled:
    plan.append(f"enable {KEY} in {path}")
if manual:
    plan.append(f"remove the hand-written {', '.join(manual)} from {path}; the plugin registers them")
if retired:
    plan.append(f"remove the retired {', '.join(retired)} from {path}")
for p in plan:
    print(("" if mode == "apply" else "would ") + p)
if not plan:
    sys.exit(0)
if mode != "apply":
    sys.exit(10)

d.setdefault("extraKnownMarketplaces", {})[MKT] = {"source": {"source": "directory", "path": mkt_path}}
d.setdefault("enabledPlugins", {})[KEY] = True
if manual or retired:
    for ev in list(hooks):
        kept = []
        for g in hooks[ev] if isinstance(hooks[ev], list) else []:
            if isinstance(g, dict) and isinstance(g.get("hooks"), list):
                g["hooks"] = [h for h in g["hooks"]
                              if not (isinstance(h, dict) and own(ev, g.get("matcher"), h.get("command")))]
                if not g["hooks"]:
                    continue
            kept.append(g)
        if kept:
            hooks[ev] = kept
        else:
            del hooks[ev]
real = os.path.realpath(path)
tmp = real + ".install-tmp"
with open(tmp, "w") as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write("\n")
if exists:
    shutil.copymode(real, tmp)
    bak = f"{real}.{time.strftime('%Y%m%d-%H%M%S')}.bak"
    shutil.copy2(real, bak)
    print(f"backed up {real} to {bak}")
os.replace(tmp, real)
sys.exit(10)
PY

settings_seen=" "
do_settings() { # $1 = config dir
  local s key rc
  s="$1/settings.json"
  key="$(readlink -f "$s" 2>/dev/null || printf '%s' "$s")"
  case "$settings_seen" in *" $key "*) return 0 ;; esac
  settings_seen="$settings_seen$key "
  if ! command -v python3 >/dev/null 2>&1; then
    printf 'hooks: python3 is needed to read %s\n' "$s"; errors=$((errors + 1)); return 0
  fi
  python3 -c "$SETTINGS_PY" "$MODE" "$s" "$REPO" "$(tilde_home "$1")" "$(fix_for "$1")"; rc=$?
  case "$rc" in
    0) ;;
    10) changes=$((changes + 1)) ;;
    20) problems=$((problems + 1)) ;;
    *) errors=$((errors + 1)) ;;
  esac
  return 0
}

for d in "${DIRS[@]}"; do
  if [ "$MODE" = check ]; then
    [ "$(phys "$d")" = "$REPO" ] || check_links "$d"
    check_hostmd "$d"
  else
    [ "$(phys "$d")" = "$REPO" ] || link_dir "$d"
  fi
  do_settings "$d"
done

if [ "$MODE" = check ]; then
  [ "$problems" -eq 0 ] && [ "$errors" -eq 0 ] && exit 0
  exit 1
fi
if [ "$changes" -gt 0 ] && [ "$MODE" = dry ]; then
  printf '\n%d change(s) planned for %d config dir(s). Re-run with --apply to make them.\n' "$changes" "${#DIRS[@]}"
fi
[ "$errors" -eq 0 ]
