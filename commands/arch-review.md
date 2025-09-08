---
description: "Performs a comprehensive Principal Architect review including quality gates, security, and development practices"
allowed-tools: ["Bash", "Read", "Write", "Glob", "Grep", "LS", "WebFetch", "TodoWrite"]
---

# Principal Architect Review

Perform a comprehensive architectural review of the current project considering:

• **AWS Well-Architected Framework** - Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability
• **Azure Well-Architected Framework** - Cost Optimization, Operational Excellence, Performance Efficiency, Reliability, Security  
• **CNCF Cloud Native principles** - Containerization, orchestration, microservices, observability
• **Design Patterns** - Architectural, creational, and behavioral patterns
• **SOLID Design principles** - Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
• **Clean Code practices** - Code quality, naming conventions, function design, documentation
• **CAP Theorem implications** - Consistency, Availability, Partition tolerance trade-offs
• **Quality Gates & Testing Standards** - Test coverage metrics, API testing, regression testing, edge cases
• **Atomic Development Practices** - Single logical units, TDD approach, rollback safety
• **Security Gates** - Zero-tolerance vulnerability policies, secret scanning, dependency monitoring
• **Code Quality Standards** - Lint/type safety, pre-commit hooks, clean code enforcement
• **Technical Debt Management** - File management policies, directory structure, debt prevention
• **Progress & Metrics Tracking** - Sprint progress, quality metrics, feature completion tracking
• **Emergency Response Protocols** - Production issue response, hotfix procedures, retrospectives

## Analysis Instructions

Please analyze the current project by:

1. **Project Structure Analysis**: Detect technology stack, examine configuration files, and identify architectural patterns
2. **Specification Review**: Find and analyze any specifications, requirements, or ADRs in the codebase
3. **Implementation Coverage**: Evaluate how well specifications are implemented
4. **Architectural Assessment**: Review against the frameworks and principles listed above
5. **Quality Gates Assessment**: Evaluate test coverage (≥85% target), API testing completeness (100% target), lint/type errors (0 tolerance), security vulnerabilities (0 critical/high tolerance)
6. **Development Process Review**: Assess atomic development practices, TDD implementation, rollback safety, and technical debt management
7. **Security Posture Analysis**: Review secret management, dependency security, vulnerability scanning, and security automation
8. **Code Quality Evaluation**: Examine lint configurations, type safety, pre-commit hooks, and clean code adherence
9. **Technical Debt Assessment**: Identify forbidden file patterns, directory structure cleanliness, and debt prevention strategies
10. **Progress Tracking Review**: Evaluate metrics collection, sprint tracking, and quality gate integration
11. **Emergency Preparedness**: Assess production incident response, hotfix procedures, and retrospective practices
12. **Documentation Generation**: Create a comprehensive markdown report in `docs/arch-review-YYYY-MM-DD-HHMMSS.md`

Focus on providing actionable recommendations prioritized by impact and effort required.

## Implementation

1. **Project Structure & Technology Analysis**
   - Detect technology stack and framework usage
   - Analyze configuration files and build systems
   - Identify architectural patterns and layer separation

2. **Specification & Requirements Review**
   - Search for and read existing specifications, ADRs, requirements documents
   - Evaluate specification completeness and clarity
   - Assess business logic documentation

3. **Quality Gates Assessment**
   - Check test coverage metrics (target: ≥85% overall, 100% API)
   - Analyze test suite structure (unit, integration, regression, edge cases)
   - Review testing frameworks and practices
   - Examine API testing completeness (Postman collections, contract tests)

4. **Security Posture Evaluation**
   - Scan for hardcoded secrets and credentials
   - Review dependency security and vulnerability management
   - Assess security scanning automation (npm audit, Snyk, etc.)
   - Evaluate authentication and authorization implementation

5. **Code Quality Analysis**
   - Check lint configurations and error tolerance (target: 0 errors)
   - Review TypeScript/language-specific type safety
   - Analyze pre-commit hooks and quality enforcement
   - Assess code formatting and style consistency

6. **Atomic Development Review**
   - Evaluate commit granularity and atomic change practices
   - Review Test-Driven Development (TDD) implementation
   - Assess rollback safety and deployment independence
   - Analyze branching strategy and feature isolation

7. **Technical Debt Assessment**
   - Identify forbidden file patterns (_fix, _old, _backup, _temp, etc.)
   - Review directory structure cleanliness
   - Assess code duplication and refactoring needs
   - Evaluate debt prevention strategies

8. **Development Process Analysis**
   - Review CI/CD pipeline quality gates
   - Assess automated testing integration
   - Evaluate deployment and rollback procedures
   - Analyze code review processes

9. **Progress Tracking & Metrics**
   - Review sprint/iteration tracking mechanisms
   - Assess quality metrics collection and dashboards
   - Evaluate feature completion tracking with quality gates
   - Analyze performance and reliability metrics

10. **Emergency Response Preparedness**
    - Review production incident response procedures
    - Assess hotfix deployment processes
    - Evaluate monitoring and alerting systems
    - Review retrospective and learning practices

11. **Documentation Standards Review**
    - Assess API documentation (OpenAPI/Swagger specs)
    - Review code documentation (JSDoc/TSDoc coverage)
    - Evaluate Architecture Decision Records (ADRs)
    - Check setup, deployment, and operational guides

12. **Comprehensive Report Generation**
    - Create detailed architectural review report
    - Include all Well-Architected frameworks assessment
    - Provide SOLID principles and Clean Code evaluation
    - Include CAP theorem trade-off analysis
    - Generate prioritized recommendations with impact/effort matrix

The report should provide actionable recommendations categorized by priority (Critical, High, Medium, Low) with clear implementation guidance and success metrics.