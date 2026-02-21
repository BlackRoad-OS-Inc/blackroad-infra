# AI Compute Accelerators

Total fleet AI compute: **~135 TOPS** across Hailo-8, NVIDIA Jetson, Apple M1, and Arm Ethos-U55.

---

## Accelerator Inventory

| # | Accelerator | Node | Architecture | TOPS | Interface | Serial | Status |
|---|-------------|------|-------------|------|-----------|--------|--------|
| 1 | Hailo-8 M.2 | Cecilia | Hailo-8 | 26 | M.2 PCIe | HLLWM2B233704667 | Active |
| 2 | Hailo-8 M.2 | Octavia | Hailo-8 | 26 | M.2 PCIe | HLLWM2B233704606 | Active |
| 3 | Hailo-8 M.2 | Aria | Hailo-8 | 26 | M.2 PCIe | — | Active |
| 4 | Jetson Orin Nano GPU | Jetson-Agent | NVIDIA Ampere | 40 | Onboard | — | Pending |
| 5 | Apple M1 Neural Engine | Alexandria | Apple NE | 15.8 | Onboard | — | Active |
| 6 | Himax Ethos-U55 NPU | SenseCAP W1-A | Arm Ethos-U55 | ~1 | Onboard | — | Returned |

### Compute Budget

| Category | TOPS | Status |
|----------|------|--------|
| Hailo-8 (3x) | 78 | Active |
| NVIDIA Jetson Orin Nano | 40 | Pending setup |
| Apple M1 Neural Engine | 15.8 | Active |
| Arm Ethos-U55 | ~1 | Returned |
| **Total Active** | **93.8** | |
| **Total (incl. pending)** | **~135** | |

---

## Hailo-8 M.2 Modules (3 units)

### Specifications

| Spec | Value |
|------|-------|
| Architecture | Hailo-8 |
| Compute | 26 TOPS (INT8) |
| Interface | M.2 Key M (PCIe Gen 3.0 x1) |
| Power | ~2.5W typical |
| Price | $214.99 each |
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

### Benchmark Results

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

### Status

Pending initial setup. Dev kit available with 10.1" ROADOM touchscreen.

---

## Apple M1 Neural Engine

### Specifications

| Spec | Value |
|------|-------|
| Architecture | Apple Neural Engine (16-core) |
| AI Compute | 15.8 TOPS |
| Host | MacBook Pro M1 (Alexandria) |
| Framework | CoreML, MLX |
| Power | Integrated (shared power budget) |

### Capabilities

- CoreML model inference (Vision, NLP, Audio)
- Ollama via Metal GPU acceleration
- MLX framework for on-device ML
- Whisper transcription
- Stable Diffusion (via MLX)

---

## Arm Ethos-U55 NPU (SenseCAP Watcher — Returned)

### Specifications

| Spec | Value |
|------|-------|
| Architecture | Arm Ethos-U55 microNPU |
| Host Processor | Arm Cortex-M55 (Himax HX6538) |
| AI Compute | ~1 TOPS (INT8) |
| Device | SenseCAP Watcher W1-A |
| Status | Returned (August 2025) |

### Capabilities (When Active)

- Person/animal/gesture detection via camera
- Low-power always-on vision inference
- Voice keyword detection
- Designed for battery-powered edge AI

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

---

## Power Efficiency Comparison

| Accelerator | TOPS | Power (W) | TOPS/W | Notes |
|-------------|------|-----------|--------|-------|
| Hailo-8 | 26 | 2.5 | **10.4** | Best efficiency |
| Jetson Orin Nano | 40 | 15 | 2.7 | Most versatile |
| M1 Neural Engine | 15.8 | ~5 | 3.2 | Integrated in laptop |
| Ethos-U55 | ~1 | 0.05 | 20.0 | Ultra-low-power (returned) |
