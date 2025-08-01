# Conventional Commits Guidelines

All projects must use [Conventional Commits](https://www.conventionalcommits.org/) format for git commit messages.

## Quick Reference

Two commands are available:

### Manual commit (when you know what you want)
```bash
~/.claude/commands/commit feat auth "add login endpoint"
~/.claude/commands/commit fix "resolve null pointer exception"
```

### Auto-commit (let Claude analyze and suggest)
```bash
~/.claude/commands/autocommit        # Interactive
~/.claude/commands/autocommit -y     # Skip confirmation
~/.claude/commands/autocommit -t fix # Suggest type to Claude
```

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

## Examples

### Simple commits
```
feat: add user authentication
fix: prevent race condition in data processing
docs: update API documentation
```

### With scope
```
feat(auth): add OAuth2 support
fix(parser): handle empty input gracefully
style(dashboard): update button colors
```

### With breaking change
```
feat(api): change authentication method

BREAKING CHANGE: API now uses JWT tokens instead of API keys
```

### Multi-line with body
```
fix(server): prevent memory leak in connection pool

The connection pool was not properly releasing connections
after timeout, causing memory to gradually increase over time.

This fix ensures all connections are properly closed and
removed from the pool after the timeout period.

Fixes #123
```

## Best Practices

1. **Use present tense**: "add feature" not "added feature"
2. **Use imperative mood**: "move cursor to..." not "moves cursor to..."
3. **Don't capitalize first letter** after the colon
4. **No period at the end** of the subject line
5. **Keep subject line under 72 characters**
6. **Reference issues** when applicable (e.g., "Fixes #123")
7. **Use scope** to indicate which part of the codebase changed

## Enforcement

For projects requiring strict adherence, consider:

1. Git hooks (commitlint)
2. CI/CD validation
3. PR checks

## Claude Code Integration

When asking Claude Code to make commits, reference this guideline:

```
Please follow ~/.claude/guidelines/conventional-commits.md for all git commits.
```

### Available Commands

You can use these commands to help create properly formatted commits:

```bash
# Manual commit (when you know what you want)
~/.claude/commands/commit feat "add new feature"

# Auto-commit (let Claude analyze and suggest)
~/.claude/commands/autocommit
```

### Example Project Instruction

When starting a new project, include this in your initial prompt:

```
For all git commits in this project:
1. Follow ~/.claude/guidelines/conventional-commits.md
2. You may use ~/.claude/commands/autocommit to generate commit messages
3. Always ensure commits follow the conventional format
```