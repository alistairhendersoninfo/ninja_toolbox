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

### AI Tools

#### ComfyUI
Node-based GUI for AI image and video generation using Stable Diffusion, LTX-Video, and more.

**Getting started after install:**
1. Start: `cd /opt/apps/LLM/ComfyUI && source venv/bin/activate && python3 main.py`
2. Open http://127.0.0.1:8188
3. Download models via the **Manager** button > **Model Manager**
4. Upload PNGs by dragging onto the canvas or copying to `/opt/apps/LLM/ComfyUI/input/`
5. Output saves to `/opt/apps/LLM/ComfyUI/output/`

For the full guide including video generation and marketing clips, see: [ComfyUI Complete Guide](../../docs/comfyui-guide.md)

## Prerequisites

- Node.js 20.x (install via PostsetupKali → Node.js) — for CLI tools
- API keys from respective providers — for CLI tools
- 16 GB+ RAM recommended for ComfyUI video generation

## Troubleshooting

### Command not found after install

**Solution:** Restart your terminal or run `source ~/.bashrc`

### API key errors

**Solution:** Ensure you've set up API keys correctly for each service

## See Also

- [Technical Manual](../technical_manuals/llm.md)
