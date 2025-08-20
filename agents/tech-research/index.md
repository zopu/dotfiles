# Technical Research Documentation Library

## Overview

This directory contains comprehensive technical research documentation maintained by the Tech Research Team, consisting of the Tech Research Lead, Tech Researcher, and Tech Research Librarian agents.

## Directory Structure

```
agents/tech-research/
├── index.md                                   # This catalog/index file
└── docs/                                     # Technology-specific documentation
    └── claudecode2025.md                     # Claude Code 2025 technology documentation
```

## Main Research Documents

*Main research files contain comprehensive analysis of topics requiring detailed research and multiple technology components. Individual technologies are documented in the docs/ subdirectory.*

Currently, all research focuses on specific technologies rather than broad topics. See Technology-Specific Documentation section below.

## Technology-Specific Documentation

The `docs/` subdirectory contains technology-specific documentation files following the naming convention `{technology}{version}.md`:

### Development Tools & Platforms
- **[claudecode2025.md](./docs/claudecode2025.md)** - Claude Code 2025 implementation guide
  - Complete agent architecture and configuration documentation
  - Multi-agent system collaboration patterns
  - Performance optimization and MCP integration
  - Research agent implementations (Tech Research Lead, Tech Researcher, Tech Research Librarian)
  - Best practices and troubleshooting guidance

Additional technology documentation files are created as research requirements demand.

## Agent Configuration Files

Agent definitions are stored in `../claude/.claude/agents/`:

- **[tech-research-lead.md](../claude/.claude/agents/tech-research-lead.md)** - Orchestrator agent for research coordination
- **[tech-researcher.md](../claude/.claude/agents/tech-researcher.md)** - Specialized research and documentation agent  
- **[tech-research-librarian.md](../claude/.claude/agents/tech-research-librarian.md)** - Library organization and maintenance agent

## Research Standards

### File Naming Conventions
- **Main research files**: Descriptive topic-based names (e.g., `react-authentication-apis-2024.md`)
- **Technology docs**: Exact format `{technology}{version}.md` (e.g., `bun12.md`, `reactv20.md`)
- **Index files**: `index.md` for directory catalogs

### Required Documentation Elements
- Executive summary with key takeaways
- Detailed technical analysis with implementation guidance
- Cross-references to related technology documentation
- Complete source citations
- Practical code examples and configuration details

### Quality Standards
- All research must include multiple authoritative sources
- Documentation must be implementation-ready
- Proper citations and source verification required
- Cross-verification of technical details mandatory

## Search and Discovery

To find existing research:
1. Check this index for main research topics
2. Search file names using glob patterns for keywords
3. Search content using grep for specific technologies
4. Check both main directory and `docs/` subdirectory
5. Look for related research that could be extended vs. creating new files

## Integration with Development Workflow

This research library is designed to:
- Eliminate need for additional research on covered topics
- Provide implementation-ready technical guidance
- Support rapid development decision-making
- Maintain consistency across development projects

## Maintenance

The Tech Research Librarian maintains this library structure, ensures proper cross-references, validates documentation integrity, and updates this index as new research is added.

---
*Last updated: 2025-01-07*
*Maintained by: Tech Research Librarian*