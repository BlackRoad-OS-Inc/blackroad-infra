#!/usr/bin/env bash
# ============================================================
#  BlackRoad — Pi Fleet Nginx Domain Router
#  Deploys nginx configs to the Pi cluster so all *.blackroad.io
#  subdomains route through your own hardware via Cloudflare tunnel.
#
#  Pi fleet:
#    blackroad-pi  192.168.4.64  (primary — cloudflared tunnel lives here)
#    aria64        192.168.4.38  (22,500 agents)
#    alice         192.168.4.49  (ops)
#    lucidia       192.168.4.99  (alternate)
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

PRIMARY_PI="pi@192.168.4.64"    # cloudflared + nginx ingress
AGENT_PI="pi@192.168.4.38"      # 22,500 agents
OPS_PI="pi@192.168.4.49"        # ops / alice
ALT_PI="pi@192.168.4.99"        # lucidia alt

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NGINX_DIR="$SCRIPT_DIR/nginx"

log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
warn() { echo -e "${AMBER}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }

# ============================================================
# 1. Install nginx on all pis (idempotent)
# ============================================================
install_nginx() {
    local host=$1
    info "Installing nginx on $host..."
    ssh "$host" "
        sudo apt-get update -qq &&
        sudo apt-get install -y nginx certbot python3-certbot-nginx -qq &&
        sudo systemctl enable nginx &&
        sudo systemctl start nginx
    " && log "nginx ready on $host" || warn "Could not reach $host"
}

# ============================================================
# 2. Upload nginx site configs to primary Pi
# ============================================================
deploy_nginx_config() {
    info "Uploading nginx configs to primary Pi ($PRIMARY_PI)..."
    
    # Upload all .conf files
    scp "$NGINX_DIR"/sites-available/*.conf "${PRIMARY_PI}:/tmp/" 2>/dev/null || true
    
    ssh "$PRIMARY_PI" "
        sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
        sudo cp /tmp/*.conf /etc/nginx/sites-available/
        
        # Enable all sites
        for f in /etc/nginx/sites-available/*.conf; do
            name=\$(basename \$f)
            sudo ln -sf \"/etc/nginx/sites-available/\$name\" \"/etc/nginx/sites-enabled/\$name\" 2>/dev/null || true
        done
        
        # Remove default if it exists
        sudo rm -f /etc/nginx/sites-enabled/default
        
        # Test config
        sudo nginx -t && sudo systemctl reload nginx && echo '✓ nginx reloaded'
    "
    log "Configs deployed and nginx reloaded"
}

# ============================================================
# 3. Update Cloudflare tunnel config to point at nginx
# ============================================================
update_tunnel_config() {
    info "Updating cloudflared tunnel config on $PRIMARY_PI..."
    
    scp "$NGINX_DIR/cloudflared-config.yml" "${PRIMARY_PI}:/tmp/config.yml"
    
    ssh "$PRIMARY_PI" "
        sudo mkdir -p /etc/cloudflared
        sudo cp /tmp/config.yml /etc/cloudflared/config.yml
        sudo systemctl restart cloudflared && echo '✓ cloudflared restarted'
    " && log "Tunnel config updated" || warn "cloudflared not running as service yet"
}

# ============================================================
# Main
# ============================================================
case "${1:-all}" in
    install)
        install_nginx "$PRIMARY_PI"
        install_nginx "$AGENT_PI"
        install_nginx "$OPS_PI"
        ;;
    deploy)
        deploy_nginx_config
        ;;
    tunnel)
        update_tunnel_config
        ;;
    all)
        echo -e "${PINK}"
        echo "  ██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗ "
        echo "  ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗"
        echo "  ██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║███████║██║  ██║"
        echo "  ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║██╔══██║██║  ██║"
        echo "  ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝██║  ██║██████╔╝"
        echo "  ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ "
        echo -e "${NC}"
        echo -e "${AMBER}  Pi Fleet Domain Router — Your domain. Your hardware. Your rules.${NC}"
        echo ""
        
        install_nginx "$PRIMARY_PI"
        deploy_nginx_config
        update_tunnel_config
        
        echo ""
        log "All done! Domains routing through your Pi fleet via nginx + cloudflared tunnel."
        echo ""
        echo -e "  ${CYAN}Traffic flow:${NC}"
        echo -e "  Internet → Cloudflare edge → cloudflared tunnel → nginx (Pi 192.168.4.64)"
        echo -e "           → upstream services on Pi fleet (192.168.4.38/49/99)"
        echo ""
        ;;
    status)
        for host in "$PRIMARY_PI" "$AGENT_PI" "$OPS_PI"; do
            echo -e "\n${CYAN}── $host ──${NC}"
            ssh "$host" "sudo systemctl status nginx --no-pager -l | head -8" 2>/dev/null || warn "unreachable"
        done
        ;;
    *)
        echo "Usage: $0 [install|deploy|tunnel|status|all]"
        ;;
esac
