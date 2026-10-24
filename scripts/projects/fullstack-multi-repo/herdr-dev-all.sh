#!/bin/bash
# 작업 폴더들의 herdr dev 탭을 root 에서 다룬다. 각 폴더의 herdr-dev.sh 를 대신 불러 준다.
#
# usage: ./herdr-dev-all.sh <명령> [<폴더> ...]
#   up <폴더> ...        지정한 폴더의 dev 탭을 띄운다 (폴더 필수)
#   restart <폴더> ...   지정한 폴더를 내렸다 올린다 (폴더 필수)
#   down [<폴더> ...]    지정한 폴더, 없으면 herdr-dev.sh 가 있는 모든 폴더를 내린다
#   status [<폴더> ...]  지정한 폴더, 없으면 모든 폴더의 상태를 보여준다
#   ports [<폴더> ...]   포트와 실행 명령을 보여준다
#
# <폴더>: feature-cpq-task-a, task-a (feature-cpq- 생략), 또는 절대 경로
#
# 예) ./herdr-dev-all.sh up task-a
#     ./herdr-dev-all.sh down
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
usage() { awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; }

cmd="${1:-}"
[ $# -gt 0 ] && shift
case "$cmd" in
  up|restart)
    [ $# -gt 0 ] || { echo "$cmd 는 폴더를 지정해야 합니다. 예) $0 $cmd task-a" >&2; usage >&2; exit 2; } ;;
  down|status|ports) ;;
  *) usage; exit 2 ;;
esac

# 폴더 인자 → 절대 경로. feature-cpq- 를 생략한 이름도 받는다
resolve() {
  local a="${1%/}"
  case "$a" in
    /*) echo "$a" ;;
    *)  if [ -d "$root/$a" ]; then echo "$root/$a"
        elif [ -d "$root/feature-cpq-$a" ]; then echo "$root/feature-cpq-$a"
        else echo "$root/$a"; fi ;;
  esac
}

dirs=()
if [ $# -eq 0 ]; then
  for s in "$root"/*/herdr-dev.sh; do [ -x "$s" ] && dirs+=("$(dirname "$s")"); done
  [ ${#dirs[@]} -gt 0 ] || { echo "herdr-dev.sh 가 있는 폴더가 없습니다: $root/*/" >&2; exit 1; }
else
  for a in "$@"; do dirs+=("$(resolve "$a")"); done
fi

rc=0
for d in "${dirs[@]}"; do
  echo "## $(basename "$d")"
  if [ ! -x "$d/herdr-dev.sh" ]; then
    echo "herdr-dev.sh 가 없습니다: $d  (./install-herdr-dev.sh $(basename "$d") 로 설치)" >&2
    rc=1; continue
  fi
  case "$cmd" in
    status) HERDR_DEV_NO_OTHERS=1 "$d/herdr-dev.sh" status || true ;;   # 탭 없음(1)은 실패가 아니다
    *)      "$d/herdr-dev.sh" "$cmd" || rc=1 ;;
  esac
done
exit $rc
