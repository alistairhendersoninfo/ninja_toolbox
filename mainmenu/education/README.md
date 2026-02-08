# Education Scripts

This section contains **tool scripts** — educational, demonstration, and automation scripts that use tools installed via the NinjaMenu toolbox.

## How It Works

Each script declares a `binary:` field in its YAML header specifying which tool it requires. The menu checks if that binary is installed:

- **▶️** = Binary found, script is ready to run
- **⛔** = Binary not found, script is blocked (install the tool first)

## Folder Structure

Scripts are organised by **category > tool > technique**:

```
education/
├── network/
│   ├── nmap/
│   │   ├── scanning/          # Host discovery, port scanning
│   │   ├── footprinting/      # OS detection, service enumeration
│   │   └── vulnerability/     # Vulnerability scanning
│   └── wireshark/
│       ├── capture/           # Packet capture techniques
│       └── analysis/          # Traffic analysis
└── monitoring/
    └── htop/
        └── usage/             # Process management examples
```

### Conventions

| Level | Rule |
|-------|------|
| **Category** | Must match an existing toolbox category (`network`, `monitoring`, `llm`, etc.) |
| **Tool** | Named after the binary (e.g., `nmap`, `wireshark`, `htop`) |
| **Technique** | Groups scripts by purpose (e.g., `scanning`, `capture`, `analysis`) |

## Adding a Script

1. Copy `.docs/templates/tool_template.sh` into the correct technique folder
2. Set `binary:` to the required command name (e.g., `"nmap"`)
3. Set `type: tool` in the YAML header
4. Write your script logic in the `run()` function

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for full details.
