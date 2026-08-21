#!/usr/bin/env bash
# Link this repo's herdr config into ~/.config/herdr and reload the server.
# Safe to re-run: backs up a real file once, no-ops if the link already exists.
set -euo pipefail

repo_config="$(cd "$(dirname "$0")" && pwd)/config.toml"
target="$HOME/.config/herdr/config.toml"

mkdir -p "$HOME/.config/herdr"

if [ -e "$target" ] && [ ! -L "$target" ]; then
  backup="$target.bak-$(date +%Y%m%d-%H%M%S)"
  mv "$target" "$backup"
  echo "backed up existing config to $backup"
fi

ln -sfn "$repo_config" "$target"
echo "linked $target -> $repo_config"

if command -v herdr >/dev/null 2>&1; then
  herdr config check || { echo "config check failed; fix before reloading" >&2; exit 1; }
  herdr server reload-config && echo "herdr config reloaded" || echo "herdr server not running; config applies on next start"
fi
