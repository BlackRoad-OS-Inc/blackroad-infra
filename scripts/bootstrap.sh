#!/usr/bin/env bash
# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
# Bootstrap a new development environment with required tools.
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

echo "BlackRoad Infra — Bootstrap"
echo "==========================="

# Check Node.js
if command -v node &>/dev/null; then
  log "Node.js $(node -v)"
else
  fail "Node.js not found. Install Node.js 22+."
fi

# Check Terraform
if command -v terraform &>/dev/null; then
  log "Terraform $(terraform version -json | jq -r .terraform_version)"
else
  warn "Terraform not found. Install: brew install terraform"
fi

# Check Docker
if command -v docker &>/dev/null; then
  log "Docker $(docker --version | awk '{print $3}')"
else
  warn "Docker not found. Install Docker Desktop."
fi

# Check Wrangler
if command -v wrangler &>/dev/null; then
  log "Wrangler installed"
else
  warn "Wrangler not found. Install: npm i -g wrangler"
fi

# Check GitHub CLI
if command -v gh &>/dev/null; then
  log "GitHub CLI $(gh --version | head -1 | awk '{print $3}')"
else
  warn "GitHub CLI not found. Install: brew install gh"
fi

echo ""
log "Bootstrap complete."
