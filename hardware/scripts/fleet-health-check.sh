#!/bin/bash
# BlackRoad Fleet Health Check
# Pings all devices and checks key service ports
# Usage: ./fleet-health-check.sh [--verbose]

set -e

PINK='\033[38;5;205m'
GREEN='\033[38;5;82m'
AMBER='\033[38;5;214m'
RED='\033[38;5;196m'
CYAN='\033[38;5;81m'
RESET='\033[0m'
BOLD='\033[1m'

VERBOSE=false
[ "$1" = "--verbose" ] && VERBOSE=true

echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  BLACKROAD FLEET HEALTH CHECK${RESET}"
echo -e "  $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Define fleet with name:ip:ports
declare -A FLEET_IPS=(
  ["cecilia"]="192.168.4.89"
  ["octavia"]="192.168.4.38"
  ["lucidia"]="192.168.4.81"
  ["aria"]="192.168.4.82"
  ["anastasia"]="192.168.4.33"
  ["cordelia"]="192.168.4.27"
  ["alice"]="192.168.4.49"
  ["athena"]="192.168.4.45"
  ["codex-infinity"]="159.65.43.12"
  ["shellfish"]="174.138.44.45"
)

# Service ports to check per node
declare -A NODE_SERVICES=(
  ["cecilia"]="22:SSH 11434:Ollama"
  ["lucidia"]="22:SSH 4222:NATS 11434:Ollama"
  ["octavia"]="22:SSH 53:DNS 8080:PowerDNS-Admin"
  ["aria"]="22:SSH"
  ["anastasia"]="22:SSH"
  ["cordelia"]="22:SSH"
  ["alice"]="22:SSH"
  ["athena"]=""
  ["codex-infinity"]="22:SSH"
  ["shellfish"]="22:SSH"
)

TOTAL=0
UP=0
DOWN=0

check_port() {
  local ip=$1 port=$2
  nc -z -w 2 "$ip" "$port" &>/dev/null
  return $?
}

echo -e "${CYAN}  Node Health:${RESET}"
echo ""
printf "  ${BOLD}%-16s %-18s %-10s %-30s${RESET}\n" "NODE" "IP" "PING" "SERVICES"
echo "  ────────────────────────────────────────────────────────────────────────"

for node in cecilia octavia lucidia aria anastasia cordelia alice athena codex-infinity shellfish; do
  ip="${FLEET_IPS[$node]}"
  TOTAL=$((TOTAL + 1))

  # Ping check
  if ping -c 1 -W 2 "$ip" &>/dev/null; then
    ping_status="${GREEN}UP${RESET}"
    UP=$((UP + 1))
  else
    ping_status="${RED}DOWN${RESET}"
    DOWN=$((DOWN + 1))
  fi

  # Service checks
  services="${NODE_SERVICES[$node]}"
  service_results=""
  if [ -n "$services" ]; then
    for svc in $services; do
      port="${svc%%:*}"
      name="${svc##*:}"
      if check_port "$ip" "$port"; then
        service_results+="${GREEN}${name}${RESET} "
      else
        service_results+="${RED}${name}!${RESET} "
      fi
    done
  else
    service_results="—"
  fi

  printf "  %-16s %-18s " "$node" "$ip"
  echo -ne "$ping_status"
  printf "%*s" $((10 - 2)) ""
  echo -e "$service_results"
done

echo ""
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${BOLD}Results:${RESET} $TOTAL checked  |  ${GREEN}Up: $UP${RESET}  |  ${RED}Down: $DOWN${RESET}"

# Overall health
if [ "$DOWN" -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}Fleet Status: ALL HEALTHY${RESET}"
elif [ "$DOWN" -le 2 ]; then
  echo -e "  ${AMBER}${BOLD}Fleet Status: DEGRADED ($DOWN node(s) down)${RESET}"
else
  echo -e "  ${RED}${BOLD}Fleet Status: CRITICAL ($DOWN node(s) down)${RESET}"
fi

echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Tailscale mesh check
if command -v tailscale &>/dev/null; then
  echo ""
  echo -e "${CYAN}  Tailscale Mesh Status:${RESET}"
  TS_NODES=$(tailscale status 2>/dev/null | grep -c "online" || echo 0)
  echo "  Connected nodes: $TS_NODES"
  if $VERBOSE; then
    tailscale status 2>/dev/null || echo "  (tailscale not available)"
  fi
fi

echo ""
