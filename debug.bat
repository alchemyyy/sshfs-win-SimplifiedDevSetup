@echo off
echo ========================================
echo SSHFS-Win Debug Information
echo ========================================
echo.

echo [1] Checking WinFsp Installation...
if exist "%ProgramFiles(x86)%\WinFsp\bin\winfsp-x64.dll" (
    echo   [OK] WinFsp found in Program Files (x86)
) else if exist "%ProgramFiles%\WinFsp\bin\winfsp-x64.dll" (
    echo   [OK] WinFsp found in Program Files
) else (
    echo   [ERROR] WinFsp not found!
)
echo.

echo [2] Checking WinFsp Services...
sc query WinFsp.Launcher | find "STATE"
echo.

echo [3] Checking Network Providers...
reg query "HKLM\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order" /v ProviderOrder
echo.

echo [4] Checking if WinFsp.Np is in network providers...
reg query "HKLM\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order" /v ProviderOrder | find "WinFsp.Np"
if errorlevel 1 (
    echo   [ERROR] WinFsp.Np NOT found in network provider list!
    echo   This is likely the cause of "network not present" errors.
    echo   Try reinstalling WinFsp.
) else (
    echo   [OK] WinFsp.Np found in network providers
)
echo.

echo [5] Checking SSHFS-Win Registry Entries...
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "REG_KEY=HKLM\SOFTWARE\WOW6432Node\WinFsp\Services"
) else (
    set "REG_KEY=HKLM\SOFTWARE\WinFsp\Services"
)
echo   Registry key: %REG_KEY%
reg query "%REG_KEY%\sshfs" 2>nul
if errorlevel 1 (
    echo   [ERROR] sshfs service not registered!
) else (
    echo   [OK] sshfs service registered
)
echo.

echo [6] Checking SSHFS-Win Installation...
if exist "%ProgramFiles%\SSHFS-Win\bin\sshfs-win.exe" (
    echo   [OK] sshfs-win.exe found
) else (
    echo   [ERROR] sshfs-win.exe not found!
)
if exist "%ProgramFiles%\SSHFS-Win\bin\sshfs.exe" (
    echo   [OK] sshfs.exe found
) else (
    echo   [ERROR] sshfs.exe not found!
)
echo.

echo [7] Testing sshfs-win.exe...
"%ProgramFiles%\SSHFS-Win\bin\sshfs-win.exe" 2>&1
echo.

echo ========================================
echo.
echo Common fixes:
echo   - If WinFsp.Np is NOT in network providers: Reinstall WinFsp
echo   - If services are STOPPED: run "net start WinFsp.Launcher"
echo   - Try restarting Windows Explorer or logging out/in
echo.
pause
