#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="nginx"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install it first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

run() {
    log_info "Nginx — WAF Rules (Coraza / ModSecurity) Reference"
    log_info "Displays example Web Application Firewall rules for common attack vectors."
    log_info "Compatible with Coraza WAF (nginx module) and ModSecurity v3."
    echo ""

    # --- Overview ------------------------------------------------------------
    log_step "WAF Architecture Overview"
    echo ""
    cat <<'OVERVIEW'
Coraza WAF (or ModSecurity v3) runs as an nginx module that inspects every
request and response against a set of rules. The OWASP Core Rule Set (CRS)
provides a baseline; custom rules extend it for your application.

Files:
  /etc/nginx/modsecurity/modsecurity.conf      — Main engine config
  /etc/nginx/modsecurity/crs-setup.conf         — OWASP CRS tuning
  /etc/nginx/modsecurity/rules/*.conf           — OWASP CRS rule files
  /etc/nginx/modsecurity/custom-rules.conf      — YOUR custom rules (below)

nginx.conf snippet to enable:
  modsecurity on;
  modsecurity_rules_file /etc/nginx/modsecurity/modsecurity.conf;
OVERVIEW
    echo ""

    # --- SQL Injection -------------------------------------------------------
    log_step "1. SQL Injection Blocking"
    echo ""
    cat <<'SQLI'
# --- SQL Injection — custom patterns beyond CRS coverage ---
# File: /etc/nginx/modsecurity/custom-rules.conf

# Block UNION-based injection in query strings
SecRule ARGS "@rx (?i:union\s+(all\s+)?select)" \
    "id:100001,\
     phase:2,\
     deny,\
     status:403,\
     log,\
     msg:'SQL Injection — UNION SELECT detected',\
     tag:'attack-sqli',\
     severity:'CRITICAL'"

# Block stacked queries (semicolon followed by SQL keyword)
SecRule ARGS "@rx (?i:;\s*(drop|alter|create|truncate|insert|update|delete)\b)" \
    "id:100002,\
     phase:2,\
     deny,\
     status:403,\
     log,\
     msg:'SQL Injection — stacked query detected',\
     tag:'attack-sqli',\
     severity:'CRITICAL'"

# Block SQL comment sequences used to bypass filters
SecRule ARGS "@rx (/\*!?|\*/|--\s)" \
    "id:100003,\
     phase:2,\
     deny,\
     status:403,\
     log,\
     msg:'SQL Injection — comment sequence detected',\
     tag:'attack-sqli',\
     severity:'WARNING'"
SQLI
    echo ""

    # --- XSS -----------------------------------------------------------------
    log_step "2. Cross-Site Scripting (XSS) Blocking"
    echo ""
    cat <<'XSS'
# --- XSS — catch patterns that CRS may miss in specific contexts ---

# Block script tags in any argument
SecRule ARGS "@rx (?i:<script[^>]*>)" \
    "id:100010,\
     phase:2,\
     deny,\
     status:403,\
     log,\
     msg:'XSS — script tag detected',\
     tag:'attack-xss',\
     severity:'CRITICAL'"

# Block javascript: protocol in href/src attributes
SecRule ARGS "@rx (?i:javascript\s*:)" \
    "id:100011,\
     phase:2,\
     deny,\
     status:403,\
     log,\
     msg:'XSS — javascript: protocol detected',\
     tag:'attack-xss',\
     severity:'CRITICAL'"

# Block event handlers (onerror, onload, onclick, etc.)
SecRule ARGS "@rx (?i:\bon\w+\s*=)" \
    "id:100012,\
     phase:2,\
     deny,\
     status:403,\
     log,\
     msg:'XSS — inline event handler detected',\
     tag:'attack-xss',\
     severity:'HIGH'"
XSS
    echo ""

    # --- Remote File Inclusion -----------------------------------------------
    log_step "3. Remote File Inclusion (RFI) Blocking"
    echo ""
    cat <<'RFI'
# --- RFI — block attempts to include remote resources ---

# Block http:// and https:// in parameter values
SecRule ARGS "@rx (?i:https?://)" \
    "id:100020,\
     phase:2,\
     deny,\
     status:403,\
     log,\
     msg:'RFI — remote URL in parameter',\
     tag:'attack-rfi',\
     severity:'CRITICAL'"

# Block PHP wrappers (php://input, php://filter, data://, etc.)
SecRule ARGS "@rx (?i:(php|data|expect|zip|phar)://)" \
    "id:100021,\
     phase:2,\
     deny,\
     status:403,\
     log,\
     msg:'RFI — PHP stream wrapper detected',\
     tag:'attack-rfi',\
     severity:'CRITICAL'"

# Block path traversal sequences
SecRule ARGS "@rx (\.\./|\.\.\\\\)" \
    "id:100022,\
     phase:2,\
     deny,\
     status:403,\
     log,\
     msg:'RFI/LFI — path traversal detected',\
     tag:'attack-lfi',\
     severity:'HIGH'"
RFI
    echo ""

    # --- Scanner/Bot Blocking ------------------------------------------------
    log_step "4. Scanner and Bot Blocking"
    echo ""
    cat <<'BOTS'
# --- Scanner/Bot blocking — block known malicious user agents ---

# Block common vulnerability scanners
SecRule REQUEST_HEADERS:User-Agent "@rx (?i:(nikto|sqlmap|nessus|openvas|w3af|acunetix|netsparker|burpsuite|dirbuster|gobuster|wfuzz|ffuf))" \
    "id:100030,\
     phase:1,\
     deny,\
     status:403,\
     log,\
     msg:'Scanner — known vulnerability scanner detected',\
     tag:'automation-scanner',\
     severity:'CRITICAL'"

# Block empty user agents (often used by scripts/bots)
SecRule REQUEST_HEADERS:User-Agent "@rx ^$" \
    "id:100031,\
     phase:1,\
     deny,\
     status:403,\
     log,\
     msg:'Bot — empty User-Agent',\
     tag:'automation-bot',\
     severity:'WARNING'"

# Block requests to common probe paths
SecRule REQUEST_URI "@rx (?i:(wp-login\.php|wp-admin|xmlrpc\.php|/\.env|/\.git|phpmyadmin|/actuator|/api/v1/debug))" \
    "id:100032,\
     phase:1,\
     deny,\
     status:403,\
     log,\
     msg:'Scanner — probe path detected',\
     tag:'automation-scanner',\
     severity:'HIGH'"
BOTS
    echo ""

    # --- Rate Limiting -------------------------------------------------------
    log_step "5. Rate Limiting (nginx native + WAF)"
    echo ""
    cat <<'RATE'
# --- Rate limiting — combine nginx native limits with WAF rules ---

# In nginx.conf http {} block, define a rate-limit zone:
#
#   limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
#   limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;
#
# In your server block:
#
#   location /api/ {
#       limit_req zone=api_limit burst=20 nodelay;
#       limit_req_status 429;
#   }
#
#   location /login {
#       limit_req zone=login_limit burst=3 nodelay;
#       limit_req_status 429;
#   }

# WAF rule: block IPs that hit rate limits repeatedly (ban after 5 429s in 60s)
# This requires ModSecurity persistent storage (SecDataDir)
SecRule RESPONSE_STATUS "@eq 429" \
    "id:100040,\
     phase:5,\
     pass,\
     log,\
     msg:'Rate limit hit — tracking IP',\
     tag:'rate-limit',\
     setvar:'ip.rate_limit_count=+1',\
     expirevar:'ip.rate_limit_count=60'"

SecRule IP:RATE_LIMIT_COUNT "@ge 5" \
    "id:100041,\
     phase:1,\
     deny,\
     status:403,\
     log,\
     msg:'Rate limit — IP temporarily banned after repeated 429s',\
     tag:'rate-limit',\
     severity:'HIGH'"
RATE
    echo ""

    # --- Summary -------------------------------------------------------------
    log_step "Putting it all together"
    echo ""
    cat <<'SUMMARY'
To deploy these rules:

  1. Install Coraza WAF module (or ModSecurity v3 + connector):
     sudo apt install libnginx-mod-http-modsecurity   # Debian/Ubuntu
     # or compile Coraza from source for latest features

  2. Enable in nginx.conf:
     modsecurity on;
     modsecurity_rules_file /etc/nginx/modsecurity/modsecurity.conf;

  3. Download OWASP CRS:
     cd /etc/nginx/modsecurity
     git clone https://github.com/coreruleset/coreruleset.git rules
     cp rules/crs-setup.conf.example crs-setup.conf

  4. Add custom rules:
     Copy the rules above into /etc/nginx/modsecurity/custom-rules.conf
     Include it from modsecurity.conf:
       Include /etc/nginx/modsecurity/custom-rules.conf

  5. Test and reload:
     sudo nginx -t && sudo systemctl reload nginx

  6. Monitor logs:
     tail -f /var/log/nginx/modsec_audit.log

TIP: Start in DetectionOnly mode (SecRuleEngine DetectionOnly) to audit
before switching to enforcement (SecRuleEngine On).
SUMMARY
    echo ""

    log_success "WAF rules reference display complete."
}

run
