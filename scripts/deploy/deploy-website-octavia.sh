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
# Deploy www.blackroad.io to octavia (has nginx already)
# No sudo required - just file creation and service reload

set -e

echo "🌌 Deploying www.blackroad.io to octavia"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Create website content
echo "[1/4] Creating website content..."
ssh octavia "mkdir -p ~/www.blackroad.io/public"

# Create index.html
cat << 'HTML' | ssh octavia 'cat > ~/www.blackroad.io/public/index.html'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlackRoad OS - Distributed AI Operating System</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 100%);
            color: #ffffff;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        header {
            padding: 4rem 2rem 2rem;
            text-align: center;
            background: rgba(255, 29, 108, 0.05);
            border-bottom: 2px solid #FF1D6C;
        }
        h1 {
            font-size: 4rem;
            background: linear-gradient(135deg, #FF1D6C 0%, #9C27B0 50%, #2979FF 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 1rem;
        }
        .tagline {
            font-size: 1.5rem;
            color: #F5A623;
            margin-bottom: 2rem;
        }
        main {
            flex: 1;
            padding: 4rem 2rem;
            max-width: 1200px;
            margin: 0 auto;
            width: 100%;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin: 3rem 0;
        }
        .card {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 29, 108, 0.3);
            border-radius: 1rem;
            padding: 2rem;
            transition: all 0.3s ease;
        }
        .card:hover {
            transform: translateY(-5px);
            border-color: #FF1D6C;
            box-shadow: 0 10px 30px rgba(255, 29, 108, 0.3);
        }
        .card h2 {
            color: #FF1D6C;
            margin-bottom: 1rem;
            font-size: 1.5rem;
        }
        .card p {
            line-height: 1.6;
            color: rgba(255, 255, 255, 0.8);
        }
        footer {
            text-align: center;
            padding: 2rem;
            border-top: 1px solid rgba(255, 29, 108, 0.3);
            color: rgba(255, 255, 255, 0.6);
        }
        .status {
            display: inline-block;
            padding: 0.5rem 1rem;
            background: rgba(82, 255, 168, 0.1);
            border: 1px solid #52FFA8;
            border-radius: 2rem;
            color: #52FFA8;
            font-size: 0.9rem;
            margin: 1rem 0;
        }
    </style>
</head>
<body>
    <header>
        <h1>BlackRoad OS</h1>
        <p class="tagline">Distributed AI Operating System</p>
        <span class="status">● ONLINE - Powered by octavia</span>
    </header>
    
    <main>
        <div class="grid">
            <div class="card">
                <h2>🤖 AI Fleet</h2>
                <p>Distributed AI inference across Raspberry Pi 5 + Hailo-8 accelerators. Real-time model serving with sub-50ms latency.</p>
            </div>
            
            <div class="card">
                <h2>🌐 Edge Computing</h2>
                <p>Cloudflare tunnels routing traffic to on-premises hardware. Zero-trust networking with global edge presence.</p>
            </div>
            
            <div class="card">
                <h2>🔊 TTS Pipeline</h2>
                <p>piper-tts running on all nodes. Natural voice synthesis with multiple language models. API endpoints ready.</p>
            </div>
            
            <div class="card">
                <h2>🔒 Security</h2>
                <p>fail2ban intrusion prevention, ufw firewall, Let's Encrypt SSL. Zero-knowledge architecture with end-to-end encryption.</p>
            </div>
            
            <div class="card">
                <h2>📧 Email Infrastructure</h2>
                <p>Postfix SMTP relay on all nodes. Automated alerts and notifications. SPF/DKIM/DMARC configured.</p>
            </div>
            
            <div class="card">
                <h2>📊 Monitoring</h2>
                <p>Real-time metrics with Prometheus + Grafana. Health checks, alerts, and auto-healing. <5min MTTR.</p>
            </div>
        </div>
        
        <div style="margin-top: 4rem; text-align: center;">
            <h2 style="color: #F5A623; margin-bottom: 2rem;">Lucidia · BlackRoad OS</h2>
            <p style="color: rgba(255,255,255,0.6);">Deployed: 2026-02-16 | Version: 0.1.0</p>
        </div>
    </main>
    
    <footer>
        <p>© 2026 BlackRoad OS | Powered by Raspberry Pi + Jetson + Cloudflare</p>
    </footer>
</body>
</html>
HTML

echo "✅ Website content created"

# Step 2: Create nginx config
echo "[2/4] Creating nginx configuration..."
cat << 'NGINX' | ssh octavia 'cat > ~/www.blackroad.io/nginx.conf'
server {
    listen 80;
    listen [::]:80;
    server_name www.blackroad.io blackroad.io;
    
    root /home/blackroad/www.blackroad.io/public;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
NGINX

echo "✅ nginx config created"

# Step 3: Test nginx config (requires sudo)
echo "[3/4] Testing nginx config..."
echo "⚠️  Skipping nginx test (requires sudo)"
echo "   Manual step: ssh octavia 'sudo nginx -t'"

# Step 4: Create deployment script for manual execution
echo "[4/4] Creating manual deployment script..."
cat << 'DEPLOY' | ssh octavia 'cat > ~/www.blackroad.io/deploy.sh && chmod +x ~/www.blackroad.io/deploy.sh'
#!/bin/bash
# Manual deployment script (run with sudo)

echo "🚀 Deploying www.blackroad.io..."

# Copy nginx config
sudo cp ~/www.blackroad.io/nginx.conf /etc/nginx/sites-available/www.blackroad.io
sudo ln -sf /etc/nginx/sites-available/www.blackroad.io /etc/nginx/sites-enabled/

# Test and reload nginx
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Deployed! Visit http://www.blackroad.io"
DEPLOY

echo "✅ Deployment script created"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Configuration deployed to octavia!"
echo ""
echo "Files created:"
echo "  ✅ ~/www.blackroad.io/public/index.html"
echo "  ✅ ~/www.blackroad.io/nginx.conf"
echo "  ✅ ~/www.blackroad.io/deploy.sh"
echo ""
echo "Manual step required (with sudo):"
echo "  ssh octavia '~/www.blackroad.io/deploy.sh'"
echo ""
echo "After deployment, www.blackroad.io will be live!"
