# Project Constitution Generator

## When to Use

- Starting a new project and establishing governance before code
- Formalizing an existing project's working agreements
- Onboarding a team to Spec-Driven Development practices
- Called automatically by the `discovery-init` droid

## Instructions

### 1. Gather project context

Read `README.md` (if it exists) to extract:
- Project name and acronym
- Domain / problem space
- Team structure (if mentioned)

If no README exists, ask you for: project name, mission (one sentence), and primary domain.

### 2. Generate .github/CONSTITUTION.md

Create the file with these sections:

#### Mission
One sentence: "Deliver the **[Project Name]** through spec-driven development, ensuring every feature traces from business need → design → implementation → validation."

#### Core Principles (5 — use these verbatim)
1. **Spec-First Development**: Write specifications before code. Requirements, feature files, and acceptance criteria are first-class artifacts that drive implementation.
2. **Bidirectional Traceability**: Every artifact links forward and backward: `UX Design → Requirement → Feature → Epic → Story → Code → Test → Validation`
3. **Documentation-as-Code**: Documentation lives in the repository, updated in the same PR as code changes. Stale docs are treated as bugs.
4. **AI-as-Team-Member**: AI agents are full team participants. They follow the same processes, use the same templates, and produce the same quality output as human developers.
5. **Continuous Validation**: Validate continuously against specifications — not just at milestones. Every story completion proves traceability.

#### Definition of Done (4 levels)

**Story Done**:
- [ ] Code complete and reviewed
- [ ] Unit tests pass
- [ ] Feature file scenarios pass
- [ ] Traceability matrix updated
- [ ] UX matches design (screenshot evidence for UI stories)
- [ ] Documentation updated

**Sprint Done**:
- [ ] All committed stories meet Story Done criteria
- [ ] Sprint retrospective completed
- [ ] Traceability coverage updated

**Epic Done**:
- [ ] All stories complete
- [ ] End-to-end tests pass
- [ ] Stakeholder acceptance documented
- [ ] Feature files reflect final behavior

**Release Done**:
- [ ] All epics complete
- [ ] Performance benchmarks met
- [ ] Security review passed
- [ ] Deployment runbook verified
- [ ] Documentation published

#### Quality Gates

| Transition | Gate Criteria | Enforced By |
|------------|---------------|-------------|
| Discovery → Design | Requirements documented (FR-###), UX mockups complete | PM review |
| Design → Plan | Architecture approved (ADR), API contracts defined | Tech lead review |
| Plan → Build | Epics broken into stories, acceptance criteria written | Sprint planning |
| Build → Validate | Tests pass, traceability proven, docs updated | PR checklist |
| Validate → Release | UAT complete, stakeholder sign-off | Release review |

#### Collaboration Norms

Include sections for: Human Developers, AI Agents, Everyone — with 4 rules each.

#### Document Hierarchy

Map the project's directory structure with purpose annotations.

#### Amendments

"This constitution may be amended through an ADR. Create `docs/decisions/ADR-NNN-constitution-amendment.md` with rationale."

### 3. Generate .github/WORKFLOWS.md

Create the file with:

- ASCII lifecycle diagram: DISCOVER → DESIGN → PLAN → BUILD → VALIDATE with feedback loop
- Phase details table for each phase: Inputs, Activities, Outputs, Gate criteria
- Key artifacts per phase
- Traceability flow diagram (ASCII)
- Handoff protocol checklists between phases

### 4. Verify

- [ ] CONSTITUTION.md has all 6 sections
- [ ] WORKFLOWS.md has all 5 phases documented
- [ ] Quality gates match between both documents
- [ ] Cross-references between documents use correct relative paths
- [ ] Project name appears in Mission statement

## Output

Report the two files created and their key sections.
