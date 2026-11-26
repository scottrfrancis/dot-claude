#!/usr/bin/env bash
# PreToolUse hook: Warn before destructive operations.
# Blocks with exit code 2 (causes Claude to show the message and ask user to confirm).
# Advisory only for non-destructive tools.

set -euo pipefail

HOOK_INPUT=$(cat)

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
TOOL_INPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_input // empty' 2>/dev/null)

# Only inspect Bash tool calls
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Examine only the first line: heredoc bodies and multi-line messages start on line 2.
# Parameter expansion, because piping a long command into `head -1` kills the writer with
# SIGPIPE, and under pipefail the hook would exit 141 and check nothing.
FIRST_LINE="${COMMAND%%$'\n'*}"
# Drop -m/--message arguments, so a message that mentions `push --force` trips nothing. Only
# the message goes: `python3 -m pytest && git push --force` keeps the push. A quote left open
# on line 1 runs to the end of the line.
if command -v perl >/dev/null 2>&1; then
  CMD_HEAD=$(printf '%s\n' "$FIRST_LINE" | perl -pe 's/\s(?:-m|--message)(?:=|\s+)(?:"(?:[^"\\]|\\.)*"|'"'"'[^'"'"']*'"'"'|"[^"]*$|'"'"'[^'"'"']*$|\S+)//g')
else
  CMD_HEAD=$(printf '%s\n' "$FIRST_LINE" | sed 's/ -m .*//; s/ --message .*//')
fi
CMD_HEAD="${CMD_HEAD:0:200}"

# git's global options come before the subcommand, and every rule below looks for
# `git <subcommand>`, so `git -C repo push --force` used to pass unchecked. Collapse
# -C/-c <value> (quoted or not), --git-dir/--work-tree/--namespace <value> and the
# value-less globals to plain `git`. perl, because BSD and GNU sed disagree on loops.
if command -v perl >/dev/null 2>&1; then
  GIT_CMD_HEAD=$(printf '%s\n' "$CMD_HEAD" | perl -pe '1 while s/\bgit\s+(?:-[Cc]\s+(?:"[^"]*"|'"'"'[^'"'"']*'"'"'|\S+)|--(?:git-dir|work-tree|namespace)(?:=|\s+)\S+|--(?:no-pager|bare|no-replace-objects|literal-pathspecs))\s*/git /')
else
  GIT_CMD_HEAD="$CMD_HEAD"
fi

# A push that overwrites the remote without a real guard: a bare --force, -f alone or
# inside combined short flags (-uf), a +refspec, or a lease that guards nothing.
# A lease is safe when it names the expected commit (--force-with-lease=<ref>:<sha>)
# or is paired with --force-if-includes. A bare lease, or one naming only the ref,
# compares against the remote-tracking ref, which a background fetch may have moved.
force_push() {
  local re='(^|[^[:alnum:]_.-])git[[:space:]]+push([[:space:]].*)?$'
  [[ $1 =~ $re ]] || return 1
  local args=" ${BASH_REMATCH[2]} "
  [[ $args =~ [[:space:]]--force[[:space:]] ]] && return 0
  [[ $args =~ [[:space:]]-[[:alpha:]]*f[[:alpha:]]*[[:space:]] ]] && return 0
  [[ $args =~ [[:space:]]\+[^[:space:]] ]] && return 0
  if [[ $args =~ [[:space:]]--force-with-lease[=[:space:]] ]]; then
    [[ $args =~ [[:space:]]--force-if-includes[[:space:]] ]] && return 1
    [[ $args =~ [[:space:]]--force-with-lease=[^[:space:]:]+:[^[:space:]]+[[:space:]] ]] && return 1
    return 0
  fi
  return 1
}

# --- Destructive git operations ---
if force_push "$GIT_CMD_HEAD"; then
  echo "Safety check: force push without a guarded lease — '$(echo "$CMD_HEAD" | head -c 120)'. Use --force-with-lease=<branch>:<expected sha> (or add --force-if-includes), or confirm this is intentional." >&2
  exit 2
fi
if echo "$GIT_CMD_HEAD" | grep -qE 'git\s+(reset\s+--hard|clean\s+-f|checkout\s+--\s|\brebase\s+.*--abort)'; then
  echo "Safety check: destructive git operation detected — '$(echo "$CMD_HEAD" | head -c 120)'. Confirm this is intentional." >&2
  exit 2
fi

# --- Force-remove worktrees ---
if echo "$GIT_CMD_HEAD" | grep -qE 'git\s+worktree\s+remove\s+--force'; then
  echo "Safety check: 'git worktree remove --force' will delete uncommitted work in the worktree. Confirm." >&2
  exit 2
fi

# --- Recursive delete ---
if echo "$CMD_HEAD" | grep -qE '\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\b|\brm\s+-rf\b|\brm\s+-fr\b'; then
  echo "Safety check: recursive delete detected — '$(echo "$CMD_HEAD" | head -c 120)'. Confirm this is intentional." >&2
  exit 2
fi

# --- Writes to sensitive global config files ---
if echo "$CMD_HEAD" | grep -qE '(>|>>)\s*(~\/\.claude\/settings\.json|~\/\.ssh\/|~\/\.aws\/credentials)'; then
  echo "Safety check: redirect to sensitive config file detected. Confirm this is intentional." >&2
  exit 2
fi

# --- Commands, segment by segment ---
# A perl lexer reads the whole first line with quotes resolved, splits it on ; & && | || ( ),
# and walks the segments, following cd so each git command is judged in the directory it
# runs in. It prints one line per finding:
#   kill                  pkill/killall, or pgrep feeding kill, with a pattern for Claude
#   cleanup <0|1>         session-cleanup run as a command; 1 when --kill-all-claude is given
#   newbranch <dir>       git checkout -b / switch -c
#   commit <dir>          git commit
#   push <dir> <args...>  git push and its arguments, tab-separated
# A pattern is for Claude when "claude" stands alone in it, as a word or a path's last part
# (claude, Claude, "claude --resume", node.*claude, /usr/local/bin/claude): every session
# matches it. A name that only contains it, such as /tmp/claude-502/x/server.py or
# claude-mem-worker, is a targeted kill and passes.
ANALYZE=$(cat <<'PERL'
use strict; use warnings; use File::Spec;
local $/; my $line = <STDIN> // ''; $line =~ s/\n.*//s;
my $home = $ENV{HOME} // ''; my $dir = $ENV{SAFETY_CWD} || '.';
my (@segs, @cur); my ($w, $inw, $q) = ('', 0, '');
my @c = split //, $line;
for (my $i = 0; $i < @c; $i++) {
  my $ch = $c[$i];
  if ($q) {
    if ($ch eq $q) { $q = '' } elsif ($ch eq '\\' && $q eq '"' && $i + 1 < @c) { $w .= $c[++$i] } else { $w .= $ch }
    next;
  }
  if ($ch eq '"' || $ch eq "'") { $q = $ch; $inw = 1; next }
  if ($ch eq '\\' && $i + 1 < @c) { $w .= $c[++$i]; $inw = 1; next }
  if ($ch =~ /\s/) { if ($inw) { push @cur, $w; $w = ''; $inw = 0 } next }
  my $redir = $ch eq '&' && (($i > 0 && $c[$i - 1] =~ /[<>]/) || ($i + 1 < @c && $c[$i + 1] eq '>'));
  if ($ch =~ /[;&|()]/ && !$redir) {
    if ($inw) { push @cur, $w; $w = ''; $inw = 0 }
    push @segs, [@cur]; @cur = ();
    $i++ if $ch =~ /[&|]/ && $i + 1 < @c && $c[$i + 1] eq $ch;
    next;
  }
  $w .= $ch; $inw = 1;
}
push @cur, $w if $inw; push @segs, [@cur];
sub resolve { my ($p, $base) = @_; $p = $home if $p eq '~'; $p =~ s{^~/}{$home/}; File::Spec->rel2abs($p, $base) }
my $CL = qr{(?:^|[/ .*])[Cc]laude(?:$|[ .*\$])};
my ($pgrep, $killer) = (0, 0); my @out;
for my $seg (@segs) {
  my @w = grep { !/[<>]/ } @$seg;
  while (@w) {
    if ($w[0] =~ /^(?:sudo|nohup|command|exec|time|builtin)$/ || $w[0] =~ /^[A-Za-z_]\w*=/) { shift @w; next }
    if ($w[0] eq 'env') { shift @w; shift @w while @w && ($w[0] =~ /^-/ || $w[0] =~ /=/); next }
    last;
  }
  next unless @w;
  (my $cmd = $w[0]) =~ s{.*/}{};
  if ($cmd eq 'cd' || $cmd eq 'pushd') { $dir = resolve(@w > 1 ? $w[1] : '~', $dir) unless @w > 1 && $w[1] eq '-'; next }
  if ($cmd =~ /^(?:pkill|killall|pgrep)$/) {
    my @pats = grep { !/^-/ } @w[1 .. $#w];
    @pats = ($pats[-1]) if $cmd ne 'killall' && @pats;
    if (grep { $_ =~ $CL } @pats) { if ($cmd eq 'pgrep') { $pgrep = 1 } else { push @out, 'kill' } }
    next;
  }
  if ($cmd eq 'kill' || ($cmd eq 'xargs' && grep { m{(?:^|/)kill$} } @w)) { $killer = 1; next }
  my @cw = ($cmd =~ /^(?:bash|sh|zsh)$/ && @w > 1) ? @w[1 .. $#w] : @w;
  if ($cw[0] =~ m{(?:^|/)session-cleanup$}) { push @out, "cleanup\t" . ((grep { $_ eq '--kill-all-claude' } @cw) ? 1 : 0); next }
  next unless $cmd eq 'git';
  my ($g, $i) = ($dir, 1);
  while ($i < @w) {
    my $a = $w[$i];
    if ($a eq '-C') { $g = resolve($w[$i + 1] // '.', $g); $i += 2; next }
    if ($a =~ /^(?:-c|--git-dir|--work-tree|--namespace)$/) { $i += 2; next }
    if ($a =~ /^-/) { $i++; next }
    last;
  }
  my $sub = $w[$i] // ''; my @args = @w[$i + 1 .. $#w];
  if ($sub eq 'commit') { push @out, "commit\t$g" }
  elsif ($sub eq 'push') { push @out, join("\t", 'push', $g, @args) }
  elsif ($sub =~ /^(?:checkout|switch)$/ && grep { /^-[bBcC]$/ } @args) { push @out, "newbranch\t$g" }
}
push @out, 'kill' if $pgrep && $killer;
print "$_\n" for @out;
PERL
)

# The user is asked; the reason is shown in the permission prompt.
ask() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
  exit 0
}

ACTIONS=""
if command -v perl >/dev/null 2>&1; then
  CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
  ACTIONS=$(printf '%s' "$FIRST_LINE" | SAFETY_CWD="${CWD:-$PWD}" perl -e "$ANALYZE" 2>/dev/null || true)
fi

# Blocks first, so an ask for one segment never waves through a kill in another.
if printf '%s\n' "$ACTIONS" | grep -qx 'kill'; then
  echo "Safety check: this kills every process matching 'claude', which ends every Claude Code session on the host, this one included. Kill a specific PID instead." >&2
  exit 2
fi
if printf '%s\n' "$ACTIONS" | grep -qx $'cleanup\t0'; then
  echo "Safety check: session-cleanup kills every Claude process on the machine and runs only with --kill-all-claude, on a dedicated NPU/GPU box. Ask Scott before running it." >&2
  exit 2
fi
if printf '%s\n' "$ACTIONS" | grep -qx $'cleanup\t1'; then
  ask "session-cleanup --kill-all-claude kills every Claude process on this machine, this session included. Run it only on a dedicated NPU/GPU box."
fi

# --- Commits and pushes on a default branch ---
# Never commit or push a default branch. This asks rather than blocks, so a repo that
# commits to its default branch by design (an engagement umbrella) is one approval away.
# The default branch is origin/HEAD, else main or master.
branch_of() { git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null || true; }
default_of() { local d; d=$(git -C "$1" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true); printf '%s' "${d#origin/}"; }
is_default() { # $1 branch, $2 the repo's default ('' when there is no origin/HEAD)
  [ -n "$1" ] || return 1
  if [ -n "$2" ]; then [ "$1" = "$2" ]; else [ "$1" = main ] || [ "$1" = master ]; fi
}

if [ -n "$ACTIONS" ] && command -v git >/dev/null 2>&1; then
  new_dirs=" "
  while IFS=$'\t' read -r kind dir rest; do
    case "$kind" in commit|push|newbranch) ;; *) continue ;; esac
    git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || continue
    if [ "$kind" = newbranch ]; then new_dirs="$new_dirs$dir "; continue; fi
    branch=$(branch_of "$dir"); default=$(default_of "$dir")
    if [ "$kind" = commit ]; then
      case "$new_dirs" in *" $dir "*) continue ;; esac   # a branch made earlier in this command
      is_default "$branch" "$default" && \
        ask "This commits on $branch, the default branch of $dir. Branch first, unless this repo commits to $branch by design."
      continue
    fi
    toks=(); IFS=$'\t' read -r -a toks <<< "$rest"
    pos=(); skip=0; all=0; tags=0
    for t in ${toks[@]+"${toks[@]}"}; do
      if [ "$skip" -eq 1 ]; then skip=0; continue; fi
      case "$t" in
        --all|--mirror) all=1 ;;
        --tags) tags=1 ;;
        -o|--push-option|--repo|--receive-pack|--exec) skip=1 ;;
        -*) ;;
        *) pos+=("$t") ;;
      esac
    done
    dsts=()
    if [ "$all" -eq 1 ]; then dsts+=("${default:-main}")
    elif [ "${#pos[@]}" -le 1 ]; then [ "$tags" -eq 1 ] || dsts+=("$branch")   # --tags alone pushes only tags
    else
      for r in "${pos[@]:1}"; do
        r="${r#+}"
        case "$r" in *:*) d="${r#*:}" ;; *) d="$r" ;; esac
        [ "$d" = HEAD ] && d="$branch"
        dsts+=("${d#refs/heads/}")
      done
    fi
    for d in ${dsts[@]+"${dsts[@]}"}; do
      is_default "$d" "$default" && \
        ask "This pushes to $d, the default branch of $dir. Push a branch and open a PR, unless this repo pushes to $d by design."
    done
  done <<< "$ACTIONS"
fi

exit 0
