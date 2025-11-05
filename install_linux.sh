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
    . venv/bin/activate
    echo "[OK] Virtual environment activated"
else
    echo "[ERROR] Virtual environment activation script not found"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# Install Python dependencies
echo "Installing Python packages (this may take a minute)"
echo ""

# Make sure we're using venv's pip
if [ -f "venv/bin/pip" ]; then
    echo "Upgrading pip..."
    venv/bin/pip install --upgrade pip
    echo ""
    echo "Installing requirements..."
    venv/bin/pip install -r requirements.txt
    if [ $? -eq 0 ]; then
        echo ""
        echo "[OK] Python packages installed"
        
        # Verify critical packages
        echo "Verifying installation..."
        if venv/bin/python -c "import gradio" 2>/dev/null; then
            echo "[OK] Gradio verified"
        else
            echo "[ERROR] Gradio installation failed"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    else
        echo ""
        echo "[ERROR] Failed to install Python packages"
        echo "Check your internet connection and try again"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
else
    echo "[ERROR] pip not found in virtual environment"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
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

# Create launcher script
echo "Creating launcher script..."
cat > run.sh << 'LAUNCHER_EOF'
#!/bin/sh
# AI Code Agent - Launcher Script
# This script ensures the virtual environment is activated and runs the UI

cd "$(dirname "$0")"

if [ ! -d "venv" ]; then
    echo "Error: Virtual environment not found!"
    echo "Please run the installer first: bash install_linux.sh"
    exit 1
fi

if [ ! -f "venv/bin/python" ]; then
    echo "Error: Python not found in virtual environment!"
    echo "Please re-run the installer: bash install_linux.sh"
    exit 1
fi

echo "============================================"
echo "Starting AI Code Agent"
echo "============================================"
echo ""
echo "UI will be available at: http://127.0.0.1:7860"
echo "Press Ctrl+C to stop the server"
echo ""

# Use venv's python directly (no activation needed)
exec venv/bin/python ui.py
LAUNCHER_EOF

chmod +x run.sh
echo "✓ Launcher script created: ./run.sh"
echo ""

# Show summary
echo "✓ All components installed successfully!"
echo ""

echo "To start the AI Code Agent:"
echo "  EASY WAY: ./run.sh"
echo ""
echo "  OR manually:"
echo "    1. Run: . venv/bin/activate"
echo "    2. Run: python ui.py"
echo "    3. Open browser at http://127.0.0.1:7860"
echo ""
echo "Optional: Pull more models with:"
echo "  ollama pull llama3.1"
echo "  ollama pull codellama:13b"
echo ""
