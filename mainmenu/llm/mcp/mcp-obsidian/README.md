# MCP Obsidian Server

Installs and configures the [MCP Obsidian server](https://github.com/bitbonsai/mcp-obsidian) — a Model Context Protocol server that gives AI assistants (Claude Desktop, Claude Code) safe read/write access to your Obsidian vaults.

## What It Does

- Checks Obsidian is installed
- Checks Node.js v18+ is available
- Auto-discovers your Obsidian vaults
- Downloads the MCP server package via npx
- Configures Claude Desktop and Claude Code MCP settings
- Full uninstall support (cleans up all config)

## Supported OSes

| OS | Status |
|----|--------|
| macOS | Supported |
| Ubuntu 22.04 | Not yet |
| Ubuntu 24.04 | Not yet |
| Debian | Not yet |
| Kali Linux | Not yet |
| Fedora | Not yet |

## Features Provided by the MCP Server

- Read, write, delete, move notes
- Search content and frontmatter
- Manage tags (add, remove, list)
- Batch read multiple notes
- Safe YAML frontmatter handling

## Source

- [github.com/bitbonsai/mcp-obsidian](https://github.com/bitbonsai/mcp-obsidian)
