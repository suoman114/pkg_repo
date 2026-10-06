@echo off
chcp 65001 >nul
rem pkg_repo 끄기 (DB 포함) — 사용법: stop.bat [WSL 배포판 이름]   (기본: CentOS7)
set DISTRO=%1
if "%DISTRO%"=="" set DISTRO=CentOS7
wsl.exe -d %DISTRO% -u root -- pkg-repo stop all
pause
