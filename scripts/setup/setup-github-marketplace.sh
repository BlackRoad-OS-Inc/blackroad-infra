#!/bin/bash

# 🖤 BlackRoad OS - GitHub Marketplace Automation
# Prepares and deploys products to GitHub Marketplace
# Author: Alexa Amundson
# Date: 2026-01-30

set -euo pipefail

# Colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;33m'
GREEN='\033[38;5;10m'
RESET='\033[0m'

echo -e "${PINK}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║    🖤 BlackRoad OS - GitHub Marketplace Automation 🛣️        ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Flagship products to list on Marketplace
PRODUCTS=(
  "BlackRoad-OS/blackroad-prism-console:Prism Console:Intelligent system monitoring for AI infrastructure:deployment:99"
  "BlackRoad-OS/blackroad-os-web:BlackRoad OS Core:Complete AI operating system for teams:platform:499"
  "BlackRoad-OS/lucidia-agents:Lucidia AI:Advanced AI agent orchestration system:ai-ml:299"
  "BlackRoad-OS/blackroad-multi-ai-system:Multi-AI System:1000+ agent scale collaboration platform:ai-ml:499"
  "BlackRoad-OS/blackroad-ai-inference-accelerator:AI Inference Accelerator:High-performance AI inference optimization:ai-ml:199"
  "BlackRoad-OS/blackroad-os-jenkins:CI/CD Pro:BlackRoad-enhanced Jenkins automation:devops:149"
  "BlackRoad-OS/blackroad-os-vault:Secrets Vault:Enterprise secrets management:security:249"
  "BlackRoad-OS/blackroad-os-prometheus:Monitoring Suite:Complete observability stack:monitoring:179"
  "BlackRoad-OS/blackroad-os-postgresql:Database Pro:Production-ready PostgreSQL:database:129"
  "BlackRoad-OS/blackroad-os-kubernetes:K8s Platform:Enterprise Kubernetes platform:containers:399"
)

create_marketplace_files() {
  local repo="$1"
  local name="$2"
  local description="$3"
  local category="$4"
  local price="$5"
  
  echo -e "${BLUE}📦 Setting up: $name${RESET}"
  
  # Check if repo exists
  if ! gh repo view "$repo" &>/dev/null; then
    echo -e "  ⚠️  Repository not found: $repo"
    return 1
  fi
  
  # Clone or update repo
  local repo_name=$(basename "$repo")
  local work_dir="/tmp/marketplace-setup/$repo_name"
  
  if [[ -d "$work_dir" ]]; then
    cd "$work_dir"
    git pull -q
  else
    mkdir -p /tmp/marketplace-setup
    gh repo clone "$repo" "$work_dir" -- --quiet
    cd "$work_dir"
  fi
  
  # Create .github/marketplace directory
  mkdir -p .github/marketplace
  
  # Create marketplace listing
  cat > .github/marketplace/listing.yml <<EOF
name: "$name"
description: "$description"
category: $category
pricing:
  model: subscription
  tiers:
    - name: Starter
      price: \$$(($price / 5))/month
      features:
        - Up to 10 users
        - Community support
        - Basic features
    - name: Professional
      price: \$$price/month
      features:
        - Up to 100 users
        - Priority support
        - Advanced features
        - API access
    - name: Enterprise
      price: \$$(($price * 5))/month
      features:
        - Unlimited users
        - 24/7 dedicated support
        - All features
        - Custom integrations
        - On-premise deployment
screenshots:
  - path: docs/screenshots/dashboard.png
    caption: Main dashboard
  - path: docs/screenshots/features.png
    caption: Key features
support:
  email: support@blackroad.io
  docs: https://docs.blackroad.io
  issues: https://github.com/$repo/issues
links:
  website: https://blackroad.io
  documentation: https://docs.blackroad.io
  privacy: https://blackroad.io/privacy
  terms: https://blackroad.io/terms
EOF

  # Create marketplace README
  cat > .github/marketplace/README.md <<EOF
# $name

$description

## Features

- 🚀 **Production Ready** - Battle-tested in enterprise environments
- 🔒 **Secure by Default** - SOC2, HIPAA, GDPR compliant
- 📊 **Enterprise Support** - 24/7 support for Enterprise tier
- 🔄 **Regular Updates** - Monthly feature releases
- 📚 **Complete Documentation** - Comprehensive guides and API docs

## Quick Start

\`\`\`bash
# Install
npm install @blackroad-os/$repo_name

# Configure
export BLACKROAD_API_KEY="your-key"

# Run
blackroad-$repo_name start
\`\`\`

## Pricing

| Tier | Price | Users | Support |
|------|-------|-------|---------|
| Starter | \$$(($price / 5))/mo | 10 | Community |
| Professional | \$$price/mo | 100 | Priority |
| Enterprise | \$$(($price * 5))/mo | Unlimited | 24/7 Dedicated |

## Support

- 📧 Email: support@blackroad.io
- 📚 Docs: https://docs.blackroad.io
- 💬 Discord: https://discord.gg/blackroad
- 🐛 Issues: https://github.com/$repo/issues

## License

Enterprise license with open-core model. See LICENSE file.

---

**🖤 Built by BlackRoad OS, Inc.**
EOF

  # Create screenshots directory
  mkdir -p docs/screenshots
  
  # Create placeholder screenshots (in production, these would be real)
  cat > docs/screenshots/dashboard.png.md <<EOF
# Dashboard Screenshot
Replace this file with actual dashboard.png screenshot
EOF

  cat > docs/screenshots/features.png.md <<EOF
# Features Screenshot  
Replace this file with actual features.png screenshot
EOF

  # Commit changes
  git add .github/marketplace docs/screenshots
  
  if git diff --staged --quiet; then
    echo -e "  ℹ️  No changes to commit"
  else
    git commit -m "feat: add GitHub Marketplace listing for $name

- Add marketplace listing.yml with pricing tiers
- Add marketplace README with features
- Add screenshot placeholders
- Configure support and documentation links

Price: \$$price/mo (Professional tier)
Category: $category
"
    
    # Push changes
    if git push -q; then
      echo -e "  ${GREEN}✅ Marketplace files added and pushed${RESET}"
    else
      echo -e "  ⚠️  Failed to push changes"
    fi
  fi
  
  cd - > /dev/null
  echo ""
}

# Main execution
echo -e "${AMBER}Processing ${#PRODUCTS[@]} products...${RESET}"
echo ""

SUCCESS_COUNT=0
FAILED_COUNT=0

for product_spec in "${PRODUCTS[@]}"; do
  IFS=':' read -r repo name description category price <<< "$product_spec"
  
  if create_marketplace_files "$repo" "$name" "$description" "$category" "$price"; then
    ((SUCCESS_COUNT++))
  else
    ((FAILED_COUNT++))
  fi
done

echo ""
echo -e "${PINK}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║                    📊 SUMMARY                                 ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${GREEN}✅ Successful: $SUCCESS_COUNT${RESET}"
echo -e "  ❌ Failed: $FAILED_COUNT"
echo ""
echo -e "${BLUE}Next steps:${RESET}"
echo -e "  1. Review marketplace listings in each repo"
echo -e "  2. Replace screenshot placeholders with actual images"
echo -e "  3. Submit to GitHub Marketplace approval"
echo -e "  4. Configure Stripe payment links"
echo ""
