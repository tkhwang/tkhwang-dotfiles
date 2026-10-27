#!/bin/bash
# herdr 에 dev 탭을 4분할로 만들어 frontend/backend 의 test watch 와 server 를 띄우고 내린다.
#
#   ┌───────────────────────┬───────────────────────┐
#   │ fe test               │ be test               │
#   │ pnpm test:unit:watch  │ pnpm test:unit:watch  │
#   ├───────────────────────┼───────────────────────┤
#   │ fe server             │ be server             │
#   │ pnpm main --port FE   │ PORT=BE pnpm start    │
#   └───────────────────────┴───────────────────────┘
#
# 이 스크립트는 branch-base(backend/, frontend/ 가 나란히 있는 폴더)에 두고 쓴다.
# 스크립트 위치 기준으로 ./frontend, ./backend 를 쓴다. branch-base 는 monask-fullstack 바로 아래에 있어야 한다.
# 탭은 branch-base 폴더 이름과 label 이 같은 herdr workspace 에 만들고, 없으면 현재 workspace 에 만든다.
#
# task 별 포트와 서버 명령은 ../dev-ports.sh 에 정의돼 있다. agent-dev.sh(agent 가 background 로 띄움)도
# 같은 정의를 쓴다. task 하나에 서버는 한 벌이라, 포트가 이미 열려 있으면 up 은 탭을 만들지 않고 멈춘다.
#
# 사이드바 표시: up 은 감시 프로세스(watch)를 백그라운드로 띄운다. 5초마다 두 서버 포트를 이 task 폴더의
# 프로세스가 LISTEN 중인지 보고, 열려 있는 것만 누가 띄웠는지에 따라 workspace 토큰으로 보고한다.
#   herdr 탭이나 사람이 띄운 서버   $fe, $be              예) "🧑 fe:3011 · be:5010" (첫 토큰에만 🧑)
#   agent-dev.sh 가 띄운 서버       $fe_agent, $be_agent  예) "🤖 fe:3011 · be:5010" (첫 토큰에만 🤖)
#   둘이 섞이면 폭을 넘지 않게 🤖 만 붙인다                예) "fe:3011 · 🤖 be:5010"
# agent-dev.sh 도 up·restart 때 watch-start 로 같은 감시를 켠다. 서버가 내려가면 토큰이 사라지고, dev 탭도
# 이 task 의 서버도(기동 중인 agent-dev 서버 포함) 15초 넘게 없으면 감시가 끝난다.
# ~/.config/herdr/config.toml 의 [ui.sidebar.spaces] rows 에 네 토큰이 있어야 보인다 (색은 거기서 정한다).
#
# usage: ./herdr-dev.sh up|down|restart|status|ports|watch-start
#   up       dev 탭을 만들고 네 pane 에 명령을 실행한다 (이미 있으면 감시만 확인한다)
#   down     각 pane 에 ctrl+c 를 보내 끝낸 뒤 탭을 닫는다. 탭 밖에서 띄운 서버가 남아 있지 않으면 감시도 멈춘다
#   restart  down 뒤 up
#   status   이 task 의 dev 탭 pane, 열린 포트, 감시 상태, 다른 task 의 dev 탭을 보여준다
#   ports    이 task 의 포트와 실행될 명령을 보여준다 (herdr 밖에서도 됨)
#   watch-start  감시만 켠다 (이미 돌고 있으면 그대로). agent-dev.sh 가 부른다
#   watch    (up·watch-start 가 내부적으로 띄움) 포트 감시 루프
#
# env 로 바꿀 수 있다:
#   BE_PORT FE_PORT                          포트 표 대신 쓸 값 (dev-ports.sh 가 읽는다)
#   FE_TEST_CMD BE_TEST_CMD FE_SERVER_CMD BE_SERVER_CMD   명령 자체
# 예) BE_SERVER_CMD="PORT=5010 pnpm start:dev" ./herdr-dev.sh up
set -euo pipefail

base="$(cd "$(dirname "$0")" && pwd)"
fe="$base/frontend"
be="$base/backend"
name="$(basename "$base")"

die() { echo "$*" >&2; exit 1; }

# ---- 포트와 서버 명령: ../dev-ports.sh ----
def="$base/../dev-ports.sh"
[ -f "$def" ] || die "포트 정의가 없습니다: $def (branch-base 가 monask-fullstack 바로 아래에 있어야 합니다)"
# shellcheck source=/dev/null
source "$def"
dev_ports "$base"                        # task be_port fe_port port_note be_server_cmd fe_server_cmd
prefix="${HERDR_DEV_PREFIX:-dev:}"      # 탭 label 접두사
label="${prefix}${task}"

FE_TEST_CMD="${FE_TEST_CMD:-pnpm test:unit:watch}"
BE_TEST_CMD="${BE_TEST_CMD:-pnpm test:unit:watch}"
FE_SERVER_CMD="$fe_server_cmd"
BE_SERVER_CMD="$be_server_cmd"

cmd_ports() {
  echo "$task  ${port_note:-}"
  echo "  frontend  http://localhost:$fe_port"
  echo "  backend   http://localhost:$be_port"
  printf '  %-10s %s\n' "fe test"   "$FE_TEST_CMD"
  printf '  %-10s %s\n' "be test"   "$BE_TEST_CMD"
  printf '  %-10s %s\n' "fe server" "$FE_SERVER_CMD"
  printf '  %-10s %s\n' "be server" "$BE_SERVER_CMD"
}

if [ "${1:-}" = ports ]; then cmd_ports; exit 0; fi

[ "${HERDR_ENV:-}" = 1 ] || die "herdr 안의 터미널에서 실행해야 합니다 (HERDR_ENV=1 이 아님)"
command -v herdr >/dev/null || die "herdr CLI 가 없습니다"
command -v jq >/dev/null || die "jq 가 없습니다"
[ -d "$fe" ] || die "frontend 폴더가 없습니다: $fe"
[ -d "$be" ] || die "backend 폴더가 없습니다: $be"

# branch-base 이름과 같은 label 의 workspace, 없으면 현재 workspace
ws="$(herdr workspace list \
  | jq -r --arg n "$name" '.result.workspaces[] | select(.label == $n) | .workspace_id' | head -1)"
[ -n "$ws" ] || ws="${HERDR_WORKSPACE_ID:-}"
[ -n "$ws" ] || die "workspace 를 찾지 못했습니다"

# 이 task 의 dev 탭 id (없으면 빈 문자열)
find_tab() {
  herdr tab list --workspace "$ws" \
    | jq -r --arg l "$label" '.result.tabs[] | select(.label == $l) | .tab_id' | head -1
}

# 다른 task 의 dev 탭: "workspace_id<TAB>tab_id<TAB>label" 한 줄씩
other_dev_tabs() {
  herdr tab list \
    | jq -r --arg p "$prefix" --arg l "$label" \
      '.result.tabs[] | select((.label | startswith($p)) and .label != $l) | [.workspace_id, .tab_id, .label] | @tsv'
}

tab_panes() {  # $1: tab_id → pane_id 목록
  herdr pane list --workspace "$ws" \
    | jq -r --arg t "$1" '.result.panes[] | select(.tab_id == $t) | .pane_id'
}

# 셸이 foreground 면 (아무것도 실행 중이 아니면) 0
at_prompt() {
  herdr pane process-info --pane "$1" \
    | jq -e '.result.process_info | .foreground_process_group_id == .shell_pid' >/dev/null
}

# $1: pane_id, $2: 최대 대기 초
wait_prompt() {
  local i
  for ((i = 0; i < $2 * 5; i++)); do
    at_prompt "$1" 2>/dev/null && return 0
    sleep 0.2
  done
  return 1
}

# 프롬프트가 실제로 그려질 때까지 기다린다: 셸이 foreground 이고, 화면이 비어 있지 않고,
# 0.2초 전과 같아야 한다. 새 탭의 zsh 는 rc 를 읽는 동안 들어온 입력을 버리므로
# process-info 만으로는 이르다. $1: pane_id, $2: 최대 대기 초
wait_ready() {
  local i prev="" cur
  for ((i = 0; i < $2 * 5; i++)); do
    if at_prompt "$1" 2>/dev/null; then
      cur="$(herdr pane read "$1" --source visible 2>/dev/null | sed '/^[[:space:]]*$/d' | tail -1)"
      [ -n "$cur" ] && [ "$cur" = "$prev" ] && return 0
      prev="$cur"
    fi
    sleep 0.2
  done
  return 1
}

# 명령이 foreground 로 올라올 때까지 기다린다. $1: pane_id, $2: 최대 대기 초
wait_running() {
  local i
  for ((i = 0; i < $2 * 5; i++)); do
    at_prompt "$1" 2>/dev/null || return 0
    sleep 0.2
  done
  return 1
}

# pane 에서 사용자가 친 최상위 명령 (경로는 basename 으로 줄임)
fg_cmd() {
  herdr pane process-info --pane "$1" | jq -r '
    (.result.process_info.foreground_processes | last // {}) | .argv // []
    | map(if startswith("/") then (split("/") | last) else . end) | join(" ")'
}

# $1: pane_id, $2: label, $3: command
# 명령은 오래 도는 것(watch, server)을 전제로 한다. 보낸 뒤 foreground 가 바뀌지 않으면
# 입력이 버려진 것으로 보고 한 번 더 보낸다.
launch() {
  local try
  herdr pane rename "$1" "$2" >/dev/null
  wait_ready "$1" 15 || echo "  경고: $1 ($2) 프롬프트를 기다리다 넘어갑니다" >&2
  for try in 1 2; do
    herdr pane run "$1" "$3" >/dev/null
    wait_running "$1" 3 && break
    if [ "$try" = 1 ]; then
      echo "  $2: 명령이 시작되지 않아 다시 보냅니다" >&2
      herdr pane send-keys "$1" ctrl+u >/dev/null
    else
      echo "  경고: $2 ($1) 명령이 시작되지 않았습니다. 직접 확인하세요" >&2
    fi
  done
  printf '  %-10s %-8s %s\n' "$2" "$1" "$3"
}

# ---- 사이드바 서버 표시 (workspace 토큰 $fe, $be) ----
pidfile="$base/.herdr-dev.watch.pid"
self="$base/$(basename "$0")"

port_of() { if [ "$1" = be ]; then echo "$be_port"; else echo "$fe_port"; fi; }

# $1: be|fe → 포트를 잡은 쪽
#   agent  agent-dev.sh 가 띄운 서버 (listener 의 process group 이 ./.agent-dev/<be|fe>.pid 와 같다)
#   user   herdr 탭이나 사람이 띄운 이 task 서버 (listener 가 이 task 폴더 안에서 돈다)
#   빈 문자열  꺼짐, 또는 같은 포트를 쓰는 다른 폴더의 서버 (표에 없는 폴더는 _base 와 같은 포트를 쓴다)
port_owner() {
  local pid pg
  pid="$(port_pid "$(port_of "$1")")"
  [ -n "$pid" ] || return 0
  pg="$(cat "$base/.agent-dev/$1.pid" 2>/dev/null || true)"
  if [ -n "$pg" ] && [ "$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')" = "$pg" ]; then echo agent; return 0; fi
  case "$(pid_cwd "$pid")/" in "$base"/*) echo user ;; esac
}

# agent-dev.sh 가 띄운 서버 process group 이 살아 있으면 0 (포트를 열기 전 기동 중일 때도)
agent_alive() {
  local s pg
  for s in be fe; do
    pg="$(cat "$base/.agent-dev/$s.pid" 2>/dev/null)" || continue
    [ -n "$pg" ] && kill -0 -- "-$pg" 2>/dev/null && return 0
  done
  return 1
}

# 사이드바에 보여 줄 이 task 의 서버가 있거나 곧 생기면 0
servers_alive() {
  agent_alive || [ -n "$(port_owner be)" ] || [ -n "$(port_owner fe)" ]
}

# 열린 포트만 띄운 쪽의 토큰으로 보고하고, 나머지 토큰은 지운다. ttl 이 있어 감시가 죽으면 사라진다.
# 띄운 쪽 이모지(사람·herdr 탭 🧑, agent-dev 🤖)는 그쪽의 첫 토큰에만 붙인다.
# 기본 사이드바 폭(26칸)에서 이 줄은 20칸이다. 이모지가 2칸이라 콜론 앞 공백을 빼야 "🤖 fe:3011 · be:5010" 이
# 딱 맞는다. 사람과 agent 가 섞이면 이모지 둘로 23칸이 되므로 🧑 는 빼고 🤖 만 붙인다 (색으로도 구분된다).
# 넘치면 herdr 가 토큰을 번갈아 줄여 포트가 안 보인다
report_servers() {
  local args=() s owner fe_owner be_owner hum="🧑 " bot="🤖 "
  fe_owner="$(port_owner fe)"
  be_owner="$(port_owner be)"
  if [ "$fe_owner" = agent ] || [ "$be_owner" = agent ]; then hum=""; fi
  for s in fe be; do
    if [ "$s" = fe ]; then owner="$fe_owner"; else owner="$be_owner"; fi
    case "$owner" in
      user)  args+=(--token "$s=$hum$s:$(port_of "$s")" --clear-token "${s}_agent"); hum="" ;;
      agent) args+=(--token "${s}_agent=$bot$s:$(port_of "$s")" --clear-token "$s"); bot="" ;;
      *)     args+=(--clear-token "$s" --clear-token "${s}_agent") ;;
    esac
  done
  herdr workspace report-metadata "$ws" --source herdr-dev --ttl-ms 15000 "${args[@]}" >/dev/null
}

clear_servers() {
  herdr workspace report-metadata "$ws" --source herdr-dev \
    --clear-token fe --clear-token be --clear-token fe_agent --clear-token be_agent >/dev/null 2>&1 || true
}

watch_pid() {  # 살아 있는 감시 pid, 없으면 빈 문자열
  local pid
  [ -f "$pidfile" ] || return 0
  pid="$(cat "$pidfile" 2>/dev/null)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then echo "$pid"; else rm -f "$pidfile"; fi
}

start_watch() {
  local pid
  pid="$(watch_pid)"
  if [ -n "$pid" ]; then echo "  감시 실행 중 (pid $pid)"; return 0; fi
  # 자기 process group 으로 띄운다. agent 의 셸 도구가 명령을 끝내며 process group 을 정리해도 살아남게
  set -m
  nohup "$self" watch >/dev/null 2>&1 < /dev/null &
  pid=$!
  set +m
  disown 2>/dev/null || true
  echo "$pid" > "$pidfile"   # 감시도 시작하며 쓰지만, 그 전에 다시 불려도 하나만 뜨게 바로 적는다
  echo "  감시 시작 (pid $pid): 열린 서버 포트를 사이드바에 표시"
}

stop_watch() {
  local pid
  pid="$(watch_pid)"
  if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; rm -f "$pidfile"; echo "  감시 종료 (pid $pid)"; fi
  clear_servers
}

# 탭을 내린 뒤: agent-dev.sh 등 탭 밖에서 띄운 이 task 의 서버가 남아 있으면 감시를 켜 둔다
finish_watch() {
  if servers_alive; then
    echo "  이 task 의 서버가 아직 떠 있어 (agent-dev 등) 사이드바 감시를 유지합니다"
    start_watch
  else
    stop_watch
  fi
}

# up·watch-start 가 백그라운드로 띄우는 루프. dev 탭도 이 task 의 서버도 3번 연속(15초) 없거나,
# herdr 가 계속 응답하지 않으면 토큰을 지우고 끝난다. 연속 3번은 restart 의 down~up 사이를 넘기려는 것이다
cmd_watch() {
  local fails=0 idle=0
  echo $$ > "$pidfile"
  trap 'clear_servers; rm -f "$pidfile"; exit 0' INT TERM
  while :; do
    if report_servers 2>/dev/null; then fails=0; else fails=$((fails + 1)); fi
    [ "$fails" -ge 5 ] && break
    if [ -n "$(find_tab 2>/dev/null)" ] || servers_alive; then idle=0; else idle=$((idle + 1)); fi
    [ "$idle" -ge 3 ] && break
    sleep 5
  done
  clear_servers
  rm -f "$pidfile"
}

print_other_tabs() {
  local others
  others="$(other_dev_tabs)"
  [ -n "$others" ] || return 0
  echo "다른 task 의 dev 탭:"
  printf '%s\n' "$others" | awk -F'\t' '{ printf "  %s (%s, workspace %s)\n", $3, $2, $1 }'
}

cmd_up() {
  local tab
  tab="$(find_tab)"
  if [ -n "$tab" ]; then
    echo "이미 있습니다: $label ($tab). 다시 띄우려면 restart"
    start_watch
    return 0
  fi
  # 서버는 task 당 한 벌이다. agent-dev.sh 등 탭 밖에서 띄운 서버가 포트를 잡고 있으면 탭을 만들지 않는다
  local port pid busy=0
  for port in "$be_port" "$fe_port"; do
    pid="$(port_pid "$port")"
    [ -n "$pid" ] || continue
    echo ":$port 가 이미 열려 있습니다 (pid $pid, $(pid_cwd "$pid"))" >&2
    busy=1
  done
  if [ "$busy" = 1 ]; then
    [ -d "$base/.agent-dev" ] && echo "agent-dev.sh 가 띄운 서버면 ./agent-dev.sh down 뒤 다시 실행하세요" >&2
    return 1
  fi
  echo "workspace $ws 에 $label 탭을 만듭니다  ${port_note:-}"
  local out p_fe_test p_be_test p_fe_srv p_be_srv
  out="$(herdr tab create --workspace "$ws" --cwd "$fe" --label "$label" --no-focus)"
  tab="$(jq -r '.result.tab.tab_id' <<<"$out")"
  p_fe_test="$(jq -r '.result.root_pane.pane_id' <<<"$out")"
  p_be_test="$(herdr pane split "$p_fe_test" --direction right --cwd "$be" --no-focus | jq -r '.result.pane.pane_id')"
  p_fe_srv="$(herdr pane split "$p_fe_test" --direction down --cwd "$fe" --no-focus | jq -r '.result.pane.pane_id')"
  p_be_srv="$(herdr pane split "$p_be_test" --direction down --cwd "$be" --no-focus | jq -r '.result.pane.pane_id')"
  launch "$p_fe_test" "fe test"   "$FE_TEST_CMD"
  launch "$p_be_test" "be test"   "$BE_TEST_CMD"
  launch "$p_fe_srv"  "fe server" "$FE_SERVER_CMD"
  launch "$p_be_srv"  "be server" "$BE_SERVER_CMD"
  echo "완료: $tab   frontend http://localhost:$fe_port → backend http://localhost:$be_port"
  start_watch
}

cmd_down() {
  local tab panes p
  tab="$(find_tab)"
  if [ -z "$tab" ]; then
    echo "$label 탭이 없습니다"
    finish_watch
    return 0
  fi
  panes="$(tab_panes "$tab")"
  echo "$label ($tab) 프로세스를 끝냅니다"
  for p in $panes; do
    at_prompt "$p" && continue
    printf '  ctrl+c → %s  %s\n' "$p" "$(fg_cmd "$p")"
    herdr pane send-keys "$p" ctrl+c >/dev/null
  done
  for p in $panes; do
    wait_prompt "$p" 10 && continue
    echo "  아직 실행 중, 한 번 더 ctrl+c: $p  $(fg_cmd "$p")"
    herdr pane send-keys "$p" ctrl+c >/dev/null
    wait_prompt "$p" 5 || echo "  경고: $p 가 끝나지 않아 탭을 닫으며 강제 종료합니다" >&2
  done
  herdr tab close "$tab" >/dev/null
  echo "탭을 닫았습니다: $label ($tab)"
  finish_watch
}

cmd_status() {
  local tab rc=0
  tab="$(find_tab)"
  if [ -z "$tab" ]; then
    echo "$label 탭이 없습니다 (workspace $ws)"
    rc=1
  else
    echo "$label ($tab, workspace $ws)   frontend :$fe_port → backend :$be_port"
    herdr pane list --workspace "$ws" \
      | jq -r --arg t "$tab" '.result.panes[] | select(.tab_id == $t) | [.pane_id, (.label // "-")] | @tsv' \
      | while IFS=$'\t' read -r p l; do
          printf '  %-8s %-10s %s\n' "$p" "$l" "$(fg_cmd "$p")"
        done
  fi
  # 탭이 없어도 agent-dev.sh 가 띄운 서버와 그 감시가 있을 수 있어 늘 보여준다
  local pid s open=() agent_up=0
  for s in fe be; do
    case "$(port_owner "$s")" in
      user)  open+=("$s :$(port_of "$s") (herdr 탭·사람)") ;;
      agent) open+=("$s :$(port_of "$s") (agent)"); agent_up=1 ;;
    esac
  done
  [ "$agent_up" = 0 ] && agent_alive && open+=("(agent-dev 서버 기동 중)")
  pid="$(watch_pid)"
  if [ -n "$pid" ]; then pid="pid $pid"; else pid="꺼짐 (herdr-dev.sh up 이나 agent-dev.sh up 이 켠다)"; fi
  echo "  열린 서버: ${open[*]:-(없음)}   사이드바 감시: $pid"
  [ "${HERDR_DEV_NO_OTHERS:-}" = 1 ] || print_other_tabs   # herdr-dev-all.sh 는 폴더마다 반복되므로 끈다
  return $rc
}

case "${1:-}" in
  up)      cmd_up ;;
  down)    cmd_down ;;
  restart) cmd_down; cmd_up ;;
  status)  cmd_status ;;
  watch-start) start_watch ;;
  watch)   cmd_watch ;;
  *)       awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 2 ;;
esac
