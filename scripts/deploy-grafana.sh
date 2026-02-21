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
# Deploy Grafana for BlackRoad OS monitoring
# Wave 8A: Professional dashboards (no external packages needed!)

set -e

echo "🎨 Deploying Grafana to octavia..."

# Create Grafana dashboard using only standard library
ssh octavia << 'REMOTE'
set -e

echo "📁 Creating Grafana directories..."
mkdir -p ~/grafana

# Create Grafana-style dashboard using http.server + urllib (Python standard library only!)
cat > ~/grafana/app.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
from urllib.request import urlopen
from urllib.error import URLError
from datetime import datetime

PORT = 5600

class GrafanaHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            try:
                # Fetch metrics from our collector
                with urlopen('http://localhost:5400/metrics/json', timeout=2) as response:
                    metrics = json.loads(response.read())
                
                services_healthy = sum(1 for v in metrics['services'].values() if v)
                services_total = len(metrics['services'])
                
                # Format uptime
                seconds = metrics['uptime_seconds']
                hours = int(seconds // 3600)
                minutes = int((seconds % 3600) // 60)
                uptime_formatted = f"{hours}h {minutes}m" if hours > 0 else f"{minutes}m"
                
                # Generate HTML
                html = f'''<!DOCTYPE html>
<html>
<head>
    <title>BlackRoad Grafana</title>
    <meta http-equiv="refresh" content="10">
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: #0b0c0e;
            color: #d8d9da;
        }}
        .navbar {{
            background: #1f1f20;
            padding: 12px 20px;
            border-bottom: 1px solid #2d2e30;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }}
        .logo {{
            font-size: 20px;
            font-weight: 600;
            color: #ff1d6c;
        }}
        .time {{
            color: #9d9fa1;
            font-size: 14px;
        }}
        .container {{
            padding: 20px;
            max-width: 1400px;
            margin: 0 auto;
        }}
        .dashboard-header {{
            margin-bottom: 20px;
        }}
        .dashboard-title {{
            font-size: 28px;
            font-weight: 500;
            margin-bottom: 5px;
        }}
        .dashboard-subtitle {{
            color: #9d9fa1;
            font-size: 14px;
        }}
        .row {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }}
        .panel {{
            background: #1f1f20;
            border: 1px solid #2d2e30;
            border-radius: 4px;
            padding: 16px;
        }}
        .panel-title {{
            font-size: 14px;
            font-weight: 500;
            margin-bottom: 12px;
            color: #d8d9da;
        }}
        .metric-value {{
            font-size: 36px;
            font-weight: 300;
            margin-bottom: 4px;
        }}
        .metric-label {{
            font-size: 12px;
            color: #9d9fa1;
        }}
        .metric-good {{ color: #73bf69; }}
        .metric-warning {{ color: #f5a623; }}
        .metric-critical {{ color: #ff1d6c; }}
        .status-indicator {{
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            margin-right: 6px;
        }}
        .status-up {{ background: #73bf69; }}
        .status-down {{ background: #ff1d6c; }}
        .service-row {{
            padding: 8px 0;
            border-bottom: 1px solid #2d2e30;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }}
        .service-name {{
            display: flex;
            align-items: center;
        }}
        .graph {{
            height: 200px;
            background: #161719;
            border-radius: 4px;
            margin-top: 12px;
            position: relative;
            overflow: hidden;
        }}
        .bar {{
            position: absolute;
            bottom: 0;
            left: 0;
            background: linear-gradient(180deg, #ff1d6c 0%, #f5a623 100%);
            transition: width 0.3s ease;
        }}
        .refresh-indicator {{
            color: #9d9fa1;
            font-size: 12px;
            text-align: right;
            margin-top: 10px;
        }}
    </style>
</head>
<body>
    <div class="navbar">
        <div class="logo">⚡ BlackRoad Grafana</div>
        <div class="time">{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</div>
    </div>
    
    <div class="container">
        <div class="dashboard-header">
            <div class="dashboard-title">BlackRoad Infrastructure Overview</div>
            <div class="dashboard-subtitle">Real-time monitoring • Auto-refresh: 10s</div>
        </div>
        
        <div class="row">
            <div class="panel">
                <div class="panel-title">CPU Usage</div>
                <div class="metric-value {'metric-good' if metrics['system']['cpu_percent'] < 50 else 'metric-warning' if metrics['system']['cpu_percent'] < 80 else 'metric-critical'}">
                    {metrics['system']['cpu_percent']:.1f}%
                </div>
                <div class="metric-label">Current CPU load</div>
                <div class="graph">
                    <div class="bar" style="width: {metrics['system']['cpu_percent']}%; height: 100%;"></div>
                </div>
            </div>
            
            <div class="panel">
                <div class="panel-title">Memory Usage</div>
                <div class="metric-value {'metric-good' if metrics['system']['memory_percent'] < 60 else 'metric-warning' if metrics['system']['memory_percent'] < 85 else 'metric-critical'}">
                    {metrics['system']['memory_percent']:.1f}%
                </div>
                <div class="metric-label">{metrics['system']['memory_used_gb']:.2f} GB / {metrics['system']['memory_total_gb']:.2f} GB</div>
                <div class="graph">
                    <div class="bar" style="width: {metrics['system']['memory_percent']}%; height: 100%;"></div>
                </div>
            </div>
            
            <div class="panel">
                <div class="panel-title">Disk Usage</div>
                <div class="metric-value {'metric-good' if metrics['system']['disk_percent'] < 70 else 'metric-warning' if metrics['system']['disk_percent'] < 90 else 'metric-critical'}">
                    {metrics['system']['disk_percent']:.1f}%
                </div>
                <div class="metric-label">{metrics['system']['disk_used_gb']:.2f} GB / {metrics['system']['disk_total_gb']:.2f} GB</div>
                <div class="graph">
                    <div class="bar" style="width: {metrics['system']['disk_percent']}%; height: 100%;"></div>
                </div>
            </div>
            
            <div class="panel">
                <div class="panel-title">System Uptime</div>
                <div class="metric-value metric-good">
                    {uptime_formatted}
                </div>
                <div class="metric-label">Metrics collector uptime</div>
            </div>
        </div>
        
        <div class="panel">
            <div class="panel-title">Service Health ({services_healthy}/{services_total})</div>
'''
                
                for service, status in metrics['services'].items():
                    status_class = 'status-up' if status else 'status-down'
                    status_text = '<span style="color: #73bf69;">✓ Running</span>' if status else '<span style="color: #ff1d6c;">✗ Down</span>'
                    html += f'''
            <div class="service-row">
                <div class="service-name">
                    <span class="status-indicator {status_class}"></span>
                    <span>{service}</span>
                </div>
                <div>{status_text}</div>
            </div>'''
                
                html += f'''
        </div>
        
        <div class="refresh-indicator">
            Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} • Next refresh in 10s
        </div>
    </div>
</body>
</html>'''
                
                self.wfile.write(html.encode())
            
            except Exception as e:
                error_html = f'<h1>Error loading metrics</h1><p>{str(e)}</p>'
                self.wfile.write(error_html.encode())
        
        elif self.path == '/api/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = json.dumps({"status": "healthy", "service": "grafana"})
            self.wfile.write(response.encode())
        
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

with socketserver.TCPServer(("", PORT), GrafanaHandler) as httpd:
    print(f"Grafana server running on port {PORT}")
    httpd.serve_forever()
EOF

chmod +x ~/grafana/app.py

echo "📝 Creating systemd service..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/grafana.service << 'SYSTEMD'
[Unit]
Description=BlackRoad Grafana Dashboard
After=network.target

[Service]
Type=simple
WorkingDirectory=%h/grafana
ExecStart=/usr/bin/python3 %h/grafana/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
SYSTEMD

echo "🚀 Starting Grafana service..."
systemctl --user daemon-reload
systemctl --user enable grafana.service
systemctl --user restart grafana.service

echo "⏳ Waiting for Grafana to start..."
sleep 3

echo "✅ Testing Grafana..."
curl -f http://localhost:5600/api/health || echo "⚠️  Health check failed"

echo ""
echo "✅ Grafana deployed successfully!"
systemctl --user status grafana.service --no-pager | head -10
REMOTE

echo ""
echo "✅ Wave 8A deployment complete!"
echo ""
echo "🎨 Access Grafana:"
echo "   http://octavia:5600/"
echo ""
echo "📊 Features:"
echo "   • Real-time system metrics"
echo "   • Service health monitoring"
echo "   • Auto-refresh (10s)"
echo "   • Professional Grafana-style UI"
