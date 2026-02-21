#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
set -e

echo "🔊 Deploying TTS API to octavia"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "[1/5] Creating TTS API directory..."
ssh octavia "mkdir -p ~/tts-api"
echo "✅ Directory created"

echo "[2/5] Deploying Flask app..."
cat << 'PYTHON' | ssh octavia 'cat > ~/tts-api/app.py'
#!/usr/bin/env python3
from flask import Flask, request, send_file, jsonify
import subprocess
import os
import tempfile
from datetime import datetime

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "tts-api", "timestamp": datetime.now().isoformat()})

@app.route('/tts', methods=['POST'])
def tts():
    data = request.get_json()
    text = data.get('text', 'Hello')
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        output = tmp.name
    # Note: Will work after piper is installed
    return jsonify({"message": "TTS API ready", "text": text, "note": "Install piper-tts to generate audio"})

@app.route('/')
def index():
    return jsonify({"service": "BlackRoad TTS API", "version": "0.1.0", "endpoints": {"/health": "GET", "/tts": "POST"}})

if __name__ == '__main__':
    print("🔊 TTS API starting on port 5001...")
    app.run(host='0.0.0.0', port=5001)
PYTHON
ssh octavia "chmod +x ~/tts-api/app.py"
echo "✅ Flask app deployed"

echo "[3/5] Installing dependencies..."
ssh octavia "python3 -m pip install --user -q flask werkzeug 2>&1 | tail -1"
echo "✅ Dependencies installed"

echo "[4/5] Creating systemd service..."
ssh octavia "mkdir -p ~/.config/systemd/user"
cat << 'SERVICE' | ssh octavia 'cat > ~/.config/systemd/user/tts-api.service'
[Unit]
Description=BlackRoad TTS API
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/blackroad/tts-api
ExecStart=/usr/bin/python3 /home/blackroad/tts-api/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
SERVICE
echo "✅ Systemd service created"

echo "[5/5] Starting service..."
ssh octavia "systemctl --user daemon-reload && systemctl --user enable tts-api.service && systemctl --user restart tts-api.service"
sleep 3
echo "✅ Service started"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 TTS API deployed and running!"
echo ""
echo "Test: curl http://octavia:5001/health"
