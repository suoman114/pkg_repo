@echo off
chcp 65001 >nul
rem pkg_repo 켜기 — 사용법: start.bat [WSL 배포판 이름]   (기본: CentOS7)
set DISTRO=%1
if "%DISTRO%"=="" set DISTRO=CentOS7
wsl.exe -d %DISTRO% -u root -- pkg-repo start
for /f "usebackq delims=" %%p in (`wsl.exe -d %DISTRO% -u root -- bash -c "grep -E '^PORT=' /opt/pkg-repo/pkg-repo.env | cut -d= -f2"`) do set PORT=%%p
if "%PORT%"=="" set PORT=3000
start "" http://localhost:%PORT%
