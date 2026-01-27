# LLM Tools - Technical Manual

## Architecture

LLM tools are organized into two submenus:
- `cli/` - Command-line interfaces
- `ide/` - Graphical IDE applications

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

## Dependencies

- Node.js 20.x (from postsetup-kali/nodejs.sh)
- npm

## Development

### Adding a New LLM Tool

1. Determine installation method (npm, AppImage, deb, etc.)
2. Copy appropriate template
3. Set `check_command` and `check_path` for detection
4. Test installation and uninstallation

## See Also

- [User Guide](../user_manuals/llm.md)
