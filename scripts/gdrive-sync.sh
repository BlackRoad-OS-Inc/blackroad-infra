#!/bin/bash
# gdrive-sync.sh
# Sync local BlackRoad files to Google Drive via rclone
# Run: bash gdrive-sync.sh [setup|sync|auto]

set -e

BLACKROAD_DIR="/Users/alexa/blackroad"
REMOTE_NAME="gdrive"
REMOTE_PATH="gdrive:/BlackRoad-Backup"
LOG_FILE="$HOME/.blackroad/logs/gdrive-sync.log"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "$(dirname "$LOG_FILE")"

setup_rclone() {
  echo -e "${CYAN}Setting up rclone Google Drive...${NC}"
  
  # Install rclone if needed
  if ! command -v rclone &>/dev/null; then
    curl -fsSL https://rclone.org/install.sh | sudo bash
  fi
  
  echo -e "${CYAN}Configure Google Drive remote:${NC}"
  echo "1. Run: rclone config"
  echo "2. Choose: n (new remote)"
  echo "3. Name: gdrive"
  echo "4. Type: 17 (Google Drive)"
  echo "5. Follow OAuth flow"
  echo ""
  echo "Or for headless Pi: use --auth-no-open-browser flag"
  echo "rclone config --no-opt --auto-confirm"
  
  rclone config
}

sync_to_gdrive() {
  local source="${1:-$BLACKROAD_DIR}"
  local dest="${REMOTE_PATH}/$(basename $source)"
  
  echo -e "${CYAN}Syncing $(basename $source) → Google Drive...${NC}"
  
  rclone sync "$source" "$dest" \
    --exclude ".git/**" \
    --exclude "node_modules/**" \
    --exclude "*.pyc" \
    --exclude "__pycache__/**" \
    --exclude ".DS_Store" \
    --exclude "*.log" \
    --exclude "*.db-shm" \
    --exclude "*.db-wal" \
    --transfers 8 \
    --checkers 16 \
    --fast-list \
    --progress \
    --log-file "$LOG_FILE" \
    --log-level INFO \
    2>&1 | tail -5
    
  echo -e "${GREEN}✅ Synced to $dest${NC}"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"gdrive_sync\",\"source\":\"$source\",\"dest\":\"$dest\"}" \
    >> ~/.blackroad/memory/journals/master-journal.jsonl 2>/dev/null || true
}

setup_auto_sync() {
  echo -e "${CYAN}Setting up auto-sync cron (every 6 hours)...${NC}"
  
  CRON_JOB="0 */6 * * * bash $BLACKROAD_DIR/blackroad-infra/scripts/gdrive-sync.sh sync >> $LOG_FILE 2>&1"
  
  # Add to crontab if not already there
  (crontab -l 2>/dev/null | grep -v "gdrive-sync"; echo "$CRON_JOB") | crontab -
  echo -e "${GREEN}✅ Auto-sync scheduled every 6 hours${NC}"
  echo -e "${GREEN}   Log: $LOG_FILE${NC}"
}

case "${1:-sync}" in
  setup) setup_rclone ;;
  sync)  sync_to_gdrive "${2:-$BLACKROAD_DIR}" ;;
  auto)  setup_auto_sync ;;
  all)
    sync_to_gdrive "$BLACKROAD_DIR"
    sync_to_gdrive "$HOME/.blackroad"
    ;;
  *)
    echo "Usage: $0 [setup|sync [path]|auto|all]"
    ;;
esac
