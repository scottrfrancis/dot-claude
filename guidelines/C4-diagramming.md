# C4 Model PlantUML Diagramming Guidelines

## Overview

This document provides global guidelines for working with C4 Model architecture diagrams using PlantUML. These guidelines apply to any project using the C4 Model with PlantUML for system architecture documentation.

## PlantUML File Structure and Organization

### Modular Include Pattern

The recommended approach for organizing PlantUML C4 diagrams follows a modular pattern:

1. **Individual Definition Files**: Each system, person, container, or component is defined in its own `.puml` file with a unique identifier
   - Example: `systems/ai-agent.puml`, `persons/participant.puml`
   - Each file contains a single definition with a unique ID

2. **Category Aggregators**: Group related definitions using aggregator files
   - `internal-systems.puml` - Includes all internal system definitions
   - `external-systems.puml` - Includes all external system definitions
   - `persons.puml` - Includes all person/actor definitions
   - Use `!include` statements to aggregate individual files

3. **Main Diagram Files**: Top-level diagram files that compose the architecture views
   - `10-Context.plantuml` - C1 System Context diagram
   - `20-Container.plantuml` - C2 Container diagram
   - `30-Component.plantuml` - C3 Component diagram
   - Include aggregators or specific definition files as needed

### Directory Structure

```
docs/diagrams/
├── 10-Context.plantuml       # C1 System Context
├── 20-Container.plantuml     # C2 Container
├── 30-Component.plantuml     # C3 Component
├── systems/                   # System definitions
│   ├── internal-systems.puml # Aggregator for internal
│   ├── external-systems.puml # Aggregator for external
│   └── *.puml                # Individual system files
├── containers/               # Container definitions
│   └── *.puml
├── components/               # Component definitions
│   └── *.puml
└── persons/                  # Person/actor definitions
    ├── persons.puml         # Aggregator
    └── *.puml              # Individual person files
```

## C4 Level-Specific Guidelines

### C1 Context Diagram
- **Include ALL systems** (both internal and external) to show complete system context
- Use bulk include files (`internal-systems.puml`, `external-systems.puml`)
- Show all major external dependencies and integrations
- Focus on high-level relationships between systems

### C2 Container Diagram
- **Use selective includes** to avoid conflicts
- Common conflict: A system in C1 may become a System_Boundary in C2
- Include only external systems that directly interact with containers
- Focus on the internal architecture of your system

### C3 Component Diagram
- Drill down into specific container internals
- Include only relevant external dependencies
- Show component-level interactions and dependencies

## Common Pitfalls and Solutions

### 1. System vs System_Boundary Conflicts

**Problem**: An element defined as `System()` in C1 needs to be `System_Boundary()` in C2.

**Solution**: 
- Use selective includes in C2 instead of bulk aggregator files
- Directly include only the specific system files needed
- Redefine elements within the appropriate boundary when needed

**Example**:
```plantuml
' C2 Container - Use selective includes
!include ./systems/performancecentral.puml
!include ./systems/apim.puml
' Don't include ai-agent.puml since it's a System_Boundary here
System_Boundary(AIAgentSystem, "AI Agent System") {
    !include ./containers/containers.puml
}
```

### 2. Orphaned Systems

**Problem**: Systems included but not connected to any relationships.

**Solution**:
- Review all included systems and verify they have relationships
- Remove unused includes to keep diagrams clean
- Use comments to document why a system is included if relationships aren't obvious

### 3. Boundary Confusion

**Problem**: Unclear whether a system is internal or external.

**Solution**:
- Refer to authoritative architecture documentation
- Document boundary decisions in comments
- Use consistent placement across all diagram levels

## Maintenance Guidelines

### When Updating Diagrams

1. **Always verify parent diagrams** - Ensure C1 isn't broken when updating C2
2. **Test rendering** - Verify PlantUML diagrams render correctly after changes
3. **Use version control** - Track changes to understand evolution
4. **Document decisions** - Add comments for non-obvious architectural choices

### Change Process

1. **Before changes**:
   - Review existing diagrams at all levels
   - Understand current include structure
   - Identify potential conflicts

2. **During changes**:
   - Update individual definition files first
   - Test each diagram level separately
   - Verify relationships are maintained

3. **After changes**:
   - Render all affected diagrams
   - Verify no broken references
   - Update documentation if structure changed

## Best Practices

### Naming Conventions

- **Files**: Use lowercase with hyphens (e.g., `api-gateway.puml`)
- **IDs**: Use PascalCase for IDs (e.g., `APIGateway`)
- **Boundaries**: Suffix with purpose (e.g., `AIAgentSystem`, `vnet`)

### Documentation

- Add comments in PlantUML files to explain complex relationships
- Document why certain systems are included/excluded
- Note any deviations from standard patterns

### Relationships

- Use descriptive labels for all relationships
- Include technology/protocol where relevant
- Group related relationships with comments

### Layout

- Use `Lay_*` directives sparingly - let PlantUML auto-layout when possible
- Group related elements within boundaries
- Maintain consistent positioning across diagram levels when feasible

## Integration with Project Documentation

### Project-Specific Files

While these guidelines are global, each project should maintain:

1. **CLAUDE.md** or **README.md** - Project-specific architecture notes
2. **Architecture decision records** - Document key decisions
3. **Client documentation** - Authoritative source for requirements

### Referencing Guidelines

Projects should reference these global guidelines rather than duplicating them:

```markdown
## Working with Diagrams

This project follows the [C4 Model PlantUML Guidelines](~/.claude/guidelines/C4-diagramming.md)
for diagram organization and maintenance.

### Project-Specific Notes
[Add any project-specific variations or notes here]
```

## Tools and Resources

### Recommended Tools

- **PlantUML** - Diagram rendering
- **VS Code** with PlantUML extension - Local preview
- **C4-PlantUML** - Standard library for C4 diagrams

### Useful Resources

- [C4 Model](https://c4model.com/) - Official C4 Model documentation
- [C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML) - C4 PlantUML library
- [PlantUML](https://plantuml.com/) - PlantUML documentation

## Version

Last Updated: August 2025
Version: 1.0