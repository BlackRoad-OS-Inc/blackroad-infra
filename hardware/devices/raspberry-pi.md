# Raspberry Pi Fleet — Live Verified

**8 nodes** forming the always-on production backbone of BlackRoad infrastructure.

**Verified via SSH probes on 2026-02-21.**

---

## Fleet Overview

| Node | Board | RAM | Storage | Case | Accelerator | IP (Local) | IP (Tailscale) | Status |
|------|-------|-----|---------|------|-------------|------------|----------------|--------|
| Cecilia | Pi 5 | 8GB | 500GB NVMe (49% used) | Standard | **Hailo-8 26T** | 192.168.4.89 | 100.72.180.98 | **Active** |
| Octavia | Pi 5 | 8GB | 29GB SD (60% used) | Pironman | None confirmed | 192.168.4.38 | 100.66.235.47 | **Active (OVERLOADED)** |
| Lucidia | Pi 5 | 8GB | Unknown | ElectroCookie | Unknown | 192.168.4.81 | 100.83.149.86 | **DOWN** |
| Aria | Pi 5 | 8GB | 29GB SD (74% used) | Pironman | None confirmed | 192.168.4.82 | 100.109.14.17 | **Active** |
| Anastasia | Pi 5 | 8GB | Unknown | Pironman | Unknown | 192.168.4.33 | — | **SSH Closed** |
| Cordelia | Pi 5 | 8GB | Unknown | Standard | Unknown | 192.168.4.27 | — | **SSH Closed** |
| Alice | Pi 400 | 4GB | 29GB SD (93% used) | Built-in | — | 192.168.4.49 | 100.77.210.18 | **Active** |
| Olympia | Pi 4B | 4GB | Unknown | PiKVM | — | — | — | **Offline** |

### ERRATA vs Prior Documentation

| Item | Previously Documented | Live Verified |
|------|----------------------|---------------|
| Octavia Tailscale IP | 100.83.149.86 | **100.66.235.47** |
| Lucidia Tailscale IP | 100.66.235.47 | **100.83.149.86** |
| Hailo-8 on Octavia | Active (26 TOPS) | **Not detected** (no `/dev/hailo*`, no `hailort.service`) |
| Hailo-8 on Aria | Active (26 TOPS) | **Not detected** (no `/dev/hailo*`, no `hailort.service`) |
| SSH user | `alexandria` | **`blackroad`** |
| Lucidia status | Active | **DOWN** (unreachable) |
| Octavia storage | 235GB Samsung EVO | **29GB** (60% used) |
| Cecilia OS | Bookworm | **Debian 13 Trixie** |
| Alice OS | Bookworm | **Raspbian 11 Bullseye** |

---

## Per-Node Details

### Cecilia — Primary AI Host

- **Role:** CECE OS orchestrator, primary AI inference, observability hub
- **Hardware:** Pi 5 8GB + Hailo-8 M.2 (serial: HLLWM2B233704667) + 500GB NVMe
- **OS:** Debian 13 (Trixie), Kernel 6.6.62+rpt-rpi-2712
- **Case:** Standard with active fan
- **PSU:** Geekworm 27W 5V/5A USB-C
- **MAC:** 88:a2:9e:3b:eb:72
- **Storage:** 500GB Crucial P310 NVMe (49% used, 230GB free)
- **SSH:** `ssh cecilia` / `ssh cecilia-ts` (user: `blackroad`)
- **Tunnel:** tunnel-cecilia.blackroad.io (cloudflared running)
- **Systemd:** hailort, ollama, cloudflared, docker

**Verified Services (16+ listening ports):**

| Port | Service | Bind |
|------|---------|------|
| 22 | SSH | 0.0.0.0 |
| 53 | DNS resolver | 0.0.0.0 |
| 80 | HTTP (nginx/caddy) | 0.0.0.0 |
| 631 | CUPS (printing) | 127.0.0.1 |
| 3001 | Dashboard (python3) | 0.0.0.0 |
| 3100 | Loki log aggregator | 0.0.0.0 |
| 5001-5002 | Python services | 0.0.0.0 |
| 5432 | **PostgreSQL** | 127.0.0.1 |
| 5900 | **VNC** | 0.0.0.0 |
| 8086 | **InfluxDB** | 0.0.0.0 |
| 8787 | Python service | 0.0.0.0 |
| 9000-9001 | **MinIO** (S3 + Console) | 0.0.0.0 |
| 9100 | Node Exporter (Prometheus) | 0.0.0.0 |
| 11434 | **Ollama** | 127.0.0.1 |
| 34001 | Tailscale relay | 0.0.0.0 |

**Infrastructure Stack:** PostgreSQL + InfluxDB + MinIO + Loki + Node Exporter = full observability

---

### Octavia — Multi-Service Hub (OVERLOADED)

- **Role:** Multi-arm processing, microservice host
- **Hardware:** Pi 5 8GB + Pironman case (NO Hailo-8 detected)
- **OS:** Debian 12 (Bookworm), Kernel 6.6.51+rpt-rpi-2712
- **Case:** Pironman with dual-fan tower cooler
- **PSU:** Geekworm 27W 5V/5A USB-C
- **MAC:** 2c:cf:67:cf:fa:17
- **Storage:** 29GB SD (60% used, 10.3GB free)
- **Load Average:** **9.47** (dangerously high for 4-core Pi)
- **RAM:** 6.6GB / 7.9GB (83% used)
- **SSH:** `ssh octavia` / `ssh octavia-ts` (user: `blackroad`)
- **Tunnel:** tunnel-octavia.blackroad.io (cloudflared running)
- **Systemd:** ollama, ollama-bridge, cloudflared, docker

> **WARNING:** 30+ listening ports, load average 9.47, RAM 83%. This node needs service migration or hardware upgrade.

**Verified Services (30+ listening ports):**

| Port Range | Service |
|------------|---------|
| 3002-3006 | App services (5 containers) |
| 3109, 4001-4002, 4010 | App services |
| 5200-6300 | 10 Python microservices |
| 8000 | API (uvicorn/gunicorn) |
| 8011, 8080-8082, 8180 | HTTP services |
| 5432 | PostgreSQL (localhost) |
| 11434 | Ollama (localhost) |
| 34001 | Tailscale relay |

---

### Lucidia — Event Bus (DOWN)

- **Role:** NATS event bus, Ollama LLM server, edge agent
- **Hardware:** Pi 5 8GB + ElectroCookie Radial Tower case
- **PSU:** Geekworm 27W 5V/5A USB-C
- **MAC:** incomplete (ARP expired)
- **IP:** 192.168.4.81 (local), 100.83.149.86 (Tailscale)
- **Status:** **DOWN — unreachable since at least 2026-02-21**
- **Tunnel:** tunnel-lucidia.blackroad.io (**DOWN** — node unreachable)

> **ACTION REQUIRED:** Physical investigation needed. This node hosts the NATS event bus.
> Power cycle or check ethernet/SD card.

---

### Aria — Container Host

- **Role:** Container workloads, web services
- **Hardware:** Pi 5 8GB + Pironman case (NO Hailo-8 detected)
- **OS:** Debian 12 (Bookworm), Kernel 6.6.51+rpt-rpi-2712
- **Case:** Pironman with dual-fan tower cooler
- **PSU:** Geekworm 27W 5V/5A USB-C
- **MAC:** 88:a2:9e:0d:42:07
- **Storage:** 29GB SD (74% used — monitor closely)
- **SSH:** `ssh aria` / `ssh aria-ts` (user: `blackroad`)
- **Systemd:** ollama, cloudflared, docker

**Verified Services (30+ listening ports):**

| Port Range | Service |
|------------|---------|
| 3140-3167 | **28 Docker container ports** |
| 8081 | HTTP service |
| 8180 | Python service |

> **NOTE:** 28 container ports in the 3140-3167 range. Disk at 74% — monitor closely.

---

### Anastasia — Pi (SSH Closed)

- **Role:** Secondary AI inference node (pending deployment)
- **Hardware:** Pi 5 8GB + Pironman case + NVMe
- **Case:** Pironman with dual-fan tower cooler
- **PSU:** Geekworm 27W 5V/5A USB-C
- **MAC:** 60:92:c8:11:cf:7c
- **IP:** 192.168.4.33 (no Tailscale)
- **Ping:** UP
- **SSH:** **Connection refused** — port 22 not open

> **NOTE:** SSH alias `anastasia` in `~/.ssh/config` points to the DigitalOcean droplet (174.138.44.45),
> NOT this Pi. Add an `anastasia-pi` alias for 192.168.4.33 once SSH is enabled.

---

### Cordelia — Orchestration (SSH Closed)

- **Role:** Fleet orchestration (pending deployment)
- **Hardware:** Pi 5 8GB
- **Case:** Standard with active cooler
- **PSU:** Geekworm 27W 5V/5A USB-C
- **MAC:** 6c:4a:85:32:ae:72
- **IP:** 192.168.4.27 (no Tailscale)
- **Ping:** UP
- **SSH:** **Connection refused** — port 22 not open

> **NOTE:** No SSH config entry exists for `cordelia`. Cannot configure remotely until SSH is enabled.

---

### Alice — Gateway / Admin

- **Role:** Gateway, auth, development
- **Hardware:** Pi 400 (keyboard built-in) 4GB
- **OS:** Raspbian 11 (Bullseye), Kernel 6.1.21-v8+
- **Case:** Built-in keyboard enclosure
- **PSU:** 5V/3A USB-C (15W)
- **MAC:** d8:3a:dd:ff:98:87
- **Storage:** 29GB SD (93% used — **CRITICAL**)
- **SSH:** `ssh alice` / `ssh alice-ts` (user: `blackroad`)
- **Systemd:** cloudflared, docker

**Verified Services:**

| Port | Service |
|------|---------|
| 22 | SSH |

> **WARNING:** Disk at 93% full. Immediate cleanup needed. Minimal services running but load avg 6.17
> is concerning for a 4-core Pi 400 — investigate Docker workloads.

---

### Olympia — KVM Console (Offline)

- **Role:** Remote KVM access to other nodes
- **Hardware:** Pi 4B 4GB + PiKVM case
- **Case:** PiKVM enclosure
- **PSU:** 5V/3A USB-C (15W)
- **Status:** **Offline** — not on network, needs recommissioning
- **Notes:** Used for headless recovery of other Pis. Not verified.

---

## Maintenance Priority

### Immediate Actions

1. **Lucidia** — Physical investigation. Node DOWN. Power cycle and check connectivity.
2. **Alice** — Disk at 93%. Run `sudo apt autoremove && docker system prune -a`.
3. **Octavia** — Overloaded (load 9.47, RAM 83%). Migrate services to Aria or Cecilia.
4. **Anastasia / Cordelia** — Enable SSH (requires keyboard + monitor).

### Hailo-8 Investigation

3 Hailo-8 M.2 modules were purchased but only 1 is detected (Cecilia). Possible explanations:
- Modules not physically installed in Octavia/Aria M.2 slots
- HailoRT not installed on those nodes
- Modules installed but not recognized (driver issue)

Requires physical inspection of M.2 slots on Octavia and Aria.

### Stale Data Cleanup

| Item | Issue | Fix |
|------|-------|-----|
| `/etc/hosts` on Mac | `192.168.4.74 octavia` (wrong IP) | Change to `192.168.4.38 octavia` |
| `~/hailo.sh` | Connects to `pi@192.168.4.74` | Change to `blackroad@192.168.4.38` |
| SSH `anastasia` alias | Points to DO droplet, not Pi | Add `anastasia-pi` for 192.168.4.33 |
| Agent registry | Octavia/Aria listed as `pironman_hailo8` | Change to `pironman` (no Hailo confirmed) |

### SSH Quick Reference

```bash
# All SSH uses user 'blackroad', not 'alexandria'
ssh cecilia           # 192.168.4.89
ssh octavia           # 192.168.4.38
ssh aria              # 192.168.4.82
ssh alice             # 192.168.4.49
ssh lucidia           # 192.168.4.81 (DOWN)

# Tailscale (remote access)
ssh cecilia-ts        # 100.72.180.98
ssh octavia-ts        # 100.66.235.47
ssh aria-ts           # 100.109.14.17
ssh alice-ts          # 100.77.210.18
ssh lucidia-ts        # 100.83.149.86 (DOWN)
```

### Management Scripts

```bash
~/pifleet.sh                    # Fleet overview
~/hardware.sh                   # Interactive hardware menu
~/blackroad-network-scan.sh     # Scan all Pi IPs
~/blackroad-network-discovery.sh  # SSH probe all nodes
```
