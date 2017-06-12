tkhwang-dotfiles
================

My own personal configurations...

## Font

- [Download Operator Fonts | Hoefler & Co.](https://www.typography.com/fonts/operator/styles/)
- [Install Monaco font in Linux](https://gist.github.com/rogerleite/99819#file-install_monaco_font-sh)
- [PT Mono for powerline](https://github.com/wedens/dotfiles/blob/master/fonts/PT%20Mono%20for%20Powerline.ttf)


## Bash

* [bash-it](https://github.com/Bash-it/bash-it)

```
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

## Powerline : tmux configuration

- Ubuntu : [How can I install and use powerline plugin?](http://askubuntu.com/questions/283908/how-can-i-install-and-use-powerline-plugin)
- Mac : [Coderwall | Setup Vim, Powerline and iTerm2 on Mac OS X](https://coderwall.com/p/yiot4q/setup-vim-powerline-and-iterm2-on-mac-os-x)
	 - [GitHub - powerline/fonts: Patched fonts for Powerline users.](https://github.com/powerline/fonts)


## Terminal

### Gnome terminal

* [Dracula : Gnome terminal](https://github.com/dracula/gnome-terminal)
* Terminal colors : Solarized dark : [Gnome terminal](https://github.com/metalelf0/gnome-terminal-colors)

### Terminator

- [Terminator-solarized](https://github.com/ghuntley/terminator-solarized)

## Editor

###  [Sublime Text](http://www.sublimetext.com/3)

* Theme
  * [equinusocio/material-theme: Material Theme, the most epic theme for Sublime Text 3 by Mattia Astorino](https://github.com/equinusocio/material-theme)
  * [Theme - Soda Solarized​Dark](https://packagecontrol.io/packages/Theme%20-%20Soda%20SolarizedDark)
* Markdown [knockdown](https://github.com/aziz/knockdown/)
* [All Autocomplete](https://packagecontrol.io/packages/All%20Autocomplete)

```
{
  "color_scheme": "Packages/User/Solarized (Dark) (SublimePythonIDE).tmTheme",
  "font_face": "PT Mono",
  "font_size": 13,
  "highlight_line": true,
  "theme": "Soda SolarizedDark.sublime-theme"
}
```


### ATOM

- UI Theme : `Atom Dark`
- Syntax Theme : `Spacegray Dark Neue`

### vim 

- [SpaceVim](https://spacevim.org/)


### Emacs 

- [syl20bnr/spacemacs: A community-driven Emacs distribution - The best editor is neither Emacs nor Vim, it's Emacs *and* Vim!](https://github.com/syl20bnr/spacemacs)

#### Font

* Default font : `Operator Mono`

```lisp
   ;; Default font, or prioritized list of fonts. `powerline-scale' allows to
   ;; quickly tweak the mode-line size to make separators look not too crappy.
   dotspacemacs-default-font '("Operator Mono"
                               :size 13
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)
```

#### `dotspacemacs-configuration-layers`

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


#### `dotspacemacs/user-config`

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

## JetBrain : Android Studio, PyCharm

- AndroidStudio : [Color Themes](http://color-themes.com/?view=theme&id=563a1a6480b4acf11273ae47)
- PyCharm : [Material Theme UI :: JetBrains Plugin Repository](https://plugins.jetbrains.com/plugin/8006-material-theme-ui)


## System

### Ubuntu

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




