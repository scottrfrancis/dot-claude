---
paths:
  - "**/*.{md,mdx,markdown}"
---

# Markdown

A person will read this file, so the `prose-style` skill applies; load it for a long document
or an audit. Before saving, check the draft against the rules that cost most to fix later:

- Em-dashes: at most `max(2, lines/40)`. If a dash can be a period, colon or comma, make it
  one. `**Term** — definition` becomes `**Term.** Definition`.
- Contrasts that set up a claim only to deny it: delete the denied half. That includes a denial
  split across two sentences, and one that trails the sentence after a comma.
- State what is. Words such as "previously", "now", "no longer" and "updated" usually mean the
  page is narrating its own edits, which belong in a changelog or a commit.
- Bold is for the one phrase a reader must not miss, at most `max(3, lines/10)` spans, and not
  every list lead-in.
- Plain register: no closing epigram that restates the paragraph, no staged reveal, no run of
  sentence fragments.
- Name the concrete thing ("the retry loop") in place of an abstraction ("the edge").
- Vary sentence openings and length, and cut any sentence kept because it sounds professional.

Formatting: a blank line before and after each list, heading and code fence, and between
paragraphs. Use one bullet marker per list.
