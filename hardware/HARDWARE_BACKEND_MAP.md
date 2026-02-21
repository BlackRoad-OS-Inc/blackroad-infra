# BlackRoad Hardware Backend Map

**Canonical source of truth for all BlackRoad physical infrastructure.**

| Field | Value |
|-------|-------|
| Owner | BlackRoad OS, Inc. |
| Updated | 2026-02-20 |
| Fleet Version | 2.0.0 |
| Total Devices | 21 |
| Total AI Compute | ~135 TOPS |
| Network | 192.168.4.0/24 LAN + Tailscale mesh |

---

## 1. Fleet Summary

| # | Name | Type | Hardware | IP (Local) | IP (Tailscale) | Accelerator | Role | Status |
|---|------|------|----------|------------|----------------|-------------|------|--------|
| 1 | Cecilia | Pi 5 | 8GB + Hailo-8 + 500GB NVMe | 192.168.4.89 | 100.72.180.98 | Hailo-8 26 TOPS | Primary AI / CECE OS | Active |
| 2 | Octavia | Pi 5 | 8GB + Pironman + Hailo-8 | 192.168.4.38 | 100.83.149.86 | Hailo-8 26 TOPS | AI Inference | Active |
| 3 | Lucidia | Pi 5 | 8GB + ElectroCookie | 192.168.4.81 | 100.66.235.47 | — | NATS + Ollama Brain | Active |
| 4 | Aria | Pi 5 | 8GB + Pironman + Hailo-8 | 192.168.4.82 | 100.109.14.17 | Hailo-8 26 TOPS | API Services | Active |
| 5 | Anastasia | Pi 5 | 8GB + Pironman + NVMe | 192.168.4.33 | — | — | AI Inference Secondary | Active |
| 6 | Cordelia | Pi 5 | 8GB | 192.168.4.27 | — | — | Orchestration | Active |
| 7 | Alice | Pi 400 | 4GB | 192.168.4.49 | 100.77.210.18 | — | Gateway / Auth | Active |
| 8 | Olympia | Pi 4B | PiKVM | — | — | — | KVM Console | Offline |
| 9 | Codex-Infinity | DO Droplet | 1 vCPU / 1GB | 159.65.43.12 | 100.108.132.8 | — | Codex Server | Active |
| 10 | Shellfish | DO Droplet | 1 vCPU / 1GB | 174.138.44.45 | 100.94.33.37 | — | Cloud Edge | Active |
| 11 | Jetson-Agent | Jetson Orin Nano | 8GB + GPU | — | — | 40 TOPS GPU | Agent UI / Inference | Pending |
| 12 | Alexandria | MacBook Pro M1 | 8GB | 192.168.4.28 | — | M1 Neural Engine 15.8 TOPS | Operator Workstation | Active |
| 13 | Athena | Heltec LoRa ESP32 | ESP32 + SX1276 | 192.168.4.45 | — | — | LoRa Mesh Node | Active |
| 14 | Persephone | Sipeed RISC-V | — | — | — | — | Portable Compute | Active |
| 15 | Iris | Roku | — | 192.168.4.26 | — | — | Streaming | Active |
| 16 | Ares | Xbox | — | 192.168.4.90 | — | — | Gaming | Active |
| 17 | Phoebe | iPhone | — | 192.168.4.88 | — | — | Mobile | Active |
| 18 | Calliope | Unidentified IoT | — | — | — | — | IoT Node | Active |
| 19 | Sophia | Unidentified IoT | — | — | — | — | IoT Node | Active |
| 20 | SenseCAP W1-A | IoT AI Agent | ESP32-S3 + HX6538 | — | — | Ethos-U55 ~1 TOPS | Vision AI | Returned |
| 21 | Pi-Holo | Pi 5 (planned) | 8GB | — | — | — | Hologram Renderer | Planned |

---

## 2. Production Cluster — Raspberry Pis

Eight Raspberry Pi nodes form the always-on backbone.

| Node | Board | RAM | Storage | Case | Accelerator | Cooling | PSU | Role |
|------|-------|-----|---------|------|-------------|---------|-----|------|
| Cecilia | Pi 5 | 8GB | 500GB NVMe | Standard | Hailo-8 M.2 (26 TOPS) | Active fan | 27W USB-C | Primary AI, CECE OS |
| Octavia | Pi 5 | 8GB | 235GB SD | Pironman | Hailo-8 M.2 (26 TOPS) | Pironman dual-fan tower | 27W USB-C | AI Inference |
| Lucidia | Pi 5 | 8GB | 117GB SD | ElectroCookie Radial Tower | — | ElectroCookie tower | 27W USB-C | NATS bus, Ollama |
| Aria | Pi 5 | 8GB | 29GB SD | Pironman | Hailo-8 M.2 (26 TOPS) | Pironman dual-fan tower | 27W USB-C | API Services |
| Anastasia | Pi 5 | 8GB | NVMe (Pironman) | Pironman | — | Pironman dual-fan tower | 27W USB-C | AI Inference Secondary |
| Cordelia | Pi 5 | 8GB | SD | Standard | — | Active cooler | 27W USB-C | Orchestration |
| Alice | Pi 400 | 4GB | 32GB SD | Built-in keyboard | — | Passive (built-in) | 15W USB-C | Gateway, Auth |
| Olympia | Pi 4B | 4GB | SD | PiKVM case | — | Passive | 15W USB-C | KVM Console |

### SSH Access

```bash
ssh alice         # 192.168.4.49
ssh lucidia       # 192.168.4.81  (or lucidia-ts for Tailscale)
ssh aria          # 192.168.4.82  (or aria-ts)
ssh cecilia       # 192.168.4.89  (or cecilia-ts)
ssh octavia       # 192.168.4.38  (or octavia-ts)
ssh anastasia     # 192.168.4.33
ssh cordelia      # 192.168.4.27
```

### OS Baseline

All Pis run Debian 12 (Bookworm) with:
- Kernel: 6.1 LTS
- User: `alexandria` (uid 1000)
- SSH: key-only, no password auth
- Firewall: UFW (deny by default, allow 22/80/443/41641)
- Time sync: chrony → time.cloudflare.com
- Auto-updates: unattended-upgrades + fail2ban

---

## 3. Cloud Compute

Two DigitalOcean droplets provide cloud presence.

| Node | Region | Spec | Public IP | Tailscale IP | Storage | Role |
|------|--------|------|-----------|--------------|---------|------|
| Codex-Infinity | NYC | 1 vCPU / 1GB | 159.65.43.12 | 100.108.132.8 | 78GB SSD | Codex DB, cloud services |
| Shellfish | NYC | 1 vCPU / 1GB | 174.138.44.45 | 100.94.33.37 | 25GB SSD | Edge compute, tunnels |

### OS Baseline

- Debian 12 (Bookworm), Kernel 5.15 LTS
- Same user/SSH/firewall config as Pis
- Cloudflare tunnels for ingress

---

## 4. Edge Compute

| Node | Hardware | Status | Purpose |
|------|----------|--------|---------|
| Jetson-Agent | NVIDIA Jetson Orin Nano 8GB | Pending setup | Agent UI on 10.1" touch, GPU inference |
| Pi-Holo | Pi 5 8GB (planned) | Planned | Hologram renderer on 4" 720x720 display |
| Pi-Ops | Pi 5 8GB (planned) | Planned | MQTT broker + ops monitor on 9.3" ultrawide |
| Pi-Zero-Sim | Pi Zero W | Ready | Lightweight sim output on 7" display |
| Persephone | Sipeed RISC-V | Active | Portable RISC-V compute experiments |

---

## 5. Microcontroller Array

| MCU | Chip | Qty | Connectivity | Form Factor | Purpose |
|-----|------|-----|--------------|-------------|---------|
| ESP32-S3 SuperMini | ESP32-S3 | 5 | WiFi + BLE | Tiny USB-C | General IoT |
| ESP32-S3 N8R8 | ESP32-S3 | 2 | WiFi + BLE + OTG | Dev board | 8MB PSRAM apps |
| ESP32 Touchscreen | ESP32 | 3 | WiFi + BLE | 2.8" TFT (320x240) | Standalone sensor display |
| Athena (Heltec LoRa) | ESP32 + SX1276 | 1 | WiFi + LoRa 868/915MHz | OLED 0.96" | LoRa mesh node |
| M5Stack Atom Lite | ESP32-PICO | 2 | WiFi + BLE | 24x24mm cube | Button/LED/Grove |
| Raspberry Pi Pico | RP2040 | 2 | USB only | Breadboard | MicroPython prototyping |
| ATTINY88 | AVR 8-bit | 3 | None (I2C/SPI slave) | DIP | Low-power peripherals |
| ELEGOO UNO R3 | ATmega328P | 2 | USB | Arduino form factor | Starter kit projects |
| WCH CH32V003 | RISC-V | 1 | USB | Minimal | Ultra-cheap RISC-V |

**Total MCUs: 21 units**

### Flashing Tools
- `esptool.py` / `espflash` for ESP32 family
- `arduino-cli` for Arduino/ATmega boards
- PlatformIO for cross-platform builds
- `picotool` for Pico RP2040

---

## 6. IoT & Sensor Devices

### SenseCAP Watcher W1-A

| Field | Value |
|-------|-------|
| Name | SenseCAP Watcher W1-A |
| Type | IoT AI Agent |
| Status | **Returned** (August 2025) |
| Processor | ESP32-S3 |
| AI Chip | Himax WiseEye2 HX6538 (Arm Cortex-M55 + Arm Ethos-U55 NPU) |
| AI Compute | ~1 TOPS (Ethos-U55) |
| Camera | Image recognition (person/animal/gesture detection) |
| Microphone | Voice-activated commands |
| Speaker | Audio output |
| Touch | Capacitive touch interface |
| Connectivity | WiFi |
| Features | On-device AI inference, SenseCraft AI, no-code workflows, OTA |
| Notes | Purchased and returned Aug 2025. Standalone edge AI unit with dedicated Himax coprocessor. Could be re-acquired for doorbell/monitor use case. |

### Sensor Inventory

| Sensor | Type | Interface | Attached To |
|--------|------|-----------|-------------|
| DHT22 | Temperature / Humidity | GPIO | Available |
| Radar (HLK-LD2410 / RCWL-0516) | Presence / Motion | GPIO/UART | Available |
| GPS Module | NMEA Location | UART | Available |
| ToF (VL53L0X / VL53L1X) | Distance (mm) | I2C | Available |
| AS7341 | Spectral 11-channel | I2C | Available |
| Pi Camera V2 | 8MP IMX219 | CSI | Available |
| USB + I2S MEMS Mics | Audio capture | USB / I2S | Available |
| Ultrasonic | Distance | GPIO | ELEGOO kit |
| PIR | Motion | GPIO | ELEGOO kit |
| Photoresistor | Light level | ADC | ELEGOO kit |
| IR Receiver | Remote control | GPIO | ELEGOO kit |
| Joystick | Analog input | ADC | ELEGOO kit |

### IoT Nodes (Unidentified)

| Name | Platform | Status | Notes |
|------|----------|--------|-------|
| Calliope | Unknown IoT | Active | Registered in agent registry, needs identification |
| Sophia | Unknown IoT | Active | Registered in agent registry, needs identification |

---

## 7. Consumer Devices

| Name | Hardware | IP | Role | Notes |
|------|----------|-----|------|-------|
| Iris | Roku | 192.168.4.26 | Streaming | Media playback |
| Ares | Xbox | 192.168.4.90 | Gaming | Entertainment |
| Phoebe | iPhone | 192.168.4.88 | Mobile | Monitoring, OOB access |
| Alexandria | MacBook Pro M1 8GB | 192.168.4.28 | Primary operator | Development, orchestration |
| MacBook #1 | ~2014 Intel MacBook | — | Monitoring station | Secondary display |
| MacBook #2 | ~2014 Intel MacBook | — | Agent orchestrator | Secondary display |
| iPad Pro | 2015 iPad Pro | — | Tablet | Touch interface |

---

## 8. AI Accelerator Summary

| Accelerator | Location | Architecture | Compute | Status |
|-------------|----------|--------------|---------|--------|
| Hailo-8 M.2 #1 | Cecilia | Hailo-8 (serial: HLLWM2B233704667) | 26 TOPS | Active |
| Hailo-8 M.2 #2 | Octavia | Hailo-8 (serial: HLLWM2B233704606) | 26 TOPS | Active |
| Hailo-8 M.2 #3 | Aria | Hailo-8 M.2 | 26 TOPS | Active |
| Jetson Orin Nano | Jetson-Agent | NVIDIA Ampere GPU | 40 TOPS | Pending |
| Apple M1 Neural Engine | Alexandria | Apple Neural Engine | 15.8 TOPS | Active |
| Himax Ethos-U55 | SenseCAP W1-A | Arm Ethos-U55 NPU | ~1 TOPS | Returned |

### Total AI Compute Budget

| Category | TOPS |
|----------|------|
| Hailo-8 (3 units) | 78 |
| Jetson Orin Nano | 40 |
| Apple M1 Neural Engine | 15.8 |
| Ethos-U55 (returned) | ~1 |
| **Total (active)** | **~134 TOPS** |
| **Total (including returned/pending)** | **~135 TOPS** |

### Model Compatibility

| Model | Hailo-8 | Jetson | M1 |
|-------|---------|--------|----|
| YOLOv5m | HEF compiled | TensorRT | CoreML |
| YOLOv8 | HEF compiled | TensorRT | CoreML |
| Llama 2 7B | — | CUDA | Ollama (Metal) |
| Whisper | — | CUDA | Ollama |
| ResNet-50 | HEF compiled | TensorRT | CoreML |

---

## 9. Network Topology

### LAN (192.168.4.0/24)

```
                        ┌──────────────┐
                        │  TP-Link     │
                        │  Router/WiFi │
                        │ 192.168.4.1  │
                        └──────┬───────┘
                               │
                    ┌──────────┴──────────┐
                    │  TP-Link TL-SG105   │
                    │  5-Port Gigabit SW   │
                    └┬────┬────┬────┬────┘
                     │    │    │    │
              ┌──────┘    │    │    └──────┐
              │           │    │           │
         ┌────┴────┐ ┌───┴──┐ ┌┴────┐ ┌──┴──────┐
         │ Cecilia │ │Lucia │ │Aria │ │ Octavia │
         │  .89    │ │ .81  │ │ .82 │ │  .38    │
         │ Hailo-8 │ │ NATS │ │Hail │ │ Hailo-8 │
         └─────────┘ └──────┘ └─────┘ └─────────┘

    WiFi:
         ┌─────────┐ ┌──────┐ ┌───────┐ ┌───────────┐
         │ Alice   │ │Anast.│ │Cordel.│ │Alexandria │
         │  .49    │ │ .33  │ │  .27  │ │   .28     │
         └─────────┘ └──────┘ └───────┘ └───────────┘
         ┌─────────┐ ┌──────┐ ┌───────┐ ┌───────────┐
         │ Athena  │ │Phoebe│ │ Ares  │ │   Iris    │
         │  .45    │ │ .88  │ │  .90  │ │   .26     │
         └─────────┘ └──────┘ └───────┘ └───────────┘
```

### Tailscale Mesh Overlay

| Node | Tailscale IP | Connected |
|------|-------------|-----------|
| Cecilia | 100.72.180.98 | Yes |
| Lucidia | 100.66.235.47 | Yes |
| Octavia | 100.83.149.86 | Yes |
| Aria | 100.109.14.17 | Yes |
| Alice | 100.77.210.18 | Yes |
| Codex-Infinity | 100.108.132.8 | Yes |
| Shellfish | 100.94.33.37 | Yes |

### DNS & Tunnels

- Cloudflare DNS: `blackroad.io` zone
- Cloudflare tunnels per node: `tunnel-{hostname}.blackroad.io`
- Headscale: self-hosted coordination on Alice (planned)

---

## 10. Storage Infrastructure

| Node | Type | Capacity | Interface | Used | Notes |
|------|------|----------|-----------|------|-------|
| Cecilia | NVMe M.2 | 500GB | PCIe | ~50% | Crucial P310 |
| Anastasia | NVMe M.2 | 1TB | PCIe (Pironman) | — | Crucial P310 |
| Octavia | microSD | 235GB | SD slot | ~90% | Samsung EVO Select, needs cleanup |
| Lucidia | microSD | 117GB | SD slot | ~60% | Samsung EVO Select |
| Alice | microSD | 32GB | SD slot | ~93% | Needs cleanup |
| Aria | microSD | 29GB | SD slot | ~70% | Samsung EVO Select |
| Codex-Infinity | SSD | 78GB | Cloud block | ~40% | DigitalOcean |
| Shellfish | SSD | 25GB | Cloud block | ~50% | DigitalOcean |

---

## 11. Power & Cooling

| Node | PSU | Watts | Cooling |
|------|-----|-------|---------|
| Pi 5 nodes (Cecilia, Lucidia, Aria, Octavia, Anastasia, Cordelia) | Geekworm 27W 5V/5A USB-C | 27W | Pironman dual-fan / ElectroCookie tower / Active cooler |
| Alice (Pi 400) | 5V/3A USB-C | 15W | Passive (built-in) |
| Olympia (Pi 4B) | 5V/3A USB-C | 15W | Passive |
| Jetson Orin Nano | Barrel jack | 15W | Dev kit heatsink + fan |
| Pi Zero W | 5V/2A Micro USB | 10W | None |
| Displays | Various 5V wall adapters | 5-15W each | N/A |
| DigitalOcean droplets | Cloud-managed | — | Cloud-managed |

### Total Power Budget (On-Premises)

| Category | Devices | Est. Draw |
|----------|---------|-----------|
| Pi 5 cluster (6) | Cecilia, Lucidia, Aria, Octavia, Anastasia, Cordelia | ~60W peak |
| Pi 400 + Pi 4B | Alice, Olympia | ~20W peak |
| Jetson Orin Nano | Jetson-Agent | ~15W peak |
| Displays (5) | Various | ~30W |
| Networking | Router + Switch | ~15W |
| Mac + peripherals | Alexandria | ~30W |
| **Total** | | **~170W peak** |

---

## 12. Display Inventory

| Size | Resolution | Model | Assigned To | Interface |
|------|-----------|-------|-------------|-----------|
| 10.1" | 1024x600 | ROADOM Touch IPS | Jetson-Agent | HDMI + USB touch |
| 9.3" | 1600x600 | Waveshare Ultrawide | Pi-Ops (shared via HDMI switch) | HDMI |
| 7" | 1024x600 | Waveshare Touch | Pi-Zero-Sim | HDMI + USB touch |
| 4" | 720x720 | Waveshare Square | Pi-Holo | HDMI |
| 2.8" | 320x240 | ESP32 Touch TFT (x3) | ESP32 MCUs | SPI |
| 0.96" | 128x64 | OLED (x3) | Arduino / ESP32 | I2C |

### Video Routing

- UGREEN HDMI Switch 5-in-1: shares 9.3" between Pi-Ops and Pi 400
- WAVLINK HDMI Splitter: clone Pi-Holo to second display
- WARRKY USB-C to HDMI (2-pack): Mac to display
- JSAUX Micro HDMI adapters: Pi to display

---

## 13. Management Tools

| Script | Location | Purpose |
|--------|----------|---------|
| `hardware.sh` | `~/hardware.sh` | Interactive fleet overview menu |
| `hailo.sh` | `~/hailo.sh` | Hailo-8 detection, benchmarks, inference |
| `mcus.sh` | `~/mcus.sh` | Microcontroller fleet status |
| `sensors.sh` | `~/sensors.sh` | Sensor inventory and live readings |
| `espflash.sh` | `~/espflash.sh` | ESP32 flashing tool |
| `i2c.sh` | `~/i2c.sh` | I2C bus scanning |
| `lora.sh` | `~/lora.sh` | LoRa network tools |
| `blackroad-network-scan.sh` | `~/blackroad-network-scan.sh` | ARP + ping sweep + Tailscale status |
| `blackroad-network-discovery.sh` | `~/blackroad-network-discovery.sh` | SSH probe all devices |
| `pifleet.sh` | `~/pifleet.sh` | Pi-specific fleet management |
| `hardware-inventory.sh` | `hardware/scripts/hardware-inventory.sh` | Registry query + live scan (this repo) |
| `fleet-health-check.sh` | `hardware/scripts/fleet-health-check.sh` | Ping + port check (this repo) |

---

## 14. Provisioning Phases

All nodes follow a 4-phase provisioning process:

1. **Base Image** — Flash Debian 12, create `alexandria` user, deploy SSH keys, enable UFW
2. **Fleet Identity** — Install Tailscale, configure `/etc/hosts`, deploy SSH aliases, set MOTD banner
3. **Role Provisioning** — Install role-specific packages/services, deploy systemd units, configure Cloudflare tunnel
4. **Cloud Integration** — Deploy GitHub deploy key, register in fleet inventory, verify connectivity

See `~/blackroad-fleet.yaml` for the full provisioning spec.

---

## Appendix A: IP Address Registry

### LAN (192.168.4.0/24)

| IP | Hostname | Type |
|----|----------|------|
| 192.168.4.1 | Router | TP-Link |
| 192.168.4.26 | Iris | Roku |
| 192.168.4.27 | Cordelia | Pi 5 |
| 192.168.4.28 | Alexandria | MacBook Pro M1 |
| 192.168.4.33 | Anastasia | Pi 5 |
| 192.168.4.38 | Octavia | Pi 5 |
| 192.168.4.45 | Athena | Heltec LoRa ESP32 |
| 192.168.4.49 | Alice | Pi 400 |
| 192.168.4.81 | Lucidia | Pi 5 |
| 192.168.4.82 | Aria | Pi 5 |
| 192.168.4.88 | Phoebe | iPhone |
| 192.168.4.89 | Cecilia | Pi 5 |
| 192.168.4.90 | Ares | Xbox |

### Cloud

| IP | Hostname | Provider |
|----|----------|----------|
| 159.65.43.12 | Codex-Infinity | DigitalOcean |
| 174.138.44.45 | Shellfish | DigitalOcean |

### Tailscale (100.x.x.x)

| IP | Hostname |
|----|----------|
| 100.66.235.47 | Lucidia |
| 100.72.180.98 | Cecilia |
| 100.77.210.18 | Alice |
| 100.83.149.86 | Octavia |
| 100.94.33.37 | Shellfish |
| 100.108.132.8 | Codex-Infinity |
| 100.109.14.17 | Aria |
