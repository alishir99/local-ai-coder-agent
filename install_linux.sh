#!/bin/bash
# AI Code Agent - Linux Installation Script
# This script installs all dependencies and sets up the environment

ERROR_COUNT=0
ERRORS=""

echo "============================================"
echo "AI Code Agent - Linux Setup"
echo "============================================"
echo ""
echo "Checking prerequisites..."
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
echo "[1/5] Checking Python installation"
if ! command -v python3 &> /dev/null; then
    echo "[MISSING] Python not found - attempting automatic installation"
    echo ""
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        echo "Installing Python 3 via apt"
        sudo apt update
        sudo apt install -y python3 python3-pip python3-venv
        if [ $? -eq 0 ]; then
            echo "[OK] Python installed"
        else
            echo "[ERROR] Failed to install Python"
            ERRORS="${ERRORS}- Python 3.10+\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
        echo "Installing Python 3 via dnf"
        sudo dnf install -y python3 python3-pip
        if [ $? -eq 0 ]; then
            echo "[OK] Python installed"
        else
            echo "[ERROR] Failed to install Python"
            ERRORS="${ERRORS}- Python 3.10+\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    elif [ "$OS" = "arch" ] || [ "$OS" = "manjaro" ]; then
        echo "Installing Python via pacman"
        sudo pacman -S --noconfirm python python-pip
        if [ $? -eq 0 ]; then
            echo "[OK] Python installed"
        else
            echo "[ERROR] Failed to install Python"
            ERRORS="${ERRORS}- Python 3.10+\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    else
        echo "[ERROR] Unsupported distribution for automatic installation"
        ERRORS="${ERRORS}- Python 3.10+ (manual installation required)\n"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
else
    python3 --version
    echo "[OK] Python found"
fi
echo ""

# Check for Docker
echo "[2/5] Checking Docker installation"
if ! command -v docker &> /dev/null; then
    echo "[MISSING] Docker not found - attempting automatic installation"
    echo ""
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        echo "Installing Docker via apt"
        sudo apt update
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        if [ $? -eq 0 ]; then
            echo "[OK] Docker installed"
            echo "[WARNING] You may need to log out and back in for Docker permissions"
        else
            echo "[ERROR] Failed to install Docker"
            ERRORS="${ERRORS}- Docker\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
        echo "Installing Docker via dnf"
        sudo dnf install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        if [ $? -eq 0 ]; then
            echo "[OK] Docker installed"
            echo "[WARNING] You may need to log out and back in for Docker permissions"
        else
            echo "[ERROR] Failed to install Docker"
            ERRORS="${ERRORS}- Docker\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    elif [ "$OS" = "arch" ] || [ "$OS" = "manjaro" ]; then
        echo "Installing Docker via pacman"
        sudo pacman -S --noconfirm docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        if [ $? -eq 0 ]; then
            echo "[OK] Docker installed"
            echo "[WARNING] You may need to log out and back in for Docker permissions"
        else
            echo "[ERROR] Failed to install Docker"
            ERRORS="${ERRORS}- Docker\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    else
        echo "[ERROR] Unsupported distribution for automatic installation"
        ERRORS="${ERRORS}- Docker (manual installation required)\n"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
else
    docker --version
    echo "[OK] Docker found"
fi
echo ""

# Check for Ollama
echo "[3/5] Checking Ollama installation"
if ! command -v ollama &> /dev/null; then
    echo "[MISSING] Ollama not found - attempting automatic installation"
    echo ""
    echo "Installing Ollama via official script"
    curl -fsSL https://ollama.com/install.sh | sh
    if [ $? -eq 0 ]; then
        echo "[OK] Ollama installed"
    else
        echo "[ERROR] Failed to install Ollama"
        ERRORS="${ERRORS}- Ollama from https://ollama.com\n"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
else
    ollama --version
    echo "[OK] Ollama found"
fi
echo ""

# If there are missing prerequisites, show them and exit
if [ $ERROR_COUNT -gt 0 ]; then
    echo ""
    echo "============================================"
    echo "Missing Prerequisites: $ERROR_COUNT"
    echo "============================================"
    echo ""
    echo "Please install the following:"
    echo ""
    echo -e "$ERRORS"
    echo "After installing, run this script again."
    echo ""
    exit 1
fi

echo "============================================"
echo "All prerequisites found! Starting setup..."
echo "============================================"
echo ""

# Start Ollama service
echo "[3/5] Starting Ollama service"
if ! pgrep -x ollama > /dev/null; then
    ollama serve &> /dev/null &
    sleep 2
fi
echo "[OK] Ollama service started"
echo ""

# Pull default models
echo "Pulling recommended AI models (this may take 5-10 minutes)"
echo ""
echo "[Model 1/2] Pulling qwen2.5-coder:1.5b (smallest, fastest)"
ollama pull qwen2.5-coder:1.5b
if [ $? -eq 0 ]; then
    echo "[OK] qwen2.5-coder:1.5b installed"
else
    echo "[WARNING] Failed to pull qwen2.5-coder:1.5b"
    echo "You can manually pull it later with: ollama pull qwen2.5-coder:1.5b"
fi
echo ""
echo "[Model 2/2] Pulling phi3.5"
ollama pull phi3.5
if [ $? -eq 0 ]; then
    echo "[OK] phi3.5 installed"
else
    echo "[WARNING] Failed to pull phi3.5"
    echo "You can manually pull it later with: ollama pull phi3.5"
fi
echo ""

# Create virtual environment
echo "[4/5] Setting up Python virtual environment"
if [ ! -d "venv" ]; then
    echo "Creating virtual environment"
    python3 -m venv venv
    if [ $? -eq 0 ]; then
        echo "[OK] Virtual environment created"
    else
        echo "[ERROR] Failed to create virtual environment"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
else
    echo "[OK] Virtual environment already exists"
fi

if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "[OK] Virtual environment activated"
else
    echo "[ERROR] Virtual environment activation script not found"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# Install Python dependencies
echo "Installing Python packages (this may take a minute)"
pip install --upgrade pip > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[WARNING] Failed to upgrade pip (continuing anyway)"
fi
pip install -r requirements.txt
if [ $? -eq 0 ]; then
    echo "[OK] Python packages installed"
else
    echo "[ERROR] Failed to install Python packages"
    echo "Check your internet connection and try again"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# Build Docker sandbox
echo "[5/5] Building Docker sandbox image"
echo "This may take a few minutes on first run"
sudo docker build -t ai-agent-python .
if [ $? -eq 0 ]; then
    echo "[OK] Docker image built successfully"
else
    echo "[ERROR] Docker build failed"
    echo "Make sure Docker is running and try again"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# Final summary
echo "============================================"
if [ $ERROR_COUNT -gt 0 ]; then
    echo "Installation Completed with $ERROR_COUNT error(s)"
    echo "============================================"
    echo ""
    echo "Some steps failed. Please review the errors above."
    echo "You may need to fix the issues and run this script again."
else
    echo "Installation Complete!"
    echo "============================================"
    echo ""
    echo "✓ All components installed successfully!"
    echo ""
    echo "To start the AI Code Agent:"
    echo "  1. Run: source venv/bin/activate"
    echo "  2. Run: python ui.py"
    echo "  3. Open browser at http://127.0.0.1:7860"
    echo ""
    echo "Optional: Pull more models with:"
    echo "  ollama pull llama3.1"
    echo "  ollama pull codellama:13b"
fi
echo ""
if groups | grep -q docker; then
    :
else
    echo "Note: If you just installed Docker, you may need to:"
    echo "  1. Log out and log back in"
    echo "  2. Or run: newgrp docker"
    echo ""
fi
