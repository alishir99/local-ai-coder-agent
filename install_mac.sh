#!/bin/bash
# AI Code Agent - macOS Installation Script
# This script installs all dependencies and sets up the environment

set -e

echo "============================================"
echo "AI Code Agent - macOS Setup"
echo "============================================"
echo ""

# Check for Homebrew
echo "[1/6] Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✓ Homebrew installed"
fi
echo ""

# Check for Python
echo "[2/6] Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "Installing Python 3..."
    brew install python@3.11
else
    python3 --version
    echo "✓ Python installed"
fi
echo ""

# Check for Docker
echo "[3/6] Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "Docker not found!"
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    echo "After installation, restart this script."
    exit 1
else
    docker --version
    echo "✓ Docker installed"
fi
echo ""

# Check for Ollama
echo "[4/6] Checking Ollama installation..."
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
ollama serve &> /dev/null &
sleep 2

# Pull default models
echo "Pulling recommended models (this may take a while)..."
ollama pull qwen2.5-coder:1.5b
ollama pull phi3.5
echo "✓ Models installed"
echo ""

# Create virtual environment
echo "[5/6] Setting up Python virtual environment..."
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
echo "[6/6] Building Docker sandbox image..."
docker build -t ai-agent-python .
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
