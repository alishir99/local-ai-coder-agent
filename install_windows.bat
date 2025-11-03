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
)
docker --version
echo.

REM Check for Ollama
echo [3/5] Checking Ollama installation...
where ollama >nul 2>&1
if %errorlevel% neq 0 (
    echo Ollama not found!
    echo.
    echo Please install Ollama manually:
    echo   1. Open https://ollama.com/download in your browser
    echo   2. Download and run OllamaSetup.exe
    echo   3. After installation completes, restart this script
    echo.
    echo Alternative: Use winget (if available):
    echo   winget install Ollama.Ollama
    echo.
    echo Press any key to try automatic installation (may take a few minutes)...
    pause >nul
    echo.
    echo Downloading Ollama installer...
    powershell -Command "try { $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile 'OllamaSetup.exe' -TimeoutSec 30 } catch { Write-Host 'Download failed. Please install manually.'; exit 1 }"
    if %errorlevel% neq 0 (
        echo.
        echo Download failed. Please install Ollama manually from https://ollama.com/download
        pause
        goto :eof
    )
    echo Starting Ollama installer...
    echo Note: The installer window will open. Please complete the installation.
    start /wait OllamaSetup.exe /S
    del OllamaSetup.exe 2>nul
    echo.
    echo Ollama installation complete! Checking...
    timeout /t 5 >nul
    where ollama >nul 2>&1
    if %errorlevel% neq 0 (
        echo Ollama not detected. You may need to restart your terminal or computer.
        echo After restarting, run this script again.
        pause
        goto :eof
    )
)

REM Start Ollama service if not running
echo Starting Ollama service...
start /B ollama serve >nul 2>&1
timeout /t 3 >nul

REM Pull default models
echo Pulling recommended models (this may take a while)...
echo This might take 5-10 minutes depending on your internet speed.
echo.
echo Pulling qwen2.5-coder:1.5b (smallest, fastest)...
ollama pull qwen2.5-coder:1.5b
if %errorlevel% neq 0 (
    echo Warning: Failed to pull qwen2.5-coder:1.5b
    echo You can manually pull it later with: ollama pull qwen2.5-coder:1.5b
)
echo.
echo Pulling phi3.5...
ollama pull phi3.5
if %errorlevel% neq 0 (
    echo Warning: Failed to pull phi3.5
    echo You can manually pull it later with: ollama pull phi3.5
)
echo Models installation complete!
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
