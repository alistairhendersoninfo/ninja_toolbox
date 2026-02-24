#!/usr/bin/env python3
"""
Kali Menu Installer - Dynamic TUI Menu System
NinjaMenu - Generates menus from folder structure with YAML header parsing.
"""

import os
import sys
import re
import signal
import shutil
import subprocess
import argparse
import platform
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from datetime import datetime

from cache import (
    rebuild_cache, get_menu_items, is_cache_stale,
    update_installed, get_script,
)

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

try:
    from textual.app import App, ComposeResult
    from textual.containers import Container, Vertical, Horizontal, VerticalScroll
    from textual.widgets import Header, Footer, Static, Button, ListItem, ListView, Label, OptionList
    from textual.widgets.option_list import Option
    from textual.binding import Binding
    from textual.screen import Screen
    from textual import events
    HAS_TEXTUAL = True
except ImportError:
    HAS_TEXTUAL = False

# Constants
APP_DIR = Path(__file__).parent.resolve()
MENU_ROOT = APP_DIR.parent  # Parent of .app directory
MAIN_MENU_DIR = MENU_ROOT / "mainmenu"
LOG_DIR = MENU_ROOT / ".docs" / "logs"
CONFIG_DIR = MENU_ROOT / ".configs"
SETTINGS_FILE = CONFIG_DIR / "menusystem" / "settings.conf"
SETTINGS_DEFAULT_FILE = CONFIG_DIR / "menusystem" / "settings.default.conf"
GUM_DEFAULT_FILE = CONFIG_DIR / "menusystem" / "gum.default.conf"
TEXTUAL_DEFAULT_FILE = CONFIG_DIR / "menusystem" / "textual.default.conf"
WHIPTAIL_DEFAULT_FILE = CONFIG_DIR / "menusystem" / "whiptail.default.conf"
CACHE_DIR = MENU_ROOT / ".cache"
DB_PATH = CACHE_DIR / "menu.db"


def get_config_settings() -> Dict[str, str]:
    """Read all settings from config file."""
    settings = {}
    if SETTINGS_FILE.exists():
        try:
            with open(SETTINGS_FILE, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        settings[key.strip()] = value.strip()
        except:
            pass
    return settings


def save_config_settings(updates: Dict[str, str]) -> None:
    """Write updated settings back to config file, preserving comments."""
    lines = []
    seen_keys = set()
    if SETTINGS_FILE.exists():
        with open(SETTINGS_FILE, 'r') as f:
            lines = f.readlines()

    new_lines = []
    for line in lines:
        stripped = line.strip()
        if stripped and not stripped.startswith('#') and '=' in stripped:
            key = stripped.split('=', 1)[0].strip()
            if key in updates:
                new_lines.append(f"{key}={updates[key]}\n")
                seen_keys.add(key)
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)

    # Append any new keys not already in file
    for key, value in updates.items():
        if key not in seen_keys:
            new_lines.append(f"{key}={value}\n")

    tmp_path = SETTINGS_FILE.parent / "settings.conf.tmp"
    with open(tmp_path, 'w') as f:
        f.writelines(new_lines)
    os.replace(tmp_path, SETTINGS_FILE)


def reset_settings_to_defaults() -> None:
    """Reset settings.conf to factory defaults."""
    if SETTINGS_DEFAULT_FILE.exists():
        shutil.copy2(SETTINGS_DEFAULT_FILE, SETTINGS_FILE)


def reset_backend_settings(backend: str) -> None:
    """Reset only a specific backend's settings to factory defaults.

    Reads the backend-specific default file (e.g. gum.default.conf) and
    overwrites matching keys in settings.conf while leaving other keys intact.
    """
    default_files = {
        "gum": GUM_DEFAULT_FILE,
        "textual": TEXTUAL_DEFAULT_FILE,
        "whiptail": WHIPTAIL_DEFAULT_FILE,
    }
    default_path = default_files.get(backend)
    if not default_path or not default_path.exists():
        return

    # Parse the backend default file for key=value pairs
    defaults = {}
    with open(default_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                defaults[key.strip()] = value.strip()

    if defaults:
        save_config_settings(defaults)


def _check_venv_package(package: str) -> bool:
    """Check if a Python package is installed in the project venv."""
    venv_python = MENU_ROOT / ".venv" / "bin" / "python3"
    if not venv_python.exists():
        return False
    try:
        result = subprocess.run(
            [str(venv_python), "-c", f"import {package}"],
            capture_output=True, timeout=5
        )
        return result.returncode == 0
    except Exception:
        return False


def _check_backend_available(backend: str) -> bool:
    """Check if a TUI backend is currently available."""
    if backend == "gum":
        return gum_available()
    elif backend == "textual":
        if HAS_TEXTUAL:
            return True
        # Textual may be installed in the venv but not importable in
        # the current process (e.g. running without venv activated)
        return _check_venv_package("textual")
    elif backend == "whiptail":
        return shutil.which("whiptail") is not None
    return False


def install_backend(backend: str) -> bool:
    """Install a TUI backend on demand. Returns True on success."""
    global HAS_TEXTUAL

    os_type = CURRENT_OS
    venv_dir = MENU_ROOT / ".venv"

    if backend == "gum":
        if os_type == "macos":
            cmd = ["brew", "install", "gum"]
        else:
            # Linux: needs charm repo first
            print("Adding Charm repository...")
            setup_cmds = [
                "sudo mkdir -p /etc/apt/keyrings",
                "curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg",
                'echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list',
                "sudo apt-get update -qq",
            ]
            for c in setup_cmds:
                if subprocess.run(c, shell=True).returncode != 0:
                    print(f"Failed: {c}")
                    return False
            cmd = ["sudo", "apt-get", "install", "-y", "gum"]

    elif backend == "textual":
        # Install into the project venv
        if not venv_dir.exists():
            print("Creating virtual environment...")
            subprocess.run([sys.executable, "-m", "venv", str(venv_dir)])

        pip_bin = venv_dir / "bin" / "pip"
        if not pip_bin.exists():
            print("Error: venv pip not found")
            return False
        cmd = [str(pip_bin), "install", "textual"]

    elif backend == "whiptail":
        if os_type == "macos":
            cmd = ["brew", "install", "newt"]
        else:
            cmd = ["sudo", "apt-get", "install", "-y", "whiptail"]

    else:
        return False

    print(f"Installing {backend}...")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"Installation failed (exit code {result.returncode})")
        return False

    # Re-check availability
    if backend == "textual":
        # Try to import textual now
        try:
            import importlib
            importlib.import_module("textual")
            HAS_TEXTUAL = True
        except ImportError:
            return False

    # Verify the backend is actually available now
    if _check_backend_available(backend):
        print(f"{backend} installed successfully!")
        return True

    print(f"Installation completed but {backend} still not detected")
    return False


def get_config_backend() -> str:
    """Read backend preference from config file."""
    settings = get_config_settings()
    return settings.get('backend', 'gum')


def get_gum_style_args() -> List[str]:
    """Build gum filter style arguments from config.
    Note: gum filter doesn't support --border, only gum style does.
    """
    settings = get_config_settings()
    args = []

    # Colors (gum filter supports these)
    if settings.get('gum.header_foreground'):
        args.extend(['--header.foreground', settings['gum.header_foreground']])
    if settings.get('gum.match_foreground'):
        args.extend(['--match.foreground', settings['gum.match_foreground']])
    if settings.get('gum.cursor_foreground'):
        args.extend(['--cursor-text.foreground', settings['gum.cursor_foreground']])
    if settings.get('gum.prompt_foreground'):
        args.extend(['--prompt.foreground', settings['gum.prompt_foreground']])

    # Dimensions
    if settings.get('gum.height'):
        args.extend(['--height', settings['gum.height']])
    if settings.get('gum.width'):
        args.extend(['--width', settings['gum.width']])

    # Indicators
    if settings.get('gum.cursor'):
        args.extend(['--indicator', settings['gum.cursor']])
    if settings.get('gum.selected_prefix'):
        args.extend(['--selected-prefix', f" {settings['gum.selected_prefix']} "])
    if settings.get('gum.unselected_prefix'):
        args.extend(['--unselected-prefix', f" {settings['gum.unselected_prefix']} "])

    return args


def get_layout_params(settings: Dict[str, str] = None) -> Dict[str, int]:
    """Calculate centering layout params based on terminal width.

    Returns dict with content_width, left_margin, and terminal_cols.
    Re-reads terminal size each call so resize is picked up on redraw.
    """
    if settings is None:
        settings = get_config_settings()
    max_width = int(settings.get('layout.max_width', '80'))
    alignment = settings.get('layout.alignment', 'center')
    terminal_cols = shutil.get_terminal_size().columns
    content_width = min(max_width, terminal_cols - 4)
    if alignment == 'left':
        left_margin = 0
        content_width = min(max_width, terminal_cols)
    else:
        left_margin = max(0, (terminal_cols - content_width) // 2)
    return {
        'content_width': content_width,
        'left_margin': left_margin,
        'terminal_cols': terminal_cols,
    }


class TerminalResized(Exception):
    """Raised when the terminal is resized during a gum subprocess."""
    pass


class _sigwinch_guard:
    """Context manager that kills a subprocess on terminal resize.

    Sets a SIGWINCH handler that terminates the tracked process and raises
    TerminalResized so the calling loop can clear + redraw.
    """

    def __init__(self):
        self.proc: subprocess.Popen = None
        self._old_handler = None

    def track(self, proc: subprocess.Popen):
        """Register a running Popen process to kill on resize."""
        self.proc = proc

    def __enter__(self):
        def _on_resize(signum, frame):
            if self.proc and self.proc.poll() is None:
                self.proc.terminate()
            raise TerminalResized()

        self._old_handler = signal.getsignal(signal.SIGWINCH)
        signal.signal(signal.SIGWINCH, _on_resize)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        signal.signal(signal.SIGWINCH, self._old_handler or signal.SIG_DFL)
        return False  # Let TerminalResized propagate to the caller


def check_if_installed(info: 'ScriptInfo') -> bool:
    """Check if software is actually installed on the system."""
    # Check by command
    if info.check_command:
        try:
            # Include common user paths that might not be in subprocess PATH
            env = os.environ.copy()
            home = os.path.expanduser("~")
            extra_paths = [
                f"{home}/.local/bin",
                f"{home}/.cargo/bin",
                f"{home}/.npm-global/bin",
                "/usr/local/bin",
                "/opt/homebrew/bin",
            ]
            env["PATH"] = ":".join(extra_paths) + ":" + env.get("PATH", "")

            result = subprocess.run(
                info.check_command,
                shell=True,
                capture_output=True,
                timeout=5,
                env=env
            )
            if result.returncode == 0:
                return True
        except:
            pass

    # Check by path
    if info.check_path:
        check_paths = info.check_path.split(':')  # Support multiple paths with :
        for p in check_paths:
            expanded = os.path.expanduser(p.strip())
            if os.path.exists(expanded):
                return True

    # Fall back to YAML header value if no check defined
    if not info.check_command and not info.check_path:
        return info.installed

    return False


def _check_binary_available(binary: str) -> bool:
    """Check if a required binary is available on PATH."""
    home = os.path.expanduser("~")
    extra_paths = [
        f"{home}/.local/bin",
        f"{home}/.cargo/bin",
        f"{home}/.npm-global/bin",
        "/usr/local/bin",
        "/opt/homebrew/bin",
    ]
    extended_path = ":".join(extra_paths) + ":" + os.environ.get("PATH", "")
    return shutil.which(binary, path=extended_path) is not None


def _detect_os() -> tuple:
    """Detect current OS and distro, matching platform.sh conventions."""
    system = platform.system()
    if system == "Darwin":
        return ("macos", "macos")
    elif system == "Linux":
        distro = "unknown"
        try:
            with open("/etc/os-release") as f:
                for line in f:
                    if line.startswith("ID="):
                        distro = line.strip().split("=", 1)[1].strip('"')
                        break
        except FileNotFoundError:
            pass
        return ("linux", distro)
    elif system == "Windows":
        return ("windows", "windows")
    return ("unknown", "unknown")


CURRENT_OS, CURRENT_DISTRO = _detect_os()


@dataclass
class ScriptInfo:
    """Parsed script information from YAML header."""
    path: Path
    name: str = "Unnamed Script"
    description: str = "No description"
    version: str = "1.0.0"
    author: str = "Unknown"
    root: bool = False
    order: int = 50
    hidden: bool = False
    installed: bool = False
    uninstall: str = ""
    dependencies: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)
    check_command: str = ""  # Command to check if installed (e.g., "claude --version")
    check_path: str = ""     # Path to check if exists (e.g., "/usr/bin/claude")
    script_type: str = "install"  # "install" = Install/Uninstall, "config" = Run only, "tool" = Run with binary check
    binary: str = ""         # Required binary command for tool scripts (e.g., "nmap")
    binary_available: bool = True  # Set at runtime after checking binary exists
    supported_os: List[str] = field(default_factory=list)  # e.g. ["macos", "kali", "debian", "ubuntu"]
    is_modular_folder: bool = False  # True if script lives in a Tier 1 modular folder
    aliases: List[str] = field(default_factory=list)  # Cross-reference paths relative to mainmenu/


@dataclass
class MenuItem:
    """Menu item (script or submenu)."""
    name: str
    path: Path
    is_submenu: bool = False
    script_info: Optional[ScriptInfo] = None
    order: int = 50
    description: str = ""


def parse_yaml_header(script_path: Path) -> Optional[ScriptInfo]:
    """Parse YAML header from a shell script."""
    if not HAS_YAML:
        return None
    try:
        content = script_path.read_text()

        # Match YAML block between # --- markers
        pattern = r'^#\s*---\s*\n((?:#.*\n)*?)#\s*---'
        match = re.search(pattern, content, re.MULTILINE)

        if not match:
            return None

        # Extract YAML content, removing # prefix from each line
        yaml_lines = match.group(1).split('\n')
        yaml_content = '\n'.join(
            line[1:].strip() if line.startswith('#') else line
            for line in yaml_lines
        )

        data = yaml.safe_load(yaml_content)
        if not data:
            return None

        info = ScriptInfo(
            path=script_path,
            name=data.get('name', script_path.stem),
            description=data.get('description', 'No description'),
            version=data.get('version', '1.0.0'),
            author=data.get('author', 'Unknown'),
            root=data.get('root', False),
            order=data.get('order', 50),
            hidden=data.get('hidden', False),
            installed=data.get('installed', False),
            uninstall=data.get('uninstall', ''),
            dependencies=data.get('dependencies', []),
            tags=data.get('tags', []),
            check_command=data.get('check_command', ''),
            check_path=data.get('check_path', ''),
            script_type=data.get('type', 'install'),  # "install", "config", or "tool"
            binary=data.get('binary', ''),
        )
        # Dynamically check if installed
        info.installed = check_if_installed(info)
        # Check if required binary is available (for tool scripts)
        if info.binary:
            info.binary_available = _check_binary_available(info.binary)
        return info
    except Exception as e:
        print(f"Error parsing {script_path}: {e}", file=sys.stderr)
        return None


def parse_meta_yaml(meta_path: Path, script_path: Path) -> Optional[ScriptInfo]:
    """Parse a standalone meta.yaml or .meta.yaml file."""
    if not HAS_YAML or not meta_path.exists():
        return None
    try:
        data = yaml.safe_load(meta_path.read_text())
        if not data:
            return None

        info = ScriptInfo(
            path=script_path,
            name=data.get('name', script_path.stem),
            description=data.get('description', 'No description'),
            version=data.get('version', '1.0.0'),
            author=data.get('author', 'Unknown'),
            root=data.get('root', False),
            order=data.get('order', 50),
            hidden=data.get('hidden', False),
            installed=data.get('installed', False),
            uninstall=data.get('uninstall', ''),
            dependencies=data.get('dependencies', []),
            tags=data.get('tags', []),
            check_command=data.get('check_command', ''),
            check_path=data.get('check_path', ''),
            script_type=data.get('type', 'install'),
            binary=data.get('binary', ''),
            supported_os=data.get('supported_os', []),
            aliases=data.get('aliases', []),
        )
        info.installed = check_if_installed(info)
        if info.binary:
            info.binary_available = _check_binary_available(info.binary)
        return info
    except Exception as e:
        print(f"Error parsing {meta_path}: {e}", file=sys.stderr)
        return None


def _resolve_modular_script(folder: Path) -> Optional[Path]:
    """Resolve a Tier 1 modular folder to the correct OS-specific script.

    Checks for exact distro match first (e.g. kali.sh), then falls back
    to generic linux.sh, then _common.sh as last resort.
    """
    # Try exact distro match: kali.sh, ubuntu.sh, debian.sh, macos.sh
    distro_script = folder / f"{CURRENT_DISTRO}.sh"
    if distro_script.exists():
        return distro_script

    # Try distro variants with version: ubuntu-22.04.sh, kali-linux.sh
    for f in folder.iterdir():
        if f.suffix == '.sh' and not f.name.startswith('_'):
            stem = f.stem.replace('-', ' ').replace('_', ' ').split()[0]
            if stem == CURRENT_DISTRO:
                return f

    # Try generic OS match: linux.sh, macos.sh
    os_script = folder / f"{CURRENT_OS}.sh"
    if os_script.exists():
        return os_script

    # Windows: try .ps1 extension
    if CURRENT_OS == "windows":
        ps1_script = folder / "windows.ps1"
        if ps1_script.exists():
            return ps1_script

    # No match found for this OS
    return None


def _is_modular_folder(directory: Path) -> bool:
    """Check if a directory is a Tier 1 modular script folder (has meta.yaml)."""
    return (directory / "meta.yaml").exists()


def _ensure_cache() -> None:
    """Ensure the SQLite cache exists and is up to date."""
    if not DB_PATH.exists() or is_cache_stale(MAIN_MENU_DIR, DB_PATH):
        rebuild_cache(MAIN_MENU_DIR, DB_PATH)


def _dict_to_script_info(d: Dict[str, Any]) -> ScriptInfo:
    """Convert a cache dict to a ScriptInfo dataclass."""
    # Resolve the actual filesystem path for the script
    script_file = d.get('script_file', d.get('path', ''))
    script_path = MAIN_MENU_DIR / script_file if script_file else MAIN_MENU_DIR / d['path']

    info = ScriptInfo(
        path=script_path,
        name=d.get('name', 'Unnamed'),
        description=d.get('description', 'No description'),
        version=d.get('version', '1.0.0'),
        author=d.get('author', 'Unknown'),
        root=d.get('root', False),
        order=d.get('order', 50),
        hidden=d.get('hidden', False),
        installed=d.get('installed', False),
        uninstall=d.get('uninstall', ''),
        dependencies=d.get('dependencies', []),
        tags=d.get('tags', []),
        check_command=d.get('check_command', ''),
        check_path=d.get('check_path', ''),
        script_type=d.get('script_type', 'install'),
        binary=d.get('binary', ''),
        binary_available=d.get('binary_available', True),
        supported_os=d.get('supported_os', []),
        is_modular_folder=d.get('is_modular_folder', False),
        aliases=d.get('aliases', []),
    )
    # Check binary availability at runtime for tool scripts
    if info.binary:
        info.binary_available = _check_binary_available(info.binary)
    return info


def scan_menu_directory(directory: Path) -> List[MenuItem]:
    """Get menu items from SQLite cache for the given directory.

    Replaces the old filesystem-scanning version. Now queries the cache
    which was pre-built from YAML metadata files.
    """
    _ensure_cache()

    # Compute parent_menu key relative to mainmenu/
    try:
        rel_dir = directory.relative_to(MAIN_MENU_DIR)
        parent_menu = str(rel_dir) if str(rel_dir) != "." else ""
    except ValueError:
        parent_menu = ""

    cached_items = get_menu_items(DB_PATH, parent_menu, CURRENT_OS, CURRENT_DISTRO)
    items = []

    for d in cached_items:
        if d.get('is_submenu'):
            items.append(MenuItem(
                name=d['name'],
                path=MAIN_MENU_DIR / d['path'],
                is_submenu=True,
                order=0,
                description=d.get('description', ''),
            ))
        else:
            script_info = _dict_to_script_info(d)
            items.append(MenuItem(
                name=script_info.name,
                path=script_info.path,
                is_submenu=False,
                script_info=script_info,
                order=script_info.order,
            ))

    return items


def _reparse_script_info(script_info: ScriptInfo) -> Optional[ScriptInfo]:
    """Re-parse a script's metadata after install/uninstall.

    Handles all three tiers: modular folder meta.yaml, sibling .meta.yaml,
    and legacy inline YAML headers. Also updates the SQLite cache.
    """
    path = script_info.path

    # Tier 1: modular folder — re-read the folder's meta.yaml
    if script_info.is_modular_folder:
        meta_path = path.parent / "meta.yaml"
        if meta_path.exists():
            updated = parse_meta_yaml(meta_path, path)
            if updated and DB_PATH.exists():
                try:
                    rel_path = str(path.parent.relative_to(MAIN_MENU_DIR))
                    update_installed(DB_PATH, rel_path, updated.installed)
                except ValueError:
                    pass
            return updated

    # Tier 2/3: sibling .meta.yaml
    sibling_meta = path.parent / f"{path.stem}.meta.yaml"
    if sibling_meta.exists():
        updated = parse_meta_yaml(sibling_meta, path)
        if updated and DB_PATH.exists():
            try:
                rel_path = str(path.relative_to(MAIN_MENU_DIR))
                update_installed(DB_PATH, rel_path, updated.installed)
            except ValueError:
                pass
        return updated

    # Legacy: inline YAML header
    return parse_yaml_header(path)


def run_script(script_info: ScriptInfo, action: str = "install") -> int:
    """Run a script with proper handling."""
    script_path = script_info.path

    # Build command
    # On macOS, install scripts handle their own privilege checks via require_root
    # (Homebrew refuses to run under sudo). But tool scripts need sudo on macOS
    # too — raw socket operations (nmap -sS, -f, etc.) require root everywhere.
    cmd = []
    if script_info.root:
        if script_info.script_type == "tool" or platform.system() != "Darwin":
            cmd = ["sudo"]
    cmd.extend(["bash", str(script_path), action])

    print(f"\n{'='*50}")
    print(f"Running: {script_info.name}")
    print(f"Action: {action}")
    print(f"Script: {script_path}")
    print(f"{'='*50}\n")

    try:
        result = subprocess.run(cmd, cwd=str(script_path.parent))
        return result.returncode
    except KeyboardInterrupt:
        print("\n\nScript interrupted by user")
        return 130
    except Exception as e:
        print(f"\nError running script: {e}")
        return 1


def view_log(script_name: str):
    """View the most recent log for a script."""
    log_pattern = f"{script_name}_*.log"
    logs = sorted(LOG_DIR.glob(log_pattern), reverse=True)

    if not logs:
        print(f"No logs found for {script_name}")
        return

    latest_log = logs[0]
    print(f"\n{'='*50}")
    print(f"Log: {latest_log.name}")
    print(f"{'='*50}\n")

    try:
        subprocess.run(["less", "-R", str(latest_log)])
    except:
        print(latest_log.read_text())


# ============================================
# GUM-BASED MENU (Modern, Beautiful)
# ============================================

def gum_available() -> bool:
    """Check if gum is available and can access TTY."""
    try:
        # Check if gum exists
        result = subprocess.run(["gum", "--version"], capture_output=True, check=True)
        # Check if we have a TTY
        if not sys.stdin.isatty():
            return False
        # Try a simple gum command to verify TTY access
        test = subprocess.run(
            ["gum", "style", "test"],
            capture_output=True,
            timeout=2
        )
        return test.returncode == 0
    except:
        return False


# ============================================
# SETTINGS MENUS
# ============================================

# Color theme presets: name -> (header_fg, match_fg, cursor_fg)
_COLOR_PRESETS = {
    "purple": ("99", "212", "212"),
    "cyan": ("39", "51", "51"),
    "green": ("40", "82", "82"),
    "pink": ("212", "219", "219"),
}

# Textual built-in themes (from textual 7.x)
_TEXTUAL_THEMES = [
    "textual-dark",
    "textual-light",
    "textual-ansi",
    "nord",
    "gruvbox",
    "tokyo-night",
    "monokai",
    "dracula",
    "catppuccin-mocha",
    "catppuccin-latte",
    "solarized-dark",
    "solarized-light",
    "atom-one-dark",
    "atom-one-light",
    "flexoki",
    "rose-pine",
    "rose-pine-dawn",
    "rose-pine-moon",
]


def _gum_choose_with_active(options: List[str], active: str,
                            unavailable: List[str] = None) -> Optional[str]:
    """Run gum choose with a * marker on the active option.

    Options in the unavailable list are shown greyed out with (not installed).
    Returns the chosen value (without markers), or None on cancel/unavailable.
    """
    if unavailable is None:
        unavailable = []
    display = []
    for opt in options:
        if opt in unavailable:
            display.append(f"  {opt}  (not installed)")
        elif opt == active:
            display.append(f"* {opt}")
        else:
            display.append(f"  {opt}")
    r = subprocess.Popen(
        ["gum", "choose"] + display,
        stdout=subprocess.PIPE, text=True
    )
    out, _ = r.communicate()
    if r.returncode != 0 or not out.strip():
        return None
    chosen = out.strip()
    # Reject unavailable selections
    if "(not installed)" in chosen:
        return None
    # Strip the marker prefix
    return chosen.lstrip("* ").strip()


def _gum_header(title: str, subtitle: str, settings: Dict[str, str] = None) -> None:
    """Display a styled gum header box."""
    if settings is None:
        settings = get_config_settings()
    layout = get_layout_params(settings)
    margin_str = f"0 {layout['left_margin']}"
    border = settings.get('gum.border', 'rounded')
    border_fg = settings.get('gum.border_foreground', '99')
    os.system('clear')
    subprocess.run([
        "gum", "style",
        "--border", border,
        "--border-foreground", border_fg,
        "--padding", "1 2",
        "--margin", margin_str,
        "--width", str(layout['content_width']),
        title, subtitle
    ])


def _gum_select(choices: List[str], settings: Dict[str, str] = None,
                placeholder: str = "Select setting to change...") -> Optional[str]:
    """Run gum filter with padded choices, return stripped selection or None."""
    if settings is None:
        settings = get_config_settings()
    layout = get_layout_params(settings)
    pad = " " * layout['left_margin']
    padded = [f"{pad}{c}" for c in choices]
    proc = subprocess.Popen(
        ["gum", "filter", "--height", "15", "--placeholder", placeholder]
        + padded,
        stdout=subprocess.PIPE, text=True
    )
    stdout, _ = proc.communicate()
    if proc.returncode != 0:
        return None
    return stdout.strip().lstrip() if stdout else None


def _gum_offer_install(backend: str) -> bool:
    """Prompt user to install a missing backend via gum confirm."""
    r = subprocess.run(
        ["gum", "confirm", f"Install {backend}?"]
    )
    if r.returncode != 0:
        return False
    success = install_backend(backend)
    if not success:
        input("\nPress Enter to continue...")
    return success


# ── Gum backend submenus ──────────────────────────────────

def _gum_configure_gum(settings: Dict[str, str]) -> None:
    """Gum-specific settings submenu (border, colors, reset)."""
    while True:
        settings = get_config_settings()
        current_border = settings.get('gum.border', 'rounded')
        current_theme = "custom"
        for name, (h, m, c) in _COLOR_PRESETS.items():
            if (settings.get('gum.header_foreground') == h and
                    settings.get('gum.match_foreground') == m and
                    settings.get('gum.cursor_foreground') == c):
                current_theme = name
                break

        _gum_header("Gum Settings", "Configure the Gum backend", settings)

        choices = [
            f"1.   Border Style         [{current_border}]",
            f"2.   Color Theme          [{current_theme}]",
            "─" * 30,
            "3. Reset Gum to Defaults",
            "b. Back",
        ]

        try:
            sel = _gum_select(choices, settings)
            if not sel or sel.startswith("b.") or sel.startswith("─"):
                return

            if sel.startswith("1."):
                val = _gum_choose_with_active(
                    ["none", "normal", "rounded", "double", "thick"],
                    current_border)
                if val:
                    save_config_settings({'gum.border': val})

            elif sel.startswith("2."):
                preset_choices = list(_COLOR_PRESETS.keys()) + ["custom"]
                val = _gum_choose_with_active(preset_choices, current_theme)
                if val:
                    if val in _COLOR_PRESETS:
                        h, m, c = _COLOR_PRESETS[val]
                        save_config_settings({
                            'gum.header_foreground': h,
                            'gum.match_foreground': m,
                            'gum.cursor_foreground': c,
                        })
                    elif val == "custom":
                        r2 = subprocess.Popen(
                            ["gum", "input", "--placeholder",
                             "Enter 256-color code for header (e.g. 39)"],
                            stdout=subprocess.PIPE, text=True
                        )
                        out2, _ = r2.communicate()
                        if r2.returncode == 0 and out2.strip():
                            code = out2.strip()
                            save_config_settings({
                                'gum.header_foreground': code,
                                'gum.match_foreground': code,
                                'gum.cursor_foreground': code,
                            })

            elif sel.startswith("3."):
                r = subprocess.run(
                    ["gum", "confirm", "Reset Gum settings to defaults?"]
                )
                if r.returncode == 0:
                    reset_backend_settings("gum")

        except KeyboardInterrupt:
            return


def _gum_configure_whiptail(settings: Dict[str, str]) -> None:
    """Whiptail-specific settings submenu (theme, reset)."""
    while True:
        settings = get_config_settings()
        current_wt = settings.get('whiptail.theme', 'default')

        _gum_header("Whiptail Settings", "Configure the Whiptail backend", settings)

        choices = [
            f"1.   Theme                [{current_wt}]",
            "─" * 30,
            "2. Reset Whiptail to Defaults",
            "b. Back",
        ]

        try:
            sel = _gum_select(choices, settings)
            if not sel or sel.startswith("b.") or sel.startswith("─"):
                return

            if sel.startswith("1."):
                val = _gum_choose_with_active(
                    ["default", "green", "blue", "red"], current_wt)
                if val:
                    save_config_settings({'whiptail.theme': val})

            elif sel.startswith("2."):
                r = subprocess.run(
                    ["gum", "confirm", "Reset Whiptail settings to defaults?"]
                )
                if r.returncode == 0:
                    reset_backend_settings("whiptail")

        except KeyboardInterrupt:
            return


def _gum_configure_textual(settings: Dict[str, str]) -> None:
    """Textual-specific settings submenu (theme selection, reset)."""
    while True:
        settings = get_config_settings()
        current_theme = settings.get('textual.theme', 'textual-dark')

        _gum_header("Textual Settings", "Configure the Textual backend", settings)

        choices = [
            f"1.   Theme                [{current_theme}]",
            "─" * 30,
            "2. Reset Textual to Defaults",
            "b. Back",
        ]

        try:
            sel = _gum_select(choices, settings)
            if not sel or sel.startswith("b.") or sel.startswith("─"):
                return

            if sel.startswith("1."):
                val = _gum_choose_with_active(_TEXTUAL_THEMES, current_theme)
                if val:
                    save_config_settings({'textual.theme': val})

            elif sel.startswith("2."):
                r = subprocess.run(
                    ["gum", "confirm", "Reset Textual settings to defaults?"]
                )
                if r.returncode == 0:
                    reset_backend_settings("textual")

        except KeyboardInterrupt:
            return


def gum_settings_menu() -> None:
    """Interactive settings editor using gum — hierarchical with backend submenus."""
    settings = get_config_settings()

    while True:
        settings = get_config_settings()

        current_backend = settings.get('backend', 'gum')
        current_align = settings.get('layout.alignment', 'center')
        current_width = settings.get('layout.max_width', '80')

        # Backend availability
        gum_avail = _check_backend_available("gum")
        textual_avail = _check_backend_available("textual")
        whiptail_avail = _check_backend_available("whiptail")

        gum_status = "installed" if gum_avail else "not installed"
        textual_status = "installed" if textual_avail else "not installed"
        whiptail_status = "installed" if whiptail_avail else "not installed"

        _gum_header("Settings", "Change menu appearance and behaviour", settings)

        choices = [
            f"1. * Active Backend       [{current_backend}]",
            "─── Backends ───",
            f"2.   Gum                  [{gum_status}]",
            f"3.   Textual              [{textual_status}]",
            f"4.   Whiptail             [{whiptail_status}]",
            "─── Layout ───",
            f"5.   Alignment            [{current_align}]",
            f"6.   Max Width            [{current_width}]",
            "─" * 30,
            "7. Reset All to Defaults",
            "b. Back",
        ]

        try:
            sel = _gum_select(choices, settings)
            if not sel or sel.startswith("b.") or sel.startswith("─"):
                return

            if sel.startswith("1."):
                # Only show installed backends for active selection
                installed = [b for b in ("gum", "textual", "whiptail")
                             if _check_backend_available(b)]
                if installed:
                    val = _gum_choose_with_active(installed, current_backend)
                    if val:
                        save_config_settings({'backend': val})

            elif sel.startswith("2."):
                if gum_avail:
                    _gum_configure_gum(settings)
                else:
                    if _gum_offer_install("gum"):
                        _gum_configure_gum(settings)

            elif sel.startswith("3."):
                if textual_avail:
                    _gum_configure_textual(settings)
                else:
                    if _gum_offer_install("textual"):
                        _gum_configure_textual(settings)

            elif sel.startswith("4."):
                if whiptail_avail:
                    _gum_configure_whiptail(settings)
                else:
                    if _gum_offer_install("whiptail"):
                        _gum_configure_whiptail(settings)

            elif sel.startswith("5."):
                val = _gum_choose_with_active(
                    ["center", "left"], current_align)
                if val:
                    save_config_settings({'layout.alignment': val})

            elif sel.startswith("6."):
                r = subprocess.Popen(
                    ["gum", "input", "--placeholder", "Enter width (40-200)",
                     "--value", current_width],
                    stdout=subprocess.PIPE, text=True
                )
                out, _ = r.communicate()
                if r.returncode == 0 and out.strip():
                    try:
                        val = int(out.strip())
                        if 40 <= val <= 200:
                            save_config_settings({'layout.max_width': str(val)})
                    except ValueError:
                        pass

            elif sel.startswith("7."):
                r = subprocess.run(
                    ["gum", "confirm", "Reset all settings to defaults?"]
                )
                if r.returncode == 0:
                    reset_settings_to_defaults()
                    settings = get_config_settings()

        except KeyboardInterrupt:
            return


def _whiptail_active(value: str, current: str) -> str:
    """Return a whiptail description with * marker if active."""
    return f"* {value}" if value == current else f"  {value}"


def _whiptail_run(title: str, text: str, menu_items: List[str],
                  num_items: int) -> Optional[str]:
    """Run a whiptail --menu dialog, return selected tag or None."""
    wh_h, wh_w, wh_m = _whiptail_dimensions(num_items)
    with open("/dev/tty", "r") as tty_in, open("/dev/tty", "w") as tty_out:
        proc = subprocess.Popen(
            ["whiptail", "--title", title, "--menu", text,
             wh_h, wh_w, wh_m] + menu_items,
            stdin=tty_in, stdout=tty_out,
            stderr=subprocess.PIPE, text=True
        )
        _, stderr = proc.communicate()
        if proc.returncode == 0 and stderr.strip():
            return stderr.strip()
    return None


def _whiptail_confirm(text: str) -> bool:
    """Run a whiptail --yesno dialog, return True if confirmed."""
    with open("/dev/tty", "r") as ti, open("/dev/tty", "w") as to_:
        p = subprocess.Popen(
            ["whiptail", "--title", "Confirm", "--yesno", text, "8", "50"],
            stdin=ti, stdout=to_, stderr=subprocess.PIPE, text=True
        )
        p.communicate()
        return p.returncode == 0


def _whiptail_input(title: str, text: str, default: str = "") -> Optional[str]:
    """Run a whiptail --inputbox, return entered text or None."""
    with open("/dev/tty", "r") as ti, open("/dev/tty", "w") as to_:
        p = subprocess.Popen(
            ["whiptail", "--title", title, "--inputbox",
             text, "8", "50", default],
            stdin=ti, stdout=to_, stderr=subprocess.PIPE, text=True
        )
        _, se = p.communicate()
        if p.returncode == 0 and se.strip():
            return se.strip()
    return None


def _whiptail_offer_install(backend: str) -> bool:
    """Prompt user to install a missing backend via whiptail confirm."""
    if not _whiptail_confirm(f"Install {backend}?"):
        return False
    success = install_backend(backend)
    if not success:
        input("\nPress Enter to continue...")
    return success


# ── Whiptail backend submenus ─────────────────────────────

def _whiptail_configure_gum() -> None:
    """Gum-specific settings submenu using whiptail."""
    while True:
        settings = get_config_settings()
        current_border = settings.get('gum.border', 'rounded')
        current_theme = "custom"
        for name, (h, m, c) in _COLOR_PRESETS.items():
            if (settings.get('gum.header_foreground') == h and
                    settings.get('gum.match_foreground') == m and
                    settings.get('gum.cursor_foreground') == c):
                current_theme = name
                break

        menu_items = [
            "1", f"  Border Style         [{current_border}]",
            "2", f"  Color Theme          [{current_theme}]",
            "-", "──────────────",
            "3", "  Reset Gum to Defaults",
        ]

        try:
            sel = _whiptail_run("Gum Settings", "Configure Gum backend:",
                                menu_items, 4)
            if not sel or sel == "-":
                return

            if sel == "1":
                items = []
                for v in ("none", "normal", "rounded", "double", "thick"):
                    items.extend([v, _whiptail_active(v, current_border)])
                val = _whiptail_run("Border Style", "Choose border:", items, 5)
                if val:
                    save_config_settings({'gum.border': val})

            elif sel == "2":
                presets = list(_COLOR_PRESETS.keys())
                items = []
                for v in presets:
                    items.extend([v, _whiptail_active(v, current_theme)])
                val = _whiptail_run("Color Theme", "Choose theme:", items,
                                    len(presets))
                if val and val in _COLOR_PRESETS:
                    h, m, c = _COLOR_PRESETS[val]
                    save_config_settings({
                        'gum.header_foreground': h,
                        'gum.match_foreground': m,
                        'gum.cursor_foreground': c,
                    })

            elif sel == "3":
                if _whiptail_confirm("Reset Gum settings to defaults?"):
                    reset_backend_settings("gum")

        except KeyboardInterrupt:
            return


def _whiptail_configure_whiptail() -> None:
    """Whiptail-specific settings submenu using whiptail."""
    while True:
        settings = get_config_settings()
        current_wt = settings.get('whiptail.theme', 'default')

        menu_items = [
            "1", f"  Theme                [{current_wt}]",
            "-", "──────────────",
            "2", "  Reset Whiptail to Defaults",
        ]

        try:
            sel = _whiptail_run("Whiptail Settings",
                                "Configure Whiptail backend:", menu_items, 3)
            if not sel or sel == "-":
                return

            if sel == "1":
                items = []
                for v in ("default", "green", "blue", "red"):
                    items.extend([v, _whiptail_active(v, current_wt)])
                val = _whiptail_run("Whiptail Theme", "Choose theme:",
                                    items, 4)
                if val:
                    save_config_settings({'whiptail.theme': val})

            elif sel == "2":
                if _whiptail_confirm(
                        "Reset Whiptail settings to defaults?"):
                    reset_backend_settings("whiptail")

        except KeyboardInterrupt:
            return


def _whiptail_configure_textual() -> None:
    """Textual-specific settings submenu using whiptail."""
    while True:
        settings = get_config_settings()
        current_theme = settings.get('textual.theme', 'textual-dark')

        menu_items = [
            "1", f"  Theme                [{current_theme}]",
            "-", "──────────────",
            "2", "  Reset Textual to Defaults",
        ]

        try:
            sel = _whiptail_run("Textual Settings",
                                "Configure Textual backend:", menu_items, 3)
            if not sel or sel == "-":
                return

            if sel == "1":
                items = []
                for v in _TEXTUAL_THEMES:
                    items.extend([v, _whiptail_active(v, current_theme)])
                val = _whiptail_run("Textual Theme", "Choose theme:",
                                    items, len(_TEXTUAL_THEMES))
                if val:
                    save_config_settings({'textual.theme': val})

            elif sel == "2":
                if _whiptail_confirm(
                        "Reset Textual settings to defaults?"):
                    reset_backend_settings("textual")

        except KeyboardInterrupt:
            return


def whiptail_settings_menu() -> None:
    """Interactive settings editor using whiptail — hierarchical."""
    while True:
        settings = get_config_settings()
        current_backend = settings.get('backend', 'gum')
        current_align = settings.get('layout.alignment', 'center')
        current_width = settings.get('layout.max_width', '80')

        gum_avail = _check_backend_available("gum")
        textual_avail = _check_backend_available("textual")
        whiptail_avail = _check_backend_available("whiptail")

        gum_status = "installed" if gum_avail else "not installed"
        textual_status = "installed" if textual_avail else "not installed"
        whiptail_status = "installed" if whiptail_avail else "not installed"

        menu_items = [
            "1", f"* Active Backend       [{current_backend}]",
            "-", "─── Backends ───",
            "2", f"  Gum                  [{gum_status}]",
            "3", f"  Textual              [{textual_status}]",
            "4", f"  Whiptail             [{whiptail_status}]",
            "-", "─── Layout ───",
            "5", f"  Alignment            [{current_align}]",
            "6", f"  Max Width            [{current_width}]",
            "-", "──────────────",
            "7", "  Reset All to Defaults",
        ]

        try:
            sel = _whiptail_run("Settings",
                                "Change menu appearance and behaviour:",
                                menu_items, 10)
            if not sel or sel == "-":
                return

            if sel == "1":
                installed = [b for b in ("gum", "textual", "whiptail")
                             if _check_backend_available(b)]
                if installed:
                    items = []
                    for b in installed:
                        items.extend([b, _whiptail_active(b, current_backend)])
                    val = _whiptail_run("Active Backend", "Choose backend:",
                                        items, len(installed))
                    if val:
                        save_config_settings({'backend': val})

            elif sel == "2":
                if gum_avail:
                    _whiptail_configure_gum()
                else:
                    if _whiptail_offer_install("gum"):
                        _whiptail_configure_gum()

            elif sel == "3":
                if textual_avail:
                    _whiptail_configure_textual()
                else:
                    if _whiptail_offer_install("textual"):
                        _whiptail_configure_textual()

            elif sel == "4":
                if whiptail_avail:
                    _whiptail_configure_whiptail()
                else:
                    if _whiptail_offer_install("whiptail"):
                        _whiptail_configure_whiptail()

            elif sel == "5":
                val = _whiptail_run("Layout Alignment", "Choose alignment:", [
                    "center", _whiptail_active("center", current_align),
                    "left", _whiptail_active("left", current_align),
                ], 2)
                if val:
                    save_config_settings({'layout.alignment': val})

            elif sel == "6":
                val = _whiptail_input("Max Width",
                                      "Enter width (40-200):", current_width)
                if val:
                    try:
                        n = int(val)
                        if 40 <= n <= 200:
                            save_config_settings({'layout.max_width': str(n)})
                    except ValueError:
                        pass

            elif sel == "7":
                if _whiptail_confirm("Reset all settings to defaults?"):
                    reset_settings_to_defaults()

        except KeyboardInterrupt:
            return


def _fallback_active(value: str, current: str) -> str:
    """Return a display string with * marker if active."""
    return f"* {value}" if value == current else f"  {value}"


# ── Fallback backend submenus ─────────────────────────────

def _fallback_configure_gum() -> None:
    """Gum-specific settings submenu using plain text."""
    while True:
        settings = get_config_settings()
        current_border = settings.get('gum.border', 'rounded')
        current_theme = "custom"
        for name, (h, m, c) in _COLOR_PRESETS.items():
            if (settings.get('gum.header_foreground') == h and
                    settings.get('gum.match_foreground') == m and
                    settings.get('gum.cursor_foreground') == c):
                current_theme = name
                break

        os.system('cls' if os.name == 'nt' else 'clear')
        print("=" * 40)
        print("  Gum Settings")
        print("=" * 40)
        print(f"  1.   Border Style       [{current_border}]")
        print(f"  2.   Color Theme        [{current_theme}]")
        print(f"  ──────────────")
        print(f"  3. Reset Gum to Defaults")
        print(f"  b. Back")
        print("=" * 40)

        try:
            choice = input("  Select: ").strip().lower()
        except (KeyboardInterrupt, EOFError):
            return

        if choice == 'b' or not choice:
            return

        if choice == '1':
            for v in ('none', 'normal', 'rounded', 'double', 'thick'):
                print(f"    {_fallback_active(v, current_border)}")
            val = input("  Border: ").strip().lower()
            if val in ('none', 'normal', 'rounded', 'double', 'thick'):
                save_config_settings({'gum.border': val})

        elif choice == '2':
            presets = list(_COLOR_PRESETS.keys())
            for v in presets:
                print(f"    {_fallback_active(v, current_theme)}")
            val = input("  Theme: ").strip().lower()
            if val in _COLOR_PRESETS:
                h, m, c = _COLOR_PRESETS[val]
                save_config_settings({
                    'gum.header_foreground': h,
                    'gum.match_foreground': m,
                    'gum.cursor_foreground': c,
                })

        elif choice == '3':
            confirm = input("  Reset Gum to defaults? (y/n): ").strip().lower()
            if confirm == 'y':
                reset_backend_settings("gum")
                print("  Gum settings reset.")
                input("  Press Enter to continue...")


def _fallback_configure_whiptail() -> None:
    """Whiptail-specific settings submenu using plain text."""
    while True:
        settings = get_config_settings()
        current_wt = settings.get('whiptail.theme', 'default')

        os.system('cls' if os.name == 'nt' else 'clear')
        print("=" * 40)
        print("  Whiptail Settings")
        print("=" * 40)
        print(f"  1.   Theme              [{current_wt}]")
        print(f"  ──────────────")
        print(f"  2. Reset Whiptail to Defaults")
        print(f"  b. Back")
        print("=" * 40)

        try:
            choice = input("  Select: ").strip().lower()
        except (KeyboardInterrupt, EOFError):
            return

        if choice == 'b' or not choice:
            return

        if choice == '1':
            for v in ('default', 'green', 'blue', 'red'):
                print(f"    {_fallback_active(v, current_wt)}")
            val = input("  Theme: ").strip().lower()
            if val in ('default', 'green', 'blue', 'red'):
                save_config_settings({'whiptail.theme': val})

        elif choice == '2':
            confirm = input("  Reset Whiptail to defaults? (y/n): ").strip().lower()
            if confirm == 'y':
                reset_backend_settings("whiptail")
                print("  Whiptail settings reset.")
                input("  Press Enter to continue...")


def _fallback_configure_textual() -> None:
    """Textual-specific settings submenu using plain text."""
    while True:
        settings = get_config_settings()
        current_theme = settings.get('textual.theme', 'textual-dark')

        os.system('cls' if os.name == 'nt' else 'clear')
        print("=" * 40)
        print("  Textual Settings")
        print("=" * 40)
        print(f"  1.   Theme              [{current_theme}]")
        print(f"  ──────────────")
        print(f"  2. Reset Textual to Defaults")
        print(f"  b. Back")
        print("=" * 40)

        try:
            choice = input("  Select: ").strip().lower()
        except (KeyboardInterrupt, EOFError):
            return

        if choice == 'b' or not choice:
            return

        if choice == '1':
            for v in _TEXTUAL_THEMES:
                print(f"    {_fallback_active(v, current_theme)}")
            val = input("  Theme: ").strip().lower()
            if val in _TEXTUAL_THEMES:
                save_config_settings({'textual.theme': val})

        elif choice == '2':
            confirm = input("  Reset Textual to defaults? (y/n): ").strip().lower()
            if confirm == 'y':
                reset_backend_settings("textual")
                print("  Textual settings reset.")
                input("  Press Enter to continue...")


def _fallback_offer_install(backend: str) -> bool:
    """Prompt user to install a missing backend via plain text."""
    confirm = input(f"  Install {backend}? (y/n): ").strip().lower()
    if confirm != 'y':
        return False
    success = install_backend(backend)
    if not success:
        input("\nPress Enter to continue...")
    return success


def fallback_settings_menu() -> None:
    """Plain text settings menu — hierarchical with backend submenus."""
    while True:
        settings = get_config_settings()
        current_backend = settings.get('backend', 'gum')
        current_align = settings.get('layout.alignment', 'center')
        current_width = settings.get('layout.max_width', '80')

        gum_avail = _check_backend_available("gum")
        textual_avail = _check_backend_available("textual")
        whiptail_avail = _check_backend_available("whiptail")

        gum_status = "installed" if gum_avail else "not installed"
        textual_status = "installed" if textual_avail else "not installed"
        whiptail_status = "installed" if whiptail_avail else "not installed"

        os.system('cls' if os.name == 'nt' else 'clear')
        print("=" * 40)
        print("  Settings")
        print("=" * 40)
        print(f"  1. * Active Backend     [{current_backend}]")
        print(f"  ─── Backends ───")
        print(f"  2.   Gum                [{gum_status}]")
        print(f"  3.   Textual            [{textual_status}]")
        print(f"  4.   Whiptail           [{whiptail_status}]")
        print(f"  ─── Layout ───")
        print(f"  5.   Alignment          [{current_align}]")
        print(f"  6.   Max Width          [{current_width}]")
        print(f"  ──────────────")
        print(f"  7. Reset All to Defaults")
        print(f"  b. Back")
        print("=" * 40)

        try:
            choice = input("  Select: ").strip().lower()
        except (KeyboardInterrupt, EOFError):
            return

        if choice == 'b' or not choice:
            return

        if choice == '1':
            installed = [b for b in ("gum", "textual", "whiptail")
                         if _check_backend_available(b)]
            for v in installed:
                print(f"    {_fallback_active(v, current_backend)}")
            val = input("  Backend: ").strip().lower()
            if val in installed:
                save_config_settings({'backend': val})

        elif choice == '2':
            if gum_avail:
                _fallback_configure_gum()
            else:
                if _fallback_offer_install("gum"):
                    _fallback_configure_gum()

        elif choice == '3':
            if textual_avail:
                _fallback_configure_textual()
            else:
                if _fallback_offer_install("textual"):
                    _fallback_configure_textual()

        elif choice == '4':
            if whiptail_avail:
                _fallback_configure_whiptail()
            else:
                if _fallback_offer_install("whiptail"):
                    _fallback_configure_whiptail()

        elif choice == '5':
            for v in ('center', 'left'):
                print(f"    {_fallback_active(v, current_align)}")
            val = input("  Alignment: ").strip().lower()
            if val in ('center', 'left'):
                save_config_settings({'layout.alignment': val})

        elif choice == '6':
            val = input("  Width (40-200): ").strip()
            try:
                n = int(val)
                if 40 <= n <= 200:
                    save_config_settings({'layout.max_width': str(n)})
            except ValueError:
                pass

        elif choice == '7':
            confirm = input("  Reset to defaults? (y/n): ").strip().lower()
            if confirm == 'y':
                reset_settings_to_defaults()
                print("  Settings reset to defaults.")
                input("  Press Enter to continue...")


def textual_settings_menu() -> None:
    """Settings menu for Textual backend — delegates to gum/whiptail/fallback."""
    if gum_available():
        gum_settings_menu()
    elif shutil.which("whiptail"):
        whiptail_settings_menu()
    else:
        fallback_settings_menu()


def gum_menu(directory: Path, breadcrumb: List[str] = None) -> None:
    """Display menu using gum with modal dialog style."""
    if breadcrumb is None:
        breadcrumb = ["Main Menu"]

    settings = get_config_settings()
    border = settings.get('gum.border', 'rounded')
    border_fg = settings.get('gum.border_foreground', '99')
    header_fg = settings.get('gum.header_foreground', '99')
    height = settings.get('gum.height', '15')

    while True:
        layout = get_layout_params(settings)
        margin_str = f"0 {layout['left_margin']}"

        items = scan_menu_directory(directory)

        if not items:
            print("No items in this menu")
            return

        # Build choice list with number/letter prefixes for keyboard selection
        choices = []
        item_map = {}  # Map prefix to item

        # Calculate padding width for alignment (01, 02... or 001, 002...)
        num_items = len(items)
        pad_width = len(str(num_items))
        if pad_width < 2:
            pad_width = 2  # Minimum 2 digits (01, 02...)

        num = 1
        for item in items:
            # Zero-padded prefix for display, but also map non-padded for easy typing
            padded = str(num).zfill(pad_width)
            if item.is_submenu:
                if item.description:
                    label = f"{padded}. 📁 {item.name} — {item.description}"
                else:
                    label = f"{padded}. 📁 {item.name}"
            else:
                if item.script_info.script_type == "tool":
                    if item.script_info.binary and not item.script_info.binary_available:
                        status = "⛔"
                    else:
                        status = "▶️ "
                else:
                    status = "✅" if item.script_info.installed else "⬜"
                root = "🔐" if item.script_info.root else "  "
                label = f"{padded}. {status}{root} {item.name}"
            choices.append(label)
            # Map both padded and non-padded versions
            item_map[padded] = item
            item_map[str(num)] = item
            num += 1

        # Add navigation with letter shortcuts
        choices.append("─" * 30)
        if len(breadcrumb) == 1:
            choices.append("s. ⚙️  Settings")
        if len(breadcrumb) > 1:
            choices.append("b. ⬅️  Back")
        choices.append("x. ❌ Exit")

        # Show breadcrumb path
        path_display = " > ".join(breadcrumb)

        try:
            with _sigwinch_guard() as guard:
                # Clear screen and show styled header
                os.system('clear')

                # Display bordered title using gum style (centered via margin)
                subprocess.run([
                    "gum", "style",
                    "--border", border,
                    "--border-foreground", border_fg,
                    "--foreground", header_fg,
                    "--padding", "1 2",
                    "--margin", margin_str,
                    "--width", str(layout['content_width']),
                    f"📍 {path_display}",
                    "Type number to select, b=back, x=exit",
                    "✅ Installed  ⬜ Not installed  🔐 Requires root"
                ])

                # Pad filter choices for visual centering
                pad = " " * layout['left_margin']
                padded_choices = [f"{pad}{c}" for c in choices]

                # Run gum filter via Popen so guard can kill on resize
                proc = subprocess.Popen(
                    [
                        "gum", "filter",
                        "--height", height,
                        "--placeholder", "Type number to select...",
                    ] + padded_choices,
                    stdout=subprocess.PIPE,
                    text=True
                )
                guard.track(proc)
                stdout, _ = proc.communicate()

            if proc.returncode != 0:
                return

            selection = stdout.strip().lstrip() if stdout else ""

            if not selection:
                return

            # Parse the prefix from selection
            if selection.startswith("x."):
                return

            if selection.startswith("b."):
                return  # Go back one level

            if selection.startswith("s."):
                gum_settings_menu()
                settings = get_config_settings()  # Re-read after changes
                continue

            if selection.startswith("─"):
                continue

            # Extract prefix number and find item
            prefix = selection.split(".")[0] if "." in selection else ""
            if prefix in item_map:
                item = item_map[prefix]
                if item.is_submenu:
                    gum_menu(item.path, breadcrumb + [item.name])
                else:
                    gum_script_action(item.script_info)

        except TerminalResized:
            continue  # Restart loop with fresh layout params
        except KeyboardInterrupt:
            return


def gum_script_action(script_info: ScriptInfo) -> None:
    """Show script actions using gum with modal dialog style."""
    settings = get_config_settings()
    border = settings.get('gum.border', 'rounded')
    border_fg = settings.get('gum.border_foreground', '99')

    while True:
        layout = get_layout_params(settings)
        margin_str = f"0 {layout['left_margin']}"
        # Build info display based on script type
        if script_info.script_type == "tool":
            binary_status = "✅ found" if script_info.binary_available else "⛔ not found"
            info_lines = [
                f"📦 {script_info.name}",
                f"",
                f"Description: {script_info.description}",
                f"Version: {script_info.version}",
                f"Type: Tool Script",
                f"Requires: {script_info.binary} ({binary_status})",
            ]
            if script_info.binary_available:
                choices = [
                    "r. ▶️  Run",
                    "l. 📋 View Log",
                    "v. 📄 View Script",
                    "b. ⬅️  Back"
                ]
            else:
                info_lines.extend([
                    f"",
                    f"Install {script_info.binary} first to use this script.",
                ])
                choices = [
                    "v. 📄 View Script",
                    "b. ⬅️  Back"
                ]
        elif script_info.script_type == "config":
            info_lines = [
                f"📦 {script_info.name}",
                f"",
                f"Description: {script_info.description}",
                f"Version: {script_info.version}",
                f"Type: Configuration",
                f"Requires Root: {'Yes' if script_info.root else 'No'}",
            ]
            choices = [
                "r. ▶️  Run",
                "l. 📋 View Log",
                "v. 📄 View Script",
                "b. ⬅️  Back"
            ]
        else:
            info_lines = [
                f"📦 {script_info.name}",
                f"",
                f"Description: {script_info.description}",
                f"Version: {script_info.version}",
                f"Requires Root: {'Yes' if script_info.root else 'No'}",
                f"Installed: {'✅ Yes' if script_info.installed else '⬜ No'}",
            ]
            choices = ["i. ▶️  Install"]
            if script_info.installed:
                choices.append("u. 🗑️  Uninstall")
            choices.extend([
                "l. 📋 View Log",
                "v. 📄 View Script",
                "b. ⬅️  Back"
            ])

        try:
            with _sigwinch_guard() as guard:
                # Clear screen and show styled info box
                os.system('clear')

                # Display script info in bordered box (centered via margin)
                subprocess.run([
                    "gum", "style",
                    "--border", border,
                    "--border-foreground", border_fg,
                    "--padding", "1 2",
                    "--margin", margin_str,
                    "--width", str(layout['content_width']),
                ] + info_lines)

                # Pad filter choices for visual centering
                pad = " " * layout['left_margin']
                padded_choices = [f"{pad}{c}" for c in choices]

                # Run gum filter via Popen so guard can kill on resize
                proc = subprocess.Popen(
                    ["gum", "filter", "--height", "8", "--placeholder", "Type letter to select..."] + padded_choices,
                    stdout=subprocess.PIPE,
                    text=True
                )
                guard.track(proc)
                stdout, _ = proc.communicate()

            if proc.returncode != 0:
                return

            selection = stdout.strip().lstrip() if stdout else ""

            if not selection or selection.startswith("b."):
                return

            if selection.startswith("r.") or selection.startswith("i."):
                rc = run_script(script_info, "install")
                if script_info.script_type not in ("config", "tool"):
                    updated = _reparse_script_info(script_info)
                    if updated:
                        script_info.installed = updated.installed
                if rc != 0:
                    print(f"\n⚠ Script failed (exit code {rc}). Returning to menu.")
                input("\nPress Enter to continue...")
                if rc != 0:
                    return

            elif selection.startswith("u."):
                rc = run_script(script_info, "uninstall")
                updated = _reparse_script_info(script_info)
                if updated:
                    script_info.installed = updated.installed
                if rc != 0:
                    print(f"\n⚠ Script failed (exit code {rc}). Returning to menu.")
                input("\nPress Enter to continue...")
                if rc != 0:
                    return

            elif selection.startswith("l."):
                view_log(script_info.path.stem)

            elif selection.startswith("v."):
                subprocess.run(["less", str(script_info.path)])

        except TerminalResized:
            continue  # Restart loop with fresh layout params
        except KeyboardInterrupt:
            return


# ============================================
# WHIPTAIL FALLBACK MENU
# ============================================

def _whiptail_dimensions(num_items: int) -> tuple:
    """Calculate dynamic whiptail dialog dimensions from terminal size.

    Returns (height, width, menu_lines) as strings for whiptail args.
    """
    term = shutil.get_terminal_size()
    width = max(50, min(100, int(term.columns * 0.8)))
    height = max(15, min(40, int(term.lines * 0.8)))
    menu_lines = max(4, height - 8)  # Reserve ~8 lines for dialog chrome
    menu_lines = min(menu_lines, num_items + 2)  # Don't exceed items + nav
    return (str(height), str(width), str(menu_lines))


def whiptail_menu(directory: Path, breadcrumb: List[str] = None) -> None:
    """Display menu using whiptail."""
    if breadcrumb is None:
        breadcrumb = ["Main Menu"]

    while True:
        items = scan_menu_directory(directory)

        if not items:
            subprocess.run([
                "whiptail", "--msgbox", "No items in this menu", "8", "40"
            ])
            return

        # Build menu items for whiptail
        # Note: whiptail shows "tag  description" so we use the tag as the number
        menu_items = []
        for i, item in enumerate(items):
            tag = str(i + 1)  # 1-based numbering shown as tag
            if item.is_submenu:
                if item.description:
                    desc = f"📁 {item.name} — {item.description}"
                else:
                    desc = f"📁 {item.name}"
            else:
                status = "✅" if item.script_info.installed else "⬜"
                root = "🔐" if item.script_info.root else ""
                desc = f"{status}{root} {item.name}"
            menu_items.extend([tag, desc])

        # Add navigation
        if len(breadcrumb) == 1:
            menu_items.extend(["s", "⚙️  Settings"])
        menu_items.extend(["b", "⬅️  Back"])
        menu_items.extend(["x", "❌ Exit"])

        title = " > ".join(breadcrumb)

        try:
            wh_h, wh_w, wh_m = _whiptail_dimensions(len(items))
            cmd = [
                "whiptail", "--title", title,
                "--menu", "Select an option (use arrow keys):",
                wh_h, wh_w, wh_m
            ] + menu_items

            # Run whiptail with direct terminal access
            # Capture only stderr (where selection is returned)
            # stdin/stdout go to terminal for UI interaction
            with open("/dev/tty", "r") as tty_in, open("/dev/tty", "w") as tty_out:
                proc = subprocess.Popen(
                    cmd,
                    stdin=tty_in,
                    stdout=tty_out,
                    stderr=subprocess.PIPE,
                    text=True
                )
                _, stderr_output = proc.communicate()
                result = type('Result', (), {'returncode': proc.returncode, 'stderr': stderr_output})()

            if result.returncode != 0:
                return

            selection = result.stderr.strip()

            if selection == "x" or not selection:
                return

            if selection == "b":
                return

            if selection == "s":
                whiptail_settings_menu()
                continue

            try:
                idx = int(selection) - 1  # Convert 1-based tag back to 0-based index
                item = items[idx]

                if item.is_submenu:
                    whiptail_menu(item.path, breadcrumb + [item.name])
                else:
                    whiptail_script_action(item.script_info)
            except (ValueError, IndexError):
                continue

        except KeyboardInterrupt:
            return


def whiptail_script_action(script_info: ScriptInfo) -> None:
    """Show script actions using whiptail."""
    while True:
        root = "🔐 Yes" if script_info.root else "No"

        # Different display for config vs install scripts
        if script_info.script_type == "config":
            info = (
                f"{script_info.name} (v{script_info.version})\n"
                f"{script_info.description}\n"
                f"Type: Configuration  |  Root: {root}"
            )
            menu_items = [
                "run", "▶️  Run",
                "log", "View Log",
                "view", "View Script",
                "back", "Back"
            ]
        else:
            status = "✅ Installed" if script_info.installed else "⬜ Not Installed"
            info = (
                f"{script_info.name} (v{script_info.version})\n"
                f"{script_info.description}\n"
                f"Status: {status}  |  Root: {root}"
            )
            menu_items = [
                "install", "Install",
            ]
            if script_info.installed:
                menu_items.extend(["uninstall", "Uninstall"])
            menu_items.extend([
                "log", "View Log",
                "view", "View Script",
                "back", "Back"
            ])

        try:
            wh_h, wh_w, wh_m = _whiptail_dimensions(len(menu_items) // 2)
            cmd = [
                "whiptail", "--title", script_info.name,
                "--menu", info,
                wh_h, wh_w, wh_m
            ] + menu_items

            # Run whiptail with direct terminal access
            with open("/dev/tty", "r") as tty_in, open("/dev/tty", "w") as tty_out:
                proc = subprocess.Popen(
                    cmd,
                    stdin=tty_in,
                    stdout=tty_out,
                    stderr=subprocess.PIPE,
                    text=True
                )
                _, stderr_output = proc.communicate()
                result = type('Result', (), {'returncode': proc.returncode, 'stderr': stderr_output})()

            if result.returncode != 0:
                return

            selection = result.stderr.strip()

            if selection == "back" or not selection:
                return

            if selection == "run":
                rc = run_script(script_info, "install")  # Config scripts use install action
                if rc != 0:
                    print(f"\n⚠ Script failed (exit code {rc}). Returning to menu.")
                input("\nPress Enter to continue...")
                if rc != 0:
                    return

            elif selection == "install":
                rc = run_script(script_info, "install")
                updated = _reparse_script_info(script_info)
                if updated:
                    script_info.installed = updated.installed
                if rc != 0:
                    print(f"\n⚠ Script failed (exit code {rc}). Returning to menu.")
                input("\nPress Enter to continue...")
                if rc != 0:
                    return

            elif selection == "uninstall":
                rc = run_script(script_info, "uninstall")
                updated = _reparse_script_info(script_info)
                if updated:
                    script_info.installed = updated.installed
                if rc != 0:
                    print(f"\n⚠ Script failed (exit code {rc}). Returning to menu.")
                input("\nPress Enter to continue...")
                if rc != 0:
                    return

            elif selection == "log":
                view_log(script_info.path.stem)

            elif selection == "view":
                subprocess.run(["less", str(script_info.path)])

        except KeyboardInterrupt:
            return


# ============================================
# TEXTUAL TUI (Most Modern) - FIXED FOR KEYBOARD
# ============================================

if HAS_TEXTUAL:

    class NinjaMenuApp(App):
        """Modern TUI menu application using Textual with full keyboard support."""

        CSS = """
        Screen {
            background: $surface;
        }

        #breadcrumb {
            dock: top;
            width: 100%;
            height: 3;
            padding: 1;
            background: $primary;
            color: $text;
            text-style: bold;
        }

        #content-wrapper {
            width: 100%;
            max-width: 100;
            align-horizontal: center;
            height: 1fr;
        }

        #menu-list {
            width: 100%;
            height: 1fr;
            padding: 1;
        }

        #info-panel {
            dock: bottom;
            width: 100%;
            height: 6;
            padding: 1;
            background: $panel;
            border-top: solid $accent;
        }

        OptionList {
            width: 100%;
            height: 100%;
        }

        OptionList > .option-list--option-highlighted {
            background: $accent;
            color: $text;
        }

        OptionList > .option-list--option-hover {
            background: $accent 50%;
        }
        """

        BINDINGS = [
            Binding("q", "quit", "Quit"),
            Binding("escape", "go_back", "Back"),
            Binding("backspace", "go_back", "Back"),
            Binding("r", "refresh", "Refresh"),
            Binding("l", "view_log", "View Log"),
            Binding("enter", "select_item", "Select"),
            Binding("i", "install", "Install"),
            Binding("u", "uninstall", "Uninstall"),
        ]

        def __init__(self, start_dir: Path = None):
            super().__init__()
            self.current_dir = start_dir or MAIN_MENU_DIR
            self.breadcrumb = ["NinjaMenu"]
            self.items: List[MenuItem] = []
            self.history: List[Path] = []
            self._id_to_item: Dict[str, MenuItem] = {}  # option_id -> MenuItem

        def compose(self) -> ComposeResult:
            yield Header(show_clock=True)
            yield Static("📍 NinjaMenu", id="breadcrumb")
            with Container(id="content-wrapper"):
                yield OptionList(id="menu-list")
            yield Static("Use ↑↓ arrows to navigate, Enter to select, Backspace/Esc to go back, q to quit", id="info-panel")
            yield Footer()

        def on_mount(self) -> None:
            # Apply configured theme (must be done after mount, not in __init__)
            settings = get_config_settings()
            theme_name = settings.get('textual.theme', 'textual-dark')
            try:
                self.theme = theme_name
            except Exception:
                self.theme = "textual-dark"
            self.refresh_menu()
            # Focus the option list for keyboard navigation
            self.query_one("#menu-list", OptionList).focus()

        def refresh_menu(self) -> None:
            """Refresh the menu with current directory contents."""
            option_list = self.query_one("#menu-list", OptionList)
            option_list.clear_options()

            # Update breadcrumb
            breadcrumb = self.query_one("#breadcrumb", Static)
            breadcrumb.update(f"📍 {' > '.join(self.breadcrumb)}")

            self.items = scan_menu_directory(self.current_dir)
            self._id_to_item.clear()

            folder_num = 1
            for idx, item in enumerate(self.items):
                opt_id = f"item_{idx}"
                self._id_to_item[opt_id] = item
                if item.is_submenu:
                    if item.description:
                        option_list.add_option(Option(f"{folder_num}. 📁 {item.name} — {item.description}", id=opt_id))
                    else:
                        option_list.add_option(Option(f"{folder_num}. 📁 {item.name}", id=opt_id))
                    folder_num += 1
                else:
                    status = "✅" if item.script_info.installed else "⬜"
                    root = "🔐" if item.script_info.root else "  "
                    option_list.add_option(Option(f"   {status}{root} {item.name}", id=opt_id))

            # Add settings at root level, back option in submenus
            option_list.add_option(None)  # Separator
            if not self.history:
                option_list.add_option(Option("⚙️  Settings", id="__settings__"))
            else:
                option_list.add_option(Option("⬅️  Back", id="__back__"))

            # Update info panel
            self.update_info_panel()

        def update_info_panel(self, item: MenuItem = None) -> None:
            """Update the info panel with selected item details."""
            info_panel = self.query_one("#info-panel", Static)

            if item and item.script_info:
                info = item.script_info
                root = " | 🔐 Root" if info.root else ""
                tags = f" | Tags: {', '.join(info.tags)}" if info.tags else ""

                if info.script_type == "config":
                    info_panel.update(f"{info.description}\n[⚙️ Config{root}{tags}] Press Enter to run")
                else:
                    status = "✅ Installed" if info.installed else "⬜ Not installed"
                    info_panel.update(f"{info.description}\n[{status}{root}{tags}]")
            elif item and item.is_submenu:
                desc = f"\n{item.description}" if item.description else ""
                info_panel.update(f"📁 {item.name}{desc}\nPress Enter to open submenu")
            else:
                info_panel.update("Use ↑↓ arrows to navigate, Enter to select, Backspace/Esc to go back, q to quit")

        def _get_item(self, option_id: str) -> Optional[MenuItem]:
            """Look up a MenuItem by its option ID."""
            return self._id_to_item.get(option_id)

        def on_option_list_option_highlighted(self, event: OptionList.OptionHighlighted) -> None:
            """Handle option highlight (selection change)."""
            if event.option_id in ("__back__", "__settings__"):
                self.update_info_panel(None)
                return
            item = self._get_item(event.option_id)
            if item:
                self.update_info_panel(item)

        def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
            """Handle option selection (Enter key or click)."""
            if event.option_id == "__back__":
                self.action_go_back()
                return

            if event.option_id == "__settings__":
                self.exit(result=("settings", None))
                return

            item = self._get_item(event.option_id)
            if item:
                if item.is_submenu:
                    self.history.append(self.current_dir)
                    self.current_dir = item.path
                    self.breadcrumb.append(item.name)
                    self.refresh_menu()
                else:
                    self.handle_script_selection(item)

        def handle_script_selection(self, item: MenuItem) -> None:
            """Handle script selection - show action menu."""
            self.exit(result=("action", item))

        def action_go_back(self) -> None:
            """Go back to previous menu."""
            if self.history:
                self.current_dir = self.history.pop()
                self.breadcrumb.pop()
                self.refresh_menu()

        def action_refresh(self) -> None:
            """Refresh current menu."""
            self.refresh_menu()

        def action_select_item(self) -> None:
            """Select currently highlighted item."""
            option_list = self.query_one("#menu-list", OptionList)
            if option_list.highlighted is not None:
                option = option_list.get_option_at_index(option_list.highlighted)
                if option:
                    self.on_option_list_option_selected(
                        OptionList.OptionSelected(option_list, option_list.highlighted, option.id)
                    )

        def action_install(self) -> None:
            """Install currently highlighted script."""
            option_list = self.query_one("#menu-list", OptionList)
            if option_list.highlighted is not None:
                option = option_list.get_option_at_index(option_list.highlighted)
                if option:
                    item = self._get_item(option.id)
                    if item and not item.is_submenu:
                        self.exit(result=("install", item))

        def action_uninstall(self) -> None:
            """Uninstall currently highlighted script."""
            option_list = self.query_one("#menu-list", OptionList)
            if option_list.highlighted is not None:
                option = option_list.get_option_at_index(option_list.highlighted)
                if option:
                    item = self._get_item(option.id)
                    if item and not item.is_submenu:
                        if item.script_info and item.script_info.installed:
                            self.exit(result=("uninstall", item))

        def action_view_log(self) -> None:
            """View log for currently highlighted script."""
            option_list = self.query_one("#menu-list", OptionList)
            if option_list.highlighted is not None:
                option = option_list.get_option_at_index(option_list.highlighted)
                if option:
                    item = self._get_item(option.id)
                    if item and not item.is_submenu:
                        self.exit(result=("log", item))


def run_textual_menu(start_dir: Path = None):
    """Run the Textual menu with action handling."""
    while True:
        app = NinjaMenuApp(start_dir)
        result = app.run()

        if result is None:
            break

        action, item = result

        if action == "settings":
            textual_settings_menu()
            continue

        if action == "action":
            # Show action menu using gum or whiptail
            if gum_available():
                gum_script_action(item.script_info)
            else:
                whiptail_script_action(item.script_info)

        elif action == "install":
            run_script(item.script_info, "install")
            input("\nPress Enter to continue...")

        elif action == "uninstall":
            run_script(item.script_info, "uninstall")
            input("\nPress Enter to continue...")

        elif action == "log":
            view_log(item.script_info.path.stem)

        # Continue the loop to return to menu
        start_dir = None  # Reset to show from where we left


# ============================================
# CLI LIST COMMAND
# ============================================

def list_all_scripts(directory: Path = None, indent: int = 0) -> None:
    """List all scripts in the menu structure."""
    if directory is None:
        directory = MAIN_MENU_DIR

    items = scan_menu_directory(directory)
    prefix = "  " * indent

    for item in items:
        if item.is_submenu:
            if item.description:
                print(f"{prefix}📁 {item.name}/ — {item.description}")
            else:
                print(f"{prefix}📁 {item.name}/")
            list_all_scripts(item.path, indent + 1)
        else:
            info = item.script_info
            status = "✅" if info.installed else "⬜"
            root = "🔐" if info.root else "  "
            print(f"{prefix}{status}{root} {info.name}")
            print(f"{prefix}    └─ {item.path.relative_to(MENU_ROOT)}")


# ============================================
# MAIN ENTRY POINT
# ============================================

def main():
    parser = argparse.ArgumentParser(
        description="NinjaMenu - Kali Linux Installer Menu System"
    )
    parser.add_argument(
        "--list", "-l",
        action="store_true",
        help="List all available scripts"
    )
    parser.add_argument(
        "--run", "-r",
        metavar="SCRIPT",
        help="Run a specific script directly"
    )
    parser.add_argument(
        "--submenu", "-s",
        metavar="PATH",
        help="Start at a specific submenu (e.g., llm/cli)"
    )
    parser.add_argument(
        "--tui",
        choices=["auto", "textual", "gum", "whiptail"],
        default="auto",
        help="Force a specific TUI backend"
    )
    parser.add_argument(
        "--rebuild",
        action="store_true",
        help="Force rebuild the SQLite menu cache from YAML metadata"
    )

    args = parser.parse_args()

    # Ensure log and cache directories exist
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    # Ensure SQLite cache is up to date (replaces alias registry + filesystem scanning)
    _ensure_cache()

    if args.rebuild:
        print("Rebuilding menu cache...")
        rebuild_cache(MAIN_MENU_DIR, DB_PATH)
        print(f"Cache rebuilt: {DB_PATH}")
        return

    if args.list:
        print("\n📋 NinjaMenu - Available Scripts:\n")
        list_all_scripts()
        print()
        return

    if args.run:
        script_path = MENU_ROOT / args.run
        if not script_path.exists():
            script_path = MAIN_MENU_DIR / args.run

        if not script_path.exists():
            print(f"Script not found: {args.run}")
            sys.exit(1)

        info = parse_yaml_header(script_path)
        if not info:
            print(f"Could not parse script: {args.run}")
            sys.exit(1)

        sys.exit(run_script(info))

    # Determine start directory
    start_dir = MAIN_MENU_DIR
    if args.submenu:
        start_dir = MAIN_MENU_DIR / args.submenu
        if not start_dir.exists():
            print(f"Submenu not found: {args.submenu}")
            sys.exit(1)

    # Select TUI backend
    tui = args.tui

    has_whiptail = shutil.which("whiptail") is not None

    if tui == "auto":
        # Read from config file
        config_backend = get_config_backend()

        if config_backend == "textual" and _check_backend_available("textual"):
            tui = "textual"
        elif config_backend == "gum" and gum_available():
            tui = "gum"
        elif config_backend == "whiptail" and has_whiptail:
            tui = "whiptail"
        else:
            # Configured backend not available — fall back gracefully
            if config_backend not in ("gum", "textual", "whiptail"):
                pass  # Unknown value, use fallback chain
            elif config_backend != "auto":
                print(f"Warning: configured backend '{config_backend}' is not available, falling back...")
            if gum_available():
                tui = "gum"
            elif _check_backend_available("textual"):
                tui = "textual"
            elif has_whiptail:
                tui = "whiptail"
            else:
                print("Error: no TUI backend available (install gum, textual, or whiptail)")
                sys.exit(1)

    # Final availability guard for explicit --tui flag
    if tui == "whiptail" and not has_whiptail:
        print("Error: whiptail is not installed")
        sys.exit(1)
    if tui == "gum" and not gum_available():
        print("Error: gum is not installed or cannot access TTY")
        sys.exit(1)
    if tui == "textual" and not _check_backend_available("textual"):
        print("Error: textual is not installed (pip install textual)")
        sys.exit(1)

    # If textual is selected but not importable in the current process,
    # re-exec through the venv Python where it IS installed.
    # Guard against infinite re-exec with an env var.
    if tui == "textual" and not HAS_TEXTUAL:
        if os.environ.get('_NINJA_VENV_REEXEC'):
            print("Error: textual could not be imported even from the venv Python.")
            print("Try: source .venv/bin/activate && pip install textual")
            sys.exit(1)
        venv_python = MENU_ROOT / ".venv" / "bin" / "python3"
        if venv_python.exists():
            os.environ['_NINJA_VENV_REEXEC'] = '1'
            os.execv(str(venv_python), [str(venv_python)] + sys.argv)
        else:
            print("Error: textual is in the venv but venv python not found")
            sys.exit(1)

    if tui == "gum":
        gum_menu(start_dir)
    elif tui == "textual":
        run_textual_menu(start_dir)
    else:
        whiptail_menu(start_dir)


if __name__ == "__main__":
    main()
