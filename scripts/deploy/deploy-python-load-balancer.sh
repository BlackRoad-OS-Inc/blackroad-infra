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
# Deploy Python-based load balancer (no sudo needed)
# Provides failover between octavia and cecilia

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RESET='\033[0m'

echo -e "${PINK}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║   ⚖️  Python Load Balancer Deployment                 ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Deploy to octavia
echo -e "${BLUE}📦 Deploying to octavia...${RESET}"
ssh octavia "mkdir -p ~/load-balancer"

cat > /tmp/lb-app.py << 'EOF'
#!/usr/bin/env python3
"""
BlackRoad Load Balancer
Provides failover routing between octavia and cecilia
"""
from flask import Flask, request, Response, jsonify
import requests
from requests.exceptions import RequestException, Timeout
import time

app = Flask(__name__)

# Backend configuration
BACKENDS = {
    'tts': [
        ('http://localhost:5001', 'octavia-local'),
        ('http://cecilia:5001', 'cecilia')
    ],
    'monitor': [
        ('http://localhost:5002', 'octavia-local'),
        ('http://cecilia:5002', 'cecilia')
    ]
}

def try_backends(service, path, method='GET', **kwargs):
    """Try backends in order until one succeeds."""
    backends = BACKENDS.get(service, [])
    last_error = None
    
    for backend_url, backend_name in backends:
        try:
            url = f"{backend_url}{path}"
            timeout = kwargs.pop('timeout', 5)
            
            if method == 'GET':
                resp = requests.get(url, timeout=timeout, **kwargs)
            elif method == 'POST':
                resp = requests.post(url, timeout=timeout, **kwargs)
            else:
                resp = requests.request(method, url, timeout=timeout, **kwargs)
            
            resp.raise_for_status()
            return resp, backend_name
            
        except (RequestException, Timeout) as e:
            last_error = e
            continue
    
    # All backends failed
    raise Exception(f"All backends failed. Last error: {last_error}")

@app.route('/tts', defaults={'path': ''}, methods=['GET', 'POST'])
@app.route('/tts/<path:path>', methods=['GET', 'POST'])
def tts_proxy(path):
    """Proxy TTS requests with failover."""
    full_path = '/' + path if path else '/'
    
    try:
        resp, backend = try_backends(
            'tts',
            full_path,
            method=request.method,
            headers=dict(request.headers),
            data=request.get_data(),
            params=request.args
        )
        
        return Response(
            resp.content,
            status=resp.status_code,
            headers=dict(resp.headers),
            content_type=resp.headers.get('Content-Type')
        )
    
    except Exception as e:
        return jsonify({
            "error": "All TTS backends unavailable",
            "message": str(e)
        }), 503

@app.route('/monitor', defaults={'path': ''})
@app.route('/monitor/<path:path>')
def monitor_proxy(path):
    """Proxy Monitor requests with failover."""
    full_path = '/' + path if path else '/'
    
    try:
        resp, backend = try_backends(
            'monitor',
            full_path,
            headers=dict(request.headers),
            params=request.args
        )
        
        return Response(
            resp.content,
            status=resp.status_code,
            headers=dict(resp.headers),
            content_type=resp.headers.get('Content-Type')
        )
    
    except Exception as e:
        return jsonify({
            "error": "All Monitor backends unavailable",
            "message": str(e)
        }), 503

@app.route('/health')
def health():
    """Load balancer health check."""
    backend_status = {}
    
    # Check TTS backends
    for url, name in BACKENDS['tts']:
        try:
            resp = requests.get(f"{url}/health", timeout=2)
            backend_status[f"tts-{name}"] = resp.status_code == 200
        except:
            backend_status[f"tts-{name}"] = False
    
    # Check Monitor backends
    for url, name in BACKENDS['monitor']:
        try:
            resp = requests.get(f"{url}/health", timeout=2)
            backend_status[f"monitor-{name}"] = resp.status_code == 200
        except:
            backend_status[f"monitor-{name}"] = False
    
    return jsonify({
        "service": "load-balancer",
        "status": "healthy",
        "backends": backend_status,
        "endpoints": ["/tts", "/monitor", "/health"]
    })

@app.route('/')
def home():
    return jsonify({
        "service": "BlackRoad Load Balancer",
        "version": "0.1.0",
        "endpoints": {
            "tts": "/tts",
            "monitor": "/monitor",
            "health": "/health"
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5100)
EOF

scp /tmp/lb-app.py octavia:~/load-balancer/app.py
ssh octavia "chmod +x ~/load-balancer/app.py"

# Install requests
ssh octavia "pip3 install --user requests 2>/dev/null || true"

echo -e "${GREEN}✅ Application deployed${RESET}"
echo ""

# Create systemd service
echo -e "${BLUE}⚙️  Creating systemd service...${RESET}"

cat > /tmp/lb-service << 'EOF'
[Unit]
Description=BlackRoad Python Load Balancer
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/blackroad/load-balancer/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

scp /tmp/lb-service octavia:~/.config/systemd/user/load-balancer.service

ssh octavia "systemctl --user daemon-reload"
ssh octavia "systemctl --user enable load-balancer"
ssh octavia "systemctl --user restart load-balancer"

echo -e "${GREEN}✅ Service started${RESET}"
echo ""

# Test
echo -e "${BLUE}🧪 Testing load balancer...${RESET}"
sleep 3

echo ""
echo "Load Balancer Health:"
ssh octavia "curl -s http://localhost:5100/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:5100/health"

echo ""
echo "TTS via Load Balancer:"
ssh octavia "curl -s http://localhost:5100/tts/health 2>&1 | head -5"

echo ""
echo "Monitor via Load Balancer:"
ssh octavia "curl -s http://localhost:5100/monitor/health 2>&1 | head -5"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✅ Load Balancer Live on Port 5100!                  ║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Endpoints:"
echo "  http://octavia:5100/tts      (with cecilia failover)"
echo "  http://octavia:5100/monitor  (with cecilia failover)"
echo "  http://octavia:5100/health   (backend status)"
echo ""
