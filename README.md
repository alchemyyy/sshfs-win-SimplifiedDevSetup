# SSHFS-Win Simplified Dev Setup

Some scripts for simplifying getting a development environment going for [SSHFS-Win](https://github.com/winfsp/sshfs-win) and building it.

Features:

* no Wix dependency
* automated cygwin package set
* install.bat + uninstall.bat instead of .msi
* debug.bat script to sanity check WinFsp

Overview:
* Set up the environment: `setup_workspace.bat`
	* Installs WinFsp and Cygwin with all required packages.
* Build: `build.bat`
	* Output will be in `.build\root\`
* Install: `.build\root\install.bat`
* Uninstall: `.build\root\uninstall.bat`
	* Note: does not uninstall Cygwin + packages


Note: I'm bundling Cygwin's setup here out of laziness. It is recommended to get a fresh copy from [Cygwin](https://www.cygwin.com/setup-x86_64.exe).