# Edge Compute

Specialized compute nodes for AI inference, visualization, and constellation workstation.

---

## Active Edge Nodes

| Node | Hardware | Accelerator | Display | Status |
|------|----------|-------------|---------|--------|
| Jetson-Agent | NVIDIA Jetson Orin Nano 8GB | 40 TOPS GPU | 10.1" Touch | Pending setup |
| Persephone | Sipeed RISC-V | — | — | Active |

## Planned Constellation Nodes

| Node | Hardware | Display | Purpose | Status |
|------|----------|---------|---------|--------|
| Pi-Holo | Pi 5 8GB | 4" 720x720 Square | Hologram renderer (Pepper's Ghost) | Planned |
| Pi-Ops | Pi 5 8GB | 9.3" 1600x600 Ultrawide | MQTT broker + ops monitor | Planned |
| Pi-Zero-Sim | Pi Zero W | 7" 1024x600 Touch | Lightweight sim output | Ready |

---

## Per-Node Details

### Jetson-Agent — GPU AI Workstation

- **Hardware:** NVIDIA Jetson Orin Nano Developer Kit
- **RAM:** 8GB LPDDR5
- **GPU:** NVIDIA Ampere architecture, 40 TOPS
- **Storage:** microSD + NVMe slot
- **Display:** 10.1" ROADOM Touch IPS (1024x600) via HDMI
- **Input:** Apple Magic Keyboard (Bluetooth), Apple Magic Mouse
- **PSU:** Barrel jack (15W TDP)
- **Cooling:** Dev kit heatsink + fan
- **Status:** Pending initial setup
- **Capabilities:**
  - Full CUDA support for LLM inference
  - TensorRT optimized model execution
  - Real-time object detection (YOLOv8)
  - Agent UI touchscreen interface

### Persephone — RISC-V Experimental

- **Hardware:** Sipeed RISC-V board
- **Role:** Portable RISC-V compute experiments
- **Status:** Active in agent registry
- **Notes:** Experimental platform for RISC-V software testing

### Pi-Holo — Hologram Renderer (Planned)

- **Hardware:** Raspberry Pi 5 8GB (new, ready to flash)
- **Display:** 4" Waveshare Square 720x720 (under pyramid)
- **Cooling:** GeeekPi Active Cooler RGB
- **PSU:** Geekworm 27W 5V/5A USB-C
- **Purpose:** Render holographic content via Pepper's Ghost optics
- **Build Materials:** 50x 4" glass mirrors, 5x 6" beveled mirrors, bamboo frame, LED light bases, acrylic risers
- **Camera:** Pi Camera V2 (8MP IMX219) for input tracking

### Pi-Ops — Operations Monitor (Planned)

- **Hardware:** Raspberry Pi 5 8GB (new, ready to flash)
- **Display:** 9.3" Waveshare Ultrawide 1600x600 (shared via UGREEN HDMI switch with Pi 400)
- **Cooling:** ElectroCookie Radial Tower
- **PSU:** Geekworm 27W 5V/5A USB-C
- **Purpose:** MQTT broker (Mosquitto), real-time ops dashboard
- **Services (planned):** Mosquitto, monitoring dashboard

### Pi-Zero-Sim — Simulation Output (Ready)

- **Hardware:** Raspberry Pi Zero W
- **Display:** 7" Waveshare Touch 1024x600
- **PSU:** 5V/2A Micro USB
- **Purpose:** Lightweight simulation and output display
- **Notes:** WiFi-connected (no Ethernet)

---

## Constellation Workstation Layout

```
┌──────────────────────────────────────────────────────────┐
│                    BLACKROAD WORKSTATION                   │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  LEFT                CENTER              RIGHT            │
│  ┌───────┐          ┌──────────┐       ┌───────┐         │
│  │ 4"    │          │ 10.1"    │       │ 7"    │         │
│  │ HOLO  │          │ AGENT    │       │ SIM   │         │
│  │ Pi-5  │          │ JETSON   │       │ Pi-0W │         │
│  └───────┘          └──────────┘       └───────┘         │
│  [Pyramid]           [Touch UI]       [Output]            │
│                                                           │
│              ┌────────────────┐                           │
│              │   9.3" OPS     │                           │
│              │   Pi-5 #2      │ ← MQTT BROKER             │
│              └────────────────┘                           │
│                                                           │
│  ┌──────────────────────────────────┐                    │
│  │   Pi-400 KEYBOARD (Admin/KVM)    │                    │
│  └──────────────────────────────────┘                    │
└──────────────────────────────────────────────────────────┘
```
