---
paths:
  - "**/tests/**"
  - "**/__tests__/**"
  - "**/test_*.py"
  - "**/*_test.{py,go}"
  - "**/*.{test,spec}.{js,jsx,ts,tsx}"
---

# Tests

Load the `testing` skill before writing or changing a test. The parts that are easiest to miss:

- Run the new test and see it fail for the right reason before writing the code it covers.
- A test written after its code has never been seen to fail. Break the code, watch the test go
  red, restore it, and say in review that the test came second.
- Spikes, pure configuration, generated code and one-off scripts are exempt. Name the exemption
  where you take it.
