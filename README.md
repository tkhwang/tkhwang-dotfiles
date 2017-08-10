tkhwang-dotfiles
================

My own personal configurations...


## Bash

* [bash-it](https://github.com/Bash-it/bash-it)

```
export BASH_IT_THEME='zork'
or 
export BASH_IT_THEME='powerline-multiline'
```

* [autojump](https://github.com/wting/autojump)
* My configuration : `~/.bash_tkhwang`

```
cat <<'EOF' >> ~/.bashrc
# tkhwang-dotfiles configuration
[ -s ~/.bash_tkhwang ] && source ~/.bash_tkhwang
EOF
```


## Homebrew

- [Homebrew — macOS 용 패키지 관리자](https://brew.sh/index_ko.html)

```bash
$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

- [Homebrew-Cask](https://caskroom.github.io/)
- [caskroom/homebrew-cask: A CLI workflow for the administration of Mac applications distributed as binaries](https://github.com/caskroom/homebrew-cask)


## Font

- [Install powerline patched fonts](https://askubuntu.com/questions/283908/how-can-i-install-and-use-powerline-plugin)

```bash
wget https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf
sudo mv PowerlineSymbols.otf /usr/share/fonts/
sudo fc-cache -vf
sudo mv 10-powerline-symbols.conf /etc/fonts/conf.d/
```

- [powerline/fonts: Patched fonts for Powerline users.](https://github.com/powerline/fonts)
- [Download Operator Fonts | Hoefler & Co.](https://www.typography.com/fonts/operator/styles/)
- [Install Monaco font in Linux](https://gist.github.com/rogerleite/99819#file-install_monaco_font-sh)
- [PT Mono for powerline](https://github.com/wedens/dotfiles/blob/master/fonts/PT%20Mono%20for%20Powerline.ttf)


## Terminal

### iTerm2

* [mbadolato/iTerm2-Color-Schemes: Over 150 terminal color schemes/themes for iTerm/iTerm2 (with ports to Terminal, Konsole, PuTTY, Xresources, XRDB, and Terminator)](https://github.com/mbadolato/iTerm2-Color-Schemes)


### tmux

- [tmux-plugins/tpm: Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- [jimeh/tmux-themepack: A pack of various Tmux themes.](https://github.com/jimeh/tmux-themepack)

```
source-file "${HOME}/.tmux-themepack/powerline/block/cyan.tmuxtheme"

set-option -g default-terminal "screen-256color"

# Sane scrolling
set -g terminal-overrides 'xterm*:smcup@:rmcup@'
#set -g mode-mouse on

# tmux
set -g @plugin 'jimeh/tmux-themepack'
set -g @themepack 'powerline/doulbe/cyan'
```

### Gnome terminal

* [Dracula : Gnome terminal](https://github.com/dracula/gnome-terminal)
* Terminal colors : Solarized dark : [Gnome terminal](https://github.com/metalelf0/gnome-terminal-colors)

### Terminator

- [Terminator-solarized](https://github.com/ghuntley/terminator-solarized)

### [Hyper™](https://hyper.is/)

* Theme : [Dracula — A dark theme for Hyper and 40+ apps](https://draculatheme.com/hyper)

```
plugins: [
  "hyper-dracula"
]
```

## Editor


### vim 

- [SpaceVim](https://spacevim.org/)


###  [Sublime Text](http://www.sublimetext.com/3)

* Theme
  * [equinusocio/material-theme: Material Theme, the most epic theme for Sublime Text 3 by Mattia Astorino](https://github.com/equinusocio/material-theme)
  * [Theme - Soda Solarized​Dark](https://packagecontrol.io/packages/Theme%20-%20Soda%20SolarizedDark)
* Markdown [knockdown](https://github.com/aziz/knockdown/)
* [All Autocomplete](https://packagecontrol.io/packages/All%20Autocomplete)

```
{
  "color_scheme": "Packages/User/Solarized (Dark) (SublimePythonIDE).tmTheme",
  "font_face": "Operator Mono Light",
  "font_size": 13,
  "highlight_line": true,
  "theme": "Soda SolarizedDark.sublime-theme"
}
```


### ATOM

- UI Theme : `Atom Dark`
- Syntax Theme : `Spacegray Dark Neue`


### Emacs 

- [syl20bnr/spacemacs: A community-driven Emacs distribution - The best editor is neither Emacs nor Vim, it's Emacs *and* Vim!](https://github.com/syl20bnr/spacemacs)

Theme

```
   ;; List of themes, the first of the list is loaded when spacemacs starts.
   ;; Press <SPC> T n to cycle to the next theme in the list (works great
   ;; with 2 themes variants, one dark and one light)
   dotspacemacs-themes '(spacegray)
```

Font : Default font : `Operator Mono`

```lisp
   ;; Default font, or prioritized list of fonts. `powerline-scale' allows to
   ;; quickly tweak the mode-line size to make separators look not too crappy.
   dotspacemacs-default-font '("Operator Mono"
                               :size 13
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)
```

`dotspacemacs-configuration-layers`

```lisp
   dotspacemacs-configuration-layers
   '(
     python
     ;; ----------------------------------------------------------------
     ;; Example of useful layers you may want to use right away.
     ;; Uncomment some layer names and press <SPC f e R> (Vim style) or
     ;; <M-m f e R> (Emacs style) to install them.
     ;; ----------------------------------------------------------------
     helm
     auto-completion
     better-defaults
     emacs-lisp
     git
     markdown
     ;; org
     ;; (shell :variables
     ;;        shell-default-height 30
     ;;        shell-default-position 'bottom)
     ;; spell-checking
     ;; syntax-checking
     ;; version-control
     )
```


`dotspacemacs/user-config`

```lisp
(defun dotspacemacs/user-config ()
  ;; Item 2: Invoke M-x without the Alt key
  (global-set-key "\C-x\C-m" 'execute-extended-command)
  ; [Ctrl]-[L]
  (global-set-key "\C-l" 'goto-line)
  (global-linum-mode 1)
  "Configuration function for user code.
This function is called at the very end of Spacemacs initialization after
layers configuration.
This is the place where most of your configurations should be done. Unless it is
explicitly specified that a variable should be set before a package is loaded,
you should place your code here."
  )
```


## File Explorer

- vifm : [vifm/vifm: Vifm is an ncurses based file manager with vi like key bindings, which also borrows some useful ideas from mutt.](https://github.com/vifm/vifm)



## JetBrain : Android Studio, PyCharm

- AndroidStudio : [Color Themes](http://color-themes.com/?view=theme&id=563a1a6480b4acf11273ae47)
- PyCharm : [Material Theme UI :: JetBrains Plugin Repository](https://plugins.jetbrains.com/plugin/8006-material-theme-ui)


## System

### Ubuntu

- [Latest Unity Tweak Tool for Ubuntu - NoobsLab | Ubuntu/Linux News, Reviews, Tutorials, Apps](http://www.noobslab.com/2013/04/latest-unity-tweak-tool-for-ubuntu-1304.html)

```bash
$ sudo apt-get install unity-tweak-tool
```

* [Shadow icon theme](http://www.noobslab.com/2015/07/a-new-icon-set-shadow-available-for.html)


### Windows

#### Caps lock 키를 Windows key 로 remap

[Windows: Map CAPS LOCK to Windows Key | mattshaw.org](http://mattshaw.org/news/window-map-caps-lock-to-windows-key/)

Save as caps.reg, then double click to import into Registry.

```
Windows Registry Editor Version 5.00
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout]
"Scancode Map"=hex:00,00,00,00,00,00,00,00,02,00,00,00,5c,e0,3a,00,00,00,00,00
```




