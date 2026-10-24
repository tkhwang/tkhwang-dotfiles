#!/bin/bash
# 작업 폴더(branch-base)별 dev 서버 포트와 서버 명령을 정의한다. 정의는 이 파일 한 곳이고,
# herdr-dev.sh(herdr pane 에 띄움)와 agent-dev.sh(agent 가 background 로 띄움)가 source 해서 쓴다.
# 작업 폴더는 이 파일과 같은 폴더(monask-fullstack) 바로 아래에 있어야 한다. 두 스크립트가 ../dev-ports.sh 를 읽는다.
#
#   폴더          backend  frontend
#   _base (원본)  5000     3001     ← repo 기본값
#   task-a        5010     3011
#   task-b        5020     3021
#   task-c        5030     3031
#   task-d        5040     3041
#   shared        5050     3051
#
# 표에 없는 폴더는 원본과 같은 5000/3001 을 쓴다. DB 는 worktree 별로 분리돼 있고 Redis 만 공유한다.
# frontend 는 VITE_BASE_API_URL 로 같은 task 의 backend 를 바라보고, --strictPort 라 포트가 막혀 있으면
# 옆 포트로 비켜 가지 않고 실패한다.
#
# source 할 때: dev_ports <작업 폴더>
#   task be_port fe_port port_note be_server_cmd fe_server_cmd 를 채운다.
#   env 로 바꿀 수 있다: BE_PORT FE_PORT (포트 표 대신), BE_SERVER_CMD FE_SERVER_CMD (명령 자체)
#   port_pid <포트>     LISTEN 중인 pid (없으면 빈 문자열)
#   pid_cwd <pid>       프로세스의 현재 폴더
#   두 함수는 없어도 0 으로 끝난다. set -e·pipefail 인 스크립트에서 lsof 의 1 로 멈추지 않게 하려는 것이다.
#
# 실행할 때: ./dev-ports.sh [<폴더> ...]
#   폴더별 포트, 서버 명령, 포트를 잡고 있는 프로세스를 보여준다. 인자가 없으면 모든 작업 폴더.
#   <폴더>: feature-cpq-task-a, task-a (feature-cpq- 생략), 또는 절대 경로

dev_ports() {
  local name
  name="$(basename "${1%/}")"
  task="${name#feature-cpq-}"              # feature-cpq-task-a → task-a
  port_note=""
  case "$task" in
    _base)       be_port=5000; fe_port=3001 ;;   # 원본: repo 기본값
    task-a)      be_port=5010; fe_port=3011 ;;
    task-b)      be_port=5020; fe_port=3021 ;;
    task-c)      be_port=5030; fe_port=3031 ;;
    task-d)      be_port=5040; fe_port=3041 ;;
    task-shared) be_port=5050; fe_port=3051 ;;
    *)           be_port=5000; fe_port=3001; port_note="(표에 없는 폴더 '$task': 원본과 같은 기본 포트)" ;;
  esac
  be_port="${BE_PORT:-$be_port}"
  fe_port="${FE_PORT:-$fe_port}"
  be_server_cmd="${BE_SERVER_CMD:-PORT=$be_port pnpm start}"
  fe_server_cmd="${FE_SERVER_CMD:-VITE_BASE_API_URL=http://localhost:$be_port pnpm main --port $fe_port --strictPort}"
}

port_pid() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN -t 2>/dev/null | head -1 || true
}

pid_cwd() {
  lsof -a -p "$1" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' || true
}

# 직접 실행했을 때만 아래를 돈다 (source 하면 함수만 정의한다)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
  root="$(cd "$(dirname "$0")" && pwd)"

  dirs=()
  if [ $# -eq 0 ]; then
    for d in "$root"/*/; do
      [ -d "$d/backend" ] && [ -d "$d/frontend" ] && dirs+=("${d%/}")
    done
  else
    for a in "$@"; do
      a="${a%/}"
      case "$a" in
        /*) dirs+=("$a") ;;
        *)  if [ -d "$root/$a" ]; then dirs+=("$root/$a"); else dirs+=("$root/feature-cpq-$a"); fi ;;
      esac
    done
  fi

  listener() {  # $1: 포트 → "pid <pid> <cwd>" 또는 "-"
    local pid
    pid="$(port_pid "$1")"
    if [ -n "$pid" ]; then echo "pid $pid $(pid_cwd "$pid")"; else echo "-"; fi
  }

  for d in "${dirs[@]}"; do
    dev_ports "$d"
    echo "$task  $port_note"
    printf '  backend   :%s  %s\n' "$be_port" "$(listener "$be_port")"
    printf '  frontend  :%s  %s\n' "$fe_port" "$(listener "$fe_port")"
    printf '  be server  %s\n' "$be_server_cmd"
    printf '  fe server  %s\n' "$fe_server_cmd"
  done
fi
