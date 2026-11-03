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
./herdr-app/sync.sh apply    # herdr-app/ -> ~/.config/herdr-app (replaced files go to ~/.config/herdr-app.bak-<time>-<pid>/)
```

Both copy only the mods and files named in `sync.sh` (`mods`, `files`, plus copy-on-select and the Catppuccin themes on `apply`); any other mod in `~/.config/herdr-app` is neither backed up nor replaced.

After a first `apply`, restart Herdr (it sees new mod folders at start) and pick the `main-dev` layout with ⌘⇧L.

- `layouts/main-dev.json` — clone of the shipped `main` layout; its spaces block points to `better-spaces`, its agents block to `agents-dev`, its Changes slot to `better-changes`, its tab bar to `tabs-dev`. Its theme is Catppuccin: `herdr-catppuccin` (Mocha) in dark mode, `herdr-catppuccin-latte` in light mode
- `mods/spaces-dev` — dev server ports under each space (`🧑 fe:3011 · be:5010`, `🤖` for agent-started servers), read from the files `herdr-dev.sh watch` writes (see `scripts/projects/fullstack-multi-repo/`); patch: `ports.js` and lines marked `dev ports`. Replaced in the layout by `better-spaces` and kept as the fallback
- `mods/better-spaces` — [munza/herdr-mods](https://github.com/munza/herdr-mods/tree/main/better-spaces) at `77d94f7` (branch right-aligned on the space row, worktrees nested, PR status from `gh`), in the spaces block. Patched with the same `dev ports` line (`ports.js` and lines marked `dev ports`), and `updateColors` waits up to 2 s after a start for the shared `space.colors` (marked `space colors`): without that its first tick recolored every space. It runs `git`, `hc` and `gh` (GitHub with your local `gh` login). A space whose first terminal is in a non-repo folder (a workbranch wrapper) shows no branch or PR. Also merged in: the agent status glows of [filipores/herdr-spaces-status](https://github.com/filipores/herdr-spaces-status) at `4881e68` (green done, orange blocked, a breathing neutral contour while an agent works; `navigation.js` and lines marked `status glow`; commands `better-spaces.first_done` and `better-spaces.next_working`, no keys bound), Apache-2.0 ([`LICENSE-herdr-spaces-status`](herdr-app/LICENSE-herdr-spaces-status), [`NOTICE-herdr-spaces-status`](herdr-app/NOTICE-herdr-spaces-status)). Its own `spaces-glow` mod isn't installed: it replaces the same Spaces block and would drop the branch, PR and port lines. The active space row is tinted cyan (`#22d3ee`), with a cyan bar on the left and its name in bold (marked `current highlight`): the plain selected background looked like the status outlines, most space colors are green or teal like the done glow, and yellow sat too close to the blocked orange
- `mods/agents-dev` — "Grouped by space" headers with the space's colored letter, bold name, separators and git branch; patch marked `space headers`. Until a sort is picked it groups by space (the shipped default is Priority, which has no space headers); the pick is kept by the app, not in this repo. Each agent row also gets the Spaces list's status glow (green done, orange blocked, breathing contour while working; marked `status glow`), and the focused agent's row the same cyan highlight (marked `current highlight`)
- `mods/changes-dev` — in a workbranch wrapper folder (not a repo, repos right under it such as `backend/` and `frontend/`) a repo picker with per-repo change counts; commits go to the picked repo; patch marked `wrapper repos`
- `mods/better-changes` — [munza/herdr-mods](https://github.com/munza/herdr-mods/tree/main/better-changes) at `77d94f7` (staged/unstaged groups with stage buttons, tree/flat list, inline/side-by-side diff in one reusable tab), in the Changes slot. Patched with the same `wrapper repos` repo picker (it commits staged changes of the picked repo only), and `mod.json` `place` is `none` so it doesn't also dock a second right sidebar. `changes-dev` stays installed: put it back in the layout's `changes` block to switch.
- `mods/tabs-dev` — clone of the shipped tab bar whose `+` button opens `herdr-open-with-zed` (one row taller, 543px); patch marked `open with zed`. Each tab is at least 180px wide, so a short name is still easy to click, with the status dot and close button at its right edge (marked `tab width`). A tab with an agent in any of its panes is tinted yellow (`#facc15`), the color that stands out most since agent tabs matter most, while other tabs keep the theme's grey and are always outlined in the theme's foreground at 25% (40% when active, also filled), since the shipped tab bar draws inactive tabs as bare text and the theme's own border color almost vanishes against the bar (marked `tab kind`)
- `mods/herdr-open-with-zed` — [atleugim/herdr-open-with-zed](https://github.com/atleugim/herdr-open-with-zed) at `a15570e`, unchanged: Herdr's `+` menu (`new-menu` 0.1.11) with an **Open with Zed** row that opens the focused terminal's folder in Zed (`zed`, else `zeditor`, else `open -a Zed`). Apache-2.0 ([`LICENSE-herdr-open-with-zed`](herdr-app/LICENSE-herdr-open-with-zed)); after a Herdr update changes `new-menu`, copy its `main.js` again and re-add the row
- `settings.json`, `keys.json` — app look and keys
- copy-on-select ([jspoynor/herdr-copy-on-select](https://github.com/jspoynor/herdr-copy-on-select)) — copies a terminal selection on mouse release; it has no license, so `apply` downloads it at a pinned commit instead of keeping a copy here
- Catppuccin themes ([MarcozVD/herdr-layout-catppuccin](https://github.com/MarcozVD/herdr-layout-catppuccin)) — `themes/herdr-catppuccin.json` and `themes/herdr-catppuccin-latte.json`, with a sky-blue `#60b9fc` accent; no license, so `apply` downloads them at `b58f434` and checks each sha256. Only the themes: that repo's `catppuccin` layout swaps the tab bar, spaces, agents and changes blocks for its own mods, which would drop the patches above. A theme picked in Settings > Look is kept per layout in `layouts/.state/`; pick the Catppuccin themes there again if one was picked before

The `-dev` mods are `mod.clone`s of Herdr's own mods (version 0.1.11, recorded as `cloned_from` in each `mod.json`), licensed Apache-2.0 ([`LICENSE-herdr`](herdr-app/LICENSE-herdr)). Clones get no Herdr updates: after an update changes a shipped mod, clone it again and re-apply the marked patch.

`better-changes` and `better-spaces` are Apache-2.0 ([`LICENSE-herdr-mods`](herdr-app/LICENSE-herdr-mods), [`NOTICE-herdr-mods`](herdr-app/NOTICE-herdr-mods)). To update one, copy `<name>/mods/<name>/` from that repo and re-apply its marked patch (and for `better-changes` the `place` change).

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