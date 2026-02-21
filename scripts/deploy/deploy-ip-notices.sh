#!/bin/bash
# Deploy IP notices to all BlackRoad repos

NOTICE_FILE=~/BLACKROAD_IP_NOTICE.md
POLICY_FILE=~/BLACKROAD_AI_POLICY.md

# Key repos to update first
PRIORITY_REPOS=(
    "blackroad-os-infra"
    "blackroad-os-brand"
    "blackroad-io"
    "blackroad"
    "index"
)

for repo in "${PRIORITY_REPOS[@]}"; do
    echo "Updating $repo..."
    cd /tmp
    rm -rf "$repo" 2>/dev/null
    gh repo clone "BlackRoad-OS/$repo" 2>/dev/null || continue
    cd "$repo"
    
    cp "$NOTICE_FILE" ./BLACKROAD_IP_NOTICE.md
    cp "$POLICY_FILE" ./BLACKROAD_AI_POLICY.md
    
    git add -A
    git commit -m "Add BlackRoad IP protection notices

All code is property of BlackRoad OS, Inc.
AI-assisted development does not transfer ownership.
NOT licensed for AI training or extraction." 2>/dev/null
    
    git push 2>/dev/null && echo "  Pushed $repo" || echo "  Failed $repo"
done

echo "Done with priority repos"
