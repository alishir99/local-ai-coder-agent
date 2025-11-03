@echo off
REM AI Code Agent - Windows Installation Script
REM This script installs all dependencies and sets up the environment

REM Keep window open on script errors
if "%1"=="" (
    cmd /k "%~f0" continue
    exit
)

setlocal enabledelayedexpansion
set "ERRORS="
set "ERROR_COUNT=0"

echo ============================================
echo AI Code Agent - Windows Setup
echo ============================================
echo.
echo Checking prerequisites...
echo.

REM Check for Python
echo [1/5] Checking Python installation
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [MISSING] Python not found - attempting automatic installation
    echo.
    call :install_python
) else (
    python --version
    echo [OK] Python found!
)
echo.

REM Check for Docker
echo [2/5] Checking Docker installation
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [MISSING] Docker not found - attempting automatic installation
    echo.
    call :install_docker
) else (
    docker --version
    echo [OK] Docker found!
)
echo.

REM Check for Ollama
echo [3/5] Checking Ollama installation
where ollama >nul 2>&1
if %errorlevel% neq 0 (
    echo [MISSING] Ollama not found - attempting automatic installation
    echo.
    call :install_ollama
) else (
    ollama --version 2>nul
    echo [OK] Ollama found!
)
echo.

REM If there are missing prerequisites, show them and exit
if %ERROR_COUNT% gtr 0 (
    echo.
    echo ============================================
    echo Missing Prerequisites: %ERROR_COUNT%
    echo ============================================
    echo.
    echo Please install the following:
    echo.
    echo !ERRORS!
    echo After installing, run this script again.
    echo.
    pause
    goto :eof
)

echo ============================================
echo All prerequisites found! Starting setup...
echo ============================================
echo.

REM Start Ollama service if not running
echo [3/5] Starting Ollama service
start /B ollama serve >nul 2>&1
timeout /t 3 >nul
echo [OK] Ollama service started
echo.

REM Pull default models
echo Pulling recommended AI models (this may take 5-10 minutes)
echo.
echo [Model 1/2] Pulling qwen2.5-coder:1.5b (smallest, fastest)
ollama pull qwen2.5-coder:1.5b
if %errorlevel% neq 0 (
    echo [WARNING] Failed to pull qwen2.5-coder:1.5b
    echo You can manually pull it later with: ollama pull qwen2.5-coder:1.5b
) else (
    echo [OK] qwen2.5-coder:1.5b installed
)
echo.
echo [Model 2/2] Pulling phi3.5
ollama pull phi3.5
if %errorlevel% neq 0 (
    echo [WARNING] Failed to pull phi3.5
    echo You can manually pull it later with: ollama pull phi3.5
) else (
    echo [OK] phi3.5 installed
)
echo.

REM Create virtual environment
echo [4/5] Setting up Python virtual environment
if not exist "venv" (
    echo Creating virtual environment
    python -m venv venv
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to create virtual environment!
        set /a ERROR_COUNT+=1
    ) else (
        echo [OK] Virtual environment created
    )
) else (
    echo [OK] Virtual environment already exists
)

if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
    echo [OK] Virtual environment activated
) else (
    echo [ERROR] Virtual environment activation script not found!
    set /a ERROR_COUNT+=1
)
echo.

REM Install Python dependencies
echo Installing Python packages (this may take a minute)
pip install --upgrade pip >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Failed to upgrade pip (continuing anyway)
)
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install Python packages!
    echo Check your internet connection and try again.
    set /a ERROR_COUNT+=1
) else (
    echo [OK] Python packages installed
)
echo.

REM Build Docker sandbox
echo [5/5] Building Docker sandbox image
echo This may take a few minutes on first run
docker build -t ai-agent-python .
if %errorlevel% neq 0 (
    echo [ERROR] Docker build failed!
    echo Make sure Docker Desktop is running and try again.
    set /a ERROR_COUNT+=1
) else (
    echo [OK] Docker image built successfully
)
echo.

REM Final summary
echo ============================================
if %ERROR_COUNT% gtr 0 (
    echo Installation Completed with %ERROR_COUNT% error(s)
    echo ============================================
    echo.
    echo Some steps failed. Please review the errors above.
    echo You may need to fix the issues and run this script again.
    echo.
    echo Press any key to exit
    pause >nul
) else (
    echo Installation Complete!
    echo ============================================
    echo.
    echo ✓ All components installed successfully!
    echo.
    echo Optional: Pull more models with:
    echo   ollama pull llama3.1
    echo   ollama pull codellama:13b
    echo.
    echo ============================================
    echo.
    set /p "RUN_NOW=Do you want to start the AI Code Agent now? [Y/N]: "
    if /i "%RUN_NOW%"=="Y" (
        echo.
        echo Starting AI Code Agent...
        echo The UI will open in your browser at http://127.0.0.1:7860
        echo Press Ctrl+C to stop the server when done.
        echo.
        call venv\Scripts\activate.bat
        python ui.py
    ) else (
        echo.
        echo To start the AI Code Agent later:
        echo   1. Run: venv\Scripts\activate.bat
        echo   2. Run: python ui.py
        echo   3. Open browser at http://127.0.0.1:7860
        echo.
    )
)
goto :eof

REM Subroutine to install Python
:install_python
    REM Try winget first
    echo Trying winget installation
    winget --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo Installing Python via winget
        winget install -e --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
        if %errorlevel% equ 0 (
            echo [OK] Python installed via winget
            echo Refreshing PATH
            timeout /t 3 >nul
            python --version >nul 2>&1
            if %errorlevel% neq 0 (
                echo [WARNING] Python installed but not in PATH yet
                echo You need to restart your terminal or computer
                echo After restarting, run this script again
                set "ERRORS=!ERRORS!- Restart required after Python installation\n"
                set /a ERROR_COUNT+=1
            )
            goto :eof
        ) else (
            echo [WARNING] winget installation failed, trying manual download
        )
    ) else (
        echo winget not available, trying manual installation
    )
    
    REM Manual download and installation
    echo Downloading Python installer
    powershell -Command "try { $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe' -OutFile 'python-installer.exe' -TimeoutSec 60 } catch { Write-Host 'Download failed.'; exit 1 }"
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to download Python
        set "ERRORS=!ERRORS!- Python 3.10+ from https://www.python.org/downloads/ (manual installation required)\n"
        set /a ERROR_COUNT+=1
        goto :eof
    )
    
    echo Installing Python (this may take a few minutes)
    echo IMPORTANT: Installing with "Add to PATH" option
    start /wait python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    del python-installer.exe 2>nul
    echo [OK] Python installer completed
    timeout /t 5 >nul
    python --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo [WARNING] Python installed but not in PATH yet
        echo You need to restart your terminal or computer
        echo After restarting, run this script again
        set "ERRORS=!ERRORS!- Restart required after Python installation\n"
        set /a ERROR_COUNT+=1
    ) else (
        echo [OK] Python available in PATH
    )
    goto :eof

REM Subroutine to install Docker
:install_docker
    REM Try winget first
    echo Trying winget installation
    winget --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo Installing Docker Desktop via winget
        winget install -e --id Docker.DockerDesktop --silent --accept-package-agreements --accept-source-agreements
        if %errorlevel% equ 0 (
            echo [OK] Docker Desktop installed via winget
            echo.
            echo IMPORTANT: Docker Desktop has been installed
            echo Please start Docker Desktop manually from the Start Menu
            echo Wait for it to fully start (green icon in system tray)
            echo Then run this script again
            echo.
            set "ERRORS=!ERRORS!- Start Docker Desktop and run this script again\n"
            set /a ERROR_COUNT+=1
            goto :eof
        ) else (
            echo [WARNING] winget installation failed, trying manual download
        )
    ) else (
        echo winget not available, trying manual installation
    )
    
    REM Manual download and installation
    echo Downloading Docker Desktop installer
    powershell -Command "try { $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' -OutFile 'DockerDesktopInstaller.exe' -TimeoutSec 120 } catch { Write-Host 'Download failed.'; exit 1 }"
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to download Docker Desktop
        set "ERRORS=!ERRORS!- Docker Desktop from https://www.docker.com/products/docker-desktop/ (manual installation required)\n"
        set /a ERROR_COUNT+=1
        goto :eof
    )
    
    echo Installing Docker Desktop (this may take several minutes)
    echo The installer will open - please follow the installation wizard
    start /wait DockerDesktopInstaller.exe install --quiet
    del DockerDesktopInstaller.exe 2>nul
    echo [OK] Docker Desktop installer completed
    echo.
    echo IMPORTANT: Docker Desktop has been installed
    echo Please start Docker Desktop manually from the Start Menu
    echo Wait for it to fully start (green icon in system tray)
    echo Then run this script again
    echo.
    set "ERRORS=!ERRORS!- Start Docker Desktop and run this script again\n"
    set /a ERROR_COUNT+=1
    goto :eof

REM Subroutine to install Ollama
:install_ollama
    REM Try winget first (faster and more reliable)
    echo Trying winget installation
    winget --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo Installing Ollama via winget
        winget install -e --id Ollama.Ollama --silent --accept-package-agreements --accept-source-agreements
        if %errorlevel% equ 0 (
            echo [OK] Ollama installed via winget
            echo Refreshing PATH
            timeout /t 3 >nul
            where ollama >nul 2>&1
            if %errorlevel% neq 0 (
                echo Note: You may need to restart your terminal for ollama to be available in PATH
                echo Continuing with setup
            )
            goto :eof
        ) else (
            echo [WARNING] winget installation failed, trying manual download
        )
    ) else (
        echo winget not available, trying manual installation
    )
    
    REM Manual download and installation
    echo Downloading Ollama installer
    powershell -Command "try { $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile 'OllamaSetup.exe' -TimeoutSec 60 } catch { Write-Host 'Download failed.'; exit 1 }"
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to download Ollama
        set "ERRORS=!ERRORS!- Ollama from https://ollama.com/download (manual installation required)\n"
        set /a ERROR_COUNT+=1
        goto :eof
    )
    
    echo Installing Ollama (this may take a minute)
    start /wait OllamaSetup.exe /S
    del OllamaSetup.exe 2>nul
    echo [OK] Ollama installer completed
    timeout /t 5 >nul
    where ollama >nul 2>&1
    if %errorlevel% neq 0 (
        echo [WARNING] Ollama installed but not in PATH yet
        echo You may need to restart your terminal
    ) else (
        echo [OK] Ollama available in PATH
    )
    goto :eof
