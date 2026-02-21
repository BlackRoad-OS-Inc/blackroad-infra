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
# Mass Infrastructure Deployment Script
# Deploys nginx, postfix, TTS, and security hardening to all Pis

set -e

PINK='\033[38;5;205m'
GREEN='\033[38;5;82m'
BLUE='\033[38;5;69m'
YELLOW='\033[38;5;214m'
RED='\033[38;5;196m'
RESET='\033[0m'

# Target hosts (excluding alice which is offline)
HOSTS="cecilia octavia"

echo -e "${PINK}🌌 BlackRoad Mass Infrastructure Deployment${RESET}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to run command on all hosts
run_on_all() {
    local cmd="$1"
    local desc="$2"
    
    echo -e "${BLUE}📡 $desc${RESET}"
    for host in $HOSTS; do
        echo -n "  $host: "
        ssh $host "$cmd" && echo -e "${GREEN}✅${RESET}" || echo -e "${RED}❌${RESET}"
    done
    echo ""
}

# Phase 1: System Updates
echo -e "${YELLOW}[1/7] System Updates${RESET}"
run_on_all "sudo apt update -qq && sudo apt upgrade -y -qq" "Updating packages"

# Phase 2: Install nginx
echo -e "${YELLOW}[2/7] nginx Installation${RESET}"
run_on_all "command -v nginx || sudo apt install -y nginx" "Installing nginx"
run_on_all "sudo systemctl enable nginx && sudo systemctl start nginx" "Enabling nginx"

# Phase 3: Install postfix (non-interactive)
echo -e "${YELLOW}[3/7] Postfix Installation${RESET}"
run_on_all "DEBIAN_FRONTEND=noninteractive sudo apt install -y postfix mailutils" "Installing postfix"

# Phase 4: Install fail2ban
echo -e "${YELLOW}[4/7] Security Tools${RESET}"
run_on_all "sudo apt install -y fail2ban ufw" "Installing fail2ban + ufw"
run_on_all "sudo systemctl enable fail2ban && sudo systemctl start fail2ban" "Enabling fail2ban"

# Phase 5: Configure firewall
echo -e "${YELLOW}[5/7] Firewall Configuration${RESET}"
run_on_all "sudo ufw --force enable" "Enabling ufw"
run_on_all "sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp" "Opening ports"

# Phase 6: Install piper-tts
echo -e "${YELLOW}[6/7] TTS Installation${RESET}"
echo "  Downloading piper-tts..."
for host in $HOSTS; do
    echo -n "  $host: "
    ssh $host "cd /tmp && \
        wget -q https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_arm64.tar.gz && \
        tar -xzf piper_arm64.tar.gz && \
        sudo mv piper/piper /usr/local/bin/ && \
        rm -rf piper piper_arm64.tar.gz" && \
    echo -e "${GREEN}✅${RESET}" || echo -e "${RED}❌${RESET}"
done
echo ""

# Phase 7: Download TTS voice model
echo -e "${YELLOW}[7/7] TTS Voice Models${RESET}"
echo "  Downloading voice models..."
for host in $HOSTS; do
    echo -n "  $host: "
    ssh $host "sudo mkdir -p /usr/local/share/piper && \
        cd /usr/local/share/piper && \
        sudo wget -q https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx && \
        sudo wget -q https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json" && \
    echo -e "${GREEN}✅${RESET}" || echo -e "${RED}❌${RESET}"
done
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Mass deployment complete!${RESET}"
echo ""
echo "Installed on all Pis:"
echo "  ✅ nginx (web server)"
echo "  ✅ postfix (email relay)"
echo "  ✅ fail2ban (intrusion prevention)"
echo "  ✅ ufw (firewall)"
echo "  ✅ piper (TTS engine)"
echo "  ✅ Voice models (en_US lessac)"
echo ""
echo "Next steps:"
echo "  1. Configure nginx virtual hosts"
echo "  2. Set up postfix SMTP relay"
echo "  3. Create TTS API service"
echo "  4. Deploy www.blackroad.io content"
echo "  5. Configure Cloudflare tunnels"
echo ""
