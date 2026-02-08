# Cross-Platform Library — Development Notes

## PR: feature/cross-platform-library

### What this adds
A shared platform library (`.lib/platform.sh`) that all install scripts source for OS detection, cross-platform package management, and common helper functions. This is the foundation for making all 50+ scripts work on both Linux and macOS.

### Files created/modified
- `.lib/platform.sh` — NEW: shared cross-platform library
- `.app/menu.py` — fix sudo handling on macOS
- `.docs/templates/script_template.sh` — use platform.sh, remove boilerplate
- `.docs/templates/config_template.sh` — use platform.sh, remove boilerplate
- `CONTRIBUTING.md` — add platform.sh usage guide
- `README.md` — note cross-platform library in architecture

### This is PR 1 of 4
1. **PR 1 (this)**: Foundation — library, menu.py fix, templates
2. PR 2: Convert simple scripts (monitoring/ + network/)
3. PR 3: Convert medium + config scripts
4. PR 4: Linux-only guards + platform YAML field

### Acceptance criteria
- [ ] `source .lib/platform.sh` sets NT_OS, NT_DISTRO, NT_ARCH on macOS
- [ ] `pkg_install zenmap` resolves to `brew install --cask zenmap` on macOS
- [ ] `require_root` blocks sudo on macOS, requires sudo on Linux
- [ ] `mark_installed` works on macOS (no `.bak` files)
- [ ] `ninjamenu` doesn't prepend sudo on macOS
- [ ] `.lib/` hidden from menu discovery
