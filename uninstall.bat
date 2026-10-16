@echo off
chcp 65001 >nul
setlocal
rem pkg_repo 지우기 — 웹·DB 서비스·설치 폴더(프로그램, DB, 받아 둔 패키지, 백업)·바탕화면 아이콘을 모두 지운다.
rem 지우기 전에 공용 서버로 올리지 않은 설치본 백업을 보여 주고, DELETE 를 직접 입력해야 진행한다.
set "PKGREPO_SELF=%~f0"
rem 관리자 권한 확인(fltmc는 관리자만 성공 — net session은 Server 서비스를 꺼 둔 PC에서 늘 실패한다). 아니면 권한을 올려 다시 실행
fltmc >nul 2>&1
if errorlevel 1 (
  echo 관리자 권한이 필요합니다 — 권한 확인 창이 뜨면 '예'를 누르세요.
  powershell -NoProfile -Command "Start-Process -FilePath $env:PKGREPO_SELF -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
pause
