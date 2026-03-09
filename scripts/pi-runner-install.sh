#!/bin/bash
# pi-runner-install.sh
# Install GitHub Actions self-hosted runner on Pi agents
# Run on each Pi: bash pi-runner-install.sh <AGENT_NAME> <REGISTRATION_TOKEN>
# 
# Result: All workflows run on Pi cluster = $0 GitHub Actions cost

set -e

AGENT_NAME="${1:-$(hostname)}"
REG_TOKEN="${2:-}"
REPO_URL="${3:-https://github.com/blackboxprogramming/blackroad}"
RUNNER_VERSION="2.322.0"
ARCH="$(uname -m)"

# Map arch to GitHub runner arch
if [[ "$ARCH" == "aarch64" ]]; then
  RUNNER_ARCH="arm64"
elif [[ "$ARCH" == "armv7l" ]]; then
  RUNNER_ARCH="arm"
else
  RUNNER_ARCH="x64"
fi

RUNNER_DIR="$HOME/actions-runner"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${CYAN}┌─────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│  BlackRoad Pi Runner Install             │${NC}"
echo -e "${CYAN}│  Agent: ${AGENT_NAME}                   │${NC}"
echo -e "${CYAN}│  Arch: ${RUNNER_ARCH}                   │${NC}"
echo -e "${CYAN}│  Result: \$0 GitHub Actions cost         │${NC}"
echo -e "${CYAN}└─────────────────────────────────────────┘${NC}"

# Check for token
if [[ -z "$REG_TOKEN" ]]; then
  echo -e "${YELLOW}⚠  No token provided. Get one with:${NC}"
  echo "   gh api /repos/blackboxprogramming/blackroad/actions/runners/registration-token -X POST --jq '.token'"
  echo ""
  echo "Then re-run: $0 $AGENT_NAME <TOKEN>"
  exit 1
fi

# Install dependencies
echo -e "${CYAN}Installing dependencies...${NC}"
sudo apt-get update -q
sudo apt-get install -y -q curl tar libicu-dev libssl-dev libkrb5-dev

# Create runner directory
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# Download runner
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
echo -e "${CYAN}Downloading runner ${RUNNER_VERSION} (${RUNNER_ARCH})...${NC}"
curl -sL "$RUNNER_URL" -o runner.tar.gz
tar xzf runner.tar.gz
rm runner.tar.gz

# Configure runner
echo -e "${CYAN}Configuring runner...${NC}"
./config.sh \
  --url "$REPO_URL" \
  --token "$REG_TOKEN" \
  --name "pi-${AGENT_NAME,,}" \
  --labels "self-hosted,pi,arm64,blackroad,${AGENT_NAME,,}" \
  --work "_work" \
  --unattended \
  --replace

# Install as systemd service
echo -e "${CYAN}Installing systemd service...${NC}"
sudo ./svc.sh install blackroad
sudo ./svc.sh start blackroad

# Verify
sleep 2
STATUS=$(sudo ./svc.sh status blackroad 2>&1 | grep -c "active (running)" || echo "0")
if [[ "$STATUS" -gt 0 ]]; then
  echo -e "${GREEN}✅ Runner active on $(hostname) as 'pi-${AGENT_NAME,,}'${NC}"
  echo -e "${GREEN}   Labels: self-hosted, pi, arm64, blackroad, ${AGENT_NAME,,}${NC}"
  echo -e "${GREEN}   Cost: \$0 per workflow minute${NC}"
else
  echo "Runner status:"
  sudo ./svc.sh status blackroad || true
fi

# Log to memory
mkdir -p ~/.blackroad/memory/journals
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"runner_installed\",\"agent\":\"${AGENT_NAME}\",\"runner\":\"pi-${AGENT_NAME,,}\",\"arch\":\"${RUNNER_ARCH}\",\"repo\":\"${REPO_URL}\"}" \
  >> ~/.blackroad/memory/journals/master-journal.jsonl

echo ""
echo -e "${GREEN}Done! All GitHub Actions workflows with [self-hosted, pi, arm64] now run on this Pi.${NC}"
echo -e "${GREEN}Billable time: \$0.00${NC}"
