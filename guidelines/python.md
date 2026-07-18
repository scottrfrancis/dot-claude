# Python Standards

## Style
- Type hints on all function signatures (parameters and return types)
- Use `pathlib.Path` over `os.path`
- f-strings for formatting, not `.format()` or `%`
- Dataclasses or Pydantic models for structured data, not raw dicts

## Error Handling
- Specific exception types, never bare `except:`
- Use custom exception classes for domain errors
- Return `None` or raise — don't return error codes

## Imports
- Standard library, blank line, third-party, blank line, local
- Absolute imports preferred over relative
- No wildcard imports (`from module import *`)

## Testing
- **Red-Green-Refactor TDD is REQUIRED** — failing test first, minimum code to pass, refactor.
- pytest, not unittest
- Fixtures for setup/teardown
- Parametrize for data-driven tests
- Assert messages on non-obvious assertions
