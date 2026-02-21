#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# Deploy Cloudflare Tunnel configs for TTS and Monitoring services
# Uses cloudflared tunnel route dns commands

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RESET='\033[0m'

echo -e "${PINK}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║   🌐 BlackRoad Cloudflare Tunnel Deployment           ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Create tunnel config for octavia user space
TUNNEL_CONFIG="$HOME/.cloudflared/config.yml"
echo -e "${BLUE}📝 Creating tunnel config at: $TUNNEL_CONFIG${RESET}"

# Create directory
ssh octavia "mkdir -p ~/.cloudflared"

# Generate tunnel config
cat > /tmp/cloudflared-config.yml << 'EOF'
tunnel: blackroad-octavia
credentials-file: /home/operator/.cloudflared/credentials.json

ingress:
  # TTS API
  - hostname: tts.blackroad.io
    service: http://localhost:5001
    originRequest:
      noTLSVerify: true
  
  # Monitoring Dashboard
  - hostname: monitor.blackroad.io
    service: http://localhost:5002
    originRequest:
      noTLSVerify: true
  
  # Website
  - hostname: www.blackroad.io
    service: http://localhost:80
    originRequest:
      noTLSVerify: true
  
  # Catch-all
  - service: http_status:404
EOF

echo -e "${GREEN}✅ Tunnel config created${RESET}"
echo ""

# Copy config to octavia
scp /tmp/cloudflared-config.yml octavia:~/.cloudflared/config.yml
echo -e "${GREEN}✅ Config deployed to octavia${RESET}"
echo ""

# Show DNS records needed
echo -e "${AMBER}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${AMBER}║   📋 DNS Records Needed (Cloudflare Dashboard)        ║${RESET}"
echo -e "${AMBER}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Type: CNAME | Name: tts | Target: <tunnel-id>.cfargotunnel.com"
echo "Type: CNAME | Name: monitor | Target: <tunnel-id>.cfargotunnel.com"
echo "Type: CNAME | Name: www | Target: <tunnel-id>.cfargotunnel.com"
echo ""

# Test local services
echo -e "${BLUE}🧪 Testing local services...${RESET}"
echo ""

echo -n "TTS API (5001): "
ssh octavia "curl -s http://localhost:5001/health | jq -r .status 2>/dev/null || echo 'FAIL'"

echo -n "Monitor API (5002): "
ssh octavia "curl -s http://localhost:5002/health | jq -r .status 2>/dev/null || echo 'FAIL'"

echo -n "Nginx (80): "
ssh octavia "curl -s -o /dev/null -w '%{http_code}' http://localhost:80 2>/dev/null"
echo ""

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✅ Tunnel Config Deployed!                           ║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Next steps:"
echo "1. Get tunnel ID: ssh octavia 'cloudflared tunnel list'"
echo "2. Add DNS records in Cloudflare dashboard"
echo "3. Restart: ssh octavia 'systemctl --user restart cloudflared'"
echo ""
