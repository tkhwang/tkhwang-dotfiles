#!/bin/bash
# agent 가 이 작업 폴더(branch-base)의 dev 서버를 background 로 띄우고 내린다. 포트와 서버 명령은
# ../dev-ports.sh 의 정의를 쓰므로 herdr-dev.sh 로 띄운 서버와 같다. herdr 없이도 동작한다.
#
# task 하나에 서버는 한 벌이다. 이 폴더의 서버가 이미 떠 있으면(herdr 탭이든 사용자든) 그대로 쓰고,
# 내리거나 다시 띄우는 것은 agent-dev.sh 가 띄운 서버만 한다. 포트를 다른 폴더의 프로세스가 잡고 있으면 멈춘다.
# 서버는 자기 process group 으로 띄워 pnpm 아래 node 까지 한 번에 내린다. pid·log 는 ./.agent-dev/ 에 둔다.
# herdr 안에서 실행하면 up·restart 때 herdr-dev.sh watch-start 로 사이드바 감시를 켜서, herdr 탭으로 띄운
# 서버처럼 열린 포트가 사이드바에 보인다. agent-dev 가 띄운 서버는 workspace 토큰 $fe_agent, $be_agent 로
# 보고되어 사람이 띄운 서버($fe, $be)와 구분된다. herdr 밖이거나 실패해도 서버에는 영향이 없다.
#
# usage: ./agent-dev.sh <명령> [be|fe]
#   up [be|fe]        서버를 띄우고 포트가 열릴 때까지 기다린다 (기본 둘 다)
#   restart [be|fe]   agent-dev.sh 가 띄운 서버를 내렸다 올린다 (기본 be. backend 는 watch 가 없다)
#   down [be|fe]      agent-dev.sh 가 띄운 서버를 내린다 (기본 둘 다)
#   status            포트, 서버를 띄운 쪽, log 경로
#   logs [be|fe] [N]  log 마지막 N 줄 (기본 be, 80줄)
#   ports             포트와 서버 명령
#
# exit code: 0 성공, 1 실패, 2 사용법 오류, 3 herdr 탭이나 사용자가 띄운 서버라 손대지 않음
set -euo pipefail

base="$(cd "$(dirname "$0")" && pwd)"
def="$base/../dev-ports.sh"
[ -f "$def" ] || { echo "포트 정의가 없습니다: $def (작업 폴더가 monask-fullstack 바로 아래에 있어야 합니다)" >&2; exit 1; }
# shellcheck source=/dev/null
source "$def"
dev_ports "$base"

state="$base/.agent-dev"

die() { echo "$*" >&2; exit 1; }
usage() { awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; }

port_of() { case "$1" in be) echo "$be_port" ;; fe) echo "$fe_port" ;; esac; }
dir_of()  { case "$1" in be) echo "$base/backend" ;; fe) echo "$base/frontend" ;; esac; }
cmd_of()  { case "$1" in be) echo "$be_server_cmd" ;; fe) echo "$fe_server_cmd" ;; esac; }
name_of() { case "$1" in be) echo backend ;; fe) echo frontend ;; esac; }
limit_of() { case "$1" in be) echo 300 ;; fe) echo 120 ;; esac; }   # 포트가 열릴 때까지 최대 대기 초

# agent-dev.sh 가 띄운 process group id. 살아 있지 않으면 pid 파일을 지우고 빈 문자열
group_of() {
  local f="$state/$1.pid" pg
  [ -f "$f" ] || return 0
  pg="$(cat "$f" 2>/dev/null)"
  if [ -n "$pg" ] && kill -0 -- "-$pg" 2>/dev/null; then echo "$pg"; else rm -f "$f"; fi
}

# 포트를 잡은 쪽: off | agent | task (herdr 탭·사용자가 띄운 이 폴더 서버) | other:<cwd>
owner_of() {
  local pid pg cwd
  pid="$(port_pid "$(port_of "$1")")"
  [ -n "$pid" ] || { echo off; return; }
  pg="$(group_of "$1")"
  if [ -n "$pg" ] && [ "$(ps -o pgid= -p "$pid" | tr -d ' ')" = "$pg" ]; then echo agent; return; fi
  cwd="$(pid_cwd "$pid")"
  case "$cwd/" in "$base"/*) echo task ;; *) echo "other:$cwd" ;; esac
}

# 서버를 띄운다. 이미 떠 있거나 기동 중이면 그대로 둔다
launch() {
  local s=$1 port dir cmd owner pg
  port="$(port_of "$s")"; dir="$(dir_of "$s")"; cmd="$(cmd_of "$s")"
  [ -d "$dir" ] || die "폴더가 없습니다: $dir"
  owner="$(owner_of "$s")"
  case "$owner" in
    agent)   echo "$(name_of "$s") :$port 이미 떠 있습니다 (agent-dev)"; return 0 ;;
    task)    echo "$(name_of "$s") :$port 이미 떠 있습니다 (herdr 탭 또는 사용자가 띄운 이 task 서버). 그대로 씁니다"; return 0 ;;
    other:*) echo "$(name_of "$s") :$port 를 다른 폴더의 프로세스가 잡고 있습니다: ${owner#other:}" >&2; return 1 ;;
  esac
  pg="$(group_of "$s")"
  if [ -n "$pg" ]; then echo "$(name_of "$s") 기동 중입니다 (pgid $pg)"; return 0; fi
  mkdir -p "$state"
  echo "== $(date '+%F %T') $cmd" >> "$state/$s.log"
  set -m   # background job 을 자기 process group 으로 띄운다
  ( cd "$dir" && exec nohup bash -c "$cmd" ) >> "$state/$s.log" 2>&1 < /dev/null &
  pg=$!
  set +m
  echo "$pg" > "$state/$s.pid"
  echo "$(name_of "$s") 시작 (pgid $pg): $cmd"
}

# herdr 안이면 열린 서버 포트를 사이드바에 보여주는 감시를 켠다 (이미 돌고 있으면 그대로). 서버가 다 내려가면 감시가 스스로 끝난다
sidebar_watch() {
  [ "${HERDR_ENV:-}" = 1 ] && [ -x "$base/herdr-dev.sh" ] || return 0
  "$base/herdr-dev.sh" watch-start 2>/dev/null | sed 's/^ */herdr 사이드바: /' || true
}

# 포트가 열릴 때까지 기다린다. 이미 떠 있던 서버는 바로 통과한다
await_port() {
  local s=$1 port pg limit i
  port="$(port_of "$s")"; limit="$(limit_of "$s")"
  for ((i = 0; i < limit; i++)); do
    if [ -n "$(port_pid "$port")" ]; then
      echo "$(name_of "$s") http://localhost:$port 준비됨"
      return 0
    fi
    pg="$(group_of "$s")"
    if [ -z "$pg" ]; then
      echo "$(name_of "$s") 가 포트를 열기 전에 끝났습니다. log: $state/$s.log" >&2
      tail -n 30 "$state/$s.log" >&2 || true
      return 1
    fi
    sleep 1
  done
  echo "$(name_of "$s") 가 ${limit}초 안에 :$port 를 열지 않았습니다. 기동 중일 수 있으니 status·logs 로 확인하세요" >&2
  return 1
}

stop() {
  local s=$1 pg owner i
  pg="$(group_of "$s")"
  if [ -z "$pg" ]; then
    owner="$(owner_of "$s")"
    case "$owner" in
      task)    echo "$(name_of "$s") :$(port_of "$s") 는 herdr 탭이나 사용자가 띄운 서버라 내리지 않습니다" >&2; return 3 ;;
      other:*) echo "$(name_of "$s") :$(port_of "$s") 는 다른 폴더의 서버라 내리지 않습니다: ${owner#other:}" >&2; return 1 ;;
      *)       echo "$(name_of "$s"): agent-dev 가 띄운 서버가 없습니다"; return 0 ;;
    esac
  fi
  kill -TERM -- "-$pg" 2>/dev/null || true
  for ((i = 0; i < 15; i++)); do
    kill -0 -- "-$pg" 2>/dev/null || break
    sleep 1
  done
  if kill -0 -- "-$pg" 2>/dev/null; then
    kill -KILL -- "-$pg" 2>/dev/null || true
    echo "  $(name_of "$s"): 15초 안에 끝나지 않아 강제 종료했습니다"
  fi
  rm -f "$state/$s.pid"
  echo "$(name_of "$s") 종료 (pgid $pg)"
}

restart() {
  local s=$1 owner
  owner="$(owner_of "$s")"
  case "$owner" in
    task)    echo "$(name_of "$s") :$(port_of "$s") 는 herdr 탭이나 사용자가 띄운 서버입니다. 재시작은 사용자에게 요청하세요" >&2; return 3 ;;
    other:*) echo "$(name_of "$s") :$(port_of "$s") 를 다른 폴더의 프로세스가 잡고 있습니다: ${owner#other:}" >&2; return 1 ;;
  esac
  stop "$s" && launch "$s" && { sidebar_watch; await_port "$s"; }
}

cmd_status() {
  local s o pg
  echo "$task  $port_note"
  for s in be fe; do
    o="$(owner_of "$s")"; pg="$(group_of "$s")"
    case "$o" in
      off)     if [ -n "$pg" ]; then o="기동 중 (agent-dev, pgid $pg)"; else o="꺼짐"; fi ;;
      agent)   o="agent-dev (pgid $pg)" ;;
      task)    o="herdr 탭 또는 사용자 (이 task)" ;;
      other:*) o="다른 폴더: ${o#other:}" ;;
    esac
    printf '  %-9s http://localhost:%s  %s\n' "$(name_of "$s")" "$(port_of "$s")" "$o"
  done
  echo "  log: $state/{be,fe}.log"
}

cmd_ports() {
  echo "$task  $port_note"
  echo "  backend   http://localhost:$be_port  ($base/backend) $be_server_cmd"
  echo "  frontend  http://localhost:$fe_port  ($base/frontend) $fe_server_cmd"
}

cmd="${1:-}"
[ $# -gt 0 ] && shift
sel="${1:-}"
case "$sel" in ""|be|fe) ;; *) echo "be 또는 fe 만 받습니다: $sel" >&2; exit 2 ;; esac

rc=0
case "$cmd" in
  up)
    for s in ${sel:-be fe}; do launch "$s" || rc=$?; done
    [ "$rc" = 0 ] && sidebar_watch
    [ "$rc" = 0 ] && for s in ${sel:-be fe}; do await_port "$s" || rc=$?; done ;;
  restart) for s in ${sel:-be}; do restart "$s" || rc=$?; done ;;
  down)    for s in ${sel:-be fe}; do stop "$s" || rc=$?; done ;;
  status)  cmd_status ;;
  logs)
    f="$state/${sel:-be}.log"
    [ -f "$f" ] || die "log 가 없습니다: $f"
    tail -n "${2:-80}" "$f" ;;
  ports)   cmd_ports ;;
  *)       usage; exit 2 ;;
esac
exit "$rc"
