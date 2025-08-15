---
description: Generate and organize session summaries with optional topic tagging
argument-hint: [topic]
allowed-tools: Write, Bash, Read, LS
---

I'll create a comprehensive session summary and save it to `.claude/session-logs/` with proper organization.

First, let me create the session logs directory:

!mkdir -p .claude/session-logs

Now I'll generate a detailed session summary covering:
- Key decisions and outcomes
- Technical patterns discovered
- Action items and follow-ups
- Reusable insights

The summary will be saved with a timestamp and optional topic tag: `.claude/session-logs/YYYY-MM-DD-HHMM${topic:+-$topic}.md`

Arguments provided: $ARGUMENTS

Let me analyze our conversation and create a structured summary...