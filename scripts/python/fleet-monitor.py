#!/usr/bin/env python3
"""
BlackRoad Fleet Monitor - Real-time Pi metrics API
Serves JSON data for all fleet devices
"""
import json
import subprocess
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime

FLEET = {
    'aria': '192.168.4.82',
    'lucidia': '192.168.4.81',
    'alice': '192.168.4.49',
    'octavia': '192.168.4.38',
    'cecilia': '192.168.4.89'
}

def get_device_metrics(hostname, ip):
    """Get real-time metrics from a Pi"""
    try:
        # Get uptime
        uptime_cmd = f"ssh -o ConnectTimeout=3 {hostname} 'uptime'"
        uptime_raw = subprocess.check_output(uptime_cmd, shell=True, timeout=5).decode().strip()
        
        # Parse load average
        load_parts = uptime_raw.split('load average:')[1].strip().split(',')
        load_1min = float(load_parts[0].strip())
        
        # Get memory
        mem_cmd = f"ssh -o ConnectTimeout=3 {hostname} \"free -m | grep Mem:\""
        mem_raw = subprocess.check_output(mem_cmd, shell=True, timeout=5).decode().strip()
        mem_parts = mem_raw.split()
        mem_total = int(mem_parts[1])
        mem_used = int(mem_parts[2])
        mem_percent = round((mem_used / mem_total) * 100, 1)
        
        # Get disk
        disk_cmd = f"ssh -o ConnectTimeout=3 {hostname} \"df -h / | tail -1\""
        disk_raw = subprocess.check_output(disk_cmd, shell=True, timeout=5).decode().strip()
        disk_parts = disk_raw.split()
        disk_used = disk_parts[4].replace('%', '')
        
        # Get CPU count
        cpu_cmd = f"ssh -o ConnectTimeout=3 {hostname} 'nproc'"
        cpu_count = subprocess.check_output(cpu_cmd, shell=True, timeout=5).decode().strip()
        
        # Check Ollama
        ollama_cmd = f"ssh -o ConnectTimeout=3 {hostname} 'pgrep ollama >/dev/null && echo running || echo stopped'"
        ollama_status = subprocess.check_output(ollama_cmd, shell=True, timeout=5).decode().strip()
        
        return {
            'hostname': hostname,
            'ip': ip,
            'status': 'online',
            'load': load_1min,
            'cpu_cores': int(cpu_count),
            'memory_percent': mem_percent,
            'memory_used_mb': mem_used,
            'memory_total_mb': mem_total,
            'disk_percent': int(disk_used),
            'ollama': ollama_status,
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }
    except Exception as e:
        return {
            'hostname': hostname,
            'ip': ip,
            'status': 'offline',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }

class MonitorHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Silence logs
    
    def do_GET(self):
        if self.path == '/api/fleet':
            # Get metrics from all devices
            metrics = {}
            for hostname, ip in FLEET.items():
                print(f"Fetching {hostname}...")
                metrics[hostname] = get_device_metrics(hostname, ip)
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(metrics, indent=2).encode())
        
        elif self.path == '/':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(b"""
<!DOCTYPE html>
<html><body style="font-family: monospace; padding: 20px; background: #000; color: #fff;">
<h1 style="color: #FF0066;">BlackRoad Fleet Monitor API</h1>
<p>Endpoints:</p>
<ul>
  <li><a href="/api/fleet" style="color: #0066FF;">/api/fleet</a> - Get all fleet metrics (JSON)</li>
</ul>
<p>Dashboard: <a href="file:///Users/alexa/blackroad-live-monitor.html" style="color: #FF0066;">blackroad-live-monitor.html</a></p>
</body></html>
""")
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    PORT = 8888
    print(f"🚀 BlackRoad Fleet Monitor API")
    print(f"   Listening on: http://localhost:{PORT}")
    print(f"   Endpoint: http://localhost:{PORT}/api/fleet")
    print(f"   Monitoring: {', '.join(FLEET.keys())}")
    print(f"\n   Press Ctrl+C to stop")
    
    server = HTTPServer(('localhost', PORT), MonitorHandler)
    server.serve_forever()
