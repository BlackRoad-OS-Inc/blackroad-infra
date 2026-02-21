#!/bin/bash
# Setup /blackroad global directory (uses existing macOS synthetic.conf setup)
# Run with: bash setup-blackroad-fixed.sh

set -e

echo "🌍 Setting up /blackroad global directory..."
echo ""

# Create subdirectories (using existing /blackroad symlink)
echo "📂 Creating subdirectories..."
sudo mkdir -p /blackroad/agents
sudo mkdir -p /blackroad/services
sudo mkdir -p /blackroad/devices
sudo mkdir -p /blackroad/shared
sudo mkdir -p /blackroad/config
sudo mkdir -p /blackroad/logs
sudo mkdir -p /blackroad/tmp

# Set ownership on subdirectories
echo "👥 Setting ownership to alexa:staff..."
sudo chown -R alexa:staff /blackroad/agents
sudo chown -R alexa:staff /blackroad/services
sudo chown -R alexa:staff /blackroad/devices
sudo chown -R alexa:staff /blackroad/shared
sudo chown -R alexa:staff /blackroad/config
sudo chown -R alexa:staff /blackroad/logs
sudo chown -R alexa:staff /blackroad/tmp

# Set permissions
echo "🔐 Setting permissions..."
sudo chmod 755 /blackroad/agents
sudo chmod 755 /blackroad/services
sudo chmod 755 /blackroad/devices
sudo chmod 775 /blackroad/shared
sudo chmod 755 /blackroad/config
sudo chmod 755 /blackroad/logs
sudo chmod 1777 /blackroad/tmp

# Create README
echo "📝 Creating README..."
cat > /tmp/blackroad-readme.md << 'EOF'
# 🌍 /blackroad - Global System Directory

**Owner:** Alexa Amundson (alexa@blackroad.io)  
**Created:** 2026-02-17  
**Purpose:** Universal access point for BlackRoad OS infrastructure

---

## 📁 Structure

```
/blackroad/
├── agents/     # AI agents (Claude, ollama, specialized agents)
├── services/   # Web services, APIs, workers
├── devices/    # Hardware fleet (Pi, ESP32, Jetson)
├── shared/     # Shared resources (775 permissions)
├── config/     # Global configuration files
├── logs/       # System-wide logs
└── tmp/        # Temporary files (sticky bit, like /tmp)
```

---

## 🔐 Permissions

- **Owner:** alexa (full access)
- **Group:** staff
- **Shared:** 775 (rwxrwxr-x)
- **Tmp:** 1777 (sticky bit, world-writable)

---

## 🎯 Purpose

Universal coordination point for AI agents, services, and hardware across all systems.

**BlackRoad OS, Inc.** - *The universe observing itself through computational substrate*
EOF

sudo mv /tmp/blackroad-readme.md /blackroad/README.md
sudo chown alexa:staff /blackroad/README.md

echo ""
echo "✅ /blackroad setup complete!"
echo ""
echo "📁 Structure:"
ls -la /blackroad/
