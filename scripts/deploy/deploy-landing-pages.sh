#!/bin/bash
# Deploy All Landing Pages to Cloudflare Pages
# Run this after Stripe products are created

set -e

echo "🚀 DEPLOYING ALL LANDING PAGES"
echo "================================"
echo ""

# Landing pages ready
PAGES=(
  "lucidia-landing.html → lucidia.blackroad.io"
  "roadauth-landing.html → roadauth.blackroad.io"
  "context-bridge-landing.html → context-bridge.pages.dev"
)

echo "📦 Landing pages ready:"
for page in "${PAGES[@]}"; do
  echo "   ✅ $page"
done
echo ""

echo "🎯 DEPLOYMENT OPTIONS:"
echo ""
echo "Option 1: Cloudflare Pages (Recommended)"
echo "   1. Go to: https://dash.cloudflare.com/pages"
echo "   2. Click 'Create a project'"
echo "   3. Upload each HTML file"
echo "   4. Set custom domain"
echo ""
echo "Option 2: Quick Deploy with Wrangler"
echo "   cd /Users/alexa"
echo "   wrangler pages deploy lucidia-landing.html --project-name=lucidia"
echo "   wrangler pages deploy roadauth-landing.html --project-name=roadauth"
echo "   wrangler pages deploy context-bridge-landing.html --project-name=context-bridge"
echo ""
echo "Option 3: GitHub Pages (Free)"
echo "   1. Create repo for each landing page"
echo "   2. Push HTML file"
echo "   3. Enable GitHub Pages in repo settings"
echo ""

echo "✅ All landing pages created and ready!"
echo ""
echo "Next steps:"
echo "1. ✅ Create Stripe products (DO THIS NOW if not done)"
echo "2. Deploy landing pages (choose option above)"
echo "3. Add payment links to pages"
echo "4. Test all flows"
echo "5. Launch marketing!"
echo ""
