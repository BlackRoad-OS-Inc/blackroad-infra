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

echo "🚀 BlackRoad Workflow System - Production Deployment"
echo "======================================================"
echo ""

# List of candidate repos
REPOS=(
  ~/blackroad-os-demo
  ~/blackroad.io
  ~/blackroad-os-home
  ~/lucidia-earth
  ~/blackroad-pi-ops
)

echo "📋 Selected repositories for deployment:"
for i in "${!REPOS[@]}"; do
  echo "  $((i+1)). ${REPOS[$i]}"
done
echo ""

read -p "Deploy to these repos? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Deployment cancelled"
  exit 0
fi

echo ""
echo "🔄 Starting deployment..."
echo ""

SUCCESS=0
FAILED=0

for repo in "${REPOS[@]}"; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Deploying to: $(basename $repo)"
  echo ""
  
  if [ ! -d "$repo" ]; then
    echo "⚠️  Directory not found, skipping..."
    ((FAILED++))
    continue
  fi
  
  cd "$repo" || continue
  
  # Check if it's a git repo
  if [ ! -d .git ]; then
    echo "⚠️  Not a git repository, skipping..."
    ((FAILED++))
    continue
  fi
  
  # Run deployment script
  ~/.blackroad/cross-repo-templates/deploy-cross-repo-index.sh . 2>&1 | grep -E "✅|⚠️|📍"
  
  # Check if files were created
  if [ -f .github/workflows/workflow-index-sync.yml ] && [ -f .github/workflows/check-dependencies.yml ]; then
    echo ""
    echo "📝 Committing changes..."
    
    git add .github/workflows/ .blackroad/ 2>/dev/null
    
    if git diff --staged --quiet 2>/dev/null; then
      echo "ℹ️  No changes to commit (already deployed)"
    else
      git commit -m "🌐 Add cross-repo index system (Tier 1)" -q
      echo "✅ Committed"
      
      # Optionally push (commented out for safety)
      # git push 2>&1 | grep -E "✓|→|✗"
      echo "⏸️  Ready to push (run 'git push' when ready)"
    fi
    
    ((SUCCESS++))
  else
    echo "❌ Deployment failed"
    ((FAILED++))
  fi
  
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Deployment Summary:"
echo "  ✅ Successful: $SUCCESS"
echo "  ❌ Failed: $FAILED"
echo "  �� Total: ${#REPOS[@]}"
echo ""

if [ $SUCCESS -gt 0 ]; then
  echo "🎉 Deployment complete!"
  echo ""
  echo "🔔 Next steps:"
  echo "  1. Review changes: cd <repo> && git status"
  echo "  2. Push changes: cd <repo> && git push"
  echo "  3. Create test issues with workflow ID labels"
  echo "  4. Watch automatic indexing in action"
  echo ""
  echo "📖 Quick guide: ~/CROSS_REPO_QUICK_START.md"
fi
