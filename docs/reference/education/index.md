---
layout: default
title: Education
parent: Documentation
nav_order: 3
---

<img src="{{ '/assets/images/it_super_nerd_14213d.png' | relative_url }}" alt="IT Super Nerd" style="float: right; width: 120px; margin-left: 1rem;" />

# Education Scripts

Education scripts are **tool usage demonstrations** that teach you how to use installed tools effectively. Unlike install scripts, they don't install anything -- they require a tool to already be present and then walk you through using it.

**Location:** [`mainmenu/education/`](https://github.com/alistairhendersoninfo/ninja_toolbox/tree/main/mainmenu/education)

## How It Works

Education scripts use `type: tool` in their YAML header and declare a `binary:` dependency:

```bash
# ---
# name: "Quick Network Scan"
# description: "Fast host discovery scan on local subnet"
# type: tool
# root: false
# binary: "nmap"
# order: 10
# tags: "network, scanning, nmap"
# ---
```

The menu checks if the required binary is available:
- If found, the script shows a play icon and can be run
- If not found, the script shows a blocked icon and cannot be run

## Folder Structure

Education scripts follow a **category > tool > technique** convention:

```
mainmenu/education/
├── network/
│   ├── nmap/
│   │   └── scanning/
│   │       └── quick-scan.sh
│   └── tcpdump/
│       └── capture/
│           └── basic-capture.sh
├── monitoring/
│   └── htop/
│       └── profiling/
│           └── system-profile.sh
```

## Contributing Education Scripts

This section is actively being developed and needs contributions. See the [Contribute]({{ site.baseurl }}/contribute/) page for how to add education scripts.

Education scripts should:
1. Use `type: tool` and declare the `binary:` field
2. Source `.lib/platform.sh` and verify the binary is available
3. Provide clear output explaining what each command does
4. Be safe to run (no destructive actions without confirmation)

Use the template at `.docs/templates/tool_template.sh` as a starting point.
