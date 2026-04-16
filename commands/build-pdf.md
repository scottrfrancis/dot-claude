---
description: Build a PDF from markdown sections using md2pdf and report.yaml
argument-hint: [path/to/report.yaml]
allowed-tools: Bash, Read, Glob
---

Build a PDF from ordered markdown sections using the `md2pdf` CLI tool.

Arguments: $ARGUMENTS

## Prerequisites

- `md2pdf` must be on PATH (`~/.local/bin/md2pdf`)
- `weasyprint` must be installed (`brew install weasyprint`)
- `python-markdown` must be installed (`pip3 install markdown`)

## Step 1 — Find the config

If an argument was provided, use it as the config path. Otherwise look for
`report.yaml` in the project root.

If no config exists, ask whether to scaffold one:

```bash
md2pdf --init
```

Then help the user populate the `sections` list by scanning for markdown files.

## Step 2 — Build the PDF

```bash
md2pdf
```

Or with an explicit path:

```bash
md2pdf path/to/report.yaml
```

## Step 3 — Report results

Show the output path and file size. If WeasyPrint reports errors, diagnose them.

## Config format (report.yaml)

```yaml
title: My Report
footer: "Footer text for each page"
output: report/output.pdf
sections:
  - report/01-intro.md
  - report/02-body.md
css: optional/override.css      # optional
combined: report/_combined.md   # optional
```

- **title**: Document title (used in default footer if footer not set)
- **footer**: Text in bottom-left of every page
- **output**: PDF output path relative to project root
- **sections**: Ordered list of markdown files to combine
- **css**: Optional CSS override (replaces default styles entirely)
- **combined**: Optional path to write merged markdown
