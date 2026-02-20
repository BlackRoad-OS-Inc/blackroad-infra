#!/usr/bin/env bash
# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
# Health check all BlackRoad services.
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
ok() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }

echo "BlackRoad Health Check"
echo "======================"

check_url() {
  local name="$1" url="$2"
  if curl -sf --max-time 5 "$url" > /dev/null 2>&1; then
    ok "$name ($url)"
  else
    fail "$name ($url)"
  fi
}

check_url "Gateway" "${BLACKROAD_GATEWAY_URL:-http://127.0.0.1:8787}/v1/health"
check_url "Web" "${BLACKROAD_WEB_URL:-http://127.0.0.1:3000}"
check_url "Agents" "${BLACKROAD_AGENTS_URL:-http://127.0.0.1:8788}"

echo ""
echo "Done."
