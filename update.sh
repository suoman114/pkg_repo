#!/bin/bash
# pkg_repo 새 버전 받기 + 설치 — 리눅스 PC(CentOS/RHEL 7)용. Windows(WSL)는 update.bat 을 쓴다.
#   sudo ./update.sh
# GitHub의 최신 Release에서 설치 묶음을 받아 install.sh 로 설치한다. 설정·DB·받아 둔 파일은 그대로 유지된다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec bash "$HERE/install.sh" --download
