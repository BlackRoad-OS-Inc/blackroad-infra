#!/usr/bin/env bash
# ============================================================
#  BlackRoad — Cloudflare DNS Bulk Setup
#  Points ALL domains/subdomains → Cloudflare tunnel (CNAME)
#
#  Tunnel: 52915859-da18-4aa6-add5-7bd9fcac2e0b
#  CNAME target: <tunnel-id>.cfargotunnel.com
#
#  Usage:
#    export CF_API_TOKEN=<your-token>   # Needs Zone:DNS:Edit
#    ./scripts/cf-dns-setup.sh
#    ./scripts/cf-dns-setup.sh --dry-run   # show what would be created
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; AMBER='\033[38;5;214m'; CYAN='\033[0;36m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
warn() { echo -e "${AMBER}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1" >&2; }
hdr()  { echo -e "\n${BOLD}${CYAN}$1${NC}"; }

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

CF_API_TOKEN="${CF_API_TOKEN:-}"
if [[ -z "$CF_API_TOKEN" ]]; then
    err "CF_API_TOKEN not set. Export your Cloudflare API token with Zone:DNS:Edit permission."
    exit 1
fi

TUNNEL_ID="52915859-da18-4aa6-add5-7bd9fcac2e0b"
TUNNEL_CNAME="${TUNNEL_ID}.cfargotunnel.com"
CF_API="https://api.cloudflare.com/client/v4"

# ── CF API helpers ────────────────────────────────────────────
cf_get() {
    curl -sf -H "Authorization: Bearer $CF_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${CF_API}$1"
}

cf_post() {
    local endpoint="$1"; shift
    local body="$1"
    curl -sf -X POST \
         -H "Authorization: Bearer $CF_API_TOKEN" \
         -H "Content-Type: application/json" \
         -d "$body" \
         "${CF_API}${endpoint}"
}

cf_put() {
    local endpoint="$1"; shift
    local body="$1"
    curl -sf -X PUT \
         -H "Authorization: Bearer $CF_API_TOKEN" \
         -H "Content-Type: application/json" \
         -d "$body" \
         "${CF_API}${endpoint}"
}

# ── Get zone ID for a domain ──────────────────────────────────
get_zone_id() {
    local domain="$1"
    cf_get "/zones?name=${domain}&status=active" | \
        python3 -c "import sys,json; z=json.load(sys.stdin)['result']; print(z[0]['id'] if z else '')" 2>/dev/null
}

# ── Upsert CNAME record ───────────────────────────────────────
upsert_cname() {
    local zone_id="$1"
    local name="$2"       # subdomain or @ for root
    local content="$3"    # CNAME target
    local proxied="${4:-true}"

    if [[ "$DRY_RUN" == "true" ]]; then
        info "  [DRY-RUN] CNAME ${name} → ${content} (proxied=${proxied})"
        return 0
    fi

    # Check if record exists
    local existing
    existing=$(cf_get "/zones/${zone_id}/dns_records?type=CNAME&name=${name}" | \
        python3 -c "import sys,json; r=json.load(sys.stdin)['result']; print(r[0]['id'] if r else '')" 2>/dev/null)

    local body="{\"type\":\"CNAME\",\"name\":\"${name}\",\"content\":\"${content}\",\"proxied\":${proxied},\"ttl\":1}"

    if [[ -n "$existing" ]]; then
        if cf_put "/zones/${zone_id}/dns_records/${existing}" "$body" | python3 -c "import sys,json; print('ok' if json.load(sys.stdin)['success'] else 'fail')" | grep -q ok; then
            info "  updated  ${name}"
        else
            warn "  failed   ${name}"
        fi
    else
        if cf_post "/zones/${zone_id}/dns_records" "$body" | python3 -c "import sys,json; print('ok' if json.load(sys.stdin)['success'] else 'fail')" | grep -q ok; then
            log "  created  ${name}"
        else
            warn "  failed   ${name}"
        fi
    fi
}

# ============================================================
#  Domain definitions — each entry: "domain subdomains..."
# ============================================================

setup_blackroad_io() {
    hdr "blackroad.io"
    local zone_id
    zone_id=$(get_zone_id "blackroad.io")
    if [[ -z "$zone_id" ]]; then warn "Zone blackroad.io not found in your CF account"; return; fi
    info "Zone ID: $zone_id"

    # Root
    upsert_cname "$zone_id" "blackroad.io"        "$TUNNEL_CNAME"
    upsert_cname "$zone_id" "www.blackroad.io"    "$TUNNEL_CNAME"

    # Services
    for sub in agents api ollama gateway ws health stats docs dashboard home \
               earth demo brand console control admin analytics creator-studio \
               creator studio devops education finance legal ideas research-lab \
               chat git deploy status operator prism mesh builder workflows \
               store payment buy-now company portals unified assets status-new \
               pitstop systems llm model dev blog cdn cli tools; do
        upsert_cname "$zone_id" "${sub}.blackroad.io" "$TUNNEL_CNAME"
    done
}

setup_lucidia_earth() {
    hdr "lucidia.earth"
    local zone_id
    zone_id=$(get_zone_id "lucidia.earth")
    if [[ -z "$zone_id" ]]; then warn "Zone lucidia.earth not found in your CF account"; return; fi
    info "Zone ID: $zone_id"

    upsert_cname "$zone_id" "lucidia.earth"       "$TUNNEL_CNAME"
    upsert_cname "$zone_id" "www.lucidia.earth"   "$TUNNEL_CNAME"
    for sub in api ws admin docs dev gateway; do
        upsert_cname "$zone_id" "${sub}.lucidia.earth" "$TUNNEL_CNAME"
    done
}

setup_blackroad_systems() {
    hdr "blackroad.systems"
    local zone_id
    zone_id=$(get_zone_id "blackroad.systems")
    if [[ -z "$zone_id" ]]; then warn "Zone blackroad.systems not found"; return; fi
    info "Zone ID: $zone_id"
    upsert_cname "$zone_id" "blackroad.systems"     "$TUNNEL_CNAME"
    upsert_cname "$zone_id" "www.blackroad.systems" "$TUNNEL_CNAME"
    upsert_cname "$zone_id" "api.blackroad.systems" "$TUNNEL_CNAME"
}

setup_blackroad_me() {
    hdr "blackroad.me"
    local zone_id
    zone_id=$(get_zone_id "blackroad.me")
    if [[ -z "$zone_id" ]]; then warn "Zone blackroad.me not found"; return; fi
    info "Zone ID: $zone_id"
    upsert_cname "$zone_id" "blackroad.me"     "$TUNNEL_CNAME"
    upsert_cname "$zone_id" "www.blackroad.me" "$TUNNEL_CNAME"
}

setup_quantum_suite() {
    hdr "Quantum suite"
    for domain in blackroadqi.com blackroadquantum.info blackroadquantum.net blackroadquantum.shop blackroadquantum.store; do
        local zone_id
        zone_id=$(get_zone_id "$domain")
        if [[ -z "$zone_id" ]]; then warn "Zone $domain not found"; continue; fi
        info "  $domain → zone $zone_id"
        upsert_cname "$zone_id" "$domain"       "$TUNNEL_CNAME"
        upsert_cname "$zone_id" "www.$domain"   "$TUNNEL_CNAME"
    done
}

setup_road_domains() {
    hdr "Road domains"
    for domain in roadchain.io roadcoin.io; do
        local zone_id
        zone_id=$(get_zone_id "$domain")
        if [[ -z "$zone_id" ]]; then warn "Zone $domain not found"; continue; fi
        info "  $domain → zone $zone_id"
        upsert_cname "$zone_id" "$domain"       "$TUNNEL_CNAME"
        upsert_cname "$zone_id" "www.$domain"   "$TUNNEL_CNAME"
        upsert_cname "$zone_id" "api.$domain"   "$TUNNEL_CNAME"
    done
}

# ============================================================
#  Run
# ============================================================
echo -e "${BOLD}BlackRoad DNS → Tunnel Setup${NC}"
echo    "Tunnel:  $TUNNEL_ID"
echo    "CNAME:   $TUNNEL_CNAME"
[[ "$DRY_RUN" == "true" ]] && echo -e "${AMBER}DRY-RUN mode — no changes will be made${NC}"
echo

setup_blackroad_io
setup_lucidia_earth
setup_blackroad_systems
setup_blackroad_me
setup_quantum_suite
setup_road_domains

echo
log "DNS setup complete!"
echo
echo "Next steps:"
echo "  1. SSH to primary Pi (192.168.4.64)"
echo "  2. sudo cloudflared service restart"
echo "  3. cloudflared tunnel info blackroad"
echo "  4. ./scripts/verify-tunnel.sh"
