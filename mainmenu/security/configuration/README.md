# Security Configuration

Security hardening profiles from light to extreme for nginx and nftables.

## Scripts

| Script | Description | Type |
|--------|-------------|------|
| Nginx Light Hardening | Basic security headers and server token hiding | config |
| Nginx Moderate Hardening | Rate limiting, SSL hardening, and security headers | config |
| Nginx Extreme Hardening | Full lockdown with HSTS, WAF, bot blocking, and attack filtering | config |
| nftables Basic Firewall | Basic firewall rules allowing SSH, HTTP, HTTPS inbound | config |
| nftables Hardened Firewall | Hardened firewall with SYN flood protection and rate limiting | config |

## Quick Start

```bash
ninjamenu
# Navigate to: Security -> Configuration -> pick a hardening level
```

## Nginx Hardening Levels

The three nginx profiles are cumulative. Each higher level supersedes and removes the lower config:

- **Light** -- Hides server version, adds X-Content-Type-Options and X-Frame-Options, disables autoindex
- **Moderate** -- All light protections plus rate limiting, TLS 1.2+ enforcement, strong ciphers, Referrer-Policy, Permissions-Policy, basic CSP, HTTP method restriction
- **Extreme** -- All moderate protections plus HSTS with preload, strict CSP, ModSecurity/Coraza placeholder, bot/scanner blocking, attack pattern filtering, request size limits, connection limits, GeoIP blocking placeholder

## nftables Firewall Levels

- **Basic** -- Allow SSH/HTTP/HTTPS inbound, DNS/HTTP/HTTPS/NTP outbound, drop everything else
- **Hardened** -- All basic rules plus SYN flood protection, SSH rate limiting (3/min), HTTP rate limiting (25/sec), ICMP throttling, christmas tree/null packet blocking, dropped packet logging

## Requirements

- Nginx must be installed before running nginx hardening scripts
- nftables must be installed before running firewall scripts
- Root access required for all scripts

## Documentation

- [User Guide](../../../.docs/user_manuals/security.md) - Usage instructions
- [Technical Manual](../../../.docs/technical_manuals/security.md) - Developer docs

## Tags

`security` `nginx` `nftables` `firewall` `hardening` `ssl` `hsts` `waf`
