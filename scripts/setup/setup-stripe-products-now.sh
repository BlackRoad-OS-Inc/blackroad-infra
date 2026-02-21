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
# Stripe Product Setup - Live Mode
# Creates 5 products with payment links

set -e

echo "🚀 STRIPE LIVE MODE SETUP"
echo "=========================="
echo ""

# Check if logged in
if ! stripe config --list | grep -q "live_"; then
    echo "⚠️  Not logged into Stripe CLI in live mode"
    echo "Run: stripe login"
    exit 1
fi

echo "✅ Stripe CLI authenticated"
echo ""

# Create products
echo "📦 Creating products..."
echo ""

# 1. Context Bridge Monthly
echo "1️⃣  Context Bridge - Monthly ($10/mo)"
CB_MONTHLY=$(stripe products create \
  --name="Context Bridge - Monthly" \
  --description="Unlimited context bridges for AI coding assistants. Never re-explain yourself." \
  2>&1 | grep "^id" | awk '{print $2}')

CB_MONTHLY_PRICE=$(stripe prices create \
  --product="$CB_MONTHLY" \
  --unit-amount=1000 \
  --currency=usd \
  --recurring='{"interval":"month"}' \
  2>&1 | grep "^id" | awk '{print $2}')

CB_MONTHLY_LINK=$(stripe payment_links create \
  --line-items[0][price]="$CB_MONTHLY_PRICE" \
  --line-items[0][quantity]=1 \
  2>&1 | grep "^url" | awk '{print $2}')

echo "   ✅ $CB_MONTHLY_LINK"
echo ""

# 2. Context Bridge Annual
echo "2️⃣  Context Bridge - Annual ($100/yr)"
CB_ANNUAL=$(stripe products create \
  --name="Context Bridge - Annual" \
  --description="Unlimited context bridges (save \$20/year)" \
  2>&1 | grep "^id" | awk '{print $2}')

CB_ANNUAL_PRICE=$(stripe prices create \
  --product="$CB_ANNUAL" \
  --unit-amount=10000 \
  --currency=usd \
  --recurring='{"interval":"year"}' \
  2>&1 | grep "^id" | awk '{print $2}')

CB_ANNUAL_LINK=$(stripe payment_links create \
  --line-items[0][price]="$CB_ANNUAL_PRICE" \
  --line-items[0][quantity]=1 \
  2>&1 | grep "^url" | awk '{print $2}')

echo "   ✅ $CB_ANNUAL_LINK"
echo ""

# 3. Lucidia Pro
echo "3️⃣  Lucidia Pro ($49/mo)"
LUCIDIA=$(stripe products create \
  --name="Lucidia Pro" \
  --description="Advanced AI simulation engine with physics modeling" \
  2>&1 | grep "^id" | awk '{print $2}')

LUCIDIA_PRICE=$(stripe prices create \
  --product="$LUCIDIA" \
  --unit-amount=4900 \
  --currency=usd \
  --recurring='{"interval":"month"}' \
  2>&1 | grep "^id" | awk '{print $2}')

LUCIDIA_LINK=$(stripe payment_links create \
  --line-items[0][price]="$LUCIDIA_PRICE" \
  --line-items[0][quantity]=1 \
  2>&1 | grep "^url" | awk '{print $2}')

echo "   ✅ $LUCIDIA_LINK"
echo ""

# 4. RoadAuth Starter
echo "4️⃣  RoadAuth - Starter ($29/mo)"
RA_STARTER=$(stripe products create \
  --name="RoadAuth - Starter" \
  --description="Authentication for up to 1,000 users" \
  2>&1 | grep "^id" | awk '{print $2}')

RA_STARTER_PRICE=$(stripe prices create \
  --product="$RA_STARTER" \
  --unit-amount=2900 \
  --currency=usd \
  --recurring='{"interval":"month"}' \
  2>&1 | grep "^id" | awk '{print $2}')

RA_STARTER_LINK=$(stripe payment_links create \
  --line-items[0][price]="$RA_STARTER_PRICE" \
  --line-items[0][quantity]=1 \
  2>&1 | grep "^url" | awk '{print $2}')

echo "   ✅ $RA_STARTER_LINK"
echo ""

# 5. RoadAuth Enterprise
echo "5️⃣  RoadAuth - Enterprise ($299/mo)"
RA_ENTERPRISE=$(stripe products create \
  --name="RoadAuth - Enterprise" \
  --description="Authentication for unlimited users + SSO" \
  2>&1 | grep "^id" | awk '{print $2}')

RA_ENTERPRISE_PRICE=$(stripe prices create \
  --product="$RA_ENTERPRISE" \
  --unit-amount=29900 \
  --currency=usd \
  --recurring='{"interval":"month"}' \
  2>&1 | grep "^id" | awk '{print $2}')

RA_ENTERPRISE_LINK=$(stripe payment_links create \
  --line-items[0][price]="$RA_ENTERPRISE_PRICE" \
  --line-items[0][quantity]=1 \
  2>&1 | grep "^url" | awk '{print $2}')

echo "   ✅ $RA_ENTERPRISE_LINK"
echo ""

# Save to file
cat > ~/STRIPE_PAYMENT_LINKS_LIVE.txt << EOF
# 💳 STRIPE PAYMENT LINKS - LIVE MODE
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

Context Bridge - Monthly (\$10/mo):
$CB_MONTHLY_LINK

Context Bridge - Annual (\$100/yr):
$CB_ANNUAL_LINK

Lucidia Pro (\$49/mo):
$LUCIDIA_LINK

RoadAuth - Starter (\$29/mo):
$RA_STARTER_LINK

RoadAuth - Enterprise (\$299/mo):
$RA_ENTERPRISE_LINK

---

Revenue Potential per Customer: \$387/month (if all purchased)
Total Annual Value: \$4,644

Next Steps:
1. Add these links to landing pages
2. Test checkout flow
3. Configure webhooks
4. Set up customer portal
EOF

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL 5 PRODUCTS CREATED!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Payment links saved to:"
echo "   ~/STRIPE_PAYMENT_LINKS_LIVE.txt"
echo ""
echo "💰 Revenue Potential: \$387/month per customer"
echo ""
echo "🎯 Next: Add links to landing pages!"
echo ""
