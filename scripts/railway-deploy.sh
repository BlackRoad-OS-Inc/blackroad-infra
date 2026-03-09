#!/usr/bin/env bash
# BlackRoad Infrastructure — Railway deployment helper
# Usage: ./railway-deploy.sh [project-name] [--env production|staging]

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log()   { echo -e "${GREEN}✓${NC} $1"; }
info()  { echo -e "${CYAN}→${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

# ── Projects map ──────────────────────────────────────────────────────────────
declare -A PROJECTS=(
  ["gateway"]="aa968fb7-ec35-4a8b-92dc-1eba70fa8478"
  ["api"]="aa968fb7-ec35-4a8b-92dc-1eba70fa8478"
  ["prism-console"]="47f557cf-09b8-40df-8d77-b34f91ba90cc"
  ["beacon"]="8ac583cb-ffad-40bd-8676-6569783274d1"
  ["home"]="1a039a7e-a60c-42c5-be68-e66f9e269209"
)

PROJECT=${1:-gateway}
ENV=${2:-production}

if [[ ! -v PROJECTS[$PROJECT] ]]; then
  error "Unknown project '$PROJECT'. Known: ${!PROJECTS[*]}"
fi

PROJECT_ID="${PROJECTS[$PROJECT]}"
info "Deploying $PROJECT ($PROJECT_ID) to $ENV..."

# Check railway CLI
command -v railway >/dev/null 2>&1 || error "railway CLI not found. Install: npm install -g @railway/cli"

# Deploy
railway up --project "$PROJECT_ID" --environment "$ENV" --detach

log "Deployment triggered for $PROJECT"
info "Monitor: https://railway.app/project/$PROJECT_ID"

# Wait for health
info "Waiting for health check..."
sleep 15
railway status --project "$PROJECT_ID" --environment "$ENV" | head -5
