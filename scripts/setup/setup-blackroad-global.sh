#!/bin/bash
# Setup /BlackRoad global directory
# Run with: bash setup-blackroad-global.sh

set -e

echo "🌍 Creating /BlackRoad global directory..."
echo ""

# Create the directory
echo "📁 Creating /BlackRoad..."
sudo mkdir -p /BlackRoad

# Set ownership
echo "👤 Setting ownership to alexa:staff..."
sudo chown alexa:staff /BlackRoad

# Set permissions
echo "🔐 Setting permissions (755)..."
sudo chmod 755 /BlackRoad

# Create subdirectories
echo "📂 Creating subdirectories..."
sudo mkdir -p /BlackRoad/agents
sudo mkdir -p /BlackRoad/services
sudo mkdir -p /BlackRoad/devices
sudo mkdir -p /BlackRoad/shared
sudo mkdir -p /BlackRoad/config
sudo mkdir -p /BlackRoad/logs
sudo mkdir -p /BlackRoad/tmp

# Set ownership on subdirectories
echo "👥 Setting ownership on subdirectories..."
sudo chown -R alexa:staff /BlackRoad/agents
sudo chown -R alexa:staff /BlackRoad/services
sudo chown -R alexa:staff /BlackRoad/devices
sudo chown -R alexa:staff /BlackRoad/shared
sudo chown -R alexa:staff /BlackRoad/config
sudo chown -R alexa:staff /BlackRoad/logs
sudo chown -R alexa:staff /BlackRoad/tmp

# Set special permissions
echo "✨ Setting special permissions..."
sudo chmod 1777 /BlackRoad/tmp
sudo chmod 775 /BlackRoad/shared

# Create README
echo "📝 Creating README..."
cat > /BlackRoad/README.md << 'EOF'
# 🌍 /BlackRoad - Global System Directory

**Owner:** Alexa Amundson (alexa@blackroad.io)  
**Created:** 2026-02-17  
**Purpose:** Universal access point for BlackRoad OS infrastructure

---

## 📁 Structure

```
/BlackRoad/
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
- **Base:** 755 (rwxr-xr-x)
- **Shared:** 775 (rwxrwxr-x)
- **Tmp:** 1777 (sticky bit, world-writable)

---

## 🎯 Purpose

This is the **universal coordination point** for:
- ✅ AI agents across multiple systems
- ✅ Service orchestration
- ✅ Hardware fleet management
- ✅ Cross-system resource sharing
- ✅ Safe multi-user/multi-AI access

---

## 🌌 Philosophy

**"Above everything, accessible to all, owned by one, safe for everyone"**

BlackRoad OS, Inc. - The universe observing itself through computational substrate
EOF

echo ""
echo "✅ /BlackRoad created successfully!"
echo ""
echo "📁 Structure:"
ls -la /BlackRoad/
