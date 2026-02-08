---
layout: default
title: LLM & AI
parent: Tool Reference
grand_parent: Documentation
nav_order: 3
---

# LLM & AI Tools

Tools for installing and using Large Language Model command-line interfaces and AI-powered IDEs.

**Location:** [`mainmenu/llm/`](https://github.com/alistairhendersoninfo/ninja_toolbox/tree/main/mainmenu/llm)

## CLI Tools

**Location:** [`mainmenu/llm/cli/`](https://github.com/alistairhendersoninfo/ninja_toolbox/tree/main/mainmenu/llm/cli)

| Tool | Description | Install Method | Check Command |
|------|-------------|---------------|---------------|
| Claude CLI | Anthropic's Claude AI terminal interface | npm global | `claude --version` |
| Gemini CLI | Google's Gemini AI terminal interface | npm global | `gemini --version` |
| Codex CLI | OpenAI's Codex code generation CLI | npm global | `codex --version` |

### Usage

```bash
claude              # Interactive mode
claude "question"   # Direct query
```

## IDE Tools

**Location:** [`mainmenu/llm/ide/`](https://github.com/alistairhendersoninfo/ninja_toolbox/tree/main/mainmenu/llm/ide)

| Tool | Description | Install Method |
|------|-------------|---------------|
| Cursor | AI-first code editor built on VS Code | AppImage (Linux) / Homebrew cask (macOS) |
| Antigravity | Google's experimental AI IDE | Direct download |

## Prerequisites

- **Node.js 20.x** -- Required for all CLI tools. Install via Post-Setup Kali > Node.js, or the menu will prompt you.
- **API keys** -- Each CLI tool requires an API key from its respective provider.

## Troubleshooting

### Command not found after install

Restart your terminal or run `source ~/.bashrc` / `source ~/.zshrc`.

### API key errors

Ensure you've configured API keys for each service. Follow the setup prompts that appear on first run.

## Technical Details

- CLI tools are installed globally via `npm install -g`
- IDE tools use platform-specific installation (AppImage on Linux, Homebrew cask on macOS)
- The Claude CLI skill integration lives in `mainmenu/llm/claude/.skills/` and provides Claude Code workflow automation
