# AI Compute Accelerators — Live Verified

**Verified via SSH probes on 2026-02-21.**

> **UPDATE 2026-02-21:** Lucidia came back online and has a **second Hailo-8** confirmed!
> `hailort.service` running on both Cecilia and Lucidia. Octavia and Aria have no Hailo.
> 1 of 3 purchased modules remains unaccounted for.

**Confirmed fleet AI compute: ~67.8 TOPS active** (2x Hailo-8 + M1 Neural Engine)

---

## Accelerator Inventory

| # | Accelerator | Node | TOPS | Interface | Status | Verification |
|---|-------------|------|------|-----------|--------|-------------|
| 1 | Hailo-8 M.2 | Cecilia | 26 | M.2 PCIe | **Active** | `hailort.service` running, `/dev/hailo0` present |
| 2 | Hailo-8 M.2 | Lucidia | 26 | M.2 PCIe | **Active** | `hailort.service` running (confirmed 2026-02-21) |
| 3 | Hailo-8 M.2 | Octavia | 26 | M.2 PCIe | **NOT DETECTED** | No `/dev/hailo*`, no `hailort.service` |
| — | Hailo-8 M.2 | Aria | — | M.2 PCIe | **NOT DETECTED** | No `/dev/hailo*`, no `hailort.service` |
| 4 | Jetson Orin Nano GPU | Jetson-Agent | 40 | Onboard | **Pending** | Dev kit not deployed |
| 5 | Apple M1 Neural Engine | Alexandria | 15.8 | Onboard | **Active** | Mac in use daily |
| 6 | Himax Ethos-U55 NPU | SenseCAP W1-A | ~1 | Onboard | **Returned** | Returned Aug 2025 |

### Compute Budget — Corrected

| Category | TOPS | Status | Notes |
|----------|------|--------|-------|
| Hailo-8 (2x confirmed) | 52 | **Active** | Cecilia + Lucidia |
| Hailo-8 (1x unverified) | 26 | **Unknown** | 3rd module purchased, not detected on Octavia or Aria |
| NVIDIA Jetson Orin Nano | 40 | **Pending** | Dev kit not deployed |
| Apple M1 Neural Engine | 15.8 | **Active** | Alexandria Mac |
| Arm Ethos-U55 | ~1 | **Returned** | SenseCAP Watcher |
| **Confirmed Active** | **67.8** | | 2x Hailo-8 + M1 |
| **Potential (if all working)** | **~135** | | +1 Hailo-8 + Jetson |

---

## Missing Hailo-8 Investigation

3 Hailo-8 M.2 modules were purchased (serial numbers documented: HLLWM2B233704667, HLLWM2B233704606, third unknown). 2 are confirmed active: Cecilia and Lucidia. 1 remains unaccounted for.

### Possible Explanations

1. **Not physically installed** — M.2 modules may still be in packaging or stored separately
2. **Installed but no drivers** — HailoRT runtime not installed on Octavia/Aria
3. **Hardware fault** — M.2 slot or module not functioning
4. **Wrong slot** — Pironman case M.2 slot may be configured for NVMe, not AI accelerator

### Verification Steps

```bash
# On Octavia (ssh octavia):
ls /dev/hailo*                    # Check for Hailo device nodes
systemctl status hailort          # Check for Hailo runtime service
lspci | grep -i hailo             # Check PCIe bus for Hailo device
dpkg -l | grep hailo              # Check if HailoRT packages installed

# On Aria (ssh aria):
ls /dev/hailo*
systemctl status hailort
lspci | grep -i hailo
dpkg -l | grep hailo

# Physical inspection required:
# 1. Open Pironman cases on Octavia and Aria
# 2. Check M.2 Key M slot — is a Hailo-8 card present?
# 3. If present, install HailoRT: sudo apt install hailort
```

---

## Hailo-8 M.2 Module

### Specifications

| Spec | Value |
|------|-------|
| Architecture | Hailo-8 |
| Compute | 26 TOPS (INT8) |
| Interface | M.2 Key M (PCIe Gen 3.0 x1) |
| Power | ~2.5W typical |
| Price | $214.99 each (3x = $644.97 total) |
| Compatible Hosts | Raspberry Pi 5 (via HAT), Pironman case |

### Software Stack

- **HailoRT:** Runtime library for model execution
- **Hailo Model Zoo:** Pre-compiled HEF files
- **Hailo TAPPAS:** Application examples and pipelines
- **Hailo Dataflow Compiler:** Convert ONNX/TF models to HEF format

### Detection & Management

```bash
# Detect Hailo devices
hailortcli scan

# Identify firmware version
hailortcli fw-control identify

# Run inference benchmark
hailortcli benchmark --hef /usr/share/hailo-models/yolov5m_wo_spp_60p.hef

# List installed models
ls /usr/share/hailo-models/*.hef

# Check installed packages
dpkg -l | grep hailo

# Management script
~/hailo.sh
```

### Benchmark Results (Cecilia only)

Hailo-8 vs NVIDIA Jetson benchmarks (from BlackRoad testing):
- **Power Efficiency:** 15-30x more efficient than NVIDIA Jetson (TOPS/Watt)
- **YOLOv5m:** Real-time 30+ FPS at 2.5W power draw
- **Latency:** Sub-10ms inference for object detection

### Model Compatibility

| Model | Format | Use Case | Status |
|-------|--------|----------|--------|
| YOLOv5m | HEF | Object detection | Compiled |
| YOLOv8n/s/m | HEF | Object detection | Compiled |
| ResNet-50 | HEF | Image classification | Compiled |
| MobileNet v2 | HEF | Classification (lightweight) | Compiled |
| SSD MobileNet | HEF | Detection (lightweight) | Compiled |
| Custom models | ONNX → HEF | Via Dataflow Compiler | Supported |

---

## Ollama Deployment (4 nodes)

Ollama runs on 4 of 6 reachable nodes, providing LLM inference across the fleet:

| Node | Binding | Security | Status |
|------|---------|----------|--------|
| Cecilia | 127.0.0.1:11434 | Localhost only | **Secure** |
| Octavia | 127.0.0.1:11434 | Localhost only | **Secure** |
| Shellfish | 100.64.0.1:11434 | Tailscale interface | **Secure** |
| Codex-Infinity | **0.0.0.0:11434** | **ALL INTERFACES** | **INSECURE** |

> **ACTION:** Fix Codex-Infinity Ollama binding immediately. Public IP 159.65.43.12:11434 is
> accessible to anyone on the internet.

---

## NVIDIA Jetson Orin Nano

### Specifications

| Spec | Value |
|------|-------|
| GPU | NVIDIA Ampere (1024 CUDA cores) |
| AI Compute | 40 TOPS (INT8) |
| CPU | 6-core Arm Cortex-A78AE |
| RAM | 8GB LPDDR5 |
| Storage | microSD + NVMe M.2 |
| Power | 7-15W configurable TDP |
| Price | $114.29 (base dev kit) |
| Display | HDMI + DisplayPort |
| Status | **Pending initial setup** |

### Software Stack

- **JetPack SDK:** Ubuntu-based OS with CUDA, cuDNN, TensorRT
- **TensorRT:** Optimized inference engine
- **DeepStream:** Video analytics SDK
- **Ollama:** LLM inference via CUDA

### Capabilities

| Task | Framework | Notes |
|------|-----------|-------|
| LLM inference | Ollama (CUDA) | Llama 2 7B, Mistral 7B |
| Object detection | TensorRT | YOLOv8 real-time |
| Speech-to-text | Whisper (CUDA) | Real-time transcription |
| Image generation | Stable Diffusion | Small models only (8GB RAM) |
| Video analytics | DeepStream | Multi-stream pipeline |

---

## Apple M1 Neural Engine

| Spec | Value |
|------|-------|
| Architecture | Apple Neural Engine (16-core) |
| AI Compute | 15.8 TOPS |
| Host | MacBook Pro M1 (Alexandria) |
| Framework | CoreML, MLX |
| Status | **Active** (daily use) |

---

## Arm Ethos-U55 NPU (SenseCAP Watcher — Returned)

| Spec | Value |
|------|-------|
| Architecture | Arm Ethos-U55 microNPU |
| Host Processor | Arm Cortex-M55 (Himax HX6538) |
| AI Compute | ~1 TOPS (INT8) |
| Device | SenseCAP Watcher W1-A |
| Status | **Returned** (August 2025) |

---

## Power Efficiency Comparison

| Accelerator | TOPS | Power (W) | TOPS/W | Status |
|-------------|------|-----------|--------|--------|
| Hailo-8 | 26 | 2.5 | **10.4** | 1 active, 2 unverified |
| Jetson Orin Nano | 40 | 15 | 2.7 | Pending setup |
| M1 Neural Engine | 15.8 | ~5 | 3.2 | Active |
| Ethos-U55 | ~1 | 0.05 | 20.0 | Returned |

---

## Model Compatibility Matrix

| Model | Hailo-8 (HEF) | Jetson (TRT) | M1 (CoreML) | Ethos-U55 (TFLite) |
|-------|---------------|--------------|-------------|---------------------|
| YOLOv5m | Yes | Yes | Yes | — |
| YOLOv8n | Yes | Yes | Yes | — |
| ResNet-50 | Yes | Yes | Yes | — |
| MobileNet v2 | Yes | Yes | Yes | Yes |
| Llama 2 7B | — | Yes (CUDA) | Yes (Metal) | — |
| Whisper | — | Yes (CUDA) | Yes (Metal) | — |
| Stable Diffusion | — | Yes (limited) | Yes (MLX) | — |
| Person Detection | Yes | Yes | Yes | Yes |
