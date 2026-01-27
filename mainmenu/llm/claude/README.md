# Claude Tools

Tools for installing and configuring Claude Code CLI and custom skills.

## Scripts

| Script | Description | Type |
|--------|-------------|------|
| Claude Code CLI | Install Anthropic's official Claude Code CLI | install |
| Install Claude Skills | Copy custom skills to your .claude folder | config |

## Quick Start

```bash
ninjamenu
# Navigate to: LLM -> Claude -> Claude Code CLI (to install)
# Navigate to: LLM -> Claude -> Install Claude Skills (to add skills)
```

## Included Skills

### git-commit
Provides a structured workflow for staging, committing, and pushing git changes. Triggers when you ask Claude to "commit", "git commit", "push code", etc.

## Adding New Skills

1. Create a folder in `skills/` with your skill name
2. Add a `SKILL.md` file with frontmatter:
   ```yaml
   ---
   name: skill-name
   description: When to trigger this skill...
   version: 1.0.0
   ---
   ```
3. Add skill content in markdown format
4. Run "Install Claude Skills" to deploy

## Documentation

- [User Guide](../../../.docs/user_manuals/llm.md) - Usage instructions
- [Technical Manual](../../../.docs/technical_manuals/llm.md) - Developer docs

## Requirements

- Node.js and npm (for Claude Code CLI)
- Existing Claude installation (for skills)

## Tags

`llm` `claude` `anthropic` `ai` `skills`
