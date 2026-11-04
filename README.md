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

## Herdr app

The [Herdr app](https://herdr.dev/core/) setup lives in [tkhwang-herdr-mods](https://github.com/tkhwang/tkhwang-herdr-mods). The split: whatever installs into `~/.config/herdr-app` (mods, `layouts/main-dev.json`, `settings.json`, `keys.json`) belongs there, and everything else stays here, including [`herdr/`](herdr/), which is the herdr TUI config.

The two repos share one file format. `herdr-dev.sh watch` writes `~/.local/state/herdr-dev/<folder path>.json`, and `ports.js` in the `better-spaces` mod (used by `main-dev`) and its fallback `spaces-dev` reads it. A change to that JSON's fields needs both repos changed together.

The dev-tab scripts in [`scripts/projects/fullstack-multi-repo/`](scripts/projects/fullstack-multi-repo/) (`herdr-dev.sh`, `agent-dev.sh`, `dev-ports.sh`, …) run from the monask-fullstack root:

```bash
./scripts/projects/fullstack-multi-repo/apply.sh [<monask-fullstack>]   # copy changed scripts to the root (default ~/git/job/monask-fullstack), install into task folders
```

## mco

[mco](https://github.com/mco-org/mco) workflow helpers live in [`mco/mco-workflow.zsh`](mco/mco-workflow.zsh), symlinked to `~/.mco-workflow.zsh` and sourced from `~/.zshrc`.

```bash
./mco/apply.sh   # backup existing file, symlink, add source line to ~/.zshrc
```

Workflow: spec → 접근안 수집 (mco) → plan 작성 (claude) → plan review (mco) → plan 보강 (claude) → 구현 (mco) → 구현 리뷰 (mco). Providers are always the first argument.

```bash
mco-plan-draft claude,codex,grok plans/auth.spec.md   # independent short approaches -> plans/auth.drafts.md
mco-plan-review codex,grok plans/auth.md              # plan review + debate -> plans/auth.debate.md
mco-code-impl codex plans/auth.md                     # implement (write mode)
mco-code-review codex,grok main --plan plans/auth.md  # review git diff vs base ref (default: main)
```

`-n` = dry-run; other `--xxx` flags pass through to mco. File args accept a partial name (`insight`, `insight precedence`): one match runs directly, several open fzf (terminal) or list candidates (non-interactive). Artifacts go to `reports/mco/<task-id>/`.

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