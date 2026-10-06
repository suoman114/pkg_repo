#!/bin/bash
# pkg_repo 설치 / 새 버전으로 갱신 — 리눅스 PC(CentOS/RHEL 7)용. Windows(WSL)는 install.bat 을 쓴다.
#
#   sudo ./install.sh              이 폴더에 pkgrepo-el7-bundle.tar.gz 가 있으면 그것으로, 없으면 GitHub에서 받아 설치
#   sudo ./install.sh --download   항상 GitHub의 최신 Release를 새로 받아 설치 (update.sh 가 이것을 부른다)
#
# 설치 묶음은 CentOS/RHEL 7용이다(Node·PostgreSQL 15·git rpm이 7용). 처음 설치할 때만 설치 형태·공용 서버 주소 등을 묻고,
# 다시 실행하면 설정·DB·받아 둔 패키지와 백업은 그대로 둔 채 웹만 새 버전으로 바꾼다.
# 설치 뒤 켜고 끄기: pkg-repo start | stop | restart | status | log
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
URL=https://github.com/suoman114/pkg_repo/releases/latest/download/pkgrepo-el7-bundle.tar.gz
TAR="$HERE/pkgrepo-el7-bundle.tar.gz"
WORK=/root/pkg-repo-install

[ "$(id -u)" = "0" ] || { echo "[오류] root로 실행하세요: sudo $0 $*" >&2; exit 1; }

download() {
  echo "== 최신 설치 묶음을 받습니다 (약 150MB)"
  echo "   $URL"
  rm -f "$TAR.part"
  if command -v curl >/dev/null 2>&1 && curl -L -f --retry 2 -o "$TAR.part" "$URL"; then
    :
  elif command -v wget >/dev/null 2>&1 && wget -O "$TAR.part" "$URL"; then
    :
  else
    rm -f "$TAR.part"
    echo "[오류] 설치 묶음을 받지 못했습니다. 인터넷 연결을 확인하세요." >&2
    echo "       인터넷이 안 되거나 인증서 오류가 나는 PC라면, 다른 PC에서 위 주소의 파일을 받아" >&2
    echo "       이 폴더($HERE)에 넣고 ./install.sh 를 실행하세요." >&2
    exit 1
  fi
  mv -f "$TAR.part" "$TAR"
}

if [ "${1:-}" = "--download" ] || [ ! -s "$TAR" ]; then download; else echo "== 이 폴더의 설치 묶음을 씁니다: $TAR"; fi

mkdir -p "$WORK"
cd "$WORK"
rm -rf pkgrepo-el7-bundle
tar -xzf "$TAR"
chmod +x pkgrepo-el7-bundle/install-el7.sh
echo "== 설치 (버전 $(cat pkgrepo-el7-bundle/VERSION 2>/dev/null || echo '?'))"
exec ./pkgrepo-el7-bundle/install-el7.sh
