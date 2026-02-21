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
set -e

# Phase 6: Deploy GitHub CI/CD workflows to all orgs
# Usage: ./deploy-workflows-to-orgs.sh [org-name] (if no org specified, deploys to all)

WORKFLOWS_DIR="/tmp/workflows"
TARGET_ORG="${1:-all}"

ORGS=(
  "BlackRoad-AI"
  "BlackRoad-Archive"
  "BlackRoad-Cloud"
  "BlackRoad-Education"
  "BlackRoad-Foundation"
  "BlackRoad-Gov"
  "BlackRoad-Hardware"
  "BlackRoad-Interactive"
  "BlackRoad-Labs"
  "BlackRoad-Media"
  "BlackRoad-OS"
  "BlackRoad-Security"
  "BlackRoad-Studio"
  "BlackRoad-Ventures"
  "Blackbox-Enterprises"
)

echo "🚀 PHASE 6: GitHub CI/CD Deployment"
echo "===================================="
echo ""

deploy_to_repo() {
  local repo=$1
  local org=$2
  
  echo "  📦 $repo"
  
  # Clone repo
  git clone --depth 1 "https://github.com/$org/$repo.git" "/tmp/repo-$repo" 2>/dev/null || {
    echo "    ⚠️  Could not clone (might be empty or no access)"
    return
  }
  
  cd "/tmp/repo-$repo"
  
  # Create workflows directory
  mkdir -p .github/workflows
  
  # Copy workflows
  cp "$WORKFLOWS_DIR/security-scan.yml" .github/workflows/ 2>/dev/null || true
  cp "$WORKFLOWS_DIR/auto-deploy.yml" .github/workflows/ 2>/dev/null || true
  cp "$WORKFLOWS_DIR/self-healing.yml" .github/workflows/ 2>/dev/null || true
  
  # Copy dependabot config
  mkdir -p .github
  cp "$WORKFLOWS_DIR/dependabot.yml" .github/ 2>/dev/null || true
  
  # Check if there are changes
  if [ -n "$(git status --porcelain)" ]; then
    git config user.name "BlackRoad Bot"
    git config user.email "bot@blackroad.io"
    git add .github/
    git commit -m "ci: add GitHub Actions workflows

- Security scanning (CodeQL, dependency scan, secret scan)
- Auto-deployment to Cloudflare/Railway
- Self-healing with auto-rollback
- Dependabot for dependency updates

Deployed by: Phase 6 GitHub CI/CD automation"
    
    git push origin main 2>/dev/null || git push origin master 2>/dev/null || {
      echo "    ⚠️  Could not push (check branch protection)"
    }
    
    echo "    ✅ Workflows deployed!"
  else
    echo "    ℹ️  No changes needed"
  fi
  
  cd /tmp
  rm -rf "/tmp/repo-$repo"
}

deploy_to_org() {
  local org=$1
  
  echo ""
  echo "🏢 Organization: $org"
  echo "---"
  
  # Get all active repos for this org
  repos=$(gh repo list "$org" --limit 100 --json name,isArchived,isFork | \
    jq -r '.[] | select(.isArchived == false and .isFork == false) | .name')
  
  if [ -z "$repos" ]; then
    echo "  ℹ️  No active repos found"
    return
  fi
  
  for repo in $repos; do
    deploy_to_repo "$repo" "$org"
  done
}

# Main execution
if [ "$TARGET_ORG" = "all" ]; then
  echo "Deploying to ALL 15 organizations..."
  echo ""
  
  for org in "${ORGS[@]}"; do
    deploy_to_org "$org"
  done
else
  echo "Deploying to: $TARGET_ORG"
  deploy_to_org "$TARGET_ORG"
fi

echo ""
echo "================================"
echo "✅ Phase 6 Deployment Complete!"
echo "================================"
