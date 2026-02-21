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
# Deploy infrastructure without requiring passwords
# Uses direct installation commands where user already has sudo access

set -e

PINK='\033[38;5;205m'
GREEN='\033[38;5;82m'
BLUE='\033[38;5;69m'
YELLOW='\033[38;5;214m'
RED='\033[38;5;196m'
RESET='\033[0m'

HOSTS="cecilia octavia"

echo -e "${PINK}🌌 BlackRoad Infrastructure Deployment (Manual Steps)${RESET}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Since sudo requires password, deploying step-by-step..."
echo ""

# Generate deployment script for each host
for host in $HOSTS; do
    cat > /tmp/deploy_${host}.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
# Deployment script - run with sudo access

set -e

echo "🚀 Starting deployment on $(hostname)..."

# System update
echo "1/7 Updating system..."
sudo apt update -qq && sudo apt upgrade -y -qq

# Install nginx
echo "2/7 Installing nginx..."
if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx
fi
sudo systemctl enable nginx
sudo systemctl start nginx || sudo systemctl restart nginx
echo "✅ nginx installed"

# Install postfix
echo "3/7 Installing postfix..."
if ! command -v postfix &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive sudo apt install -y postfix mailutils
fi
echo "✅ postfix installed"

# Install security tools
echo "4/7 Installing security tools..."
sudo apt install -y fail2ban ufw
sudo systemctl enable fail2ban
sudo systemctl start fail2ban || sudo systemctl restart fail2ban
echo "✅ fail2ban installed"

# Configure firewall
echo "5/7 Configuring firewall..."
sudo ufw --force enable || true
sudo ufw allow 22/tcp || true
sudo ufw allow 80/tcp || true
sudo ufw allow 443/tcp || true
echo "✅ firewall configured"

# Install piper-tts
echo "6/7 Installing piper-tts..."
if ! command -v piper &> /dev/null; then
    cd /tmp
    wget -q https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_arm64.tar.gz
    tar -xzf piper_arm64.tar.gz
    sudo mv piper/piper /usr/local/bin/
    rm -rf piper piper_arm64.tar.gz
fi
echo "✅ piper-tts installed"

# Download voice models
echo "7/7 Installing voice models..."
sudo mkdir -p /usr/local/share/piper
cd /usr/local/share/piper
if [ ! -f "en_US-lessac-medium.onnx" ]; then
    sudo wget -q https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx
    sudo wget -q https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json
fi
echo "✅ voice models installed"

echo ""
echo "🎉 Deployment complete on $(hostname)!"
echo ""
echo "Installed services:"
systemctl list-units --type=service --state=running | grep -E 'nginx|fail2ban|postfix' || echo "Services starting..."

DEPLOY_SCRIPT

    # Copy and execute
    echo -e "${BLUE}Deploying to $host...${RESET}"
    scp /tmp/deploy_${host}.sh $host:/tmp/deploy.sh
    ssh -t $host "chmod +x /tmp/deploy.sh && /tmp/deploy.sh"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 All deployments complete!${RESET}"
echo ""

# Verify installations
echo "Verifying installations..."
for host in $HOSTS; do
    echo ""
    echo -e "${BLUE}$host status:${RESET}"
    ssh $host "systemctl is-active nginx && echo '  ✅ nginx running' || echo '  ❌ nginx not running'"
    ssh $host "systemctl is-active fail2ban && echo '  ✅ fail2ban running' || echo '  ❌ fail2ban not running'"
    ssh $host "command -v piper && echo '  ✅ piper installed' || echo '  ❌ piper not installed'"
done

echo ""
echo "🚀 Ready for configuration phase!"
