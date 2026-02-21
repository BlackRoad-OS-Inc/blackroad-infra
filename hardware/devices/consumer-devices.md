# Consumer Devices

Non-server devices on the BlackRoad network — workstations, entertainment, mobile.

---

## Overview

| Name | Hardware | IP (Local) | Role | Status |
|------|----------|------------|------|--------|
| Alexandria | MacBook Pro M1 8GB | 192.168.4.28 | Primary operator workstation | Active |
| MacBook #1 | ~2014 Intel MacBook | — | Monitoring station | Available |
| MacBook #2 | ~2014 Intel MacBook | — | Agent orchestrator | Available |
| iPad Pro | 2015 iPad Pro | — | Touch interface | Available |
| Iris | Roku | 192.168.4.26 | Streaming / media | Active |
| Ares | Xbox | 192.168.4.90 | Gaming | Active |
| Phoebe | iPhone | 192.168.4.88 | Mobile access / OOB | Active |

---

## Per-Device Details

### Alexandria — Primary Operator Workstation

- **Hardware:** MacBook Pro M1 (2020/2021)
- **CPU:** Apple M1 (4 performance + 4 efficiency cores)
- **RAM:** 8GB unified memory
- **GPU:** Apple M1 integrated (8-core)
- **AI:** Neural Engine (15.8 TOPS)
- **Storage:** SSD (256GB or 512GB)
- **IP:** 192.168.4.28
- **OS:** macOS
- **Role:** Development, orchestration, fleet management
- **Tools:** Terminal (zsh), VS Code, Claude Code, SSH to all fleet nodes
- **Input:** Apple Magic Keyboard ($98.50), Apple Magic Mouse ($79.99)
- **Docking:** TobenONE 15-in-1 USB-C Dock ($129.99)
- **Notes:** Primary workstation. All scripts and CLI tools run from here.

### MacBook #1 — Monitoring Station

- **Hardware:** ~2014 Intel MacBook
- **Role:** Secondary display for monitoring dashboards
- **Status:** Available for deployment

### MacBook #2 — Agent Orchestrator

- **Hardware:** ~2014 Intel MacBook
- **Role:** Dedicated agent orchestration display
- **Status:** Available for deployment

### iPad Pro — Touch Interface

- **Hardware:** 2015 iPad Pro
- **Role:** Touch-based control interface, remote monitoring
- **Status:** Available

### Iris — Streaming

- **Hardware:** Roku
- **IP:** 192.168.4.26
- **Agent Registry:** Registered as "Iris" (streaming role)
- **Role:** Media playback and streaming

### Ares — Gaming

- **Hardware:** Xbox
- **IP:** 192.168.4.90
- **Agent Registry:** Registered as "Ares" (gaming role)
- **Role:** Entertainment

### Phoebe — Mobile

- **Hardware:** iPhone
- **IP:** 192.168.4.88
- **Agent Registry:** Registered as "Phoebe" (mobile role)
- **Role:** Mobile monitoring, out-of-band access, notifications

---

## Input Peripherals

| Device | Price | Connection | Used With |
|--------|-------|------------|-----------|
| Apple Magic Keyboard | $98.50 | Bluetooth | Alexandria / Jetson |
| Apple Magic Mouse | $79.99 | Bluetooth | Alexandria |
| Logitech H390 USB Headset | $28.84 | USB | Voice I/O for agents |
| Pi 400 Keyboard | $119 | Built-in | Alice (admin console) |
| Apple USB-C SD Reader | $45 | USB-C | Alexandria (flashing) |
| Anker USB 3.0 SD Reader (x2) | — | USB-A | Flashing stations |
