# Discovery Project Initialization

Scaffold a new Spec-Driven Development (SDD) project with the full artifact structure for discovery, design, and construction phases.

## Inputs

Provide in your message (or I will ask):
- **Project name** and optional acronym
- **Client name**
- **Domain description** (1-2 paragraphs describing the problem space)
- **Known systems** (optional list of systems to seed inventory)
- **Known stakeholders** (optional list for interview scheduling)
- **SOW deliverable IDs** (optional; defaults to D1.1-D1.10, D2.1-D2.9)

## Phase 1: Create Directory Structure

Create these directories (skip any that already exist):

```
.github/
.github/instructions/
docs/
docs/discovery/
docs/discovery/interviews/
docs/discovery/architecture/
docs/discovery/database-schemas/
docs/deliverables/
docs/decisions/
docs/design/
docs/design/ux-design/
docs/requirements/
docs/onboarding/
docs/workflows/
docs/traceability/
session-logs/
```

## Phase 2: Generate Core Governance Documents

### .github/CONSTITUTION.md

Create the project constitution with these sections:
- **Mission**: One sentence using the project name and domain
- **Core Principles**: Spec-First Development, Bidirectional Traceability, Documentation-as-Code, AI-as-Team-Member, Continuous Validation
- **Definition of Done**: Four levels (Story, Sprint, Epic, Release) with checkbox lists
- **Quality Gates**: Five transitions (Discovery→Design, Design→Plan, Plan→Build, Build→Validate, Validate→Release)
- **Collaboration Norms**: Sections for human developers, AI agents, and everyone
- **Document Hierarchy**: Map of the directory structure with purpose annotations

### .github/WORKFLOWS.md

Create lifecycle documentation with:
- Lifecycle overview diagram (ASCII: DISCOVER → DESIGN → PLAN → BUILD → VALIDATE with feedback loop)
- Phase details: inputs, activities, outputs, gate criteria for each phase
- Key artifacts per phase
- Sprint cadence template
- Traceability flow diagram
- Handoff protocols between phases

### .github/instructions/spec-driven-dev.instructions.md

Create with YAML frontmatter `applyTo: "**/*.{feature,md}"` containing:
- Core principle statement
- BDD/Gherkin feature file location and structure guidance
- Traceability matrix update rules
- Phase gate checklists
- Acceptance criteria format (Given/When/Then)
- Documentation-as-code principles

### .github/instructions/interview-process.instructions.md

Create with guidance for:
- Interview preparation (read existing artifacts first)
- Structured question template (10 standard questions)
- Readout format (findings, systems, pain points, assumptions, actions)
- Pipeline: raw notes → readout → requirements → Gherkin scenarios

## Phase 3: Generate Discovery Templates

### docs/discovery/README.md
Navigation guide linking to all discovery artifacts.

### docs/discovery/DISCOVERY-REPORT.md
Shell with section headers for: Executive Summary, Discovery Methodology, Current State Assessment, System Landscape, Future State Vision, Key Findings & Validated Assumptions, Integration Architecture, Risk Register, Pilot Scope & Phasing, Next Steps. Include placeholder text explaining what goes in each section.

### docs/discovery/SYSTEM-INVENTORY.md
Template with a 3-tier structure: quick reference table, system summaries, and detailed profiles. Pre-populate column headers: System Name, Function, Platform, Network Layer, Integration Type, ENGAGE Role.

### docs/discovery/ASSUMPTIONS-TRACKER.md
Template with hypothesis format. Include one example assumption showing the pattern:
```
### A01: [Assumption Title]
**Hypothesis**: [Statement]
**Validation Status**: PENDING | VALIDATED | CONDITIONAL | FAILED
**Validation Method**: [How we will test this]
**Impact if TRUE**: [Consequence]
**Impact if FALSE**: [Consequence]
**Fallback**: [Plan C]
**Owner**: [Name]
**Due Date**: [Date]
```

### docs/discovery/interviews/interview-template.md
The 10-question structured template covering: role & mandate, current workflows, systems & tools, data flows & integrations, governance & access, pain points & gaps, success metrics, roadmap & dependencies, recommendations, follow-up needs. Include project context paragraph with placeholders for team names.

## Phase 4: Generate Deliverable Shells

For each D1.x deliverable, create a file in `docs/deliverables/` with:
- Title, document owner, date, status
- Table of contents with section numbers
- Placeholder text for each section explaining what content goes there

Default D1.x set:
- D1.1 - Pilot Scope & Boundary
- D1.2 - Prioritized Use Cases
- D1.3 - Data Sources Inventory & Access Plan
- D1.4 - Integration Requirements
- D1.5 - Target User Personas
- D1.6 - Process Maps & Workflows
- D1.7 - Requirements Specification
- D1.8 - Technology Stack Assessment
- D1.9 - Pilot Measurement & Governance
- D1.10 - Phase 2 Design Plan

## Phase 5: Generate Supporting Documents

### docs/GLOSSARY.md
Seed with domain-specific terms extracted from the domain description. Use a table format: Term | Definition | Source | First Used. Include standard acronyms section.

### docs/TRACEABILITY-MATRIX.md
Empty matrix scaffold with column headers: Req ID | Requirement | Feature File | Scenarios | Test File | Status. Include instructions for maintaining the matrix.

### docs/onboarding/README.md
"Welcome to [Project]" with 5-minute orientation: What is this project, How we work (SDD principles), Quick navigation table, Key documents (must-read list), First day checklist, AI agent instructions.

### docs/onboarding/QUICK-START.md
Environment setup template with sections for prerequisites, clone, install, run, verify.

### docs/onboarding/GLOSSARY.md
Subset of the main glossary with the 20-30 most essential domain terms for day-1 understanding.

### docs/onboarding/ROLES.md
RACI matrix template for: Product Owner, Tech Lead, Developer, QA, AI Agent. Include AI agent capabilities and boundaries.

### CONTRIBUTING.md
Development guidelines: code standards, conventional commits, branching strategy, testing requirements, data privacy rules, PR process, review checklist.

### FAQ.md
Shell with sections: General Questions, Technical Questions, Operational Questions, Documentation & Resources. Pre-populate 3-4 placeholder Q&A entries.

### README.md
Project hub with: project name/acronym, quick links table, overview (problem, solution, before/after example), project phases with status, key metrics targets, quick start, documentation index organized by role (PM, Architect, Developer, Everyone).

## Phase 6: Initialize Git-Friendly Files

- Create `.gitkeep` in empty directories (architecture, database-schemas, decisions, design, ux-design, requirements, workflows)
- Create `session-logs/.gitkeep`

## Rules

- All templates include placeholder text that explains what goes in each section -- never create empty files
- Use the project name and domain description to make templates project-specific, not generic
- Conventional commits terminology throughout
- Cross-reference links between documents must use relative paths
- Do not generate any code -- this is documentation scaffolding only
- Do not commit -- leave that to the user after review

## Output

Report a summary of files created, organized by category, with total count.
