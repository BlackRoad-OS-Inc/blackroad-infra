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
# Deploy TTS and Monitoring services to cecilia
# Mirrors octavia deployment but for cecilia node

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RESET='\033[0m'

echo -e "${PINK}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║   🚀 Deploy Services to Cecilia                        ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# 1. Deploy TTS API
echo -e "${BLUE}📦 Deploying TTS API...${RESET}"
ssh cecilia "mkdir -p ~/tts-api"

cat > /tmp/cecilia-tts-app.py << 'EOF'
#!/usr/bin/env python3
from flask import Flask, request, jsonify, send_file
import subprocess
import tempfile
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "service": "BlackRoad TTS API",
        "version": "0.1.0",
        "node": "cecilia",
        "endpoints": ["/health", "/tts"]
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "tts-api", "node": "cecilia"})

@app.route('/tts', methods=['POST'])
def text_to_speech():
    data = request.json
    if not data or 'text' not in data:
        return jsonify({"error": "Missing 'text' field"}), 400
    
    text = data['text']
    
    # Check if piper is available
    try:
        subprocess.run(['which', 'piper'], check=True, capture_output=True)
        
        # Generate speech with piper
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
            tmp_path = tmp.name
        
        subprocess.run([
            'piper',
            '--model', '/home/operator/piper-models/en_US-lessac-medium.onnx',
            '--output_file', tmp_path
        ], input=text.encode(), check=True)
        
        return send_file(tmp_path, mimetype='audio/wav')
    
    except (subprocess.CalledProcessError, FileNotFoundError):
        # Piper not installed - return placeholder
        return jsonify({
            "status": "success",
            "message": "TTS placeholder (piper not installed)",
            "text": text,
            "audio": None
        })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
EOF

scp /tmp/cecilia-tts-app.py cecilia:~/tts-api/app.py
ssh cecilia "chmod +x ~/tts-api/app.py"

# Install Flask if needed
ssh cecilia "pip3 install --user flask werkzeug 2>/dev/null || true"

echo -e "${GREEN}✅ TTS API deployed${RESET}"
echo ""

# 2. Create systemd service for TTS
echo -e "${BLUE}⚙️  Creating TTS systemd service...${RESET}"

ssh cecilia "mkdir -p ~/.config/systemd/user"

cat > /tmp/cecilia-tts-service << 'EOF'
[Unit]
Description=BlackRoad TTS API (Cecilia)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/operator/tts-api/app.py
Restart=always
RestartSec=10
Environment="FLASK_ENV=production"

[Install]
WantedBy=default.target
EOF

scp /tmp/cecilia-tts-service cecilia:~/.config/systemd/user/tts-api.service

ssh cecilia "systemctl --user daemon-reload"
ssh cecilia "systemctl --user enable tts-api"
ssh cecilia "systemctl --user restart tts-api"

echo -e "${GREEN}✅ TTS service started${RESET}"
echo ""

# 3. Deploy Monitoring API
echo -e "${BLUE}📊 Deploying Monitoring API...${RESET}"
ssh cecilia "mkdir -p ~/monitoring"

cat > /tmp/cecilia-monitor.py << 'EOF'
#!/usr/bin/env python3
from flask import Flask, jsonify
import subprocess
import psutil
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "service": "BlackRoad Monitoring API",
        "version": "0.1.0",
        "node": "cecilia",
        "endpoints": ["/health", "/status"]
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "monitor-api", "node": "cecilia"})

@app.route('/status')
def status():
    def check_service(name):
        try:
            result = subprocess.run(['systemctl', 'is-active', name], 
                                  capture_output=True, text=True, timeout=2)
            return result.stdout.strip() == 'active'
        except:
            return False
    
    def check_user_service(name):
        try:
            result = subprocess.run(['systemctl', '--user', 'is-active', name], 
                                  capture_output=True, text=True, timeout=2)
            return result.stdout.strip() == 'active'
        except:
            return False
    
    def check_port(port):
        try:
            result = subprocess.run(['curl', '-s', '-o', '/dev/null', '-w', '%{http_code}',
                                   f'http://localhost:{port}/health'],
                                  capture_output=True, text=True, timeout=5)
            return result.stdout.strip() == '200'
        except:
            return False
    
    cpu = psutil.cpu_percent(interval=1)
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    return jsonify({
        "node": "cecilia",
        "timestamp": subprocess.check_output(['date', '-u', '+%Y-%m-%dT%H:%M:%SZ']).decode().strip(),
        "services": {
            "ollama": check_service("ollama"),
            "cloudflared": check_service("cloudflared"),
            "tts-api": check_user_service("tts-api"),
            "monitor-api": check_user_service("monitor-api")
        },
        "endpoints": {
            "ollama": check_port(11434),
            "tts-api": check_port(5001),
            "monitor-api": check_port(5002)
        },
        "resources": {
            "cpu_percent": cpu,
            "memory_used_gb": round(mem.used / 1024**3, 1),
            "memory_total_gb": round(mem.total / 1024**3, 1),
            "disk_used_gb": round(disk.used / 1024**3, 1),
            "disk_total_gb": round(disk.total / 1024**3, 1)
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
EOF

scp /tmp/cecilia-monitor.py cecilia:~/monitoring/monitor-api.py
ssh cecilia "chmod +x ~/monitoring/monitor-api.py"

# Install psutil
ssh cecilia "pip3 install --user psutil 2>/dev/null || true"

echo -e "${GREEN}✅ Monitoring API deployed${RESET}"
echo ""

# 4. Create systemd service for monitoring
echo -e "${BLUE}⚙️  Creating Monitoring systemd service...${RESET}"

cat > /tmp/cecilia-monitor-service << 'EOF'
[Unit]
Description=BlackRoad Monitoring API (Cecilia)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/operator/monitoring/monitor-api.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

scp /tmp/cecilia-monitor-service cecilia:~/.config/systemd/user/monitor-api.service

ssh cecilia "systemctl --user daemon-reload"
ssh cecilia "systemctl --user enable monitor-api"
ssh cecilia "systemctl --user restart monitor-api"

echo -e "${GREEN}✅ Monitoring service started${RESET}"
echo ""

# 5. Test all services
echo -e "${BLUE}🧪 Testing services on cecilia...${RESET}"
sleep 3

echo ""
echo "TTS API:"
ssh cecilia "curl -s http://localhost:5001/health" || echo "  ❌ Not responding"

echo ""
echo "Monitor API:"
ssh cecilia "curl -s http://localhost:5002/health" || echo "  ❌ Not responding"

echo ""
echo "Service Status:"
ssh cecilia "systemctl --user status tts-api --no-pager | head -5"
echo ""
ssh cecilia "systemctl --user status monitor-api --no-pager | head -5"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✅ Cecilia Services Deployed!                        ║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Endpoints:"
echo "  http://cecilia:5001/health  (TTS API)"
echo "  http://cecilia:5002/status  (Monitoring)"
echo ""
