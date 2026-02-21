#!/usr/bin/env bash
# BlackRoad OS - Brady Bunch Bootstrap Deployer
# Deploys native grid display to all Pi devices

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
RESET='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRADY_SCRIPT="$SCRIPT_DIR/blackroad-brady-bunch-native.py"
SYSTEMD_SERVICE="blackroad-brady-bunch"

# Pi Fleet - parallel arrays for bash 3 compatibility
HOSTS=(cecilia lucidia octavia alice aria)
IPS=("192.168.4.89" "192.168.4.81" "192.168.4.38" "192.168.4.49" "192.168.4.82")

get_ip() {
  local host=$1
  for i in "${!HOSTS[@]}"; do
    if [[ "${HOSTS[$i]}" == "$host" ]]; then
      echo "${IPS[$i]}"
      return
    fi
  done
}

banner() {
  echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${PINK}║${RESET}  ${BOLD}BlackRoad OS - Brady Bunch Bootstrap Deployer${RESET}           ${PINK}║${RESET}"
  echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
}

log() { echo -e "${GREEN}[$(date +%H:%M:%S)]${RESET} $*"; }
warn() { echo -e "${AMBER}[WARN]${RESET} $*"; }
error() { echo -e "${RED}[ERROR]${RESET} $*"; }

check_host() {
  local host=$1
  if ssh -o ConnectTimeout=2 -o BatchMode=yes $host "true" 2>/dev/null; then
    echo "online"
  else
    echo "offline"
  fi
}

deploy_to_host() {
  local host=$1
  local ip=$(get_ip "$host")

  log "${BLUE}Deploying to $host ($ip)...${RESET}"

  # Check connectivity
  if [[ "$(check_host $host)" != "online" ]]; then
    error "$host is offline, skipping"
    return 1
  fi

  # Install dependencies
  log "Installing pygame on $host..."
  ssh $host "pip3 install pygame --break-system-packages 2>/dev/null || pip3 install pygame 2>/dev/null || true" &>/dev/null

  # Create directory
  ssh $host "mkdir -p ~/blackroad-display"

  # Copy display script
  log "Copying display script..."
  scp -q "$BRADY_SCRIPT" $host:~/blackroad-display/brady-bunch.py

  # Create launcher script
  log "Creating launcher..."
  ssh $host "cat > ~/blackroad-display/start.sh << 'LAUNCHER'
#!/bin/bash
# BlackRoad Brady Bunch Display Launcher

export SDL_VIDEODRIVER=fbcon
export SDL_FBDEV=/dev/fb0
export DISPLAY=:0

cd ~/blackroad-display

# Try framebuffer first, then X11
if [ -e /dev/fb0 ]; then
  python3 brady-bunch.py --fullscreen
elif [ -n \"\$DISPLAY\" ]; then
  export SDL_VIDEODRIVER=x11
  python3 brady-bunch.py
else
  echo 'No display available'
  exit 1
fi
LAUNCHER
chmod +x ~/blackroad-display/start.sh"

  # Create user-level autostart (no sudo required)
  log "Creating autostart config..."
  ssh $host "mkdir -p ~/.config/autostart && cat > ~/.config/autostart/brady-bunch.desktop << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=BlackRoad Brady Bunch
Exec=/home/\$USER/blackroad-display/start.sh
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
AUTOSTART"

  # Also create rc.local style autostart for headless
  ssh $host "cat >> ~/.bashrc << 'RCLOCAL'

# BlackRoad Brady Bunch autostart (framebuffer mode)
if [ -e /dev/fb0 ] && [ -z \"\$DISPLAY\" ] && [ \"\$(tty)\" = \"/dev/tty1\" ]; then
  ~/blackroad-display/start.sh &
fi
RCLOCAL" 2>/dev/null || true

  log "${GREEN}Deployed to $host!${RESET}"
  return 0
}

enable_autostart() {
  local host=$1

  if [[ "$(check_host $host)" != "online" ]]; then
    warn "$host offline, can't enable autostart"
    return 1
  fi

  log "Enabling autostart on $host..."
  ssh $host "sudo systemctl daemon-reload && sudo systemctl enable ${SYSTEMD_SERVICE} 2>/dev/null" || true
  echo -e "${GREEN}Autostart enabled on $host${RESET}"
}

start_display() {
  local host=$1

  if [[ "$(check_host $host)" != "online" ]]; then
    warn "$host offline"
    return 1
  fi

  log "Starting display on $host..."
  ssh $host "sudo systemctl start ${SYSTEMD_SERVICE} 2>/dev/null || ~/blackroad-display/start.sh &" || true
}

stop_display() {
  local host=$1

  if [[ "$(check_host $host)" != "online" ]]; then
    return 1
  fi

  log "Stopping display on $host..."
  ssh $host "sudo systemctl stop ${SYSTEMD_SERVICE} 2>/dev/null; pkill -f brady-bunch 2>/dev/null" || true
}

status_all() {
  echo -e "\n${BOLD}Device Status:${RESET}"
  echo "────────────────────────────────────────"

  for i in "${!HOSTS[@]}"; do
    host="${HOSTS[$i]}"
    ip="${IPS[$i]}"
    state=$(check_host $host)

    if [[ "$state" == "online" ]]; then
      # Check if display is running
      running=$(ssh $host "pgrep -f brady-bunch >/dev/null && echo 'running' || echo 'stopped'" 2>/dev/null)
      fb=$(ssh $host "[ -e /dev/fb0 ] && echo 'yes' || echo 'no'" 2>/dev/null)

      echo -e "${GREEN}●${RESET} ${BOLD}$host${RESET} ($ip)"
      echo -e "  Display: ${running:-unknown}, Framebuffer: ${fb:-unknown}"
    else
      echo -e "${RED}●${RESET} ${BOLD}$host${RESET} ($ip) - OFFLINE"
    fi
  done
  echo ""
}

deploy_all() {
  banner
  log "Deploying Brady Bunch display to all devices..."
  echo ""

  local success=0
  local failed=0

  for host in "${HOSTS[@]}"; do
    if deploy_to_host "$host"; then
      ((success++))
    else
      ((failed++))
    fi
    echo ""
  done

  echo -e "${BOLD}Deployment complete: ${GREEN}$success success${RESET}, ${RED}$failed failed${RESET}"
}

start_all() {
  log "Starting Brady Bunch displays on all devices..."
  for host in "${HOSTS[@]}"; do
    start_display "$host"
  done
}

stop_all() {
  log "Stopping Brady Bunch displays on all devices..."
  for host in "${HOSTS[@]}"; do
    stop_display "$host"
  done
}

enable_all() {
  log "Enabling autostart on all devices..."
  for host in "${HOSTS[@]}"; do
    enable_autostart "$host"
  done
}

# Check TP-Link devices
check_tplink() {
  echo -e "\n${BOLD}TP-Link Network Scan:${RESET}"
  echo "────────────────────────────────────────"

  # Common TP-Link MAC prefixes
  arp -a | grep -iE "(tp-link|60:92:c8|30:be:29|44:ac:85|b0:4e:26|14:eb:b6)" | while read line; do
    ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    mac=$(echo "$line" | grep -oE '([0-9a-f]{1,2}:){5}[0-9a-f]{1,2}')
    echo -e "${AMBER}●${RESET} $ip - $mac"
  done

  echo ""
  echo "Known TP-Link devices on network:"
  echo "  192.168.4.1  - Router/Gateway"
  echo "  192.168.4.22 - TP-Link Switch/AP"
  echo "  192.168.4.33 - TP-Link Device"
}

usage() {
  echo "Usage: $0 <command> [host]"
  echo ""
  echo "Commands:"
  echo "  deploy [host]    Deploy to host or all"
  echo "  start [host]     Start display on host or all"
  echo "  stop [host]      Stop display on host or all"
  echo "  status           Show status of all devices"
  echo "  enable [host]    Enable autostart on boot"
  echo "  tplink           Scan for TP-Link devices"
  echo "  test             Run local test"
  echo ""
  echo "Hosts: ${HOSTS[*]}"
}

# Main
case "${1:-}" in
  deploy)
    if [[ -n "${2:-}" ]]; then
      deploy_to_host "$2"
    else
      deploy_all
    fi
    ;;
  start)
    if [[ -n "${2:-}" ]]; then
      start_display "$2"
    else
      start_all
    fi
    ;;
  stop)
    if [[ -n "${2:-}" ]]; then
      stop_display "$2"
    else
      stop_all
    fi
    ;;
  status)
    banner
    status_all
    ;;
  enable)
    if [[ -n "${2:-}" ]]; then
      enable_autostart "$2"
    else
      enable_all
    fi
    ;;
  tplink)
    banner
    check_tplink
    ;;
  test)
    log "Running local test..."
    python3 "$BRADY_SCRIPT"
    ;;
  *)
    banner
    usage
    echo ""
    status_all
    ;;
esac
