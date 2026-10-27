#!/bin/bash
# herdr-dev.sh·agent-dev.sh(원본)를 작업 폴더(branch-base)로 복사한다.
# 두 스크립트는 자기 위치의 ./frontend, ./backend 를 쓰므로 backend/, frontend/ 가
# 나란히 있는 폴더에 두어야 한다. 포트 정의 dev-ports.sh 는 복사하지 않는다. 두 스크립트가
# ../dev-ports.sh 를 읽으므로 작업 폴더는 monask-fullstack 바로 아래에 있어야 한다.
#
# usage: ./install-herdr-dev.sh [<task-dir> ...]
#   <task-dir>: monask-fullstack 아래 작업 폴더 이름(예: feature-cpq-task-b) 또는 절대 경로
#   인자가 없으면 .workbranch.task 가 있는 모든 작업 폴더에 설치한다.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
for f in herdr-dev.sh agent-dev.sh dev-ports.sh; do
  [ -f "$root/$f" ] || { echo "원본이 없습니다: $root/$f" >&2; exit 1; }
done

tasks=()
if [ $# -eq 0 ]; then
  for d in "$root"/*/; do
    [ -f "$d.workbranch.task" ] && tasks+=("${d%/}")
  done
else
  for a in "$@"; do
    case "$a" in
      /*) tasks+=("${a%/}") ;;
      *)  tasks+=("$root/${a%/}") ;;
    esac
  done
fi
[ ${#tasks[@]} -gt 0 ] || { echo "설치할 작업 폴더가 없습니다" >&2; exit 1; }

status=0
for task in "${tasks[@]}"; do
  if [ ! -d "$task" ]; then
    echo "건너뜀: 폴더가 없습니다: $task" >&2; status=1; continue
  fi
  if [ ! -d "$task/frontend" ] || [ ! -d "$task/backend" ]; then
    echo "건너뜀: frontend/ 와 backend/ 가 없습니다: $task" >&2; status=1; continue
  fi
  if [ ! -f "$task/../dev-ports.sh" ]; then
    echo "건너뜀: ../dev-ports.sh 가 없습니다 (monask-fullstack 바로 아래 폴더가 아님): $task" >&2; status=1; continue
  fi
  for script in herdr-dev.sh agent-dev.sh; do
    dst="$task/$script"
    if [ -f "$dst" ] && cmp -s "$root/$script" "$dst"; then
      echo "같음    $dst"
      continue
    fi
    # 새 파일로 바꿔 끼운다. bash 는 스크립트를 읽어 가며 실행하므로, 덮어쓰면 돌고 있는
    # herdr-dev.sh watch 가 바뀐 내용을 엉뚱한 위치부터 읽는다. mv 면 돌던 프로세스는 옛 파일을 계속 읽는다
    cp "$root/$script" "$dst.tmp.$$"
    chmod +x "$dst.tmp.$$"
    mv -f "$dst.tmp.$$" "$dst"
    echo "copied → $dst"
  done
done
exit $status
