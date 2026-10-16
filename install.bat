@echo off
chcp 65001 >nul
setlocal
rem pkg_repo 설치 / 갱신 (Windows, WSL 없이) — 이 폴더의 pkgrepo-win-bundle.tar.gz 를 풀고 install-win.ps1 을 관리자 권한으로 실행한다.
rem 설치 폴더 C:\pkg-repo — 다시 실행하면 갱신이다(설정·DB·받아 둔 파일은 그대로).
set "PKGREPO_SELF=%~f0"
rem 관리자 권한 확인(fltmc는 관리자만 성공 — net session은 Server 서비스를 꺼 둔 PC에서 늘 실패한다). 아니면 권한을 올려 다시 실행
fltmc >nul 2>&1
if errorlevel 1 (
  echo 관리자 권한이 필요합니다 — 권한 확인 창이 뜨면 '예'를 누르세요.
  powershell -NoProfile -Command "Start-Process -FilePath $env:PKGREPO_SELF -Verb RunAs"
  exit /b
)
if not exist "%~dp0pkgrepo-win-bundle.tar.gz" (
  echo [오류] 이 폴더에 pkgrepo-win-bundle.tar.gz 가 없습니다. update.bat 으로 받으세요.
  pause & exit /b 1
)

rem 짧은 경로에 푼다 — 사용자 폴더(%TEMP%) 아래는 node_modules가 깊어 경로 길이 제한(260자)에 걸릴 수 있다.
rem 이름은 매번 새로(미리 만들어 둔 폴더를 쓰지 않게), 권한은 SYSTEM·관리자만 — 관리자 권한으로 돌릴 파일을 일반 사용자가 바꿔치지 못하게 한다
set WORK=%SystemDrive%\pkgrepo-tmp-%RANDOM%%RANDOM%
if exist "%WORK%" (
  echo [오류] 임시 폴더 %WORK% 가 이미 있습니다. 다시 실행하세요.
  pause & exit /b 1
)
mkdir "%WORK%" || (pause & exit /b 1)
icacls "%WORK%" /inheritance:r /grant:r *S-1-5-18:(OI)(CI)F *S-1-5-32-544:(OI)(CI)F >nul
if errorlevel 1 (
  echo [오류] 임시 폴더 권한을 설정하지 못했습니다.
  rmdir /s /q "%WORK%" & pause & exit /b 1
)
rem 묶음을 잠긴 폴더로 먼저 복사한 뒤 그 사본을 검사하고 푼다(검사와 풀기 사이에 바뀌지 않게)
copy /y "%~dp0pkgrepo-win-bundle.tar.gz" "%WORK%\bundle.tar.gz" >nul || (rmdir /s /q "%WORK%" & pause & exit /b 1)
if exist "%~dp0pkgrepo-win-bundle.tar.gz.sha256" (
  rem 경로는 환경 변수로 넘긴다 — 폴더 이름에 ' 나 ( ) 가 있어도 깨지지 않게
  set "PKGREPO_SHA=%~dp0pkgrepo-win-bundle.tar.gz.sha256"
  set "PKGREPO_COPY=%WORK%\bundle.tar.gz"
  powershell -NoProfile -Command "$want = ((Get-Content -LiteralPath $env:PKGREPO_SHA -TotalCount 1) -split '\s+')[0]; if ((Get-FileHash -LiteralPath $env:PKGREPO_COPY -Algorithm SHA256).Hash -ne $want) { exit 1 }"
  if errorlevel 1 (
    echo [오류] 설치 묶음이 손상됐거나 바뀌었습니다^(SHA-256 불일치^). update.bat 으로 다시 받으세요.
    rmdir /s /q "%WORK%" & pause & exit /b 1
  )
  echo == 설치 묶음 확인 ^(SHA-256 일치^)
) else (
  echo [주의] pkgrepo-win-bundle.tar.gz.sha256 이 없어 묶음을 검사하지 못했습니다.
)
echo == 설치 묶음을 풉니다
"%SystemRoot%\System32\tar.exe" -xzf "%WORK%\bundle.tar.gz" -C "%WORK%"
if errorlevel 1 (
  echo [오류] 설치 묶음을 풀지 못했습니다.
  rmdir /s /q "%WORK%" & pause & exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%WORK%\pkgrepo-win-bundle\install-win.ps1"
set RC=%errorlevel%
rmdir /s /q "%WORK%"
if not "%RC%"=="0" (
  echo [오류] 설치가 끝까지 진행되지 않았습니다. 위 메시지를 확인하세요.
  pause & exit /b 1
)
echo.
echo 설치가 끝났습니다. 바탕화면의 'PKG 관리' 아이콘으로 엽니다. PC를 켜면 자동으로 시작됩니다.
pause
