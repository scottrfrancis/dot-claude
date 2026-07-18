# Interview-to-Spec Pipeline

Transform raw interview notes into structured discovery artifacts: readout document, pain points, assumptions, requirements (FR-###), Gherkin scenarios, and glossary updates.

## Inputs

Provide in your message either:
- Raw interview notes (pasted text), OR
- A file path to raw interview notes

Plus optionally:
- Interviewee name and role
- Interview date
- Interview topic/focus area

## Phase 1: Load Project Context

Before processing, read these files to understand existing state (skip any that don't exist):

1. `docs/GLOSSARY.md` — existing terms (don't duplicate)
2. `docs/discovery/ASSUMPTIONS-TRACKER.md` — existing assumptions (don't duplicate, get next A## number)
3. `docs/discovery/SYSTEM-INVENTORY.md` — existing systems (don't duplicate)
4. `docs/requirements/*.feature` — existing Gherkin files (get tag patterns, persona names, domain vocabulary, highest FR-### number)
5. `docs/deliverables/D1.7*` or `docs/design/SRS.md` — existing requirements

## Phase 2: Produce Structured Readout

Create `docs/discovery/interviews/[name]-readout.md` with:

```markdown
# Interview Readout: [Name], [Role]

**Date**: [Date]
**Interviewer(s)**: [Names]
**Duration**: [Estimated]
**Topic**: [Focus area]

---

## Key Findings

1. [Finding with specific detail, not generic summary]
2. ...

## Systems Mentioned

| System | Role in Workflow | Integration Type | Notes |
|--------|-----------------|------------------|-------|
| [name] | [what it does]  | [API/DB/manual]  | [detail] |

## Pain Points Identified

| # | Pain Point | Impact | Frequency | Current Workaround |
|---|-----------|--------|-----------|-------------------|
| 1 | [specific problem] | [HIGH/MED/LOW] | [daily/weekly/etc] | [what they do now] |

## Assumptions Surfaced

| ID | Assumption | Validation Method | Impact if Wrong |
|----|-----------|-------------------|-----------------|
| A## | [hypothesis] | [how to test] | [consequence] |

## Candidate Requirements

| ID | Requirement | Source Quote | Priority |
|----|------------|-------------|----------|
| FR-X.X | [functional requirement] | "[exact words]" | [P0/P1/P2] |

## Action Items

- [ ] [Specific action with suggested owner]
- [ ] [Follow-up meeting or data request]

## Follow-Up Needed

- [Stakeholder to interview next]
- [Data to request]
- [System to get access to]

## Raw Quotes (Notable)

> "[Direct quote that captures a key insight]"
> — [Name], on [topic]
```

## Phase 3: Save Cleaned Interview Notes

If the input was pasted text, save to `docs/discovery/interviews/[name]-interview.md` with the interview template format (date, participants, context, questions & responses, discussion notes, action items).

## Phase 4: Extract and Append Assumptions

For each assumption identified in Phase 2:
1. Check `docs/discovery/ASSUMPTIONS-TRACKER.md` for duplicates (similar hypothesis)
2. If new, append using the hypothesis template format with:
   - Next sequential A## number
   - Hypothesis statement
   - Validation status: PENDING
   - Impact if TRUE / Impact if FALSE
   - Fallback plan
   - Owner: TBD
   - Source: Interview with [Name], [Date]

## Phase 5: Extract and Append Glossary Terms

For each domain-specific term, acronym, or system name mentioned:
1. Check `docs/GLOSSARY.md` for existing entries
2. If new, append with: Term, Definition (inferred from context), Source (interview reference)
3. If existing but interview adds context, update the definition

## Phase 6: Update System Inventory

For each system mentioned:
1. Check `docs/discovery/SYSTEM-INVENTORY.md` for existing entries
2. If new, add with available details: name, function, platform, network layer, integration type
3. If existing but interview adds detail, update the entry

## Phase 7: Generate Candidate Requirements

For each pain point or capability need identified:
1. Determine the next FR-### number (read existing requirements)
2. Write the requirement in standard format:
   ```
   **FR-X.X**: [Requirement title]
   **Description**: [What the system must do]
   **Source**: Interview with [Name], [Date]
   **Priority**: [P0/P1/P2 based on pain point severity]
   **Acceptance Criteria**: [Given/When/Then format]
   ```
3. Save to a working file: `docs/discovery/interviews/[name]-requirements-draft.md`

## Phase 8: Draft Gherkin Scenarios

For each candidate requirement, generate draft Gherkin scenarios:

```gherkin
@fr-X.X @draft @source-[interviewee-name]
Scenario: [Descriptive name from requirement]
  Given [context from current workflow]
  When [user action or system event]
  Then [expected outcome addressing the pain point]
```

Save to `docs/requirements/[topic]-draft.feature` with:
- Feature header (As a / I want / So that)
- Happy path scenario
- 1-2 edge case scenarios where the interview provided enough context
- All scenarios tagged `@draft` and `@source-[name]`

Do NOT modify existing non-draft feature files.

## Rules

- Never fabricate information not present in the interview notes
- Use exact quotes when attributing statements to the interviewee
- Mark any inferences with "(inferred)" so reviewers can validate
- All generated artifacts are drafts — tag them appropriately
- Do not commit — report what was created/updated and let the human review
- If the interview notes are thin on a topic, say so rather than padding
- Preserve interviewee voice in raw quotes section

## Output

Report:
1. Files created (with paths)
2. Files updated (with what changed)
3. Count: assumptions added, glossary terms added, systems added, requirements drafted, scenarios drafted
4. Gaps: topics where the interview was thin and follow-up is recommended
