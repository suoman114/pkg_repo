@echo off
chcp 65001 >nul
setlocal
rem pkg_repo 켜기 — 꺼 두었을 때만 필요하다(PC를 켜면 자동으로 시작된다). 설치 폴더는 PKGREPO_ROOT(설치할 때 기억)
set "PKGREPO_SELF=%~f0"
rem 관리자 권한 확인(fltmc는 관리자만 성공 — net session은 Server 서비스를 꺼 둔 PC에서 늘 실패한다). 아니면 권한을 올려 다시 실행
fltmc >nul 2>&1
if errorlevel 1 (
  echo 관리자 권한이 필요합니다 — 권한 확인 창이 뜨면 '예'를 누르세요.
  powershell -NoProfile -Command "Start-Process -FilePath $env:PKGREPO_SELF -Verb RunAs"
  exit /b
)
powershell -NoProfile -Command "$r = [Environment]::GetEnvironmentVariable('PKGREPO_ROOT', 'Machine'); if (-not $r) { $r = 'C:\pkg-repo' }; Start-Service pkg-repo-db -ErrorAction Stop; Start-ScheduledTask -TaskName pkg-repo-web -ErrorAction Stop; $p = (Select-String -Path (Join-Path $r 'pkg-repo.env') -Pattern '^PORT=(\d+)' -ErrorAction SilentlyContinue).Matches.Groups[1].Value; if (-not $p) { $p = '3000' }; '켰습니다 — 잠시 뒤 바탕화면의 PKG 관리 아이콘(또는 http://127.0.0.1:' + $p + ')으로 엽니다.'"
if errorlevel 1 (
  echo [오류] 켜지 못했습니다 — 설치돼 있는지 확인하세요.
  pause & exit /b 1
)
pause
