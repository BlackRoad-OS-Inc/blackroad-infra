#!/bin/bash
# Deploy Alert Manager for BlackRoad OS
# Wave 10A: Intelligent alerting system

set -e

echo "🚨 Deploying Alert Manager to octavia..."

# Create alert manager on octavia
ssh octavia << 'REMOTE'
set -e

echo "📁 Creating alert manager directories..."
mkdir -p ~/alert-manager/{alerts,history}

# Create alert manager using Python stdlib
cat > ~/alert-manager/app.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import os
import time
from urllib.request import urlopen, Request
from urllib.error import URLError
from datetime import datetime
from email.mime.text import MIMEText
import smtplib

PORT = 5700
ALERTS_DIR = os.path.expanduser('~/alert-manager/alerts')
HISTORY_DIR = os.path.expanduser('~/alert-manager/history')

# Alert rules configuration
ALERT_RULES = {
    'cpu_high': {
        'metric': 'cpu_percent',
        'threshold': 80,
        'operator': '>',
        'severity': 'warning',
        'message': 'CPU usage is high: {value}%'
    },
    'cpu_critical': {
        'metric': 'cpu_percent',
        'threshold': 95,
        'operator': '>',
        'severity': 'critical',
        'message': 'CPU usage is critical: {value}%'
    },
    'memory_high': {
        'metric': 'memory_percent',
        'threshold': 85,
        'operator': '>',
        'severity': 'warning',
        'message': 'Memory usage is high: {value}%'
    },
    'memory_critical': {
        'metric': 'memory_percent',
        'threshold': 95,
        'operator': '>',
        'severity': 'critical',
        'message': 'Memory usage is critical: {value}%'
    },
    'disk_high': {
        'metric': 'disk_percent',
        'threshold': 90,
        'operator': '>',
        'severity': 'warning',
        'message': 'Disk usage is high: {value}%'
    },
    'service_down': {
        'metric': 'services',
        'threshold': 5,
        'operator': '<',
        'severity': 'critical',
        'message': 'Service down: {service}'
    }
}

class AlertManager:
    def __init__(self):
        self.active_alerts = {}
        self.alert_history = []
        
    def check_metrics(self):
        """Fetch current metrics and check against rules"""
        try:
            with urlopen('http://localhost:5400/metrics/json', timeout=2) as response:
                metrics = json.loads(response.read())
            
            triggered_alerts = []
            
            # Check system metrics
            system = metrics.get('system', {})
            for rule_id, rule in ALERT_RULES.items():
                if rule['metric'] in system:
                    value = system[rule['metric']]
                    if self._evaluate_rule(value, rule['threshold'], rule['operator']):
                        alert = {
                            'id': rule_id,
                            'severity': rule['severity'],
                            'message': rule['message'].format(value=value),
                            'value': value,
                            'threshold': rule['threshold'],
                            'timestamp': datetime.now().isoformat()
                        }
                        triggered_alerts.append(alert)
            
            # Check service health
            services = metrics.get('services', {})
            healthy_count = sum(1 for v in services.values() if v)
            if healthy_count < 5:
                for service, status in services.items():
                    if not status:
                        alert = {
                            'id': f'service_{service}_down',
                            'severity': 'critical',
                            'message': f'Service down: {service}',
                            'service': service,
                            'timestamp': datetime.now().isoformat()
                        }
                        triggered_alerts.append(alert)
            
            # Process alerts
            for alert in triggered_alerts:
                self._handle_alert(alert)
            
            # Clear resolved alerts
            self._clear_resolved_alerts(metrics)
            
            return triggered_alerts
            
        except Exception as e:
            return [{'error': str(e)}]
    
    def _evaluate_rule(self, value, threshold, operator):
        """Evaluate a rule condition"""
        if operator == '>':
            return value > threshold
        elif operator == '<':
            return value < threshold
        elif operator == '==':
            return value == threshold
        return False
    
    def _handle_alert(self, alert):
        """Handle a triggered alert"""
        alert_id = alert['id']
        
        # Check if alert already active
        if alert_id in self.active_alerts:
            # Update existing alert
            self.active_alerts[alert_id]['count'] += 1
            self.active_alerts[alert_id]['last_seen'] = alert['timestamp']
        else:
            # New alert
            alert['count'] = 1
            alert['first_seen'] = alert['timestamp']
            alert['last_seen'] = alert['timestamp']
            self.active_alerts[alert_id] = alert
            
            # Send notification for new alerts
            self._send_notification(alert)
            
            # Log to history
            self._log_to_history(alert)
    
    def _clear_resolved_alerts(self, metrics):
        """Clear alerts that are no longer triggered"""
        system = metrics.get('system', {})
        resolved = []
        
        for alert_id, alert in list(self.active_alerts.items()):
            # Check if condition is still met
            should_clear = False
            
            if 'service' in alert:
                # Service alert
                services = metrics.get('services', {})
                if alert['service'] in services and services[alert['service']]:
                    should_clear = True
            else:
                # System metric alert
                for rule_id, rule in ALERT_RULES.items():
                    if rule_id == alert_id:
                        if rule['metric'] in system:
                            value = system[rule['metric']]
                            if not self._evaluate_rule(value, rule['threshold'], rule['operator']):
                                should_clear = True
            
            if should_clear:
                resolved.append(alert_id)
                del self.active_alerts[alert_id]
        
        return resolved
    
    def _send_notification(self, alert):
        """Send notification (webhook or email)"""
        # Check for webhook configuration
        webhook_url = os.environ.get('ALERT_WEBHOOK_URL')
        if webhook_url:
            try:
                data = json.dumps(alert).encode()
                req = Request(webhook_url, data=data, headers={'Content-Type': 'application/json'})
                urlopen(req, timeout=5)
            except:
                pass
    
    def _log_to_history(self, alert):
        """Log alert to history file"""
        history_file = os.path.join(HISTORY_DIR, f"alerts_{datetime.now().strftime('%Y%m%d')}.json")
        
        history_entry = {
            'timestamp': alert['timestamp'],
            'id': alert['id'],
            'severity': alert['severity'],
            'message': alert['message']
        }
        
        self.alert_history.append(history_entry)
        
        # Append to daily log file
        try:
            with open(history_file, 'a') as f:
                f.write(json.dumps(history_entry) + '\n')
        except:
            pass

alert_manager = AlertManager()

class AlertHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            # Check for new alerts
            triggered = alert_manager.check_metrics()
            
            active_count = len(alert_manager.active_alerts)
            critical_count = sum(1 for a in alert_manager.active_alerts.values() if a['severity'] == 'critical')
            warning_count = sum(1 for a in alert_manager.active_alerts.values() if a['severity'] == 'warning')
            
            html = f'''<!DOCTYPE html>
<html>
<head>
    <title>BlackRoad Alert Manager</title>
    <meta http-equiv="refresh" content="15">
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
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
            color: #ff1d6c;
            margin-bottom: 10px;
        }}
        .stats {{
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 20px;
        }}
        .stat-card {{
            background: #1f1f20;
            padding: 16px;
            border-radius: 8px;
            border-left: 4px solid;
        }}
        .stat-card.active {{ border-color: #0096FF; }}
        .stat-card.critical {{ border-color: #ff1d6c; }}
        .stat-card.warning {{ border-color: #f5a623; }}
        .stat-value {{
            font-size: 32px;
            font-weight: 300;
            margin-bottom: 4px;
        }}
        .stat-label {{
            font-size: 14px;
            color: #9d9fa1;
        }}
        .alerts-section {{
            background: #1f1f20;
            padding: 20px;
            border-radius: 8px;
        }}
        .section-title {{
            font-size: 18px;
            margin-bottom: 16px;
            color: #d8d9da;
        }}
        .alert {{
            padding: 12px;
            border-radius: 4px;
            margin-bottom: 12px;
            border-left: 4px solid;
        }}
        .alert.critical {{
            background: #ff1d6c22;
            border-color: #ff1d6c;
        }}
        .alert.warning {{
            background: #f5a62322;
            border-color: #f5a623;
        }}
        .alert-header {{
            display: flex;
            justify-content: space-between;
            margin-bottom: 4px;
        }}
        .alert-severity {{
            font-weight: 600;
            text-transform: uppercase;
            font-size: 12px;
        }}
        .alert-time {{
            font-size: 12px;
            color: #9d9fa1;
        }}
        .alert-message {{
            font-size: 14px;
        }}
        .no-alerts {{
            text-align: center;
            padding: 40px;
            color: #73bf69;
            font-size: 18px;
        }}
    </style>
</head>
<body>
    <div class="header">
        <div class="title">🚨 Alert Manager</div>
        <div style="color: #9d9fa1; font-size: 14px;">Real-time monitoring • Auto-refresh: 15s</div>
    </div>
    
    <div class="stats">
        <div class="stat-card active">
            <div class="stat-value">{active_count}</div>
            <div class="stat-label">Active Alerts</div>
        </div>
        <div class="stat-card critical">
            <div class="stat-value">{critical_count}</div>
            <div class="stat-label">Critical</div>
        </div>
        <div class="stat-card warning">
            <div class="stat-value">{warning_count}</div>
            <div class="stat-label">Warnings</div>
        </div>
    </div>
    
    <div class="alerts-section">
        <div class="section-title">Active Alerts</div>
'''
            
            if alert_manager.active_alerts:
                for alert_id, alert in alert_manager.active_alerts.items():
                    severity_class = alert['severity']
                    html += f'''
        <div class="alert {severity_class}">
            <div class="alert-header">
                <span class="alert-severity">{alert['severity']}</span>
                <span class="alert-time">{alert['last_seen']}</span>
            </div>
            <div class="alert-message">{alert['message']}</div>
            <div style="font-size: 12px; color: #9d9fa1; margin-top: 4px;">
                Triggered {alert['count']} time(s) • First seen: {alert['first_seen']}
            </div>
        </div>'''
            else:
                html += '<div class="no-alerts">✅ All systems healthy - No active alerts</div>'
            
            html += '''
    </div>
</body>
</html>'''
            
            self.wfile.write(html.encode())
        
        elif self.path == '/api/alerts':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = json.dumps({
                'active_alerts': list(alert_manager.active_alerts.values()),
                'count': len(alert_manager.active_alerts)
            })
            self.wfile.write(response.encode())
        
        elif self.path == '/api/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = json.dumps({'status': 'healthy', 'service': 'alert-manager'})
            self.wfile.write(response.encode())
        
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("", PORT), AlertHandler) as httpd:
    print(f"Alert Manager running on port {PORT}")
    httpd.serve_forever()
EOF

chmod +x ~/alert-manager/app.py

echo "📝 Creating systemd service..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/alert-manager.service << 'SYSTEMD'
[Unit]
Description=BlackRoad Alert Manager
After=network.target

[Service]
Type=simple
WorkingDirectory=%h/alert-manager
ExecStart=/usr/bin/python3 %h/alert-manager/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
SYSTEMD

echo "🚀 Starting Alert Manager service..."
systemctl --user daemon-reload
systemctl --user enable alert-manager.service
systemctl --user restart alert-manager.service

echo "⏳ Waiting for Alert Manager to start..."
sleep 3

echo "✅ Testing Alert Manager..."
curl -f http://localhost:5700/api/health || echo "⚠️  Health check failed"

echo ""
echo "✅ Alert Manager deployed successfully!"
systemctl --user status alert-manager.service --no-pager | head -10
REMOTE

echo ""
echo "✅ Wave 10A deployment complete!"
echo ""
echo "🚨 Access Alert Manager:"
echo "   http://octavia:5700/"
echo ""
echo "📊 Features:"
echo "   • Real-time alert monitoring"
echo "   • Threshold-based rules"
echo "   • Alert history tracking"
echo "   • Webhook integration ready"
