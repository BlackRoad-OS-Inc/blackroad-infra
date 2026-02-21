# Cloud Compute

**2 DigitalOcean droplets** providing cloud presence and edge compute.

---

## Fleet Overview

| Node | Region | Spec | Public IP | Tailscale IP | Storage | Role | Status |
|------|--------|------|-----------|--------------|---------|------|--------|
| Codex-Infinity | NYC | 1 vCPU / 1GB | 159.65.43.12 | 100.108.132.8 | 78GB SSD | Codex server, oracle | Active |
| Shellfish | NYC | 1 vCPU / 1GB | 174.138.44.45 | 100.94.33.37 | 25GB SSD | Edge compute, tunnels | Active |

---

## Per-Node Details

### Codex-Infinity — Codex Server / Oracle

- **Role:** Codex database host, cloud services oracle
- **Provider:** DigitalOcean
- **Region:** NYC
- **Spec:** 1 vCPU, 1GB RAM, 78GB SSD
- **OS:** Debian 12 (Bookworm), Kernel 5.15 LTS
- **Public IP:** 159.65.43.12
- **Tailscale IP:** 100.108.132.8
- **Services:** codex-db, cloud-services
- **Tunnel:** tunnel-codex.blackroad.io
- **SSH:** `ssh codex-infinity` or `ssh 159.65.43.12`
- **User:** alexandria

### Shellfish — Edge Compute

- **Role:** Cloud edge node, Cloudflare tunnel relay
- **Provider:** DigitalOcean
- **Region:** NYC
- **Spec:** 1 vCPU, 1GB RAM, 25GB SSD
- **OS:** Debian 12 (Bookworm), Kernel 5.15 LTS
- **Public IP:** 174.138.44.45
- **Tailscale IP:** 100.94.33.37
- **Services:** Cloudflare tunnels, edge-agent
- **Tunnel:** tunnel-cadence.blackroad.io
- **SSH:** `ssh shellfish` or `ssh 174.138.44.45`
- **User:** alexandria

---

## Security Baseline

Both droplets follow the standard BlackRoad OS baseline:

- SSH key-only authentication (no passwords)
- UFW firewall: deny by default, allow 22/80/443/41641
- fail2ban enabled
- unattended-upgrades enabled
- chrony time sync to time.cloudflare.com
- Tailscale mesh connected

## Management

```bash
ssh codex-infinity       # Direct SSH
ssh shellfish            # Direct SSH
doctl compute droplet list   # DigitalOcean CLI (if installed)
```
