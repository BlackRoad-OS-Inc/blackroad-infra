#!/bin/bash
# domain-nginx-gen.sh
# Generate nginx config for all BlackRoad domains → served from Pi cluster
# alice (192.168.4.49) with cloudflared tunnel is the primary entry point
#
# Architecture:
#   Internet → Cloudflare Tunnel → alice:nginx → local Pi services
#   Failover: alice down → gematria (DO) → Cloudflare Pages → GitHub Pages → Railway

set -e

NGINX_DIR="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

# Pi cluster backends
OCTAVIA_IP="192.168.4.38"
ARIA_IP="192.168.4.82"
ALICE_IP="192.168.4.49"

# All BlackRoad domains to serve
declare -A DOMAINS=(
  # Main domains → octavia (compute)
  ["blackroad.ai"]="http://${OCTAVIA_IP}:3000"
  ["blackroad.io"]="http://${OCTAVIA_IP}:3000"
  ["blackroad.network"]="http://${OCTAVIA_IP}:4000"
  ["blackroad.systems"]="http://${OCTAVIA_IP}:4000"
  ["blackroad.me"]="http://${OCTAVIA_IP}:3000"
  ["blackroad.inc"]="http://${OCTAVIA_IP}:3001"

  # Lucidia → aria (frontend)
  ["lucidia.earth"]="http://${ARIA_IP}:5000"
  ["lucidia.studio"]="http://${ARIA_IP}:5001"

  # API → octavia
  ["api.blackroad.io"]="http://${OCTAVIA_IP}:8080"
  ["agents.blackroad.io"]="http://${OCTAVIA_IP}:8787"
  ["ai.blackroad.io"]="http://${OCTAVIA_IP}:11434"

  # Prism console → aria
  ["console.blackroad.io"]="http://${ARIA_IP}:3000"
  ["dashboard.blackroad.io"]="http://${ARIA_IP}:3001"

  # Docs → aria
  ["docs.blackroad.io"]="http://${ARIA_IP}:3002"
)

generate_server_block() {
  local domain="$1"
  local upstream="$2"

  cat << EOF
server {
    listen 80;
    server_name ${domain} www.${domain};

    # Health check
    location /health {
        return 200 '{"status":"ok","host":"${domain}","pi":"$(hostname)"}';
        add_header Content-Type application/json;
    }

    location / {
        proxy_pass ${upstream};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;

        # Failover: if upstream fails, return 503 for Cloudflare to handle
        proxy_intercept_errors on;
        error_page 502 503 504 = @failover;
    }

    location @failover {
        return 302 https://\$host\$request_uri;
        # Cloudflare will serve cached version or Pages fallback
    }
}
EOF
}

# Generate all configs
echo -e "${CYAN}Generating nginx configs for ${#DOMAINS[@]} domains...${NC}"

for domain in "${!DOMAINS[@]}"; do
  upstream="${DOMAINS[$domain]}"
  config_file="${NGINX_DIR}/${domain}.conf"
  
  generate_server_block "$domain" "$upstream" | sudo tee "$config_file" > /dev/null
  sudo ln -sf "$config_file" "${NGINX_ENABLED}/${domain}.conf" 2>/dev/null || true
  echo -e "${GREEN}  ✅ ${domain} → ${upstream}${NC}"
done

# Test and reload nginx
echo -e "${CYAN}Testing nginx config...${NC}"
sudo nginx -t && sudo systemctl reload nginx \
  && echo -e "${GREEN}✅ nginx reloaded — all ${#DOMAINS[@]} domains active${NC}" \
  || echo "⚠️  nginx test failed"

# Cloudflare tunnel config
cat > /tmp/cloudflare-tunnel-config.yml << TUNNEL
tunnel: 52915859-da18-4aa6-add5-7bd9fcac2e0b
credentials-file: /root/.cloudflared/52915859-da18-4aa6-add5-7bd9fcac2e0b.json

ingress:
$(for domain in "${!DOMAINS[@]}"; do
  echo "  - hostname: ${domain}"
  echo "    service: http://localhost:80"
done)
  - service: http_status:404
TUNNEL

echo -e "${CYAN}Cloudflare tunnel config written to /tmp/cloudflare-tunnel-config.yml${NC}"
echo "Copy to alice: scp /tmp/cloudflare-tunnel-config.yml alice:/root/.cloudflared/config.yml"
echo "Then restart: ssh alice 'sudo systemctl restart cloudflared'"
