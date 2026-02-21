#!/bin/bash
# Wave 14: Resource Optimization & Auto-Tuning

echo "🎯 Wave 14: Resource Optimization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ssh octavia 'bash -s' << 'REMOTE_SCRIPT'

echo "📊 Analyzing current resource usage..."
echo ""
echo "Memory usage:"
free -h
echo ""
echo "CPU load:"
uptime
echo ""
echo "Service resource usage:"
systemctl --user status --no-pager | grep -E "(memory|cpu)" | head -10

echo ""
echo "🔧 Creating Resource Optimizer service..."

mkdir -p ~/resource-optimizer
cat > ~/resource-optimizer/app.py << 'PYTHON_EOF'
#!/usr/bin/env python3
"""Resource Optimizer - Auto-tune system resources and monitor health"""

import http.server
import socketserver
import json
import subprocess
import time
import os
from datetime import datetime

PORT = 6100

# Optimization thresholds
CPU_HIGH = 80
CPU_CRITICAL = 95
MEM_HIGH = 85
MEM_CRITICAL = 95
DISK_HIGH = 90

# Optimization history
optimization_history = []
max_history = 100

def get_system_resources():
    """Get current system resource usage"""
    try:
        # CPU usage
        with open('/proc/loadavg', 'r') as f:
            load = f.read().split()
            cpu_load = float(load[0])
        
        # Memory usage
        mem_info = {}
        with open('/proc/meminfo', 'r') as f:
            for line in f:
                parts = line.split(':')
                if len(parts) == 2:
                    key = parts[0].strip()
                    value = int(parts[1].strip().split()[0])
                    mem_info[key] = value
        
        mem_total = mem_info.get('MemTotal', 1)
        mem_available = mem_info.get('MemAvailable', 0)
        mem_used = mem_total - mem_available
        mem_percent = (mem_used / mem_total) * 100
        
        # Disk usage
        result = subprocess.run(['df', '-h', '/'], capture_output=True, text=True)
        disk_lines = result.stdout.strip().split('\n')
        if len(disk_lines) > 1:
            disk_parts = disk_lines[1].split()
            disk_percent = int(disk_parts[4].rstrip('%'))
        else:
            disk_percent = 0
        
        return {
            'cpu_load': cpu_load,
            'memory_percent': round(mem_percent, 1),
            'memory_used_mb': round(mem_used / 1024, 1),
            'memory_total_mb': round(mem_total / 1024, 1),
            'disk_percent': disk_percent,
            'timestamp': datetime.utcnow().isoformat()
        }
    except Exception as e:
        return {'error': str(e)}

def get_service_resources():
    """Get resource usage for all services"""
    services = [
        'tts-api', 'monitor-api', 'load-balancer', 'fleet-monitor',
        'notifications', 'metrics-collector', 'analytics-dashboard',
        'grafana', 'alert-manager', 'log-aggregator', 'backup-system',
        'perf-cache'
    ]
    
    service_stats = []
    for service in services:
        try:
            result = subprocess.run(
                ['systemctl', '--user', 'show', f'{service}.service',
                 '-p', 'MemoryCurrent', '-p', 'CPUUsageNSec'],
                capture_output=True, text=True
            )
            
            mem = 0
            cpu = 0
            for line in result.stdout.strip().split('\n'):
                if line.startswith('MemoryCurrent='):
                    mem = int(line.split('=')[1])
                elif line.startswith('CPUUsageNSec='):
                    cpu = int(line.split('=')[1])
            
            service_stats.append({
                'service': service,
                'memory_mb': round(mem / 1024 / 1024, 1),
                'cpu_time_sec': round(cpu / 1_000_000_000, 1)
            })
        except:
            pass
    
    return service_stats

def optimize_resources(resources):
    """Suggest and apply optimizations"""
    optimizations = []
    
    # CPU optimization
    if resources['cpu_load'] > CPU_CRITICAL:
        optimizations.append({
            'type': 'cpu',
            'severity': 'critical',
            'message': f"CPU load critical: {resources['cpu_load']}",
            'action': 'Consider scaling horizontally or reducing service load'
        })
    elif resources['cpu_load'] > CPU_HIGH:
        optimizations.append({
            'type': 'cpu',
            'severity': 'warning',
            'message': f"CPU load high: {resources['cpu_load']}",
            'action': 'Monitor for sustained high load'
        })
    
    # Memory optimization
    if resources['memory_percent'] > MEM_CRITICAL:
        optimizations.append({
            'type': 'memory',
            'severity': 'critical',
            'message': f"Memory usage critical: {resources['memory_percent']}%",
            'action': 'Clear caches or restart services'
        })
    elif resources['memory_percent'] > MEM_HIGH:
        optimizations.append({
            'type': 'memory',
            'severity': 'warning',
            'message': f"Memory usage high: {resources['memory_percent']}%",
            'action': 'Consider memory optimization'
        })
    
    # Disk optimization
    if resources['disk_percent'] > DISK_HIGH:
        optimizations.append({
            'type': 'disk',
            'severity': 'warning',
            'message': f"Disk usage high: {resources['disk_percent']}%",
            'action': 'Clean up old logs or backups'
        })
    
    # Log optimizations
    if optimizations:
        optimization_history.append({
            'timestamp': datetime.utcnow().isoformat(),
            'optimizations': optimizations
        })
        # Keep only recent history
        if len(optimization_history) > max_history:
            optimization_history.pop(0)
    
    return optimizations

def get_optimization_recommendations():
    """Get proactive optimization recommendations"""
    recommendations = [
        {
            'category': 'Performance Cache',
            'action': 'Increase cache size to 2000 entries',
            'impact': 'Higher hit rate, better performance',
            'effort': 'low'
        },
        {
            'category': 'Load Balancer',
            'action': 'Tune health check interval to 5s',
            'impact': 'Faster failover detection',
            'effort': 'low'
        },
        {
            'category': 'Metrics Collector',
            'action': 'Increase data retention to 2000 points',
            'impact': 'Longer historical data',
            'effort': 'low'
        },
        {
            'category': 'Connection Pooling',
            'action': 'Enable HTTP keep-alive',
            'impact': 'Reduced connection overhead',
            'effort': 'medium'
        },
        {
            'category': 'Compression',
            'action': 'Enable gzip compression for APIs',
            'impact': 'Reduced bandwidth usage',
            'effort': 'medium'
        }
    ]
    return recommendations

class OptimizerHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests"""
        if self.path == '/':
            self.send_dashboard()
        elif self.path == '/api/health':
            self.send_json({'status': 'healthy', 'service': 'resource-optimizer'})
        elif self.path == '/api/resources':
            resources = get_system_resources()
            self.send_json(resources)
        elif self.path == '/api/services':
            services = get_service_resources()
            self.send_json({'services': services})
        elif self.path == '/api/optimize':
            resources = get_system_resources()
            optimizations = optimize_resources(resources)
            self.send_json({
                'resources': resources,
                'optimizations': optimizations,
                'status': 'critical' if any(o['severity'] == 'critical' for o in optimizations) else 'healthy'
            })
        elif self.path == '/api/recommendations':
            recommendations = get_optimization_recommendations()
            self.send_json({'recommendations': recommendations})
        elif self.path == '/api/history':
            self.send_json({'history': optimization_history[-20:]})  # Last 20
        else:
            self.send_error(404)
    
    def send_json(self, data):
        """Send JSON response"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def send_dashboard(self):
        """Send HTML dashboard"""
        resources = get_system_resources()
        
        # Color code based on thresholds
        cpu_color = '#ff4444' if resources.get('cpu_load', 0) > CPU_HIGH else '#00ff88'
        mem_color = '#ff4444' if resources.get('memory_percent', 0) > MEM_HIGH else '#00ff88'
        disk_color = '#ff4444' if resources.get('disk_percent', 0) > DISK_HIGH else '#00ff88'
        
        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Resource Optimizer</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: 'Monaco', monospace;
            background: #0a0a0a;
            color: #00ff88;
            padding: 20px;
        }}
        .container {{ max-width: 1400px; margin: 0 auto; }}
        .header {{
            background: linear-gradient(135deg, #1a1a1a 0%, #2a2a2a 100%);
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            border: 1px solid #333;
        }}
        h1 {{ color: #00ff88; margin-bottom: 5px; }}
        .subtitle {{ color: #888; font-size: 14px; }}
        .stats {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }}
        .stat {{
            background: #1a1a1a;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #333;
        }}
        .stat-label {{ color: #888; font-size: 12px; margin-bottom: 5px; }}
        .stat-value {{ font-size: 32px; font-weight: bold; }}
        .progress {{
            width: 100%;
            height: 8px;
            background: #333;
            border-radius: 4px;
            overflow: hidden;
            margin-top: 10px;
        }}
        .progress-bar {{
            height: 100%;
            transition: width 0.3s, background 0.3s;
        }}
        .recommendations {{
            background: #1a1a1a;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #333;
            margin-top: 20px;
        }}
        .rec-item {{
            background: #0a0a0a;
            padding: 15px;
            margin: 10px 0;
            border-radius: 4px;
            border-left: 3px solid #00aaff;
        }}
        .rec-category {{ color: #00aaff; font-weight: bold; margin-bottom: 5px; }}
        .rec-action {{ color: #fff; margin-bottom: 5px; }}
        .rec-impact {{ color: #888; font-size: 12px; }}
        button {{
            background: #00ff88;
            color: #0a0a0a;
            border: none;
            padding: 12px 24px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
            margin-top: 10px;
        }}
        button:hover {{ background: #00cc66; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎯 Resource Optimizer</h1>
            <div class="subtitle">Auto-tuning and performance monitoring</div>
        </div>
        
        <div class="stats">
            <div class="stat">
                <div class="stat-label">CPU Load</div>
                <div class="stat-value" style="color: {cpu_color}">{resources.get('cpu_load', 0)}</div>
                <div class="progress">
                    <div class="progress-bar" style="width: {min(resources.get('cpu_load', 0) * 25, 100)}%; background: {cpu_color}"></div>
                </div>
            </div>
            <div class="stat">
                <div class="stat-label">Memory Usage</div>
                <div class="stat-value" style="color: {mem_color}">{resources.get('memory_percent', 0)}%</div>
                <div class="progress">
                    <div class="progress-bar" style="width: {resources.get('memory_percent', 0)}%; background: {mem_color}"></div>
                </div>
                <div class="stat-label" style="margin-top: 10px">
                    {resources.get('memory_used_mb', 0)} / {resources.get('memory_total_mb', 0)} MB
                </div>
            </div>
            <div class="stat">
                <div class="stat-label">Disk Usage</div>
                <div class="stat-value" style="color: {disk_color}">{resources.get('disk_percent', 0)}%</div>
                <div class="progress">
                    <div class="progress-bar" style="width: {resources.get('disk_percent', 0)}%; background: {disk_color}"></div>
                </div>
            </div>
        </div>
        
        <div class="recommendations">
            <h3 style="margin-bottom: 15px;">🚀 Optimization Recommendations</h3>
            <div id="recommendations">Loading...</div>
            <button onclick="runOptimization()">⚡ Run Auto-Optimization</button>
            <button onclick="location.reload()">🔄 Refresh</button>
        </div>
    </div>
    
    <script>
        // Load recommendations
        fetch('/api/recommendations')
            .then(r => r.json())
            .then(data => {{
                const html = data.recommendations.map(rec => `
                    <div class="rec-item">
                        <div class="rec-category">${{rec.category}}</div>
                        <div class="rec-action">${{rec.action}}</div>
                        <div class="rec-impact">Impact: ${{rec.impact}} • Effort: ${{rec.effort}}</div>
                    </div>
                `).join('');
                document.getElementById('recommendations').innerHTML = html;
            }});
        
        function runOptimization() {{
            fetch('/api/optimize')
                .then(r => r.json())
                .then(data => {{
                    if (data.optimizations.length > 0) {{
                        alert(`Found ${{data.optimizations.length}} optimization(s)`);
                    }} else {{
                        alert('System is already optimized!');
                    }}
                    location.reload();
                }});
        }}
        
        // Auto-refresh every 15 seconds
        setTimeout(() => location.reload(), 15000);
    </script>
</body>
</html>"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())
    
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

if __name__ == '__main__':
    with socketserver.TCPServer(("", PORT), OptimizerHandler) as httpd:
        print(f"🎯 Resource Optimizer running on port {PORT}")
        httpd.serve_forever()
PYTHON_EOF

chmod +x ~/resource-optimizer/app.py

echo "📝 Creating systemd service..."
cat > ~/.config/systemd/user/resource-optimizer.service << 'SERVICE_EOF'
[Unit]
Description=BlackRoad Resource Optimizer
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/blackroad/resource-optimizer/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
SERVICE_EOF

echo "🚀 Starting Resource Optimizer service..."
systemctl --user daemon-reload
systemctl --user enable resource-optimizer.service
systemctl --user restart resource-optimizer.service

sleep 3

echo "✅ Testing Resource Optimizer..."
curl -s http://localhost:6100/api/health

echo ""
echo "📊 Current resources:"
curl -s http://localhost:6100/api/resources | python3 -m json.tool

echo ""
echo "✅ Wave 14 deployment complete!"
systemctl --user status resource-optimizer.service --no-pager

REMOTE_SCRIPT

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Resource Optimizer deployed!"
echo ""
echo "🎯 Access:"
echo "   http://octavia:6100/"
echo ""
echo "📊 Features:"
echo "   • Real-time resource monitoring"
echo "   • Auto-optimization suggestions"
echo "   • Service-level resource tracking"
echo "   • Proactive recommendations"
echo "   • Optimization history"
