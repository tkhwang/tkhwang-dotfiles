#!/usr/bin/env bash
# Keep the Herdr app (herdr.dev/core) layout and mods in this repo.
#
#   ./herdr-app/sync.sh backup   copy the live ~/.config/herdr-app files into this folder
#   ./herdr-app/sync.sh apply    restore this folder into ~/.config/herdr-app
#
# Files are copied, not linked: the app rewrites the layout file as you use the window
# (panel shown, sizes), so a link would keep the repo dirty.
#
# apply moves whatever it replaces to ~/.config/herdr-app.bak-<time>/ (outside the app folder,
# so the app never loads a backup as a mod), installs copy-on-select from its own repo at a
# pinned commit (it has no license, so it isn't copied here), and checks each mod. The app sees
# a new mod folder only when it starts, so restart Herdr after a first apply, then pick the
# layout with ⌘⇧L or `herdr-app do layout.switch '{"name":"main-dev"}'`.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
live="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"

# Mods kept here, each with a small patch: clones of Herdr's own mods (Apache-2.0, see
# LICENSE-herdr), and better-changes and better-spaces from munza/herdr-mods (Apache-2.0, see
# LICENSE-herdr-mods and NOTICE-herdr-mods), and herdr-open-with-zed from atleugim/herdr-open-with-zed
# (Apache-2.0, see LICENSE-herdr-open-with-zed).
mods="spaces-dev agents-dev changes-dev better-changes better-spaces tabs-dev herdr-open-with-zed"
files="layouts/main-dev.json settings.json keys.json"
# Third-party mod installed from its repo instead of kept here.
cos_repo="jspoynor/herdr-copy-on-select"
cos_sha="ea2304a28e3bda6812048ee556c592a558320aa2"

die() { echo "$*" >&2; exit 1; }

backup() {
  local m f
  [ -d "$live" ] || die "no Herdr app folder: $live"
  for m in $mods; do
    [ -d "$live/mods/$m" ] || die "missing mod: $live/mods/$m"
    mkdir -p "$here/mods/$m"
    # gpui-kit.d.ts (800 KB of editor types) and jsconfig.json are written by the app.
    rsync -a --delete --exclude '*.d.ts' --exclude jsconfig.json "$live/mods/$m/" "$here/mods/$m/"
  done
  for f in $files; do
    [ -f "$live/$f" ] || die "missing file: $live/$f"
    mkdir -p "$here/$(dirname "$f")"
    cp "$live/$f" "$here/$f"
  done
  [ -f /Applications/Herdr.app/Contents/Resources/LICENSE ] &&
    cp /Applications/Herdr.app/Contents/Resources/LICENSE "$here/LICENSE-herdr"
  echo "backed up $live -> $here"
  git -C "$here" status --short -- . || true
}

# Moves `path` (relative to the app folder) into this run's backup folder.
stash() {
  local dest="$live.bak-$stamp/$1"
  mkdir -p "$(dirname "$dest")"
  mv "$live/$1" "$dest"
  echo "  backed up $1 -> $dest"
}

apply() {
  local m f tmp
  stamp="$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$live/mods" "$live/layouts"
  for m in $mods; do
    if [ -d "$live/mods/$m" ]; then
      diff -rq -x '*.d.ts' -x jsconfig.json "$here/mods/$m" "$live/mods/$m" >/dev/null 2>&1 && { echo "same: mods/$m"; continue; }
      stash "mods/$m"
    fi
    rsync -a "$here/mods/$m/" "$live/mods/$m/"
    echo "installed mods/$m"
  done
  for f in $files; do
    if [ -f "$live/$f" ]; then
      cmp -s "$here/$f" "$live/$f" && { echo "same: $f"; continue; }
      stash "$f"
    fi
    mkdir -p "$live/$(dirname "$f")"
    cp "$here/$f" "$live/$f"
    echo "installed $f"
  done
  if [ -d "$live/mods/copy-on-select" ]; then
    echo "kept: mods/copy-on-select"
  else
    tmp="$(mktemp -d)"
    for f in main.js mod.json; do
      curl -fsSL "https://raw.githubusercontent.com/$cos_repo/$cos_sha/mods/copy-on-select/$f" -o "$tmp/$f" ||
        { rm -rf "$tmp"; die "could not fetch copy-on-select/$f from $cos_repo"; }
    done
    mkdir -p "$live/mods/copy-on-select"
    cp "$tmp/main.js" "$tmp/mod.json" "$live/mods/copy-on-select/"
    rm -rf "$tmp"
    echo "installed mods/copy-on-select ($cos_repo@${cos_sha:0:7})"
  fi
  if command -v herdr-app >/dev/null 2>&1; then
    for m in $mods copy-on-select; do herdr-app check "$live/mods/$m"; done
  fi
  echo "restart Herdr if a mod folder was new, then switch to the main-dev layout (⌘⇧L)"
}

case "${1:-}" in
  backup) backup ;;
  apply) apply ;;
  *) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
