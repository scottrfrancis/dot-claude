# README Documentation Guidelines

Guidelines for organizing project documentation with README.md as the central navigation hub.

## Core Principle

**All user-facing information must be accessible from the README.md file, either directly included or linked.**

Users should never need to hunt through the repository structure to find documentation. The README serves as the single entry point for understanding and using the project.

## README Structure

### Essential Sections

Every README.md should include these sections in this order:

1. **Project Title and Description** - What the project does
2. **Installation/Setup** - How to get started
3. **Usage** - Basic usage examples
4. **Documentation** - Links to all other documentation
5. **Contributing** - How to contribute (if applicable)
6. **License** - Legal information

### Documentation Section

**Do this:**
```markdown
## Documentation

- [User Guide](docs/user-guide.md) - Complete usage instructions
- [API Reference](docs/api/README.md) - Full API documentation
- [Developer Guide](docs/development.md) - Setup for contributors
- [Architecture](docs/architecture.md) - System design and structure
- [Changelog](CHANGELOG.md) - Version history
- [FAQ](docs/faq.md) - Frequently asked questions
```

**Don't do this:**
```markdown
## Documentation

See the docs folder for more information.
```

## Documentation Organization Patterns

### Pattern 1: Inline README (Small Projects)

For simple projects, include all documentation directly in README.md:

```markdown
# Project Name

Brief description

## Installation
[Installation steps here]

## Usage
[Usage examples here]

## API Reference
[Complete API docs here]

## Contributing
[Contributing guidelines here]
```

### Pattern 2: Linked Documentation (Medium Projects)

Use a `docs/` directory with clear navigation:

```markdown
# Project Name

Brief description and quick start

## Quick Start
[Essential getting started info]

## Documentation

- **[User Guide](docs/user-guide.md)** - Complete usage instructions
- **[API Reference](docs/api.md)** - Method and endpoint documentation  
- **[Examples](docs/examples/)** - Code examples and tutorials
- **[FAQ](docs/faq.md)** - Common questions and solutions

## Development

- **[Contributing](docs/contributing.md)** - How to contribute
- **[Development Setup](docs/development.md)** - Environment setup
- **[Architecture](docs/architecture.md)** - Technical overview
```

### Pattern 3: Multi-Section Documentation (Large Projects)

For complex projects with multiple audiences:

```markdown
# Project Name

Brief description

## For Users
- **[Installation Guide](docs/installation.md)** - Setup instructions
- **[User Manual](docs/user-manual.md)** - Complete usage guide
- **[Tutorials](docs/tutorials/)** - Step-by-step walkthroughs
- **[FAQ](docs/faq.md)** - Common questions

## For Developers  
- **[API Documentation](docs/api/)** - Complete API reference
- **[SDK Documentation](docs/sdk/)** - Language-specific guides
- **[Architecture Guide](docs/architecture.md)** - Technical overview

## For Contributors
- **[Contributing Guide](docs/contributing.md)** - How to contribute
- **[Development Setup](docs/development.md)** - Environment setup
- **[Code Style Guide](docs/style-guide.md)** - Coding standards
```

## Documentation File Organization

### Directory Structure

**Do this:**
```
docs/
├── README.md              # Documentation index (optional)
├── user-guide.md         # Complete user documentation
├── api/
│   ├── README.md         # API overview
│   ├── authentication.md
│   └── endpoints.md
├── examples/
│   ├── README.md         # Examples index
│   ├── basic-usage.md
│   └── advanced-usage.md
└── development/
    ├── README.md         # Development docs index
    ├── setup.md
    └── testing.md
```

### Linking Best Practices

1. **Use descriptive link text**: `[User Guide](docs/user-guide.md)` not `[here](docs/user-guide.md)`
2. **Include brief descriptions**: Explain what each linked document contains
3. **Use relative paths**: `docs/guide.md` not `/project/docs/guide.md`
4. **Verify all links work**: Broken documentation links frustrate users

## Content Guidelines

### What Goes in README vs Separate Files

**Include directly in README:**
- Project overview and purpose
- Quick installation steps
- Basic usage example
- Essential getting started information
- Links to all other documentation

**Link to separate files:**
- Detailed installation procedures
- Complete API documentation
- Extensive tutorials and examples
- Architecture and design documents
- Contributing guidelines and development setup

### Navigation Aids

**Do this:**
```markdown
## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)  
- [Documentation](#documentation)
- [Examples](#examples)
- [Contributing](#contributing)
```

**For multi-page documentation:**
```markdown
📖 **[Complete Documentation](docs/README.md)** - Full documentation index
```

## Examples

### Good README Documentation Section

```markdown
## Documentation

### For Users
- **[Getting Started](docs/getting-started.md)** - Installation and first steps
- **[User Guide](docs/user-guide.md)** - Complete feature documentation
- **[CLI Reference](docs/cli-reference.md)** - Command-line interface
- **[Configuration](docs/configuration.md)** - Settings and customization

### For Developers
- **[API Documentation](docs/api/)** - REST API reference
- **[SDK Documentation](docs/sdk/)** - Language bindings
- **[Examples Repository](https://github.com/org/project-examples)** - Code samples

### Additional Resources
- **[FAQ](docs/faq.md)** - Frequently asked questions
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Changelog](CHANGELOG.md)** - Version history and updates
```

### Bad README Documentation Section

```markdown
## Documentation

Check out our wiki for more info. There's also some docs in the docs folder.
```

## Maintenance

1. **Keep links current**: Verify all documentation links work
2. **Update navigation**: When adding new docs, update README links
3. **Review organization**: Periodically assess if the structure still makes sense
4. **User feedback**: Monitor issues for documentation requests or confusion

## Claude Code Integration

When asking Claude Code to create or organize documentation:

```
Please follow ~/.claude/guidelines/readme-documentation.md for all documentation organization.
```

Ensure that:
- All user-facing information is accessible from README.md
- Documentation structure is clear and navigable
- Links include helpful descriptions
- Organization follows established patterns