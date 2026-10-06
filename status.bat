@echo off
chcp 65001 >nul
rem pkg_repo 상태 보기 — 사용법: status.bat [WSL 배포판 이름]   (기본: CentOS7)
set DISTRO=%1
if "%DISTRO%"=="" set DISTRO=CentOS7
wsl.exe -d %DISTRO% -u root -- pkg-repo status
pause
