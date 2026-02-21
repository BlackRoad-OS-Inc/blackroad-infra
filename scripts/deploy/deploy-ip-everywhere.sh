#!/bin/bash
# Deploy IP notices to ALL BlackRoad repos across ALL orgs

NOTICE_FILE=~/BLACKROAD_IP_NOTICE.md
POLICY_FILE=~/BLACKROAD_AI_POLICY.md

ORGS=(
    "BlackRoad-OS"
    "BlackRoad-AI"
    "BlackRoad-Cloud"
    "BlackRoad-Security"
    "BlackRoad-Media"
    "BlackRoad-Foundation"
    "BlackRoad-Interactive"
    "BlackRoad-Labs"
    "BlackRoad-Hardware"
    "BlackRoad-Studio"
    "BlackRoad-Ventures"
    "BlackRoad-Education"
    "BlackRoad-Gov"
    "BlackRoad-Archive"
    "Blackbox-Enterprises"
)

total=0
success=0

for org in "${ORGS[@]}"; do
    echo "=== $org ==="
    repos=$(gh repo list "$org" --limit 500 --json name -q '.[].name' 2>/dev/null)
    
    for repo in $repos; do
        ((total++))
        echo -n "  $repo... "
        
        cd /tmp
        rm -rf "$repo" 2>/dev/null
        
        if gh repo clone "$org/$repo" --depth 1 2>/dev/null; then
            cd "$repo"
            cp "$NOTICE_FILE" ./BLACKROAD_IP_NOTICE.md 2>/dev/null
            cp "$POLICY_FILE" ./BLACKROAD_AI_POLICY.md 2>/dev/null
            
            git add -A 2>/dev/null
            if git commit -m "Add BlackRoad IP protection - All code property of BlackRoad OS, Inc." 2>/dev/null; then
                if git push 2>/dev/null; then
                    echo "OK"
                    ((success++))
                else
                    echo "push failed"
                fi
            else
                echo "no changes"
                ((success++))
            fi
        else
            echo "clone failed"
        fi
        
        cd /tmp
        rm -rf "$repo" 2>/dev/null
    done
done

echo ""
echo "Complete: $success/$total repos updated"
