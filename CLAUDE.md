# Claude Code Project Guidelines

This directory contains consistent guidance for all my projects with Claude Code.

## Overview

These guidelines help maintain consistency across projects and capture best practices learned through experience. Reference these when starting new projects or when you need specific technical guidance.

## Branch Policy and Strategy

The user works on multiple projects that have different repositories, policies and strategies.  The user is also forgetful to update the local repository when starting sessions.

REMIND the user to consider the appropriate branching strategy when starting a session or a series of tasks.  This reminder should include
- current branch and status
- suggestions to pull, push, create or delete branches

## Session Safety (CRITICAL)

**ALWAYS follow ~/.claude/guidelines/session-safety.md** when working on hardware development systems. Multiple Claude sessions accessing NPU/GPU devices simultaneously causes device contention, resource leakage, and complete context loss requiring system restart.

**Before every session**: Run session cleanup, verify device availability, and ensure exclusive hardware access.

## Active Guidelines

- [Shell Script Best Practices](./guidelines/shell-scripts.md) - Directory management, error handling, and portability
- [Conventional Commits](./guidelines/conventional-commits.md) - Standardized commit message format
- [README Documentation](./guidelines/readme-documentation.md) - Organizing project documentation with README as central hub
- [Session Safety](./guidelines/session-safety.md) - **CRITICAL** - Prevent session hangs and context loss on hardware systems
- [AI Systems Engineering Patterns](./guidelines/ai-patterns.md) - LLM integration patterns: caching, routing, guardrails, RAG
- [Project Setup](./guidelines/project-setup.md) - Tiered checklist for bootstrapping new projects with hooks, memory, and session tooling
- [Python Code Standards](./guidelines/python.md) - *Coming soon*
- [JavaScript/TypeScript Guidelines](./guidelines/javascript.md) - *Coming soon*
- [Testing Strategies](./guidelines/testing.md) - *Coming soon*

## Custom Commands

- `~/.claude/commands/commit` - Helper for creating conventional commits
- `~/.claude/commands/lets-go.md` - Session initialization with git sync protocol
- `~/.claude/commands/session-logger.md` - Session summary with cross-linking and effectiveness assessment
- `~/.claude/commands/handoff.md` - Generate continuation prompt for seamless session handoff
- `~/.claude/commands/mine-sessions.md` - Analyze session logs for patterns, metrics, and process improvements

## Global Hooks

Registered in `~/.claude/settings.json`, these fire for every project automatically:

- **SessionStart** → `~/.claude/hooks/load-handoff-context.sh` — Auto-injects the most recent `handoff-*.md` as context on new session startup (skips files >7 days old)
- **Stop** → `~/.claude/hooks/session-end-reminder.sh` — Reminds about `/session-logger` (3+ files changed) and `/handoff` (5+ files changed) if not already run

Project-local hooks in `.claude/settings.local.json` layer on top of these.

## How to Use These Guidelines

### Starting a New Project

Include relevant guidelines in your initial Claude Code prompt:

```yaml
Please follow these guidelines:
- ~/.claude/guidelines/shell-scripts.md for all bash scripts
- ~/.claude/guidelines/shell-escaping.md for shell escaping
- ~/.claude/guidelines/conventional-commits.md for git commits
- ~/.claude/guidelines/readme-documentation.md for documentation organization
```

### Multiple Guidelines

For projects using multiple technologies:

```yaml
Please follow these guidelines:
- ~/.claude/guidelines/shell-scripts.md for bash scripts
- ~/.claude/guidelines/python.md for Python code
```

### Project-Specific Overrides

If a project needs exceptions to these guidelines, create a local override file:

```sh
project/.claude/overrides.md
```

## Contributing to Guidelines

1. Update guidelines when you discover new patterns or best practices
2. Include both positive examples (do this) and negative examples (avoid this)
3. Explain the reasoning behind each guideline
4. Keep guidelines concise but comprehensive

## Quick Reference

List all available guidelines:

```bash
find ~/.claude/guidelines -name "*.md" -type f | sort
```

## Global Behavioral Rules

- Create temporary test scripts and programs in `/tmp`, not in the project directory
- When the user reports a PR has been merged, prompt them to update the local repository (pull, delete merged branch)
- When asked to push to a repo, suggest a new branch if the current branch is the default (main/master)

## Version History

- 2025-01-31: Initial setup with shell script guidelines
- 2026-02-17: Establish as pure base class — remove project-specific content, document extension pattern
