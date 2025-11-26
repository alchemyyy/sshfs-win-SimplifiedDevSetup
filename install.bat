@echo off
setlocal

:: ============================================================================
:: SSHFS-Win Installation Script (Self-Elevating)
:: ============================================================================

:: Check for admin privileges
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator privileges...
    
    :: Create a temporary VBScript to elevate
    set "ELEVATE_VBS=%TEMP%\elevate_%RANDOM%.vbs"
    
    echo Set UAC = CreateObject^("Shell.Application"^) > "%ELEVATE_VBS%"
    echo UAC.ShellExecute "%~f0", "", "%~dp0", "runas", 1 >> "%ELEVATE_VBS%"
    
    :: Run the VBScript and exit current instance
    cscript //nologo "%ELEVATE_VBS%"
    del "%ELEVATE_VBS%" >nul 2>&1
    exit /b 0
)

echo ============================================
echo   SSHFS-Win Installer
echo ============================================
echo.

set "INSTALL_DIR=%ProgramFiles%\SSHFS-Win"
set "SCRIPT_DIR=%~dp0"

echo Installing to: %INSTALL_DIR%
echo.

echo [1/5] Stopping any running SSHFS-Win processes...
taskkill /F /IM sshfs-win.exe >nul 2>&1
taskkill /F /IM sshfs.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo   Done

echo [2/5] Creating installation directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\bin" mkdir "%INSTALL_DIR%\bin"
if not exist "%INSTALL_DIR%\dev" mkdir "%INSTALL_DIR%\dev"
if not exist "%INSTALL_DIR%\dev\mqueue" mkdir "%INSTALL_DIR%\dev\mqueue"
if not exist "%INSTALL_DIR%\dev\shm" mkdir "%INSTALL_DIR%\dev\shm"
if not exist "%INSTALL_DIR%\etc" mkdir "%INSTALL_DIR%\etc"

echo [3/5] Copying files...
xcopy /E /Y /Q "%SCRIPT_DIR%bin\*" "%INSTALL_DIR%\bin\" >nul
xcopy /E /Y /Q "%SCRIPT_DIR%etc\*" "%INSTALL_DIR%\etc\" >nul
if exist "%SCRIPT_DIR%License.txt" copy /Y "%SCRIPT_DIR%License.txt" "%INSTALL_DIR%\" >nul
if exist "%SCRIPT_DIR%debug.bat" copy /Y "%SCRIPT_DIR%debug.bat" "%INSTALL_DIR%\" >nul
echo   Files copied

echo [4/5] Adding registry entries...

:: Generate complete registry file with correct paths
set "TEMP_REG=%TEMP%\sshfs-win-install.reg"
set "INSTALL_DIR_ESC=%INSTALL_DIR:\=\\%"

if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    (
        echo Windows Registry Editor Version 5.00
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\WinFsp\Services\sshfs]
        echo "Executable"="%INSTALL_DIR_ESC%\\bin\\sshfs-win.exe"
        echo "CommandLine"="svc %%1 %%2 %%U"
        echo "Security"="D:P(A;;RPWPLC;;;WD)"
        echo "JobControl"=dword:00000001
        echo "Credentials"=dword:00000001
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\WinFsp\Services\sshfs.r]
        echo "Executable"="%INSTALL_DIR_ESC%\\bin\\sshfs-win.exe"
        echo "CommandLine"="svc %%1 %%2 %%U"
        echo "Security"="D:P(A;;RPWPLC;;;WD)"
        echo "JobControl"=dword:00000001
        echo "Credentials"=dword:00000001
        echo "sshfs.rootdir"=dword:00000001
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\WinFsp\Services\sshfs.k]
        echo "Executable"="%INSTALL_DIR_ESC%\\bin\\sshfs-win.exe"
        echo "CommandLine"="svc %%1 %%2 %%U"
        echo "Security"="D:P(A;;RPWPLC;;;WD)"
        echo "JobControl"=dword:00000001
        echo "Credentials"=dword:00000000
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\WinFsp\Services\sshfs.kr]
        echo "Executable"="%INSTALL_DIR_ESC%\\bin\\sshfs-win.exe"
        echo "CommandLine"="svc %%1 %%2 %%U"
        echo "Security"="D:P(A;;RPWPLC;;;WD)"
        echo "JobControl"=dword:00000001
        echo "Credentials"=dword:00000000
        echo "sshfs.rootdir"=dword:00000001
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\SSHFS-Win]
        echo "InstallDir"="%INSTALL_DIR_ESC%\\"
    ) > "%TEMP_REG%"
) else (
    (
        echo Windows Registry Editor Version 5.00
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\WinFsp\Services\sshfs]
        echo "Executable"="%INSTALL_DIR_ESC%\\bin\\sshfs-win.exe"
        echo "CommandLine"="svc %%1 %%2 %%U"
        echo "Security"="D:P(A;;RPWPLC;;;WD)"
        echo "JobControl"=dword:00000001
        echo "Credentials"=dword:00000001
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\WinFsp\Services\sshfs.r]
        echo "Executable"="%INSTALL_DIR_ESC%\\bin\\sshfs-win.exe"
        echo "CommandLine"="svc %%1 %%2 %%U"
        echo "Security"="D:P(A;;RPWPLC;;;WD)"
        echo "JobControl"=dword:00000001
        echo "Credentials"=dword:00000001
        echo "sshfs.rootdir"=dword:00000001
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\WinFsp\Services\sshfs.k]
        echo "Executable"="%INSTALL_DIR_ESC%\\bin\\sshfs-win.exe"
        echo "CommandLine"="svc %%1 %%2 %%U"
        echo "Security"="D:P(A;;RPWPLC;;;WD)"
        echo "JobControl"=dword:00000001
        echo "Credentials"=dword:00000000
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\WinFsp\Services\sshfs.kr]
        echo "Executable"="%INSTALL_DIR_ESC%\\bin\\sshfs-win.exe"
        echo "CommandLine"="svc %%1 %%2 %%U"
        echo "Security"="D:P(A;;RPWPLC;;;WD)"
        echo "JobControl"=dword:00000001
        echo "Credentials"=dword:00000000
        echo "sshfs.rootdir"=dword:00000001
        echo.
        echo [HKEY_LOCAL_MACHINE\SOFTWARE\SSHFS-Win]
        echo "InstallDir"="%INSTALL_DIR_ESC%\\"
    ) > "%TEMP_REG%"
)

:: Import the registry file
regedit /s "%TEMP_REG%"

:: Clean up temp file
del "%TEMP_REG%" >nul 2>&1

echo   Registry entries added

echo [5/5] Adding to system PATH and configuring WinFsp...
:: Check if already in PATH
echo %PATH% | findstr /I /C:"%INSTALL_DIR%\bin" >nul
if errorlevel 1 (
    :: Get current system PATH from registry
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul ^| findstr /i "Path"') do set "SYSPATH=%%b"
    :: Add our bin directory
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "%SYSPATH%;%INSTALL_DIR%\bin" /f >nul 2>&1
    echo   Added %INSTALL_DIR%\bin to system PATH
) else (
    echo   Already in PATH
)

:: Ensure WinFsp driver is loaded
for /f "skip=3 tokens=4" %%a in ('sc query WinFsp 2^>nul') do if "%%a"=="STOPPED" sc start WinFsp >nul 2>&1
if errorlevel 1 for /f "skip=3 tokens=4" %%a in ('sc query winfsp-x64 2^>nul') do if "%%a"=="STOPPED" sc start winfsp-x64 >nul 2>&1
:: Configure and start launcher
sc config WinFsp.Launcher start= auto >nul 2>&1
net start WinFsp.Launcher >nul 2>&1
:: Refresh network provider order
reg query "HKLM\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order" /v ProviderOrder >nul 2>&1 && (
    echo   Network providers refreshed
)
echo   Done

echo ============================================
echo   Installation Complete!
echo ============================================
echo.
echo SSHFS-Win installed to: %INSTALL_DIR%
echo.
echo IMPORTANT: You must LOG OUT and LOG BACK IN (or restart)
echo for the PATH changes to take effect!
echo.
echo Usage:
echo   Map network drives: net use X: \\sshfs\user@host
echo   SSH key auth:       net use X: \\sshfs.k\user@host
echo.
pause
endlocal
