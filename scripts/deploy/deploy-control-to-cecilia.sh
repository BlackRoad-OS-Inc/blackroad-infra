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
# ============================================================================
# DEPLOY BLACKROAD CONTROL TO CECILIA
# Deploys the unified control dashboard and orchestrator
# ============================================================================

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
GREEN='\033[38;5;82m'
RESET='\033[0m'

echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${AMBER}  DEPLOYING BLACKROAD CONTROL TO CECILIA${RESET}"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# 1. Deploy dashboard
echo -e "\n${AMBER}▸ Deploying dashboard...${RESET}"
rsync -avz ~/blackroad-control-dashboard/ cecilia:~/blackroad-control-dashboard/
ssh cecilia "pip3 install flask --break-system-packages 2>/dev/null || pip3 install flask"

# 2. Deploy orchestrator
echo -e "\n${AMBER}▸ Deploying orchestrator...${RESET}"
scp ~/blackroad-orchestrator.sh cecilia:~/
ssh cecilia "chmod +x ~/blackroad-orchestrator.sh"

# 3. Deploy tmux config
echo -e "\n${AMBER}▸ Deploying tmux config...${RESET}"
scp ~/.tmux-blackroad.conf cecilia:~/
scp ~/blackroad-tmux-session.sh cecilia:~/
ssh cecilia "chmod +x ~/blackroad-tmux-session.sh"

# 4. Start dashboard on cecilia
echo -e "\n${AMBER}▸ Starting dashboard on cecilia...${RESET}"
ssh cecilia "pkill -f 'python3.*app.py' 2>/dev/null || true"
ssh cecilia "cd ~/blackroad-control-dashboard && nohup python3 app.py > /tmp/blackroad-dashboard.log 2>&1 &"

# 5. Verify
sleep 2
echo -e "\n${AMBER}▸ Verifying deployment...${RESET}"
if ssh cecilia "curl -s http://localhost:8888 | head -5" | grep -q "BlackRoad"; then
    echo -e "${GREEN}✓ Dashboard running on cecilia:8888${RESET}"
else
    echo -e "Dashboard may still be starting... check in a moment"
fi

echo -e "\n${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}DEPLOYMENT COMPLETE${RESET}"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "Access dashboard at:"
echo -e "  ${AMBER}Local:${RESET}     http://192.168.4.89:8888"
echo -e "  ${AMBER}Tailscale:${RESET} http://100.72.180.98:8888"
echo ""
echo -e "Run unified tmux session:"
echo -e "  ${AMBER}ssh cecilia '~/blackroad-tmux-session.sh'${RESET}"
echo ""
echo -e "Or from local:"
echo -e "  ${AMBER}~/blackroad-tmux-session.sh${RESET}"
