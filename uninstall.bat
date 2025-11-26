@echo off
setlocal

:: ============================================================================
:: SSHFS-Win Uninstallation Script
:: ============================================================================

echo ============================================
echo   SSHFS-Win Uninstaller
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: This script requires administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

set "INSTALL_DIR=%ProgramFiles%\SSHFS-Win"

echo Uninstalling from: %INSTALL_DIR%
echo.

echo [1/4] Stopping any running SSHFS-Win processes...
taskkill /F /IM sshfs-win.exe >nul 2>&1
taskkill /F /IM sshfs.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo   Done

echo [2/4] Removing WinFsp service registry entries...
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    reg delete "HKLM\SOFTWARE\WOW6432Node\WinFsp\Services\sshfs" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\WOW6432Node\WinFsp\Services\sshfs.r" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\WOW6432Node\WinFsp\Services\sshfs.k" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\WOW6432Node\WinFsp\Services\sshfs.kr" /f >nul 2>&1
) else (
    reg delete "HKLM\SOFTWARE\WinFsp\Services\sshfs" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\WinFsp\Services\sshfs.r" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\WinFsp\Services\sshfs.k" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\WinFsp\Services\sshfs.kr" /f >nul 2>&1
)
reg delete "HKLM\SOFTWARE\SSHFS-Win" /f >nul 2>&1
echo   Registry entries removed

echo [3/4] Removing from system PATH...
:: Get current system PATH
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul ^| findstr /i "Path"') do set "SYSPATH=%%b"
:: Remove our bin directory from PATH (replace with nothing)
set "NEWPATH=%SYSPATH:;C:\Program Files\SSHFS-Win\bin=%"
set "NEWPATH=%NEWPATH:C:\Program Files\SSHFS-Win\bin;=%"
set "NEWPATH=%NEWPATH:C:\Program Files\SSHFS-Win\bin=%"
:: Update registry if changed
if not "%NEWPATH%"=="%SYSPATH%" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "%NEWPATH%" /f >nul 2>&1
    echo   Removed from system PATH
) else (
    echo   Not found in PATH
)

echo [4/4] Removing files...
if exist "%INSTALL_DIR%" (
    rmdir /s /q "%INSTALL_DIR%"
    echo   Files removed
) else (
    echo   Installation directory not found
)

echo.
echo ============================================
echo   Uninstallation Complete!
echo ============================================
echo.
echo You may need to log out and log back in for
echo PATH changes to fully take effect.
echo.
pause
endlocal
