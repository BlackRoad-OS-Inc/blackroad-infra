#!/bin/bash
# [DEPLOY] System - Deployment tracking for BlackRoad
# Usage: ~/deploy-system.sh <command> [args]

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
RESET='\033[0m'

DEPLOY_DB="$HOME/.blackroad/deploy.db"

init_deploy() {
    mkdir -p "$HOME/.blackroad"
    sqlite3 "$DEPLOY_DB" <<EOF
CREATE TABLE IF NOT EXISTS deployments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    service TEXT NOT NULL,
    environment TEXT DEFAULT 'production',
    platform TEXT NOT NULL,
    url TEXT,
    version TEXT,
    status TEXT DEFAULT 'pending',
    deployed_by TEXT,
    deployed_at TEXT DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS platforms (
    name TEXT PRIMARY KEY,
    type TEXT,
    config TEXT,
    last_used TEXT
);

CREATE TABLE IF NOT EXISTS rollbacks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deployment_id INTEGER,
    reason TEXT,
    rolled_back_at TEXT DEFAULT CURRENT_TIMESTAMP
);
EOF

    # Seed platforms
    sqlite3 "$DEPLOY_DB" "INSERT OR IGNORE INTO platforms (name, type) VALUES
        ('cloudflare', 'pages'),
        ('railway', 'container'),
        ('vercel', 'serverless'),
        ('digitalocean', 'droplet'),
        ('github-pages', 'static'),
        ('pi-cluster', 'edge');"

    echo -e "${GREEN}[DEPLOY]${RESET} System initialized"
}

# Log a deployment
log() {
    local service="$1"
    local platform="$2"
    local url="${3:-}"
    local version="${4:-latest}"
    local env="${5:-production}"
    local deployer="${6:-$USER}"

    sqlite3 "$DEPLOY_DB" "INSERT INTO deployments (service, platform, url, version, environment, status, deployed_by) VALUES ('$service', '$platform', '$url', '$version', '$env', 'success', '$deployer');"
    sqlite3 "$DEPLOY_DB" "UPDATE platforms SET last_used=datetime('now') WHERE name='$platform';"

    echo -e "${GREEN}[DEPLOY]${RESET} Logged: $service -> $platform ($env)"
}

# List recent deployments
list() {
    local filter="${1:-}"
    echo -e "${AMBER}[DEPLOY]${RESET} Recent Deployments"
    echo ""
    if [[ -n "$filter" ]]; then
        sqlite3 -column -header "$DEPLOY_DB" "SELECT id, service, platform, environment, status, deployed_at FROM deployments WHERE service LIKE '%$filter%' OR platform='$filter' ORDER BY deployed_at DESC LIMIT 20;"
    else
        sqlite3 -column -header "$DEPLOY_DB" "SELECT id, service, platform, environment, status, deployed_at FROM deployments ORDER BY deployed_at DESC LIMIT 20;"
    fi
}

# Get deployment by service
get() {
    local service="$1"
    sqlite3 -column -header "$DEPLOY_DB" "SELECT * FROM deployments WHERE service='$service' ORDER BY deployed_at DESC LIMIT 1;"
}

# List by platform
platform() {
    local platform="$1"
    echo -e "${AMBER}[DEPLOY]${RESET} Deployments on $platform"
    sqlite3 -column -header "$DEPLOY_DB" "SELECT service, url, version, status, deployed_at FROM deployments WHERE platform='$platform' ORDER BY deployed_at DESC LIMIT 20;"
}

# Rollback
rollback() {
    local deployment_id="$1"
    local reason="$2"
    sqlite3 "$DEPLOY_DB" "UPDATE deployments SET status='rolled_back' WHERE id=$deployment_id;"
    sqlite3 "$DEPLOY_DB" "INSERT INTO rollbacks (deployment_id, reason) VALUES ($deployment_id, '$reason');"
    echo -e "${RED}[DEPLOY]${RESET} Rollback logged for deployment #$deployment_id"
}

# Stats
stats() {
    echo -e "${PINK}╔══════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║${RESET}       ${AMBER}[DEPLOY] System Stats${RESET}        ${PINK}║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════╝${RESET}"
    echo ""

    local total=$(sqlite3 "$DEPLOY_DB" "SELECT COUNT(*) FROM deployments;")
    local success=$(sqlite3 "$DEPLOY_DB" "SELECT COUNT(*) FROM deployments WHERE status='success';")
    local rollbacks=$(sqlite3 "$DEPLOY_DB" "SELECT COUNT(*) FROM rollbacks;")
    local services=$(sqlite3 "$DEPLOY_DB" "SELECT COUNT(DISTINCT service) FROM deployments;")
    local today=$(sqlite3 "$DEPLOY_DB" "SELECT COUNT(*) FROM deployments WHERE date(deployed_at)=date('now');")

    echo -e "  ${GREEN}Total Deploys:${RESET}  $total"
    echo -e "  ${GREEN}Successful:${RESET}     $success"
    echo -e "  ${GREEN}Rollbacks:${RESET}      $rollbacks"
    echo -e "  ${GREEN}Services:${RESET}       $services"
    echo -e "  ${GREEN}Today:${RESET}          $today"
    echo ""
    echo -e "${BLUE}By Platform:${RESET}"
    sqlite3 -column "$DEPLOY_DB" "SELECT platform, COUNT(*) as deploys FROM deployments GROUP BY platform ORDER BY deploys DESC;"
}

show_help() {
    echo -e "${PINK}[DEPLOY]${RESET} - BlackRoad Deployment Tracking"
    echo ""
    echo "Usage: ~/deploy-system.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  init                                    Initialize system"
    echo "  log <service> <platform> [url] [ver]   Log deployment"
    echo "  list [filter]                           List deployments"
    echo "  get <service>                           Get latest for service"
    echo "  platform <name>                         List by platform"
    echo "  rollback <id> <reason>                  Log rollback"
    echo "  stats                                   Show statistics"
    echo ""
    echo "Platforms: cloudflare, railway, vercel, digitalocean, github-pages, pi-cluster"
}

case "${1:-help}" in
    init)       init_deploy ;;
    log)        log "$2" "$3" "$4" "$5" "$6" "$7" ;;
    list)       list "$2" ;;
    get)        get "$2" ;;
    platform)   platform "$2" ;;
    rollback)   rollback "$2" "$3" ;;
    stats)      stats ;;
    help|*)     show_help ;;
esac
