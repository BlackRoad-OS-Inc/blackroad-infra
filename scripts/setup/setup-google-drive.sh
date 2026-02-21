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
# Google Drive Setup with rclone

echo "════════════════════════════════════════════════════════════════"
echo "  💾 GOOGLE DRIVE INTEGRATION"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Setting up Google Drive sync with rclone..."
echo ""

# Check if already configured
if rclone listremotes | grep -q "gdrive:"; then
    echo "✅ Google Drive already configured!"
    echo ""
    echo "Available remotes:"
    rclone listremotes
    echo ""
    echo "Quick commands:"
    echo "  • List files: rclone ls gdrive:"
    echo "  • Sync down: rclone sync gdrive:/Planning ~/GoogleDrive/Planning"
    echo "  • Sync up: rclone sync ~/local-folder gdrive:/folder"
    echo "  • Copy file: rclone copy file.txt gdrive:/Documents"
    echo ""
else
    echo "Setting up Google Drive remote..."
    echo ""
    echo "1. Run: rclone config"
    echo "2. Type 'n' for new remote"
    echo "3. Name it 'gdrive'"
    echo "4. Choose 'Google Drive' (usually option 18)"
    echo "5. Leave client_id blank (press Enter)"
    echo "6. Leave client_secret blank (press Enter)"
    echo "7. Choose scope: '1' for full access"
    echo "8. Leave root_folder_id blank (press Enter)"
    echo "9. Leave service_account_file blank (press Enter)"
    echo "10. Auto config: 'Y' (browser will open)"
    echo "11. Authenticate in browser"
    echo "12. Not a Shared Drive: 'N'"
    echo "13. Confirm: 'Y'"
    echo "14. Quit: 'q'"
    echo ""
    read -p "Press Enter to start configuration, or Ctrl+C to cancel..."
    
    rclone config
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  📂 RECOMMENDED SYNC STRUCTURE"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Create local mirror:"
echo "  mkdir -p ~/GoogleDrive"
echo "  rclone sync gdrive: ~/GoogleDrive --progress"
echo ""
echo "Sync planning docs:"
echo "  rclone sync gdrive:/BlackRoad ~/GoogleDrive/BlackRoad --progress"
echo ""
echo "Watch for changes (continuous sync):"
echo "  rclone mount gdrive: ~/GoogleDrive --vfs-cache-mode writes"
echo ""
echo "List all files:"
echo "  rclone ls gdrive: --max-depth 2"
echo ""
