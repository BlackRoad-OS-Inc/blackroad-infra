#!/bin/bash
# PM2 Ecosystem Configuration for BlackRoad Services
# Use PM2 for production-grade process management

cat > /tmp/blackroad-ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'blackroad-auth',
      cwd: process.env.HOME + '/services/auth',
      script: 'npm',
      args: 'run dev',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'development',
        PORT: 3004
      },
      error_file: process.env.HOME + '/.blackroad/logs/auth-error.log',
      out_file: process.env.HOME + '/.blackroad/logs/auth-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },
    {
      name: 'blackroad-domains',
      cwd: process.env.HOME + '/services/domains',
      script: 'npm',
      args: 'run dev',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'development',
        PORT: 3005
      },
      error_file: process.env.HOME + '/.blackroad/logs/domains-error.log',
      out_file: process.env.HOME + '/.blackroad/logs/domains-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },
    {
      name: 'copilot-gateway',
      cwd: process.env.HOME + '/copilot-agent-gateway',
      script: 'web-server.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3030,
        BLACKROAD_AI_ENDPOINT: 'http://localhost:11434'
      },
      error_file: process.env.HOME + '/.blackroad/logs/gateway-error.log',
      out_file: process.env.HOME + '/.blackroad/logs/gateway-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    }
  ]
}
EOF

echo "✓ PM2 ecosystem config created at /tmp/blackroad-ecosystem.config.js"
echo ""
echo "To use PM2:"
echo "  1. Install: npm install -g pm2"
echo "  2. Start: pm2 start /tmp/blackroad-ecosystem.config.js"
echo "  3. Monitor: pm2 monit"
echo "  4. Status: pm2 status"
echo "  5. Logs: pm2 logs"
echo "  6. Save: pm2 save"
echo "  7. Startup: pm2 startup"
echo ""
echo "PM2 provides:"
echo "  - Auto-restart on crash"
echo "  - Memory limits and restart"
echo "  - Log management"
echo "  - Load balancing"
echo "  - Startup scripts"
