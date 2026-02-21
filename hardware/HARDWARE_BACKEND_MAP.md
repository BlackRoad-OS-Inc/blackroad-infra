# BlackRoad Hardware Backend Map

**Canonical source of truth for all BlackRoad physical infrastructure.**
**Verified against live network probes — not documentation, not registries.**

| Field | Value |
|-------|-------|
| Owner | BlackRoad OS, Inc. |
| Updated | 2026-02-21 |
| Fleet Version | 2.1.0 |
| Verified | Live SSH + ARP + ping sweep |
| Total Devices | 21 registered + 4 unidentified |
| Confirmed AI Compute | 52 TOPS (2x Hailo-8 verified: Cecilia + Lucidia) |
| Network | 192.168.4.0/24 LAN + 7-node Tailscale mesh |

---

## 0. ERRATA — Corrections From Live Verification

> **This section documents discrepancies found between prior documentation
> and actual live system state as of 2026-02-21.**

| Issue | Prior Documentation | Live Reality |
|-------|-------------------|--------------|
| Hailo-8 count | 3 units (Cecilia, Octavia, Aria) | **1 confirmed** (Cecilia only). Octavia/Aria report `HAILO: none` |
| Lucidia Tailscale IP | 100.66.235.47 | **100.83.149.86** (SSH config + live binding) |
| Octavia Tailscale IP | 100.83.149.86 | **100.66.235.47** (SSH config + live binding) |
| Lucidia status | Active → DOWN → **BACK UP** | Was down during initial scan, came back online. Has 1TB NVMe + Hailo-8 + NATS |
| Lucidia hostname | "lucidia" | **/etc/hostname says "octavia"** — identity mismatch, needs fixing |
| Hailo-8 count | 1 confirmed (Cecilia only) | **2 confirmed**: Cecilia + Lucidia (hailort.service running on both) |
| Cecilia OS | Debian 12 Bookworm | **Debian 13 Trixie**, kernel 6.12.62 |
| Alice OS | Debian 12 Bookworm | **Raspbian 11 Bullseye**, kernel 6.1.21 |
| Alice storage | 32GB SD | **15GB root partition** (71% used) |
| Octavia storage used | ~90% | **34%** (76G/235G) — was cleaned up |
| SSH user | `alexandria` | **`blackroad`** for fleet nodes |
| Shellfish hostname | shellfish | **`anastasia`** (hostname on the droplet) |
| Codex-Infinity hostname | codex-infinity | **`gematria`** (hostname on the droplet) |
| Octavia old IP | 192.168.4.74 (in /etc/hosts) | **192.168.4.38** (current, .74 is stale) |
| Unknown devices | None documented | **4 found** at .22, .44, .83, .92 |
| Anastasia/Cordelia SSH | Assumed accessible | **SSH port closed** (ping responds, port 22 refused) |

---

## 1. Fleet Summary — Live Verified

| # | Name | Type | Hardware | IP (Local) | IP (Tailscale) | Accelerator | Status | Verified |
|---|------|------|----------|------------|----------------|-------------|--------|----------|
| 1 | Cecilia | Pi 5 | 8GB, Hailo-8, 457GB NVMe | 192.168.4.89 | 100.72.180.98 | **Hailo-8 26 TOPS** (confirmed /dev/hailo0) | **UP** | SSH |
| 2 | Octavia | Pi 5 | 8GB, Pironman, 235GB SD | 192.168.4.38 | 100.66.235.47 | **None** (HAILO: none) | **UP** | SSH |
| 3 | Lucidia | Pi 5 | 8GB, Pironman, **1TB NVMe**, 119G SD | 192.168.4.81 | 100.83.149.86 | **Hailo-8** (hailort running) | **UP** | SSH |
| 4 | Aria | Pi 5 | 8GB, 29GB SD | 192.168.4.82 | 100.109.14.17 | **None** (HAILO: none) | **UP** | SSH |
| 5 | Anastasia | Pi 5 | 8GB | 192.168.4.33 | — | — | **SSH closed** | ARP + ping |
| 6 | Cordelia | Pi 5 | 8GB | 192.168.4.27 | — | — | **SSH closed** | ARP + ping |
| 7 | Alice | Pi 400 | 4GB, 15GB root | 192.168.4.49 | 100.77.210.18 | — | **UP** | SSH |
| 8 | Olympia | Pi 4B | PiKVM | — | — | — | **Offline** | Not probed |
| 9 | Codex-Infinity | DO Droplet | AMD vCPU, 765MB RAM | 159.65.43.12 | 100.108.132.8 | — | **UP** | SSH (hostname: gematria) |
| 10 | Shellfish | DO Droplet | AMD vCPU, 765MB RAM | 174.138.44.45 | 100.94.33.37 | — | **UP** | SSH (hostname: anastasia) |
| 11 | Jetson-Agent | Jetson Orin Nano | 8GB + GPU | — | — | 40 TOPS GPU | **Pending** | Not deployed |
| 12 | Alexandria | MacBook Pro M1 | 8GB | 192.168.4.28 | — | M1 NE 15.8 TOPS | **UP** | Self |
| 13 | Athena | Heltec LoRa ESP32 | ESP32 + SX1276 | 192.168.4.45 | — | — | **UP** | ARP |
| 14 | Persephone | Sipeed RISC-V | — | — | — | — | Unknown | Registry only |
| 15 | Iris | Roku | — | 192.168.4.26 | — | — | **UP** | ARP |
| 16 | Ares | Xbox | — | 192.168.4.90 | — | — | **DOWN** | Ping fail |
| 17 | Phoebe | iPhone | — | 192.168.4.88 | — | — | **DOWN** | Ping fail |
| 18 | .22 unknown | **UNIDENTIFIED** | — | 192.168.4.22 | — | — | **UP** | ARP (30:be:29) |
| 19 | .44 unknown | **TP-Link device** | — | 192.168.4.44 | — | — | **UP** | ARP (98:17:3c) |
| 20 | .83 unknown | **UNIDENTIFIED** | — | 192.168.4.83 | — | — | **UP** | ARP (54:4c:8a) |
| 21 | .92 unknown | **Apple device** (private MAC) | — | 192.168.4.92 | — | — | **DOWN** | Stale ARP |

---

## 2. Production Cluster — Raspberry Pis (Live Data)

### Cecilia — Primary AI Host (VERIFIED)

| Field | Value |
|-------|-------|
| Board | Raspberry Pi 5 Model B Rev 1.1 |
| OS | **Debian 13 (Trixie)** |
| Kernel | 6.12.62+rpt-rpi-2712 |
| RAM | 7.9GB total, 3.3GB used, 4.6GB available |
| Storage | /dev/nvme0n1p2 **457GB**, 65GB used (**15%**) |
| IP Local | 192.168.4.89 |
| IP Tailscale | 100.72.180.98 |
| MAC | 88:a2:9e:3b:eb:72 |
| Hailo-8 | **/dev/hailo0 DETECTED**, serial HLLWM2B233704667 |
| Uptime | 2h 3m (recently rebooted) |
| Load | 3.40, 3.15, 3.48 |
| SSH | `ssh cecilia` (user: blackroad) |

**Services (systemd):**
- `hailort.service` — HailoRT AI runtime
- `ollama.service` — LLM inference (port 11434, localhost only)
- `cloudflared.service` — Cloudflare tunnel
- `docker.service` — Container runtime

**Listening Ports:**

| Port | Service | Bind |
|------|---------|------|
| 22 | SSH | 0.0.0.0 |
| 53 | DNS | 0.0.0.0 |
| 80 | HTTP | 0.0.0.0 |
| 3001 | Python app | 0.0.0.0 |
| 3100 | Loki/log collector | 0.0.0.0 |
| 5001 | Python app | 0.0.0.0 |
| 5002 | Python app | 0.0.0.0 |
| 5432 | PostgreSQL | 127.0.0.1 |
| 5900 | VNC | 0.0.0.0 |
| 8086 | InfluxDB | 0.0.0.0 |
| 8787 | Python app | 0.0.0.0 |
| 9000 | MinIO | 0.0.0.0 + [::] |
| 9001 | MinIO Console | 0.0.0.0 |
| 9100 | Node Exporter | 0.0.0.0 |
| 11434 | Ollama | 127.0.0.1 |
| 34001 | Tailscale relay | 0.0.0.0 |

---

### Octavia — Heavy Services (VERIFIED)

| Field | Value |
|-------|-------|
| Board | Raspberry Pi 5 Model B Rev 1.1 |
| OS | Debian 12 (Bookworm) |
| Kernel | 6.12.62+rpt-rpi-2712 |
| RAM | 7.9GB total, **6.6GB used**, 1.3GB available |
| Storage | /dev/mmcblk0p2 **235GB**, 76GB used (**34%**) |
| IP Local | 192.168.4.38 |
| IP Tailscale | **100.66.235.47** |
| MAC | 2c:cf:67:cf:fa:17 |
| Hailo-8 | **NONE** |
| Uptime | 12 min (rebooted, xmrig+finetune processes cleared) |
| Load | 0.86, 0.78, 0.72 (healthy after reboot) |
| SSH | `ssh octavia` (user: blackroad) |

**Services (systemd):**
- `ollama.service` — LLM inference
- `ollama-bridge.service` — SSE chat proxy
- `cloudflared.service` — Cloudflare tunnel
- `docker.service` — Container runtime

**Listening Ports (28+ services):**

| Port | Service | Bind |
|------|---------|------|
| 3002-3006 | App services | 0.0.0.0 |
| 3109 | App service | 0.0.0.0 |
| 4001-4002 | App services | 0.0.0.0 |
| 4010 | App service | 127.0.0.1 |
| 5200-5900 | Python microservices (7 ports) | 0.0.0.0 |
| 6000-6300 | Python microservices (4 ports) | 0.0.0.0 |
| 8000 | API (uvicorn/gunicorn) | 0.0.0.0 |
| 8011 | Python service | 0.0.0.0 |
| 8080-8082 | HTTP services | 0.0.0.0 |
| 8180 | Python service | 0.0.0.0 |
| 5432 | PostgreSQL | 127.0.0.1 |
| 11434 | Ollama | 127.0.0.1 |
| 34001 | Tailscale relay | 0.0.0.0 |

> **Cleaned 2026-02-21:** xmrig miner killed, apple-finetune processes cleared after reboot.
> Load dropped from 9.47 to 0.86. Monitor for process respawns.

---

### Aria — API Services (VERIFIED)

| Field | Value |
|-------|-------|
| Board | Raspberry Pi 5 Model B Rev 1.1 |
| OS | Debian 12 (Bookworm) |
| Kernel | 6.12.62+rpt-rpi-2712 |
| RAM | 7.9GB total, 3.8GB used, 4.0GB available |
| Storage | /dev/mmcblk0p2 **29GB**, 20GB used (**74%**) |
| IP Local | 192.168.4.82 |
| IP Tailscale | 100.109.14.17 |
| MAC | 88:a2:9e:0d:42:07 |
| Hailo-8 | **NONE** |
| Uptime | 3h 54m |
| Load | 0.45, 0.60, 0.68 |
| SSH | `ssh aria` (user: blackroad) |

**Services (systemd):**
- `ollama.service` — LLM inference
- `cloudflared.service` — Cloudflare tunnel
- `docker.service` — Container runtime

**Listening Ports (28+ services):**

| Port Range | Count | Service |
|------------|-------|---------|
| 3140-3167 | 28 | Docker container ports |
| 3153-3167 | 15 | (subset, unique services) |
| 8081 | 1 | HTTP service |
| 8180 | 1 | Python service |

> **WARNING:** 74% disk on 29GB. Only 7.3GB free. Needs storage upgrade or cleanup.

---

### Alice — Gateway (VERIFIED)

| Field | Value |
|-------|-------|
| Board | Raspberry Pi 400 Rev 1.0 |
| OS | **Raspbian 11 (Bullseye)** — NOT Bookworm |
| Kernel | **6.1.21-v8+** |
| RAM | 3.7GB total, 579MB used, 3.1GB available |
| Storage | /dev/root **15GB**, 9.6GB used (**71%**) |
| IP Local | 192.168.4.49 |
| IP Tailscale | 100.77.210.18 |
| MAC | d8:3a:dd:ff:98:87 |
| Hailo-8 | None |
| Uptime | 2 days, 6h 24m |
| Load | 6.17, 5.60, 5.56 (HIGH for 4 cores) |
| SSH | `ssh alice` (user: blackroad) |

**Services (systemd):**
- `cloudflared.service` — Cloudflare tunnel
- `docker.service` — Container runtime

> **WARNING:** Load average 6.17 on a Pi 400 (4-core). 71% disk. Consider upgrading OS to Bookworm.

---

### Lucidia — BACK ONLINE (VERIFIED 2026-02-21)

> **HOSTNAME BUG:** `/etc/hostname` on this machine says "octavia", but it IS Lucidia
> by hardware serial (a91e903b3e7bfcc4), IP, and physical presence (1TB NVMe + Hailo-8).

| Field | Value |
|-------|-------|
| Board | Raspberry Pi 5 Model B Rev 1.1 |
| Serial | a91e903b3e7bfcc4 |
| OS | **Debian 13 (Trixie)** |
| Kernel | 6.12.62+rpt-rpi-2712 |
| RAM | 8GB total |
| Storage (root) | /dev/mmcblk0p2 **119G**, 53GB used (**47%**), 60G free |
| Storage (NVMe) | /dev/nvme0n1p1 **916G**, 1.8GB used (**1%**), **868G free** |
| IP Local | 192.168.4.81 |
| IP Tailscale | 100.83.149.86 |
| MAC | 88:a2:9e:10:a3:a (from IPv6 SLAAC) |
| Hailo-8 | **hailort.service RUNNING** |
| Uptime | 16 min (recently rebooted) |
| Load | 0.15, 0.33, 0.33 |
| SSH | `ssh lucidia` (user: blackroad) |

**Services (systemd):**
- `hailort.service` — HailoRT AI runtime (**2nd Hailo-8 in fleet!**)
- `ollama.service` — LLM inference (port 11434, localhost only)
- `cloudflared.service` — Cloudflare tunnel
- `docker.service` — Container runtime
- `influxdb.service` — Time series DB
- `pironman5.service` — Case controller
- `tailscaled.service` — Mesh VPN

**Listening Ports:**

| Port | Service | Bind |
|------|---------|------|
| 22 | SSH | 0.0.0.0 |
| 80 | PowerDNS Admin | 0.0.0.0 |
| 3000 | Python app | 0.0.0.0 |
| 4222 | **NATS** | 0.0.0.0 |
| 5000 | App service | 0.0.0.0 |
| 8080 | HTTP service | 0.0.0.0 |
| 8082 | HTTP service | 0.0.0.0 |
| 8088 | InfluxDB | 127.0.0.1 |
| 8222 | NATS monitoring | 0.0.0.0 |
| 8787 | Python app | 0.0.0.0 |
| 9100 | Node Exporter | 0.0.0.0 |
| 11434 | Ollama | 127.0.0.1 |
| 34001 | Tailscale relay | 0.0.0.0 |

> **This is the NATS event bus node** (ports 4222/8222) — critical for inter-node messaging.
> **Healthiest storage in fleet:** 868G free on NVMe. Use for offloading from Alexandria.
> **No xmrig found** — this node was never compromised.

---

### Anastasia — SSH Closed

| Field | Value |
|-------|-------|
| Board | Raspberry Pi 5 (confirmed by MAC OUI 60:92:c8 = Pi 5) |
| IP Local | 192.168.4.33 |
| MAC | 60:92:c8:11:cf:7c |
| Ping | **Responds** |
| SSH | **Connection refused** (port 22 closed) |
| Status | Powered on but not provisioned for SSH access |

> **ACTION REQUIRED:** SSH not configured. Needs keyboard/monitor access to enable SSH or re-flash SD.

---

### Cordelia — SSH Closed

| Field | Value |
|-------|-------|
| Board | Raspberry Pi 5 (confirmed by MAC OUI 6c:4a:85 = Pi 5) |
| IP Local | 192.168.4.27 |
| MAC | 6c:4a:85:32:ae:72 |
| Ping | **Responds** |
| SSH | **Connection refused** (port 22 closed) |
| Status | Powered on but not provisioned for SSH access |

> **ACTION REQUIRED:** Same as Anastasia — needs initial SSH setup.

---

### Olympia — Offline

| Field | Value |
|-------|-------|
| Board | Raspberry Pi 4B (PiKVM) |
| IP Local | pikvm.local (mDNS) |
| SSH | `ssh root@pikvm.local` |
| Status | **Offline** — not on network |

---

## 3. Cloud Compute (Live Verified)

### Codex-Infinity / "gematria" (159.65.43.12)

| Field | Value |
|-------|-------|
| Provider | DigitalOcean |
| CPU | DO-Premium-AMD (1 vCPU) |
| OS | (Debian/Ubuntu based) |
| RAM | ~765MB |
| Storage | 25GB+ |
| Public IP | 159.65.43.12 |
| Tailscale IP | 100.108.132.8 |
| Actual Hostname | **gematria** |
| Uptime | 55+ days |
| SSH | `ssh gematria` (user: blackroad) |
| Root | `ssh blackroad-os-infinity-root` (user: root) |

**Services:**
- `ollama.service` — LLM inference (port 11434, public!)
- `nginx.service` — Reverse proxy (80, 443)
- `cloudflared.service` — Tunnel
- Caddy (port 2019 admin)
- Python app (8787)
- Custom app (8011)

---

### Shellfish / "anastasia" (174.138.44.45)

| Field | Value |
|-------|-------|
| Provider | DigitalOcean |
| CPU | DO-Premium-AMD (1 vCPU) |
| OS | **CentOS Stream 9** (kernel 5.14.0-651.el9.x86_64) |
| RAM | 765MB total, 408MB used |
| Storage | 25GB, 15GB used (57%) |
| Public IP | 174.138.44.45 |
| Tailscale IP | 100.94.33.37 |
| Actual Hostname | **anastasia** |
| Uptime | **55 days** |
| SSH | `ssh anastasia` or `ssh cadence` (user: blackroad/shellfish) |
| Root | `ssh shellfish-root` (user: root) |

**Services:**
- `ollama.service` — LLM inference (port 11434, Tailscale-only at 100.64.0.1)
- `nginx.service` — Reverse proxy (80)
- `cloudflared.service` — Tunnel
- `docker.service` — Container runtime
- uvicorn API (port 8000)
- WebSocket servers (8765, 8766)
- Redis-like (6379)
- Grafana/dashboard (3000, 3001)
- Python apps (8080, 8787, 8888)

> **NAMING CONFUSION:** This droplet's hostname is "anastasia" which collides
> with the Pi 5 at 192.168.4.33 also named Anastasia. The SSH alias `anastasia`
> points to the DO droplet (174.138.44.45), NOT the Pi.

---

## 4. Unidentified Network Devices

Four devices discovered on the LAN with no agent registry entry.

| IP | MAC Address | OUI Vendor | Ping | Ports | Best Guess |
|----|-------------|-----------|------|-------|------------|
| 192.168.4.22 | 30:be:29:5b:24:5f | Unknown (possibly Hisense) | **UP** | No common ports open | Smart TV or IoT device |
| 192.168.4.44 | 98:17:3c:38:db:78 | **TP-Link** | **UP** | No common ports open | WiFi extender or smart plug |
| 192.168.4.83 | 54:4c:8a:9b:09:3d | Unknown (Shenzhen Bilian) | **UP** | No common ports open | Smart home WiFi module |
| 192.168.4.92 | de:a2:b7:f3:f9:5d | Locally administered (Apple) | **DOWN** | — | Apple device with private WiFi MAC |

> **ACTION:** Identify .22, .44, .83 by physical inspection or DHCP lease table on router.
> Could be Calliope and Sophia from agent registry, plus a network accessory.

---

## 5. AI Accelerator Summary — Corrected

| Accelerator | Node | Verified Method | TOPS | Status |
|-------------|------|----------------|------|--------|
| Hailo-8 M.2 | Cecilia | `/dev/hailo0` + `hailort.service` | 26 | **CONFIRMED active** |
| Hailo-8 M.2 | Octavia | SSH probe: `HAILO: none` | 26 | **NOT INSTALLED** |
| Hailo-8 M.2 | Aria | SSH probe: `HAILO: none` | 26 | **NOT INSTALLED** |
| Jetson Orin Nano | Jetson-Agent | Not deployed | 40 | Pending |
| Apple M1 NE | Alexandria | Known hardware | 15.8 | Active |
| Ethos-U55 | SenseCAP W1-A | Returned | ~1 | Returned |

### Corrected Compute Budget

| Category | TOPS | Status |
|----------|------|--------|
| Hailo-8 (1x confirmed) | 26 | **Active** |
| Apple M1 Neural Engine | 15.8 | Active |
| **Total confirmed active** | **41.8** | |
| Hailo-8 (2x uninstalled) | 52 | Available hardware, not installed |
| Jetson Orin Nano | 40 | Pending setup |
| **Total potential** | **~134** | If all installed |

> **Where are the other 2 Hailo-8 modules?** They were purchased ($215 each) but
> are not detected on Octavia or Aria. Check if they're physically seated in M.2
> slots or sitting uninstalled. Serials: HLLWM2B233704667 (Cecilia), HLLWM2B233704606 (unknown).

---

## 6. Network — Live ARP Table

Devices with confirmed MAC addresses as of 2026-02-21:

| IP | MAC | OUI | Hostname | Status |
|----|-----|-----|----------|--------|
| 192.168.4.1 | 44:ac:85:94:37:92 | TP-Link | Router | **UP** |
| 192.168.4.22 | 30:be:29:5b:24:5f | Unknown | **UNIDENTIFIED** | **UP** |
| 192.168.4.26 | d4:be:dc:6c:61:6b | Roku | Iris | **UP** |
| 192.168.4.27 | 6c:4a:85:32:ae:72 | Raspberry Pi 5 | Cordelia | **UP** (no SSH) |
| 192.168.4.28 | b0:be:83:66:cc:10 | Apple | Alexandria (Mac) | **UP** |
| 192.168.4.33 | 60:92:c8:11:cf:7c | Raspberry Pi 5 | Anastasia (Pi) | **UP** (no SSH) |
| 192.168.4.38 | 2c:cf:67:cf:fa:17 | Raspberry Pi | Octavia | **UP** |
| 192.168.4.44 | 98:17:3c:38:db:78 | TP-Link | **UNIDENTIFIED** | **UP** |
| 192.168.4.45 | d0:c9:07:50:51:ca | Espressif | Athena (ESP32) | **UP** |
| 192.168.4.49 | d8:3a:dd:ff:98:87 | Raspberry Pi | Alice | **UP** |
| 192.168.4.81 | (incomplete) | — | Lucidia | **DOWN** |
| 192.168.4.82 | 88:a2:9e:0d:42:07 | Raspberry Pi 5 | Aria | **UP** |
| 192.168.4.83 | 54:4c:8a:9b:09:3d | Unknown | **UNIDENTIFIED** | **UP** |
| 192.168.4.88 | 9e:0d:2a:82:99:96 | Private MAC | Phoebe (iPhone) | **DOWN** |
| 192.168.4.89 | 88:a2:9e:3b:eb:72 | Raspberry Pi 5 | Cecilia | **UP** |
| 192.168.4.90 | a0:4a:5e:2a:db:d2 | Microsoft | Ares (Xbox) | **DOWN** |
| 192.168.4.92 | de:a2:b7:f3:f9:5d | Private MAC | **UNIDENTIFIED** | **DOWN** |

### Stale Entry

| IP | Note |
|----|------|
| 192.168.4.74 | In `/etc/hosts` as "octavia" — **stale**. Octavia is now at .38. Remove. |

---

## 7. Tailscale Mesh — Corrected

| Node | Tailscale IP | SSH Alias | Verified |
|------|-------------|-----------|----------|
| Cecilia | 100.72.180.98 | cecilia-ts | SSH config |
| Lucidia | **100.83.149.86** | lucidia-ts | SSH config (was wrongly documented as .66.235.47) |
| Octavia | **100.66.235.47** | octavia-ts | SSH config + ss binding (was wrongly documented as .83.149.86) |
| Aria | 100.109.14.17 | aria-ts | SSH config |
| Alice | 100.77.210.18 | alice-ts | SSH config |
| Codex-Infinity | 100.108.132.8 | gematria-ts | SSH config |
| Shellfish | 100.94.33.37 | anastasia-ts / cadence-ts | SSH config |

> **Note:** Tailscale daemon is NOT running on Alexandria (Mac). `tailscale status` returns "not running".

---

## 8. DNS — Cloudflare Proxied

All `blackroad.io` DNS resolves to Cloudflare proxy IPs (not origin):

| Subdomain | Resolves To | Type |
|-----------|------------|------|
| blackroad.io | 172.67.211.99 | Cloudflare proxy |
| www.blackroad.io | 172.67.211.99 | Cloudflare proxy |
| api.blackroad.io | 172.67.211.99 | Cloudflare proxy |
| status.blackroad.io | 172.67.211.99 | Cloudflare proxy |
| docs.blackroad.io | 172.67.211.99 | Cloudflare proxy |
| dashboard.blackroad.io | 172.67.211.99 | Cloudflare proxy |
| agents.blackroad.io | 104.21.91.74 | Cloudflare proxy |
| monitoring.blackroad.io | 172.67.211.99 | Cloudflare proxy |
| tunnel-cecilia.blackroad.io | 172.67.211.99 | Cloudflare proxy |
| tunnel-lucidia.blackroad.io | 104.21.91.74 | Cloudflare proxy |
| tunnel-octavia.blackroad.io | 172.67.211.99 | Cloudflare proxy |
| tunnel-codex.blackroad.io | 104.21.91.74 | Cloudflare proxy |
| tunnel-cadence.blackroad.io | 172.67.211.99 | Cloudflare proxy |

All traffic routes: Client → Cloudflare CDN → Cloudflare Tunnel → Origin Node

---

## 9. SSH Configuration Truth Table

From `~/.ssh/config` (hardened 2026-02-19):

| Alias | HostName | User | Notes |
|-------|----------|------|-------|
| cecilia | 192.168.4.89 | blackroad | ed25519 key |
| lucidia | 192.168.4.81 | blackroad | ed25519 key |
| aria | 192.168.4.82 | blackroad | ed25519 key |
| octavia | 192.168.4.38 | blackroad | ed25519 key |
| alice | 192.168.4.49 | blackroad | ed25519 key |
| anastasia | **174.138.44.45** | blackroad | **Points to DO droplet, NOT the Pi!** |
| gematria | 159.65.43.12 | blackroad | Codex-Infinity droplet |
| cadence | 174.138.44.45 | shellfish | Same host as anastasia alias |
| olympia | pikvm.local | root | mDNS, not IP |
| alexandria / mac | 192.168.4.28 | alexa | Local Mac |
| lucidia-pi | 192.168.4.81 | pi | Legacy fallback user |
| *-ts | 100.x.x.x | blackroad | Tailscale aliases |
| *-root | DO IPs | root | Root access to droplets |

### Missing SSH Entries

- **Cordelia** (192.168.4.27) — no SSH config entry
- **Anastasia Pi** (192.168.4.33) — alias `anastasia` points to DO droplet instead

---

## 10. Storage — Live Verified

| Node | Device | Total | Used | Free | % | Verified |
|------|--------|-------|------|------|---|----------|
| Cecilia | /dev/nvme0n1p2 | 457GB | 65GB | 370GB | **15%** | SSH |
| Octavia | /dev/mmcblk0p2 | 235GB | 76GB | 148GB | **34%** | SSH |
| Aria | /dev/mmcblk0p2 | 29GB | 20GB | 7.3GB | **74%** | SSH |
| Alice | /dev/root | 15GB | 9.6GB | 4.1GB | **71%** | SSH |
| Shellfish | /dev/vda1 | 25GB | 15GB | 11GB | **57%** | SSH |
| Lucidia | — | — | — | — | — | DOWN |
| Anastasia Pi | — | — | — | — | — | No SSH |
| Cordelia | — | — | — | — | — | No SSH |

### Storage Alerts

| Priority | Node | Issue |
|----------|------|-------|
| High | Aria | 74% used, only 7.3GB free on 29GB card |
| Medium | Alice | 71% used, only 4.1GB free on 15GB root |
| Monitor | Shellfish | 57% used |
| OK | Cecilia | 15% used — healthiest node |
| OK | Octavia | 34% used — cleaned up from prior 90% |

---

## 11. OS Version Matrix

| Node | Distribution | Version | Kernel | Architecture |
|------|-------------|---------|--------|-------------|
| Cecilia | Debian | **13 (Trixie)** | 6.12.62+rpt-rpi-2712 | aarch64 |
| Octavia | Debian | 12 (Bookworm) | 6.12.62+rpt-rpi-2712 | aarch64 |
| Aria | Debian | 12 (Bookworm) | 6.12.62+rpt-rpi-2712 | aarch64 |
| Alice | **Raspbian** | **11 (Bullseye)** | **6.1.21-v8+** | aarch64 |
| Shellfish | **CentOS Stream** | **9** | 5.14.0-651.el9.x86_64 | x86_64 |
| Codex-Infinity | Unknown | — | — | x86_64 (DO-Premium-AMD) |
| Lucidia | (down) | — | — | — |
| Anastasia Pi | (no SSH) | — | — | — |
| Cordelia | (no SSH) | — | — | — |

> **Note:** The fleet is NOT uniform. Three different OS families and kernels in play.

---

## 12. Action Items

### Critical

1. **Investigate Lucidia** — Node is down. Check power, SD card, Ethernet. NATS bus may be affected.
2. **Locate 2 Hailo-8 modules** — Purchased but not detected on Octavia or Aria. Physical check needed.
3. **Fix Anastasia naming collision** — DO droplet hostname "anastasia" collides with Pi at .33. Rename droplet to "shellfish" or "cadence".

### High

4. **Enable SSH on Anastasia Pi** (.33) — Port 22 closed. Needs keyboard access to `sudo systemctl enable ssh`.
5. **Enable SSH on Cordelia** (.27) — Same issue.
6. **Add Cordelia to SSH config** — No entry exists.
7. **Fix SSH config** — `anastasia` alias should point to Pi (.33), not DO droplet.
8. **Reduce Octavia load** — Load avg 9.47 on 4-core, 6.6/7.9GB RAM. Migrate services.

### Medium

9. **Identify unknown devices** — .22, .44, .83 on the network. Check router DHCP leases.
10. **Clean up Aria storage** — 74% used, 7.3GB free.
11. **Remove stale /etc/hosts** — `192.168.4.74 octavia` is wrong (now .38).
12. **Upgrade Alice OS** — Bullseye (11) is EOL. Upgrade to Bookworm (12).
13. **Install Tailscale on Mac** — `tailscale status` shows "not running" on Alexandria.
14. **Add Anastasia + Cordelia to Tailscale** — Not in mesh yet.
15. **Correct agent registry** — Octavia and Aria listed as `pironman_hailo8` but have no Hailo.
16. **Fix `~/blackroad-fleet.yaml`** — Lucidia/Octavia IPs are swapped (both local and Tailscale).

---

## Appendix: Data Sources

| Source | Method | Trust Level |
|--------|--------|-------------|
| SSH probe (system info) | `ssh <host> "hostname; uname -r; ..."` | **Highest** — live system state |
| ARP table | `arp -a` | **High** — recent MAC-to-IP mappings |
| Ping sweep | `ping -c 1 -W 1` | **High** — reachability |
| Port scan | `ss -tlnp` via SSH | **Highest** — actual listening services |
| `~/.ssh/config` | File read | **High** — operational SSH aliases |
| DNS dig | `dig +short` | **High** — current DNS state |
| Agent registry DB | SQLite query | **Medium** — may be stale |
| `~/blackroad-fleet.yaml` | File read | **Low** — contains known errors (IPs swapped) |
| Prior documentation | Various .md files | **Low** — multiple inaccuracies found |
