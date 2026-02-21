# Cloud Compute — Live Verified

**2 DigitalOcean droplets** providing cloud presence and edge compute.

**Verified via SSH probes on 2026-02-21.**

---

## Fleet Overview

| Node | Hostname | Region | Spec | Public IP | Tailscale IP | Storage | Role | Status |
|------|----------|--------|------|-----------|--------------|---------|------|--------|
| Codex-Infinity | **gematria** | NYC | 1 vCPU / 1GB | 159.65.43.12 | 100.108.132.8 | 78GB SSD | Codex server | Active |
| Shellfish | **anastasia** | NYC | 1 vCPU / 1GB | 174.138.44.45 | 100.94.33.37 | 25GB SSD | Edge compute | Active |

### ERRATA vs Prior Documentation

| Item | Previously Documented | Live Verified |
|------|----------------------|---------------|
| Codex-Infinity hostname | "codex-infinity" | **gematria** |
| Shellfish hostname | "shellfish" | **anastasia** (naming collision with Pi!) |
| SSH user | `alexandria` | **`blackroad`** |
| Codex-Infinity OS | Debian 12, Kernel 5.15 | **CentOS Stream 9**, Kernel 6.12.10-200 |
| Shellfish OS | Debian 12, Kernel 5.15 | **Debian 12 (Bookworm)**, Kernel 6.1.0-28-amd64 |

> **NAMING COLLISION:** The Shellfish droplet's actual hostname is `anastasia`, which collides with
> the Anastasia Pi at 192.168.4.33. The SSH alias `anastasia` in `~/.ssh/config` points to the
> droplet (174.138.44.45), NOT the Pi. Consider renaming the droplet hostname to `shellfish` or
> `cadence` to eliminate confusion.

---

## Per-Node Details

### Codex-Infinity (hostname: gematria) — Cloud Oracle

- **Role:** Codex database host, cloud services, HTTP/HTTPS gateway
- **Provider:** DigitalOcean
- **Region:** NYC
- **Spec:** 1 vCPU, 1GB RAM, 78GB SSD
- **OS:** CentOS Stream 9, Kernel 6.12.10-200.fc41.x86_64
- **Public IP:** 159.65.43.12
- **Tailscale IP:** 100.108.132.8
- **SSH:** `ssh gematria` or `ssh gematria-ts` (user: `blackroad`)
- **Tunnel:** tunnel-codex.blackroad.io (cloudflared running)
- **SSH Aliases:** `gematria`, `gematria-ts`, `blackroad-os-ts`

**Verified Services (7 listening ports):**

| Port | Service | Process |
|------|---------|---------|
| 22 | SSH | sshd |
| 53 | DNS (local resolver) | systemd-resolved |
| 80 | HTTP | nginx |
| 443 | HTTPS | nginx |
| 2019 | Caddy admin | caddy |
| 8011 | App service | — |
| 8787 | Python service | python3 |
| 11434 | **Ollama (PUBLIC!)** | ollama |

> **SECURITY WARNING:** Ollama is bound to `*:11434` (all interfaces) on this public-facing droplet.
> Anyone on the internet can access the Ollama API at `159.65.43.12:11434`.
> **Immediate action:** Restrict to localhost or Tailscale interface only.
>
> ```bash
> # Fix: edit /etc/systemd/system/ollama.service
> # Change OLLAMA_HOST to 127.0.0.1:11434
> ssh gematria "sudo sed -i 's/OLLAMA_HOST=.*/OLLAMA_HOST=127.0.0.1/' /etc/systemd/system/ollama.service"
> ssh gematria "sudo systemctl daemon-reload && sudo systemctl restart ollama"
> ```

---

### Shellfish (hostname: anastasia) — Edge Compute

- **Role:** Cloud edge node, dashboards, API services, WebSocket servers
- **Provider:** DigitalOcean
- **Region:** NYC
- **Spec:** 1 vCPU, 1GB RAM, 25GB SSD
- **OS:** Debian 12 (Bookworm), Kernel 6.1.0-28-amd64
- **Public IP:** 174.138.44.45
- **Tailscale IP:** 100.94.33.37
- **SSH:** `ssh shellfish` or `ssh anastasia` or `ssh anastasia-ts` (user: `blackroad`)
- **Tunnel:** tunnel-cadence.blackroad.io (cloudflared running)
- **SSH Aliases:** `shellfish`, `anastasia`, `anastasia-ts`, `cadence-ts`

**Verified Services (14+ listening ports):**

| Port | Service | Process |
|------|---------|---------|
| 22 | SSH | sshd |
| 80 | HTTP | nginx |
| 3000 | Dashboard (Grafana?) | node |
| 3001 | Dashboard | node |
| 6379 | Redis-like | python3 |
| 8000 | API | uvicorn |
| 8080 | HTTP service | — |
| 8765 | WebSocket server | python3 |
| 8766 | WebSocket server | python3 |
| 8787 | Python service | python3 |
| 8888 | Python service | python3 |
| 11434 | Ollama | ollama (Tailscale-only: 100.64.0.1) |

**Systemd services:** cloudflared, docker, nginx, ollama

> **NOTE:** Ollama on Shellfish is bound to Tailscale interface only (100.64.0.1) — secure.

---

## Security Baseline

Both droplets should follow the standard BlackRoad OS baseline:

| Control | Codex-Infinity | Shellfish | Status |
|---------|---------------|-----------|--------|
| SSH key-only auth | Yes | Yes | OK |
| Firewall (UFW/firewalld) | Unknown (CentOS) | UFW | Verify |
| fail2ban | Unknown | Enabled | Verify |
| unattended-upgrades | N/A (CentOS = dnf-automatic) | Enabled | Verify |
| Ollama binding | **PUBLIC (insecure!)** | Tailscale-only | **FIX** |

### Firewall Action Items

```bash
# Codex-Infinity (CentOS) — check firewalld
ssh gematria "sudo firewall-cmd --list-all"

# Shellfish (Debian) — check ufw
ssh shellfish "sudo ufw status verbose"
```

---

## Management

```bash
# SSH access
ssh gematria              # Codex-Infinity via direct IP
ssh gematria-ts           # Codex-Infinity via Tailscale
ssh shellfish             # Shellfish via direct IP
ssh anastasia-ts          # Shellfish via Tailscale

# DigitalOcean CLI
doctl compute droplet list   # List all droplets (if doctl installed)

# Cloudflare tunnel status
ssh gematria "systemctl status cloudflared"
ssh shellfish "systemctl status cloudflared"
```
