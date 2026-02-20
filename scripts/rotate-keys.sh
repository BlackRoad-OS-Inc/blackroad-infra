#!/usr/bin/env bash
# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
# Key rotation helper — generates new secrets and updates .env files.
set -euo pipefail

echo "BlackRoad Key Rotation"
echo "======================"

generate_key() {
  openssl rand -hex 32
}

echo "Generating new keys..."
echo ""
echo "GATEWAY_SECRET=$(generate_key)"
echo "JWT_SECRET=$(generate_key)"
echo "SESSION_SECRET=$(generate_key)"
echo ""
echo "Copy the values above into your .env file."
echo "Remember to restart services after updating keys."
