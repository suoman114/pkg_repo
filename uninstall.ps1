# pkg_repo 지우기 (Windows) — uninstall.bat이 관리자 권한으로 부른다.
# 웹 예약 작업, DB 서비스, 설치 폴더(프로그램·DB·받아 둔 패키지·백업 전부), 바탕화면 아이콘, 설치 폴더 환경 변수를 지운다.
# 지우기 전에 공용 서버로 올리지 않은 설치본 백업이 있는지 보여 주고, DELETE를 직접 입력해야 진행한다.
$ErrorActionPreference = 'Stop'
$DbService = 'pkg-repo-db'
$WebTask = 'pkg-repo-web'

function Say($m) { Write-Host "[uninstall] $m" }
function Fail($m) { Write-Host "[오류] $m" -ForegroundColor Red; exit 1 }

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Fail '관리자 권한으로 실행해야 합니다' }

# 설치 폴더 — install-win.ps1과 같은 순서로 찾는다(환경 변수 → DB 서비스가 가리키는 폴더 → 기본값)
$Root = [Environment]::GetEnvironmentVariable('PKGREPO_ROOT', 'Machine')
$svc = Get-CimInstance Win32_Service -Filter "Name='$DbService'" -ErrorAction SilentlyContinue
# 환경 변수만 남고 폴더가 없으면(손으로 지운 경우) 서비스가 가리키는 폴더를 본다
if ($Root -and -not (Test-Path -LiteralPath $Root) -and $svc) { $Root = $null }
if (-not $Root -and $svc -and $svc.PathName -match '-D\s+"?([^"]+?)\\pgdata"?(\s|$)') { $Root = $Matches[1] }
if (-not $Root) { $Root = 'C:\pkg-repo' }
# (2026-10-16) 기억된 폴더(환경 변수)와 DB 서비스가 쓰는 폴더가 다르면 지우지 않는다 — 환경 변수가 엉뚱한 곳을 가리키면
# 서비스만 지우고 엉뚱한 폴더를 지운 뒤 진짜 설치 폴더는 남는다
if ($svc -and $svc.PathName -match '-D\s+"?([^"]+?)\\pgdata"?(\s|$)') {
  $svcRoot = $Matches[1]
  if ([IO.Path]::GetFullPath($svcRoot).TrimEnd('\') -ine [IO.Path]::GetFullPath($Root).TrimEnd('\')) {
    Fail "기억된 설치 폴더($Root)와 DB 서비스가 쓰는 폴더($svcRoot)가 다릅니다 — 아무것도 지우지 않습니다. 직접 확인하세요"
  }
}
$task = Get-ScheduledTask -TaskName $WebTask -ErrorAction SilentlyContinue
# 지울 폴더가 정말 pkg_repo 설치 폴더인지 — 아니면 폴더는 건드리지 않는다
$isInstall = (Test-Path -LiteralPath (Join-Path $Root 'pkg-repo.env')) -or (Test-Path -LiteralPath (Join-Path $Root 'app\server.js')) -or (Test-Path -LiteralPath (Join-Path $Root 'pgdata\PG_VERSION'))
if (-not $svc -and -not $task -and -not $isInstall) { Say "설치된 pkg_repo가 없습니다 ($Root)"; exit 0 }
if ((Test-Path -LiteralPath $Root) -and -not $isInstall) { Fail "$Root 는 pkg_repo 설치 폴더로 보이지 않습니다 — 폴더는 지우지 않습니다" }
# 통째로 지우기 전 한 번 더 — 기억된 경로가 잘못돼 있어도 드라이브 전체·시스템 폴더·연결 폴더(정션)는 지우지 않는다
if (Test-Path -LiteralPath $Root) {
  $full = [IO.Path]::GetFullPath($Root).TrimEnd('\')
  $deny = @($env:windir, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData, (Split-Path $env:PUBLIC), $env:USERPROFILE) | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }
  if ($full.Length -le 3 -or ($deny | Where-Object { $full -ieq $_ }) -or $full -like "$($env:windir.TrimEnd('\'))\*") { Fail "$full 는 지울 수 없는 위치입니다 — 기억된 설치 폴더가 잘못돼 있습니다. 직접 확인하세요" }
  # 설치 폴더뿐 아니라 그 위 폴더 중 하나라도 연결 폴더면 지우지 않는다(GetFullPath는 정션을 풀지 않는다)
  for ($p = $full; $p -and $p.Length -gt 3; $p = Split-Path $p) {
    if ((Get-Item -LiteralPath $p -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { Fail "$p 는 연결 폴더(정션/링크)라 지우지 않습니다 — 직접 확인하세요" }
  }
  if (-not (Test-Path -LiteralPath (Join-Path $full 'node\node.exe')) -and -not (Test-Path -LiteralPath (Join-Path $full 'pgdata\PG_VERSION'))) { Fail "$full 에 pkg_repo의 Node·DB가 없습니다 — 폴더는 지우지 않습니다" }
  $Root = $full   # 검사한 경로 그대로 지운다
}

Write-Host ''
Say "설치 폴더: $Root"

# ── 올리지 않은 설치본 백업 ─────────────────────────────────────────────────
# 노트북의 기록은 공용 서버에 올라가 있으면 다시 설치한 뒤 받을 수 있다. 올리지 않은 백업 파일은 지우면 되살릴 수 없다.
$checked = $false
$envFile = Join-Path $Root 'pkg-repo.env'
$psql = Join-Path $Root 'pgsql\bin\psql.exe'
if ((Test-Path -LiteralPath $envFile) -and (Test-Path -LiteralPath $psql) -and $svc) {
  try {
    if ((Get-Service $DbService).Status -ne 'Running') { Start-Service $DbService }
    $envText = Get-Content $envFile -Raw -Encoding UTF8
    if ($envText -match '(?m)^DATABASE_URL=postgresql://pkg_repo:([^@]+)@127\.0\.0\.1:(\d+)/') {
      $env:PGPASSWORD = $Matches[1]
      $port = $Matches[2]
      $ErrorActionPreference = 'Continue'
      $sql = "SELECT s.code || ' ' || coalesce(b.data->>'stamp', to_char(b.""createdAt"", 'YYYY-MM-DD HH24:MI')) FROM ""SiteBackup"" b JOIN ""Site"" s ON s.id = b.""siteId"" WHERE b.status = 'READY' AND EXISTS (SELECT 1 FROM jsonb_array_elements(coalesce(b.data->'files', '[]'::jsonb)) f WHERE f->>'packageId' IS NULL) ORDER BY b.""createdAt"""
      # SQL은 표준 입력으로 넘긴다 — PowerShell 5.1은 인자 속 큰따옴표("createdAt")를 망가뜨려 넘긴다
      $rows = @($sql | & $psql -h 127.0.0.1 -p $port -U pkg_repo -d pkg_repo -At 2>$null)
      $ok = $LASTEXITCODE -eq 0
      $ErrorActionPreference = 'Stop'
      Remove-Item Env:PGPASSWORD
      if ($ok) {
        $checked = $true
        if ($rows.Count -gt 0) {
          Write-Host ''
          Write-Host "공용 서버로 올리지 않은 설치본 백업이 $($rows.Count)건 있습니다 — 지우면 되살릴 수 없습니다:" -ForegroundColor Yellow
          $rows | Select-Object -First 15 | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
          if ($rows.Count -gt 15) { Write-Host "  ... 외 $($rows.Count - 15)건" -ForegroundColor Yellow }
          Write-Host '  먼저 설치본 백업 화면에서 [공용 서버로 올리기]를 누르는 것을 권합니다.' -ForegroundColor Yellow
        } else {
          Say '올리지 않은 설치본 백업은 없습니다'
        }
      }
    }
  } catch {
    $ErrorActionPreference = 'Stop'
  }
}
if (-not $checked) { Write-Host '올리지 않은 백업이 있는지 확인하지 못했습니다 — 설치본 백업 화면에서 미업로드가 없는지 먼저 확인하세요.' -ForegroundColor Yellow }

Write-Host ''
Write-Host '프로그램, DB, 받아 둔 패키지, 설치본 백업을 모두 지웁니다. 배포 이력·보고서는 데이터 동기화로 공용 서버에 올렸어야 남습니다.'
$answer = Read-Host '정말 지우려면 DELETE 를 입력하세요 (그 밖의 입력은 취소)'
# 콘솔·파이프에 따라 앞뒤에 보이지 않는 문자(BOM, CR)가 붙는다 — 앞뒤의 공백·BOM만 떼고 정확히 비교한다
if (($answer -replace '^[\s﻿]+|[\s﻿]+$', '') -cne 'DELETE') { Say '취소했습니다 — 아무것도 지우지 않았습니다'; exit 0 }

# ── 지우기 ─────────────────────────────────────────────────────────────────
$left = @()
if ($task) {
  Say "웹 예약 작업 지우기: $WebTask"
  Stop-ScheduledTask -TaskName $WebTask -ErrorAction SilentlyContinue
  Unregister-ScheduledTask -TaskName $WebTask -Confirm:$false
}
$node = Join-Path $Root 'node\node.exe'
$procs = @(Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $node })
$procs | Stop-Process -Force -ErrorAction SilentlyContinue
$procs | Wait-Process -Timeout 30 -ErrorAction SilentlyContinue

if (Get-Service $DbService -ErrorAction SilentlyContinue) {
  Say "DB 서비스 지우기: $DbService"
  Stop-Service $DbService -Force -ErrorAction SilentlyContinue
  sc.exe delete $DbService | Out-Null
  for ($i = 0; $i -lt 30 -and (Get-Service $DbService -ErrorAction SilentlyContinue); $i++) { Start-Sleep 1 }
  if (Get-Service $DbService -ErrorAction SilentlyContinue) { $left += "DB 서비스 $DbService (PC를 다시 켜면 사라집니다)" }
}

if ($isInstall -and (Test-Path -LiteralPath $Root)) {
  Say "설치 폴더 지우기: $Root"
  for ($i = 0; $i -lt 5 -and (Test-Path -LiteralPath $Root); $i++) {
    # (2026-10-16) rmdir /s 는 안쪽의 연결 폴더(정션)를 따라가지 않고 연결만 끊는다 — PowerShell 5.1 Remove-Item은 따라갈 수 있다
    cmd.exe /c "rmdir /s /q `"$Root`" >nul 2>nul"
    if (Test-Path -LiteralPath $Root) { Start-Sleep 2 }
  }
  if (Test-Path -LiteralPath $Root) { $left += "설치 폴더 $Root (쓰고 있는 프로그램을 닫고 지우세요)" }
}

$lnk = Join-Path ([Environment]::GetFolderPath('CommonDesktopDirectory')) 'PKG 관리.lnk'
if (Test-Path -LiteralPath $lnk) { Remove-Item -LiteralPath $lnk -Force }
[Environment]::SetEnvironmentVariable('PKGREPO_ROOT', $null, 'Machine')

Write-Host ''
if ($left.Count -eq 0) {
  Say '다 지웠습니다'
} else {
  Write-Host '다 지우지 못한 것이 있습니다:' -ForegroundColor Yellow
  $left | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
  exit 1
}
