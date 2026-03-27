---
description: "Performs a comprehensive Principal Architect review including quality gates, security, and development practices"
allowed-tools: ["Bash", "Read", "Write", "Glob", "Grep", "LS", "WebFetch", "TodoWrite"]
---

# Principal Architect Review

Perform a comprehensive architectural review of the current project considering:

- **AWS Well-Architected Framework** — Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability
- **Azure Well-Architected Framework** — Cost Optimization, Operational Excellence, Performance Efficiency, Reliability, Security
- **CNCF Cloud Native principles** — Containerization, orchestration, microservices, observability
- **AI Systems Engineering Patterns** — LLM integration patterns: caching, routing, guardrails, RAG
- **Design Patterns** — Architectural, creational, and behavioral patterns
- **SOLID Design principles** — Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Clean Code practices** — Code quality, naming conventions, function design, documentation
- **CAP Theorem implications** — Consistency, Availability, Partition tolerance trade-offs
- **Quality Gates & Testing Standards** — Test coverage metrics, API testing, regression testing, edge cases
- **Security Gates** — Zero-tolerance vulnerability policies, secret scanning, dependency monitoring
- **Technical Debt Management** — File management policies, directory structure, debt prevention

## Before reviewing: load project context

If the project has these files, read them before starting the analysis:

1. `docs/guidelines/` — modular rule files (security, API, data, coding standards). These are the project's accumulated rules from past reviews.
2. `docs/adr/` — architecture decision records. These constrain what choices are valid.
3. `docs/design/` — PRD, SRS, database schema, design plans. These are the requirements.
4. `docs/api/openapi.yaml` — the API contract.
5. `AGENTS.md` — cross-tool project instructions.

Not all projects have these. Skip any that don't exist.

## Analysis Instructions

1. **Project Structure Analysis**: Detect technology stack, examine configuration files, identify architectural patterns
2. **Specification Review**: Find and analyze specifications, requirements, or ADRs in the codebase
3. **Implementation Coverage**: Evaluate how well specifications are implemented
4. **Architectural Assessment**: Review against the frameworks and principles listed above
5. **Quality Gates Assessment**: Evaluate test coverage (>=85% target), API testing completeness (100% target), lint/type errors (0 tolerance), security vulnerabilities (0 critical/high tolerance)
6. **Security Posture Analysis**: Review secret management, dependency security, vulnerability scanning, security automation. If `docs/guidelines/security.md` exists, verify compliance with every rule.
7. **Code Quality Evaluation**: Examine lint configurations, type safety, clean code adherence. If `docs/guidelines/coding-standards.md` exists, verify compliance.
8. **Technical Debt Assessment**: Identify forbidden file patterns (_fix, _old, _backup, _temp), directory structure cleanliness
9. **ADR Compliance**: If `docs/adr/` exists, verify the architecture aligns with all accepted ADRs. Flag any violations or decisions that need revisiting.
10. **AI/LLM Integration Assessment** (if applicable): Evaluate input handling, caching strategies, routing, guardrails, resilience
11. **Documentation Generation**: Create a comprehensive markdown report in `docs/arch-review-YYYY-MM-DD-HHMMSS.md`

## After the review

- For significant findings that represent architectural decisions, recommend creating an ADR in `docs/adr/`.
- For findings that represent repeatable rules, recommend adding them to the appropriate `docs/guidelines/` file.

Focus on providing actionable recommendations prioritized by impact and effort required.

The report should categorize recommendations by priority (Critical, High, Medium, Low) with clear implementation guidance and success metrics.