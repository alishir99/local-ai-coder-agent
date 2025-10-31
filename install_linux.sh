#!/bin/bash
# AI Code Agent - Linux Installation Script
# This script installs all dependencies and sets up the environment

set -e

echo "============================================"
echo "AI Code Agent - Linux Setup"
echo "============================================"
echo ""

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect Linux distribution"
    exit 1
fi

# Check for Python
echo "[1/5] Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "Installing Python 3..."
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sudo apt update
        sudo apt install -y python3 python3-pip python3-venv
    elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
        sudo dnf install -y python3 python3-pip
    elif [ "$OS" = "arch" ] || [ "$OS" = "manjaro" ]; then
        sudo pacman -S --noconfirm python python-pip
    else
        echo "Unsupported distribution. Please install Python 3.10+ manually."
        exit 1
    fi
else
    python3 --version
    echo "✓ Python installed"
fi
echo ""

# Check for Docker
echo "[2/5] Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sudo apt update
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
    elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
        sudo dnf install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
    elif [ "$OS" = "arch" ] || [ "$OS" = "manjaro" ]; then
        sudo pacman -S --noconfirm docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
    fi
    echo "✓ Docker installed"
    echo "Note: You may need to log out and back in for Docker permissions to take effect"
else
    docker --version
    echo "✓ Docker installed"
fi
echo ""

# Check for Ollama
echo "[3/5] Checking Ollama installation..."
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo "✓ Ollama installed"
else
    ollama --version
    echo "✓ Ollama already installed"
fi
echo ""

# Start Ollama service
echo "Starting Ollama service..."
if ! pgrep -x ollama > /dev/null; then
    ollama serve &> /dev/null &
    sleep 2
fi

# Pull default models
echo "Pulling recommended models (this may take a while)..."
ollama pull qwen2.5-coder:1.5b
ollama pull phi3.5
echo "✓ Models installed"
echo ""

# Create virtual environment
echo "[4/5] Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

# Install Python dependencies
echo "Installing Python packages..."
pip install --upgrade pip
pip install -r requirements.txt
echo "✓ Python packages installed"
echo ""

# Build Docker sandbox
echo "[5/5] Building Docker sandbox image..."
sudo docker build -t ai-agent-python .
echo "✓ Docker image built"
echo ""

echo "============================================"
echo "Installation Complete!"
echo "============================================"
echo ""
echo "To start the AI Code Agent:"
echo "  1. Run: source venv/bin/activate"
echo "  2. Run: python ui.py"
echo "  3. Open browser at http://127.0.0.1:7860"
echo ""
echo "Optional: Pull more models with:"
echo "  ollama pull llama3.1"
echo "  ollama pull codellama:13b"
echo ""
echo "If you just installed Docker, you may need to:"
echo "  1. Log out and log back in"
echo "  2. Or run: newgrp docker"
echo ""
