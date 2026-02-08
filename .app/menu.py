#!/usr/bin/env python3
"""
Kali Menu Installer - Dynamic TUI Menu System
NinjaMenu - Generates menus from folder structure with YAML header parsing.
"""

import os
import sys
import re
import shutil
import subprocess
import argparse
import platform
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from datetime import datetime

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

try:
    from textual.app import App, ComposeResult
    from textual.containers import Container, Vertical, Horizontal, VerticalScroll
    from textual.widgets import Header, Footer, Static, Button, ListItem, ListView, Label, OptionList
    from textual.widgets.option_list import Option, Separator
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


@dataclass
class MenuItem:
    """Menu item (script or submenu)."""
    name: str
    path: Path
    is_submenu: bool = False
    script_info: Optional[ScriptInfo] = None
    order: int = 50


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


def scan_menu_directory(directory: Path) -> List[MenuItem]:
    """Scan a directory and return menu items."""
    items = []

    if not directory.exists():
        return items

    for entry in directory.iterdir():
        # Skip hidden files/folders (starting with .)
        if entry.name.startswith('.'):
            continue

        if entry.is_dir():
            # It's a submenu - convert to CamelCase
            name_parts = entry.name.replace('-', ' ').replace('_', ' ').split()
            camel_name = ''.join(word.capitalize() for word in name_parts)
            items.append(MenuItem(
                name=camel_name,
                path=entry,
                is_submenu=True,
                order=0  # Submenus first
            ))
        elif entry.suffix == '.sh':
            # It's a script
            script_info = parse_yaml_header(entry)
            if script_info and not script_info.hidden:
                items.append(MenuItem(
                    name=script_info.name,
                    path=entry,
                    is_submenu=False,
                    script_info=script_info,
                    order=script_info.order
                ))

    # Sort by order, then by name
    items.sort(key=lambda x: (0 if x.is_submenu else 1, x.order, x.name))
    return items


def run_script(script_info: ScriptInfo, action: str = "install") -> int:
    """Run a script with proper handling."""
    script_path = script_info.path

    # Build command
    # On macOS, scripts handle their own privilege checks via require_root
    # (Homebrew refuses to run under sudo)
    cmd = []
    if script_info.root and platform.system() != "Darwin":
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
        if len(breadcrumb) > 1:
            choices.append("b. ⬅️  Back")
        choices.append("x. ❌ Exit")

        # Show breadcrumb path
        path_display = " > ".join(breadcrumb)

        try:
            # Clear screen and show styled header
            os.system('clear')

            # Display bordered title using gum style
            subprocess.run([
                "gum", "style",
                "--border", border,
                "--border-foreground", border_fg,
                "--foreground", header_fg,
                "--padding", "1 2",
                "--margin", "1",
                f"📍 {path_display}",
                "Type number to select, b=back, x=exit"
            ])

            # Show menu with gum filter for keyboard input
            result = subprocess.run(
                [
                    "gum", "filter",
                    "--height", height,
                    "--placeholder", "Type number to select...",
                ] + choices,
                stdout=subprocess.PIPE,
                text=True
            )

            if result.returncode != 0:
                return

            selection = result.stdout.strip() if result.stdout else ""

            if not selection:
                return

            # Parse the prefix from selection
            if selection.startswith("x."):
                return

            if selection.startswith("b."):
                return  # Go back one level

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

        except KeyboardInterrupt:
            return


def gum_script_action(script_info: ScriptInfo) -> None:
    """Show script actions using gum with modal dialog style."""
    settings = get_config_settings()
    border = settings.get('gum.border', 'rounded')
    border_fg = settings.get('gum.border_foreground', '99')

    while True:
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
            # Clear screen and show styled info box
            os.system('clear')

            # Display script info in bordered box
            subprocess.run([
                "gum", "style",
                "--border", border,
                "--border-foreground", border_fg,
                "--padding", "1 2",
                "--margin", "1",
            ] + info_lines)

            # Show action menu with gum filter for keyboard shortcuts
            result = subprocess.run(
                ["gum", "filter", "--height", "8", "--placeholder", "Type letter to select..."] + choices,
                stdout=subprocess.PIPE,
                text=True
            )

            if result.returncode != 0:
                return

            selection = result.stdout.strip() if result.stdout else ""

            if not selection or selection.startswith("b."):
                return

            if selection.startswith("r.") or selection.startswith("i."):
                run_script(script_info, "install")
                if script_info.script_type not in ("config", "tool"):
                    updated = parse_yaml_header(script_info.path)
                    if updated:
                        script_info.installed = updated.installed
                input("\nPress Enter to continue...")

            elif selection.startswith("u."):
                run_script(script_info, "uninstall")
                updated = parse_yaml_header(script_info.path)
                if updated:
                    script_info.installed = updated.installed
                input("\nPress Enter to continue...")

            elif selection.startswith("l."):
                view_log(script_info.path.stem)

            elif selection.startswith("v."):
                subprocess.run(["less", str(script_info.path)])

        except KeyboardInterrupt:
            return


# ============================================
# WHIPTAIL FALLBACK MENU
# ============================================

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
                desc = f"📁 {item.name}"
            else:
                status = "✅" if item.script_info.installed else "⬜"
                root = "🔐" if item.script_info.root else ""
                desc = f"{status}{root} {item.name}"
            menu_items.extend([tag, desc])

        # Add navigation
        menu_items.extend(["b", "⬅️  Back"])
        menu_items.extend(["x", "❌ Exit"])

        title = " > ".join(breadcrumb)

        try:
            cmd = [
                "whiptail", "--title", title,
                "--menu", "Select an option (use arrow keys):",
                "20", "70", "12"
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
            cmd = [
                "whiptail", "--title", script_info.name,
                "--menu", info,
                "20", "70", "8"
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
                run_script(script_info, "install")  # Config scripts use install action
                input("\nPress Enter to continue...")

            elif selection == "install":
                run_script(script_info, "install")
                updated = parse_yaml_header(script_info.path)
                if updated:
                    script_info.installed = updated.installed
                input("\nPress Enter to continue...")

            elif selection == "uninstall":
                run_script(script_info, "uninstall")
                updated = parse_yaml_header(script_info.path)
                if updated:
                    script_info.installed = updated.installed
                input("\nPress Enter to continue...")

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

        def compose(self) -> ComposeResult:
            yield Header(show_clock=True)
            yield Static("📍 NinjaMenu", id="breadcrumb")
            yield OptionList(id="menu-list")
            yield Static("Use ↑↓ arrows to navigate, Enter to select, Backspace/Esc to go back, q to quit", id="info-panel")
            yield Footer()

        def on_mount(self) -> None:
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

            folder_num = 1
            for item in self.items:
                if item.is_submenu:
                    option_list.add_option(Option(f"{folder_num}. 📁 {item.name}", id=item.path.name))
                    folder_num += 1
                else:
                    status = "✅" if item.script_info.installed else "⬜"
                    root = "🔐" if item.script_info.root else "  "
                    option_list.add_option(Option(f"   {status}{root} {item.name}", id=item.path.name))

            # Add separator and back option if not at root
            if self.history:
                option_list.add_option(Separator())
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
                info_panel.update(f"📁 {item.name}\nPress Enter to open submenu")
            else:
                info_panel.update("Use ↑↓ arrows to navigate, Enter to select, Backspace/Esc to go back, q to quit")

        def on_option_list_option_highlighted(self, event: OptionList.OptionHighlighted) -> None:
            """Handle option highlight (selection change)."""
            if event.option_id == "__back__":
                self.update_info_panel(None)
                return

            # Find the highlighted item
            for item in self.items:
                if item.path.name == event.option_id:
                    self.update_info_panel(item)
                    break

        def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
            """Handle option selection (Enter key or click)."""
            if event.option_id == "__back__":
                self.action_go_back()
                return

            # Find and handle selected item
            for item in self.items:
                if item.path.name == event.option_id:
                    if item.is_submenu:
                        self.history.append(self.current_dir)
                        self.current_dir = item.path
                        self.breadcrumb.append(item.name)
                        self.refresh_menu()
                    else:
                        self.handle_script_selection(item)
                    break

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
                if option and option.id != "__back__":
                    for item in self.items:
                        if item.path.name == option.id and not item.is_submenu:
                            self.exit(result=("install", item))
                            break

        def action_uninstall(self) -> None:
            """Uninstall currently highlighted script."""
            option_list = self.query_one("#menu-list", OptionList)
            if option_list.highlighted is not None:
                option = option_list.get_option_at_index(option_list.highlighted)
                if option and option.id != "__back__":
                    for item in self.items:
                        if item.path.name == option.id and not item.is_submenu:
                            if item.script_info and item.script_info.installed:
                                self.exit(result=("uninstall", item))
                            break

        def action_view_log(self) -> None:
            """View log for currently highlighted script."""
            option_list = self.query_one("#menu-list", OptionList)
            if option_list.highlighted is not None:
                option = option_list.get_option_at_index(option_list.highlighted)
                if option and option.id != "__back__":
                    for item in self.items:
                        if item.path.name == option.id and not item.is_submenu:
                            self.exit(result=("log", item))
                            break


def run_textual_menu(start_dir: Path = None):
    """Run the Textual menu with action handling."""
    while True:
        app = NinjaMenuApp(start_dir)
        result = app.run()

        if result is None:
            break

        action, item = result

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

    args = parser.parse_args()

    # Ensure log directory exists
    LOG_DIR.mkdir(parents=True, exist_ok=True)

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

    if tui == "auto":
        # Read from config file
        config_backend = get_config_backend()

        if config_backend == "textual" and HAS_TEXTUAL:
            tui = "textual"
        elif config_backend == "gum" and gum_available():
            tui = "gum"
        elif config_backend == "whiptail":
            tui = "whiptail"
        else:
            # Fallback: gum -> whiptail -> textual
            if gum_available():
                tui = "gum"
            elif HAS_TEXTUAL:
                tui = "textual"
            else:
                tui = "whiptail"

    if tui == "gum":
        gum_menu(start_dir)
    elif tui == "textual" and HAS_TEXTUAL:
        run_textual_menu(start_dir)
    else:
        whiptail_menu(start_dir)


if __name__ == "__main__":
    main()
