tkhwang-dotfiles
================

My own personal configurations...

## Bash

### [bash-it](https://github.com/Bash-it/bash-it)

* [autojump](https://github.com/wting/autojump)
* [gnome-terminal-colors-solarized](https://github.com/Anthony25/gnome-terminal-colors-solarized)
* [Solarized terminator colors](https://github.com/ghuntley/terminator-solarized)
* [Gnome Terminal colors](https://github.com/metalelf0/gnome-terminal-colors)

### Configuration

### `~/.bash_tkhwang`

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
* Install solarzied dartk  and gotham theme

```
(M-x package-install RET solarized-theme)
(M-x package-install RET gotham-theme)
```

* Select theme in `~/.emacs.d/personal/tkhwang-dotemacs.el`

```
;; -----------------------------------------------------------------------------
;; Color-theme
;; -----------------------------------------------------------------------------
;(load-theme 'solarized-dark t)
(load-theme 'gotham t)
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

* [monaco-font](https://github.com/cstrap/monaco-font)
* [Sublime Text](http://www.sublimetext.com/3)

