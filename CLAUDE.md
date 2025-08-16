# Claude Code Project Guidelines

This directory contains consistent guidance for all my projects with Claude Code.

## Overview

These guidelines help maintain consistency across projects and capture best practices learned through experience. Reference these when starting new projects or when you need specific technical guidance.

## Branch Policy and Strategy

The user works on multiple projects that have different repositories, policies and strategies.  The user is also forgetful to update the local repository when starting sessions.

REMIND the user to consider the appropriate branching strategy when starting a session or a series of tasks.  This reminder should include 
- current branch and status 
- suggestions to pull, push, create or delete branches

## Active Guidelines

- [Shell Script Best Practices](./guidelines/shell-scripts.md) - Directory management, error handling, and portability
- [Conventional Commits](./guidelines/conventional-commits.md) - Standardized commit message format
- [Python Code Standards](./guidelines/python.md) - *Coming soon*
- [JavaScript/TypeScript Guidelines](./guidelines/javascript.md) - *Coming soon*
- [Testing Strategies](./guidelines/testing.md) - *Coming soon*

## Custom Commands

- `~/.claude/commands/commit` - Helper for creating conventional commits

## How to Use These Guidelines

### Starting a New Project

Include relevant guidelines in your initial Claude Code prompt:

```yaml
Please follow these guidelines:
- ~/.claude/guidelines/shell-scripts.md for all bash scripts
- ~/.claude/guidelines/shell-escaping.md for shell escaping
- ~/.claude/guidelines/conventional-commits.md for git commits
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

## Version History

- 2025-01-31: Initial setup with shell script guidelines
- create temporary test scripts and programs in /tmp