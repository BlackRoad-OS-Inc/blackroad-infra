#!/bin/bash
# 🚀 STRIPE LIVE MODE - QUICK SETUP
# Execute Stripe product creation for live mode

set -e

PINK='\033[38;5;205m'
GREEN='\033[38;5;82m'
BLUE='\033[38;5;69m'
AMBER='\033[38;5;214m'
RESET='\033[0m'

echo -e "${PINK}╔════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║   💳 STRIPE LIVE MODE SETUP               ║${RESET}"
echo -e "${PINK}╚════════════════════════════════════════════╝${RESET}"
echo ""

# Instructions
echo -e "${BLUE}📋 MANUAL STEPS (5 minutes):${RESET}"
echo ""
echo -e "${AMBER}1. Open Stripe Dashboard:${RESET}"
echo "   https://dashboard.stripe.com/products"
echo ""
echo -e "${AMBER}2. Toggle to LIVE MODE (top right)${RESET}"
echo ""
echo -e "${AMBER}3. Create these products:${RESET}"
echo ""

cat << 'EOF'
┌─────────────────────────────────────────────────────────────┐
│ PRODUCT 1: Context Bridge Monthly                          │
├─────────────────────────────────────────────────────────────┤
│ Name: Context Bridge - Monthly                             │
│ Description: Unlimited AI coding context bridges           │
│ Price: $10.00 USD                                           │
│ Billing: Recurring monthly                                  │
│ → Click "Add Product"                                       │
│ → Get Payment Link → Copy URL                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PRODUCT 2: Context Bridge Annual                           │
├─────────────────────────────────────────────────────────────┤
│ Name: Context Bridge - Annual                              │
│ Description: Unlimited bridges (save $20/year)             │
│ Price: $100.00 USD                                          │
│ Billing: Recurring yearly                                   │
│ → Click "Add Product"                                       │
│ → Get Payment Link → Copy URL                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PRODUCT 3: Lucidia Pro                                     │
├─────────────────────────────────────────────────────────────┤
│ Name: Lucidia Pro                                           │
│ Description: Advanced AI simulation engine                  │
│ Price: $49.00 USD                                           │
│ Billing: Recurring monthly                                  │
│ → Click "Add Product"                                       │
│ → Get Payment Link → Copy URL                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PRODUCT 4: RoadAuth Starter                                │
├─────────────────────────────────────────────────────────────┤
│ Name: RoadAuth Starter                                      │
│ Description: Authentication for startups (10K users)        │
│ Price: $29.00 USD                                           │
│ Billing: Recurring monthly                                  │
│ → Click "Add Product"                                       │
│ → Get Payment Link → Copy URL                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PRODUCT 5: RoadAuth Business                               │
├─────────────────────────────────────────────────────────────┤
│ Name: RoadAuth Business                                     │
│ Description: Business auth (50K users + SSO)                │
│ Price: $99.00 USD                                           │
│ Billing: Recurring monthly                                  │
│ → Click "Add Product"                                       │
│ → Get Payment Link → Copy URL                              │
└─────────────────────────────────────────────────────────────┘

EOF

echo ""
echo -e "${AMBER}4. Save payment links to file:${RESET}"
echo "   ~/stripe-live-payment-links.txt"
echo ""
echo -e "${GREEN}5. When done, run:${RESET}"
echo "   ~/stripe-products-enhanced.sh webhooks https://api.blackroad.systems/webhooks/stripe"
echo ""

# Open browser
read -p "Press Enter to open Stripe Dashboard..."
open "https://dashboard.stripe.com/products" 2>/dev/null || echo "Visit: https://dashboard.stripe.com/products"

echo ""
echo -e "${BLUE}💡 Tips:${RESET}"
echo "  • Use 'Add Product' button for each"
echo "  • Check 'Recurring' for billing"
echo "  • Copy payment links immediately"
echo "  • Test one checkout before continuing"
echo ""
echo -e "${GREEN}When complete, you'll have:${RESET}"
echo "  ✓ 5 live products in Stripe"
echo "  ✓ 5 payment links ready to use"
echo "  ✓ Revenue tracking enabled"
echo "  ✓ Ready for first customer!"
echo ""
