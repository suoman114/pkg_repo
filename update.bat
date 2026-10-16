@echo off
chcp 65001 >nul
setlocal
rem pkg_repo 새 버전 받기 + 설치 (Windows, WSL 없이)
rem GitHub의 최신 Release에서 설치 묶음을 이 폴더에 받은 뒤 install.bat 을 실행한다. 설정·DB·받아 둔 파일은 그대로 유지된다.

set URL=https://github.com/suoman114/pkg_repo/releases/latest/download/pkgrepo-win-bundle.tar.gz
set OUT=%~dp0pkgrepo-win-bundle.tar.gz

echo == 최신 설치 묶음을 받습니다 (약 160MB)
echo    %URL%
curl.exe -L -f --retry 2 -o "%OUT%.part" "%URL%"
if errorlevel 1 goto :failed
move /y "%OUT%.part" "%OUT%" >nul
rem 확인용 SHA-256 — install.bat 이 이 값으로 묶음을 검사한다
curl.exe -L -f --retry 2 -s -o "%OUT%.sha256" "%URL%.sha256"
if errorlevel 1 goto :failed
call "%~dp0install.bat"
exit /b %errorlevel%

:failed
del "%OUT%.part" 2>nul
echo.
echo [오류] 설치 묶음을 받지 못했습니다. 인터넷 연결을 확인하세요.
echo        인터넷이 안 되는 PC라면 다른 PC에서 위 주소의 파일을 받아 이 폴더에 넣고 install.bat 을 실행하세요.
pause
exit /b 1
