# Design Deliverable Review

Review D2.x design documents for internal consistency, terminology alignment, traceability coverage, and compliance. This is a document-layer review (complementing `arch-review` which reviews code architecture).

## Phase 1: Load All Design Artifacts

Read these document groups in order (skip any that don't exist):

1. **Design deliverables**: `docs/deliverables/D2*`
2. **Discovery deliverables**: `docs/deliverables/D1*` (for cross-reference validation)
3. **Architecture decisions**: `docs/decisions/ADR-*.md` or `docs/adr/ADR-*.md`
4. **Requirements spec**: `docs/design/SRS.md`, `docs/deliverables/D1.7*`
5. **PRD**: `docs/design/PRD.md`
6. **UX design index**: `docs/design/ux-design/README.md`
7. **Feature files**: `docs/requirements/*.feature` (headers and tags only — don't read every scenario)
8. **Glossary**: `docs/GLOSSARY.md`

Report what was found before proceeding.

## Phase 2: Terminology Consistency

Build a term inventory from all D2.x documents. Flag:

- **Same concept, different names**: e.g., "event" in D2.1 vs "cluster" in D2.3 for the same thing
- **Ambiguous terms**: Used with different meanings in different documents
- **Terms not in glossary**: Domain terms appearing in D2.x docs but missing from GLOSSARY.md
- **Terminology drift from D1.x**: Terms that changed meaning between discovery and design without explanation

For each finding, cite the specific documents and sections where the inconsistency appears.

## Phase 3: Cross-Document Reference Integrity

For every cross-reference between documents (e.g., "see D2.1 Section 5", "[D2.6](../D2.6...)"):

- Verify the target document exists
- Verify the referenced section or anchor exists
- Flag broken or ambiguous references

Also check:
- ADR references in D2.x docs → do the ADR files exist and are they Accepted?
- Requirement references (FR-###) in D2.x docs → do they exist in D1.7/SRS?
- Feature file references → do they exist in `docs/requirements/`?

## Phase 4: UX-to-Requirement Traceability

If UX design artifacts exist:
- Check that each UX screen/page maps to at least one requirement (FR-###)
- Check that each requirement referenced by UX screens exists in the SRS
- Identify screens that are purely navigational (section titles, covers) — these are valid without FR mapping
- Flag any functional screens without requirement mapping

## Phase 5: Deliverable Completeness

For each D2.x document, check:
- Does it have a clear purpose statement?
- Does it reference the relevant ADRs?
- Does it align with the architecture described in D2.1 (the target architecture)?
- Are there TODO/TBD/placeholder markers still present?
- Is the document internally consistent (no contradictions between sections)?

## Phase 6: Compliance Checklists

Run these checklists against the D2.x deliverables:

### Architecture Alignment
- [ ] All D2.x docs reference the same technology stack as D2.1
- [ ] Component names are consistent across D2.1, D2.6 (API specs), D2.8 (operations)
- [ ] Data models in D2.2 match the schemas referenced in D2.6
- [ ] Test strategy in D2.7 covers all requirements in D1.7

### Standard Compliance (if applicable)
- [ ] Security requirements addressed (authentication, authorization, data protection)
- [ ] Performance requirements specified (latency SLOs, throughput targets)
- [ ] Observability requirements specified (logging, monitoring, alerting)
- [ ] Error handling and resilience patterns documented

## Phase 7: Produce Report

Save to `docs/design-review-YYYY-MM-DD.md`:

```markdown
# Design Review — [Date]

## Executive Summary
[2-3 sentences: overall assessment, critical findings count, recommendation]

## Documents Reviewed
| Document | Sections | Size | Last Modified |
|----------|----------|------|---------------|

## Terminology Consistency
| Finding | Severity | Document A | Document B | Recommendation |
|---------|----------|------------|------------|----------------|

## Cross-Reference Integrity
| Source | Target | Status | Issue |
|--------|--------|--------|-------|

## UX-to-Requirement Coverage
| UX Screen | FR Mapping | Feature File | Status |
|-----------|------------|-------------|--------|

## Deliverable Completeness
| Document | Purpose | ADR Refs | TODOs Remaining | Status |
|----------|---------|----------|-----------------|--------|

## Compliance Assessment
| Checklist Item | Status | Evidence | Gap |
|----------------|--------|----------|-----|

## Findings by Severity
### Critical (block phase gate)
### Major (address before construction)
### Minor (address during construction)

## Recommended Actions
| Priority | Action | Owner | Deadline |
|----------|--------|-------|----------|
```

## Rules

- Strictly read-only — never modify design documents
- Severity ratings: Critical = blocks phase gate, Major = should fix before construction, Minor = fix during construction
- Focus on consistency and completeness, not style or formatting (that's doc-review's job)
- If a deliverable doesn't exist yet, note it as "Not yet created" rather than failing
- Compare against the project's own standards (constitution, glossary) not external assumptions
