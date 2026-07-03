---
name: explain-diff-md
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Produces a self-contained Markdown document (fits the wiki/OKF knowledge base).
---

# Explain Diff (Markdown)

Please make me a rich explanation of the specified code change as a **single Markdown file**.

It should have these sections:

- Background: Explain the existing system relevant to this change. (Broadly explore the surrounding code.) We don't know how much the reader already knows, so include a deep background for beginners (note it can be skipped if already familiar), then a narrower background directly relevant to the change.
- Intuition: Explain the core intuition. Focus on the essence, not full details. Use concrete examples with toy data. Use diagrams liberally.
- Code: A high-level walkthrough of the changes, grouped/ordered in an understandable way.
- Quiz: Five medium-difficulty questions that test real understanding of the change (not gotchas). Each is multiple-choice with an explanation per option, using collapsible toggles so answers stay hidden until clicked.

Format:

- Output a single self-contained **`.md`** file. Start it with an H1 title and a Markdown table-of-contents linking the section headers. Put the file in a global place outside the code repo, and start the filename with today's date in `YYYY-MM-DD-` format so files stay time-sorted and out of version control — e.g. `/tmp/2026-01-12-explanation-<slug>.md`. If the change belongs to a project with a `wiki/` or an OKF bundle, offer to also drop a copy in `wiki/` (as a `topic`/`decision`) or the bundle — but ask before writing into a knowledge base.
- Write with the clarity and flow of Martin Kleppmann — engaging, classic style, smooth transitions between sections.
- Diagrams: pick a small number of reusable diagram families. Use **Mermaid** fenced blocks (```mermaid) for system/data-flow diagrams and Markdown tables for structured comparisons. Always include example data. Do not use ASCII-art diagrams.
- Quiz toggles use Markdown `<details>`:
  ```markdown
  **1. Question text?**
  <details><summary>A) Option one</summary>❌ Why it's wrong.</details>
  <details><summary>B) Option two</summary>✅ Why it's right.</details>
  ```
- Use blockquote callouts (`> **Note:** …`) for key concepts, definitions, and important edge cases.
