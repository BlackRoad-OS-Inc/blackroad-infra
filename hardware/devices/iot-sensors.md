# IoT & Sensor Devices

Sensor inventory, IoT nodes, and the SenseCAP Watcher W1-A.

---

## SenseCAP Watcher W1-A

| Field | Value |
|-------|-------|
| **Name** | SenseCAP Watcher W1-A |
| **Manufacturer** | Seeed Studio |
| **Type** | IoT AI Agent |
| **Status** | **Returned** (August 2025) |
| **Processor** | ESP32-S3 |
| **AI Chip** | Himax WiseEye2 HX6538 |
| **AI Architecture** | Arm Cortex-M55 + Arm Ethos-U55 NPU |
| **AI Compute** | ~1 TOPS (Ethos-U55) |
| **Camera** | Built-in (person/animal/gesture detection) |
| **Microphone** | Built-in (voice-activated commands) |
| **Speaker** | Built-in (audio output) |
| **Touch** | Capacitive touch interface |
| **Connectivity** | WiFi |
| **Power** | USB-C |

### Features

- On-device AI inference (no cloud required for basic detection)
- Person, animal, and gesture detection via camera
- Voice-activated command processing
- SenseCraft AI platform integration
- No-code workflow configuration via web UI
- OTA firmware updates

### Assessment

Purchased and returned August 2025. A compact standalone edge AI unit combining ESP32-S3 with a dedicated Himax AI coprocessor. The Ethos-U55 NPU provides ~1 TOPS specifically for vision inference tasks. The form factor (camera + mic + speaker + touch in a small enclosure) makes it suitable for doorbell, room monitor, or security camera applications. Could be re-acquired if a self-contained vision AI device is needed.

---

## Sensor Inventory

### Environmental

| Sensor | Type | Interface | Range | Notes |
|--------|------|-----------|-------|-------|
| DHT22 | Temperature + Humidity | GPIO (digital) | -40°C to 80°C, 0-100% RH | ±0.5°C accuracy |
| Photoresistor | Light level | ADC (analog) | Relative lux | From ELEGOO kit |
| Tilt switch | Orientation | GPIO (digital) | Binary tilt detect | From ELEGOO kit |

### Motion & Presence

| Sensor | Type | Interface | Range | Notes |
|--------|------|-----------|-------|-------|
| PIR | Passive infrared motion | GPIO (digital) | ~7m | From ELEGOO kit |
| Radar (HLK-LD2410) | mmWave presence | UART | ~6m | Stationary + moving detection |
| Radar (RCWL-0516) | Doppler motion | GPIO (digital) | ~7m | Microwave motion sensor |
| Ultrasonic (HC-SR04) | Distance | GPIO (trigger/echo) | 2cm-4m | From ELEGOO kit |

### Precision Distance

| Sensor | Type | Interface | Range | Notes |
|--------|------|-----------|-------|-------|
| VL53L0X | Time-of-Flight laser | I2C | 30mm-2m | ±3% accuracy |
| VL53L1X | Time-of-Flight laser | I2C | 40mm-4m | Improved version |

### Spectral & Light

| Sensor | Type | Interface | Channels | Notes |
|--------|------|-----------|----------|-------|
| AS7341 | Spectral sensor | I2C | 11 channels (visible + NIR) | Lab-grade spectroscopy |

### Audio & Vision

| Sensor | Type | Interface | Spec | Notes |
|--------|------|-----------|------|-------|
| Pi Camera V2 | Camera | CSI | 8MP Sony IMX219, 1080p30 | On Pi-Holo for tracking |
| USB Microphone | Audio capture | USB | 16-bit 44.1kHz | Logitech H390 headset |
| I2S MEMS Mic | Audio capture | I2S | Digital output | For Pi/ESP32 |

### Input

| Sensor | Type | Interface | Notes |
|--------|------|-----------|-------|
| IR Receiver | Remote control | GPIO | 38kHz carrier, from ELEGOO kit |
| Joystick | 2-axis analog | ADC | X/Y + button, from ELEGOO kit |

---

## I2C Device Map

Common I2C addresses for connected sensors:

| Address | Device | Bus |
|---------|--------|-----|
| 0x29 | VL53L0X / VL53L1X | I2C-1 |
| 0x39 | AS7341 | I2C-1 |
| 0x3C | SSD1306 OLED 0.96" | I2C-1 |
| 0x40 | DHT22 (if I2C variant) | I2C-1 |
| 0x76/0x77 | BME280 (if present) | I2C-1 |

### I2C Scan

```bash
# On any Pi node:
i2cdetect -y 1

# Via management script:
~/i2c.sh
```

---

## Unidentified IoT Nodes

Two devices registered in the agent registry with unknown hardware:

| Name | Platform | IP | Role | Status |
|------|----------|-----|------|--------|
| Calliope | Unknown IoT | — | iot_node | Active |
| Sophia | Unknown IoT | — | iot_node | Active |

**Action:** Identify hardware and update registry.

---

## Management Scripts

```bash
~/sensors.sh     # Interactive sensor menu with live readings
~/i2c.sh         # I2C bus scan
~/mcus.sh        # MCU fleet (many sensors attach to MCUs)
```
