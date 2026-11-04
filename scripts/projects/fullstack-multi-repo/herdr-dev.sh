#!/bin/bash
# herdr 에 dev 탭을 만들어 frontend/backend 의 test watch 와 server 를 2x2 로 띄우고, 그 아래 전체 폭의
# check pane 에서 바뀐 .ts/.tsx 만 eslint·tsc 한다. 내릴 때는 다섯 pane 을 모두 끝낸다.
#
#   ┌───────────────────────┬───────────────────────┐
#   │ fe test               │ be test               │
#   │ pnpm test:unit:watch  │ pnpm test:unit:watch  │
#   ├───────────────────────┼───────────────────────┤
#   │ fe server             │ be server             │
#   │ pnpm main --port FE   │ PORT=BE pnpm start    │
#   ├───────────────────────┴───────────────────────┤
#   │ check                                         │
#   │ ./herdr-dev.sh check                          │
#   └───────────────────────────────────────────────┘
#
# check 높이: herdr 는 2x2 가 75%, check 가 25% 다. Herdr 앱은 분할 비율을 받지 않고 늘 반으로 나누므로
# test 행 50%, server 행 25%, check 25% 가 된다 (check 를 낮게 두려고 행부터 나눈다).
# test watch(vitest·jest)와 server(vite·nest swc)는 변환만 해서 lint 도 type 검사도 하지 않는다. check 가 그 몫이다.
#
# herdr 두 가지에서 쓴다. 실행한 터미널의 환경 변수로 고른다.
#   herdr (터미널 멀티플렉서)    HERDR_ENV=1      herdr workspace·tab·pane CLI
#   Herdr 앱 (herdr-core 기반)   HC_TERMINAL_ID   herdr-app do 로 탭·분할을 만들고 hc 로 명령을 보낸다
#
# 이 스크립트는 branch-base(backend/, frontend/ 가 나란히 있는 폴더)에 두고 쓴다.
# 스크립트 위치 기준으로 ./frontend, ./backend 를 쓴다. branch-base 는 monask-fullstack 바로 아래에 있어야 한다.
# 탭은 branch-base 폴더 이름과 이름이 같은 herdr workspace(앱은 space)에 만들고, 없으면 지금 터미널이 있는 곳에 만든다.
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
# Herdr 앱에는 사이드바 토큰이 없어서, 감시가 같은 내용을 ~/.local/state/herdr-dev/<폴더 경로>.json 에 쓴다
# (space id, 포트, 띄운 쪽, 15초 뒤 만료). Herdr 앱 사이드바 mod 가 같은 ports.js 로 읽어 space 줄 아래에 보여준다:
# main-dev layout 이 쓰는 ~/.config/herdr-app/mods/better-spaces 와 그 대체용 spaces-dev (둘 다 tkhwang-herdr-mods 저장소).
# 이 JSON 의 필드를 바꾸면 tkhwang-herdr-mods 의 ports.js 도 같이 고쳐야 한다.
#
# usage: ./herdr-dev.sh up|down|restart|status|ports|check|watch-start
#   up       dev 탭을 만들고 각 pane 에 명령을 실행한다 (이미 있으면 감시만 확인한다)
#   down     각 pane 에 ctrl+c 를 보내 끝낸 뒤 탭을 닫는다. 탭 밖에서 띄운 서버가 남아 있지 않으면 감시도 멈춘다
#   restart  down 뒤 up
#   status   이 task 의 dev 탭 pane, 열린 포트, 감시 상태, 다른 task 의 dev 탭을 보여준다
#   ports    이 task 의 포트와 실행될 명령을 보여준다 (herdr 밖에서도 됨)
#   check    바뀐 .ts/.tsx 만 eslint·tsc 하는 반복문. check pane 이 돌린다 (herdr 밖에서도 됨, ctrl+c 로 끝)
#            check --once: 한 번 검사해 결과를 다 보여주고 끝난다. error 가 있으면 exit 1
#   watch-start  감시만 켠다 (이미 돌고 있으면 그대로). agent-dev.sh 가 부른다
#   watch    (up·watch-start 가 내부적으로 띄움) 포트 감시 루프
#
# env 로 바꿀 수 있다:
#   BE_PORT FE_PORT                          포트 표 대신 쓸 값 (dev-ports.sh 가 읽는다)
#   FE_TEST_CMD BE_TEST_CMD FE_SERVER_CMD BE_SERVER_CMD   명령 자체
#   HERDR_DEV_NO_CHECK=1                     check pane 을 만들지 않는다 (2x2 만)
#   HERDR_DEV_CHECK_SINCE=<ref>              check 대상에 그 커밋 이후 커밋된 파일도 넣는다 (예: HEAD~1, origin/develop)
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
check_cmd="./herdr-dev.sh check"
if [ "${HERDR_DEV_NO_CHECK:-}" = 1 ]; then with_check=0; else with_check=1; fi

cmd_ports() {
  echo "$task  ${port_note:-}"
  echo "  frontend  http://localhost:$fe_port"
  echo "  backend   http://localhost:$be_port"
  printf '  %-10s %s\n' "fe test"   "$FE_TEST_CMD"
  printf '  %-10s %s\n' "be test"   "$BE_TEST_CMD"
  printf '  %-10s %s\n' "fe server" "$FE_SERVER_CMD"
  printf '  %-10s %s\n' "be server" "$BE_SERVER_CMD"
  if [ "$with_check" = 1 ]; then
    printf '  %-10s %s   (바뀐 .ts/.tsx 만 eslint·tsc%s)\n' check "$check_cmd" \
      "${HERDR_DEV_CHECK_SINCE:+, $HERDR_DEV_CHECK_SINCE 이후 커밋 포함}"
  else
    printf '  %-10s %s\n' check "(꺼짐: HERDR_DEV_NO_CHECK=1)"
  fi
}

# ---- check: 바뀐 .ts/.tsx 만 eslint·tsc ----
# check pane 이 돌리는 반복문이다. 저장소 전체는 검사하지 않는다: backend eslint 는 메모리가 모자라 멈추고,
# 원래 있던 error(fe tsc 13·be tsc 191·fe eslint 108 개)에 새 문제가 묻힌다.
#   대상    저장소마다 git status 에 나오는(staged·unstaged·untracked) .ts/.tsx 중 있는 파일.
#           monask-fullstack/verify-touched.sh 와 같은 기준이다. HERDR_DEV_CHECK_SINCE 면 그 커밋 이후 것도 넣는다
#   eslint  그 파일만
#   tsc     프로젝트 전체를 돌리고 그 파일의 error 만 이어지는 줄과 함께 남긴다. 전체 error 수도 보여준다
# 2초마다 HEAD, 바뀐 파일 목록, 각 파일의 수정 시각을 보고, 달라진 뒤 한 번 더(2초) 그대로면 다시 검사한다
# (저장이 몰릴 때 한 번만 돌게). 검사 중 바뀐 것은 끝난 뒤 다시 돈다. frontend 와 backend 는 따로 돌아
# fe(10초 남짓) 결과가 be(1분 가까이)를 기다리지 않는다. 검사는 nice 로 낮춰 server·test watch 를 덜 방해한다.
# 파일 목록은 임시 파일과 xargs -0 으로 넘긴다 (verify-touched.sh 처럼 변수 word-split 에 기대지 않는다).
check_interval=2
check_repos=(fe be)

check_dir() { if [ "$1" = be ]; then echo "$be"; else echo "$fe"; fi; }

# $1: 저장소 폴더 → 바뀐 .ts/.tsx 중 있는 파일을 저장소 기준 상대 경로로 한 줄씩 낸다.
# 몇 초마다 부르므로 --no-optional-locks 로 index.lock 을 잡지 않는다 (사람의 commit 등과 부딪히지 않게).
# untracked 는 normal 로 받고 새 폴더만 따로 펼친다. -uall 과 결과가 같고 backend 에서 160ms → 50ms 다
changed_files() {
  local d="$1"
  {
    git -C "$d" --no-optional-locks -c core.quotePath=false status --porcelain --untracked-files=normal
    if [ -n "${HERDR_DEV_CHECK_SINCE:-}" ]; then
      git -C "$d" --no-optional-locks -c core.quotePath=false diff --name-only "$HERDR_DEV_CHECK_SINCE" -- \
        | sed 's/^/M  /'
    fi
  } 2>/dev/null | while IFS= read -r line; do
      p="${line:3}"; p="${p##* -> }"; p="${p#\"}"; p="${p%\"}"
      case "$p" in
        */) [ "${line:0:2}" != '??' ] || git -C "$d" --no-optional-locks -c core.quotePath=false \
              ls-files --others --exclude-standard -- "$p" 2>/dev/null ;;
        *)  printf '%s\n' "$p" ;;
      esac
    done | grep -E '\.tsx?$' | sort -u \
    | while IFS= read -r p; do if [ -f "$d/$p" ]; then printf '%s\n' "$p"; fi; done
  return 0
}

# $1: fe|be → 다시 검사할지 정하는 서명. 바뀐 파일 목록은 $cstate/<fe|be>.cur 에 남긴다
check_sig() {
  local d o
  d="$(check_dir "$1")"; o="$cstate/$1"
  changed_files "$d" > "$o.cur"
  git -C "$d" rev-parse HEAD 2>/dev/null
  (cd "$d" && tr '\n' '\0' < "$o.cur" | xargs -0 stat -f '%m %N') 2>/dev/null
  return 0
}

# tsc 출력에서 바뀐 파일의 error 만 이어지는 줄과 함께 남긴다. $1: 바뀐 파일 목록, $2: tsc exit. stdin: tsc 출력
# 첫 줄 "ok <바뀐 파일 error> <전체 error>" (돌지 못했으면 "fail <exit>" 와 마지막 출력 몇 줄), 다음 줄부터 문제 줄.
# tsc 는 "path(line,col): error TSxxxx: msg" 를 내고, path 는 저장소 기준이다. 위치 없는 "error TSxxxx" (설정 문제)는 늘 남긴다
tsc_filter() {
  awk -v list="$1" -v rc="$2" '
    BEGIN { while ((getline l < list) > 0) want[l] = 1 }
    NF && !/^\[WARN\]/ { last[++nl] = $0 }
    substr($0, 1, 1) != " " && match($0, /\([0-9]+,[0-9]+\): error TS[0-9]+: /) {
      total++
      f = substr($0, 1, RSTART - 1); loc = substr($0, RSTART, RLENGTH); msg = substr($0, RSTART + RLENGTH)
      keep = (f in want)
      if (keep) {
        n++
        split(loc, a, /[(,]/)
        match(loc, /TS[0-9]+/)
        out[++k] = "E\t" f ":" a[2] "\t" substr(loc, RSTART, RLENGTH) "\t" msg
      }
      next
    }
    /^error TS[0-9]+: / {
      total++; n++; keep = 1
      match($0, /TS[0-9]+/); out[++k] = "E\ttsconfig\t" substr($0, RSTART, RLENGTH) "\t" substr($0, RSTART + RLENGTH + 2)
      next
    }
    /^ / { if (keep) out[++k] = "+\t" $0; next }
    { keep = 0 }
    END {
      if (total == 0 && rc != 0) {
        print "fail " rc
        for (i = (nl > 3 ? nl - 2 : 1); i <= nl; i++) print "+\t" last[i]
        exit
      }
      print "ok " n + 0 " " total + 0
      for (i = 1; i <= k; i++) print out[i]
    }'
}

# eslint JSON 을 줄로 바꾼다. $1: JSON, $2: 저장소 폴더. 첫 줄 "ok <error> <warning>", 다음 줄부터 error 먼저
eslint_lines() {
  jq -r --arg root "$2/" --arg rootp "$(cd "$2" && pwd -P)/" '
    def rel: ltrimstr($rootp) | ltrimstr($root);
    "ok \(map(.errorCount) | add // 0) \(map(.warningCount) | add // 0)",
    ([ .[] | (.filePath | rel) as $f | .messages[]
       | {f: $f, l: (.line // 0), s: .severity,
          r: (.ruleId // (if .fatal then "parse" else "-" end)),
          m: (.message | gsub("\\s*\\n\\s*|\\t"; " "))} ]
     | sort_by(-.s, .f, .l)[]
     | "\(if .s == 2 then "E" else "W" end)\t\(.f):\(.l)\t\(.r)\t\(.m)")' "$1"
}

# 저장소 하나를 검사한다. 반복문이 자기 process group 으로 띄우고, 끝낼 때 그룹째 죽인다. $1: fe|be
# $cstate/<fe|be>.list 를 검사해 같은 이름으로 시작하는 파일에 쓴다. 단계마다 mv 로 바꿔 끼워서 화면은
# 검사 중에도 지난 결과를 보여준다
#   .phase  지금 단계 (tsc | eslint)
#   .tsc .eslint  첫 줄 요약, 다음 줄부터 문제 줄. 탭으로 나눈 "E|W  file:line  규칙  메시지",
#                 또는 "+  앞 줄에 이어지는 줄" (경로에 공백이 있어도 칸이 어긋나지 않게 탭으로 나눈다)
#   .end    끝난 시각과 걸린 초
check_job() {
  local r="$1" d o t0 rc
  d="$(check_dir "$r")"; o="$cstate/$r"; t0="$(date +%s)"
  cd "$d" || exit 1
  echo tsc > "$o.phase"
  if [ "$r" = fe ]; then   # package.json 의 tsc:main 과 같다
    NODE_OPTIONS='--max-old-space-size=4096' nice -n 10 pnpm exec tsc --noEmit -p apps/main-web/tsconfig.app.json
  else                     # verify-touched.sh 와 같다
    nice -n 10 pnpm exec tsc --noEmit -p tsconfig.build.json
  fi > "$o.tsc.raw" 2>&1
  rc=$?
  tsc_filter "$o.list" "$rc" < "$o.tsc.raw" > "$o.tsc.tmp" && mv -f "$o.tsc.tmp" "$o.tsc"
  echo eslint > "$o.phase"
  rm -f "$o.eslint.json"
  tr '\n' '\0' < "$o.list" \
    | xargs -0 nice -n 10 pnpm exec eslint --no-warn-ignored -f json -o "$o.eslint.json" > "$o.eslint.raw" 2>&1
  # 결과 JSON 이 없거나 읽지 못하면 eslint 자체가 실패한 것이다 (설정 오류, 메모리 등)
  if [ -s "$o.eslint.json" ] && eslint_lines "$o.eslint.json" "$d" > "$o.eslint.tmp" 2>/dev/null; then :; else
    { echo fail; grep -v '^\[WARN\]' "$o.eslint.raw" | sed '/^[[:space:]]*$/d' | tail -3 | sed $'s/^/+\t/'; } > "$o.eslint.tmp"
  fi
  mv -f "$o.eslint.tmp" "$o.eslint"
  echo "$(date +%H:%M:%S) $(( $(date +%s) - t0 ))" > "$o.end"
  rm -f "$o.phase"
}

# 반복문 상태 (check_stop 이 trap 에서 읽으므로 전역): 저장소 순서는 check_repos 와 같다
check_pids=("" "")     # 검사 중인 job pid (= process group)
check_t0=(0 0)         # 검사 시작 시각
run_sig=("" "")        # 검사 중이거나 마지막으로 검사한 서명
done_sig=(- -)         # 결과가 나온 서명. - 는 아직 한 번도 안 돈 것
prev_sig=("" "")       # 지난번 확인 때 서명
cur_sig=("" "")        # 이번 확인 때 서명

# $1: 저장소 순번, $2: 서명
check_start() {
  local i="$1" o="$cstate/${check_repos[$1]}"
  run_sig[$i]="$2"
  if [ ! -s "$o.cur" ]; then        # 바뀐 파일이 없으면 돌리지 않고 지난 결과를 지운다
    rm -f "$o.tsc" "$o.eslint" "$o.end"
    done_sig[$i]="$2"
    return 0
  fi
  cp "$o.cur" "$o.list"
  check_t0[$i]="$(date +%s)"
  set -m      # 자기 process group 으로: ctrl+c 를 받은 반복문이 그룹째(pnpm, node 까지) 끝낸다
  check_job "${check_repos[$i]}" > /dev/null 2>&1 < /dev/null &
  check_pids[$i]=$!
  set +m
}

# 검사 job 을 그룹째 끝내고 임시 폴더를 지운다. trap INT 뒤에 EXIT 로 한 번 더 불려도 한 번만 한다
check_stop() {
  local p
  [ -n "${cstate:-}" ] || return 0
  for p in "${check_pids[@]}"; do [ -z "$p" ] || kill -TERM -- "-$p" 2>/dev/null; done
  check_pids=("" "")
  rm -rf "$cstate"
  cstate=""
  [ "$check_once" = 1 ] || printf '\033[?7h\n'
}

# 저장소 한 줄 요약. $1: 순번, $2: 지금 (초)
check_summary() {
  local i="$1" r="${check_repos[$1]}" o n line s a b c at took ph
  o="$cstate/$r"
  n="$(wc -l < "$o.cur" 2>/dev/null | tr -d ' ')"
  line="$c_b$r$c_0"
  if [ "${n:-0}" = 0 ] && [ -z "${check_pids[$i]}" ]; then
    echo "$line  ${c_d}바뀐 .ts/.tsx 없음$c_0"
    return 0
  fi
  line="$line  ${n}개 파일"
  if [ -f "$o.eslint" ]; then
    read -r s a b < "$o.eslint"
    if [ "$s" != ok ]; then line="$line  ${c_r}eslint 실행 실패$c_0"
    else
      if [ "$a" -gt 0 ]; then c="$c_r"; elif [ "$b" -gt 0 ]; then c="$c_y"; else c="$c_g"; fi
      line="$line  ${c}eslint $a error / $b warning$c_0"
    fi
  else line="$line  ${c_d}eslint -$c_0"; fi
  if [ -f "$o.tsc" ]; then
    read -r s a b < "$o.tsc"
    if [ "$s" != ok ]; then line="$line  ${c_r}tsc 실행 실패 (exit $a)$c_0"
    else
      if [ "$a" -gt 0 ]; then c="$c_r"; else c="$c_g"; fi
      line="$line  ${c}tsc $a error$c_0 ${c_d}(전체 $b)$c_0"
    fi
  else line="$line  ${c_d}tsc -$c_0"; fi
  if [ -f "$o.end" ]; then read -r at took < "$o.end"; line="$line  ${c_d}$at · ${took}초$c_0"; fi
  if [ -n "${check_pids[$i]}" ]; then
    ph="$(cat "$o.phase" 2>/dev/null)"
    line="$line  ${c_c}검사 중 ${ph:+$ph }$(( $2 - check_t0[i] ))초$c_0"
    [ "${cur_sig[$i]}" = "${run_sig[$i]}" ] || line="$line ${c_d}· 끝나면 다시$c_0"
  fi
  echo "$line"
}

# 문제 줄: eslint error, tsc error(이어지는 줄 포함), eslint warning 순
check_view() {
  local o="$cstate/${check_repos[$1]}"
  [ ! -f "$o.eslint" ] || sed -n '2,$p' "$o.eslint" | grep -v '^W'
  [ ! -f "$o.tsc" ] || sed -n '2,$p' "$o.tsc"
  [ ! -f "$o.eslint" ] || sed -n '2,$p' "$o.eslint" | grep '^W'
  return 0
}

# $1: view 파일, $2: 보여줄 줄 수, $3: 전체 줄 수. 잘리면 마지막 줄 대신 남은 수를 보여준다
check_lines() {
  local show="$2"
  if [ "$2" -lt "$3" ] && [ "$2" -gt 0 ]; then show=$(( $2 - 1 )); fi
  [ "$show" -gt 0 ] || return 0
  head -n "$show" "$1" | awk -F '\t' -v red="$c_r" -v yel="$c_y" -v dim="$c_d" -v off="$c_0" '
    $1 == "+" { print dim "  " $2 off; next }
    { print "  " $2 "  " ($1 == "E" ? red : yel) $3 off "  " $4 }'
  if [ "$show" -lt "$3" ] && [ "$2" -gt 0 ]; then printf '  %s… %d줄 더%s\n' "$c_d" $(( $3 - show )) "$c_0"; fi
}

# 화면 한 장. 줄 수는 터미널 높이에 맞춘다 (--once 는 다 보여준다)
check_render() {
  local now rows=0 size i budget half nf nb take=()
  now="$(date +%s)"
  if [ "$check_once" != 1 ] && size="$(stty size < /dev/tty 2>/dev/null)"; then rows="${size% *}"; fi
  printf '%scheck%s  %s  %s  %s바뀐 .ts/.tsx 만 eslint·tsc%s%s%s\n' "$c_b" "$c_0" "$task" \
    "$(date +%H:%M:%S)" "$c_d" "${HERDR_DEV_CHECK_SINCE:+ ($HERDR_DEV_CHECK_SINCE 이후 커밋 포함)}" \
    "$( [ "$check_once" = 1 ] || echo " · ${check_interval}초마다 확인, ctrl+c 로 끝" )" "$c_0"
  for i in 0 1; do check_view "$i" > "$cstate/${check_repos[$i]}.view"; done
  nf="$(wc -l < "$cstate/fe.view" | tr -d ' ')"; nb="$(wc -l < "$cstate/be.view" | tr -d ' ')"
  # 문제 줄 몫: 머리 세 줄과 맨 아래 빈 줄을 뺀 높이. 한쪽이 덜 쓰면 남는 몫은 다른 쪽이 쓴다
  take=("$nf" "$nb")
  if [ "$rows" -gt 0 ] && [ $(( nf + nb )) -gt $(( rows - 4 )) ]; then
    budget=$(( rows - 4 )); [ "$budget" -ge 0 ] || budget=0
    half=$(( budget / 2 ))
    if [ "$nf" -le "$half" ]; then take=("$nf" $(( budget - nf )))
    elif [ "$nb" -le $(( budget - half )) ]; then take=($(( budget - nb )) "$nb")
    else take=("$half" $(( budget - half ))); fi
  fi
  check_summary 0 "$now"; check_lines "$cstate/fe.view" "${take[0]}" "$nf"
  check_summary 1 "$now"; check_lines "$cstate/be.view" "${take[1]}" "$nb"
}

# 화면을 맨 위부터 다시 그린다. 줄마다 끝을 지우고 아래를 지워 깜빡이지 않게 하고, 긴 줄은 줄바꿈 대신 자른다
check_draw() {
  printf '\033[?7l\033[H'
  printf '%s\n' "$1" | sed $'s/$/\033[K/'
  printf '\033[J\033[?7h'
}

# --once 로 끝날 때: 문제가 있으면 0
check_failed() {
  local f s a b
  for f in "$cstate"/fe.eslint "$cstate"/fe.tsc "$cstate"/be.eslint "$cstate"/be.tsc; do
    [ -f "$f" ] || continue
    read -r s a b < "$f"
    [ "$s" = ok ] || return 0
    [ "${a:-0}" -le 0 ] || return 0
  done
  return 1
}

cmd_check() {
  case "${1:-}" in
    "") check_once=0 ;;
    --once) check_once=1 ;;
    *) die "usage: $0 check [--once]" ;;
  esac
  [ -d "$fe" ] || die "frontend 폴더가 없습니다: $fe"
  [ -d "$be" ] || die "backend 폴더가 없습니다: $be"
  command -v jq >/dev/null || die "jq 가 없습니다"
  # 오래 도는 반복문이라 하나가 실패해도 멈추지 않게 한다. 실패는 화면에 보인다
  set +eu
  if [ -t 1 ]; then
    c_r=$'\033[31m' c_y=$'\033[33m' c_g=$'\033[32m' c_c=$'\033[36m' c_d=$'\033[2m' c_b=$'\033[1m' c_0=$'\033[0m'
  else
    c_r="" c_y="" c_g="" c_c="" c_d="" c_b="" c_0=""
  fi
  cstate="$(mktemp -d "${TMPDIR:-/tmp}/herdr-dev-check.XXXXXX")" || die "임시 폴더를 만들지 못했습니다"
  trap 'check_stop' EXIT
  trap 'check_stop; exit 130' INT
  trap 'check_stop; exit 143' TERM HUP
  local i sig frame last=""
  [ "$check_once" = 1 ] || printf '\033[H\033[2J'
  while :; do
    for i in 0 1; do
      sig="$(check_sig "${check_repos[$i]}")"
      cur_sig[$i]="$sig"
      if [ -n "${check_pids[$i]}" ]; then
        if kill -0 "${check_pids[$i]}" 2>/dev/null; then prev_sig[$i]="$sig"; continue; fi
        wait "${check_pids[$i]}" 2>/dev/null
        check_pids[$i]=""
        done_sig[$i]="${run_sig[$i]}"
      fi
      # 처음은 바로, 그 뒤로는 서명이 마지막 결과와 다르고 지난번 확인 때와 같을 때 (--once 는 처음 한 번만)
      if [ "${done_sig[$i]}" = - ] || { [ "$check_once" != 1 ] && [ "$sig" != "${done_sig[$i]}" ] \
        && [ "$sig" = "${prev_sig[$i]}" ]; }; then
        check_start "$i" "$sig"
      fi
      prev_sig[$i]="$sig"
    done
    if [ "$check_once" = 1 ]; then
      if [ -z "${check_pids[0]}${check_pids[1]}" ]; then
        check_render
        if check_failed; then exit 1; else exit 0; fi
      fi
      sleep 0.5
      continue
    fi
    frame="$(check_render)"
    if [ "$frame" != "$last" ]; then check_draw "$frame"; last="$frame"; fi
    sleep "$check_interval"
  done
}

case "${1:-}" in
  ports) cmd_ports; exit 0 ;;
  check) cmd_check "${2:-}"; exit $? ;;
esac

# herdr TUI 를 Herdr 앱 터미널 안에서 띄우면 두 변수가 다 있다. 그때는 herdr pane 안이므로 tui 가 먼저다
if [ "${HERDR_ENV:-}" = 1 ]; then
  mode=tui
  command -v herdr >/dev/null || die "herdr CLI 가 없습니다"
elif [ -n "${HC_TERMINAL_ID:-}" ]; then
  mode=app
  command -v herdr-app >/dev/null || die "herdr-app CLI 가 없습니다 (Herdr 앱)"
  command -v hc >/dev/null || die "hc CLI 가 없습니다 (herdr-core)"
else
  die "herdr 나 Herdr 앱 안의 터미널에서 실행해야 합니다 (HERDR_ENV=1 도 HC_TERMINAL_ID 도 없음)"
fi
command -v jq >/dev/null || die "jq 가 없습니다"
[ -d "$fe" ] || die "frontend 폴더가 없습니다: $fe"
[ -d "$be" ] || die "backend 폴더가 없습니다: $be"

# ---- herdr 별 동작 ----
# 아래 함수는 두 모드가 같은 이름으로 정의한다. pane 은 tui 에선 pane_id, app 에선 hc 터미널 주소(t7)다.
#   find_tab              이 task 의 dev 탭 id (없으면 빈 문자열)
#   other_dev_tabs        다른 task 의 dev 탭: "workspace<TAB>tab_id<TAB>label" 한 줄씩
#   tab_panes <tab>       탭의 pane 목록
#   at_prompt <pane>      셸이 foreground 면 (아무것도 실행 중이 아니면) 0
#   screen_last <pane>    화면의 마지막 비지 않은 줄
#   run_in <pane> <cmd>   명령을 입력하고 실행한다
#   press <pane> <key>    ctrl+c, ctrl+u 같은 키를 누른다
#   fg_cmd <pane>         pane 에서 사용자가 친 최상위 명령 (경로는 basename 으로 줄임)
#   name_pane <pane> <이름>
#   make_dev_tab          탭과 pane 을 만들어 tab p_fe_test p_be_test p_fe_srv p_be_srv p_check 를 채운다
#                         (HERDR_DEV_NO_CHECK=1 이면 p_check 는 빈 문자열)
#   close_tab <tab>
#   status_rows <tab>     pane 마다 "id 이름 명령" 한 줄
if [ "$mode" = tui ]; then
  ws_kind=workspace
  # branch-base 이름과 같은 label 의 workspace, 없으면 현재 workspace
  ws="$(herdr workspace list \
    | jq -r --arg n "$name" '.result.workspaces[] | select(.label == $n) | .workspace_id' | head -1)"
  [ -n "$ws" ] || ws="${HERDR_WORKSPACE_ID:-}"
  [ -n "$ws" ] || die "workspace 를 찾지 못했습니다"

  find_tab() {
    herdr tab list --workspace "$ws" \
      | jq -r --arg l "$label" '.result.tabs[] | select(.label == $l) | .tab_id' | head -1
  }

  other_dev_tabs() {
    herdr tab list \
      | jq -r --arg p "$prefix" --arg l "$label" \
        '.result.tabs[] | select((.label | startswith($p)) and .label != $l) | [.workspace_id, .tab_id, .label] | @tsv'
  }

  tab_panes() {
    herdr pane list --workspace "$ws" \
      | jq -r --arg t "$1" '.result.panes[] | select(.tab_id == $t) | .pane_id'
  }

  at_prompt() {
    herdr pane process-info --pane "$1" \
      | jq -e '.result.process_info | .foreground_process_group_id == .shell_pid' >/dev/null
  }

  screen_last() { herdr pane read "$1" --source visible 2>/dev/null | sed '/^[[:space:]]*$/d' | tail -1; }
  run_in() { herdr pane run "$1" "$2" >/dev/null; }
  press() { herdr pane send-keys "$1" "$2" >/dev/null; }

  fg_cmd() {
    herdr pane process-info --pane "$1" | jq -r '
      (.result.process_info.foreground_processes | last // {}) | .argv // []
      | map(if startswith("/") then (split("/") | last) else . end) | join(" ")'
  }

  name_pane() { herdr pane rename "$1" "$2" >/dev/null; }

  make_dev_tab() {
    local out
    out="$(herdr tab create --workspace "$ws" --cwd "$fe" --label "$label" --no-focus)"
    tab="$(jq -r '.result.tab.tab_id' <<<"$out")"
    p_fe_test="$(jq -r '.result.root_pane.pane_id' <<<"$out")"
    # check 가 전체 폭이 되게 root 를 먼저 아래로 나눈다. --ratio 는 위(원래 pane) 몫이다
    if [ "$with_check" = 1 ]; then
      p_check="$(herdr pane split "$p_fe_test" --direction down --ratio 0.75 --cwd "$base" --no-focus \
        | jq -r '.result.pane.pane_id')"
    fi
    p_be_test="$(herdr pane split "$p_fe_test" --direction right --cwd "$be" --no-focus | jq -r '.result.pane.pane_id')"
    p_fe_srv="$(herdr pane split "$p_fe_test" --direction down --cwd "$fe" --no-focus | jq -r '.result.pane.pane_id')"
    p_be_srv="$(herdr pane split "$p_be_test" --direction down --cwd "$be" --no-focus | jq -r '.result.pane.pane_id')"
  }

  close_tab() { herdr tab close "$1" >/dev/null; }

  status_rows() {
    herdr pane list --workspace "$ws" \
      | jq -r --arg t "$1" '.result.panes[] | select(.tab_id == $t) | [.pane_id, (.label // "-")] | @tsv' \
      | while IFS=$'\t' read -r p l; do
          printf '  %-8s %-10s %s\n' "$p" "$l" "$(fg_cmd "$p")"
        done
  }
else
  # Herdr 앱: 탭·분할은 창(herdr-app)이, 터미널은 herdr-core(hc)가 맡는다.
  # herdr-app ls 는 {"spaces":[{id,name,active,tabs:[{id,name,active,terminals:[{terminal,pane}]}]}]} 를 낸다
  ws_kind=space
  app_ls() { herdr-app ls; }

  # herdr-app do 를 부르고 결과 JSON 을 낸다. 실패하면 {"error": ...} 를 보여주고 멈춘다
  app_do() {
    local out
    if ! out="$(herdr-app do "$@" 2>&1)" || jq -e '.error? // empty' >/dev/null 2>&1 <<<"$out"; then
      die "herdr-app do $1 실패: $out"
    fi
    printf '%s\n' "$out"
  }

  apps="$(app_ls)" || die "Herdr 앱 창에 연결하지 못했습니다 (앱이 열려 있어야 합니다): $apps"
  # branch-base 이름과 같은 이름의 space, 없으면 이 터미널이 있는 space, 그것도 없으면 보고 있는 space
  ws="$(jq -r --arg n "$name" '[.spaces[] | select(.name == $n)][0].id // empty' <<<"$apps")"
  [ -n "$ws" ] || ws="$(jq -r --arg t "$HC_TERMINAL_ID" \
    '[.spaces[] | select(any(.tabs[].terminals[]; .terminal == $t))][0].id // empty' <<<"$apps")"
  [ -n "$ws" ] || ws="$(jq -r '[.spaces[] | select(.active)][0].id // empty' <<<"$apps")"
  [ -n "$ws" ] || die "Herdr 앱 space 를 찾지 못했습니다"

  find_tab() {
    app_ls | jq -r --arg s "$ws" --arg l "$label" \
      '[.spaces[] | select(.id == $s) | .tabs[] | select(.name == $l)][0].id // empty'
  }

  other_dev_tabs() {
    app_ls | jq -r --arg p "$prefix" --arg l "$label" \
      '.spaces[] | .name as $s | .tabs[] | select(((.name // "") | startswith($p)) and .name != $l) | [$s, .id, .name] | @tsv'
  }

  tab_panes() {
    app_ls | jq -r --arg t "$1" '.spaces[].tabs[] | select(.id == $t) | .terminals[].terminal'
  }

  term_pid() { hc get "$1" --json | jq -r '.pid // empty'; }

  at_prompt() {
    local pid
    pid="$(term_pid "$1")"
    [ -n "$pid" ] && [ "$(ps -o tpgid= -p "$pid" | tr -d ' ')" = "$pid" ]
  }

  screen_last() { hc read "$1" 2>/dev/null | sed '/^[[:space:]]*$/d' | tail -1; }
  run_in() { hc send "$1" "$2" >/dev/null; }
  press() { hc keys "$1" "$2" >/dev/null; }

  # 터미널의 foreground process group 리더의 명령
  fg_cmd() {
    local pid tp tty
    pid="$(term_pid "$1" 2>/dev/null)" || return 0
    [ -n "$pid" ] || return 0
    tp="$(ps -o tpgid= -p "$pid" 2>/dev/null | tr -d ' ')" || return 0
    [ -n "$tp" ] && [ "$tp" != "$pid" ] || return 0
    tty="$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')" || return 0
    ps -t "$tty" -o pgid=,args= 2>/dev/null | awk -v g="$tp" '
      $1 == g { $1 = ""; for (i = 2; i <= NF; i++) if ($i ~ /^\//) { n = split($i, a, "/"); $i = a[n] }
                sub(/^ +/, ""); print; exit }' || true
  }

  # 앱에는 pane 이름 바꾸기가 없어서 hc 라벨로 남긴다 (status 가 읽는다)
  name_pane() { hc label "$1" "herdr-dev.role=$2" >/dev/null; }

  make_dev_tab() {
    local out orig_space orig_tab p_root p_right p_mid
    # tab.new 는 새 탭을 바로 보여준다. herdr 의 --no-focus 처럼, 다 만들면 보던 곳으로 돌아간다
    out="$(app_ls)"
    orig_space="$(jq -r '[.spaces[] | select(.active)][0].id // empty' <<<"$out")"
    orig_tab="$(jq -r '[.spaces[] | select(.active) | .tabs[] | select(.active)][0].id // empty' <<<"$out")"
    # tab.new 는 {space, tab, terminal} 만 준다. pane id 는 ls 에서 터미널 주소로 찾는다.
    # pane.split 은 pane 이 "null" 이면 오류 없이 포커스된 pane 을 나누므로, 못 찾으면 멈춘다
    out="$(app_do tab.new --space "$ws" --name "$label" --folder "$fe")"
    tab="$(jq -r '.tab // empty' <<<"$out")"
    p_fe_test="$(jq -r '.terminal // empty' <<<"$out")"
    [ -n "$tab" ] && [ -n "$p_fe_test" ] || die "tab.new 결과에 tab·terminal 이 없습니다: $out"
    p_root="$(app_ls | jq -r --arg t "$p_fe_test" \
      '[.spaces[].tabs[].terminals[] | select(.terminal == $t)][0].pane // empty')"
    [ -n "$p_root" ] || die "$p_fe_test 의 pane 을 찾지 못했습니다 (탭 $tab 은 남아 있습니다)"
    if [ "$with_check" = 1 ]; then
      # pane.split 은 비율을 받지 않고 늘 반으로 나눈다. check 를 낮게 두려고 행부터 만든다:
      # root 를 아래로 나눈 server 행을 다시 아래로 나눠 check 를 만들고(50% / 25% / 25%), 위 두 행을 좌우로 나눈다
      out="$(app_do pane.split --direction down --pane "$p_root")"
      p_fe_srv="$(jq -r '.terminal // empty' <<<"$out")"
      p_mid="$(jq -r '.pane // empty' <<<"$out")"
      [ -n "$p_mid" ] || die "pane.split 결과에 pane 이 없습니다: $out"
      p_check="$(app_do pane.split --direction down --pane "$p_mid" | jq -r '.terminal // empty')"
      p_be_test="$(app_do pane.split --direction right --pane "$p_root" | jq -r '.terminal // empty')"
      p_be_srv="$(app_do pane.split --direction right --pane "$p_mid" | jq -r '.terminal // empty')"
    else
      out="$(app_do pane.split --direction right --pane "$p_root")"
      p_be_test="$(jq -r '.terminal // empty' <<<"$out")"
      p_right="$(jq -r '.pane // empty' <<<"$out")"
      [ -n "$p_right" ] || die "pane.split 결과에 pane 이 없습니다: $out"
      p_fe_srv="$(app_do pane.split --direction down --pane "$p_root" | jq -r '.terminal // empty')"
      p_be_srv="$(app_do pane.split --direction down --pane "$p_right" | jq -r '.terminal // empty')"
    fi
    if [ -n "$orig_space" ]; then
      herdr-app do space.select --id "$orig_space" >/dev/null 2>&1 || true
      [ -z "$orig_tab" ] || herdr-app do tab.select --id "$orig_tab" >/dev/null 2>&1 || true
    fi
  }

  close_tab() { app_do tab.close --id "$1" --confirmed true >/dev/null; }

  status_rows() {
    local t
    for t in $(tab_panes "$1"); do
      printf '  %-8s %-10s %s\n' "$t" \
        "$(hc get "$t" --json | jq -r '.labels["herdr-dev.role"] // "-"')" "$(fg_cmd "$t")"
    done
  }
fi

# $1: pane, $2: 최대 대기 초
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
# foreground 확인만으로는 이르다. $1: pane, $2: 최대 대기 초
wait_ready() {
  local i prev="" cur
  for ((i = 0; i < $2 * 5; i++)); do
    if at_prompt "$1" 2>/dev/null; then
      cur="$(screen_last "$1")"
      [ -n "$cur" ] && [ "$cur" = "$prev" ] && return 0
      prev="$cur"
    fi
    sleep 0.2
  done
  return 1
}

# 명령이 foreground 로 올라올 때까지 기다린다. $1: pane, $2: 최대 대기 초
wait_running() {
  local i
  for ((i = 0; i < $2 * 5; i++)); do
    at_prompt "$1" 2>/dev/null || return 0
    sleep 0.2
  done
  return 1
}

# $1: pane, $2: label, $3: command, $4: 실행할 폴더
# 명령은 오래 도는 것(watch, server)을 전제로 한다. 보낸 뒤 foreground 가 바뀌지 않으면
# 입력이 버려진 것으로 보고 한 번 더 보낸다.
launch() {
  local try cmd="$3"
  # Herdr 앱의 pane.split 은 폴더를 받지 않아 새 pane 이 원래 pane 의 폴더에서 시작한다. 먼저 옮긴다
  if [ "$mode" = app ]; then cmd="cd $(printf '%q' "$4") && $3"; fi
  name_pane "$1" "$2"
  wait_ready "$1" 15 || echo "  경고: $1 ($2) 프롬프트를 기다리다 넘어갑니다" >&2
  for try in 1 2; do
    run_in "$1" "$cmd"
    wait_running "$1" 3 && break
    if [ "$try" = 1 ]; then
      echo "  $2: 명령이 시작되지 않아 다시 보냅니다" >&2
      press "$1" ctrl+u
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
  if [ "$mode" = app ]; then report_file "$fe_owner" "$be_owner"; return; fi
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
  if [ "$mode" = app ]; then rm -f "$statefile"; return 0; fi
  herdr workspace report-metadata "$ws" --source herdr-dev \
    --clear-token fe --clear-token be --clear-token fe_agent --clear-token be_agent >/dev/null 2>&1 || true
}

# Herdr 앱: 토큰 대신 상태 파일. 열린 포트가 없으면 파일을 지운다. 감시가 죽어도 until 이 지나면 mod 가 무시한다.
# 이모지와 색은 mod 가 TUI 와 같은 규칙으로 붙인다. $1 $2: fe·be 를 띄운 쪽 (user | agent | 빈 문자열)
# 경로는 XDG_STATE_HOME 과 무관하게 고정한다: 읽는 쪽 mod (ports.js) 가 ~/.local/state/herdr-dev 만 본다
statefile="$HOME/.local/state/herdr-dev/$(printf '%s' "${base#/}" | tr '/' '_').json"
report_file() {
  if [ -z "$1" ] && [ -z "$2" ]; then rm -f "$statefile"; return 0; fi
  mkdir -p "$(dirname "$statefile")"
  jq -n --arg space "$ws" --arg base "$base" --arg task "$task" --argjson until "$(( $(date +%s) + 15 ))" \
    --argjson fe_port "$fe_port" --arg fe "$1" --argjson be_port "$be_port" --arg be "$2" \
    '{space: $space, base: $base, task: $task, until: $until,
      fe: {port: $fe_port, owner: (if $fe == "" then null else $fe end)},
      be: {port: $be_port, owner: (if $be == "" then null else $be end)}}' \
    > "$statefile.tmp.$$" && mv -f "$statefile.tmp.$$" "$statefile"
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
  printf '%s\n' "$others" | awk -F'\t' -v k="$ws_kind" '{ printf "  %s (%s, %s %s)\n", $3, $2, k, $1 }'
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
  echo "$ws_kind $ws 에 $label 탭을 만듭니다  ${port_note:-}"
  local p_fe_test p_be_test p_fe_srv p_be_srv p_check=""
  make_dev_tab
  launch "$p_fe_test" "fe test"   "$FE_TEST_CMD"   "$fe"
  launch "$p_be_test" "be test"   "$BE_TEST_CMD"   "$be"
  launch "$p_fe_srv"  "fe server" "$FE_SERVER_CMD" "$fe"
  launch "$p_be_srv"  "be server" "$BE_SERVER_CMD" "$be"
  [ -z "$p_check" ] || launch "$p_check" "check" "$check_cmd" "$base"
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
    press "$p" ctrl+c
  done
  for p in $panes; do
    wait_prompt "$p" 10 && continue
    echo "  아직 실행 중, 한 번 더 ctrl+c: $p  $(fg_cmd "$p")"
    press "$p" ctrl+c
    wait_prompt "$p" 5 || echo "  경고: $p 가 끝나지 않아 탭을 닫으며 강제 종료합니다" >&2
  done
  close_tab "$tab"
  echo "탭을 닫았습니다: $label ($tab)"
  finish_watch
}

cmd_status() {
  local tab rc=0
  tab="$(find_tab)"
  if [ -z "$tab" ]; then
    echo "$label 탭이 없습니다 ($ws_kind $ws)"
    rc=1
  else
    echo "$label ($tab, $ws_kind $ws)   frontend :$fe_port → backend :$be_port"
    status_rows "$tab"
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
