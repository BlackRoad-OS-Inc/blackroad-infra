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
# Stripe CLI Authentication Setup

echo "════════════════════════════════════════════════════════════════"
echo "  🔐 STRIPE CLI AUTHENTICATION"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Setting up Stripe CLI for terminal access..."
echo ""

# Check if already authenticated
if stripe --version &> /dev/null; then
    echo "✅ Stripe CLI installed: $(stripe --version)"
else
    echo "❌ Stripe CLI not found"
    exit 1
fi

echo ""
echo "To authenticate Stripe CLI permanently:"
echo ""
echo "1. Run: stripe login"
echo "2. Browser will open for authentication"
echo "3. Authorize the CLI app"
echo "4. Return to terminal - you'll be authenticated!"
echo ""
echo "Once authenticated, you can:"
echo "  • stripe products create --name='Product Name' --description='Description'"
echo "  • stripe prices create --product=prod_xxx --currency=usd --unit-amount=1000 --recurring[interval]=month"
echo "  • stripe customers list"
echo "  • stripe subscriptions list"
echo "  • stripe listen --forward-to localhost:3000/api/webhooks/stripe"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
read -p "Press Enter to start authentication, or Ctrl+C to cancel..."

stripe login

echo ""
echo "✅ Authentication complete!"
echo ""
echo "Test it:"
echo "  stripe products list --limit 5"
echo ""
