@echo off
setlocal EnableDelayedExpansion

:: ============================================================================
:: SSHFS-Win Build Script
:: Builds the project without WiX toolset dependency
:: ============================================================================

echo ============================================
echo   SSHFS-Win Build
echo ============================================
echo.

:: Configuration
set CYGWIN_ROOT=C:\cygwin64
set PROJECT_DIR=%~dp0
set SSHFS_WIN_DIR=%PROJECT_DIR%sshfs-win
set BUILD_DIR=%PROJECT_DIR%.build
set SRC_DIR=%BUILD_DIR%\src
set ROOT_DIR=%BUILD_DIR%\root

:: Product info (matching original Makefile)
set PRODUCT_NAME=SSHFS-Win
set PRODUCT_VERSION=2021.1

:: Determine architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set ARCH=x64
) else (
    set ARCH=x86
)

:: Set up Cygwin environment
set PATH=%CYGWIN_ROOT%\bin;%PATH%
set CYGWIN=nodosfilewarning

cd /d "%PROJECT_DIR%"

:: ============================================================================
:: Pre-flight checks
:: ============================================================================
echo [Pre-flight] Checking requirements...

if not exist "%CYGWIN_ROOT%\bin\bash.exe" (
    echo ERROR: Cygwin not found at %CYGWIN_ROOT%
    echo Please run setup_workspace.bat first
    exit /b 1
)

:: Check for WinFsp
set WINFSP_FOUND=0
if exist "%ProgramFiles(x86)%\WinFsp\bin\winfsp-x64.dll" set WINFSP_FOUND=1
if exist "%ProgramFiles%\WinFsp\bin\winfsp-x64.dll" set WINFSP_FOUND=1
if %WINFSP_FOUND%==0 (
    echo ERROR: WinFsp not found
    echo Please run setup_workspace.bat first
    exit /b 1
)

if not exist "%SSHFS_WIN_DIR%\sshfs\sshfs.c" (
    echo ERROR: sshfs submodule not initialized
    echo Please run: git submodule update --init --recursive
    exit /b 1
)

:: Check if FUSE for Cygwin is installed, if not install it from WinFsp
set FUSE_INSTALLED=0
if exist "%CYGWIN_ROOT%\usr\include\fuse.h" set FUSE_INSTALLED=1
if exist "%CYGWIN_ROOT%\usr\include\fuse\fuse.h" set FUSE_INSTALLED=1
if exist "%CYGWIN_ROOT%\usr\local\include\fuse.h" set FUSE_INSTALLED=1
if %FUSE_INSTALLED%==0 (
    echo   Installing FUSE for Cygwin from WinFsp...
    
    :: Get WinFsp install path from registry
    set "WINFSP_PATH="
    for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WinFsp" /v InstallDir 2^>nul') do set "WINFSP_PATH=%%b"
    if not defined WINFSP_PATH (
        for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\WinFsp" /v InstallDir 2^>nul') do set "WINFSP_PATH=%%b"
    )
    
    if defined WINFSP_PATH (
        set "CYGFUSE_SCRIPT=!WINFSP_PATH!opt\cygfuse\install.sh"
        if exist "!CYGFUSE_SCRIPT!" (
            for /f "delims=" %%P in ('%CYGWIN_ROOT%\bin\cygpath.exe -u "!CYGFUSE_SCRIPT!"') do set "CYGFUSE_SCRIPT_CYG=%%P"
            %CYGWIN_ROOT%\bin\bash.exe --login -c "sh '!CYGFUSE_SCRIPT_CYG!'"
        )
    )
    
    :: Check multiple possible locations for fuse.h
    set FUSE_FOUND=0
    if exist "%CYGWIN_ROOT%\usr\include\fuse.h" set FUSE_FOUND=1
    if exist "%CYGWIN_ROOT%\usr\include\fuse\fuse.h" set FUSE_FOUND=1
    if exist "%CYGWIN_ROOT%\usr\local\include\fuse.h" set FUSE_FOUND=1
    
    if !FUSE_FOUND!==0 (
        echo.
        echo ERROR: Failed to install FUSE for Cygwin
        echo.
        echo WinFsp is missing the "FUSE for Cygwin" component.
        echo To fix this:
        echo   1. Run the WinFsp installer ^(winfsp-*.msi^)
        echo   2. Select "Modify" to change the installation
        echo   3. Enable the "FUSE for Cygwin" feature
        echo   4. Complete the installation
        echo   5. Run build.bat again
        echo.
        exit /b 1
    )
    echo   FUSE for Cygwin installed
)

echo   Requirements OK
echo.

:: ============================================================================
:: Clean previous build and prepare directories
:: ============================================================================
echo [1/6] Preparing build directories...
if exist "%BUILD_DIR%" (
    echo Cleaning previous build...
    rmdir /s /q "%BUILD_DIR%"
)
mkdir "%BUILD_DIR%"
mkdir "%SRC_DIR%"
mkdir "%ROOT_DIR%"
mkdir "%ROOT_DIR%\bin"
mkdir "%ROOT_DIR%\dev"
mkdir "%ROOT_DIR%\dev\mqueue"
mkdir "%ROOT_DIR%\dev\shm"
mkdir "%ROOT_DIR%\etc"

:: Copy sshfs source to build directory (so patches don't modify original)
echo Copying sshfs source to build directory...
xcopy /E /I /Q "%SSHFS_WIN_DIR%\sshfs" "%SRC_DIR%\sshfs" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy sshfs source
    exit /b 1
)
echo   Build directories ready

:: ============================================================================
:: Apply patches
:: ============================================================================
echo.
echo [2/6] Applying patches...
%CYGWIN_ROOT%\bin\bash.exe --login -c "cd '%BUILD_DIR:\=/%/src/sshfs' && for f in '%SSHFS_WIN_DIR:\=/%/patches'/*.patch; do patch --binary -p1 < \"$f\"; done"
if errorlevel 1 (
    echo ERROR: Failed to apply patches
    exit /b 1
)
echo   Patches applied

:: ============================================================================
:: Configure with meson
:: ============================================================================
echo.
echo [3/6] Configuring with meson...
%CYGWIN_ROOT%\bin\bash.exe --login -c "cd '%BUILD_DIR:\=/%/src/sshfs' && mkdir -p build && cd build && meson .."
if errorlevel 1 (
    echo ERROR: Meson configuration failed
    exit /b 1
)
echo   Configuration complete

:: ============================================================================
:: Build with ninja
:: ============================================================================
echo.
echo [4/6] Building sshfs with ninja...
%CYGWIN_ROOT%\bin\bash.exe --login -c "cd '%BUILD_DIR:\=/%/src/sshfs/build' && ninja"
if errorlevel 1 (
    echo ERROR: Build failed
    exit /b 1
)
echo   sshfs built successfully

:: ============================================================================
:: Gather dependencies and create root structure
:: ============================================================================
echo.
echo [5/6] Gathering dependencies and creating distribution...

:: Convert paths to Cygwin format
for /f "delims=" %%i in ('%CYGWIN_ROOT%\bin\cygpath.exe -u "%SRC_DIR%\sshfs\build\sshfs"') do set SSHFS_BIN_CYG=%%i
for /f "delims=" %%i in ('%CYGWIN_ROOT%\bin\cygpath.exe -u "%ROOT_DIR%\bin"') do set ROOT_BIN_CYG=%%i
for /f "delims=" %%i in ('%CYGWIN_ROOT%\bin\cygpath.exe -u "%ROOT_DIR%\etc"') do set ROOT_ETC_CYG=%%i
for /f "delims=" %%i in ('%CYGWIN_ROOT%\bin\cygpath.exe -u "%SSHFS_WIN_DIR%\etc"') do set SSHFS_WIN_ETC_CYG=%%i

:: Copy sshfs binary
echo Copying sshfs binary...
%CYGWIN_ROOT%\bin\bash.exe --login -c "cp '%SSHFS_BIN_CYG%' '%ROOT_BIN_CYG%/' && strip '%ROOT_BIN_CYG%/sshfs'"
if errorlevel 1 (
    echo ERROR: Failed to copy sshfs binary
    exit /b 1
)

:: Find and copy dependencies
echo Finding and copying dependencies...
%CYGWIN_ROOT%\bin\bash.exe --login -c "for dll in $(/usr/bin/cygcheck '%SSHFS_BIN_CYG%' | tr -d '\r' | tr '\\' / | grep -i cygwin64 | sort | uniq); do cyg_path=$(/usr/bin/cygpath -u \"$dll\" 2>/dev/null); if [ -f \"$cyg_path\" ]; then cp \"$cyg_path\" '%ROOT_BIN_CYG%/'; fi; done"
if errorlevel 1 (
    echo WARNING: Some dependencies may not have been copied
)

:: Copy ssh and its dependencies  
echo Copying ssh binary and dependencies...
%CYGWIN_ROOT%\bin\bash.exe --login -c "cp /usr/bin/ssh.exe '%ROOT_BIN_CYG%/'; for dll in $(/usr/bin/cygcheck /usr/bin/ssh | tr -d '\r' | tr '\\' / | grep -i cygwin64 | sort | uniq); do cyg_path=$(/usr/bin/cygpath -u \"$dll\" 2>/dev/null); if [ -f \"$cyg_path\" ]; then cp \"$cyg_path\" '%ROOT_BIN_CYG%/'; fi; done"
if errorlevel 1 (
    echo WARNING: Some ssh dependencies may not have been copied
)

:: Copy etc files
echo Copying etc files...
%CYGWIN_ROOT%\bin\bash.exe --login -c "cp -R '%SSHFS_WIN_ETC_CYG%'/* '%ROOT_ETC_CYG%/'"
if errorlevel 1 (
    echo ERROR: Failed to copy etc files
    exit /b 1
)

:: Build sshfs-win.exe wrapper
echo Building sshfs-win wrapper...
for /f "delims=" %%i in ('%CYGWIN_ROOT%\bin\cygpath.exe -u "%SSHFS_WIN_DIR%\sshfs-win.c"') do set SSHFS_WIN_C_CYG=%%i
for /f "delims=" %%i in ('%CYGWIN_ROOT%\bin\cygpath.exe -u "%ROOT_DIR%\bin\sshfs-win"') do set SSHFS_WIN_OUT_CYG=%%i
%CYGWIN_ROOT%\bin\bash.exe --login -c "gcc -o '%SSHFS_WIN_OUT_CYG%' '%SSHFS_WIN_C_CYG%' && strip '%SSHFS_WIN_OUT_CYG%'"
if errorlevel 1 (
    echo ERROR: Failed to build sshfs-win wrapper
    exit /b 1
)
echo   Distribution created

:: ============================================================================
:: Copy support files
:: ============================================================================
echo.
echo [6/6] Copying support files...

:: Copy License and support files from sshfs-win
copy "%SSHFS_WIN_DIR%\License.txt" "%ROOT_DIR%\" >nul
copy "%SSHFS_WIN_DIR%\sshfs-win-x64.reg" "%ROOT_DIR%\" >nul 2>&1
copy "%SSHFS_WIN_DIR%\sshfs-win-x86.reg" "%ROOT_DIR%\" >nul 2>&1

:: Copy installer scripts from this project
copy "%PROJECT_DIR%debug.bat" "%ROOT_DIR%\" >nul
copy "%PROJECT_DIR%install.bat" "%ROOT_DIR%\" >nul
copy "%PROJECT_DIR%uninstall.bat" "%ROOT_DIR%\" >nul

echo   Support files copied

:: ============================================================================
:: Summary
:: ============================================================================
echo.
echo ============================================
echo   Build Complete!
echo ============================================
echo.
echo Build output: %BUILD_DIR%
echo.
echo Artifacts in %ROOT_DIR%:
echo   bin\           - Executables and DLLs
echo   etc\           - Configuration files
echo   install.bat    - Installation script (run as admin)
echo   uninstall.bat  - Uninstallation script (run as admin)
echo   License.txt    - License file
echo.
echo To install:
echo   1. Copy the contents of %ROOT_DIR% to target machine
echo   2. Run install.bat as Administrator
echo   3. Ensure WinFsp is installed for full functionality
echo.

endlocal
exit /b 0
