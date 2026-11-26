---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python

- Type hints on every function signature. Use `pathlib.Path` over `os.path`, f-strings for
  formatting, and dataclasses or Pydantic models for structured data.
- Catch specific exceptions, never a bare `except:`, and give domain errors their own classes.
  Return a value or raise; never return an error code.
- Imports in three groups (standard library, third party, local), absolute, with no wildcards.
- Tests use pytest, with fixtures for setup and `parametrize` for data-driven cases. Give a
  non-obvious assertion a message.
