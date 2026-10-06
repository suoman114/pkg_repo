@echo off
chcp 65001 >nul
setlocal
rem pkg_repo 설치 (Windows + WSL CentOS 7) — 이 폴더의 pkgrepo-el7-bundle.tar.gz 를 WSL 안에 풀고 설치한다.
rem 사용법: install.bat [WSL 배포판 이름]   (기본: CentOS7)
set DISTRO=%1
if "%DISTRO%"=="" set DISTRO=CentOS7

if not exist "%~dp0pkgrepo-el7-bundle.tar.gz" (
  echo [오류] 이 폴더에 pkgrepo-el7-bundle.tar.gz 가 없습니다.
  pause & exit /b 1
)
wsl.exe -d %DISTRO% -u root -- true
if errorlevel 1 (
  echo [오류] WSL 배포판 "%DISTRO%" 을 실행할 수 없습니다. "wsl -l -v" 로 이름을 확인하고 install.bat 이름 으로 다시 실행하세요.
  pause & exit /b 1
)

echo == 묶음을 WSL(%DISTRO%)로 복사하고 설치합니다. Bitbucket 계정과 웹 비밀번호를 물어봅니다.
for /f "usebackq delims=" %%p in (`wsl.exe -d %DISTRO% -u root -- wslpath -a "%~dp0pkgrepo-el7-bundle.tar.gz"`) do set SRC=%%p
wsl.exe -d %DISTRO% -u root -- bash -c "mkdir -p /root/pkg-repo-install && cd /root/pkg-repo-install && rm -rf pkgrepo-el7-bundle && tar -xzf '%SRC%' && chmod +x pkgrepo-el7-bundle/install-el7.sh && ./pkgrepo-el7-bundle/install-el7.sh"
if errorlevel 1 (
  echo [오류] 설치가 끝까지 진행되지 않았습니다. 위 메시지를 확인하세요.
  pause & exit /b 1
)
echo.
echo 설치가 끝났습니다. 앞으로는 start.bat 으로 켜고 stop.bat 으로 끕니다.
pause
