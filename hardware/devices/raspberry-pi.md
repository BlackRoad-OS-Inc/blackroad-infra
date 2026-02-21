# Raspberry Pi Fleet

**8 nodes** forming the always-on production backbone of BlackRoad infrastructure.

---

## Fleet Overview

| Node | Board | RAM | Storage | Case | Accelerator | IP (Local) | IP (Tailscale) | Status |
|------|-------|-----|---------|------|-------------|------------|----------------|--------|
| Cecilia | Pi 5 | 8GB | 500GB NVMe | Standard | Hailo-8 26T | 192.168.4.89 | 100.72.180.98 | Active |
| Octavia | Pi 5 | 8GB | 235GB SD | Pironman | Hailo-8 26T | 192.168.4.38 | 100.83.149.86 | Active |
| Lucidia | Pi 5 | 8GB | 117GB SD | ElectroCookie | — | 192.168.4.81 | 100.66.235.47 | Active |
| Aria | Pi 5 | 8GB | 29GB SD | Pironman | Hailo-8 26T | 192.168.4.82 | 100.109.14.17 | Active |
| Anastasia | Pi 5 | 8GB | NVMe | Pironman | — | 192.168.4.33 | — | Active |
| Cordelia | Pi 5 | 8GB | SD | Standard | — | 192.168.4.27 | — | Active |
| Alice | Pi 400 | 4GB | 32GB SD | Built-in | — | 192.168.4.49 | 100.77.210.18 | Active |
| Olympia | Pi 4B | 4GB | SD | PiKVM | — | — | — | Offline |

---

## Per-Node Details

### Cecilia — Primary AI Host

- **Role:** CECE OS orchestrator, primary AI inference
- **Hardware:** Pi 5 8GB + Hailo-8 M.2 (serial: HLLWM2B233704667) + 500GB NVMe
- **Case:** Standard with active fan
- **PSU:** Geekworm 27W 5V/5A USB-C
- **Services:** Ollama, CECE OS (68 sovereign apps), Hailo runtime
- **Storage:** 500GB Crucial P310 NVMe (~50% used)
- **SSH:** `ssh cecilia` / `ssh cecilia-ts`
- **Tunnel:** tunnel-cecilia.blackroad.io
- **Notes:** Houses the 68-app CECE OS sovereign stack. Primary inference node.

### Octavia — AI Inference + Auth

- **Role:** AI inference, PowerDNS, auth gateway
- **Hardware:** Pi 5 8GB + Hailo-8 M.2 (serial: HLLWM2B233704606) + Pironman case
- **Case:** Pironman with dual-fan tower cooler
- **PSU:** Geekworm 27W 5V/5A USB-C
- **Services:** Hailo runtime, PowerDNS, PowerDNS-Admin, RoadAuth, RoadAPI, auth-gateway
- **Storage:** 235GB Samsung EVO Select microSD (~90% used — needs cleanup)
- **SSH:** `ssh octavia` / `ssh octavia-ts`
- **Tunnel:** tunnel-octavia.blackroad.io
- **Known Issues:** Disk nearly full at 90%. Schedule cleanup.

### Lucidia — Event Bus + LLM Brain

- **Role:** NATS event bus, Ollama LLM server, edge agent
- **Hardware:** Pi 5 8GB + ElectroCookie Radial Tower case
- **Case:** ElectroCookie with tower cooler
- **PSU:** Geekworm 27W 5V/5A USB-C
- **Services:** NATS (port 4222), Ollama (port 11434), edge-agent
- **Storage:** 117GB Samsung EVO Select microSD (~60% used)
- **SSH:** `ssh lucidia` / `ssh lucidia-ts`
- **Tunnel:** tunnel-lucidia.blackroad.io
- **Notes:** Central event bus. All MQTT/NATS traffic routes through here.

### Aria — API Services

- **Role:** Web services, API hosting, compute
- **Hardware:** Pi 5 8GB + Pironman case + Hailo-8 M.2
- **Case:** Pironman with dual-fan tower cooler
- **PSU:** Geekworm 27W 5V/5A USB-C
- **Services:** Compute workloads, 9 containers
- **Storage:** 29GB Samsung EVO Select microSD (~70% used)
- **SSH:** `ssh aria` / `ssh aria-ts`
- **Notes:** Rock-solid uptime (4+ weeks continuous). Low storage — consider NVMe upgrade.

### Anastasia — AI Inference Secondary

- **Role:** Secondary AI inference node
- **Hardware:** Pi 5 8GB + Pironman case + NVMe
- **Case:** Pironman with dual-fan tower cooler
- **PSU:** Geekworm 27W 5V/5A USB-C
- **Services:** (Pending deployment)
- **Storage:** NVMe via Pironman (Crucial P310)
- **SSH:** `ssh anastasia` (192.168.4.33)

### Cordelia — Orchestration

- **Role:** Fleet orchestration
- **Hardware:** Pi 5 8GB
- **Case:** Standard with active cooler
- **PSU:** Geekworm 27W 5V/5A USB-C
- **Services:** (Pending deployment)
- **SSH:** `ssh cordelia` (192.168.4.27)

### Alice — Gateway / Admin

- **Role:** Gateway, auth, development, built-in admin console
- **Hardware:** Pi 400 (keyboard built-in) 4GB
- **Case:** Built-in keyboard enclosure
- **PSU:** 5V/3A USB-C (15W)
- **Services:** Worker node, 7 containers
- **Storage:** 32GB microSD (~93% used — needs cleanup)
- **SSH:** `ssh alice` / `ssh alice-ts`
- **Known Issues:** Disk critically full at 93%. Immediate cleanup needed.

### Olympia — KVM Console

- **Role:** Remote KVM access to other nodes
- **Hardware:** Pi 4B 4GB + PiKVM case
- **Case:** PiKVM enclosure
- **PSU:** 5V/3A USB-C (15W)
- **Services:** PiKVM OS
- **Status:** **Offline** — needs recommissioning
- **Notes:** Used for headless recovery of other Pis.

---

## Maintenance Notes

### Disk Cleanup Priority

1. **Alice** (93% full) — Critical
2. **Octavia** (90% full) — High
3. **Aria** (70% full) — Monitor

### SSH Config

All nodes use key-only authentication. SSH config on Alexandria (Mac):

```
Host cecilia
  HostName 192.168.4.89
  User alexandria

Host cecilia-ts
  HostName 100.72.180.98
  User alexandria
```

### Management Scripts

```bash
~/pifleet.sh              # Fleet overview
~/hardware.sh             # Interactive hardware menu
~/blackroad-network-scan.sh  # Scan all Pi IPs
```
