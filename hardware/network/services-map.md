# Services Map — Live Verified

**Verified via `ss -tlnp` SSH probes on 2026-02-21.**

---

## Cecilia (192.168.4.89) — 16+ services

| Port | Service | Bind | Process |
|------|---------|------|---------|
| 22 | SSH | 0.0.0.0 | sshd |
| 53 | DNS | 0.0.0.0 | (resolver) |
| 80 | HTTP | 0.0.0.0 | nginx/caddy |
| 631 | CUPS (printing) | 127.0.0.1 | cupsd |
| 3001 | App (dashboard?) | 0.0.0.0 | python3 |
| 3100 | Loki/log aggregator | 0.0.0.0 | — |
| 5001 | Python service | 0.0.0.0 | python3 |
| 5002 | Python service | 0.0.0.0 | python3 |
| 5432 | **PostgreSQL** | 127.0.0.1 | postgres |
| 5900 | **VNC** | 0.0.0.0 | vnc |
| 8086 | **InfluxDB** | 0.0.0.0 | influxd |
| 8787 | Python service | 0.0.0.0 | python3 |
| 9000 | **MinIO** (S3) | 0.0.0.0 + [::] | minio |
| 9001 | **MinIO Console** | 0.0.0.0 | minio |
| 9100 | **Node Exporter** (Prometheus) | 0.0.0.0 | python3 |
| 11434 | **Ollama** | 127.0.0.1 | ollama |
| 34001 | Tailscale relay | 0.0.0.0 | tailscaled |

**Systemd services:** hailort, ollama, cloudflared, docker

**Infrastructure stack:** PostgreSQL + InfluxDB + MinIO + Loki + Node Exporter = full observability

---

## Octavia (192.168.4.38) — 30+ services (OVERLOADED)

| Port Range | Service | Bind | Process |
|------------|---------|------|---------|
| 3002-3006 | App services (5 ports) | 0.0.0.0 | containers |
| 3109 | App service | 0.0.0.0 | — |
| 4001-4002 | App services | 0.0.0.0 | — |
| 4010 | App service | 127.0.0.1 | — |
| 5200 | Python microservice | 0.0.0.0 | python3 |
| 5300 | Python microservice | 0.0.0.0 | python3 |
| 5400 | Python microservice | 0.0.0.0 | python3 |
| 5500 | Python microservice | 0.0.0.0 | python3 |
| 5600 | Python microservice | 0.0.0.0 | python3 |
| 5900 | Python microservice | 0.0.0.0 | python3 |
| 6000 | Python microservice | 0.0.0.0 | python3 |
| 6100 | Python microservice | 0.0.0.0 | python3 |
| 6200 | Python microservice | 0.0.0.0 | python3 |
| 6300 | Python microservice | 0.0.0.0 | python3 |
| 8000 | API (uvicorn/gunicorn) | 0.0.0.0 | — |
| 8011 | Python service | 0.0.0.0 | — |
| 8080-8082 | HTTP services | 0.0.0.0 | — |
| 8180 | Python service | 0.0.0.0 | — |
| 5432 | PostgreSQL | 127.0.0.1 | postgres |
| 11434 | Ollama | 127.0.0.1 | ollama |
| 34001 | Tailscale relay | 0.0.0.0 | tailscaled |

**Systemd services:** ollama, ollama-bridge, cloudflared, docker

> **WARNING:** 30+ listening ports, load average 9.47, RAM 6.6/7.9GB.
> This node needs service migration or hardware upgrade.

---

## Aria (192.168.4.82) — 30+ services

| Port Range | Service | Bind |
|------------|---------|------|
| 3140-3167 | **28 Docker container ports** | 0.0.0.0 |
| 8081 | HTTP service | 0.0.0.0 |
| 8180 | Python service | 0.0.0.0 |

**Systemd services:** ollama, cloudflared, docker

> 28 container ports in 3140-3167 range. Disk 74% full — monitor closely.

---

## Alice (192.168.4.49) — Minimal

| Port | Service |
|------|---------|
| 22 | SSH |

**Systemd services:** cloudflared, docker

> Light node. Load 6.17 is concerning for 4-core Pi 400 — investigate docker workloads.

---

## Shellfish / "anastasia" (174.138.44.45) — 14+ services

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

---

## Codex-Infinity / "gematria" (159.65.43.12) — 7 services

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

**Systemd services:** cloudflared, nginx, ollama

> **SECURITY NOTE:** Ollama is bound to `*:11434` (all interfaces) on this public-facing droplet.
> Consider restricting to localhost or Tailscale interface only.

---

## Service Distribution Summary

| Service | Cecilia | Octavia | Aria | Alice | Shellfish | Codex-Inf |
|---------|---------|---------|------|-------|-----------|-----------|
| SSH | 22 | 22 | 22 | 22 | 22 | 22 |
| HTTP | 80 | 8000+ | — | — | 80 | 80 |
| HTTPS | — | — | — | — | — | 443 |
| Ollama | 11434 (lo) | 11434 (lo) | ✓ | — | 11434 (TS) | 11434 (**PUBLIC**) |
| PostgreSQL | 5432 | 5432 | — | — | — | — |
| Docker | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| Cloudflared | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Hailo | ✓ | — | — | — | — | — |
| MinIO | 9000 | — | — | — | — | — |
| InfluxDB | 8086 | — | — | — | — | — |
| nginx | — | — | — | — | ✓ | ✓ |

### Ollama Deployment (4 nodes!)

Ollama runs on 4 of 6 reachable nodes:
1. **Cecilia** — localhost only (secure)
2. **Octavia** — localhost only (secure) + SSE bridge
3. **Shellfish** — Tailscale interface only (secure)
4. **Codex-Infinity** — **ALL INTERFACES** (security risk on public IP)

---

## Service Dependencies

```
                    ┌───────────┐
                    │   NATS    │
                    │ (Lucidia) │  ← DOWN
                    └─────┬─────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
   ┌──────┴──────┐ ┌─────┴─────┐ ┌──────┴──────┐
   │   Ollama    │ │ Observ.   │ │  CECE OS    │
   │ (4 nodes)  │ │ Stack     │ │ (Cecilia)   │
   └─────────────┘ │(Cecilia)  │ └─────────────┘
                    │InfluxDB  │
                    │Loki      │
                    │MinIO     │
                    │NodeExport│
                    └──────────┘

   ┌───────────┐        ┌───────────┐
   │ PostgreSQL│        │ Hailo RT  │
   │(Cec + Oct)│        │(Cecilia)  │  ← Only 1 confirmed
   └───────────┘        └───────────┘

   ┌────────────────┐
   │  Cloudflared   │ ← 5 nodes (all except Alice has tunnel)
   │  (5 tunnels)   │
   └────────────────┘
```
