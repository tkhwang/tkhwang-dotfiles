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

The [Herdr app](https://herdr.dev/core/) (herdr-core desktop window) keeps its layout and mods in `~/.config/herdr-app`. The customized ones live in [`herdr-app/`](herdr-app/) as copies, not symlinks: the app rewrites the layout file as the window is used.

```bash
./herdr-app/sync.sh backup   # ~/.config/herdr-app -> herdr-app/ (run after changing a mod or the layout)
./herdr-app/sync.sh apply    # herdr-app/ -> ~/.config/herdr-app (replaced files go to ~/.config/herdr-app.bak-<time>/)
```

After a first `apply`, restart Herdr (it sees new mod folders at start) and pick the `main-dev` layout with ⌘⇧L.

- `layouts/main-dev.json` — clone of the shipped `main` layout; its spaces and agents blocks point to the `-dev` mods below, its Changes slot to `better-changes`
- `mods/spaces-dev` — dev server ports under each space (`🧑 fe:3011 · be:5010`, `🤖` for agent-started servers), read from the files `herdr-dev.sh watch` writes (see `scripts/projects/fullstack-multi-repo/`); patch: `ports.js` and lines marked `dev ports`
- `mods/agents-dev` — "Grouped by space" headers with the space's colored letter, bold name, separators and git branch; patch marked `space headers`
- `mods/changes-dev` — in a workbranch wrapper folder (not a repo, repos right under it such as `backend/` and `frontend/`) a repo picker with per-repo change counts; commits go to the picked repo; patch marked `wrapper repos`
- `mods/better-changes` — [munza/herdr-mods](https://github.com/munza/herdr-mods/tree/main/better-changes) at `77d94f7` (staged/unstaged groups with stage buttons, tree/flat list, inline/side-by-side diff in one reusable tab), in the Changes slot. Patched with the same `wrapper repos` repo picker (it commits staged changes of the picked repo only), and `mod.json` `place` is `none` so it doesn't also dock a second right sidebar. `changes-dev` stays installed: put it back in the layout's `changes` block to switch.
- `settings.json`, `keys.json` — app look and keys
- copy-on-select ([jspoynor/herdr-copy-on-select](https://github.com/jspoynor/herdr-copy-on-select)) — copies a terminal selection on mouse release; it has no license, so `apply` downloads it at a pinned commit instead of keeping a copy here

The `-dev` mods are `mod.clone`s of Herdr's own mods (version 0.1.11, recorded as `cloned_from` in each `mod.json`), licensed Apache-2.0 ([`LICENSE-herdr`](herdr-app/LICENSE-herdr)). Clones get no Herdr updates: after an update changes a shipped mod, clone it again and re-apply the marked patch.

`better-changes` is Apache-2.0 ([`LICENSE-herdr-mods`](herdr-app/LICENSE-herdr-mods), [`NOTICE-herdr-mods`](herdr-app/NOTICE-herdr-mods)). To update it, copy `better-changes/mods/better-changes/` from that repo and re-apply the `wrapper repos` patch and the `place` change.

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