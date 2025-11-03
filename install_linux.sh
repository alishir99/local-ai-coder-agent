#!/bin/sh
# AI Code Agent - Linux Installation Script
# This script installs all dependencies and sets up the environment
# Compatible with bash, sh, and ash (Alpine/BusyBox)

set -e

# Detect if running in WSL
IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
    IS_WSL=1
    echo "✓ Detected WSL environment"
    echo ""
fi

echo "============================================"
echo "AI Code Agent - Linux Setup"
echo "============================================"
echo ""

# Detect Linux distribution
OS="unknown"

# First check for Alpine (common in minimal WSL)
if [ -f /etc/alpine-release ] || command -v apk > /dev/null 2>&1; then
    OS="alpine"
    echo "✓ Detected Alpine Linux"
# Then try os-release
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ -n "$ID" ]; then
        OS=$ID
    fi
fi

# If still unknown, try other detection methods
if [ "$OS" = "unknown" ]; then
    echo "⚠ Cannot detect Linux distribution automatically"
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
    elif [ "$OS" = "alpine" ]; then
        echo "✓ Detected Alpine Linux"
        apk add --no-cache python3 py3-pip py3-virtualenv
    else
        echo "⚠ Unsupported distribution for automatic installation."
        echo "Please install Python 3.10+ manually, then re-run this script."
        echo ""
        echo "Quick install commands for common distros:"
        echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv"
        echo "  Alpine:        apk add python3 py3-pip py3-virtualenv"
        echo "  Fedora:        sudo dnf install python3 python3-pip"
        exit 1
    fi
else
    python3 --version
    echo "✓ Python installed"
fi
echo ""

# Check for Docker
echo "[2/5] Checking Docker installation..."
if [ "$IS_WSL" = "1" ]; then
    echo "⚠ Running in WSL - Docker Desktop integration required"
    echo ""
    echo "To use Docker in WSL:"
    echo "  1. Install Docker Desktop on Windows (if not already installed)"
    echo "  2. In Docker Desktop settings: Settings > Resources > WSL Integration"
    echo "  3. Enable integration for your WSL distro"
    echo "  4. Restart WSL: run 'wsl --shutdown' in Windows PowerShell"
    echo ""
    if command -v docker &> /dev/null; then
        # Test if docker actually works
        if docker info &> /dev/null; then
            docker --version
            echo "✓ Docker is working via Docker Desktop"
        else
            echo "⚠ Docker command found but not functional"
            echo "Please enable WSL integration in Docker Desktop settings"
        fi
    else
        echo "⚠ Docker command not found"
        echo "Please install Docker Desktop on Windows and enable WSL integration"
    fi
elif ! command -v docker &> /dev/null; then
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
    elif [ "$OS" = "alpine" ]; then
        apk add --no-cache docker
        rc-update add docker boot
        service docker start
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
OLLAMA_INSTALLED=0
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    
    # Ensure curl or wget is available
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        echo "Installing curl (required for Ollama installation)..."
        if [ "$OS" = "alpine" ]; then
            apk add --no-cache curl
        elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
            sudo apt update && sudo apt install -y curl
        elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
            sudo dnf install -y curl
        elif [ "$OS" = "arch" ] || [ "$OS" = "manjaro" ]; then
            sudo pacman -S --noconfirm curl
        else
            echo "⚠ Cannot install curl automatically"
            echo "Please install curl first: apk add curl (for Alpine)"
        fi
    fi
    
    if command -v curl &> /dev/null; then
        # Note: Ollama install script may not support Alpine in WSL
        if curl -fsSL https://ollama.com/install.sh | sh; then
            echo "✓ Ollama installed"
            OLLAMA_INSTALLED=1
        else
            echo "⚠ Ollama installation failed"
            echo "For WSL, you may want to install Ollama on Windows instead:"
            echo "  https://ollama.com/download/windows"
        fi
    else
        echo "⚠ Cannot install Ollama automatically (curl not available)"
        echo "For WSL, install Ollama on Windows instead:"
        echo "  https://ollama.com/download/windows"
    fi
else
    ollama --version
    echo "✓ Ollama already installed"
    OLLAMA_INSTALLED=1
fi
echo ""

# Only proceed with Ollama steps if it's installed
if [ "$OLLAMA_INSTALLED" = "1" ]; then
    # Start Ollama service
    echo "Starting Ollama service..."
    if ! pgrep -x ollama > /dev/null; then
        ollama serve &> /dev/null &
        sleep 2
    fi

    # Pull default models
    echo "Pulling recommended models (this may take a while)..."
    echo "This might take 5-10 minutes depending on your internet speed."
    if ollama pull qwen2.5-coder:1.5b; then
        echo "✓ qwen2.5-coder:1.5b installed"
    else
        echo "⚠ Failed to pull qwen2.5-coder:1.5b"
    fi
    
    if ollama pull phi3.5; then
        echo "✓ phi3.5 installed"
    else
        echo "⚠ Failed to pull phi3.5"
    fi
    echo ""
else
    echo "⚠ Skipping Ollama model downloads (Ollama not available)"
    echo "Recommendation for WSL: Install Ollama on Windows and access it from WSL"
    echo ""
fi

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
if command -v docker &> /dev/null && docker info &> /dev/null; then
    # Determine if sudo is needed
    if [ "$IS_WSL" = "1" ] || docker info &> /dev/null 2>&1; then
        docker build -t ai-agent-python .
    else
        sudo docker build -t ai-agent-python .
    fi
    echo "✓ Docker image built"
else
    echo "⚠ Docker not available - skipping image build"
    echo "You can build the image later with: docker build -t ai-agent-python ."
fi
echo ""

echo "============================================"
echo "Installation Complete!"
echo "============================================"
echo ""

# Show summary of what needs attention
NEEDS_ATTENTION=0
if [ "$IS_WSL" = "1" ]; then
    if ! docker info &> /dev/null 2>&1; then
        echo "⚠ ACTION REQUIRED: Docker Desktop WSL Integration"
        echo "  1. Open Docker Desktop on Windows"
        echo "  2. Go to Settings > Resources > WSL Integration"
        echo "  3. Enable your WSL distro"
        echo "  4. Run 'wsl --shutdown' in Windows PowerShell"
        echo "  5. Restart WSL"
        echo ""
        NEEDS_ATTENTION=1
    fi
    
    if [ "$OLLAMA_INSTALLED" = "0" ]; then
        echo "⚠ ACTION REQUIRED: Install Ollama on Windows"
        echo "  Download from: https://ollama.com/download/windows"
        echo "  After installation, you can access it from WSL"
        echo ""
        NEEDS_ATTENTION=1
    fi
fi

if [ "$NEEDS_ATTENTION" = "0" ]; then
    echo "✓ All components installed successfully!"
    echo ""
fi

echo "To start the AI Code Agent:"
echo "  1. Run: source venv/bin/activate"
echo "  2. Run: python ui.py"
echo "  3. Open browser at http://127.0.0.1:7860"
echo ""
echo "Optional: Pull more models with:"
echo "  ollama pull llama3.1"
echo "  ollama pull codellama:13b"
echo ""
if [ "$IS_WSL" = "0" ] && [ "$NEEDS_ATTENTION" = "1" ]; then
    echo "If you just installed Docker, you may need to:"
    echo "  1. Log out and log back in"
    echo "  2. Or run: newgrp docker"
    echo ""
fi
