tkhwang-dotfiles
================

My own personal configurations...

## Bash

* [bash-it](https://github.com/Bash-it/bash-it)
* [autojump](https://github.com/wting/autojump)
* [metalelf0/gnome-terminal-colors: Solarized Gnome Terminal colors, based on http://ethanschoonover.com/solarized](https://github.com/metalelf0/gnome-terminal-colors)
* My configuration : `~/.bash_tkhwang`

```
cat <<'EOF' >> ~/.bashrc
# tkhwang-dotfiles configuration
[ -s ~/.bash_tkhwang ] && source ~/.bash_tkhwang
EOF
```

## Powerline

[How can I install and use powerline plugin?](http://askubuntu.com/questions/283908/how-can-i-install-and-use-powerline-plugin)

## vim

[pathogen.vim](https://github.com/tpope/vim-pathogen)


## Emacs

* [prelude](https://github.com/bbatsov/prelude)
* Install dracular theme

```
(M-x package-install <RET> dracula-theme)
```

```
;; -----------------------------------------------------------------------------
;; Color-theme
;; -----------------------------------------------------------------------------
;(load-theme 'solarized-dark t)
;(load-theme 'gotham t)
(load-theme 'dracula t)
```

* cp -r ./personal ~/.emacs.d/
* personal config

```
cat <<'EOF' >> ~/.emacs.d/init.el

;; tkhwang-dotfiles configuration
(require 'tkhwang-dotemacs)
EOF
```

## Other tools

* [Install Monaco font in Linux](https://gist.github.com/rogerleite/99819#file-install_monaco_font-sh)
* [Sublime Text](http://www.sublimetext.com/3)

