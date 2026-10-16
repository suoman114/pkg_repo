@echo off
chcp 65001 >nul
setlocal
rem pkg_repo 상태 보기
set "PKGREPO_SELF=%~f0"
rem 관리자 권한 확인(fltmc는 관리자만 성공 — net session은 Server 서비스를 꺼 둔 PC에서 늘 실패한다). 아니면 권한을 올려 다시 실행
fltmc >nul 2>&1
if errorlevel 1 (
  echo 관리자 권한이 필요합니다 — 권한 확인 창이 뜨면 '예'를 누르세요.
  powershell -NoProfile -Command "Start-Process -FilePath $env:PKGREPO_SELF -Verb RunAs"
  exit /b
)
powershell -NoProfile -Command "$r = [Environment]::GetEnvironmentVariable('PKGREPO_ROOT', 'Machine'); if (-not $r) { $r = 'C:\pkg-repo' }; $s = Get-Service pkg-repo-db -ErrorAction SilentlyContinue; '설치 폴더: ' + $r; 'DB  : ' + $(if ($s) { $s.Status } else { '설치 안 됨' }); $n = Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $r 'node\node.exe') }; '웹  : ' + $(if ($n) { '실행 중 (PID ' + $n.Id + ')' } else { '꺼짐' }); $p = (Select-String -Path (Join-Path $r 'pkg-repo.env') -Pattern '^PORT=(\d+)' -ErrorAction SilentlyContinue).Matches.Groups[1].Value; if ($p) { try { 'health: ' + (Invoke-WebRequest -UseBasicParsing ('http://127.0.0.1:' + $p + '/api/health') -TimeoutSec 5).Content } catch { 'health: 응답 없음' } }; '로그: ' + (Join-Path $r 'data\web.log')"
pause
