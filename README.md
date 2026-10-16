# pkg_repo 설치 안내 (사용자 PC — Windows / 리눅스 CentOS 7)

LTE-R VCS PKG 관리 웹(pkg_repo)을 내 PC에 설치해서, 현장에서 배포 · 설치 점검 · 보고서 · 백업을 하고
사무실에서 공용 서버로 올리는 용도입니다.

PC는 Bitbucket에 직접 연결하지 않습니다. 받기와 올리기는 모두 사무실 공용 서버(`http://172.10.11.161:3000`)를 거칩니다.

설치 파일은 GitHub에서 받습니다: <https://github.com/suoman114/pkg_repo>

- 이 저장소의 파일(아래 스크립트들) — 초록색 **Code > Download ZIP** 으로 받거나 `git clone`
- 설치 묶음 — **Releases** 에 버전별로 올라가 있고, 스크립트가 최신 것을 알아서 받습니다
  (직접 받을 때: <https://github.com/suoman114/pkg_repo/releases/latest>)
  - Windows: `pkgrepo-win-bundle.tar.gz` (약 160MB)
  - 리눅스: `pkgrepo-el7-bundle.tar.gz` (약 150MB)

## 이 폴더에 든 것

| 파일 | 어디서 쓰나 | 용도 |
|---|---|---|
| `update.bat` | Windows | 최신 설치 묶음을 받아 설치 / 새 버전으로 갱신 |
| `install.bat` | Windows | 이 폴더에 있는 설치 묶음으로 설치 (인터넷 없이) |
| `start.bat` / `stop.bat` / `status.bat` | Windows | 켜기 / 끄기 / 상태 확인 |
| `uninstall.bat` (+ `uninstall.ps1`) | Windows | 완전히 지우기 (프로그램·DB·받아 둔 패키지·백업) |
| `update.sh` | 리눅스 | 최신 설치 묶음을 받아 설치 / 새 버전으로 갱신 |
| `install.sh` | 리눅스 | 이 폴더에 설치 묶음이 있으면 그것으로, 없으면 받아서 설치 |

## 준비물

- **Windows**: Windows 10 / 11, **관리자 권한**. WSL은 필요 없습니다(웹·DB가 묶음에 들어 있습니다).
- **리눅스**: **CentOS 7 / RHEL 7** 이어야 합니다(설치 묶음의 Node · PostgreSQL · git이 7용입니다). root 권한이 필요합니다.
- 공용 서버에 만들어진 **본인 계정**(아이디/비밀번호). 최고 관리자에게 요청합니다.
- 디스크 여유: 설치에 약 1GB, 패키지와 백업까지 쓰면 수 GB.

## 설치 — Windows

1. 이 폴더를 PC에 둡니다 (예: `D:\pkgrepo-dist`).
2. `update.bat` 을 더블클릭합니다. 설치 묶음을 받고 바로 설치합니다. 관리자 권한 확인 창이 뜨면 **예** 를 누릅니다.
   인터넷이 안 되는 PC는 다른 PC에서 받은 `pkgrepo-win-bundle.tar.gz` 와 `pkgrepo-win-bundle.tar.gz.sha256` 을 이 폴더에 넣고 `install.bat` 을 실행합니다.
   (`.sha256` 은 묶음이 손상되거나 바뀌지 않았는지 검사하는 데 씁니다. 없으면 검사 없이 설치합니다.)
3. 물어보는 값을 입력합니다(처음 설치할 때만).
   - 설치 폴더 — 그냥 Enter면 `C:\pkg-repo`. 다른 곳에 두려면 `D:\pkg-repo` 처럼 적습니다
     (드라이브 맨 위, Windows·Program Files 같은 시스템 폴더 자체, 다른 파일이 든 폴더, 네트워크 드라이브·USB,
     연결 폴더(정션), `& % ^ ! " < > | [ ] * ?` 가 든 경로는 쓸 수 없습니다)
   - 공용 서버 주소 — 그냥 Enter면 `http://172.10.11.161:3000`
   - 이 PC의 이름 — 공용 서버 기록에 표시됩니다 (예: `홍길동-노트북`)
   - 웹 포트 — 그냥 Enter면 3000
4. "응답 정상"이 나오면 끝입니다. 바탕화면에 **PKG 관리** 아이콘이 생깁니다.

설치 폴더(기본 `C:\pkg-repo`)는 시스템 환경 변수 `PKGREPO_ROOT` 에 기억돼, 갱신과 `start/stop/status/uninstall.bat` 이 그 폴더를 씁니다.
한 PC에는 하나만 설치됩니다 — 다른 폴더로 옮기려면 `uninstall.bat` 으로 지운 뒤 새로 설치합니다.
DB(서비스 `pkg-repo-db`)와 웹(예약 작업 `pkg-repo-web`)은 **PC를 켜면 자동으로 시작**됩니다.
DB는 이 PC 안(`127.0.0.1:15432`)에서만, 웹은 이 PC에서만(`127.0.0.1`) 열립니다.

### 예전에 WSL(CentOS 7)로 설치해 쓰던 PC

1. 예전 설치본에서 **설치본 백업 > 공용 서버로 올리기**, **설정 > 데이터 동기화 > 동기화** 를 눌러 남은 기록을 모두 올립니다.
2. 위 순서대로 새로 설치합니다. 기록은 공용 서버에서 다시 받습니다.
3. 새 설치가 잘 되면 예전 WSL 설치본은 꺼 두거나(`wsl -d CentOS7 -u root -- pkg-repo stop all`) 지워도 됩니다.

## 설치 — 리눅스 (CentOS 7 / RHEL 7)

```bash
git clone https://github.com/suoman114/pkg_repo.git    # 또는 ZIP을 받아 풉니다
cd pkg_repo
sudo bash update.sh
```

물어보는 값은 Windows와 같습니다(처음 설치할 때만). "응답 정상"이 나오면 끝입니다.
인터넷이 안 되거나 받는 중 인증서 오류가 나면, 다른 PC에서 받은 `pkgrepo-el7-bundle.tar.gz` 를 이 폴더에 넣고 `sudo bash install.sh` 를 실행합니다.

설치 뒤에는 어느 폴더에서든 아래 명령을 씁니다.

```bash
sudo pkg-repo start      # 켜기 → 브라우저에서 http://localhost:3000
sudo pkg-repo stop all   # 끄기 (DB 포함)
sudo pkg-repo status     # 상태 확인
sudo pkg-repo log        # 로그 보기
```

## 사용

1. 엽니다 — Windows는 바탕화면의 **PKG 관리** 아이콘, 리눅스는 `sudo pkg-repo start` 후 브라우저. **공용 서버 계정**으로 로그인합니다.
   사내망에서 한 번 로그인해 두면 현장(오프라인)에서도 같은 계정으로 로그인됩니다(서버 확인 후 30일까지).
2. **현장에 나가기 전(사내망)**: 왼쪽 메뉴 **설정 > 데이터 동기화** 에서 `동기화` 를 눌러 site · 패키지 목록 · 배포 단계 · 프로세스 버전을 받습니다.
3. **현장에 나가기 전(사내망)**: 배포 화면에서 쓸 패키지를 고르고 `동기화` 를 눌러 패키지 파일을 미리 받아 둡니다.
4. **현장**: 배포 실행 → 설치 점검(보고서) → 설치본 백업.
5. **사무실 복귀 후(사내망)**: 설치본 백업 화면에서 `공용 서버로 올리기`, 그리고 **설정 > 데이터 동기화** 에서 `동기화` 를 눌러
   배포 이력 · 보고서 · 백업 기록을 올립니다. 공용 서버가 꺼져 있으면 올릴 수 없고, 살아난 뒤에 올립니다.

Windows는 따로 끌 필요가 없습니다. 끄고 싶으면 `stop.bat`(관리자 권한), 다시 켤 때는 `start.bat` 또는 PC 재시작.

## 새 버전으로 갱신

- **Windows**: `update.bat` 을 다시 실행합니다.
- **리눅스**: `sudo bash update.sh` 를 다시 실행합니다.

설정, DB, 내려받은 패키지와 백업은 그대로 유지됩니다. 공용 서버와 같은 버전을 쓰세요.
지금 설치된 버전은 `status.bat`(리눅스는 `sudo pkg-repo status`)의 health 줄에 나오고, 올라와 있는 버전은 GitHub의 Releases에서 봅니다.
스크립트 자체(`*.bat`, `*.sh`)가 바뀌었을 때는 이 저장소를 다시 받습니다(`git pull` 또는 ZIP).

## 지우기 (Windows)

`uninstall.bat` 을 실행합니다(관리자 권한). 공용 서버로 올리지 않은 설치본 백업이 있으면 목록을 먼저 보여 주고,
`DELETE` 를 입력해야 지웁니다. 웹·DB 서비스·설치 폴더(프로그램, DB, 받아 둔 패키지, 백업)·바탕화면 아이콘이 모두 지워집니다.
배포 이력·보고서는 데이터 동기화로 공용 서버에 올려 두었다면 다시 설치한 뒤 동기화로 받을 수 있습니다.

## 설정을 바꾸려면

`설치 폴더\pkg-repo.env`(기본 `C:\pkg-repo\pkg-repo.env`, 리눅스는 `/opt/pkg-repo/pkg-repo.env`)를 관리자 권한 메모장으로 고치고 `stop.bat` → `start.bat` 으로 껐다 켭니다.

| 항목 | 이름 |
|---|---|
| 설치 형태 | `APP_MODE` (`client`) |
| 공용 서버 주소 | `SERVER_URL` |
| 웹 포트 | `PORT` — 바꾸면 바탕화면 아이콘은 `install.bat` 을 다시 실행해 새로 만듭니다 |
| 이 PC의 이름 | `DATA_SYNC_MACHINE_NAME` |

## 문제가 생기면

- **아이콘을 눌러도 안 열림 / 응답 없음**: `status.bat` 으로 상태를 보고, `설치 폴더\data\web.log` 로 원인을 확인합니다(리눅스는 `sudo pkg-repo status`, `pkg-repo log`).
- **3000 포트를 다른 프로그램이 씀**: `pkg-repo.env` 의 `PORT` 를 3001 등으로 바꿉니다.
- **설치 묶음을 받지 못함**: 인터넷 연결을 확인합니다. 안 되면 다른 PC에서 Releases의 파일을 받아 이 폴더에 넣고 `install.bat` / `install.sh` 를 실행합니다.
- **"공용 서버에 닿지 않습니다"**: 사내망에 연결돼 있는지, 공용 서버가 켜져 있는지 확인합니다. 현장에서는 정상입니다.
- **"공용 서버 로그인이 만료됐습니다"**: 서버 로그인은 12시간 유효합니다. 로그아웃 후 다시 로그인합니다.
- **현장에서 로그인이 안 됨**: 그 계정으로 이 PC에서 사내망 로그인을 한 적이 있어야 합니다.
- **현장에서 서버에 접속이 안 됨**: 이 PC에서 `ssh root@서버IP` 가 되는지 먼저 확인합니다(PC의 네트워크가 그 대역에 닿아야 합니다).

## 사무실 공용 서버 (참고)

공용 서버(`http://172.10.11.161:3000`)는 리눅스 묶음(`pkgrepo-el7-bundle.tar.gz`, 설치 형태 2)으로 설치돼 있습니다. 서버에서는
`pkg-repo start | stop | restart | status | log | create-super` 로 다루고, 설정은 `/opt/pkg-repo/pkg-repo.env` 입니다.
계정은 최고 관리자가 **설정 > 계정 관리** 에서 만듭니다.
