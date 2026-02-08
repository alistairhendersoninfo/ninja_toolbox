---
layout: default
title: Tool Reference
parent: Documentation
nav_order: 2
has_children: true
---

# Tool Reference

NinjaMenu organises 50+ installation scripts into categories. Each category is a folder under `mainmenu/` that becomes a submenu.

| Category | Scripts | Description |
|----------|---------|-------------|
| [Monitoring]({{ site.baseurl }}/reference/tools/monitoring) | 14 | System performance, processes, disk, I/O |
| [Network]({{ site.baseurl }}/reference/tools/network) | 22 | Scanning, packet analysis, traffic monitoring |
| [LLM & AI]({{ site.baseurl }}/reference/tools/llm) | 5 | AI CLI tools and IDE extensions |
| [Git & GitHub]({{ site.baseurl }}/reference/tools/git) | 5 | SSH setup, credentials, repo management |
| [Post-Setup Kali]({{ site.baseurl }}/reference/tools/postsetup-kali) | 6 | Fresh system configuration |
| [Proxmox]({{ site.baseurl }}/reference/tools/proxmox) | 3 | Hypervisor management |

Every script uses the shared platform library (`.lib/platform.sh`) for cross-platform support and follows the standard YAML header format for menu integration.
