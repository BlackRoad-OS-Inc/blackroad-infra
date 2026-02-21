#!/bin/bash
# Wave 13: Performance Optimization & Query Caching

echo "⚡ Wave 13: Performance Optimization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🎯 Deploying to octavia..."
echo ""

ssh octavia 'bash -s' << 'REMOTE_SCRIPT'

echo "📊 Creating performance cache service..."

mkdir -p ~/perf-cache
cat > ~/perf-cache/app.py << 'PYTHON_EOF'
#!/usr/bin/env python3
"""Performance Cache Service - Reduce backend load with smart caching"""

import http.server
import socketserver
import json
import urllib.request
import urllib.error
import hashlib
import time
import os
from datetime import datetime

PORT = 6000

# In-memory cache
cache = {}
cache_hits = 0
cache_misses = 0
cache_size_limit = 1000  # Max entries

# Backend services to cache
BACKENDS = {
    'tts': 'http://localhost:5001',
    'monitor': 'http://localhost:5002',
    'metrics': 'http://localhost:5400',
    'analytics': 'http://localhost:5500'
}

def get_cache_key(url, params):
    """Generate cache key from URL and params"""
    key_str = f"{url}:{json.dumps(params, sort_keys=True)}"
    return hashlib.md5(key_str.encode()).hexdigest()

def get_cached(key):
    """Get from cache if fresh"""
    global cache_hits, cache_misses
    if key in cache:
        entry = cache[key]
        # Check TTL (time-to-live)
        if time.time() - entry['timestamp'] < entry['ttl']:
            cache_hits += 1
            return entry['data']
    cache_misses += 1
    return None

def set_cache(key, data, ttl=60):
    """Store in cache with TTL"""
    global cache
    if len(cache) >= cache_size_limit:
        # Evict oldest entry
        oldest_key = min(cache.keys(), key=lambda k: cache[k]['timestamp'])
        del cache[oldest_key]
    
    cache[key] = {
        'data': data,
        'timestamp': time.time(),
        'ttl': ttl
    }

def fetch_from_backend(service, endpoint, params):
    """Fetch from backend service"""
    try:
        url = f"{BACKENDS[service]}{endpoint}"
        if params:
            url += '?' + '&'.join([f"{k}={v}" for k, v in params.items()])
        
        with urllib.request.urlopen(url, timeout=5) as response:
            return response.read().decode()
    except Exception as e:
        return json.dumps({'error': str(e)})

class CacheHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests with caching"""
        global cache_hits, cache_misses
        
        if self.path == '/':
            self.send_dashboard()
        elif self.path == '/api/health':
            self.send_json({'status': 'healthy', 'service': 'perf-cache'})
        elif self.path == '/api/stats':
            total = cache_hits + cache_misses
            hit_rate = (cache_hits / total * 100) if total > 0 else 0
            self.send_json({
                'cache_hits': cache_hits,
                'cache_misses': cache_misses,
                'hit_rate': f"{hit_rate:.1f}%",
                'cache_size': len(cache),
                'cache_limit': cache_size_limit
            })
        elif self.path.startswith('/api/cache/'):
            # Parse cache request: /api/cache/{service}/{endpoint}
            parts = self.path.split('/')
            if len(parts) >= 5:
                service = parts[3]
                endpoint = '/' + '/'.join(parts[4:])
                
                # Parse query params
                params = {}
                if '?' in endpoint:
                    endpoint, query = endpoint.split('?', 1)
                    params = dict(p.split('=') for p in query.split('&') if '=' in p)
                
                # Generate cache key
                cache_key = get_cache_key(f"{service}{endpoint}", params)
                
                # Try cache first
                cached_data = get_cached(cache_key)
                if cached_data:
                    self.send_json(json.loads(cached_data), cached=True)
                else:
                    # Fetch from backend
                    data = fetch_from_backend(service, endpoint, params)
                    # Cache with different TTLs based on endpoint
                    ttl = 30 if 'health' in endpoint else 60
                    set_cache(cache_key, data, ttl)
                    self.send_json(json.loads(data), cached=False)
            else:
                self.send_json({'error': 'Invalid cache path'})
        elif self.path == '/api/cache/clear':
            cache.clear()
            self.send_json({'message': 'Cache cleared', 'entries_removed': len(cache)})
        else:
            self.send_error(404)
    
    def send_json(self, data, cached=None):
        """Send JSON response"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        if cached is not None:
            self.send_header('X-Cache', 'HIT' if cached else 'MISS')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def send_dashboard(self):
        """Send HTML dashboard"""
        total = cache_hits + cache_misses
        hit_rate = (cache_hits / total * 100) if total > 0 else 0
        
        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Performance Cache</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: 'Monaco', monospace;
            background: #0a0a0a;
            color: #00ff88;
            padding: 20px;
        }}
        .container {{ max-width: 1200px; margin: 0 auto; }}
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
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
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
        .hit {{ color: #00ff88; }}
        .miss {{ color: #ff4444; }}
        .neutral {{ color: #00aaff; }}
        .actions {{
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }}
        button {{
            background: #00ff88;
            color: #0a0a0a;
            border: none;
            padding: 12px 24px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.3s;
        }}
        button:hover {{ background: #00cc66; transform: translateY(-2px); }}
        .examples {{
            background: #1a1a1a;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #333;
            margin-top: 20px;
        }}
        .example {{ 
            background: #0a0a0a;
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
            border-left: 3px solid #00ff88;
            font-family: 'Courier New', monospace;
            font-size: 12px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚡ Performance Cache</h1>
            <div class="subtitle">Smart caching layer for BlackRoad services</div>
        </div>
        
        <div class="stats">
            <div class="stat">
                <div class="stat-label">Cache Hit Rate</div>
                <div class="stat-value hit">{hit_rate:.1f}%</div>
            </div>
            <div class="stat">
                <div class="stat-label">Cache Hits</div>
                <div class="stat-value hit">{cache_hits}</div>
            </div>
            <div class="stat">
                <div class="stat-label">Cache Misses</div>
                <div class="stat-value miss">{cache_misses}</div>
            </div>
            <div class="stat">
                <div class="stat-label">Cached Entries</div>
                <div class="stat-value neutral">{len(cache)} / {cache_size_limit}</div>
            </div>
        </div>
        
        <div class="actions">
            <button onclick="location.reload()">🔄 Refresh Stats</button>
            <button onclick="clearCache()">🗑️ Clear Cache</button>
        </div>
        
        <div class="examples">
            <h3 style="margin-bottom: 15px;">📖 Usage Examples</h3>
            <div class="example">
                # Cache TTS API health check<br>
                curl http://octavia:6000/api/cache/tts/api/health
            </div>
            <div class="example">
                # Cache monitor API stats<br>
                curl http://octavia:6000/api/cache/monitor/api/stats
            </div>
            <div class="example">
                # Cache metrics data<br>
                curl http://octavia:6000/api/cache/metrics/api/metrics
            </div>
            <div class="example">
                # Check cache statistics<br>
                curl http://octavia:6000/api/stats
            </div>
        </div>
    </div>
    
    <script>
        function clearCache() {{
            fetch('/api/cache/clear')
                .then(r => r.json())
                .then(data => {{
                    alert(data.message);
                    location.reload();
                }});
        }}
        
        // Auto-refresh every 10 seconds
        setTimeout(() => location.reload(), 10000);
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
    with socketserver.TCPServer(("", PORT), CacheHandler) as httpd:
        print(f"⚡ Performance Cache running on port {PORT}")
        httpd.serve_forever()
PYTHON_EOF

chmod +x ~/perf-cache/app.py

echo "📝 Creating systemd service..."
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/perf-cache.service << 'SERVICE_EOF'
[Unit]
Description=BlackRoad Performance Cache
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/blackroad/perf-cache/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
SERVICE_EOF

echo "🚀 Starting Performance Cache service..."
systemctl --user daemon-reload
systemctl --user enable perf-cache.service
systemctl --user restart perf-cache.service

sleep 3

echo "✅ Testing Performance Cache..."
curl -s http://localhost:6000/api/health

echo ""
echo "✅ Wave 13 deployment complete!"
systemctl --user status perf-cache.service --no-pager

REMOTE_SCRIPT

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Performance Cache deployed!"
echo ""
echo "⚡ Access:"
echo "   http://octavia:6000/"
echo ""
echo "📊 Features:"
echo "   • Smart query caching"
echo "   • 60-second TTL"
echo "   • 1000-entry LRU cache"
echo "   • Cache hit/miss tracking"
echo "   • X-Cache headers"
echo "   • One-click cache clear"
