# Alexandria (Mac) — Filesystem & Ownership Map

**Scanned 2026-02-21**

---

## Disk Layout

```
/dev/disk3 — 460GB APFS Container (Apple SSD)
├─ disk3s1s1  /                              9.6G used   (OS sealed snapshot)
├─ disk3s5    /System/Volumes/Data          426G used    (98% — ALL user data lives here)
├─ disk3s6    /System/Volumes/VM             5.0G        (swap)
├─ disk3s2    /System/Volumes/Preboot        6.5G
└─ disk3s4    /System/Volumes/Update         1.5M

/dev/disk1 — 500MB Internal (iSCPreboot, xarts, Hardware)

Available space: ~11GB (2.4%)
```

> **WARNING:** Disk is 98% full with only ~11GB free. This is critical.

---

## User Accounts

| User | UID | Home | Role |
|------|-----|------|------|
| `alexa` | 501 | /Users/alexa | **Owner/Operator** — primary account |
| `maggiecox` | 502 | /Users/maggiecox | Secondary user (last login Jun 2024) |
| `root` | 0 | /var/root | System root |
| `com.malwarebytes.mbam.nobody` | 1000 | — | Malwarebytes daemon |

---

## Ownership Model

```
/                       root:wheel      (macOS system)
├── Applications/       root:admin      (101 apps)
├── Library/            root:wheel      (8.2G system libs)
├── System/             root:wheel      (macOS sealed)
├── Users/
│   ├── alexa/          alexa:staff     (3,920 items — THE BIG ONE)
│   ├── maggiecox/      maggiecox:staff (11 items)
│   └── Shared/         root:wheel
├── opt/
│   ├── blackroad/      alexa:staff     (empty scaffolding)
│   └── homebrew/       alexa:admin     (package manager)
├── usr/local/
│   ├── bin/            root:wheel      (48 binaries — node, python, docker, etc.)
│   ├── go/             root:wheel      (Go installation)
│   └── lib/            root:wheel
├── private/
│   ├── etc/            root:wheel      (→ /etc symlink)
│   ├── var/            root:wheel      (2.1G db, 38M logs)
│   └── tmp/            root:wheel      (→ /tmp symlink)
└── blackroad           root:wheel      (symlink → /System/Volumes/Data/blackroad)
```

---

## /Users/alexa — Home Directory (426G+ used)

**3,920 directories, 2,994 files, 50 symlinks at top level**

### Space Breakdown

| Category | Size | Items | Location |
|----------|------|-------|----------|
| **Shell scripts (.sh)** | **7.8G** | **1,026** | `~/*.sh` |
| **Markdown docs (.md)** | **10.9G** | **1,022** | `~/*.md` |
| **Python scripts (.py)** | — | **135** | `~/*.py` |
| **RTF documents** | ~1M | ~25 | `~/*.rtf` |

### Major Directories

| Directory | Size | Owner | Purpose |
|-----------|------|-------|---------|
| `BlackRoad-Private/` | **30G** | alexa:staff | Private repos & data |
| `BlackRoad-Public/` | 3.6G | alexa:staff | Public repos |
| `services/` | 1.4G | alexa:staff | Web services (Next.js, etc.) |
| `.blackroad/` | 1.4G | alexa:staff | Memory system (156K+ entries, journals, tasks) |
| `.rustup/` | 1.2G | alexa:staff | Rust toolchains |
| `.claude/` | 941M | alexa:staff | Claude Code sessions, plans |
| `.local/` | 777M | alexa:staff | User binaries (br, ai, ask, etc.) |
| `.npm/` | 166M | alexa:staff | npm cache |
| `.models/` | 141M | alexa:staff | ML models |
| `Alexandria/` | 128M | alexa:staff | Named workspace |
| `.cargo/` | 111M | alexa:staff | Rust packages |
| `BlackRoad-OS-Inc/` | 104M | alexa:staff | Corporate repos (blackroad-infra, etc.) |
| `.codex/` | 102M | alexa:staff | Codex sessions, memory, achievements |
| `.docker/` | 43M | alexa:staff | Docker config |
| `.roadchain/` | 25M | alexa:staff | RoadChain identity system |
| `.nvm/` | 24M | alexa:staff | Node version manager |
| `.blackroad-rag/` | 15M | alexa:staff | RAG pipeline data |
| `copilot-agent-gateway/` | 11M | alexa:staff | Copilot agent proxy |
| `.lucidia/` | 9M | alexa:staff | Lucidia agent state |
| `.ssh/` | 184K | alexa:staff | SSH keys & config |
| `.ollama/` | 40K | alexa:staff | Ollama config (models on fleet, not Mac) |

### BlackRoad Organization Repos (cloned)

| Directory | Size | Org |
|-----------|------|-----|
| `BlackRoad-Private/` | 30G | Private workspace |
| `BlackRoad-Public/` | 3.6G | Public workspace |
| `BlackRoad-OS-Inc/` | 104M | Corporate (blackroad-infra) |
| `BlackRoad-Apps-Dev/` | 1.1M | App development |
| `BlackRoad-Anthropic/` | 212K | Anthropic integration |
| `BlackRoad-OpenAI/` | 212K | OpenAI integration |
| `BlackRoad-Google/` | 212K | Google integration |
| `BlackRoad-xAI/` | 212K | xAI integration |
| `BlackRoad-Communication/` | 224K | Communications |
| `BlackRoad-Internal/` | 196K | Internal docs |
| `BlackRoad-Me/` | 132K | Personal |

### Hidden Infrastructure

| Directory | Size | Purpose |
|-----------|------|---------|
| `.blackroad/memory/journals/` | — | PS-SHA-infinity append-only log (master-journal.jsonl) |
| `.blackroad/memory/tasks/` | — | Task marketplace (2,299 tasks) |
| `.blackroad/memory/active-agents/` | — | Running Claude instances |
| `.blackroad/memory/til/` | — | 149 shared learnings |
| `.blackroad-agent-registry.db` | 57K | SQLite — 35 agents (17 hardware) |
| `.blackroad-traffic-light.db` | — | Project status (58 green) |
| `.blackroad-compliance.db` | 40K | Compliance tracking |
| `.blackroad-agent-protocol.db` | 49K | Agent protocols |
| `.blackroad-30k-orchestrator.db` | 90K | Scale orchestrator |

### Databases (SQLite)

| File | Size | Tables |
|------|------|--------|
| `.blackroad-agent-registry.db` | 57K | agents, agent_services, agent_capabilities |
| `.blackroad-agent-protocol.db` | 49K | — |
| `.blackroad-compliance.db` | 40K | — |
| `.blackroad-30k-orchestrator.db` | 90K | — |
| `.blackroad-agent-directory.db` | 4K | — |

---

## /Applications — 101 Apps

### Top by Size

| App | Size | Owner |
|-----|------|-------|
| Unity | **93G** | root:admin |
| Microsoft Outlook | 2.7G | root:admin |
| Microsoft Word | 2.6G | root:admin |
| Microsoft Excel | 2.5G | root:admin |
| Unity Project (2) | 2.2G | root:admin |
| Docker Desktop | 2.1G | root:admin |
| PyCharm | 2.0G | root:admin |
| Microsoft PowerPoint | 2.0G | root:admin |
| Unity Project (1) | 1.7G | root:admin |
| Microsoft OneNote | 1.3G | root:admin |
| Google Chrome | 1.3G | root:admin |
| OneDrive | 1.2G | root:admin |
| Microsoft Teams | 1.1G | root:admin |
| AKS Desktop | 1.0G | root:admin |
| Pyto | 850M | root:admin |
| GeForce NOW | 839M | root:admin |
| Arc (×3 copies!) | 2.4G | root:admin |
| EnclaveAI | 778M | root:admin |
| VS Code | 640M | root:admin |
| GoLogin | 593M | root:admin |
| Termius | 530M | root:admin |
| Claude | 507M | root:admin |
| Slack | 501M | root:admin |

> **NOTE:** Unity alone is 93G (20% of disk!). 3 copies of Arc Browser installed.

---

## /opt — System-level BlackRoad

```
/opt/
├── blackroad/          alexa:staff    (empty scaffolding)
│   ├── agents/
│   ├── config/
│   ├── devices/
│   ├── logs/
│   ├── services/
│   ├── shared/         (group-writable)
│   └── tmp/            (world-writable, sticky bit)
└── homebrew/           alexa:admin    (Homebrew package manager)
```

---

## /usr/local/bin — System Binaries (48)

| Binary | Owner | Type |
|--------|-------|------|
| `node` (222MB) | root:wheel | Node.js v22 |
| `python3` → Python 3.13 | root:wheel | Symlink to Framework |
| `docker` → Docker.app | root:wheel | Symlink |
| `kubectl` → Docker.app | root:wheel | Symlink |
| `lucidia` → ~/lucidia-cli | root:wheel | Symlink to user script |
| `br-new`, `br-panel` | alexa:staff | BlackRoad CLI tools |
| `pip3`, `pip3.11`, `pip3.13` | root:admin | Python package managers |
| `go` | root:wheel | Go 1.x |

---

## System Library — /Library (8.2G)

| Directory | Size |
|-----------|------|
| Developer/ | 2.9G (Xcode tools) |
| Frameworks/ | 2.5G (Python, .NET, etc.) |
| Application Support/ | 2.5G |
| Apple/ | 68M |

---

## User Library — ~/Library

| Directory | Size |
|-----------|------|
| Caches/ | 883M |
| Application Support/ | Large (scan timed out) |
| Developer/ | Large (scan timed out) |

---

## Special Mounts

| Mount | Target | Type |
|-------|--------|------|
| `/blackroad` | `/System/Volumes/Data/blackroad` | Symlink (root:wheel) |
| `/home` | `/System/Volumes/Data/home` | automount |
| `/etc` | `/private/etc` | Symlink |
| `/tmp` | `/private/tmp` | Symlink |
| `/var` | `/private/var` | Symlink |

---

## /Users/alexa — Full Size Ranking

| # | Directory | Size | Category |
|---|-----------|------|----------|
| 1 | `.bitcoin-main/` | **89G** | Bitcoin full node blockchain data |
| 2 | `Library/` | 31G | macOS user library (caches, app support) |
| 3 | `BlackRoad-Private/` | 30G | Private repos & workspaces |
| 4 | `blackroad/` | 16G | BlackRoad platform code |
| 5 | `.git/` | 9.8G | Git repo in home dir itself |
| 6 | `.espressif/` | 7.0G | ESP-IDF toolchain (for ESP32 fleet) |
| 7 | `projects/` | 3.7G | Project workspaces |
| 8 | `Chit Chat Cadillac/` | 3.6G | — |
| 9 | `BlackRoad-Public/` | 3.6G | Public repos |
| 10 | `blackroad-internet/` | 3.4G | BlackRoad internet project |
| 11 | `.platformio/` | 2.9G | PlatformIO (MCU dev toolchain) |
| 12 | `esp-idf/` | 2.3G | ESP-IDF source |
| 13 | `.iso-venv/` | 1.5G | Python virtual environment |
| 14 | `services/` | 1.4G | Web services (Next.js, etc.) |
| 15 | `bouffalo_sdk/` | 1.4G | Bouffalo RISC-V SDK |
| 16 | `.copilot/` | 1.4G | GitHub Copilot data |
| 17 | `.blackroad/` | 1.4G | Memory system (156K+ entries) |
| 18 | `.rustup/` | 1.2G | Rust toolchains |
| 19 | `tools/` | 1.1G | Dev tools |
| 20 | `lucidia-enhanced/` | 1.1G | Lucidia platform |
| 21 | `.claude/` | 942M | Claude Code sessions |
| 22 | `codex-github-repos/` | 928M | Codex indexed repos |
| 23 | `SenseCAP-Watcher-Firmware/` | 808M | SenseCAP firmware source |
| 24 | `.local/` | 777M | User binaries (br, ai, ask, etc.) |
| 25 | `github-index/` | 751M | GitHub index cache |
| 26 | `br-os/` | 599M | BlackRoad OS build |
| 27 | `operator-watcher-firmware/` | 573M | Operator firmware |
| 28 | `actions-runner/` | 553M | GitHub Actions self-hosted runner |
| 29 | `ai/` | 532M | AI projects |
| 30 | `blackroad-web/` | 525M | Web frontend |
| 31 | `cloudflare-hello-world/` | 511M | Cloudflare project |
| 32 | `.zsh_sessions/` | 434M | Shell session history |
| 33 | `sensecap-watcher-sdk/` | 432M | SenseCAP SDK |
| 34 | `Pictures/` | 428M | Photos |
| 35 | `lucidia-platform/` | 401M | Lucidia platform |
| 36 | `.nuget/` | 401M | .NET packages |
| 37 | `.npm/` | 384M | npm cache |
| 38 | `Downloads/` | 375M | Downloads |
| 39 | `go/` | 364M | Go workspace |
| 40 | `blackroad-infra/` | 305M | This repo |

---

## Disk Usage Summary

```
Total Disk:                     460 GB
├── macOS System:                22 GB  (OS + Preboot + VM + Update)
├── /Applications:             ~120 GB  (Unity = 93G!)
├── /Library (system):            8 GB
├── /Users/alexa:              ~290 GB
│   ├── .bitcoin-main:          89 GB  ← Bitcoin full node
│   ├── Library/ (user):        31 GB
│   ├── BlackRoad-Private:      30 GB
│   ├── Scripts (.sh+.md):      19 GB  (2,048 files loose in ~/)
│   ├── blackroad/:             16 GB
│   ├── .git (home repo):      9.8 GB
│   ├── .espressif + esp-idf:  9.3 GB  (ESP32 toolchain)
│   ├── Dev SDKs:              ~8 GB  (platformio, bouffalo, nuget, rustup, cargo)
│   ├── Repos + projects:     ~20 GB
│   ├── AI/ML:                 ~3 GB  (.claude, .codex, .models, .copilot)
│   ├── .blackroad infra:      1.4 GB  (memory, journals, tasks)
│   └── Other:                ~53 GB
├── /Users/maggiecox:          ~small
├── /private:                    2 GB
└── Free:                      ~11 GB  (2.4%)
```

---

## Ownership Summary

| Owner | Scope | Notes |
|-------|-------|-------|
| `root:wheel` | `/`, `/System`, `/usr`, `/private`, `/Library` | macOS system |
| `root:admin` | `/Applications`, `.VolumeIcon.icns` | Apps installed by admin |
| `alexa:staff` | `/Users/alexa`, `/opt/blackroad` | All user data, BlackRoad infra |
| `alexa:admin` | `/opt/homebrew`, some `/usr/local` | Package management |
| `maggiecox:staff` | `/Users/maggiecox` | Secondary user |

---

## Critical Findings

1. **Disk 98% full (11GB free)** — two items consume 40%: Unity (93G) + Bitcoin node (89G).
2. **Bitcoin full node** — `.bitcoin-main/` at 89GB. Active blockchain sync.
3. **2,048 loose scripts/docs in home** — 1,026 .sh files (7.8G) and 1,022 .md files (10.9G) sitting directly in `~/`.
4. **3,920 top-level items in home** — extremely cluttered home directory.
5. **9.8GB .git in home** — the home directory itself is a git repo with a large history.
6. **9.3GB ESP32 toolchain** — `.espressif/` + `esp-idf/` for microcontroller development.
7. **3 copies of Arc Browser** — 2.4G wasted on duplicates.
8. **`/opt/blackroad` is empty scaffolding** — directories created but nothing deployed.
9. **`/blackroad` symlink exists** — root-level mount point for BlackRoad (empty).
10. **SenseCAP firmware sources** — 808M + 573M + 432M = 1.8G (device was returned Aug 2025).

### Space Recovery Options

| Action | Space Freed | Risk |
|--------|-------------|------|
| Remove Unity + projects | ~97G | None if not using Unity |
| Prune Bitcoin node (switch to pruned mode) | ~70G | Keeps recent blocks only |
| Remove duplicate Arc browsers (keep 1) | ~1.6G | None |
| Remove SenseCAP firmware sources | ~1.8G | Device was returned |
| Clear ~/Library/Caches | ~883M | Regenerated on demand |
| Remove unused Microsoft apps | ~10G+ | If not using Office |
| Clean `.zsh_sessions/` | ~434M | Old shell history |
| `brew cleanup` | Variable | None |
