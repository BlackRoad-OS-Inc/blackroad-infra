#!/bin/bash
# 💳 STRIPE PRODUCTS - ENHANCED SETUP
# 
# Creates complete product catalog with:
# - Multiple pricing tiers
# - Annual/monthly options
# - Usage-based billing
# - Free trials
# - Promotional codes
# - Tax handling
# - Webhook automation

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
RESET='\033[0m'

echo -e "${PINK}╔════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║   💳 STRIPE PRODUCTS SETUP                ║${RESET}"
echo -e "${PINK}╚════════════════════════════════════════════╝${RESET}"
echo ""

# Check Stripe CLI
if ! command -v stripe &> /dev/null; then
    echo -e "${RED}❌ Stripe CLI not found${RESET}"
    echo -e "${AMBER}Install: brew install stripe/stripe-cli/stripe${RESET}"
    exit 1
fi

# Check authentication
if ! stripe config --list &> /dev/null; then
    echo -e "${AMBER}🔑 Not logged in to Stripe${RESET}"
    echo -e "${BLUE}Run: stripe login${RESET}"
    exit 1
fi

echo -e "${GREEN}✅ Stripe CLI ready${RESET}"
echo ""

# ===== PRODUCT DEFINITIONS =====

declare -A PRODUCTS=(
    ["context_bridge_monthly"]="Context Bridge|Monthly AI coding context|10.00|month|Unlimited context bridges for AI assistants"
    ["context_bridge_annual"]="Context Bridge Annual|Annual plan (save 16%)|100.00|year|Unlimited context bridges + priority support"
    ["lucidia_pro"]="Lucidia Pro|Advanced AI simulation|49.00|month|Advanced simulation engine with quantum features"
    ["roadauth_starter"]="RoadAuth Starter|Authentication platform|29.00|month|Up to 10,000 MAU with social login"
    ["roadauth_business"]="RoadAuth Business|Business authentication|99.00|month|Up to 50,000 MAU + SSO + organizations"
    ["roadauth_enterprise"]="RoadAuth Enterprise|Enterprise solution|299.00|month|Unlimited MAU + custom domains + SLA"
    ["roadwork_pro"]="RoadWork Pro|Project management|39.00|month|Unlimited projects + AI assistance"
    ["pitstop_pro"]="PitStop Pro|DevOps automation|59.00|month|CI/CD + deployment automation"
    ["roadflow_business"]="RoadFlow Business|Workflow automation|79.00|month|Unlimited workflows + integrations"
)

create_product() {
    local product_key=$1
    local product_data="${PRODUCTS[$product_key]}"
    
    IFS='|' read -r name description price interval features <<< "$product_data"
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${PINK}📦 Creating: $name${RESET}"
    echo -e "${AMBER}   Price: \$$price/$interval${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    # Create product
    PRODUCT_ID=$(stripe products create \
        --name "$name" \
        --description "$description" \
        --metadata[key]="$product_key" \
        --metadata[features]="$features" \
        --metadata[source]="blackroad_os_enhanced" \
        --active=true \
        --format json | jq -r '.id')
    
    if [ -z "$PRODUCT_ID" ]; then
        echo -e "${RED}❌ Failed to create product${RESET}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Product created: $PRODUCT_ID${RESET}"
    
    # Create price (convert dollars to cents)
    AMOUNT_CENTS=$(echo "$price * 100" | bc | cut -d. -f1)
    
    PRICE_ID=$(stripe prices create \
        --product "$PRODUCT_ID" \
        --currency usd \
        --unit-amount "$AMOUNT_CENTS" \
        --recurring[interval]="$interval" \
        --recurring[interval_count]=1 \
        --active=true \
        --metadata[product_key]="$product_key" \
        --format json | jq -r '.id')
    
    echo -e "${GREEN}✅ Price created: $PRICE_ID${RESET}"
    
    # Create payment link
    PAYMENT_LINK=$(stripe payment_links create \
        --line-items[0][price]="$PRICE_ID" \
        --line-items[0][quantity]=1 \
        --after-completion[type]=redirect \
        --after-completion[redirect][url]="https://blackroad.io/success?product=$product_key" \
        --allow-promotion-codes=true \
        --billing-address-collection=auto \
        --format json | jq -r '.url')
    
    echo -e "${GREEN}✅ Payment link: $PAYMENT_LINK${RESET}"
    
    # Save to file
    cat >> ~/stripe-products-output.txt << EOF
$name
  Product ID: $PRODUCT_ID
  Price ID: $PRICE_ID
  Payment Link: $PAYMENT_LINK
  Amount: \$$price/$interval

EOF
    
    # Log to memory
    ~/memory-system.sh log "stripe-product" "$product_key" \
        "Created $name (\$$price/$interval). Product: $PRODUCT_ID, Price: $PRICE_ID" \
        "stripe,revenue,products" 2>/dev/null || true
    
    echo ""
}

create_trial() {
    local product_key=$1
    local trial_days=${2:-14}
    
    echo -e "${BLUE}🎁 Adding $trial_days-day free trial to $product_key...${RESET}"
    
    # Get product and price IDs
    local product_data="${PRODUCTS[$product_key]}"
    IFS='|' read -r name _ _ _ _ <<< "$product_data"
    
    # Find existing price
    PRICE_ID=$(stripe prices list --product "$name" --format json | jq -r '.data[0].id')
    
    if [ -z "$PRICE_ID" ] || [ "$PRICE_ID" = "null" ]; then
        echo -e "${RED}❌ Product not found${RESET}"
        return 1
    fi
    
    # Update price with trial
    stripe prices update "$PRICE_ID" \
        --recurring[trial_period_days]="$trial_days" \
        --format json > /dev/null
    
    echo -e "${GREEN}✅ Trial added: $trial_days days${RESET}"
}

create_promo_code() {
    local code=$1
    local percent_off=$2
    local duration=${3:-once}  # once, forever, repeating
    
    echo -e "${BLUE}🎟️  Creating promo code: $code${RESET}"
    
    # Create coupon first
    COUPON_ID=$(stripe coupons create \
        --percent-off "$percent_off" \
        --duration "$duration" \
        --name "$code" \
        --format json | jq -r '.id')
    
    # Create promotion code
    PROMO_CODE=$(stripe promotion_codes create \
        --coupon "$COUPON_ID" \
        --code "$code" \
        --active=true \
        --format json | jq -r '.code')
    
    echo -e "${GREEN}✅ Promo code: $PROMO_CODE ($percent_off% off, $duration)${RESET}"
}

setup_webhooks() {
    echo -e "${BLUE}🔗 Setting up webhooks...${RESET}"
    
    WEBHOOK_URL="${1:-https://api.blackroad.systems/webhooks/stripe}"
    
    # Create webhook endpoint
    WEBHOOK_ID=$(stripe webhook_endpoints create \
        --url "$WEBHOOK_URL" \
        --enabled-events customer.subscription.created \
        --enabled-events customer.subscription.updated \
        --enabled-events customer.subscription.deleted \
        --enabled-events payment_intent.succeeded \
        --enabled-events payment_intent.payment_failed \
        --enabled-events invoice.paid \
        --enabled-events invoice.payment_failed \
        --format json | jq -r '.id')
    
    WEBHOOK_SECRET=$(stripe webhook_endpoints retrieve "$WEBHOOK_ID" --format json | jq -r '.secret')
    
    echo -e "${GREEN}✅ Webhook created: $WEBHOOK_ID${RESET}"
    echo -e "${AMBER}   Secret: $WEBHOOK_SECRET${RESET}"
    echo ""
    echo -e "${BLUE}Add to environment variables:${RESET}"
    echo "  STRIPE_WEBHOOK_SECRET=$WEBHOOK_SECRET"
}

create_all_products() {
    echo -e "${PINK}🚀 Creating all products...${RESET}"
    echo ""
    
    # Clear output file
    > ~/stripe-products-output.txt
    
    for product_key in "${!PRODUCTS[@]}"; do
        create_product "$product_key"
        sleep 1  # Rate limit prevention
    done
    
    echo -e "${GREEN}🎉 All products created!${RESET}"
    echo ""
    echo -e "${BLUE}Output saved to: ~/stripe-products-output.txt${RESET}"
}

add_promo_codes() {
    echo -e "${PINK}🎟️  Creating promotional codes...${RESET}"
    echo ""
    
    create_promo_code "LAUNCH2026" 50 "once"
    create_promo_code "BLACKROAD20" 20 "forever"
    create_promo_code "ANNUAL30" 30 "once"
    
    echo -e "${GREEN}✅ Promo codes created${RESET}"
}

show_products() {
    echo -e "${BLUE}📋 Current Stripe Products:${RESET}"
    echo ""
    
    stripe products list --limit 20 --format json | jq -r '.data[] | "  • \(.name) (\(.metadata.key // "no-key")) - $\(.default_price.unit_amount / 100)/\(.default_price.recurring.interval)"'
    
    echo ""
}

test_checkout() {
    local price_id=$1
    
    echo -e "${BLUE}🧪 Creating test checkout session...${RESET}"
    
    CHECKOUT_URL=$(stripe checkout sessions create \
        --mode subscription \
        --line-items[0][price]="$price_id" \
        --line-items[0][quantity]=1 \
        --success-url="https://blackroad.io/success?session_id={CHECKOUT_SESSION_ID}" \
        --cancel-url="https://blackroad.io/pricing" \
        --format json | jq -r '.url')
    
    echo -e "${GREEN}✅ Test checkout: $CHECKOUT_URL${RESET}"
    echo ""
    echo -e "${AMBER}Opening in browser...${RESET}"
    open "$CHECKOUT_URL" 2>/dev/null || echo "Visit: $CHECKOUT_URL"
}

# ===== MAIN MENU =====

show_menu() {
    echo -e "${BLUE}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║         STRIPE PRODUCTS MENU              ║${RESET}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "1) Create all products"
    echo "2) Create single product"
    echo "3) Add promo codes"
    echo "4) Setup webhooks"
    echo "5) Show products"
    echo "6) Test checkout"
    echo "7) Add free trial"
    echo "8) Exit"
    echo ""
    read -p "Choose option: " choice
    
    case $choice in
        1)
            create_all_products
            ;;
        2)
            echo "Available products:"
            local i=1
            for key in "${!PRODUCTS[@]}"; do
                IFS='|' read -r name _ price interval _ <<< "${PRODUCTS[$key]}"
                echo "  $i) $name (\$$price/$interval)"
                ((i++))
            done
            read -p "Enter product key: " prod_key
            create_product "$prod_key"
            ;;
        3)
            add_promo_codes
            ;;
        4)
            read -p "Webhook URL (default: https://api.blackroad.systems/webhooks/stripe): " webhook_url
            setup_webhooks "${webhook_url:-https://api.blackroad.systems/webhooks/stripe}"
            ;;
        5)
            show_products
            ;;
        6)
            read -p "Enter price ID: " price_id
            test_checkout "$price_id"
            ;;
        7)
            read -p "Product key: " prod_key
            read -p "Trial days (default: 14): " trial_days
            create_trial "$prod_key" "${trial_days:-14}"
            ;;
        8)
            echo -e "${GREEN}Goodbye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${RESET}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_menu
}

# ===== CLI ARGUMENTS =====

if [ $# -eq 0 ]; then
    show_menu
else
    case "$1" in
        create-all)
            create_all_products
            ;;
        create)
            create_product "$2"
            ;;
        promo)
            add_promo_codes
            ;;
        webhooks)
            setup_webhooks "$2"
            ;;
        list)
            show_products
            ;;
        test)
            test_checkout "$2"
            ;;
        *)
            echo "Usage: $0 {create-all|create|promo|webhooks|list|test}"
            echo ""
            echo "Or run without arguments for interactive menu"
            exit 1
            ;;
    esac
fi
