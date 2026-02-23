#!/usr/bin/env bash
# ============================================================
#  BlackRoad — GitHub Actions Self-Hosted Runner Setup
#  Installs a runner on each Pi so GitHub pushes trigger
#  deployments DIRECTLY on your hardware. $0/mo. No NAT tricks.
#  Pi connects OUT to GitHub — no open ports needed.
#
#  Usage:
#    ./setup-gh-runner.sh primary    # 192.168.4.64
#    ./setup-gh-runner.sh agents     # 192.168.4.38
#    ./setup-gh-runner.sh all        # all pis
#
#  Requires: GH_RUNNER_TOKEN env var
#    Get it from: github.com/BlackRoad-OS-Inc/blackroad-infra
#      → Settings → Actions → Runners → New self-hosted runner
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; AMBER='\033[38;5;214m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
warn() { echo -e "${AMBER}⚠${NC} $1"; }

# ── Pi fleet ─────────────────────────────────────────────────
declare -A PI_HOSTS=(
    [primary]="pi@192.168.4.64"
    [agents]="pi@192.168.4.38"
    [ops]="pi@192.168.4.49"
    [alt]="pi@192.168.4.99"
)

declare -A PI_LABELS=(
    [primary]="self-hosted,pi-fleet,primary,ARM64"
    [agents]="self-hosted,pi-fleet,agents,ARM64"
    [ops]="self-hosted,pi-fleet,ops,ARM64"
    [alt]="self-hosted,pi-fleet,alt,ARM64"
)

GH_ORG="BlackRoad-OS-Inc"
GH_REPO="blackroad-infra"
RUNNER_VERSION="2.323.0"
# Check latest: https://github.com/actions/runner/releases

: "${GH_RUNNER_TOKEN:?Set GH_RUNNER_TOKEN — get from GitHub → Settings → Actions → Runners}"

install_runner() {
    local name="$1"
    local host="${PI_HOSTS[$name]}"
    local labels="${PI_LABELS[$name]}"

    info "Installing runner '$name' on $host (labels: $labels)..."

    ssh "$host" "
        set -e
        
        # ── 1. Install dependencies ───────────────────────────
        sudo apt-get update -qq
        sudo apt-get install -y curl jq git -qq

        # ── 2. Create runner directory ────────────────────────
        mkdir -p ~/actions-runner && cd ~/actions-runner

        # ── 3. Download runner (ARM64 for Pi) ─────────────────
        if [ ! -f actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz ]; then
            curl -sOL https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz
        fi
        tar xzf actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

        # ── 4. Configure runner ───────────────────────────────
        # Unattended config — connects to BlackRoad-OS-Inc/blackroad-infra
        ./config.sh \
            --url https://github.com/${GH_ORG}/${GH_REPO} \
            --token ${GH_RUNNER_TOKEN} \
            --name blackroad-pi-${name} \
            --labels '${labels}' \
            --work /tmp/runner-work \
            --unattended \
            --replace

        # ── 5. Install as systemd service ─────────────────────
        sudo ./svc.sh install
        sudo ./svc.sh start
        sudo ./svc.sh status
        echo '✓ Runner service active'
    " && log "Runner '$name' installed on $host" || warn "Could not reach $host"
}

check_runners() {
    info "Checking runner status on all Pis..."
    for name in "${!PI_HOSTS[@]}"; do
        local host="${PI_HOSTS[$name]}"
        echo -e "\n${CYAN}── $name ($host) ──${NC}"
        ssh "$host" "
            cd ~/actions-runner 2>/dev/null && sudo ./svc.sh status 2>/dev/null || echo 'Runner not installed'
        " 2>/dev/null || warn "unreachable"
    done
}

remove_runner() {
    local name="$1"
    local host="${PI_HOSTS[$name]}"
    info "Removing runner '$name' from $host..."
    ssh "$host" "
        cd ~/actions-runner
        sudo ./svc.sh stop
        sudo ./svc.sh uninstall
        ./config.sh remove --token ${GH_RUNNER_TOKEN}
        echo '✓ Runner removed'
    "
}

# ── Main ──────────────────────────────────────────────────────
case "${1:-help}" in
    primary|agents|ops|alt)
        install_runner "$1"
        ;;
    all)
        echo ""
        echo -e "${AMBER}  Installing GitHub Actions runners on Pi fleet...${NC}"
        echo -e "${CYAN}  Org: ${GH_ORG} | Repo: ${GH_REPO}${NC}"
        echo -e "${CYAN}  Pi fleet: ${!PI_HOSTS[*]}${NC}"
        echo ""

        for name in primary agents ops; do
            install_runner "$name"
        done

        echo ""
        log "All runners installed!"
        echo ""
        echo -e "  ${CYAN}GitHub push flow:${NC}"
        echo -e "  git push → GitHub → self-hosted runner on Pi → deploy locally"
        echo ""
        echo -e "  ${CYAN}View runners at:${NC}"
        echo -e "  https://github.com/${GH_ORG}/${GH_REPO}/settings/actions/runners"
        ;;
    status) check_runners ;;
    remove) remove_runner "${2:?Specify runner name}" ;;
    *)
        echo "Usage: GH_RUNNER_TOKEN=<token> $0 [all|primary|agents|ops|alt|status|remove <name>]"
        echo ""
        echo "Get token:"
        echo "  github.com/${GH_ORG}/${GH_REPO} → Settings → Actions → Runners → New self-hosted runner"
        ;;
esac
