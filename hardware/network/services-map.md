# Services Map

Which services run on which device, and on which ports.

---

## Service-to-Device Matrix

| Service | Port | Node(s) | Protocol | Notes |
|---------|------|---------|----------|-------|
| NATS | 4222 | Lucidia | TCP | Central event bus |
| Ollama | 11434 | Lucidia, Cecilia | HTTP | LLM inference |
| Hailo Runtime | — | Cecilia, Octavia, Aria | Local | AI accelerator driver |
| CECE OS | 8080+ | Cecilia | HTTP | 68 sovereign apps |
| PowerDNS | 53 | Octavia | TCP/UDP | Internal DNS |
| PowerDNS-Admin | 8080 | Octavia | HTTP | DNS management UI |
| RoadAuth | — | Octavia | HTTP | Authentication service |
| RoadAPI | — | Octavia | HTTP | API gateway |
| Auth-Gateway | — | Octavia | HTTP | Auth proxy |
| Cloudflared | — | Cecilia, Lucidia, Octavia, Codex-Infinity, Shellfish | — | Cloudflare tunnel agent |
| Edge-Agent | — | Lucidia, Shellfish | — | Edge compute agent |
| Worker | — | Alice | — | Task worker |
| Codex-DB | — | Codex-Infinity | SQLite | Component index |
| Cloud-Services | — | Codex-Infinity | — | Cloud oracle |
| MQTT (planned) | 1883 | Pi-Ops (planned) | TCP | IoT pub/sub broker |

---

## Per-Node Service List

### Cecilia (192.168.4.89)
- Ollama (LLM inference)
- CECE OS (68 sovereign apps)
- Hailo runtime (26 TOPS accelerator)
- Cloudflared tunnel

### Lucidia (192.168.4.81)
- NATS event bus (port 4222)
- Ollama (LLM inference, port 11434)
- Edge-agent
- Cloudflared tunnel

### Octavia (192.168.4.38)
- Hailo runtime (26 TOPS accelerator)
- PowerDNS (port 53)
- PowerDNS-Admin (port 8080)
- RoadAuth
- RoadAPI
- Auth-Gateway
- Cloudflared tunnel

### Aria (192.168.4.82)
- Hailo runtime (26 TOPS accelerator)
- Compute workloads (9 containers)

### Alice (192.168.4.49)
- Worker node (7 containers)

### Anastasia (192.168.4.33)
- (Pending service deployment)

### Cordelia (192.168.4.27)
- (Pending service deployment)

### Codex-Infinity (159.65.43.12)
- Codex database
- Cloud services
- Cloudflared tunnel

### Shellfish (174.138.44.45)
- Cloudflare tunnels
- Edge-agent

---

## Service Dependencies

```
                    ┌───────────┐
                    │   NATS    │
                    │ (Lucidia) │
                    └─────┬─────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
   ┌──────┴──────┐ ┌─────┴─────┐ ┌──────┴──────┐
   │   Ollama    │ │ Edge-Agent │ │  CECE OS    │
   │(Lucidia/Cec)│ │(Lucidia)   │ │ (Cecilia)   │
   └─────────────┘ └───────────┘ └─────────────┘
                                        │
                                  ┌─────┴─────┐
                                  │  Hailo RT  │
                                  │(Cec/Oct/Ar)│
                                  └───────────┘

   ┌───────────┐        ┌───────────┐
   │ PowerDNS  │        │ Auth-GW   │
   │ (Octavia) │◄───────│ (Octavia) │
   └───────────┘        └───────────┘

   ┌────────────────┐
   │  Cloudflared   │ ← All production nodes
   │  (5 tunnels)   │
   └────────────────┘
```

---

## Planned Services

| Service | Port | Target Node | Purpose |
|---------|------|-------------|---------|
| Mosquitto MQTT | 1883 | Pi-Ops | IoT sensor pub/sub |
| Headscale | 443 | Alice | Self-hosted Tailscale control |
| Monitoring Dashboard | 3000 | Pi-Ops | Grafana/custom dashboard |
| Agent UI | 8080 | Jetson-Agent | Touch-based agent control |
