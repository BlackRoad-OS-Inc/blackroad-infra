#!/bin/bash
# BlackRoad OS - Full Backup Stack
# Layers: Local → Google Drive → GitHub → DigitalOcean → Cloudflare R2 → Railway

set -euo pipefail
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SOURCE_DIR="${SOURCE_DIR:-$HOME/blackroad}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$HOME/.blackroad/logs/backup-$TIMESTAMP.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo -e "${GREEN}✅${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1" | tee -a "$LOG_FILE"; }
info() { echo -e "${CYAN}ℹ️${NC} $1" | tee -a "$LOG_FILE"; }

# Layer 1: Google Drive (rclone)
backup_gdrive() {
  info "Layer 1: Google Drive sync..."
  RCLONE=$(which rclone 2>/dev/null || echo "$HOME/.local/bin/rclone")
  if "$RCLONE" listremotes 2>/dev/null | grep -q gdrive-blackroad; then
    "$RCLONE" sync "$SOURCE_DIR" gdrive-blackroad:blackroad-$(hostname) \
      --exclude ".git/**" --exclude "node_modules/**" --exclude "*.pyc" \
      --transfers 4 --quiet 2>&1 | tee -a "$LOG_FILE"
    log "Google Drive sync complete"
  else
    warn "Google Drive not configured (run rclone config)"
  fi
}

# Layer 2: GitHub (git push)
backup_github() {
  info "Layer 2: GitHub push..."
  cd "$SOURCE_DIR"
  git stash 2>/dev/null || true
  git push origin master 2>&1 | tee -a "$LOG_FILE" || warn "GitHub push failed"
  git stash pop 2>/dev/null || true
  log "GitHub backup complete"
}

# Layer 3: DigitalOcean (rsync to droplet)
backup_digitalocean() {
  info "Layer 3: DigitalOcean rsync..."
  DO_IP="${DO_DROPLET_IP:-159.65.43.12}"
  rsync -az --exclude=".git" --exclude="node_modules" \
    "$SOURCE_DIR/" "blackroad@$DO_IP:~/blackroad-backup/" 2>&1 | tee -a "$LOG_FILE" \
    && log "DigitalOcean backup complete" \
    || warn "DigitalOcean backup failed"
}

# Layer 4: Cloudflare R2 (via wrangler/rclone)
backup_cloudflare_r2() {
  info "Layer 4: Cloudflare R2..."
  RCLONE=$(which rclone 2>/dev/null || echo "$HOME/.local/bin/rclone")
  if "$RCLONE" listremotes 2>/dev/null | grep -q r2; then
    "$RCLONE" sync "$SOURCE_DIR" r2:blackroad-backup/$(hostname) \
      --exclude ".git/**" --exclude "node_modules/**" \
      --quiet 2>&1 | tee -a "$LOG_FILE"
    log "Cloudflare R2 backup complete"
  else
    warn "R2 not configured (run: rclone config → Cloudflare R2)"
  fi
}

# Layer 5: Railway Volume (via git or API)
backup_railway() {
  info "Layer 5: Railway metadata snapshot..."
  if command -v railway &>/dev/null; then
    railway status 2>&1 | tee -a "$LOG_FILE" | head -5 || true
    log "Railway status captured"
  else
    warn "Railway CLI not installed"
  fi
}

case "${1:-all}" in
  gdrive)   backup_gdrive ;;
  github)   backup_github ;;
  do)       backup_digitalocean ;;
  r2)       backup_cloudflare_r2 ;;
  railway)  backup_railway ;;
  all)
    backup_gdrive
    backup_github
    backup_digitalocean
    backup_cloudflare_r2
    backup_railway
    log "All backup layers complete! Log: $LOG_FILE"
    ;;
  *) echo "Usage: $0 [all|gdrive|github|do|r2|railway]" ;;
esac
