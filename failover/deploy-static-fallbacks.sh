#!/usr/bin/env bash
# ============================================================
#  BlackRoad — Static Fallback Builder
#  Builds and deploys minimal static version to:
#    Tier 3: Vercel   (vercel --prod)
#    Tier 4: CF Pages (wrangler pages deploy)
#    Tier 5: GitHub Pages (gh-pages branch)
#
#  This runs on every main branch push via GitHub Actions.
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; AMBER='\033[38;5;214m'; NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATIC_DIR="$SCRIPT_DIR/static-fallback"
DIST_DIR="$SCRIPT_DIR/static-fallback/dist"

build_static() {
    info "Building static fallback..."
    mkdir -p "$DIST_DIR"

    # Copy static site assets
    cp "$STATIC_DIR/index.html" "$DIST_DIR/"
    cp "$STATIC_DIR/status.html" "$DIST_DIR/"

    # Create a _routes.json for CF Pages
    cat > "$DIST_DIR/_routes.json" << 'EOF'
{
  "version": 1,
  "include": ["/*"],
  "exclude": []
}
EOF

    # Vercel config
    cat > "$DIST_DIR/vercel.json" << 'EOF'
{
  "cleanUrls": true,
  "trailingSlash": false
}
EOF

    log "Static build complete → $DIST_DIR"
}

deploy_vercel() {
    info "Deploying to Vercel (Tier 3)..."
    cd "$DIST_DIR"
    if command -v vercel &>/dev/null; then
        vercel --prod --yes 2>&1 | tail -5
        log "Vercel deployed"
    else
        log "vercel CLI not found — skipping (install: npm i -g vercel)"
    fi
}

deploy_cf_pages() {
    info "Deploying to Cloudflare Pages (Tier 4)..."
    cd "$DIST_DIR"
    if command -v wrangler &>/dev/null; then
        wrangler pages deploy . --project-name=blackroad-os-fallback 2>&1 | tail -5
        log "CF Pages deployed"
    else
        log "wrangler not found — skipping"
    fi
}

deploy_gh_pages() {
    info "Deploying to GitHub Pages (Tier 5)..."
    cd "$DIST_DIR"
    if command -v gh &>/dev/null; then
        git init -q
        git add -A
        git commit -m "chore: static fallback build $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        git push --force git@github.com:BlackRoad-OS/blackroad.git HEAD:gh-pages 2>&1 | tail -3
        rm -rf .git
        log "GitHub Pages deployed"
    else
        log "gh not found — skipping"
    fi
}

case "${1:-all}" in
    build)  build_static ;;
    vercel) build_static && deploy_vercel ;;
    pages)  build_static && deploy_cf_pages ;;
    gh)     build_static && deploy_gh_pages ;;
    all)
        build_static
        deploy_vercel
        deploy_cf_pages
        deploy_gh_pages
        echo ""
        log "All static fallback tiers deployed!"
        echo -e "  ${CYAN}Tier 3:${NC} Vercel"
        echo -e "  ${CYAN}Tier 4:${NC} Cloudflare Pages"
        echo -e "  ${CYAN}Tier 5:${NC} GitHub Pages"
        ;;
    *) echo "Usage: $0 [build|vercel|pages|gh|all]" ;;
esac
