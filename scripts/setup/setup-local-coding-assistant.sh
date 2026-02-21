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
# Quick Setup Script for BlackRoad Local Coding Assistant
# Installs all dependencies and configures the environment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PINK='\033[38;5;205m'
NC='\033[0m'

echo -e "${PINK}"
cat <<'BANNER'
╔═══════════════════════════════════════════════════════════╗
║  BlackRoad Local Coding Assistant - Setup                ║
║  One-command installation for local AI coding            ║
╚═══════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
  echo -e "${YELLOW}Installing Ollama...${NC}"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install ollama
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    curl -fsSL https://ollama.com/install.sh | sh
  else
    echo -e "${YELLOW}⚠ Please install Ollama manually from https://ollama.com${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Ollama installed${NC}"
else
  echo -e "${GREEN}✓ Ollama already installed${NC}"
fi

# Start Ollama if not running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
  echo -e "${YELLOW}Starting Ollama server...${NC}"
  ollama serve > /dev/null 2>&1 &
  sleep 3
  echo -e "${GREEN}✓ Ollama server started${NC}"
else
  echo -e "${GREEN}✓ Ollama server running${NC}"
fi

# Pull recommended coding model
echo -e "${YELLOW}Pulling qwen2.5-coder:7b (4.7GB - this may take a few minutes)...${NC}"
if ! ollama list | grep -q "qwen2.5-coder:7b"; then
  ollama pull qwen2.5-coder:7b
  echo -e "${GREEN}✓ Model downloaded${NC}"
else
  echo -e "${GREEN}✓ Model already downloaded${NC}"
fi

# Install Aider (optional but recommended)
echo ""
read -p "Install Aider for agentic workflows? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Installing aider-chat...${NC}"
  pip3 install aider-chat
  echo -e "${GREEN}✓ Aider installed${NC}"
fi

# Add to PATH if not already there
if ! grep -q "export PATH=\"\$HOME:\$PATH\"" ~/.zshrc 2>/dev/null; then
  echo -e "${YELLOW}Adding ~/br-code-assistant to PATH...${NC}"
  echo 'export PATH="$HOME:$PATH"' >> ~/.zshrc
  echo -e "${GREEN}✓ Added to PATH${NC}"
  echo -e "${YELLOW}ℹ Run 'source ~/.zshrc' or restart terminal${NC}"
fi

# Test installation
echo ""
echo -e "${PINK}Testing installation...${NC}"
if ~/br-code-assistant --help > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Installation successful!${NC}"
else
  echo -e "${YELLOW}⚠ Warning: Test failed, but components are installed${NC}"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Setup Complete!                                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Quick Start:"
echo "  1. Run: br-code-assistant"
echo "  2. Or: br-code-assistant chat"
echo "  3. Or: br-code-assistant task 'your coding task'"
echo ""
echo "Documentation: ~/BlackRoad-Private/docs/LOCAL_CODING_ASSISTANT.md"
echo ""
