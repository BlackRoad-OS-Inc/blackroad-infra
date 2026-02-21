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

echo "📊 Deploying Monitoring Dashboard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "[1/4] Creating monitoring directory..."
ssh octavia "mkdir -p ~/monitoring"
echo "✅ Directory created"

echo "[2/4] Creating health check script..."
cat << 'MONITOR' | ssh octavia 'cat > ~/monitoring/health-check.sh'
#!/bin/bash
# Health check all services

echo "🏥 BlackRoad Health Check - $(date)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# nginx
if systemctl is-active --quiet nginx; then
    echo "✅ nginx: RUNNING"
else
    echo "❌ nginx: DOWN"
fi

# ollama
if systemctl is-active --quiet ollama; then
    echo "✅ ollama: RUNNING"
    curl -s http://localhost:11434/api/tags > /dev/null && echo "  └─ API responding" || echo "  └─ API not responding"
else
    echo "❌ ollama: DOWN"
fi

# cloudflared
if systemctl is-active --quiet cloudflared; then
    echo "✅ cloudflared: RUNNING"
else
    echo "❌ cloudflared: DOWN"
fi

# TTS API
if systemctl --user is-active --quiet tts-api; then
    echo "✅ tts-api: RUNNING"
    curl -s http://localhost:5001/health > /dev/null && echo "  └─ API responding" || echo "  └─ API not responding"
else
    echo "❌ tts-api: DOWN"
fi

echo ""
echo "System Resources:"
echo "  CPU: $(uptime | awk -F'load average:' '{print $2}')"
echo "  RAM: $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
echo "  Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
MONITOR
ssh octavia "chmod +x ~/monitoring/health-check.sh"
echo "✅ Health check script created"

echo "[3/4] Creating monitoring API..."
cat << 'PYTHON' | ssh octavia 'cat > ~/monitoring/monitor-api.py'
#!/usr/bin/env python3
from flask import Flask, jsonify
import subprocess
import json
from datetime import datetime

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "monitor-api"})

@app.route('/status')
def status():
    """Get all service statuses"""
    services = {}
    
    # Check systemd services
    for svc in ['nginx', 'ollama', 'cloudflared']:
        try:
            result = subprocess.run(['systemctl', 'is-active', svc], 
                                  capture_output=True, text=True, timeout=2)
            services[svc] = result.stdout.strip() == 'active'
        except:
            services[svc] = False
    
    # Check user services
    try:
        result = subprocess.run(['systemctl', '--user', 'is-active', 'tts-api'], 
                              capture_output=True, text=True, timeout=2)
        services['tts-api'] = result.stdout.strip() == 'active'
    except:
        services['tts-api'] = False
    
    # System metrics
    try:
        uptime_result = subprocess.run(['uptime'], capture_output=True, text=True)
        load = uptime_result.stdout.split('load average:')[1].strip()
    except:
        load = "unknown"
    
    return jsonify({
        "timestamp": datetime.now().isoformat(),
        "services": services,
        "system": {
            "load": load,
            "hostname": subprocess.run(['hostname'], capture_output=True, text=True).stdout.strip()
        }
    })

@app.route('/dashboard')
def dashboard():
    """HTML dashboard"""
    return """
<!DOCTYPE html>
<html><head><title>BlackRoad Monitoring</title>
<meta http-equiv="refresh" content="5">
<style>
body{background:#0a0a0a;color:#fff;font-family:monospace;padding:2rem}
.service{padding:1rem;margin:0.5rem 0;border:1px solid #333;border-radius:8px}
.active{border-color:#52FFA8;background:rgba(82,255,168,0.1)}
.inactive{border-color:#FF1D6C;background:rgba(255,29,108,0.1)}
h1{color:#FF1D6C}
</style></head><body>
<h1>🌌 BlackRoad Monitoring</h1>
<div id="status">Loading...</div>
<script>
fetch('/status').then(r=>r.json()).then(data=>{
    let html = '<h2>Services</h2>';
    for(let [name, active] of Object.entries(data.services)){
        html += `<div class="service ${active?'active':'inactive'}">
            ${active?'✅':'❌'} ${name}
        </div>`;
    }
    html += `<h2>System</h2><div class="service active">
        Load: ${data.system.load}<br>
        Hostname: ${data.system.hostname}<br>
        Updated: ${new Date(data.timestamp).toLocaleString()}
    </div>`;
    document.getElementById('status').innerHTML = html;
});
</script></body></html>
"""

if __name__ == '__main__':
    print("📊 Monitor API starting on port 5002...")
    app.run(host='0.0.0.0', port=5002)
PYTHON
ssh octavia "chmod +x ~/monitoring/monitor-api.py"
echo "✅ Monitor API created"

echo "[4/4] Starting monitor API..."
cat << 'SERVICE' | ssh octavia 'cat > ~/.config/systemd/user/monitor-api.service'
[Unit]
Description=BlackRoad Monitor API
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/blackroad/monitoring
ExecStart=/usr/bin/python3 /home/blackroad/monitoring/monitor-api.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
SERVICE

ssh octavia "systemctl --user daemon-reload && systemctl --user enable monitor-api.service && systemctl --user restart monitor-api.service"
sleep 2
echo "✅ Monitor API started"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Monitoring deployed!"
echo ""
echo "Endpoints:"
echo "  Health: http://octavia:5002/health"
echo "  Status: http://octavia:5002/status"
echo "  Dashboard: http://octavia:5002/dashboard"
echo ""
echo "CLI: ssh octavia '~/monitoring/health-check.sh'"
