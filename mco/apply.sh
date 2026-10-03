#!/usr/bin/env bash
# Link this repo's mco workflow helpers into ~/.mco-workflow.zsh and source it from ~/.zshrc.
# Safe to re-run: backs up a real file once, no-ops if the link already exists.
set -euo pipefail

repo_file="$(cd "$(dirname "$0")" && pwd)/mco-workflow.zsh"
target="$HOME/.mco-workflow.zsh"

if [ -e "$target" ] && [ ! -L "$target" ]; then
  backup="$target.bak-$(date +%Y%m%d-%H%M%S)"
  mv "$target" "$backup"
  echo "backed up existing file to $backup"
fi

ln -sfn "$repo_file" "$target"
echo "linked $target -> $repo_file"

line='[ -f ~/.mco-workflow.zsh ] && source ~/.mco-workflow.zsh'
if ! grep -qF "$line" "$HOME/.zshrc" 2>/dev/null; then
  echo "$line" >> "$HOME/.zshrc"
  echo "added source line to ~/.zshrc"
fi

echo "run: source ~/.zshrc"
