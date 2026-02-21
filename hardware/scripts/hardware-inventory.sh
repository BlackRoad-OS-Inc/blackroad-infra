#!/bin/bash
# BlackRoad Hardware Inventory
# Queries agent registry + live network scan to produce fleet status
# Usage: ./hardware-inventory.sh [--live] [--json]

set -e

PINK='\033[38;5;205m'
GREEN='\033[38;5;82m'
AMBER='\033[38;5;214m'
RED='\033[38;5;196m'
CYAN='\033[38;5;81m'
RESET='\033[0m'
BOLD='\033[1m'

DB="$HOME/.blackroad-agent-registry.db"
LIVE_SCAN=false
JSON_OUTPUT=false

for arg in "$@"; do
  case $arg in
    --live) LIVE_SCAN=true ;;
    --json) JSON_OUTPUT=true ;;
    --help|-h)
      echo "Usage: $0 [--live] [--json]"
      echo "  --live  Ping each device to check reachability"
      echo "  --json  Output as JSON instead of table"
      exit 0
      ;;
  esac
done

echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  BLACKROAD HARDWARE INVENTORY${RESET}"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Check database exists
if [ ! -f "$DB" ]; then
  echo -e "${RED}  Error: Agent registry not found at $DB${RESET}"
  exit 1
fi

# Query hardware agents
echo -e "${CYAN}  Hardware Agents from Registry:${RESET}"
echo ""
printf "  ${BOLD}%-15s %-28s %-16s %-16s %-8s${RESET}\n" "NAME" "PLATFORM" "IP (LOCAL)" "IP (TAILSCALE)" "STATUS"
echo "  ─────────────────────────────────────────────────────────────────────────────────────"

sqlite3 -separator '|' "$DB" \
  "SELECT name, platform, COALESCE(ip_local,'—'), COALESCE(ip_tailscale,'—'), status FROM agents WHERE type='hardware' ORDER BY name;" \
| while IFS='|' read -r name platform ip_local ip_ts status; do
  if [ "$status" = "active" ]; then
    status_color="${GREEN}active${RESET}"
  elif [ "$status" = "offline" ]; then
    status_color="${RED}offline${RESET}"
  else
    status_color="${AMBER}${status}${RESET}"
  fi

  if $LIVE_SCAN && [ "$ip_local" != "—" ]; then
    if ping -c 1 -W 1 "$ip_local" &>/dev/null; then
      status_color="${GREEN}online${RESET}"
    else
      status_color="${RED}unreachable${RESET}"
    fi
  fi

  printf "  %-15s %-28s %-16s %-16s " "$name" "$platform" "$ip_local" "$ip_ts"
  echo -e "$status_color"
done

echo ""

# Summary stats
TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM agents WHERE type='hardware';")
ACTIVE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM agents WHERE type='hardware' AND status='active';")
OFFLINE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM agents WHERE type='hardware' AND status='offline';")

echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${BOLD}Total:${RESET} $TOTAL devices  |  ${GREEN}Active:${RESET} $ACTIVE  |  ${RED}Offline:${RESET} $OFFLINE"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Accelerator summary
echo ""
echo -e "${CYAN}  AI Accelerators:${RESET}"
echo "  ─────────────────────────────────────────"
echo "  Hailo-8 M.2 x3     78 TOPS  (Cecilia, Octavia, Aria)"
echo "  Jetson Orin Nano    40 TOPS  (pending setup)"
echo "  Apple M1 NE         15.8 TOPS (Alexandria)"
echo "  ─────────────────────────────────────────"
echo -e "  ${BOLD}Total: ~135 TOPS${RESET}"
echo ""

# Tailscale nodes
if command -v tailscale &>/dev/null; then
  echo -e "${CYAN}  Tailscale Mesh:${RESET}"
  tailscale status 2>/dev/null | head -10 || echo "  (tailscale not running)"
  echo ""
fi
