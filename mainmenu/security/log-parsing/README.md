# Log Parsing

Log analysis scripts for security tools. Each script parses logs from a specific security tool and displays a summary of events, alerts, and blocked activity.

All scripts are `type: tool` and require the relevant binary to be installed first.

## Scripts

| Script | Binary Required | Description |
|--------|----------------|-------------|
| coraza-logs.sh | nginx | Parse Coraza WAF / ModSecurity audit logs |
| nftables-logs.sh | nft | Parse nftables firewall log entries |
| falco-logs.sh | falco | Parse Falco runtime security alerts |
| auditd-logs.sh | ausearch | Parse Linux audit daemon logs |
| apparmor-logs.sh | aa-status | Parse AppArmor denial events |
| fluent-bit-logs.sh | fluent-bit | Parse Fluent Bit service logs |

## Documentation

- **User Manual:** [../../../.docs/user_manuals/security.md](../../../.docs/user_manuals/security.md)
- **Technical Manual:** [../../../.docs/technical_manuals/security.md](../../../.docs/technical_manuals/security.md)
