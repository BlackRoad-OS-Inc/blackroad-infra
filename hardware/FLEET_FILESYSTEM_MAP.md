# Fleet Filesystem Map — All Nodes

**Scanned 2026-02-21 via SSH probes**

---

## Fleet Storage Overview

| Node | Disk | Type | Size | Used | Free | Use% |
|------|------|------|------|------|------|------|
| Alexandria | APFS SSD | Apple SSD | 460G | 449G | 11G | **98%** |
| Cecilia | NVMe (root) | Crucial P310 | 466G | 65G | 370G | 15% |
| Cecilia | SD (secondary) | Samsung EVO | 238G | — | — | Mounted at /media |
| Octavia | SD | Samsung EVO | 238G | 76G | 148G | 34% |
| Aria | SD | microSD | 29G | 18G | 9.5G | 66% |
| Alice | SD | microSD | 15G | 9.2G | 4.5G | 68% |
| Codex-Infinity | VPS SSD | DigitalOcean | 80G | 26G | 52G | 33% |
| Shellfish | VPS SSD | DigitalOcean | 25G | 15G | 11G | 57% |
| **Fleet Total** | | | **1,551G** | **658G** | **606G** | |

> **Healthiest node:** Cecilia (15%, 370G free on NVMe)
> **Most critical:** Alexandria Mac (98%, 11G free)

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
| /home/blackroad/xmrig-build/ | **33M** | **xmrig build artifacts (REMNANT)** |
| /home/blackroad/datasets/ | 25M | Training datasets |

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
| /home/blackroad/xmrig-build/ | **33M** | **xmrig build artifacts (REMNANT)** |
| /home/blackroad/datasets/ | 25M | Training datasets |
| /opt/pironman5/ | 68M | Pironman case controller |

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
| /home/blackroad/xmrig-build/ | **30M** | **xmrig build artifacts (REMNANT)** |
| /var/www/ | 13M | Web content |
| /home/pi/ (various) | ~14M | Pi user projects |

> **Services on Alice:** Pi-hole (DNS ad-blocker), Caddy (web server), Ollama

---

### Codex-Infinity / gematria (DO — 80GB VPS)

```
/dev/vda1  80G root (33% used, 52G free)
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

**Top Space Consumers:**

| Directory | Size | Contents |
|-----------|------|----------|
| /var/log/ | **5.3G** | **Logs (critical — needs rotation!)** |
| /root/bouffalo_sdk/ | 1.9G | Bouffalo RISC-V SDK |
| /root/M1s_BL808_SDK/ | 758M | BL808 RISC-V SDK |
| /var/lib/ | 786M | System state |
| /opt/Xuantie-900-gcc-elf-newlib/ | 732M | RISC-V cross-compiler |
| /var/cache/ | 212M | Package cache |
| /root/M1s_BL808_example/ | 178M | RISC-V examples |
| /home/blackroad/blackroad-memory-index/ | 45M | Memory search index |
| /root/blackroad-watch-firmware/ | 40M | SenseCAP watch firmware |
| /opt/xmrig/ | **4.4M** | **xmrig installation (REMNANT!)** |

> **RISC-V development node:** Root user has 3.6G of RISC-V toolchains (Bouffalo BL808, Xuantie-900).
> This was used for SenseCAP Watcher firmware development.

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
| Octavia | pi, deploy, lucidia, nova, octavia, postgres, influxdb | 6 human accounts! |
| Aria | pi, headscale, alice, lucidia, aria, influxdb | 7 human accounts! headscale user |
| Alice | alice, pi, pihole, caddy | Pi-hole DNS |
| Codex-Infinity | codex, caddy, nginx | RISC-V dev |
| Shellfish | alexa, pi, shellfish, nginx, caddy | CentOS |

### xmrig Remnants (Clean Up!)

| Node | Path | Size | Status |
|------|------|------|--------|
| Cecilia | /home/blackroad/xmrig-build/ | 33M | **Build artifacts — DELETE** |
| Octavia | /home/blackroad/xmrig-build/ | 33M | **Build artifacts — DELETE** |
| Alice | /home/blackroad/xmrig-build/ | 30M | **Build artifacts — DELETE** |
| Codex-Infinity | /opt/xmrig/ | 4.4M | **Installation — DELETE** |

### Log Bloat

| Node | /var/log Size | Action |
|------|--------------|--------|
| Codex-Infinity | **5.3G** | Rotate immediately |
| Octavia | **2.6G** | Rotate |
| Shellfish | 347M | OK |
| Alice | 140M | OK |
| Aria | 123M | OK |
| Cecilia | 3.2M | Clean |

### Software Installed Across Fleet

| Software | Cecilia | Octavia | Aria | Alice | Codex-Inf | Shellfish |
|----------|---------|---------|------|-------|-----------|-----------|
| Ollama | yes | yes | yes | yes | yes | yes |
| Docker | yes | yes | yes | yes | — | — |
| Cloudflared | yes | yes | yes | yes | yes | yes |
| Tailscale | yes | yes | yes | yes | yes | yes |
| PostgreSQL | yes | yes | — | — | — | — |
| InfluxDB | yes | yes | yes | — | — | — |
| nginx | — | — | — | — | yes | yes |
| Caddy | — | — | — | yes | yes | yes |
| Pi-hole | — | — | — | yes | — | — |
| Pironman5 | yes | yes | yes | — | — | — |
| MinIO | yes | — | — | — | — | — |
| Wolfram | yes | — | — | — | — | — |
| Scratch 3 | yes | yes | — | — | — | — |
| Headscale | — | — | yes(user) | — | — | — |
| Prism Console | — | — | — | — | — | yes |

### Shared Directories Across Fleet

Every node has:
- `/home/blackroad/blackroad-memory-index/` (45M) — memory search index
- `/opt/blackroad/` — BlackRoad system install (mostly empty scaffolding)
- `/home/blackroad/blackroad-nlp/` — NLP module
- `/home/blackroad/roadpad/` — Roadpad CLI

### RISC-V Toolchains on Codex-Infinity

```
/root/bouffalo_sdk/              1.9G  — Bouffalo BL808 SDK
/root/M1s_BL808_SDK/             758M  — M1s Dock SDK
/root/M1s_BL808_example/         178M  — Examples
/opt/Xuantie-900-gcc-elf-newlib/ 732M  — T-Head RISC-V compiler
/root/blackroad-watch-firmware/   40M  — SenseCAP watch firmware
                                 -----
Total RISC-V dev:                3.6G
```

> SenseCAP Watcher was returned Aug 2025. These toolchains can be removed to free 3.6G.

---

## Fleet Storage Health

| Status | Node | Disk | Use% | Free | Action |
|--------|------|------|------|------|--------|
| **CRITICAL** | Alexandria | 460G SSD | 98% | 11G | Remove Unity (93G) or Bitcoin node pruning |
| OK | Cecilia | 466G NVMe | 15% | 370G | Healthiest node |
| OK | Octavia | 238G SD | 34% | 148G | Clean 2.6G logs |
| WARN | Aria | 29G SD | 66% | 9.5G | Consider NVMe upgrade |
| WARN | Alice | 15G SD | 68% | 4.5G | Tiny disk, limited capacity |
| OK | Codex-Infinity | 80G VPS | 33% | 52G | Clean 5.3G logs + 3.6G RISC-V |
| WARN | Shellfish | 25G VPS | 57% | 11G | Monitor |
