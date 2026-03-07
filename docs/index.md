---
layout: home
title: Home
nav_order: 1
description: "NinjaMenu - A terminal-based menu system for Linux and macOS that puts 50+ installation scripts at your fingertips."
permalink: /
---

<div style="display: flex; align-items: center; gap: 1.5rem; margin-bottom: 1.5rem; flex-wrap: wrap;">
  <div style="background-color: #fca311; border-radius: 16px; padding: 1rem; display: inline-block;">
    <img src="{{ '/assets/images/toolbox_ninja_logo_fca311.png' | relative_url }}" alt="NinjaMenu Logo" style="width: 140px; display: block;" />
  </div>
  <div>
    <h1 style="margin: 0; font-size: 2.5rem;">NinjaMenu</h1>
    <p style="margin: 0.25rem 0 0; font-size: 1.25rem; font-weight: 300; opacity: 0.85;">Stop hunting for install commands. Start getting things done.</p>
  </div>
</div>

<img src="{{ '/assets/images/big_tracey_ninja_14213d.png' | relative_url }}" alt="Big Tracey Ninja" style="float: right; width: 120px; margin-left: 1rem;" />

[Get Started]({{ '/reference/getting-started' | relative_url }}){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/alistairhendersoninfo/ninja_toolbox){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## What is NinjaMenu?

NinjaMenu is a terminal-based menu system that transforms the chaos of setting up a Linux or macOS workstation into a streamlined, repeatable process. Whether you're configuring a fresh Kali install, spinning up a new VM, or standardising tools across your team -- NinjaMenu puts 50+ install scripts at your fingertips.

```
+------------------------------------------+
|  NinjaMenu > Monitoring                  |
|  Type number to select, b=back, x=exit   |
+------------------------------------------+

01. [installed]  htop
02. [installed]  btop
03. [  ]         glances
04. [  ] [root]  iotop
05. [installed]  ncdu
```

## The Problem

Every time you set up a new system, it's the same story:
- *"What was that package called again?"*
- *"Did I need the PPA for this one?"*
- *"Which config file do I edit?"*
- *"What tools did I even have on my old machine?"*

You end up with browser tabs everywhere, half-remembered commands, and hours lost to setup instead of actual work.

## The Solution

NinjaMenu organises your entire toolkit into a browsable, searchable menu:

- **See everything at once** -- All your tools organised by category
- **Know what's installed** -- Green checkmarks show what you've already got
- **One-key installs** -- Press a number, hit enter, done
- **Root handled automatically** -- Scripts that need sudo will ask for it
- **Completely customisable** -- Add your own scripts in minutes

## 50+ Scripts, 7 Categories

| Category | What's Inside |
|----------|---------------|
| **Monitoring** | htop, btop, glances, iotop, ncdu, neofetch, and more |
| **Network** | nmap, wireshark, tcpdump, masscan, netcat, and more |
| **LLM & AI** | Claude Code, Gemini CLI, Cursor, Antigravity |
| **Git & GitHub** | SSH setup, credential management, repo creation |
| **Post-Setup Kali** | Themes, shell fixes, Node.js, XRDP |
| **Proxmox** | VM management and helper scripts |
| **Education** | Guided tool usage scripts (coming soon) |

## Quick Start

```bash
git clone https://github.com/alistairhendersoninfo/ninja_toolbox.git
cd ninja_toolbox

# Linux (Kali/Debian/Ubuntu) -- requires sudo
sudo ./install_menu.sh

# macOS (Intel or Apple Silicon) -- do NOT use sudo
./install_menu.sh

# Launch anytime
ninjamenu
```

## Cross-Platform

Works on Linux (Kali, Debian, Ubuntu) and macOS (Intel and Apple Silicon). The shared platform library automatically handles package manager differences -- `pkg_install` uses `apt-get` on Linux and `brew` on macOS.

## Multiple Interfaces

NinjaMenu adapts to your preference:

- **gum** (default) -- Modern, stylish interface from Charm.sh
- **whiptail** -- Classic ncurses dialogs, works everywhere
- **textual** -- Full Python TUI with mouse support
