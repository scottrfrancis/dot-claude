---
description: set initial context for a working session
argument-hint: [role with task]
allowed-tools: Write, Bash, Read, LS, Grep, Glob, TodoWrite, Git, Gh
---

as $ARGUMENTS
I'll review the project documentation including
- README
- ARCHITECTURE.md (if present)
- CONTRIBUTING.md (if present)
- .claude/session-logs (check most recent for context continuity)
- docs/
- plans/
- TODO
- recent commits

Arguments provided: $ARGUMENTS

I will check the current git status including upstream for any changes by first fetching. Handle uncommitted changes with stash if needed. If a pull can be done cleanly with the current branch policy, I will do that. Otherwise, I will alert the user to the pending changes. Suggest new branch if appropriate.

I will confirm when I am ready with a simple "i am ready to claude" and a very short, high-level plan.

output-style: brief, bulleted points
Structure the "ready" response with clear sections:                             
- Current Status (git, branch, changes)                                          
- Session Context (role, recent work)                                            
- Suggested Next Steps (based on TODOs, issues)
