# LLM Tools - User Guide

## Overview

The LLM menu provides tools for installing and using Large Language Model command-line interfaces and AI-powered IDEs.

## Available Tools

### CLI Tools

#### Claude CLI
Anthropic's official command-line interface for Claude AI.

**Installation:**
1. Run `ninjamenu` → Llm → Cli → Claude CLI
2. After installation, run `claude` to start

**Usage:**
```bash
claude              # Interactive mode
claude "question"   # Direct query
```

#### Gemini CLI
Google's command-line interface for Gemini AI.

**Installation:**
1. Run `ninjamenu` → Llm → Cli → Gemini CLI
2. Set up API key when prompted

#### OpenAI Codex
OpenAI's code generation CLI.

**Installation:**
1. Run `ninjamenu` → Llm → Cli → OpenAI Codex
2. Configure API key

### IDE Tools

#### Cursor
AI-first code editor built on VS Code.

**Installation:**
1. Run `ninjamenu` → Llm → Ide → Cursor
2. Launch from applications menu or `cursor` command

#### Antigravity
Google's experimental AI IDE.

**Installation:**
1. Run `ninjamenu` → Llm → Ide → Antigravity

## Prerequisites

- Node.js 20.x (install via PostsetupKali → Node.js)
- API keys from respective providers

## Troubleshooting

### Command not found after install

**Solution:** Restart your terminal or run `source ~/.bashrc`

### API key errors

**Solution:** Ensure you've set up API keys correctly for each service

## See Also

- [Technical Manual](../technical_manuals/llm.md)
