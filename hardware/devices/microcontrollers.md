# Microcontroller Array

**21 MCU units** across 9 types — ESP32, Arduino, Pico, ATTINY, and RISC-V.

---

## Inventory

| MCU | Chip | Qty | Connectivity | Flash | RAM | Purpose |
|-----|------|-----|--------------|-------|-----|---------|
| ESP32-S3 SuperMini | ESP32-S3 | 5 | WiFi + BLE | 8MB | 512KB | General IoT, tiny form factor |
| ESP32-S3 N8R8 | ESP32-S3 | 2 | WiFi + BLE + USB OTG | 8MB | 8MB PSRAM | High-memory applications |
| ESP32 2.8" Touchscreen | ESP32 | 3 | WiFi + BLE | 4MB | 520KB | Standalone sensor display |
| Heltec WiFi LoRa 32 (Athena) | ESP32 + SX1276 | 1 | WiFi + LoRa 868/915MHz | 4MB | 520KB | LoRa mesh node |
| M5Stack Atom Lite | ESP32-PICO | 2 | WiFi + BLE | 4MB | 520KB | Button/LED/Grove peripherals |
| Raspberry Pi Pico | RP2040 | 2 | USB only | 2MB | 264KB SRAM | MicroPython prototyping |
| ATTINY88 | AVR 8-bit | 3 | None (I2C/SPI) | 8KB | 512B | Low-power peripherals |
| ELEGOO UNO R3 | ATmega328P | 2 | USB | 32KB | 2KB SRAM | Starter kit projects |
| WCH CH32V003 | RISC-V | 1 | USB | 16KB | 2KB SRAM | Ultra-cheap RISC-V |

**Total: 21 units**

---

## ESP32 Family (13 units)

### ESP32-S3 SuperMini (x5)

- **Chip:** ESP32-S3 dual-core LX7 @ 240MHz
- **Memory:** 8MB Flash, 512KB SRAM
- **Connectivity:** WiFi 802.11 b/g/n + BLE 5.0
- **Interface:** USB-C
- **Form Factor:** Ultra-compact
- **Use Cases:** Distributed sensor mesh, beacon, environmental monitoring

### ESP32-S3 N8R8 (x2)

- **Chip:** ESP32-S3 dual-core LX7 @ 240MHz
- **Memory:** 8MB Flash, 8MB PSRAM (octal SPI)
- **Connectivity:** WiFi + BLE + USB OTG
- **Use Cases:** Camera applications, audio processing, edge ML (TFLite Micro)

### ESP32 2.8" Touchscreen (x3)

- **Chip:** ESP32 dual-core @ 240MHz
- **Display:** ILI9341 TFT 320x240, XPT2046 resistive touch
- **Memory:** 4MB Flash, 520KB SRAM
- **Connectivity:** WiFi + BLE
- **Interface:** SPI display
- **Use Cases:** Standalone sensor dashboards, room status displays

### Athena — Heltec WiFi LoRa 32 (x1)

- **Chip:** ESP32 + Semtech SX1276
- **Display:** 0.96" OLED (128x64, I2C)
- **LoRa:** 868/915MHz, up to 10km range
- **Connectivity:** WiFi + LoRa
- **IP:** 192.168.4.45
- **Agent Registry:** Registered as "Athena" (lora_mesh_node)
- **Use Cases:** Long-range sensor relay, remote monitoring, mesh backbone

### M5Stack Atom Lite (x2)

- **Chip:** ESP32-PICO-D4
- **Form Factor:** 24x24mm cube
- **Features:** Programmable button, SK6812 RGB LED, Grove port, IR LED
- **Connectivity:** WiFi + BLE
- **Use Cases:** IoT triggers, LED indicators, Grove sensor hub

---

## Arduino Family (5 units)

### ELEGOO UNO R3 (x2 kits)

- **Chip:** ATmega328P @ 16MHz
- **Memory:** 32KB Flash, 2KB SRAM
- **Kit Contents:** 200+ components including sensors, LEDs, motors, relays, LCD
- **Use Cases:** Learning, prototyping, sensor integration

### ATTINY88 (x3)

- **Chip:** AVR 8-bit @ 16MHz
- **Memory:** 8KB Flash, 512B SRAM
- **Interface:** I2C / SPI slave
- **Use Cases:** Dedicated low-power sensor readers, peripheral controllers

---

## Other (3 units)

### Raspberry Pi Pico (x2)

- **Chip:** RP2040 dual-core Cortex-M0+ @ 133MHz
- **Memory:** 2MB Flash, 264KB SRAM
- **Interface:** USB 1.1, 26 GPIO pins
- **Languages:** MicroPython, CircuitPython, C/C++
- **Use Cases:** Real-time I/O, PIO state machines, breadboard projects

### WCH CH32V003 (x1)

- **Chip:** RISC-V (QingKe V2A core) @ 48MHz
- **Memory:** 16KB Flash, 2KB SRAM
- **Interface:** USB
- **Cost:** ~$0.10/unit
- **Use Cases:** RISC-V experimentation, ultra-low-cost embedded

---

## Flashing & Development Tools

| Tool | Boards | Install |
|------|--------|---------|
| `esptool.py` | All ESP32 | `pip install esptool` |
| `espflash` | All ESP32 | `cargo install espflash` |
| `arduino-cli` | UNO, ATTINY, ESP32 | `brew install arduino-cli` |
| PlatformIO | All boards | VS Code extension |
| `picotool` | Pico RP2040 | `brew install picotool` |
| `wchisp` | WCH CH32V003 | `cargo install wchisp` |

### Serial Monitor

```bash
screen /dev/ttyUSB0 115200    # Linux
screen /dev/tty.usbserial-* 115200  # macOS
minicom -D /dev/ttyUSB0 -b 115200
```

### Management Script

```bash
~/mcus.sh        # Interactive MCU fleet menu
~/espflash.sh    # ESP32 flashing workflow
~/i2c.sh         # I2C bus scanning
~/lora.sh        # LoRa network tools
```
