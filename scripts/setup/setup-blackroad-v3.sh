#!/bin/bash
# Setup /blackroad - Create base directory first, then subdirectories

set -e

echo "🌍 Setting up /blackroad global directory..."
echo ""

# First, ensure the base directory is writable
echo "📁 Setting up base directory..."
sudo chmod 755 /System/Volumes/Data/blackroad
sudo chown alexa:staff /System/Volumes/Data/blackroad

# Now create subdirectories
echo "📂 Creating subdirectories..."
mkdir -p /blackroad/agents
mkdir -p /blackroad/services
mkdir -p /blackroad/devices
mkdir -p /blackroad/shared
mkdir -p /blackroad/config
mkdir -p /blackroad/logs
mkdir -p /blackroad/tmp

# Set permissions
echo "🔐 Setting permissions..."
chmod 755 /blackroad/agents
chmod 755 /blackroad/services
chmod 755 /blackroad/devices
chmod 775 /blackroad/shared
chmod 755 /blackroad/config
chmod 755 /blackroad/logs
chmod 1777 /blackroad/tmp

# Create README
echo "📝 Creating README..."
cat > /blackroad/README.md << 'EOF'
# 🌍 /blackroad - Global System Directory

**Owner:** Alexa Amundson  
**Created:** 2026-02-17  
**Purpose:** Universal access point for BlackRoad OS infrastructure

## 📁 Structure

```
/blackroad/
├── agents/     # AI agents (Claude, ollama, specialized agents)
├── services/   # Web services, APIs, workers  
├── devices/    # Hardware fleet (Pi, ESP32, Jetson)
├── shared/     # Shared resources (775 permissions)
├── config/     # Global configuration files
├── logs/       # System-wide logs
└── tmp/        # Temporary files (sticky bit)
```

## 🎯 Purpose

Universal coordination point for AI agents, services, and hardware across all systems.

**BlackRoad OS, Inc.** - *The universe observing itself through computational substrate*
EOF

echo ""
echo "✅ /blackroad setup complete!"
echo ""
echo "📁 Structure:"
ls -laR /blackroad/
