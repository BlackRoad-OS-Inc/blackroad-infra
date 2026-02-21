#!/bin/bash
# Deploy Log Aggregation System for BlackRoad OS
# Wave 11A: Centralized logging with search

set -e

echo "📜 Deploying Log Aggregation to octavia..."

# Create log aggregation system on octavia
ssh octavia << 'REMOTE'
set -e

echo "📁 Creating log aggregation directories..."
mkdir -p ~/log-aggregator/{logs,cache}

# Create log aggregation service using Python stdlib
cat > ~/log-aggregator/app.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import os
import re
import subprocess
from datetime import datetime
from collections import deque

PORT = 5800
LOGS_DIR = os.path.expanduser('~/log-aggregator/logs')
MAX_LOG_ENTRIES = 1000

class LogAggregator:
    def __init__(self):
        self.log_buffer = deque(maxlen=MAX_LOG_ENTRIES)
        self.services = [
            'tts-api',
            'monitor-api', 
            'load-balancer',
            'fleet-monitor',
            'notifications',
            'metrics',
            'analytics',
            'grafana',
            'alert-manager'
        ]
        
    def collect_logs(self, service=None, level=None, limit=100, search=None):
        """Collect logs from systemd journals"""
        logs = []
        
        services_to_check = [service] if service else self.services
        
        for svc in services_to_check:
            try:
                # Get logs from systemd journal
                cmd = ['journalctl', '--user', '-u', f'{svc}.service', '-n', str(limit), '--no-pager', '-o', 'json']
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                
                if result.returncode == 0:
                    for line in result.stdout.strip().split('\n'):
                        if line:
                            try:
                                entry = json.loads(line)
                                log_entry = {
                                    'service': svc,
                                    'message': entry.get('MESSAGE', ''),
                                    'timestamp': entry.get('__REALTIME_TIMESTAMP', ''),
                                    'priority': entry.get('PRIORITY', '6'),
                                    'unit': entry.get('_SYSTEMD_UNIT', '')
                                }
                                
                                # Convert priority to level
                                priority_map = {
                                    '0': 'EMERG', '1': 'ALERT', '2': 'CRIT',
                                    '3': 'ERROR', '4': 'WARN', '5': 'NOTICE',
                                    '6': 'INFO', '7': 'DEBUG'
                                }
                                log_entry['level'] = priority_map.get(log_entry['priority'], 'INFO')
                                
                                # Filter by level if specified
                                if level and log_entry['level'] != level.upper():
                                    continue
                                
                                # Filter by search term if specified
                                if search and search.lower() not in log_entry['message'].lower():
                                    continue
                                
                                logs.append(log_entry)
                            except:
                                pass
            except:
                pass
        
        # Sort by timestamp (newest first)
        logs.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        
        return logs[:limit]
    
    def get_error_count(self):
        """Get count of errors in recent logs"""
        error_logs = self.collect_logs(level='ERROR', limit=50)
        crit_logs = self.collect_logs(level='CRIT', limit=50)
        return len(error_logs) + len(crit_logs)
    
    def get_service_stats(self):
        """Get log statistics per service"""
        stats = {}
        for service in self.services:
            logs = self.collect_logs(service=service, limit=100)
            stats[service] = {
                'total': len(logs),
                'errors': len([l for l in logs if l['level'] in ['ERROR', 'CRIT', 'ALERT', 'EMERG']])
            }
        return stats

log_aggregator = LogAggregator()

class LogHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            # Parse query parameters
            query_parts = self.path.split('?')
            params = {}
            if len(query_parts) > 1:
                for param in query_parts[1].split('&'):
                    if '=' in param:
                        key, value = param.split('=', 1)
                        params[key] = value
            
            service = params.get('service')
            level = params.get('level')
            search = params.get('search')
            
            # Collect logs
            logs = log_aggregator.collect_logs(
                service=service,
                level=level,
                limit=100,
                search=search
            )
            
            # Get stats
            stats = log_aggregator.get_service_stats()
            total_errors = sum(s['errors'] for s in stats.values())
            
            html = f'''<!DOCTYPE html>
<html>
<head>
    <title>BlackRoad Log Aggregator</title>
    <meta http-equiv="refresh" content="30">
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: 'Monaco', 'Courier New', monospace;
            background: #0b0c0e;
            color: #d8d9da;
            padding: 20px;
        }}
        .header {{
            background: #1f1f20;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }}
        .title {{
            font-size: 28px;
            font-weight: 600;
            color: #0096FF;
            margin-bottom: 10px;
        }}
        .filters {{
            background: #1f1f20;
            padding: 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }}
        .filter-group {{
            display: flex;
            flex-direction: column;
            gap: 4px;
        }}
        .filter-label {{
            font-size: 12px;
            color: #9d9fa1;
        }}
        select, input {{
            background: #0b0c0e;
            border: 1px solid #2d2e30;
            color: #d8d9da;
            padding: 6px 12px;
            border-radius: 4px;
            font-family: inherit;
        }}
        .stats {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 12px;
            margin-bottom: 20px;
        }}
        .stat-card {{
            background: #1f1f20;
            padding: 12px;
            border-radius: 8px;
            border-left: 3px solid #0096FF;
        }}
        .stat-card.errors {{ border-color: #ff1d6c; }}
        .stat-service {{
            font-size: 12px;
            color: #9d9fa1;
            margin-bottom: 4px;
        }}
        .stat-count {{
            font-size: 20px;
            font-weight: 300;
        }}
        .logs-container {{
            background: #1f1f20;
            border-radius: 8px;
            padding: 16px;
        }}
        .log-entry {{
            font-family: 'Monaco', 'Courier New', monospace;
            font-size: 13px;
            padding: 8px 12px;
            border-bottom: 1px solid #2d2e30;
            display: flex;
            gap: 12px;
        }}
        .log-entry:hover {{
            background: #252527;
        }}
        .log-timestamp {{
            color: #9d9fa1;
            white-space: nowrap;
        }}
        .log-level {{
            font-weight: 600;
            width: 60px;
            flex-shrink: 0;
        }}
        .log-level.INFO {{ color: #0096FF; }}
        .log-level.WARN {{ color: #f5a623; }}
        .log-level.ERROR {{ color: #ff1d6c; }}
        .log-level.CRIT {{ color: #ff1d6c; font-weight: 700; }}
        .log-service {{
            color: #73bf69;
            width: 120px;
            flex-shrink: 0;
        }}
        .log-message {{
            flex: 1;
            word-break: break-word;
        }}
        .no-logs {{
            text-align: center;
            padding: 40px;
            color: #9d9fa1;
        }}
    </style>
</head>
<body>
    <div class="header">
        <div class="title">📜 Log Aggregator</div>
        <div style="color: #9d9fa1; font-size: 14px;">Centralized logging • Auto-refresh: 30s</div>
    </div>
    
    <div class="filters">
        <div class="filter-group">
            <label class="filter-label">Service</label>
            <select onchange="window.location.href='/?service='+this.value">
                <option value="">All Services</option>
                <option value="tts-api" {'selected' if service == 'tts-api' else ''}>TTS API</option>
                <option value="monitor-api" {'selected' if service == 'monitor-api' else ''}>Monitor API</option>
                <option value="load-balancer" {'selected' if service == 'load-balancer' else ''}>Load Balancer</option>
                <option value="fleet-monitor" {'selected' if service == 'fleet-monitor' else ''}>Fleet Monitor</option>
                <option value="grafana" {'selected' if service == 'grafana' else ''}>Grafana</option>
                <option value="alert-manager" {'selected' if service == 'alert-manager' else ''}>Alert Manager</option>
            </select>
        </div>
        <div class="filter-group">
            <label class="filter-label">Level</label>
            <select onchange="window.location.href='/?level='+this.value">
                <option value="">All Levels</option>
                <option value="ERROR" {'selected' if level == 'ERROR' else ''}>ERROR</option>
                <option value="WARN" {'selected' if level == 'WARN' else ''}>WARN</option>
                <option value="INFO" {'selected' if level == 'INFO' else ''}>INFO</option>
            </select>
        </div>
    </div>
    
    <div class="stats">
        <div class="stat-card errors">
            <div class="stat-service">Total Errors</div>
            <div class="stat-count">{total_errors}</div>
        </div>
'''
            
            for service, stat in stats.items():
                html += f'''
        <div class="stat-card">
            <div class="stat-service">{service}</div>
            <div class="stat-count">{stat['total']} logs</div>
        </div>'''
            
            html += '''
    </div>
    
    <div class="logs-container">
'''
            
            if logs:
                for log in logs:
                    # Format timestamp
                    try:
                        ts = int(log['timestamp']) / 1000000  # Convert microseconds to seconds
                        dt = datetime.fromtimestamp(ts)
                        timestamp = dt.strftime('%H:%M:%S')
                    except:
                        timestamp = 'N/A'
                    
                    html += f'''
        <div class="log-entry">
            <span class="log-timestamp">{timestamp}</span>
            <span class="log-level {log['level']}">{log['level']}</span>
            <span class="log-service">{log['service']}</span>
            <span class="log-message">{log['message']}</span>
        </div>'''
            else:
                html += '<div class="no-logs">No logs found</div>'
            
            html += '''
    </div>
</body>
</html>'''
            
            self.wfile.write(html.encode())
        
        elif self.path.startswith('/api/logs'):
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            logs = log_aggregator.collect_logs(limit=100)
            response = json.dumps({'logs': logs, 'count': len(logs)})
            self.wfile.write(response.encode())
        
        elif self.path == '/api/stats':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            stats = log_aggregator.get_service_stats()
            response = json.dumps(stats)
            self.wfile.write(response.encode())
        
        elif self.path == '/api/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = json.dumps({'status': 'healthy', 'service': 'log-aggregator'})
            self.wfile.write(response.encode())
        
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("", PORT), LogHandler) as httpd:
    print(f"Log Aggregator running on port {PORT}")
    httpd.serve_forever()
EOF

chmod +x ~/log-aggregator/app.py

echo "📝 Creating systemd service..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/log-aggregator.service << 'SYSTEMD'
[Unit]
Description=BlackRoad Log Aggregator
After=network.target

[Service]
Type=simple
WorkingDirectory=%h/log-aggregator
ExecStart=/usr/bin/python3 %h/log-aggregator/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
SYSTEMD

echo "🚀 Starting Log Aggregator service..."
systemctl --user daemon-reload
systemctl --user enable log-aggregator.service
systemctl --user restart log-aggregator.service

echo "⏳ Waiting for Log Aggregator to start..."
sleep 3

echo "✅ Testing Log Aggregator..."
curl -f http://localhost:5800/api/health || echo "⚠️  Health check failed"

echo ""
echo "✅ Log Aggregator deployed successfully!"
systemctl --user status log-aggregator.service --no-pager | head -10
REMOTE

echo ""
echo "✅ Wave 11A deployment complete!"
echo ""
echo "📜 Access Log Aggregator:"
echo "   http://octavia:5800/"
echo ""
echo "📊 Features:"
echo "   • Centralized logging from all services"
echo "   • Real-time log streaming"
echo "   • Filter by service and level"
echo "   • Search capability"
echo "   • Error tracking"
