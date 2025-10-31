@echo off
REM AI Code Agent - Windows Installation Script
REM This script installs all dependencies and sets up the environment

echo ============================================
echo AI Code Agent - Windows Setup
echo ============================================
echo.

REM Check for Python
echo [1/5] Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python not found! Please install Python 3.10+ from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)
python --version
echo.

REM Check for Docker
echo [2/5] Checking Docker installation...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker not found!
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop/
    echo After installation, restart this script.
    pause
    exit /b 1
)
docker --version
echo.

REM Check for Ollama
echo [3/5] Checking Ollama installation...
where ollama >nul 2>&1
if %errorlevel% neq 0 (
    echo Ollama not found!
    echo Installing Ollama...
    powershell -Command "Invoke-WebRequest -Uri https://ollama.com/download/OllamaSetup.exe -OutFile OllamaSetup.exe"
    start /wait OllamaSetup.exe
    del OllamaSetup.exe
    echo.
    echo Ollama installed! Please restart this script to continue.
    pause
    exit /b 0
)

REM Pull default models
echo Pulling recommended models (this may take a while)...
ollama pull qwen2.5-coder:1.5b
ollama pull phi3.5
echo Models installed!
echo.

REM Create virtual environment
echo [4/5] Setting up Python virtual environment...
if not exist "venv" (
    python -m venv venv
)
call venv\Scripts\activate.bat

REM Install Python dependencies
echo Installing Python packages...
pip install --upgrade pip
pip install -r requirements.txt
echo.

REM Build Docker sandbox
echo [5/5] Building Docker sandbox image...
docker build -t ai-agent-python .
echo.

echo ============================================
echo Installation Complete!
echo ============================================
echo.
echo To start the AI Code Agent:
echo   1. Run: venv\Scripts\activate.bat
echo   2. Run: python ui.py
echo   3. Open browser at http://127.0.0.1:7860
echo.
echo Optional: Pull more models with:
echo   ollama pull llama3.1
echo   ollama pull codellama:13b
echo.
pause
