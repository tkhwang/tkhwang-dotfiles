# tkhwang-dotfiles


## Install basic

- homebrew
- nvm

## Shell

* [oh-my-zsh](https://subicura.com/mac/dev/shell.html#oh-my-zsh-%E1%84%89%E1%85%A5%E1%86%AF%E1%84%8E%E1%85%B5)
* prompt: [starship](https://starship.rs/)
* vim : [NvChat](https://nvchad.com/)

## Application

* Terminal : [warp](https://www.warp.dev/)

```
brew install --cask warp
```
* [Raycast](https://www.raycast.com/)
* Window management : [loop](https://github.com/MrKai77/Loop)
* Taskbar : [hidden](https://github.com/dwarvesf/hidden)

## Herdr

[Herdr](https://herdr.dev) config lives in [`herdr/config.toml`](herdr/config.toml) and is symlinked into `~/.config/herdr/config.toml`, so herdr updates can't silently wipe customizations — any drift shows up in `git status`.

```bash
./herdr/apply.sh   # backup existing file, symlink, validate, reload
```

Notable customizations (herdr >= 0.8.2):

- `theme.custom.active_row_bg` — makes the current repo/branch row visible in the left pane (the old `surface_dim` override stopped working in 0.8.2, which switched active rows to this dedicated key)
- `theme.custom.teal` — turns the "agent waiting for you" indicator red

## mco

[mco](https://github.com/mco-org/mco) workflow helpers live in [`mco/mco-workflow.zsh`](mco/mco-workflow.zsh), symlinked to `~/.mco-workflow.zsh` and sourced from `~/.zshrc`.

```bash
./mco/apply.sh   # backup existing file, symlink, add source line to ~/.zshrc
```

Workflow: planning (claude) → plan review (mco) → plan 보강 (claude) → 구현 (mco) → 구현 리뷰 (mco). Providers are always the first argument.

```bash
mco-plan codex,grok plans/auth.md                  # plan review + debate -> plans/auth.debate.md
mco-impl codex plans/auth.md                       # implement (write mode)
mco-code codex,grok main --plan plans/auth.md      # review git diff vs base ref (default: main)
```

`-n` = dry-run; other `--xxx` flags pass through to mco. Artifacts go to `reports/mco/<task-id>/`.

## Font

* install [programming fonts](https://github.com/mhartington/dotfiles/tree/main/config/fonts)
    - monolisa
* [monaspace](https://monaspace.githubnext.com/)


## Shell script

### Add custom cd function to .zshrc

```bash
# Display the current path after changing the directory (cd).
function cd { builtin cd $* && pwd && ls -lF; }
```


```bash
echo -e '# Display the current path after changing the directory (cd).\nfunction cd { builtin cd $* && pwd && ls -lF; }' >> ~/.zshrc
```

Or add the function manually.