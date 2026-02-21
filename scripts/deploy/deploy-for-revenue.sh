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
# Quick Revenue Deployment Script
# Deploys all revenue-ready products to production

set -e

echo "💰 REVENUE DEPLOYMENT BLITZ"
echo "============================"
echo ""

# Track deployments
DEPLOYED=0
FAILED=0

deploy_service() {
  local name=$1
  local dir=$2
  local domain=$3
  
  echo "🚀 Deploying $name to $domain..."
  
  if cd "$dir" 2>/dev/null; then
    # Check if wrangler.toml exists (Cloudflare)
    if [ -f "wrangler.toml" ]; then
      echo "   Using Cloudflare Pages..."
      if npm run build && wrangler pages deploy build; then
        echo "   ✅ $name deployed!"
        ((DEPLOYED++))
      else
        echo "   ❌ $name failed"
        ((FAILED++))
      fi
    # Check if railway.json exists (Railway)
    elif [ -f "railway.json" ]; then
      echo "   Using Railway..."
      if railway up; then
        echo "   ✅ $name deployed!"
        ((DEPLOYED++))
      else
        echo "   ❌ $name failed"
        ((FAILED++))
      fi
    else
      echo "   ⚠️  No deployment config found"
      ((FAILED++))
    fi
    cd - > /dev/null
  else
    echo "   ⚠️  Directory not found: $dir"
    ((FAILED++))
  fi
  
  echo ""
}

# Deploy services
deploy_service "Context Bridge Web" "/Users/alexa/services/context-bridge" "context-bridge.blackroad.io"
deploy_service "Lucidia Platform" "/Users/alexa/lucidia-platform" "lucidia.blackroad.io"
deploy_service "PitStop" "/Users/alexa/blackroad-pitstop" "pitstop.blackroad.io"
deploy_service "RoadFlow" "/Users/alexa/roadflow" "roadflow.blackroad.io"

# Summary
echo "============================"
echo "📊 Deployment Summary"
echo "============================"
echo "✅ Successful: $DEPLOYED"
echo "❌ Failed: $FAILED"
echo ""

if [ $DEPLOYED -gt 0 ]; then
  echo "🎉 $DEPLOYED products deployed!"
  echo ""
  echo "Next steps:"
  echo "1. Test all deployed URLs"
  echo "2. Verify Stripe integration"
  echo "3. Check analytics"
  echo "4. Launch marketing campaigns"
  echo ""
fi

# Open revenue dashboard
echo "📈 Opening revenue dashboard..."
open /Users/alexa/REVENUE_TRACKING_DASHBOARD.html 2>/dev/null || true

echo ""
echo "🚀 DEPLOYMENT COMPLETE!"
