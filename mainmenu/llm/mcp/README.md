# MCP Servers

Model Context Protocol (MCP) server installers for AI tool integration.

MCP servers extend AI assistants (Claude Desktop, Claude Code, etc.) with access to external data sources and tools. Each script installs and configures an MCP server, wiring it into your AI workflow automatically.

## Available Scripts

| Action | Description | OS |
|--------|-------------|----|
| [mcp-obsidian/](mcp-obsidian/) | MCP server for Obsidian vault access (read/write/search notes) | macOS |

## Folder Structure

Each MCP server follows the modular OS-specific structure:

```
mcp-obsidian/
├── meta.yaml        # Metadata (name, description, supported OS)
├── _common.sh       # Shared logic (node checks, Claude Code config)
├── macos.sh         # macOS implementation
└── README.md        # Action-level docs
```

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to add new MCP servers or OS support.

## Prerequisites

- **Node.js v18+** — required for all MCP servers (`brew install node`)
- **AI client** — Claude Desktop or Claude Code must be installed

## How It Works

Each MCP installer:

1. Checks the target app is installed (e.g., Obsidian)
2. Downloads the MCP server package via npx
3. Configures Claude Desktop (`claude_desktop_config.json`) and/or Claude Code (`~/.claude.json`)
4. Provides instructions to activate

## Documentation

- **User Manual:** [`.docs/user_manuals/mcp.md`](../../../.docs/user_manuals/mcp.md)
- **Technical Manual:** [`.docs/technical_manuals/mcp.md`](../../../.docs/technical_manuals/mcp.md)
