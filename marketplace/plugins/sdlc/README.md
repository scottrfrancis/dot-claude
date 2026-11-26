# sdlc plugin

Seven commands for Spec-Driven Development, harvested from an airgapped engagement fork. They
cost listing space in every session, and most projects never use them, so they live in a plugin
that a project turns on.

| Command | Purpose |
| ------- | ------- |
| `/sdlc:discovery-init` | Scaffold the artifact structure, glossary, constitution and traceability chain |
| `/sdlc:interview-to-spec` | Turn interview notes into a readout, FR-### requirements and Gherkin scenarios |
| `/sdlc:gherkin` | Draft acceptance scenarios from a requirement or FR-### |
| `/sdlc:assumptions` | Track an assumption with its if-true, if-false and fallback |
| `/sdlc:trace-check` | Validate traceability across requirements, features, scenarios and tests |
| `/sdlc:constitution` | Generate CONSTITUTION.md and WORKFLOWS.md |
| `/sdlc:design-review` | Review design deliverables for consistency and reference integrity |

## Turning it on

The marketplace is this repo's `marketplace/` directory, and Claude Code serves the plugin from
the checkout, so a pull updates it. Declare the marketplace once per host, in
`~/.claude/settings.json`, with the checkout's absolute path:

```json
"extraKnownMarketplaces": {
  "dot-claude": { "source": { "source": "directory", "path": "/Users/you/.claude/marketplace" } }
}
```

Then enable the plugin in the project that uses it, in its committed `.claude/settings.json`:

```json
"enabledPlugins": { "sdlc@dot-claude": true }
```
