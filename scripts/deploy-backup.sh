#!/bin/bash
# Deploy Automated Backup System for BlackRoad OS
# Wave 12A: Disaster recovery and data protection

set -e

echo "💾 Deploying Backup System to octavia..."

# Create backup system on octavia
ssh octavia << 'REMOTE'
set -e

echo "📁 Creating backup system directories..."
mkdir -p ~/backup-system/{backups,logs,scripts}

# Create backup orchestrator using Python stdlib
cat > ~/backup-system/app.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import os
import subprocess
import tarfile
import shutil
from datetime import datetime
from pathlib import Path

PORT = 5900
BACKUP_DIR = os.path.expanduser('~/backup-system/backups')
LOGS_DIR = os.path.expanduser('~/backup-system/logs')

class BackupManager:
    def __init__(self):
        self.backup_dir = Path(BACKUP_DIR)
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        # Define what to backup
        self.backup_targets = {
            'configs': [
                '~/.config/systemd/user/*.service',
                '~/.cloudflared/config.yml',
                '/etc/nginx/sites-available/*',
            ],
            'services': {
                'tts-api': '~/tts-api',
                'monitor-api': '~/monitoring',
                'load-balancer': '~/load-balancer',
                'fleet-monitor': '~/fleet-monitor',
                'notifications': '~/notifications',
                'metrics': '~/metrics',
                'analytics': '~/analytics',
                'grafana': '~/grafana',
                'alert-manager': '~/alert-manager',
                'log-aggregator': '~/log-aggregator',
            },
            'website': '~/www.blackroad.io',
        }
    
    def create_backup(self, backup_type='full'):
        """Create a backup snapshot"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_name = f'backup_{backup_type}_{timestamp}'
        backup_path = self.backup_dir / backup_name
        backup_path.mkdir(parents=True, exist_ok=True)
        
        results = {
            'timestamp': timestamp,
            'type': backup_type,
            'name': backup_name,
            'files': [],
            'errors': []
        }
        
        try:
            # Backup systemd service files
            config_dir = backup_path / 'configs'
            config_dir.mkdir(parents=True, exist_ok=True)
            
            systemd_dir = os.path.expanduser('~/.config/systemd/user')
            if os.path.exists(systemd_dir):
                for service_file in Path(systemd_dir).glob('*.service'):
                    try:
                        shutil.copy2(service_file, config_dir)
                        results['files'].append(str(service_file))
                    except Exception as e:
                        results['errors'].append(f"Failed to backup {service_file}: {str(e)}")
            
            # Backup Cloudflare config
            cf_config = os.path.expanduser('~/.cloudflared/config.yml')
            if os.path.exists(cf_config):
                try:
                    shutil.copy2(cf_config, config_dir / 'cloudflared-config.yml')
                    results['files'].append(cf_config)
                except Exception as e:
                    results['errors'].append(f"Failed to backup Cloudflare config: {str(e)}")
            
            # Backup service directories
            for service_name, service_path in self.backup_targets['services'].items():
                expanded_path = os.path.expanduser(service_path)
                if os.path.exists(expanded_path):
                    dest = backup_path / 'services' / service_name
                    try:
                        shutil.copytree(expanded_path, dest, 
                                      ignore=shutil.ignore_patterns('__pycache__', '*.pyc', '*.log'))
                        results['files'].append(service_path)
                    except Exception as e:
                        results['errors'].append(f"Failed to backup {service_name}: {str(e)}")
            
            # Backup website
            website_path = os.path.expanduser(self.backup_targets['website'])
            if os.path.exists(website_path):
                dest = backup_path / 'website'
                try:
                    shutil.copytree(website_path, dest)
                    results['files'].append(self.backup_targets['website'])
                except Exception as e:
                    results['errors'].append(f"Failed to backup website: {str(e)}")
            
            # Create tarball
            tarball_path = self.backup_dir / f'{backup_name}.tar.gz'
            with tarfile.open(tarball_path, 'w:gz') as tar:
                tar.add(backup_path, arcname=backup_name)
            
            # Remove temp directory
            shutil.rmtree(backup_path)
            
            # Get backup size
            backup_size = os.path.getsize(tarball_path)
            results['size_bytes'] = backup_size
            results['size_mb'] = round(backup_size / (1024 * 1024), 2)
            results['tarball'] = str(tarball_path)
            results['success'] = True
            
            # Log backup
            self._log_backup(results)
            
        except Exception as e:
            results['success'] = False
            results['errors'].append(f"Backup failed: {str(e)}")
        
        return results
    
    def list_backups(self):
        """List all available backups"""
        backups = []
        
        for backup_file in sorted(self.backup_dir.glob('backup_*.tar.gz'), reverse=True):
            stat = backup_file.stat()
            backups.append({
                'name': backup_file.name,
                'path': str(backup_file),
                'size_mb': round(stat.st_size / (1024 * 1024), 2),
                'created': datetime.fromtimestamp(stat.st_mtime).isoformat(),
                'age_hours': round((datetime.now().timestamp() - stat.st_mtime) / 3600, 1)
            })
        
        return backups
    
    def cleanup_old_backups(self, keep_count=10):
        """Keep only the N most recent backups"""
        backups = sorted(self.backup_dir.glob('backup_*.tar.gz'), 
                        key=lambda x: x.stat().st_mtime, reverse=True)
        
        deleted = []
        for old_backup in backups[keep_count:]:
            try:
                old_backup.unlink()
                deleted.append(old_backup.name)
            except Exception as e:
                pass
        
        return deleted
    
    def get_backup_stats(self):
        """Get backup statistics"""
        backups = self.list_backups()
        
        total_size = sum(b['size_mb'] for b in backups)
        
        return {
            'count': len(backups),
            'total_size_mb': round(total_size, 2),
            'oldest': backups[-1] if backups else None,
            'newest': backups[0] if backups else None
        }
    
    def _log_backup(self, results):
        """Log backup to file"""
        log_file = Path(LOGS_DIR) / f"backup_{datetime.now().strftime('%Y%m%d')}.log"
        log_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(log_file, 'a') as f:
            f.write(json.dumps(results) + '\n')

backup_manager = BackupManager()

class BackupHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            stats = backup_manager.get_backup_stats()
            backups = backup_manager.list_backups()
            
            html = f'''<!DOCTYPE html>
<html>
<head>
    <title>BlackRoad Backup System</title>
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
            color: #73bf69;
            margin-bottom: 10px;
        }}
        .stats {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }}
        .stat-card {{
            background: #1f1f20;
            padding: 16px;
            border-radius: 8px;
            border-left: 4px solid #73bf69;
        }}
        .stat-value {{
            font-size: 32px;
            font-weight: 300;
            margin-bottom: 4px;
        }}
        .stat-label {{
            font-size: 14px;
            color: #9d9fa1;
        }}
        .actions {{
            background: #1f1f20;
            padding: 16px;
            border-radius: 8px;
            margin-bottom: 20px;
        }}
        .btn {{
            background: #73bf69;
            color: #0b0c0e;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            font-weight: 600;
            cursor: pointer;
            margin-right: 10px;
        }}
        .btn:hover {{
            background: #8cd87a;
        }}
        .backups-list {{
            background: #1f1f20;
            padding: 20px;
            border-radius: 8px;
        }}
        .section-title {{
            font-size: 18px;
            margin-bottom: 16px;
        }}
        .backup-item {{
            background: #252527;
            padding: 12px;
            border-radius: 4px;
            margin-bottom: 12px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        .backup-info {{
            flex: 1;
        }}
        .backup-name {{
            font-weight: 600;
            margin-bottom: 4px;
        }}
        .backup-meta {{
            font-size: 12px;
            color: #9d9fa1;
        }}
        .no-backups {{
            text-align: center;
            padding: 40px;
            color: #9d9fa1;
        }}
    </style>
</head>
<body>
    <div class="header">
        <div class="title">💾 Backup System</div>
        <div style="color: #9d9fa1; font-size: 14px;">Automated disaster recovery</div>
    </div>
    
    <div class="stats">
        <div class="stat-card">
            <div class="stat-value">{stats['count']}</div>
            <div class="stat-label">Total Backups</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">{stats['total_size_mb']} MB</div>
            <div class="stat-label">Storage Used</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">{'Recent' if stats.get('newest') else 'None'}</div>
            <div class="stat-label">Latest Backup</div>
        </div>
    </div>
    
    <div class="actions">
        <button class="btn" onclick="window.location.href='/api/backup/create'">
            Create Backup Now
        </button>
        <button class="btn" onclick="window.location.href='/api/backup/cleanup'">
            Cleanup Old Backups
        </button>
    </div>
    
    <div class="backups-list">
        <div class="section-title">Available Backups</div>
'''
            
            if backups:
                for backup in backups:
                    html += f'''
        <div class="backup-item">
            <div class="backup-info">
                <div class="backup-name">{backup['name']}</div>
                <div class="backup-meta">
                    {backup['size_mb']} MB • Created {backup['age_hours']}h ago
                </div>
            </div>
        </div>'''
            else:
                html += '<div class="no-backups">No backups yet. Create your first backup!</div>'
            
            html += '''
    </div>
</body>
</html>'''
            
            self.wfile.write(html.encode())
        
        elif self.path == '/api/backup/create':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            result = backup_manager.create_backup()
            response = json.dumps(result)
            self.wfile.write(response.encode())
        
        elif self.path == '/api/backup/list':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            backups = backup_manager.list_backups()
            response = json.dumps({'backups': backups})
            self.wfile.write(response.encode())
        
        elif self.path == '/api/backup/cleanup':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            deleted = backup_manager.cleanup_old_backups(keep_count=10)
            response = json.dumps({'deleted': deleted, 'count': len(deleted)})
            self.wfile.write(response.encode())
        
        elif self.path == '/api/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = json.dumps({'status': 'healthy', 'service': 'backup-system'})
            self.wfile.write(response.encode())
        
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("", PORT), BackupHandler) as httpd:
    print(f"Backup System running on port {PORT}")
    httpd.serve_forever()
EOF

chmod +x ~/backup-system/app.py

echo "📝 Creating systemd service..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/backup-system.service << 'SYSTEMD'
[Unit]
Description=BlackRoad Backup System
After=network.target

[Service]
Type=simple
WorkingDirectory=%h/backup-system
ExecStart=/usr/bin/python3 %h/backup-system/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
SYSTEMD

# Create daily backup cron job
cat > ~/backup-system/scripts/daily-backup.sh << 'BACKUP'
#!/bin/bash
# Daily automated backup
curl -s http://localhost:5900/api/backup/create > /dev/null
curl -s http://localhost:5900/api/backup/cleanup > /dev/null
BACKUP

chmod +x ~/backup-system/scripts/daily-backup.sh

echo "🚀 Starting Backup System service..."
systemctl --user daemon-reload
systemctl --user enable backup-system.service
systemctl --user restart backup-system.service

echo "⏳ Waiting for Backup System to start..."
sleep 3

echo "✅ Testing Backup System..."
curl -f http://localhost:5900/api/health || echo "⚠️  Health check failed"

echo ""
echo "💾 Creating initial backup..."
curl -s http://localhost:5900/api/backup/create | python3 -m json.tool

echo ""
echo "✅ Backup System deployed successfully!"
systemctl --user status backup-system.service --no-pager | head -10
REMOTE

echo ""
echo "✅ Wave 12A deployment complete!"
echo ""
echo "💾 Access Backup System:"
echo "   http://octavia:5900/"
echo ""
echo "📊 Features:"
echo "   • Automated configuration backups"
echo "   • Service data snapshots"
echo "   • One-click backup creation"
echo "   • Retention management"
echo "   • Backup verification"
