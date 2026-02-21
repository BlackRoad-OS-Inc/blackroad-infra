# Network Topology

BlackRoad fleet network architecture — LAN, Tailscale mesh, cloud entry points.

---

## Physical LAN (192.168.4.0/24)

### Network Equipment

| Device | Model | Ports | Role |
|--------|-------|-------|------|
| Router/WiFi | TP-Link | — | Gateway (192.168.4.1), DHCP, WiFi |
| Switch | TP-Link TL-SG105 | 5-port Gigabit | Wired backbone |
| WiFi Card | TP-Link AX3000 PCIe WiFi 6 | — | High-speed wireless |

### Topology Diagram

```
                    ┌─────────────────────┐
                    │     INTERNET         │
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    │   TP-Link Router    │
                    │   192.168.4.1       │
                    │   DHCP / WiFi / NAT │
                    └──────────┬──────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                   │
     ┌──────┴──────┐   ┌──────┴──────┐   WiFi Clients
     │  TL-SG105   │   │  WiFi AP    │
     │  Gigabit SW │   │  (built-in) │
     └┬───┬───┬───┬┘   └─────────────┘
      │   │   │   │
      │   │   │   └── Cecilia   .89  [Hailo-8, CECE OS]
      │   │   └────── Lucidia   .81  [NATS, Ollama]
      │   └────────── Aria      .82  [Hailo-8, API]
      └────────────── Octavia   .38  [Hailo-8, DNS]

     WiFi:
      ├── Alexandria  .28  [MacBook Pro M1]
      ├── Alice       .49  [Pi 400]
      ├── Anastasia   .33  [Pi 5]
      ├── Cordelia    .27  [Pi 5]
      ├── Athena      .45  [Heltec LoRa ESP32]
      ├── Phoebe      .88  [iPhone]
      ├── Ares        .90  [Xbox]
      └── Iris        .26  [Roku]
```

### IP Address Map

| IP | Hostname | Type | Wired/WiFi |
|----|----------|------|------------|
| .1 | Router | TP-Link Gateway | — |
| .26 | Iris | Roku | WiFi |
| .27 | Cordelia | Pi 5 | WiFi |
| .28 | Alexandria | MacBook Pro M1 | WiFi |
| .33 | Anastasia | Pi 5 | WiFi |
| .38 | Octavia | Pi 5 | Wired |
| .45 | Athena | Heltec LoRa ESP32 | WiFi |
| .49 | Alice | Pi 400 | WiFi |
| .81 | Lucidia | Pi 5 | Wired |
| .82 | Aria | Pi 5 | Wired |
| .88 | Phoebe | iPhone | WiFi |
| .89 | Cecilia | Pi 5 | Wired |
| .90 | Ares | Xbox | WiFi |

---

## Tailscale Mesh Overlay

Encrypted WireGuard mesh connecting on-premises and cloud nodes.

```
                    ┌───────────────┐
                    │  Tailscale    │
                    │  Control Plane│
                    └───────┬───────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                    │
   On-Premises         Cloud                 Cloud
   ┌─────────┐    ┌──────────────┐    ┌──────────────┐
   │ Cecilia  │    │Codex-Infinity│    │  Shellfish   │
   │ 100.72.  │    │ 100.108.     │    │ 100.94.      │
   │ 180.98   │    │ 132.8        │    │ 33.37        │
   └────┬─────┘    └──────────────┘    └──────────────┘
        │
   ┌────┼────┬────────┬─────────┐
   │    │    │        │         │
 Lucidia │  Aria   Octavia   Alice
 100.66  │  100.109 100.83   100.77
 .235.47 │  .14.17  .149.86  .210.18
         │
   (Full mesh — every
    node can reach
    every other node)
```

### Tailscale Node Table

| Node | Tailscale IP | OS | Connected |
|------|-------------|-----|-----------|
| Cecilia | 100.72.180.98 | Linux | Yes |
| Lucidia | 100.66.235.47 | Linux | Yes |
| Octavia | 100.83.149.86 | Linux | Yes |
| Aria | 100.109.14.17 | Linux | Yes |
| Alice | 100.77.210.18 | Linux | Yes |
| Codex-Infinity | 100.108.132.8 | Linux | Yes |
| Shellfish | 100.94.33.37 | Linux | Yes |

### SSH via Tailscale

```bash
ssh cecilia-ts     # → 100.72.180.98
ssh lucidia-ts     # → 100.66.235.47
ssh octavia-ts     # → 100.83.149.86
ssh aria-ts        # → 100.109.14.17
ssh alice-ts       # → 100.77.210.18
```

### Nodes Not Yet on Tailscale

- Anastasia (192.168.4.33)
- Cordelia (192.168.4.27)
- Olympia (offline)
- Jetson-Agent (pending setup)
- Pi-Holo, Pi-Ops, Pi-Zero-Sim (planned)

---

## Cloud Entry Points

### Cloudflare Tunnels

Each production node has a Cloudflare tunnel for HTTPS ingress:

| Tunnel | Node | Config |
|--------|------|--------|
| tunnel-cecilia.blackroad.io | Cecilia | /etc/cloudflared/config.yml |
| tunnel-lucidia.blackroad.io | Lucidia | /etc/cloudflared/config.yml |
| tunnel-octavia.blackroad.io | Octavia | /etc/cloudflared/config.yml |
| tunnel-codex.blackroad.io | Codex-Infinity | /etc/cloudflared/config.yml |
| tunnel-cadence.blackroad.io | Shellfish | /etc/cloudflared/config.yml |

### DNS

- **Provider:** Cloudflare
- **Zone:** blackroad.io
- **Internal DNS:** PowerDNS on Octavia
- **Time Sync:** chrony → time.cloudflare.com (all nodes)

---

## LoRa Network (Planned)

Athena (Heltec WiFi LoRa 32) serves as the LoRa mesh backbone:

- **Frequency:** 868/915 MHz
- **Range:** Up to 10km line-of-sight
- **Protocol:** LoRaWAN or point-to-point
- **Use Cases:** Remote sensor relay, out-of-WiFi-range monitoring
- **Management:** `~/lora.sh`

---

## Firewall Rules (All Nodes)

| Port | Protocol | Service | Direction |
|------|----------|---------|-----------|
| 22 | TCP | SSH | Inbound |
| 80 | TCP | HTTP | Inbound |
| 443 | TCP | HTTPS | Inbound |
| 41641 | UDP | Tailscale | Inbound |

Default policy: **deny** all other inbound traffic.

---

## Network Diagnostics

```bash
~/blackroad-network-scan.sh        # ARP + ping sweep + Tailscale status
~/blackroad-network-discovery.sh   # SSH probe all known devices
tailscale status                   # Tailscale mesh state
tailscale ping <hostname>          # Test Tailscale connectivity
```
