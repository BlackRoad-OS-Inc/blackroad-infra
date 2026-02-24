#!/usr/bin/env bash
# ============================================================
#  setup-blackroad-domain.sh
#  Run on your Mac to get https://blackroad working locally.
#
#  What it does:
#    1. brew install mkcert caddy dnsmasq
#    2. mkcert -install  →  trusted local CA in macOS Keychain
#    3. mkcert blackroad  →  TLS cert for bare "blackroad"
#    4. /etc/hosts entry  →  blackroad → 127.0.0.1
#    5. Caddyfile  →  Caddy reverse-proxies https://blackroad to Pi fleet
#    6. launchd plist  →  Caddy starts on login
#
#  After this:
#    https://blackroad  →  your Pi fleet (via local Caddy proxy)
#    On LAN devices:   run  ./scripts/pi-dnsmasq-setup.sh on Pi
#                      then point router DNS to 192.168.4.64
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; AMBER='\033[38;5;214m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
warn() { echo -e "${AMBER}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

CERTS_DIR="$HOME/.blackroad/certs"
CADDY_DIR="$HOME/.blackroad/caddy"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/io.blackroad.caddy.plist"
PI_PRIMARY="192.168.4.64"
HOSTS_ENTRY="127.0.0.1  blackroad"

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════╗"
echo "  ║   https://blackroad  Setup       ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"

# ── 1. Dependencies ───────────────────────────────────────────
info "Checking dependencies…"
if ! command -v brew &>/dev/null; then
    err "Homebrew not found. Install from https://brew.sh"
fi

for pkg in mkcert caddy; do
    if ! command -v "$pkg" &>/dev/null; then
        info "Installing $pkg…"
        brew install "$pkg"
    else
        log "$pkg already installed"
    fi
done

# ── 2. Local CA ───────────────────────────────────────────────
info "Installing local CA into macOS Keychain (may prompt for password)…"
mkcert -install
log "Local CA trusted"

# ── 3. Generate cert ──────────────────────────────────────────
mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

info "Generating TLS cert for: blackroad localhost 127.0.0.1 $PI_PRIMARY"
mkcert \
    blackroad \
    localhost \
    "127.0.0.1" \
    "$PI_PRIMARY" \
    "192.168.4.38" \
    "192.168.4.49" \
    "192.168.4.99"

# mkcert names the output files based on the first name
CERT_FILE="$CERTS_DIR/blackroad.pem"
KEY_FILE="$CERTS_DIR/blackroad-key.pem"

# mkcert uses + in filenames for multiple SANs — find and rename
GENERATED_CERT=$(ls "$CERTS_DIR"/*blackroad*.pem 2>/dev/null | grep -v key | head -1)
GENERATED_KEY=$(ls  "$CERTS_DIR"/*blackroad*-key.pem 2>/dev/null | head -1)

[[ -f "$GENERATED_CERT" ]] && mv "$GENERATED_CERT" "$CERT_FILE"
[[ -f "$GENERATED_KEY"  ]] && mv "$GENERATED_KEY"  "$KEY_FILE"

log "Cert: $CERT_FILE"
log "Key:  $KEY_FILE"

# ── 4. /etc/hosts entry ───────────────────────────────────────
if grep -q "^127\.0\.0\.1.*blackroad" /etc/hosts 2>/dev/null; then
    log "/etc/hosts already has blackroad entry"
else
    info "Adding blackroad to /etc/hosts (needs sudo)…"
    echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts > /dev/null
    log "Added: $HOSTS_ENTRY"
fi

# Flush DNS cache
sudo dscacheutil -flushcache 2>/dev/null || true
sudo killall -HUP mDNSResponder 2>/dev/null || true
log "DNS cache flushed"

# ── 5. Caddyfile ──────────────────────────────────────────────
mkdir -p "$CADDY_DIR"

cat > "$CADDY_DIR/Caddyfile" << CADDYEOF
# BlackRoad OS — local HTTPS gateway
# https://blackroad → Pi fleet (with local fallback)

blackroad {
    tls $CERT_FILE $KEY_FILE

    # Health check
    respond /_br/health 200 {
        body '{"status":"ok","host":"blackroad","tier":"local-mac"}'
        close
    }

    # Route by path prefix
    @agents  path /agents/*
    @api     path /api/*
    @ollama  path /ollama/*
    @ws      path /ws/*

    # Agents — try Pi primary, fall back to secondary
    reverse_proxy @agents $PI_PRIMARY:8080 192.168.4.38:8080 {
        lb_policy first
        fail_duration 10s
        transport http {
            dial_timeout 3s
        }
        header_up X-Forwarded-Host {host}
    }

    # Ollama LLM — streaming
    reverse_proxy @ollama $PI_PRIMARY:11434 192.168.4.38:11434 {
        lb_policy first
        fail_duration 10s
        flush_interval -1
        transport http {
            dial_timeout 5s
            response_header_timeout 600s
        }
    }

    # API
    reverse_proxy @api $PI_PRIMARY:3000 192.168.4.38:3000 {
        lb_policy first
        fail_duration 10s
    }

    # Default — dashboard
    reverse_proxy $PI_PRIMARY:4000 192.168.4.38:4000 {
        lb_policy first
        fail_duration 10s
        transport http {
            dial_timeout 3s
        }
        # Fallback to local if Pi is unreachable
    }
}
CADDYEOF

log "Caddyfile written: $CADDY_DIR/Caddyfile"

# ── 6. launchd service (Caddy starts on login) ────────────────
cat > "$LAUNCHD_PLIST" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>io.blackroad.caddy</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(which caddy)</string>
        <string>run</string>
        <string>--config</string>
        <string>$CADDY_DIR/Caddyfile</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/.blackroad/logs/caddy.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.blackroad/logs/caddy-error.log</string>
    <key>WorkingDirectory</key>
    <string>$CADDY_DIR</string>
</dict>
</plist>
PLISTEOF

mkdir -p "$HOME/.blackroad/logs"

# (Re)load launchd service
launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
launchctl load   "$LAUNCHD_PLIST"

log "Caddy launchd service loaded"

# ── 7. Verify ─────────────────────────────────────────────────
echo
info "Waiting for Caddy to start…"
sleep 2

if curl -sk https://blackroad/_br/health | grep -q "ok"; then
    log "https://blackroad is UP ✓"
else
    warn "Caddy may not be ready yet — check: tail -f ~/.blackroad/logs/caddy-error.log"
fi

# ── Done ──────────────────────────────────────────────────────
echo
echo -e "${BOLD}${GREEN}Done!${NC}"
echo
echo -e "  ${BOLD}https://blackroad${NC}        → Pi fleet (your OS)"
echo -e "  ${BOLD}https://blackroad/api/${NC}   → API :3000"
echo -e "  ${BOLD}https://blackroad/agents/${NC}→ Agents :8080"
echo -e "  ${BOLD}https://blackroad/ollama/${NC}→ Ollama :11434"
echo
echo "  Cert:    $CERT_FILE"
echo "  Caddy:   $CADDY_DIR/Caddyfile"
echo "  Logs:    ~/.blackroad/logs/caddy.log"
echo
echo -e "  ${CYAN}For LAN devices (iPhone etc):${NC}"
echo "    1. SSH to Pi: ssh pi@192.168.4.64"
echo "    2. Run: ./scripts/pi-dnsmasq-setup.sh"
echo "    3. In router DHCP: set DNS server → 192.168.4.64"
echo "    4. Install root CA on iPhone: https://blackroad.io/ca.crt"
