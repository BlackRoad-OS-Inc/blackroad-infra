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
# Deploy advanced monitoring with metrics collection and analytics

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RESET='\033[0m'

echo -e "${PINK}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║   📈 Advanced Monitoring & Analytics - Wave 7          ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Deploy metrics collector
echo -e "${BLUE}📊 Creating metrics collection system...${RESET}"

cat > /tmp/metrics-collector.py << 'EOF'
#!/usr/bin/env python3
"""
BlackRoad Metrics Collector
Prometheus-compatible metrics with historical tracking
"""
from flask import Flask, Response, jsonify
import time
import subprocess
import json
import os
from collections import deque
from datetime import datetime

app = Flask(__name__)

# Historical metrics storage (last 1000 data points)
metrics_history = {
    'cpu': deque(maxlen=1000),
    'memory': deque(maxlen=1000),
    'disk': deque(maxlen=1000),
    'requests': deque(maxlen=1000),
    'response_times': deque(maxlen=1000)
}

# Request counter
request_count = 0
start_time = time.time()

def get_system_metrics():
    """Collect system metrics."""
    try:
        import psutil
        
        cpu = psutil.cpu_percent(interval=0.5)
        mem = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return {
            'cpu_percent': cpu,
            'memory_percent': mem.percent,
            'memory_used_gb': round(mem.used / 1024**3, 2),
            'memory_total_gb': round(mem.total / 1024**3, 2),
            'disk_percent': disk.percent,
            'disk_used_gb': round(disk.used / 1024**3, 2),
            'disk_total_gb': round(disk.total / 1024**3, 2)
        }
    except:
        return {}

def check_service_health(port):
    """Check if service on port is responding."""
    try:
        result = subprocess.run(
            ['curl', '-s', '-o', '/dev/null', '-w', '%{http_code}',
             f'http://localhost:{port}/health'],
            capture_output=True,
            text=True,
            timeout=2
        )
        return result.stdout.strip() == '200'
    except:
        return False

def collect_metrics():
    """Collect all metrics and store in history."""
    timestamp = time.time()
    sys_metrics = get_system_metrics()
    
    if sys_metrics:
        metrics_history['cpu'].append({
            'timestamp': timestamp,
            'value': sys_metrics.get('cpu_percent', 0)
        })
        metrics_history['memory'].append({
            'timestamp': timestamp,
            'value': sys_metrics.get('memory_percent', 0)
        })
        metrics_history['disk'].append({
            'timestamp': timestamp,
            'value': sys_metrics.get('disk_percent', 0)
        })

@app.route('/')
def home():
    return jsonify({
        "service": "BlackRoad Metrics Collector",
        "version": "0.1.0",
        "endpoints": [
            "/metrics",
            "/metrics/json",
            "/metrics/history",
            "/metrics/summary",
            "/health"
        ]
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "metrics-collector"})

@app.route('/metrics')
def metrics_prometheus():
    """Prometheus-compatible metrics endpoint."""
    sys_metrics = get_system_metrics()
    uptime = time.time() - start_time
    
    # Check service health
    services_up = 0
    for port in [5001, 5002, 5100, 5200, 5300]:
        if check_service_health(port):
            services_up += 1
    
    output = []
    
    # System metrics
    if sys_metrics:
        output.append(f'# HELP blackroad_cpu_percent CPU usage percentage')
        output.append(f'# TYPE blackroad_cpu_percent gauge')
        output.append(f'blackroad_cpu_percent {sys_metrics.get("cpu_percent", 0)}')
        output.append('')
        
        output.append(f'# HELP blackroad_memory_percent Memory usage percentage')
        output.append(f'# TYPE blackroad_memory_percent gauge')
        output.append(f'blackroad_memory_percent {sys_metrics.get("memory_percent", 0)}')
        output.append('')
        
        output.append(f'# HELP blackroad_disk_percent Disk usage percentage')
        output.append(f'# TYPE blackroad_disk_percent gauge')
        output.append(f'blackroad_disk_percent {sys_metrics.get("disk_percent", 0)}')
        output.append('')
    
    # Service metrics
    output.append(f'# HELP blackroad_services_up Number of healthy services')
    output.append(f'# TYPE blackroad_services_up gauge')
    output.append(f'blackroad_services_up {services_up}')
    output.append('')
    
    # Uptime
    output.append(f'# HELP blackroad_uptime_seconds Uptime in seconds')
    output.append(f'# TYPE blackroad_uptime_seconds counter')
    output.append(f'blackroad_uptime_seconds {uptime:.2f}')
    output.append('')
    
    # Request count
    output.append(f'# HELP blackroad_requests_total Total requests')
    output.append(f'# TYPE blackroad_requests_total counter')
    output.append(f'blackroad_requests_total {request_count}')
    output.append('')
    
    return Response('\n'.join(output), mimetype='text/plain')

@app.route('/metrics/json')
def metrics_json():
    """JSON format metrics."""
    global request_count
    request_count += 1
    
    sys_metrics = get_system_metrics()
    uptime = time.time() - start_time
    
    # Collect current metrics
    collect_metrics()
    
    return jsonify({
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'uptime_seconds': uptime,
        'system': sys_metrics,
        'services': {
            'tts_api': check_service_health(5001),
            'monitor_api': check_service_health(5002),
            'load_balancer': check_service_health(5100),
            'fleet_monitor': check_service_health(5200),
            'notifications': check_service_health(5300)
        },
        'request_count': request_count
    })

@app.route('/metrics/history')
def metrics_history_endpoint():
    """Get historical metrics."""
    return jsonify({
        'cpu': list(metrics_history['cpu'])[-100:],  # Last 100 points
        'memory': list(metrics_history['memory'])[-100:],
        'disk': list(metrics_history['disk'])[-100:]
    })

@app.route('/metrics/summary')
def metrics_summary():
    """Get summary statistics."""
    def calc_avg(data):
        if not data:
            return 0
        return sum(d['value'] for d in data) / len(data)
    
    def calc_max(data):
        if not data:
            return 0
        return max(d['value'] for d in data)
    
    return jsonify({
        'cpu': {
            'current': metrics_history['cpu'][-1]['value'] if metrics_history['cpu'] else 0,
            'average': calc_avg(metrics_history['cpu']),
            'max': calc_max(metrics_history['cpu'])
        },
        'memory': {
            'current': metrics_history['memory'][-1]['value'] if metrics_history['memory'] else 0,
            'average': calc_avg(metrics_history['memory']),
            'max': calc_max(metrics_history['memory'])
        },
        'disk': {
            'current': metrics_history['disk'][-1]['value'] if metrics_history['disk'] else 0,
            'average': calc_avg(metrics_history['disk']),
            'max': calc_max(metrics_history['disk'])
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5400)
EOF

ssh octavia "mkdir -p ~/metrics"
scp /tmp/metrics-collector.py octavia:~/metrics/app.py
ssh octavia "chmod +x ~/metrics/app.py"

echo -e "${GREEN}✅ Metrics collector deployed${RESET}"
echo ""

# Create systemd service
echo -e "${BLUE}⚙️  Creating systemd service...${RESET}"

cat > /tmp/metrics-service << 'EOF'
[Unit]
Description=BlackRoad Metrics Collector
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/blackroad/metrics/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

scp /tmp/metrics-service octavia:~/.config/systemd/user/metrics-collector.service

ssh octavia "systemctl --user daemon-reload"
ssh octavia "systemctl --user enable metrics-collector"
ssh octavia "systemctl --user restart metrics-collector"

echo -e "${GREEN}✅ Metrics service started${RESET}"
echo ""

# Create analytics dashboard
echo -e "${BLUE}📊 Creating analytics dashboard...${RESET}"

cat > /tmp/analytics-dashboard.py << 'EOF'
#!/usr/bin/env python3
"""
BlackRoad Analytics Dashboard
Real-time performance visualization
"""
from flask import Flask, render_template_string, jsonify
import requests

app = Flask(__name__)

DASHBOARD_HTML = '''
<!DOCTYPE html>
<html>
<head>
    <title>BlackRoad Analytics</title>
    <meta http-equiv="refresh" content="5">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: linear-gradient(135deg, #0a0a1e 0%, #1a1a3e 100%);
            color: #fff;
            font-family: 'SF Mono', 'Monaco', monospace;
            padding: 20px;
        }
        .container { max-width: 1600px; margin: 0 auto; }
        h1 {
            color: #FF1D6C;
            text-align: center;
            font-size: 3em;
            margin-bottom: 10px;
            text-shadow: 0 0 20px rgba(255,29,108,0.5);
        }
        .subtitle {
            text-align: center;
            color: #F5A623;
            margin-bottom: 40px;
            font-size: 1.2em;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: rgba(255,255,255,0.05);
            border: 2px solid rgba(255,255,255,0.1);
            border-radius: 12px;
            padding: 25px;
            transition: all 0.3s;
        }
        .stat-card:hover {
            border-color: #2979FF;
            box-shadow: 0 0 30px rgba(41,121,255,0.3);
        }
        .stat-label {
            color: #9C27B0;
            font-size: 0.9em;
            margin-bottom: 10px;
        }
        .stat-value {
            font-size: 3em;
            font-weight: bold;
            color: #00ff88;
        }
        .stat-unit {
            color: #888;
            font-size: 0.4em;
        }
        .chart-container {
            background: rgba(255,255,255,0.05);
            border: 2px solid rgba(255,255,255,0.1);
            border-radius: 12px;
            padding: 25px;
            margin-bottom: 20px;
        }
        .chart-title {
            color: #2979FF;
            font-size: 1.5em;
            margin-bottom: 15px;
        }
        .bar {
            height: 30px;
            background: linear-gradient(90deg, #FF1D6C 0%, #F5A623 100%);
            border-radius: 5px;
            margin: 10px 0;
            transition: width 0.5s;
        }
        .service-status {
            display: flex;
            justify-content: space-between;
            padding: 15px;
            margin: 10px 0;
            background: rgba(255,255,255,0.02);
            border-radius: 8px;
        }
        .status-online { color: #00ff88; }
        .status-offline { color: #ff4444; }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚡ BlackRoad Analytics</h1>
        <div class="subtitle">Real-time Performance Monitoring</div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">CPU Usage</div>
                <div class="stat-value" id="cpu">--<span class="stat-unit">%</span></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Memory Usage</div>
                <div class="stat-value" id="memory">--<span class="stat-unit">%</span></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Disk Usage</div>
                <div class="stat-value" id="disk">--<span class="stat-unit">%</span></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Services Healthy</div>
                <div class="stat-value" id="services">--<span class="stat-unit">/5</span></div>
            </div>
        </div>
        
        <div class="chart-container">
            <div class="chart-title">📊 System Resources</div>
            <div>
                <strong>CPU:</strong>
                <div class="bar" id="cpu-bar" style="width: 0%"></div>
            </div>
            <div>
                <strong>Memory:</strong>
                <div class="bar" id="mem-bar" style="width: 0%"></div>
            </div>
            <div>
                <strong>Disk:</strong>
                <div class="bar" id="disk-bar" style="width: 0%"></div>
            </div>
        </div>
        
        <div class="chart-container">
            <div class="chart-title">🔧 Service Health</div>
            <div id="services-list">Loading...</div>
        </div>
        
        <div class="footer">
            Auto-refresh every 5 seconds | Powered by BlackRoad OS
        </div>
    </div>
    
    <script>
        async function updateMetrics() {
            try {
                const response = await fetch('http://localhost:5400/metrics/json');
                const data = await response.json();
                
                // Update stats
                document.getElementById('cpu').innerHTML = 
                    data.system.cpu_percent.toFixed(1) + '<span class="stat-unit">%</span>';
                document.getElementById('memory').innerHTML = 
                    data.system.memory_percent.toFixed(1) + '<span class="stat-unit">%</span>';
                document.getElementById('disk').innerHTML = 
                    data.system.disk_percent.toFixed(1) + '<span class="stat-unit">%</span>';
                
                // Count healthy services
                const healthyCount = Object.values(data.services).filter(s => s).length;
                document.getElementById('services').innerHTML = 
                    healthyCount + '<span class="stat-unit">/5</span>';
                
                // Update bars
                document.getElementById('cpu-bar').style.width = data.system.cpu_percent + '%';
                document.getElementById('mem-bar').style.width = data.system.memory_percent + '%';
                document.getElementById('disk-bar').style.width = data.system.disk_percent + '%';
                
                // Update services list
                let servicesHTML = '';
                for (const [name, status] of Object.entries(data.services)) {
                    const statusClass = status ? 'status-online' : 'status-offline';
                    const statusText = status ? '🟢 ONLINE' : '🔴 OFFLINE';
                    servicesHTML += `
                        <div class="service-status">
                            <span>${name.replace('_', ' ').toUpperCase()}</span>
                            <span class="${statusClass}">${statusText}</span>
                        </div>
                    `;
                }
                document.getElementById('services-list').innerHTML = servicesHTML;
                
            } catch (error) {
                console.error('Failed to fetch metrics:', error);
            }
        }
        
        updateMetrics();
        setInterval(updateMetrics, 5000);
    </script>
</body>
</html>
'''

@app.route('/')
def dashboard():
    return render_template_string(DASHBOARD_HTML)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "analytics-dashboard"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5500)
EOF

ssh octavia "mkdir -p ~/analytics"
scp /tmp/analytics-dashboard.py octavia:~/analytics/app.py
ssh octavia "chmod +x ~/analytics/app.py"

echo -e "${GREEN}✅ Analytics dashboard deployed${RESET}"
echo ""

# Create systemd service for analytics
cat > /tmp/analytics-service << 'EOF'
[Unit]
Description=BlackRoad Analytics Dashboard
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/blackroad/analytics/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

scp /tmp/analytics-service octavia:~/.config/systemd/user/analytics-dashboard.service

ssh octavia "systemctl --user daemon-reload"
ssh octavia "systemctl --user enable analytics-dashboard"
ssh octavia "systemctl --user restart analytics-dashboard"

echo -e "${GREEN}✅ Analytics dashboard started${RESET}"
echo ""

# Test everything
echo -e "${BLUE}🧪 Testing monitoring services...${RESET}"
sleep 3

echo ""
echo "Metrics Collector:"
ssh octavia "curl -s http://localhost:5400/health"

echo ""
echo "Analytics Dashboard:"
ssh octavia "curl -s http://localhost:5500/health"

echo ""
echo "Sample Metrics (Prometheus format):"
ssh octavia "curl -s http://localhost:5400/metrics | head -20"

echo ""
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✅ Advanced Monitoring Deployed!                     ║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Access monitoring:"
echo "  http://octavia:5400/metrics        (Prometheus format)"
echo "  http://octavia:5400/metrics/json   (JSON format)"
echo "  http://octavia:5400/metrics/history (Historical data)"
echo "  http://octavia:5500/               (Analytics Dashboard)"
echo ""
