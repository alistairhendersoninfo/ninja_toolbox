# MCP Servers

Model Context Protocol (MCP) server installers for AI tool integration.

MCP servers extend AI assistants (Claude Desktop, Claude Code, etc.) with access to external data sources and tools. Each script installs and configures an MCP server, wiring it into your AI workflow automatically.

## Available Scripts

| Script | Description | OS |
|--------|-------------|----|
| [mcp-obsidian.sh](mcp-obsidian.sh) | MCP server for Obsidian vault access (read/write/search notes) | macOS |

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
