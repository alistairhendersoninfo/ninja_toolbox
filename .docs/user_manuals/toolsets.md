# Toolsets - User Guide

## Overview

The Toolsets category provides GPU-accelerated terminal emulators, essential CLI developer tools, and a unified Catppuccin Mocha theming suite. Install the tools first, then apply consistent theming across all of them.

## Terminal Emulators

### kitty

GPU-accelerated terminal with image display and ligature support.

```bash
kitty                    # Launch kitty
kitty +kitten icat image.png  # Display image inline
```

### WezTerm

GPU-accelerated terminal with a built-in multiplexer and Lua configuration.

```bash
wezterm                  # Launch WezTerm
wezterm cli split-pane   # Split the current pane
```

Configuration lives in `~/.config/wezterm/wezterm.lua`.

### Alacritty

Minimal, GPU-accelerated terminal focused on speed. No tabs or splits -- pair with tmux.

```bash
alacritty                # Launch Alacritty
```

Configuration lives in `~/.config/alacritty/alacritty.toml`.

## Developer Tools

### Neovim

Hyperextensible text editor built on Vim. Supports Lua plugins and LSP natively.

```bash
nvim file.py             # Edit a file
nvim +checkhealth        # Verify installation health
```

### tmux

Terminal multiplexer for persistent sessions with splits and tabs.

```bash
tmux                     # Start new session
tmux new -s dev          # Named session
tmux attach -t dev       # Reattach
```

Key bindings (default prefix: `Ctrl-b`):
- `prefix + %` -- vertical split
- `prefix + "` -- horizontal split
- `prefix + d` -- detach

### ripgrep (rg)

Fast recursive search, respects `.gitignore` by default.

```bash
rg "TODO"                # Search current directory
rg -t py "def main"      # Search only Python files
rg -i "error" --glob "*.log"  # Case-insensitive in logs
```

### fd

Fast file finder, alternative to `find`.

```bash
fd "\.py$"               # Find Python files
fd -t d "src"            # Find directories named src
fd -e json               # Find by extension
```

### fzf

Interactive fuzzy finder. Pipe anything into it.

```bash
fzf                      # Browse files interactively
history | fzf            # Search shell history
fd | fzf --preview 'bat {}'  # Preview files with bat
```

### bat

`cat` replacement with syntax highlighting and line numbers.

```bash
bat script.sh            # View with syntax highlighting
bat --diff file.txt      # Show git diff
bat -l yaml config.yml   # Force language
```

### lazygit

Terminal UI for Git. Navigate commits, branches, and diffs visually.

```bash
lazygit                  # Launch in current repo
```

## Catppuccin Theming

The theming scripts apply the Catppuccin Mocha color palette consistently across your desktop and tools. They do not overlap with the XFCE/GTK themes in postsetup-kali -- these target KDE, terminals, Neovim, tmux, and Hyprland.

### Recommended order

1. Install terminals and dev tools first
2. Run **Catppuccin KDE** (if using KDE Plasma)
3. Run **Catppuccin Terminals** to theme whichever terminals you installed
4. Run **Catppuccin Neovim** to add the colorscheme plugin
5. Run **Catppuccin tmux** to configure TPM with the theme
6. Run **Catppuccin Hyprland** (if using Hyprland compositor)

### Tips

- Terminal theme scripts only configure terminals that are already installed
- The Neovim script auto-detects lazy.nvim or packer and writes the correct plugin spec
- The tmux script installs TPM (tmux plugin manager) if missing; press `prefix + I` to activate
- Hyprland colors are sourced via `source =` directive -- reload with `hyprctl reload`

## Troubleshooting

### fd and bat have different binary names

On Debian/Ubuntu, `fd` is installed as `fdfind` and `bat` as `batcat` to avoid name conflicts. The install scripts create symlinks at `/usr/local/bin/fd` and `/usr/local/bin/bat` automatically.

### lazygit version

lazygit is installed from the latest GitHub release binary. To update, simply re-run the install script.

### Terminal colors look wrong

Ensure your terminal supports true color (24-bit). Check with:

```bash
echo -e "\e[38;2;255;100;0mTrueColor test\e[0m"
```

If the text appears orange, true color is supported.
