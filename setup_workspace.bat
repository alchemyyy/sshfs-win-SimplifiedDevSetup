@echo off
setlocal EnableDelayedExpansion

:: ============================================================================
:: SSHFS-Win Workspace Setup Script
:: Installs Cygwin, WinFsp, and all required packages
:: ============================================================================

echo ============================================
echo   SSHFS-Win Workspace Setup
echo ============================================
echo.

:: Configuration
set CYGWIN_ROOT=C:\cygwin64
set CYGWIN_MIRROR=https://mirrors.kernel.org/sourceware/cygwin/
set CYGWIN_SETUP=setup-x86_64.exe
set CYGWIN_SETUP_URL=https://cygwin.com/%CYGWIN_SETUP%

:: WinFsp configuration (https://github.com/winfsp/winfsp/releases)
set WINFSP_VERSION=2.1
set WINFSP_BUILD=25156
set WINFSP_MSI=winfsp-%WINFSP_VERSION%.%WINFSP_BUILD%.msi
set WINFSP_URL=https://github.com/winfsp/winfsp/releases/download/v%WINFSP_VERSION%/%WINFSP_MSI%

:: Required Cygwin packages for building sshfs-win
:: meson: https://cygwin.com/packages/summary/meson.html (includes ninja as dependency)
set CYGWIN_PACKAGES=gcc-core,git,libglib2.0-devel,make,meson,patch

:: Store current directory
set PROJECT_DIR=%~dp0
cd /d "%PROJECT_DIR%"

:: ============================================================================
:: Step 1: Check/Install WinFsp
:: ============================================================================
echo [1/4] Checking for WinFsp...

:: Check if WinFsp is installed by looking for the registry key or install directory
set WINFSP_INSTALLED=0
if exist "%ProgramFiles(x86)%\WinFsp\bin\winfsp-x64.dll" set WINFSP_INSTALLED=1
if exist "%ProgramFiles%\WinFsp\bin\winfsp-x64.dll" set WINFSP_INSTALLED=1

if %WINFSP_INSTALLED%==1 (
    echo   WinFsp is already installed
) else (
    echo   WinFsp not found, downloading...
    
    :: Download WinFsp MSI
    if not exist "%WINFSP_MSI%" (
        curl -L -o "%WINFSP_MSI%" "%WINFSP_URL%"
        if errorlevel 1 (
            echo ERROR: Failed to download WinFsp
            echo Please download manually from: %WINFSP_URL%
            exit /b 1
        )
        echo   Downloaded %WINFSP_MSI%
    )
    
    :: Install WinFsp
    echo   Installing WinFsp...
    echo   Please complete the WinFsp installation wizard.
    echo.
    
    :: Launch the installer
    start "" msiexec /i "%PROJECT_DIR%%WINFSP_MSI%"
    
    :: Wait a moment for the process to start
    timeout /t 2 /nobreak >nul
    
    :: Poll until msiexec is no longer running this MSI
    echo   Waiting for WinFsp installer to complete...
    :winfsp_wait_loop
    tasklist /FI "IMAGENAME eq msiexec.exe" 2>nul | find /I "msiexec.exe" >nul
    if not errorlevel 1 (
        timeout /t 2 /nobreak >nul
        goto winfsp_wait_loop
    )
    
    echo   WinFsp installer has closed.
    
    :: Verify installation
    set WINFSP_INSTALLED=0
    if exist "%ProgramFiles(x86)%\WinFsp\bin\winfsp-x64.dll" set WINFSP_INSTALLED=1
    if exist "%ProgramFiles%\WinFsp\bin\winfsp-x64.dll" set WINFSP_INSTALLED=1
    
    if %WINFSP_INSTALLED%==0 (
        echo ERROR: WinFsp installation failed or was cancelled
        exit /b 1
    )
    echo   WinFsp installed successfully
)
echo.

:: ============================================================================
:: Step 2: Download Cygwin Setup
:: ============================================================================
echo [2/4] Downloading Cygwin setup...
if not exist "%CYGWIN_SETUP%" (
    echo   Downloading from %CYGWIN_SETUP_URL%...
    curl -L -o "%CYGWIN_SETUP%" "%CYGWIN_SETUP_URL%"
    if errorlevel 1 (
        echo ERROR: Failed to download Cygwin setup
        echo Please download manually from: %CYGWIN_SETUP_URL%
        echo and place it in: %PROJECT_DIR%
        exit /b 1
    )
    echo   Downloaded %CYGWIN_SETUP%
) else (
    echo   Cygwin setup already exists, skipping download
)

:: ============================================================================
:: Step 3: Install Cygwin with required packages
:: ============================================================================
echo.
echo [3/4] Installing Cygwin and required packages...
echo   Packages: %CYGWIN_PACKAGES%
echo.

:: Run Cygwin setup
echo   Starting Cygwin installer...
echo   Please complete the installation and click Finish when done.
echo.

:: Launch the installer
start "" "%CYGWIN_SETUP%" --root "%CYGWIN_ROOT%" --site "%CYGWIN_MIRROR%" --no-desktop --no-shortcuts --no-startmenu --packages "%CYGWIN_PACKAGES%"

:: Wait a moment for the process to start
timeout /t 2 /nobreak >nul

:: Poll until setup-x86_64.exe is no longer running
echo   Waiting for Cygwin installer to complete...
:cygwin_wait_loop
tasklist /FI "IMAGENAME eq %CYGWIN_SETUP%" 2>nul | find /I "%CYGWIN_SETUP%" >nul
if not errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto cygwin_wait_loop
)

echo   Cygwin installer has closed.
echo.

:: Verify Cygwin was installed
if not exist "%CYGWIN_ROOT%\bin\bash.exe" (
    echo ERROR: Cygwin installation failed or was cancelled
    exit /b 1
)

echo   Cygwin installed successfully to %CYGWIN_ROOT%

:: ============================================================================
:: Step 4: Initialize git submodules
:: ============================================================================
echo.
echo [4/4] Initializing git submodules...

:: Check if git is available in PATH or use Cygwin's git
where git >nul 2>&1
if errorlevel 1 (
    set "PATH=%CYGWIN_ROOT%\bin;%PATH%"
)

git submodule update --init --recursive
if errorlevel 1 (
    echo ERROR: Failed to initialize submodules
    exit /b 1
)
echo   Submodules initialized successfully

:: ============================================================================
:: Verify installation
:: ============================================================================
echo.
echo Verifying installation...

set VERIFY_FAILED=0

:: Check for WinFsp
if exist "%ProgramFiles(x86)%\WinFsp\bin\winfsp-x64.dll" (
    echo   [OK] WinFsp found
) else if exist "%ProgramFiles%\WinFsp\bin\winfsp-x64.dll" (
    echo   [OK] WinFsp found
) else (
    echo   [MISSING] WinFsp not found
    set VERIFY_FAILED=1
)

:: Check for required executables (.exe files)
for %%P in (gcc make git) do (
    if exist "%CYGWIN_ROOT%\bin\%%P.exe" (
        echo   [OK] %%P found
    ) else (
        echo   [MISSING] %%P not found
        set VERIFY_FAILED=1
    )
)

:: Check for meson (Python script, no .exe extension)
if exist "%CYGWIN_ROOT%\bin\meson" (
    echo   [OK] meson found
) else (
    echo   [MISSING] meson not found
    set VERIFY_FAILED=1
)

:: Check sshfs submodule
if exist "%PROJECT_DIR%sshfs-win\sshfs\sshfs.c" (
    echo   [OK] sshfs submodule initialized
) else (
    echo   [MISSING] sshfs submodule not initialized
    set VERIFY_FAILED=1
)

echo.
if %VERIFY_FAILED%==1 (
    echo WARNING: Some components may be missing. Build might fail.
) else (
    echo All components verified successfully!
)

:: ============================================================================
:: Done
:: ============================================================================
echo.
echo ============================================
echo   Setup Complete!
echo ============================================
echo.
echo WinFsp installed
echo Cygwin installed to: %CYGWIN_ROOT%
echo.
echo Next steps:
echo   1. Run build.bat to build the project
echo.

endlocal
exit /b 0
