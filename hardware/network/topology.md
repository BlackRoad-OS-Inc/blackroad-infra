# Network Topology — Live Verified

**Verified against ARP table, ping sweep, SSH probes, and DNS dig on 2026-02-21.**

---

## Physical LAN (192.168.4.0/24)

### Network Equipment

| Device | Model | MAC | Role |
|--------|-------|-----|------|
| Router/WiFi | TP-Link | 44:ac:85:94:37:92 | Gateway (192.168.4.1), DHCP, WiFi |
| Switch | TP-Link TL-SG105 | — | 5-port Gigabit wired backbone |
| Unknown TP-Link | TP-Link | 98:17:3c:38:db:78 | 192.168.4.44 — extender/smart plug? |

### Live ARP Map (2026-02-21)

```
                       ┌─────────────────────┐
                       │     INTERNET         │
                       └──────────┬──────────┘
                                  │
                       ┌──────────┴──────────┐
                       │   TP-Link Router    │
                       │   192.168.4.1       │
                       │   44:ac:85:94:37:92 │
                       └──────────┬──────────┘
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                     │
      ┌──────┴──────┐     ┌──────┴──────┐       WiFi Clients
      │  TL-SG105   │     │  WiFi AP    │       (see below)
      │  Gigabit SW │     │  (built-in) │
      └┬───┬───┬───┬┘     └─────────────┘
       │   │   │   │
       │   │   │   └── Cecilia   .89  88:a2:9e:3b:eb:72  [UP]  Hailo-8
       │   │   └────── Octavia   .38  2c:cf:67:cf:fa:17  [UP]  OVERLOADED
       │   └────────── Aria      .82  88:a2:9e:0d:42:07  [UP]
       └────────────── Lucidia   .81  (incomplete)        [DOWN]

      WiFi:
       ├── Alexandria  .28  b0:be:83:66:cc:10  [UP]   Apple Mac
       ├── Alice       .49  d8:3a:dd:ff:98:87  [UP]   Pi 400
       ├── Anastasia   .33  60:92:c8:11:cf:7c  [UP]   Pi 5 (no SSH)
       ├── Cordelia    .27  6c:4a:85:32:ae:72  [UP]   Pi 5 (no SSH)
       ├── Athena      .45  d0:c9:07:50:51:ca  [UP]   ESP32 LoRa
       ├── Iris        .26  d4:be:dc:6c:61:6b  [UP]   Roku
       ├── Ares        .90  a0:4a:5e:2a:db:d2  [DOWN] Xbox
       ├── Phoebe      .88  9e:0d:2a:82:99:96  [DOWN] iPhone (private MAC)
       │
       ├── UNKNOWN     .22  30:be:29:5b:24:5f  [UP]   Smart TV/IoT?
       ├── UNKNOWN     .44  98:17:3c:38:db:78  [UP]   TP-Link device
       ├── UNKNOWN     .83  54:4c:8a:9b:09:3d  [UP]   Smart home module?
       └── UNKNOWN     .92  de:a2:b7:f3:f9:5d  [DOWN] Apple (private MAC)
```

### Complete IP-to-MAC-to-Identity Table

| IP | MAC | OUI Vendor | Identity | Ping | SSH |
|----|-----|-----------|----------|------|-----|
| .1 | 44:ac:85:94:37:92 | TP-Link | Router | UP | — |
| .22 | 30:be:29:5b:24:5f | Unknown | **UNIDENTIFIED** | UP | — |
| .26 | d4:be:dc:6c:61:6b | Roku | Iris (streaming) | UP | — |
| .27 | 6c:4a:85:32:ae:72 | Raspberry Pi 5 | Cordelia | UP | REFUSED |
| .28 | b0:be:83:66:cc:10 | Apple | Alexandria (Mac M1) | UP | — |
| .33 | 60:92:c8:11:cf:7c | Raspberry Pi 5 | Anastasia (Pi) | UP | REFUSED |
| .38 | 2c:cf:67:cf:fa:17 | Raspberry Pi | Octavia | UP | OK |
| .44 | 98:17:3c:38:db:78 | TP-Link | **UNIDENTIFIED** | UP | — |
| .45 | d0:c9:07:50:51:ca | Espressif | Athena (ESP32 LoRa) | UP | — |
| .49 | d8:3a:dd:ff:98:87 | Raspberry Pi | Alice (Pi 400) | UP | OK |
| .74 | (incomplete) | — | **STALE** (old Octavia IP) | DOWN | — |
| .81 | (incomplete) | — | Lucidia (Pi 5) | **DOWN** | — |
| .82 | 88:a2:9e:0d:42:07 | Raspberry Pi 5 | Aria | UP | OK |
| .83 | 54:4c:8a:9b:09:3d | Unknown | **UNIDENTIFIED** | UP | — |
| .88 | 9e:0d:2a:82:99:96 | Private MAC | Phoebe (iPhone) | DOWN | — |
| .89 | 88:a2:9e:3b:eb:72 | Raspberry Pi 5 | Cecilia | UP | OK |
| .90 | a0:4a:5e:2a:db:d2 | Microsoft | Ares (Xbox) | DOWN | — |
| .92 | de:a2:b7:f3:f9:5d | Private MAC | **UNIDENTIFIED** | DOWN | — |

---

## WireGuard Mesh (Replaced Tailscale 2026-02-21)

> **Tailscale removed fleet-wide on 2026-02-21.** Replaced with raw WireGuard.
> Reason: `tailscaled` userspace daemon had recurring 190% CPU bug on Alice (Pi 4).
> WireGuard runs in-kernel on Linux = near-zero CPU overhead.

### Architecture: Hub-and-Spoke via Shellfish

```
                    ┌───────────────────┐
                    │     INTERNET      │
                    └────────┬──────────┘
                             │
                    ┌────────┴──────────┐
                    │  Shellfish (HUB)  │
                    │  174.138.44.45    │
                    │  10.8.0.1/24      │
                    │  Port 51820/UDP   │
                    │  IP forwarding ON │
                    └────────┬──────────┘
                             │
       ┌──────────┬──────────┼──────────┬──────────┐
       │          │          │          │          │
  ┌────┴────┐┌────┴────┐┌────┴────┐┌────┴────┐┌────┴────┐
  │Cecilia  ││Lucidia  ││ Alice   ││  Aria   ││Infinity │
  │10.8.0.3 ││10.8.0.4 ││10.8.0.6 ││10.8.0.7 ││10.8.0.8 │
  │  .89    ││  .81    ││  .49    ││  .82    ││159.65.  │
  └─────────┘└─────────┘└─────────┘└─────────┘│ 43.12   │
                                               └─────────┘
  PENDING:
  ┌─────────┐┌─────────┐
  │Mac      ││Octavia  │
  │10.8.0.2 ││10.8.0.5 │
  │(sudo)   ││(SSH key)│
  └─────────┘└─────────┘
```

### WireGuard IP Assignments (10.8.0.0/24)

| Node | WG IP | Local IP | Role | Status | Auto-start |
|------|-------|----------|------|--------|------------|
| Shellfish | 10.8.0.1 | 174.138.44.45 | **HUB** (forwarding + NAT) | Active, handshaking | `systemctl enable wg-quick@wg0` |
| Alexandria | 10.8.0.2 | 192.168.4.28 | Client | **Pending** (needs `sudo wg-quick up`) | Config at `~/.wireguard/wg0.conf` |
| Cecilia | 10.8.0.3 | 192.168.4.89 | Client | Active, handshaking | `systemctl enable wg-quick@wg0` |
| Lucidia | 10.8.0.4 | 192.168.4.81 | Client | Active, handshaking | `systemctl enable wg-quick@wg0` |
| Octavia | 10.8.0.5 | 192.168.4.38 | Client | **Pending** (no SSH key for sudo user) | Config at `/tmp/wg-keys/wg0-octavia.conf` |
| Alice | 10.8.0.6 | 192.168.4.49 | Client | Active, handshaking | `systemctl enable wg-quick@wg0` |
| Aria | 10.8.0.7 | 192.168.4.82 | Client | Active, handshaking | `systemctl enable wg-quick@wg0` |
| Infinity | 10.8.0.8 | 159.65.43.12 | Client | Active, handshaking | `systemctl enable wg-quick@wg0` |

### Hub Configuration (Shellfish)

- **Firewall:** Port 51820/UDP opened via `firewall-cmd` (CentOS)
- **IP Forwarding:** `net.ipv4.ip_forward=1` in `/etc/sysctl.d/99-wireguard.conf`
- **NAT:** `iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`
- **Config:** `/etc/wireguard/wg0.conf`

### SSH Access for WireGuard Admin

| Node | SSH User | Sudo | How |
|------|----------|------|-----|
| Alice | `alice` | NOPASSWD | `ssh alice@192.168.4.49` |
| Cecilia | `cecilia` | NOPASSWD | `ssh cecilia@192.168.4.89` |
| Lucidia | `lucidia` | NOPASSWD | `ssh lucidia@192.168.4.81` |
| Aria | `aria` | NOPASSWD | `ssh aria@192.168.4.82` |
| Octavia | `blackroad` | Needs password | **Blocked** — `octavia` user has NOPASSWD but no SSH key |
| Shellfish | `root` | — | `ssh root@174.138.44.45` |
| Infinity | `root` | — | `ssh root@159.65.43.12` |

### Tailscale (DEPRECATED — Disabled 2026-02-21)

Tailscale has been `systemctl stop && disable` on all devices. Former IPs for reference only:

| Node | Former Tailscale IP |
|------|-------------------|
| Cecilia | 100.72.180.98 |
| Octavia | 100.66.235.47 |
| Lucidia | 100.83.149.86 |
| Aria | 100.109.14.17 |
| Alice | 100.77.210.18 |
| Codex-Infinity | 100.108.132.8 |
| Shellfish | 100.94.33.37 |

### Not on WireGuard (yet)

- Anastasia Pi (192.168.4.33) — SSH closed, can't configure
- Cordelia (192.168.4.27) — SSH closed, can't configure
- Olympia — offline

---

## Cloud Entry Points — Cloudflare

### DNS Resolution (all Cloudflare-proxied)

All blackroad.io DNS resolves to Cloudflare CDN, not origin servers directly:

| Subdomain | A Record |
|-----------|----------|
| blackroad.io | 172.67.211.99 |
| www.blackroad.io | 172.67.211.99 |
| api.blackroad.io | 172.67.211.99 |
| status.blackroad.io | 172.67.211.99 |
| docs.blackroad.io | 172.67.211.99 |
| dashboard.blackroad.io | 172.67.211.99 |
| monitoring.blackroad.io | 172.67.211.99 |
| agents.blackroad.io | 104.21.91.74 |
| tunnel-cecilia.blackroad.io | 172.67.211.99 |
| tunnel-lucidia.blackroad.io | 104.21.91.74 |
| tunnel-octavia.blackroad.io | 172.67.211.99 |
| tunnel-codex.blackroad.io | 104.21.91.74 |
| tunnel-cadence.blackroad.io | 172.67.211.99 |

**Traffic flow:** Client → Cloudflare CDN → Cloudflare Tunnel → `cloudflared` on origin node

### Cloudflare Tunnels (verified via `cloudflared.service`)

| Tunnel | Origin Node | cloudflared Status |
|--------|-------------|-------------------|
| tunnel-cecilia.blackroad.io | Cecilia (192.168.4.89) | Running |
| tunnel-lucidia.blackroad.io | Lucidia (192.168.4.81) | **DOWN** (node unreachable) |
| tunnel-octavia.blackroad.io | Octavia (192.168.4.38) | Running |
| tunnel-codex.blackroad.io | Codex-Infinity (159.65.43.12) | Running |
| tunnel-cadence.blackroad.io | Shellfish (174.138.44.45) | Running |

---

## Stale Network Data to Clean Up

| Item | Location | Issue | Fix |
|------|----------|-------|-----|
| `/etc/hosts` entry | Alexandria Mac | `192.168.4.74 octavia` — wrong IP | Change to `192.168.4.38 octavia` |
| `hailo.sh` | `~/hailo.sh` | Connects to `pi@192.168.4.74` | Change to `blackroad@192.168.4.38` |
| SSH `anastasia` alias | `~/.ssh/config` | Points to DO droplet, not Pi | Add `anastasia-pi` for 192.168.4.33 |
| `blackroad-fleet.yaml` | `~/blackroad-fleet.yaml` | Lucidia/Octavia IPs swapped | Fix both local and Tailscale IPs |
| Agent registry | `~/.blackroad-agent-registry.db` | Octavia: `pironman_hailo8` | Change to `pironman` (no Hailo) |
| Agent registry | `~/.blackroad-agent-registry.db` | Aria: `pironman_hailo8` | Change to `pironman` (no Hailo) |

---

## Firewall Rules (Standard)

| Port | Protocol | Service | Direction |
|------|----------|---------|-----------|
| 22 | TCP | SSH | Inbound |
| 80 | TCP | HTTP | Inbound |
| 443 | TCP | HTTPS | Inbound |
| 51820 | UDP | WireGuard | Inbound (Shellfish hub only) |

Default policy: **deny** all other inbound.

---

## LoRa Network

Athena (Heltec WiFi LoRa 32) at 192.168.4.45:

- **Frequency:** 868/915 MHz
- **Range:** Up to 10km line-of-sight
- **MAC:** d0:c9:07:50:51:ca (Espressif OUI confirmed)
- **Status:** Powered on (responds to ARP)
- **Management:** `~/lora.sh`

---

## Network Diagnostics

```bash
# Live ARP table (shows devices seen recently)
arp -a | grep "192.168.4" | grep -v incomplete | sort -t. -k4 -n

# Ping sweep
for i in {1..255}; do ping -c1 -W1 192.168.4.$i &>/dev/null && echo "UP .${i}"; done

# Tailscale status
tailscale status

# SSH probe a node
ssh -o ConnectTimeout=3 cecilia "hostname; uname -r; ss -tlnp"

# DNS lookup
dig blackroad.io ANY +short

# Management scripts
~/blackroad-network-scan.sh
~/blackroad-network-discovery.sh
```
