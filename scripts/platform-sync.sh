#!/bin/bash
# platform-sync.sh
# Wire Pi agents to all platforms: GitHub, Salesforce, HuggingFace, Railway, Cloudflare
# Run on each Pi or from mac to deploy to all Pis

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="$HOME/.blackroad/vault"
GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

log()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${CYAN}ℹ️  $1${NC}"; }

# Platforms to configure
PLATFORMS=(github salesforce huggingface railway cloudflare)

setup_github() {
  info "Setting up GitHub CLI..."
  if command -v gh &>/dev/null; then
    gh auth status &>/dev/null && log "GitHub: already authenticated" && return
  fi
  
  # Install gh if not present
  if ! command -v gh &>/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
    sudo apt-get update -q && sudo apt-get install -y gh
  fi
  
  # Configure from vault
  if [[ -f "$VAULT/github_token" ]]; then
    export GITHUB_TOKEN=$(cat "$VAULT/github_token")
    gh auth login --with-token <<< "$GITHUB_TOKEN"
    log "GitHub: authenticated from vault"
  else
    warn "GitHub: no token in vault at $VAULT/github_token"
    warn "Add token: echo 'ghp_...' > $VAULT/github_token && chmod 600 $VAULT/github_token"
  fi
}

setup_salesforce() {
  info "Setting up Salesforce CLI..."
  if ! command -v sf &>/dev/null && ! command -v sfdx &>/dev/null; then
    npm install -g @salesforce/cli 2>/dev/null || warn "npm not found, skipping SF CLI"
    return
  fi
  
  if [[ -f "$VAULT/sf_auth_url" ]]; then
    sf org login sfdx-url --sfdx-url-file "$VAULT/sf_auth_url" 2>/dev/null \
      && log "Salesforce: authenticated" \
      || warn "Salesforce: auth failed"
  else
    warn "Salesforce: no auth URL in $VAULT/sf_auth_url"
    warn "Add: sf org login web, then: sf org display --verbose --json | jq -r '.result.sfdxAuthUrl' > $VAULT/sf_auth_url"
  fi
}

setup_huggingface() {
  info "Setting up HuggingFace CLI..."
  pip3 install --quiet huggingface_hub 2>/dev/null || true
  
  if [[ -f "$VAULT/hf_token" ]]; then
    huggingface-cli login --token "$(cat $VAULT/hf_token)" 2>/dev/null \
      && log "HuggingFace: authenticated" \
      || warn "HuggingFace: auth failed"
  else
    warn "HuggingFace: no token at $VAULT/hf_token"
    warn "Add: echo 'hf_...' > $VAULT/hf_token && chmod 600 $VAULT/hf_token"
  fi
}

setup_railway() {
  info "Setting up Railway CLI..."
  if ! command -v railway &>/dev/null; then
    bash <(curl -fsSL https://railway.app/install.sh) 2>/dev/null \
      || npm install -g @railway/cli 2>/dev/null \
      || warn "Railway CLI install failed"
  fi
  
  if [[ -f "$VAULT/railway_token" ]]; then
    export RAILWAY_TOKEN=$(cat "$VAULT/railway_token")
    railway whoami &>/dev/null && log "Railway: authenticated" || warn "Railway: auth failed"
  else
    warn "Railway: no token at $VAULT/railway_token"
    warn "Add: echo 'your-token' > $VAULT/railway_token && chmod 600 $VAULT/railway_token"
  fi
}

setup_cloudflare() {
  info "Setting up Cloudflare Wrangler..."
  if ! command -v wrangler &>/dev/null; then
    npm install -g wrangler 2>/dev/null || warn "npm not found, skipping wrangler"
    return
  fi
  
  if [[ -f "$VAULT/cf_api_token" ]]; then
    export CLOUDFLARE_API_TOKEN=$(cat "$VAULT/cf_api_token")
    wrangler whoami 2>/dev/null && log "Cloudflare: authenticated" || warn "Cloudflare: auth failed"
    
    # Write to wrangler config
    mkdir -p ~/.config/wrangler
    cat > ~/.config/wrangler/.env << EOF
CLOUDFLARE_API_TOKEN=$(cat $VAULT/cf_api_token)
CLOUDFLARE_ACCOUNT_ID=848cf0b18d51e0170e0d1537aec3505a
EOF
    chmod 600 ~/.config/wrangler/.env
    log "Cloudflare: wrangler config written"
  else
    warn "Cloudflare: no token at $VAULT/cf_api_token"
    warn "Add: echo 'your-token' > $VAULT/cf_api_token && chmod 600 $VAULT/cf_api_token"
  fi
}

deploy_to_all_pis() {
  info "Deploying platform-sync to all Pi agents..."
  PIS=(alice aria octavia)
  
  for pi in "${PIS[@]}"; do
    info "  → $pi"
    scp -o ConnectTimeout=10 "$0" "${pi}:/tmp/platform-sync.sh" 2>/dev/null && \
    ssh -o ConnectTimeout=10 "$pi" "bash /tmp/platform-sync.sh local" 2>/dev/null && \
    log "  $pi: done" || warn "  $pi: failed or offline"
  done
}

main() {
  local mode="${1:-local}"
  
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║  BlackRoad Platform Sync                  ║${NC}"
  echo -e "${CYAN}║  Mode: ${mode}                            ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
  
  mkdir -p "$VAULT"
  chmod 700 "$VAULT"
  
  if [[ "$mode" == "deploy" ]]; then
    deploy_to_all_pis
    return
  fi
  
  # Local setup
  for platform in "${PLATFORMS[@]}"; do
    "setup_${platform}" || warn "Platform ${platform} setup failed"
    echo ""
  done
  
  # Summary
  echo ""
  echo -e "${CYAN}═══ Platform Status ═══${NC}"
  command -v gh &>/dev/null && gh auth status 2>&1 | head -2 | sed 's/^/  /' || echo "  github: not installed"
  command -v sf &>/dev/null && echo "  salesforce: $(sf version 2>/dev/null | head -1)" || echo "  salesforce: not installed"
  command -v huggingface-cli &>/dev/null && echo "  huggingface: installed" || echo "  huggingface: not installed"
  command -v railway &>/dev/null && echo "  railway: $(railway version 2>/dev/null | head -1)" || echo "  railway: not installed"
  command -v wrangler &>/dev/null && echo "  cloudflare: $(wrangler version 2>/dev/null | head -1)" || echo "  cloudflare: not installed"
}

main "$@"
