# LLM Tools - Technical Manual

## Architecture

LLM tools are organized into three submenus:
- `cli/` - Command-line interfaces
- `ide/` - Graphical IDE applications
- `ai-tools/` - Standalone AI applications (ComfyUI)

Most CLI tools require Node.js and are installed via npm.

## Scripts Reference

### cli/claude-cli.sh

**Purpose:** Install Anthropic's Claude CLI

**Installation method:** npm global install
```bash
npm install -g @anthropic-ai/claude-cli
```

**Check:** `claude --version`

### cli/gemini-cli.sh

**Purpose:** Install Google's Gemini CLI

**Installation method:** npm global install

**Check:** `gemini --version`

### cli/codex-cli.sh

**Purpose:** Install OpenAI Codex CLI

**Installation method:** npm global install

**Check:** `codex --version`

### ide/cursor.sh

**Purpose:** Install Cursor AI editor

**Installation method:** AppImage download
```bash
curl -fsSL https://cursor.sh/download/linux -o cursor.AppImage
```

**Check path:** `~/.local/bin/cursor` or `/usr/bin/cursor`

### ide/antigravity.sh

**Purpose:** Install Google Antigravity IDE

**Installation method:** Direct download from Google
```bash
curl -fsSL https://antigravity.google/download/linux
```

### ai-tools/comfyui/comfyui/ (Tier 1 Modular)

**Purpose:** ComfyUI node-based AI image/video generation platform

**Location:** `mainmenu/llm/ai-tools/comfyui/comfyui/`

**Files:**
- `meta.yaml` — Metadata (name, description, check_path)
- `_common.sh` — Shared config (install path, repo URLs, Python version)
- `macos.sh` — macOS install/uninstall logic

**Check path:** `/opt/apps/LLM/ComfyUI/main.py`

**Key paths:**
- Install dir: `/opt/apps/LLM/ComfyUI`
- Models: `/opt/apps/LLM/ComfyUI/models/checkpoints/`
- User uploads: `/opt/apps/LLM/ComfyUI/input/`
- Output: `/opt/apps/LLM/ComfyUI/output/`
- Venv: `/opt/apps/LLM/ComfyUI/venv/`

**Full usage guide:** [ComfyUI Complete Guide](../../docs/comfyui-guide.md)

## Dependencies

- Node.js 20.x (from postsetup-kali/nodejs.sh) — for CLI tools
- npm — for CLI tools
- Python 3.12+, git, brew — for ComfyUI

## Development

### Adding a New LLM Tool

1. Determine installation method (npm, AppImage, deb, etc.)
2. Copy appropriate template
3. Set `check_command` and `check_path` for detection
4. Test installation and uninstallation

## See Also

- [User Guide](../user_manuals/llm.md)
