# Toolsets - Technical Manual

## Architecture

The toolsets category is divided into three subcategories, each in its own subfolder:

```
mainmenu/toolsets/
├── terminals/          # GPU-accelerated terminal emulators (Tier 2)
├── dev-tools/          # CLI developer tools (Tier 2)
└── theming/            # Catppuccin Mocha theme configs (mixed Tier 1 + Tier 2)
```

All install scripts are Tier 2 (single `.sh` + `.meta.yaml`) except `catppuccin-kde/` which is Tier 1 (folder with `meta.yaml`, `_common.sh`, `linux.sh`) because KDE theming is Linux-specific and may gain macOS/Windows support later.

## Scripts Reference

### Terminals

| Script | Package | Binary | Check |
|--------|---------|--------|-------|
| `kitty.sh` | `kitty` (apt) | `/usr/bin/kitty` | `kitty --version` |
| `wezterm.sh` | `wezterm` (apt.fury.io/wez/) | `/usr/bin/wezterm` | `wezterm --version` |
| `alacritty.sh` | `alacritty` (apt) | `/usr/bin/alacritty` | `alacritty --version` |

**WezTerm** uses a third-party APT repository (apt.fury.io). The GPG key is stored at `/usr/share/keyrings/wezterm-fury.gpg` and the source list at `/etc/apt/sources.list.d/wezterm.list`. Both are cleaned up on uninstall.

### Developer Tools

| Script | Package | Binary | Check | Notes |
|--------|---------|--------|-------|-------|
| `neovim.sh` | `neovim` | `/usr/bin/nvim` | `nvim --version` | |
| `tmux.sh` | `tmux` | `/usr/bin/tmux` | `tmux -V` | |
| `ripgrep.sh` | `ripgrep` | `/usr/bin/rg` | `rg --version` | |
| `fd.sh` | `fd-find` | `/usr/bin/fdfind` | `fdfind --version` | Symlink to `/usr/local/bin/fd` |
| `fzf.sh` | `fzf` | `/usr/bin/fzf` | `fzf --version` | |
| `bat.sh` | `bat` | `/usr/bin/batcat` | `batcat --version` | Symlink to `/usr/local/bin/bat` |
| `lazygit.sh` | GitHub release | `/usr/local/bin/lazygit` | `lazygit --version` | Downloads latest tar.gz from GitHub API |

**fd and bat binary naming:** On Debian/Ubuntu, `fd-find` installs as `fdfind` and `bat` installs as `batcat` to avoid conflicts with existing packages. The scripts create convenience symlinks at `/usr/local/bin/`.

**lazygit installation:** Downloads the latest release from the GitHub API (`jesseduffield/lazygit`), extracts the `lazygit` binary from the tar.gz, and installs it to `/usr/local/bin/` using the `install` command. No APT repository is needed.

### Theming

| Script | Type | Tier | Targets |
|--------|------|------|---------|
| `catppuccin-kde/` | install | 1 | KDE color schemes, Kvantum Qt theme |
| `catppuccin-terminals.sh` | config | 2 | kitty, WezTerm, Alacritty color configs |
| `catppuccin-neovim.sh` | config | 2 | Neovim catppuccin plugin (lazy.nvim/packer) |
| `catppuccin-tmux.sh` | config | 2 | tmux via TPM plugin |
| `catppuccin-hyprland.sh` | config | 2 | Hyprland borders, Waybar CSS, Wofi CSS |

**Config scripts** (`type: config`) show a "Run" action in the menu rather than Install/Uninstall. They do not track installation state and do not require root.

**No overlap with postsetup-kali:** The existing `catppuccin-themes` in `postsetup-kali/` targets XFCE, GTK, ZSH prompt, and VS Code. These scripts target KDE Plasma, GPU terminals, Neovim, tmux, and Hyprland.

## File Paths Written by Theming Scripts

| Script | Files created |
|--------|--------------|
| catppuccin-kde | `~/.local/share/color-schemes/CatppuccinMocha*`, `~/.config/Kvantum/*Mocha*` |
| catppuccin-terminals | `~/.config/kitty/catppuccin-mocha.conf`, `~/.config/wezterm/colors/catppuccin-mocha.toml`, `~/.config/alacritty/catppuccin-mocha.toml` |
| catppuccin-neovim | `~/.config/nvim/lua/plugins/catppuccin.lua` |
| catppuccin-tmux | `~/.tmux/plugins/tpm/` (if missing), appends to `~/.tmux.conf` |
| catppuccin-hyprland | `~/.config/hypr/catppuccin-mocha.conf`, `~/.config/waybar/catppuccin-mocha.css`, `~/.config/wofi/catppuccin-mocha.css` |

## Development

### Adding a new terminal or dev tool

1. Create `<tool>.sh` + `<tool>.meta.yaml` in the appropriate subfolder
2. Follow the Tier 2 pattern: `pkg_install` for apt packages, or download from GitHub for binary releases
3. Set `check_command` and `check_path` for installation detection
4. Update the folder README.md

### Adding a new theming target

1. Create `catppuccin-<target>.sh` + `catppuccin-<target>.meta.yaml` in `theming/`
2. Use `type: config` and `root: false`
3. Write color config files to `~/.config/<target>/`
4. Only configure if the target tool is installed (`command -v`)

## See Also

- [User Guide](../user_manuals/toolsets.md)
- [Contributing Guide](../../mainmenu/CONTRIBUTING.md)
