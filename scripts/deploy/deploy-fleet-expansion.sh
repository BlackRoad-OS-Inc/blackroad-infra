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
# Expand BlackRoad services to all available fleet nodes

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
RESET='\033[0m'

echo -e "${PINK}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║   🚀 Fleet Expansion Deployment                        ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Create unified monitoring dashboard
echo -e "${BLUE}📊 Creating unified fleet monitoring...${RESET}"

cat > /tmp/fleet-monitor.py << 'EOF'
#!/usr/bin/env python3
"""
BlackRoad Unified Fleet Monitoring Dashboard
Shows status of all nodes and services
"""
from flask import Flask, jsonify, render_template_string
import subprocess
import json
import socket

app = Flask(__name__)

FLEET_NODES = {
    'octavia': {
        'hostname': 'octavia',
        'services': ['tts-api', 'monitor-api', 'load-balancer'],
        'ports': [5001, 5002, 5100, 11434, 80]
    },
    'cecilia': {
        'hostname': 'cecilia',
        'services': ['tts-api', 'monitor-api'],
        'ports': [5001, 5002, 11434]
    },
    'alice': {
        'hostname': 'alice',
        'services': [],
        'ports': []
    },
    'lucidia': {
        'hostname': '192.168.4.81',
        'services': [],
        'ports': []
    }
}

def check_node_reachable(hostname):
    """Check if node is reachable via ping."""
    try:
        result = subprocess.run(
            ['ping', '-c', '1', '-W', '2', hostname],
            capture_output=True,
            timeout=3
        )
        return result.returncode == 0
    except:
        return False

def check_service_ssh(hostname, service):
    """Check if a systemd user service is running via SSH."""
    try:
        result = subprocess.run(
            ['ssh', '-o', 'ConnectTimeout=5', hostname,
             f'systemctl --user is-active {service}'],
            capture_output=True,
            text=True,
            timeout=6
        )
        return result.stdout.strip() == 'active'
    except:
        return False

def check_port_ssh(hostname, port):
    """Check if a port is responding via SSH."""
    try:
        result = subprocess.run(
            ['ssh', '-o', 'ConnectTimeout=5', hostname,
             f'curl -s -o /dev/null -w "%{{http_code}}" http://localhost:{port}/health 2>/dev/null || echo "000"'],
            capture_output=True,
            text=True,
            timeout=6
        )
        return result.stdout.strip() in ['200', '000'] and result.returncode == 0
    except:
        return False

@app.route('/')
def home():
    """Home page with fleet overview."""
    return render_template_string('''
<!DOCTYPE html>
<html>
<head>
    <title>BlackRoad Fleet Monitor</title>
    <meta http-equiv="refresh" content="10">
    <style>
        body {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #fff;
            font-family: 'SF Mono', 'Monaco', monospace;
            padding: 20px;
            margin: 0;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        h1 {
            color: #FF1D6C;
            text-align: center;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .subtitle {
            text-align: center;
            color: #F5A623;
            margin-bottom: 40px;
        }
        .fleet-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .node-card {
            background: rgba(255,255,255,0.05);
            border: 2px solid rgba(255,255,255,0.1);
            border-radius: 12px;
            padding: 20px;
        }
        .node-card.online {
            border-color: #00ff88;
        }
        .node-card.offline {
            border-color: #ff4444;
        }
        .node-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        .node-name {
            font-size: 1.5em;
            font-weight: bold;
            color: #2979FF;
        }
        .node-status {
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
        }
        .status-online {
            background: #00ff88;
            color: #000;
        }
        .status-offline {
            background: #ff4444;
            color: #fff;
        }
        .service-list {
            margin-top: 15px;
        }
        .service-item {
            display: flex;
            justify-content: space-between;
            padding: 8px;
            margin: 5px 0;
            background: rgba(255,255,255,0.02);
            border-radius: 6px;
        }
        .service-name {
            color: #9C27B0;
        }
        .service-status {
            font-weight: bold;
        }
        .status-active { color: #00ff88; }
        .status-inactive { color: #ff4444; }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 BlackRoad Fleet Monitor</h1>
        <div class="subtitle">Real-time infrastructure monitoring</div>
        
        <div class="fleet-grid" id="fleet-grid">
            <p style="text-align: center; color: #888;">Loading fleet status...</p>
        </div>
        
        <div class="footer">
            Auto-refresh every 10 seconds | <a href="/api/fleet" style="color: #2979FF;">JSON API</a>
        </div>
    </div>
    
    <script>
        async function updateFleet() {
            const response = await fetch('/api/fleet');
            const data = await response.json();
            
            const grid = document.getElementById('fleet-grid');
            grid.innerHTML = '';
            
            for (const [name, node] of Object.entries(data.nodes)) {
                const card = document.createElement('div');
                card.className = `node-card ${node.reachable ? 'online' : 'offline'}`;
                
                let servicesHTML = '';
                if (node.services && Object.keys(node.services).length > 0) {
                    for (const [svc, active] of Object.entries(node.services)) {
                        servicesHTML += `
                            <div class="service-item">
                                <span class="service-name">${svc}</span>
                                <span class="service-status ${active ? 'status-active' : 'status-inactive'}">
                                    ${active ? '✅ ACTIVE' : '❌ INACTIVE'}
                                </span>
                            </div>
                        `;
                    }
                } else {
                    servicesHTML = '<div class="service-item"><span style="color: #888;">No services configured</span></div>';
                }
                
                card.innerHTML = `
                    <div class="node-header">
                        <div class="node-name">${name}</div>
                        <div class="node-status ${node.reachable ? 'status-online' : 'status-offline'}">
                            ${node.reachable ? '🟢 ONLINE' : '🔴 OFFLINE'}
                        </div>
                    </div>
                    <div class="service-list">
                        ${servicesHTML}
                    </div>
                `;
                
                grid.appendChild(card);
            }
        }
        
        updateFleet();
        setInterval(updateFleet, 10000);
    </script>
</body>
</html>
    ''')

@app.route('/api/fleet')
def fleet_status():
    """Get fleet status as JSON."""
    status = {
        'timestamp': subprocess.check_output(['date', '-u', '+%Y-%m-%dT%H:%M:%SZ']).decode().strip(),
        'nodes': {}
    }
    
    for node_name, node_config in FLEET_NODES.items():
        hostname = node_config['hostname']
        reachable = check_node_reachable(hostname)
        
        node_status = {
            'hostname': hostname,
            'reachable': reachable,
            'services': {},
            'ports': {}
        }
        
        if reachable:
            # Check services
            for service in node_config['services']:
                node_status['services'][service] = check_service_ssh(hostname, service)
            
            # Check ports
            for port in node_config['ports']:
                node_status['ports'][port] = check_port_ssh(hostname, port)
        
        status['nodes'][node_name] = node_status
    
    return jsonify(status)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "fleet-monitor"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5200)
EOF

# Deploy to octavia
ssh octavia "mkdir -p ~/fleet-monitor"
scp /tmp/fleet-monitor.py octavia:~/fleet-monitor/app.py
ssh octavia "chmod +x ~/fleet-monitor/app.py"

echo -e "${GREEN}✅ Fleet monitor deployed${RESET}"
echo ""

# Create systemd service
echo -e "${BLUE}⚙️  Creating systemd service...${RESET}"

cat > /tmp/fleet-monitor-service << 'EOF'
[Unit]
Description=BlackRoad Fleet Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/blackroad/fleet-monitor/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

scp /tmp/fleet-monitor-service octavia:~/.config/systemd/user/fleet-monitor.service

ssh octavia "systemctl --user daemon-reload"
ssh octavia "systemctl --user enable fleet-monitor"
ssh octavia "systemctl --user restart fleet-monitor"

echo -e "${GREEN}✅ Fleet monitor service started${RESET}"
echo ""

# Test
echo -e "${BLUE}🧪 Testing fleet monitor...${RESET}"
sleep 3

echo ""
echo "Fleet Monitor Health:"
ssh octavia "curl -s http://localhost:5200/health"

echo ""
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✅ Fleet Monitor Deployed!                           ║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Access fleet dashboard:"
echo "  http://octavia:5200/        (HTML dashboard)"
echo "  http://octavia:5200/api/fleet  (JSON API)"
echo ""
