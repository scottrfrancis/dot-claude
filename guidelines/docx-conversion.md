# DOCX Conversion Guidelines

## Standard Tool

Use `python-docx` via a structured converter script, not pandoc or per-app hardcoded scripts.

**Job-search project**: `scripts/md-to-docx.py`

```bash
python3 scripts/md-to-docx.py <input.md> [output.docx]
```

Auto-detects resume vs cover letter format. Output defaults to same directory as input with `.docx` extension.

## Why Not Pandoc

- No control over margins, fonts, colors, or paragraph spacing
- Uses generic Word heading styles (Cambria, wide margins)
- Cannot parse inline bold within bullets or pipe-separated headers
- Produces unprofessional output requiring manual formatting

## Why Not Per-App Hardcoded Scripts

- 300+ lines of duplicated content per application
- Styles drift between copies (margins, fonts, subtitle format)
- Content embedded in code instead of read from markdown
- Unmaintainable — fix a bug in one, miss it in seven others

## Color Palette

| Element | Color | Hex |
|---|---|---|
| Section headers | Burnt orange | `#C45911` |
| Section border underline | Burnt orange | `#C45911` |
| Name, project titles, company names | Dark blue | `#1F3864` |
| Subtitle, contact line | Medium blue | `#2E5C8A` |
| Dates, meta text | Dark gray | `#444444` |
| Body text, bullets, narratives | Near-black | `#1A1A1A` |
| Hyperlinks | Blue, underlined | `#0563C1` |

## Typography

- **Font**: Calibri 10pt body, 11pt section headers, 10.5pt project titles, 20pt name
- **Margins**: 0.6" top/bottom, 0.7" left/right
- **Line spacing**: 13pt
- **Widow/orphan control**: Enabled globally
- **Keep-with-next**: On all section headers, project headers, experience headers

## Hyperlinks

Markdown links `[text](url)` are rendered as clickable DOCX hyperlinks with blue underline styling. Never strip links to plain text.

## Rules

- Never use bare `pandoc` for resume or cover letter DOCX conversion
- Never create a new per-app `convert_to_docx.py` — fix the generic script instead
- If the generic script doesn't handle a new markdown format, extend it rather than working around it
- Requires `python-docx` package (`pip install python-docx`)
