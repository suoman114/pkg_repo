@echo off
chcp 65001 >nul
setlocal
rem pkg_repo 끄기 (DB 포함). PC를 다시 켜면 자동으로 다시 시작된다.
set "PKGREPO_SELF=%~f0"
rem 관리자 권한 확인(fltmc는 관리자만 성공 — net session은 Server 서비스를 꺼 둔 PC에서 늘 실패한다). 아니면 권한을 올려 다시 실행
fltmc >nul 2>&1
if errorlevel 1 (
  echo 관리자 권한이 필요합니다 — 권한 확인 창이 뜨면 '예'를 누르세요.
  powershell -NoProfile -Command "Start-Process -FilePath $env:PKGREPO_SELF -Verb RunAs"
  exit /b
)
powershell -NoProfile -Command "$r = [Environment]::GetEnvironmentVariable('PKGREPO_ROOT', 'Machine'); if (-not $r) { $r = 'C:\pkg-repo' }; $ErrorActionPreference = 'Stop'; Stop-ScheduledTask -TaskName pkg-repo-web; Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $r 'node\node.exe') } | Stop-Process -Force; Stop-Service pkg-repo-db"
if errorlevel 1 (
  echo [오류] 끄지 못했습니다 — 위 메시지를 확인하세요.
  pause & exit /b 1
)
echo 껐습니다.
pause
