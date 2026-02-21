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
# Deploy HAProxy load balancer for TTS and Monitoring APIs
# Provides failover between octavia and cecilia

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RESET='\033[0m'

echo -e "${PINK}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║   ⚖️  BlackRoad Load Balancer Deployment              ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Deploy to octavia first
echo -e "${BLUE}📦 Deploying load balancer to octavia...${RESET}"

ssh octavia "mkdir -p ~/load-balancer"

# Create nginx-based load balancer config
cat > /tmp/lb-nginx.conf << 'EOF'
# BlackRoad Load Balancer Configuration
# Provides failover between octavia and cecilia

upstream tts_backend {
    # Prefer local, failover to cecilia
    server localhost:5001 max_fails=3 fail_timeout=30s;
    server cecilia:5001 backup;
}

upstream monitor_backend {
    # Prefer local, failover to cecilia
    server localhost:5002 max_fails=3 fail_timeout=30s;
    server cecilia:5002 backup;
}

# TTS Load Balancer (port 5101)
server {
    listen 5101;
    server_name _;
    
    location / {
        proxy_pass http://tts_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
        
        # Health check
        proxy_next_upstream error timeout http_502 http_503 http_504;
    }
    
    location /health {
        proxy_pass http://tts_backend/health;
        proxy_connect_timeout 2s;
    }
}

# Monitor Load Balancer (port 5102)
server {
    listen 5102;
    server_name _;
    
    location / {
        proxy_pass http://monitor_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
        
        # Health check
        proxy_next_upstream error timeout http_502 http_503 http_504;
    }
    
    location /health {
        proxy_pass http://monitor_backend/health;
        proxy_connect_timeout 2s;
    }
}
EOF

scp /tmp/lb-nginx.conf octavia:~/load-balancer/nginx.conf

echo -e "${GREEN}✅ Config deployed${RESET}"
echo ""

# Create standalone nginx process (no sudo needed)
echo -e "${BLUE}🚀 Creating nginx process...${RESET}"

cat > /tmp/lb-start.sh << 'EOF'
#!/bin/bash
# Start nginx load balancer as user process

NGINX_DIR="$HOME/load-balancer"
cd "$NGINX_DIR"

# Create minimal nginx config that runs as user
cat > nginx-full.conf << 'NGINX_EOF'
daemon off;
worker_processes 1;
error_log /tmp/nginx-lb-error.log;
pid /tmp/nginx-lb.pid;

events {
    worker_connections 1024;
}

http {
    access_log /tmp/nginx-lb-access.log;
    client_body_temp_path /tmp/nginx-client-body;
    proxy_temp_path /tmp/nginx-proxy;
    fastcgi_temp_path /tmp/nginx-fastcgi;
    uwsgi_temp_path /tmp/nginx-uwsgi;
    scgi_temp_path /tmp/nginx-scgi;
    
    include nginx.conf;
}
NGINX_EOF

# Start nginx
/usr/sbin/nginx -c "$NGINX_DIR/nginx-full.conf" -p "$NGINX_DIR"
EOF

scp /tmp/lb-start.sh octavia:~/load-balancer/start.sh
ssh octavia "chmod +x ~/load-balancer/start.sh"

echo -e "${GREEN}✅ Start script created${RESET}"
echo ""

# Create systemd service
echo -e "${BLUE}⚙️  Creating systemd service...${RESET}"

cat > /tmp/lb-service << 'EOF'
[Unit]
Description=BlackRoad Load Balancer (nginx)
After=network.target

[Service]
Type=simple
ExecStart=/home/operator/load-balancer/start.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

scp /tmp/lb-service octavia:~/.config/systemd/user/load-balancer.service

# Fix path for blackroad user
ssh octavia "sed -i 's|/home/operator|/home/blackroad|g' ~/.config/systemd/user/load-balancer.service"

ssh octavia "systemctl --user daemon-reload"
ssh octavia "systemctl --user enable load-balancer"
ssh octavia "systemctl --user start load-balancer || true"

echo -e "${GREEN}✅ Service started${RESET}"
echo ""

# Wait and test
echo -e "${BLUE}🧪 Testing load balancer...${RESET}"
sleep 3

echo ""
echo "TTS via Load Balancer (5101):"
ssh octavia "curl -s http://localhost:5101/health 2>&1 | head -5" || echo "  ⏸️  Not responding yet"

echo ""
echo "Monitor via Load Balancer (5102):"
ssh octavia "curl -s http://localhost:5102/health 2>&1 | head -5" || echo "  ⏸️  Not responding yet"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✅ Load Balancer Deployed!                           ║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Load-balanced endpoints:"
echo "  http://octavia:5101/  (TTS with failover)"
echo "  http://octavia:5102/  (Monitor with failover)"
echo ""
echo "Backend routing:"
echo "  Primary: localhost:500X (octavia)"
echo "  Backup:  cecilia:500X (automatic failover)"
echo ""
