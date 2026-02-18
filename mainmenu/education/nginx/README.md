# Nginx Configuration

Example nginx config generators with replaceable placeholders. Each script prompts for values, generates a production-quality config, and displays it on stdout. Optionally writes the config to the appropriate location under `/etc/nginx/`.

All scripts require `nginx` to be installed (they are `type: tool` with `binary: nginx`).

## Scripts

| Script | Description |
|--------|-------------|
| [basic-server.sh](basic-server.sh) | Generate a standard virtual-host server block with document root, logging, dotfile protection, and static-asset caching |
| [reverse-proxy.sh](reverse-proxy.sh) | Generate a reverse-proxy config with upstream block, full proxy headers, WebSocket upgrade support, and buffering tuning |
| [ssl-termination.sh](ssl-termination.sh) | Generate an HTTPS config with TLS 1.2+, strong ciphers, OCSP stapling, session caching, HSTS, and HTTP-to-HTTPS redirect |
| [security-headers.sh](security-headers.sh) | Generate a reusable snippet with X-Frame-Options, X-Content-Type-Options, CSP (basic or strict), HSTS, Permissions-Policy, and more |
| [waf-rules.sh](waf-rules.sh) | Display Coraza/ModSecurity WAF rule examples for SQL injection, XSS, RFI, scanner blocking, and rate limiting |

## Usage

From the NinjaMenu TUI, navigate to **Education > Nginx Configuration** and select a script. Alternatively, run directly:

```bash
bash mainmenu/education/nginx/basic-server.sh
```

## Documentation

- User manual: [.docs/user_manuals/nginx.md](../../../.docs/user_manuals/nginx.md)
- Technical manual: [.docs/technical_manuals/nginx.md](../../../.docs/technical_manuals/nginx.md)
