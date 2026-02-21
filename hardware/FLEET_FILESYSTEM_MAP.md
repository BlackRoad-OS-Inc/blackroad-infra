# Fleet Filesystem Map — All Nodes

**Scanned 2026-02-21 via SSH probes — Updated with live corrections**

---

## Fleet Storage Overview

| Node | Disk | Type | Size | Used | Free | Use% |
|------|------|------|------|------|------|------|
| Alexandria | APFS SSD | Apple SSD | 460G | 449G | 11G | **98%** |
| Cecilia | NVMe (root) | Crucial P310 | 466G | 65G | 370G | 15% |
| Cecilia | SD (secondary) | Samsung EVO | 238G | — | — | Mounted at /media |
| Lucidia | SD (root) | microSD | 119G | 53G | 60G | 47% |
| Lucidia | NVMe (data) | 1TB NVMe | 916G | 1.8G | 868G | 1% |
| Octavia | SD | Samsung EVO | 238G | 76G | 148G | 34% |
| Aria | SD | microSD | 29G | 18G | 9.5G | 66% |
| Alice | SD | microSD | 15G | 9.2G | 4.5G | 68% |
| Codex-Infinity | VPS SSD | DigitalOcean | 80G | 21G | 57G | 27% |
| Shellfish | VPS SSD | DigitalOcean | 25G | 15G | 11G | 57% |
| **Fleet Total** | | | **2,586G** | **698G** | **1,540G** | |

> **Healthiest node:** Lucidia (1TB NVMe at 1%, 868G free)
> **Most critical:** Alexandria Mac (98%, 11G free)

### CRITICAL FINDING: Hostname Mismatch

The machine at **192.168.4.81** (SSH alias `lucidia`) has `/etc/hostname` set to **"octavia"**.
This is a different Pi 5 from the real Octavia at 192.168.4.38 (confirmed by different serial numbers).
The .81 node has the 1TB NVMe, Hailo-8, and hailort service — it IS the Lucidia hardware.
The hostname needs to be corrected to "lucidia".

| Property | lucidia (192.168.4.81) | octavia (192.168.4.38) |
|----------|----------------------|----------------------|
| Serial | a91e903b3e7bfcc4 | aa088196e6935b14 |
| Storage | 119G SD + **931G NVMe** | 238G SD only |
| Hailo-8 | **hailort.service running** | None |
| /etc/hostname | ~~octavia~~ (WRONG) | octavia |
| Tailscale IP | 100.83.149.86 | 100.66.235.47 |

---

## Per-Node Filesystem Maps

### Cecilia (Pi 5 — 500GB NVMe root)

```
/dev/nvme0n1p2  466G root (ext4, 15% used)
/dev/nvme0n1p1  512M /boot/firmware
/dev/mmcblk0p1  238G SD card mounted at /media/cecilia/bootfs
zram0           2G   swap
```

**Users:**

| User | UID | Home |
|------|-----|------|
| cecilia | 1000 | /home/cecilia |
| blackroad | 1001 | /home/blackroad |
| alexa | 1002 | /home/alexa |
| ollama | 999 | /usr/share/ollama |
| postgres | 110 | /var/lib/postgresql |
| minio | 996 | /home/minio |
| influxdb | 997 | /var/lib/influxdb |

**Top Space Consumers:**

| Directory | Size | Contents |
|-----------|------|----------|
| /home/blackroad/alexandria-sync/ | 6.3G | Synced data from Mac |
| /opt/Wolfram/ | 4.9G | Wolfram Mathematica |
| /home/blackroad/models/ | 4.4G | ML/LLM models |
| /var/cache/ | 4.1G | Package cache |
| /home/blackroad/blackroad-source/ | 2.0G | BlackRoad source code |
| /home/blackroad/claude/ | 1.8G | Claude session data |
| /opt/Scratch 3/ | 421M | Scratch programming |
| /home/blackroad/alexandria-archive/ | 92M | Archive from Mac |
| /opt/pironman5/ | 70M | Pironman case controller |
| /home/blackroad/blackroad-memory-index/ | 45M | Memory search index |
| /home/blackroad/datasets/ | 25M | Training datasets |

> xmrig-build (33M) removed 2026-02-21.

---

### Lucidia (Pi 5 — 119GB SD root + 1TB NVMe data)

> **NOTE:** This node's `/etc/hostname` is incorrectly set to "octavia".
> It is at 192.168.4.81 (Tailscale 100.83.149.86), serial a91e903b3e7bfcc4.
> This is the only Pi with a 1TB NVMe and running hailort.service.

```
/dev/mmcblk0p2  119G root (47% used, 60G free)
/dev/mmcblk0p1  512M /boot/firmware
/dev/nvme0n1p1  916G /mnt/nvme (1% used, 868G free!)
zram0           2G   swap
```

**Users:**

| User | UID | Home |
|------|-----|------|
| pi | 1000 | /home/pi |
| lucidia | 1001 | /home/lucidia |
| blackroad | 1002 | /home/blackroad |
| alexa | 1003 | /home/alexa |
| ollama | 999 | /usr/share/ollama |

**Top Space Consumers:**

| Directory | Size | Contents |
|-----------|------|----------|
| /home/blackroad/models/ | 4.4G | ML/LLM models |
| /var/cache/ | 752M | Package cache |
| /opt/pironman5/ | 70M | Pironman case controller |
| /home/blackroad/blackroad-memory-index/ | 45M | Memory search index |
| /home/blackroad/datasets/ | 25M | Training datasets |
| /home/blackroad/blackroad-node/ | 10M | BlackRoad node |

**NVMe Contents (/mnt/nvme — 868G free):**

| Directory | Contents |
|-----------|----------|
| blackroad/ | BlackRoad data |
| models/ | AI model storage |
| quantum_discoveries/ | Quantum research data |

**Services:** Ollama (127.0.0.1:11434), Cloudflared, Docker, hailort, InfluxDB, Pironman5, Tailscale, NATS (4222/8222), PowerDNS Admin (port 80)

> **No xmrig found** — this node was clean.

---

### Octavia (Pi 5 — 238GB SD)

```
/dev/mmcblk0p2  238G root (34% used, 148G free)
/dev/mmcblk0p1  512M /boot/firmware
```

**Users (6 human accounts!):**

| User | UID | Home |
|------|-----|------|
| pi | 1000 | /home/pi |
| deploy | 1001 | /home/deploy |
| lucidia | 1002 | /home/lucidia |
| octavia | 1003 | /home/octavia |
| blackroad | 1004 | /home/blackroad |
| alexa | 1005 | /home/alexa |
| ollama | 995 | /usr/share/ollama |
| postgres | 112 | /var/lib/postgresql |
| influxdb | 994 | /var/lib/influxdb |

**Top Space Consumers:**

| Directory | Size | Contents |
|-----------|------|----------|
| /home/blackroad/models/ | 4.4G | ML/LLM models |
| /var/log/ | **2.6G** | **Logs (needs rotation!)** |
| /home/blackroad/quantum-venv/ | 742M | Python quantum venv |
| /opt/Scratch 3/ | 421M | Scratch programming |
| /home/blackroad/blackroad-memory-index/ | 45M | Memory search index |
| /home/blackroad/datasets/ | 25M | Training datasets |
| /opt/pironman5/ | 68M | Pironman case controller |

> xmrig-build (33M) removed 2026-02-21. Logs still need root to rotate.

---

### Aria (Pi 5 — 29GB SD)

```
/dev/mmcblk0p2  29G root (66% used, 9.5G free)
/dev/mmcblk0p1  512M /boot/firmware
```

**Users (7 human accounts!):**

| User | UID | Home |
|------|-----|------|
| pi | 1000 | /home/pi |
| headscale | 1001 | /home/headscale |
| alice | 1002 | /home/alice |
| lucidia | 1003 | /home/lucidia |
| aria | 1004 | /home/aria |
| blackroad | 1005 | /home/blackroad |
| alexa | 1006 | /home/alexa |
| ollama | 995 | /usr/share/ollama |
| influxdb | 994 | /var/lib/influxdb |

**Top Space Consumers:**

| Directory | Size | Contents |
|-----------|------|----------|
| /var/lib/ | 209M | System state |
| /var/log/ | 123M | Logs |
| /var/cache/ | 120M | Package cache |
| /opt/pironman5/ | 70M | Pironman case controller |
| /home/blackroad/blackroad-memory-index/ | 45M | Memory search index |
| /opt/blackroad/ | 30M | BlackRoad system install |

> **NOTE:** Aria has a `headscale` user — was this node running Headscale VPN server?

---

### Alice (Pi 400 — 15GB SD)

```
/dev/mmcblk0p2  15G root (68% used, 4.5G free)
/dev/mmcblk0p1  256M /boot
```

**Users:**

| User | UID | Home |
|------|-----|------|
| alice | 1000 | /home/alice |
| pi | 1001 | /home/pi |
| blackroad | 1002 | /home/blackroad |
| alexa | 1003 | /home/alexa |
| pihole | 998 | /home/pihole |
| caddy | 999 | /var/lib/caddy |
| ollama | 997 | /usr/share/ollama |

**Top Space Consumers:**

| Directory | Size | Contents |
|-----------|------|----------|
| /var/lib/ | 371M | System state (pihole DB, caddy, etc.) |
| /var/log/ | 140M | Logs |
| /home/blackroad/blackroad-memory-index/ | 45M | Memory search index |
| /opt/blackroad/ | 40M | BlackRoad system install |
| /var/www/ | 13M | Web content |
| /home/pi/ (various) | ~14M | Pi user projects |

> **Services on Alice:** Pi-hole (DNS ad-blocker), Caddy (web server), Ollama

---

### Codex-Infinity / gematria (DO — 80GB VPS)

```
/dev/vda1  78G root (27% used, 57G free)  ← cleaned from 33%
/dev/vda15 105M /boot/efi
```

**Users:**

| User | UID | Home |
|------|-----|------|
| codex | 1000 | /home/codex |
| blackroad | 1001 | /home/blackroad |
| alexa | 1002 | /home/alexa |
| ollama | 996 | /usr/share/ollama |
| caddy | 997 | /var/lib/caddy |
| nginx | (via yum) | — |

**Top Space Consumers (after cleanup):**

| Directory | Size | Contents |
|-----------|------|----------|
| /var/log/ | 1.5G | Logs (rotated from 5.3G) |
| /var/lib/ | 786M | System state |
| /var/cache/ | 212M | Package cache |
| /home/blackroad/blackroad-memory-index/ | 45M | Memory search index |

> **Cleaned 2026-02-21:** Removed 3.6G RISC-V toolchains, 3.8G journal logs, 4.4M xmrig.
> Ollama binding fixed from 0.0.0.0 to 127.0.0.1:11434.

---

### Shellfish / anastasia (DO — 25GB VPS)

```
/dev/vda1  25G root (57% used, 11G free)
OS: CentOS Stream 9 / Fedora-based
```

**Users:**

| User | UID | Home |
|------|-----|------|
| alexa | 1000 | /home/alexa |
| pi | 1001 | /home/pi |
| shellfish | 1002 | /home/shellfish |
| blackroad | 1003 | /home/blackroad |
| ollama | 989 | /usr/share/ollama |
| nginx | 990 | /var/lib/nginx |
| caddy | 986 | /var/lib/caddy |

**Top Space Consumers:**

| Directory | Size | Contents |
|-----------|------|----------|
| /var/cache/ | 514M | Package cache (dnf) |
| /opt/blackroad-prism-console/ | 400M | Prism Console app |
| /var/log/ | 347M | Logs |
| /home/blackroad/ | 293M | BlackRoad user data |
| /var/lib/ | 180M | System state |
| /home/shellfish/ | 108M | Shellfish user data |
| /home/blackroad/claude/ | 80M | Claude session data |
| /home/blackroad/blackroad-memory-index/ | 45M | Memory search index |
| /home/shellfish/blackroad-memory-index/ | 45M | Duplicate memory index |
| /opt/blackroad-api/ | 23M | BlackRoad API |

---

## Cross-Fleet Analysis

### User Account Inconsistency

The `blackroad` user has a **different UID on every node**:

| Node | blackroad UID | alexa UID | Primary user (UID 1000) |
|------|--------------|-----------|------------------------|
| Alexandria (Mac) | — | 501 (alexa) | alexa |
| Cecilia | **1001** | 1002 | cecilia |
| Lucidia | **1002** | 1003 | pi |
| Octavia | **1004** | 1005 | pi |
| Aria | **1005** | 1006 | pi |
| Alice | **1002** | 1003 | alice |
| Codex-Infinity | **1001** | 1002 | codex |
| Shellfish | **1003** | 1000 (!) | alexa |

> **Problem:** NFS/rsync between nodes will have ownership mismatches.
> Consider standardizing UIDs across the fleet (e.g., blackroad=1100, alexa=1101).

### Extra Users Per Node

| Node | Extra Users | Notes |
|------|------------|-------|
| Cecilia | cecilia, minio, postgres, influxdb | Observability stack |
| Lucidia | pi, lucidia | Minimal user set (cleanest node) |
| Octavia | pi, deploy, lucidia, nova, octavia, postgres, influxdb | 6 human accounts! |
| Aria | pi, headscale, alice, lucidia, aria, influxdb | 7 human accounts! headscale user |
| Alice | alice, pi, pihole, caddy | Pi-hole DNS |
| Codex-Infinity | codex, caddy, nginx | RISC-V dev (cleaned) |
| Shellfish | alexa, pi, shellfish, nginx, caddy | CentOS |

### xmrig Remnants — CLEANED 2026-02-21

All xmrig binaries, services, and build artifacts have been removed.

| Node | Path | Status |
|------|------|--------|
| Cecilia | /home/blackroad/xmrig-build/ | **DELETED** |
| Cecilia | /home/blackroad/bin/xmrig + systemd service | **DELETED** (was running at 198% CPU) |
| Octavia | /home/blackroad/xmrig-build/ | **DELETED** |
| Octavia | /home/blackroad/bin/xmrig + systemd service | **DELETED** (was running at 132% CPU) |
| Alice | /home/blackroad/xmrig-build/ | **DELETED** |
| Alice | /home/blackroad/bin/xmrig + systemd service | **DELETED** (service existed but not running) |
| Codex-Infinity | /opt/xmrig/ | **DELETED** |
| Lucidia | — | Clean (never infected) |
| Aria | — | Clean (never infected) |

> All were mining Monero to pool.hashvault.pro:80, deployed 2026-02-20.

### Log Bloat — Partially Cleaned 2026-02-21

| Node | /var/log Before | After | Action |
|------|----------------|-------|--------|
| Codex-Infinity | **5.3G** | **1.5G** | Rotated (freed 3.8G) |
| Octavia | **2.6G** | 2.6G | Needs root (no passwordless sudo) |
| Lucidia | 1.8M | — | Clean |
| Shellfish | 347M | — | OK |
| Alice | 140M | — | OK |
| Aria | 123M | — | OK |
| Cecilia | 3.2M | — | Clean |

### Software Installed Across Fleet

| Software | Cecilia | Lucidia | Octavia | Aria | Alice | Codex-Inf | Shellfish |
|----------|---------|---------|---------|------|-------|-----------|-----------|
| Ollama | yes | yes | yes | yes | yes | yes | yes |
| Docker | yes | yes | yes | yes | yes | — | — |
| Cloudflared | yes | yes | yes | yes | yes | yes | yes |
| Tailscale | yes | yes | yes | yes | yes | yes | yes |
| Hailo-8 (hailort) | yes | **yes** | — | — | — | — | — |
| PostgreSQL | yes | — | yes | — | — | — | — |
| InfluxDB | yes | yes | yes | yes | — | — | — |
| NATS | — | yes | — | — | — | — | — |
| nginx | — | — | — | — | — | yes | yes |
| Caddy | — | — | — | — | yes | yes | yes |
| Pi-hole | — | — | — | — | yes | — | — |
| PowerDNS Admin | — | yes | — | — | — | — | — |
| Pironman5 | yes | yes | yes | yes | — | — | — |
| MinIO | yes | — | — | — | — | — | — |
| Wolfram | yes | — | — | — | — | — | — |
| Scratch 3 | yes | — | yes | — | — | — | — |
| Headscale | — | — | — | yes(user) | — | — | — |
| Prism Console | — | — | — | — | — | — | yes |

### Shared Directories Across Fleet

Every node has:
- `/home/blackroad/blackroad-memory-index/` (45M) — memory search index
- `/opt/blackroad/` — BlackRoad system install (mostly empty scaffolding)
- `/home/blackroad/blackroad-nlp/` — NLP module
- `/home/blackroad/roadpad/` — Roadpad CLI

### RISC-V Toolchains on Codex-Infinity — CLEANED 2026-02-21

All RISC-V development toolchains have been removed. Freed ~3.6G.
Codex-Infinity now at 27% usage (was 33%), 57G free (was 52G).

```
DELETED: /root/bouffalo_sdk/              1.9G  — Bouffalo BL808 SDK
DELETED: /root/M1s_BL808_SDK/             758M  — M1s Dock SDK
DELETED: /root/M1s_BL808_example/         178M  — Examples
DELETED: /opt/Xuantie-900-gcc-elf-newlib/ 732M  — T-Head RISC-V compiler
DELETED: /root/blackroad-watch-firmware/   40M  — SenseCAP watch firmware
```

> SenseCAP Watcher was returned Aug 2025. Toolchains removed 2026-02-21.

---

## Fleet Storage Health (Updated 2026-02-21)

| Status | Node | Disk | Use% | Free | Action |
|--------|------|------|------|------|--------|
| **CRITICAL** | Alexandria | 460G SSD | 98% | 11G | Remove Unity (93G) or Bitcoin node pruning |
| OK | Cecilia | 466G NVMe | 15% | 370G | Healthy |
| **BEST** | Lucidia | 916G NVMe | 1% | 868G | Best storage in fleet, use for offloading |
| OK | Lucidia | 119G SD | 47% | 60G | Root disk healthy |
| OK | Octavia | 238G SD | 34% | 148G | Logs need root to rotate (2.6G) |
| WARN | Aria | 29G SD | 66% | 9.5G | Consider NVMe upgrade |
| WARN | Alice | 15G SD | 68% | 4.5G | Tiny disk, limited capacity |
| OK | Codex-Infinity | 78G VPS | 27% | 57G | Cleaned (was 33%) |
| WARN | Shellfish | 25G VPS | 57% | 11G | Monitor |

### Remaining Actions

| # | Item | Blocker |
|---|------|---------|
| 1 | Octavia: rotate 2.6G logs | No passwordless sudo for `blackroad` user |
| 2 | Lucidia: fix `/etc/hostname` from "octavia" to "lucidia" | Needs root |
| 3 | Alexandria: free disk space (Unity 93G, .bitcoin-main 89G) | User decision needed |
| 4 | Octavia: `apple-finetune-270m.py` processes may restart | Rebooted, clear for now |
