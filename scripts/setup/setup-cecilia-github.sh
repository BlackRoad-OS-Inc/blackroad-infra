#!/bin/bash
# Setup Cecilia for GitHub push/pull

echo "🔐 Configuring Cecilia GitHub Access..."

# Copy your GitHub token to Cecilia
echo ""
echo "📋 Step 1: Copy GitHub credentials"
scp ~/.config/gh/hosts.yml cecilia:~/.config/gh/ 2>/dev/null || {
    ssh cecilia "mkdir -p ~/.config/gh"
    scp ~/.config/gh/hosts.yml cecilia:~/.config/gh/
}

echo "✅ GitHub CLI credentials copied!"
echo ""
echo "🧪 Testing GitHub auth on Cecilia..."
ssh cecilia "gh auth status"

echo ""
echo "✅ Cecilia can now:"
echo "   • gh repo clone"
echo "   • git push/pull"  
echo "   • Access all BlackRoad-OS repos"
echo ""
