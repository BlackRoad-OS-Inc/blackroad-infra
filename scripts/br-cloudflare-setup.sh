#!/bin/zsh
# BlackRoad OS — Cloudflare Full Setup
# Points all 20 domains → Pi tunnel

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
hdr()  { echo -e "\n${BOLD}══ $1 ══${NC}"; }

CF_API="https://api.cloudflare.com/client/v4"
TUNNEL_CNAME="52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com"
ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"
TUNNEL_ID="52915859-da18-4aa6-add5-7bd9fcac2e0b"

# ── Get Global API Key interactively if not set ───────────────
if [[ -z "${CF_GLOBAL_KEY:-}" ]]; then
    echo ""
    echo -e "${BOLD}Get your Global API Key:${NC}"
    echo "  1. Open: https://dash.cloudflare.com/profile/api-tokens"
    echo "  2. Scroll to bottom → Global API Key → View"
    echo "  3. Paste it here:"
    echo ""
    echo -n "  CF_GLOBAL_KEY: "
    read -s CF_GLOBAL_KEY
    echo ""
fi
CF_EMAIL="${CF_EMAIL:-amundsonalexa@gmail.com}"

# ── CF API helper ─────────────────────────────────────────────
cf() {
    local method=$1 path=$2 data=${3:-}
    if [[ -n "$data" ]]; then
        curl -s -X "$method" "${CF_API}${path}" \
            -H "X-Auth-Email: ${CF_EMAIL}" \
            -H "X-Auth-Key: ${CF_GLOBAL_KEY}" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${CF_API}${path}" \
            -H "X-Auth-Email: ${CF_EMAIL}" \
            -H "X-Auth-Key: ${CF_GLOBAL_KEY}" \
            -H "Content-Type: application/json"
    fi
}

# ── Verify auth ───────────────────────────────────────────────
hdr "Verifying auth"
email=$(cf GET "/user" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d['result']['email'] if d.get('success') else 'FAILED')
")
if [[ "$email" != *"@"* ]]; then
    err "Auth failed — check your Global API Key"
    exit 1
fi
log "Authenticated: $email"

# ── Zone list: "domain zone_id" ───────────────────────────────
ZONE_PAIRS=(
    "aliceqi.com 927cead26cb27df79577db1bffbf2dfa"
    "blackboxprogramming.io 6e27d41cb2d27cd8f2f26e95608d3899"
    "blackroadai.com 590afe2b9b2ae222e77d89c10b7412d3"
    "blackroad.company f654e077612d3d240f96300b7c0c6cae"
    "blackroadinc.us decb1bf816ff29197d88751228ad0017"
    "blackroad.io d6566eba4500b460ffec6650d3b4baf6"
    "blackroad.me 622395674d479bad0a7d3790722c14be"
    "blackroad.network fae5a76a78154e0509bede2e3eba8124"
    "blackroadqi.com e24dbdfd8868183e4093b8cdba709240"
    "blackroadquantum.com 1c93ece77e64728f506d635f5b58c60a"
    "blackroadquantum.info 9855ce5bf6602150ea9195f3cd975d3e"
    "blackroadquantum.net 7d606471c0feab151c8ad493fd8a5c8e"
    "blackroadquantum.shop b842746ff2e811c1be959e5a843b25e6"
    "blackroadquantum.store 498fef62d7a9812e69413e7451edf3b1"
    "blackroad.systems 13293825c2b0491085cbece9fc02e401"
    "lucidia.earth a91af33930bb9b9ddfa0cf12c0232460"
    "lucidiaqi.com 8a787536b6dd285bdf06dde65e96e8c0"
    "lucidia.studio 43edda4c64475e5d81934ec7f64f6801"
    "roadchain.io 86d82685f669fe45d0ee6d24ef21b255"
    "roadcoin.io 111d9214d54a282b1e889fa3d1e2faa8"
)

# ── Upsert one CNAME ──────────────────────────────────────────
upsert() {
    local zone_id=$1 name=$2
    local body="{\"type\":\"CNAME\",\"name\":\"${name}\",\"content\":\"${TUNNEL_CNAME}\",\"proxied\":true,\"ttl\":1}"
    local existing
    existing=$(cf GET "/zones/${zone_id}/dns_records?type=CNAME&name=${name}" | \
        python3 -c "import sys,json; r=json.load(sys.stdin)['result']; print(r[0]['id'] if r else '')" 2>/dev/null)
    if [[ -n "$existing" ]]; then
        r=$(cf PUT "/zones/${zone_id}/dns_records/${existing}" "$body" | \
            python3 -c "import sys,json; d=json.load(sys.stdin); print('ok' if d['success'] else str(d['errors']))")
        [[ "$r" == "ok" ]] && log "  $name (updated)" || err "  $name — $r"
    else
        r=$(cf POST "/zones/${zone_id}/dns_records" "$body" | \
            python3 -c "import sys,json; d=json.load(sys.stdin); print('ok' if d['success'] else str(d['errors']))")
        [[ "$r" == "ok" ]] && log "  $name (created)" || err "  $name — $r"
    fi
}

# ── Step 1: DNS ───────────────────────────────────────────────
hdr "DNS — all 20 zones → tunnel"

for pair in "${ZONE_PAIRS[@]}"; do
    domain=${pair%% *}
    zid=${pair##* }
    info "$domain"
    upsert "$zid" "$domain"
    upsert "$zid" "www.${domain}"
done

# Extra subdomains for blackroad.io
BIO_ZID="d6566eba4500b460ffec6650d3b4baf6"
info "blackroad.io subdomains"
for sub in agents api gateway ollama dashboard docs hub console app chat admin status metrics auth deploy; do
    upsert "$BIO_ZID" "${sub}.blackroad.io"
done

# ── Step 2: Tunnel ingress ────────────────────────────────────
hdr "Updating tunnel ingress rules"

INGRESS_JSON=$(python3 << 'PYEOF'
import json
routes = [
    ("agents.blackroad.io",    "http://localhost:8080"),
    ("api.blackroad.io",       "http://localhost:3000"),
    ("gateway.blackroad.io",   "http://localhost:8787"),
    ("ollama.blackroad.io",    "http://localhost:11434"),
    ("dashboard.blackroad.io", "http://localhost:4000"),
    ("hub.blackroad.io",       "http://localhost:4000"),
    ("console.blackroad.io",   "http://localhost:4000"),
    ("docs.blackroad.io",      "http://localhost:3001"),
    ("status.blackroad.io",    "http://localhost:8090"),
    ("metrics.blackroad.io",   "http://localhost:8090"),
    ("app.blackroad.io",       "http://localhost:3000"),
    ("chat.blackroad.io",      "http://localhost:8080"),
    ("auth.blackroad.io",      "http://localhost:3000"),
    ("admin.blackroad.io",     "http://localhost:4000"),
    ("deploy.blackroad.io",    "http://localhost:8080"),
    ("health.blackroad.io",    "http://localhost:8090"),
    ("models.blackroadai.com", "http://localhost:11434"),
    ("chat.blackroadai.com",   "http://localhost:8080"),
    ("app.lucidia.earth",      "http://localhost:3000"),
    ("chat.lucidia.earth",     "http://localhost:8080"),
    ("app.roadchain.io",       "http://localhost:3000"),
    ("app.roadcoin.io",        "http://localhost:3000"),
    ("*.blackroad.io",         "http://localhost:3000"),
    ("*.lucidia.earth",        "http://localhost:3000"),
    ("*.blackroadai.com",      "http://localhost:3000"),
    ("*.roadchain.io",         "http://localhost:3000"),
    ("*.roadcoin.io",          "http://localhost:3000"),
    ("blackroad.io",           "http://localhost:3000"),
    ("blackroad.me",           "http://localhost:3000"),
    ("blackroad.network",      "http://localhost:3000"),
    ("blackroad.systems",      "http://localhost:3000"),
    ("blackroad.company",      "http://localhost:3000"),
    ("blackroadinc.us",        "http://localhost:3000"),
    ("blackroadai.com",        "http://localhost:3000"),
    ("blackroadqi.com",        "http://localhost:3000"),
    ("blackboxprogramming.io", "http://localhost:3000"),
    ("aliceqi.com",            "http://localhost:3000"),
    ("lucidiaqi.com",          "http://localhost:3000"),
    ("lucidia.earth",          "http://localhost:3000"),
    ("lucidia.studio",         "http://localhost:3000"),
    ("roadchain.io",           "http://localhost:3000"),
    ("roadcoin.io",            "http://localhost:3000"),
    ("blackroadquantum.com",   "http://localhost:3000"),
    ("blackroadquantum.net",   "http://localhost:3000"),
    ("blackroadquantum.info",  "http://localhost:3000"),
    ("blackroadquantum.shop",  "http://localhost:3000"),
    ("blackroadquantum.store", "http://localhost:3000"),
]
ingress = [{"hostname": h, "service": s} for h, s in routes]
ingress.append({"service": "http_status:404"})
print(json.dumps({"config": {"ingress": ingress}}))
PYEOF
)

r=$(cf PUT "/accounts/${ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations" "$INGRESS_JSON" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print('ok' if d['success'] else str(d['errors']))")
[[ "$r" == "ok" ]] && log "Tunnel ingress updated" || err "Tunnel update: $r"

# ── Step 3: Verify spot-check ─────────────────────────────────
hdr "Spot-check DNS"
sleep 2
for host in blackroad.io agents.blackroad.io lucidia.earth roadchain.io blackroadquantum.com; do
    result=$(dig +short CNAME "$host" 2>/dev/null || echo "")
    if [[ "$result" == *"cfargotunnel"* ]]; then
        log "$host → tunnel ✓"
    else
        echo -e "  ${YELLOW}⏳${NC} $host → ${result:-propagating...}"
    fi
done

echo ""
log "Done! All 20 domains → Pi tunnel"
echo ""
echo -e "${YELLOW}Now revoke your Global API Key:${NC}"
echo "  https://dash.cloudflare.com/profile/api-tokens"
