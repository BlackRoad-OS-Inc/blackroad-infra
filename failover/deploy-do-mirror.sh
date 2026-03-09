#!/usr/bin/env bash
# ============================================================
#  BlackRoad — Tier 2 Failover: DigitalOcean nginx mirror
#  Syncs same nginx config from Pi to droplet 159.65.43.12
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; AMBER='\033[38;5;214m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

DROPLET="blackroad@159.65.43.12"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NGINX_DIR="$SCRIPT_DIR/nginx"

info "Deploying nginx to DigitalOcean droplet ($DROPLET)..."

# 1. Install nginx on droplet
ssh "$DROPLET" "
    apt-get update -qq
    apt-get install -y nginx -qq
    systemctl enable nginx
    systemctl start nginx
    echo '✓ nginx installed'
"

# 2. Upload configs
scp "$NGINX_DIR/sites-available/blackroad.io.conf" "$DROPLET:/tmp/"

# 3. Adjust upstream IPs for droplet context
#    Pi fleet IPs are LAN — on droplet we use DO-specific upstreams or same external URLs
ssh "$DROPLET" "
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

    # On droplet, upstream 127.0.0.1 = services running on this droplet
    cp /tmp/blackroad.io.conf /etc/nginx/sites-available/blackroad.io.conf
    ln -sf /etc/nginx/sites-available/blackroad.io.conf /etc/nginx/sites-enabled/blackroad.io.conf
    rm -f /etc/nginx/sites-enabled/default

    nginx -t && systemctl reload nginx
    echo '✓ nginx configured and running'
"

# 4. Add a /health endpoint (nginx returns 200 with JSON)
ssh "$DROPLET" "
cat > /etc/nginx/sites-available/health.conf << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    location /health {
        default_type application/json;
        return 200 '{\"status\":\"up\",\"tier\":2,\"host\":\"digitalocean\"}';
    }
}
EOF
ln -sf /etc/nginx/sites-available/health.conf /etc/nginx/sites-enabled/health.conf
nginx -t && systemctl reload nginx
echo '✓ /health endpoint active'
"

log "DigitalOcean nginx mirror ready at http://159.65.43.12"
log "Tier 2 failover: active"
