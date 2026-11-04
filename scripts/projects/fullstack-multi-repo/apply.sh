#!/usr/bin/env bash
# 이 폴더의 dev 스크립트를 monask-fullstack 루트로 복사하고, 루트의 install-herdr-dev.sh 로 task 폴더에 넣는다.
# 다시 돌려도 된다: 내용이 같은 파일은 건너뛴다.
#
# usage: ./apply.sh [<monask-fullstack>]
#   <monask-fullstack>: 루트 폴더. 없으면 ~/git/job/monask-fullstack
#
# 복사는 install-herdr-dev.sh 처럼 tmp 로 복사한 뒤 mv 로 바꿔 끼운다. bash 는 스크립트를 읽어 가며 실행하므로,
# 덮어쓰면 돌고 있는 herdr-dev.sh watch 가 바뀐 내용을 엉뚱한 위치부터 읽는다. mv 면 돌던 프로세스는 옛 파일을 계속 읽는다.
# 떠 있는 dev 탭은 restart 하지 않는다. 새 내용은 그 task 에서 restart 해야 쓰인다 (끝에 안내한다).
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
root="${1:-$HOME/git/job/monask-fullstack}"
root="${root%/}"
files=(herdr-dev.sh agent-dev.sh dev-ports.sh install-herdr-dev.sh herdr-dev-all.sh)

[ -d "$root" ] || { echo "monask-fullstack 폴더가 없습니다: $root" >&2; exit 1; }
root="$(cd "$root" && pwd)"
[ "$root" != "$src" ] || { echo "대상이 이 폴더 자신입니다: $root" >&2; exit 1; }

changed=0
for f in "${files[@]}"; do
  [ -f "$src/$f" ] || { echo "원본이 없습니다: $src/$f" >&2; exit 1; }
  dst="$root/$f"
  if [ -f "$dst" ] && cmp -s "$src/$f" "$dst"; then
    echo "같음    $dst"
    continue
  fi
  cp "$src/$f" "$dst.tmp.$$"
  chmod +x "$dst.tmp.$$"
  mv -f "$dst.tmp.$$" "$dst"
  echo "copied → $dst"
  changed=1
done

echo
echo "## task 폴더에 설치: $root/install-herdr-dev.sh"
status=0
out="$("$root/install-herdr-dev.sh" 2>&1)" || status=$?
printf '%s\n' "$out"
if grep -q '^copied' <<<"$out"; then changed=1; fi   # 루트는 같아도 task 사본이 옛것이었던 경우

if [ "$changed" = 1 ]; then
  echo
  echo "떠 있는 dev 탭과 agent-dev 서버는 옛 스크립트로 돈다. 새 내용을 쓰려면 그 task 에서 다시 띄운다:"
  echo "  ./herdr-dev.sh restart        (또는 루트에서 ./herdr-dev-all.sh restart <task>)"
  echo "  ./agent-dev.sh restart be|fe  (agent-dev.sh 로 띄운 서버)"
fi
exit "$status"
