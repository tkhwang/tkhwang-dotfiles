tkhwang-dotfiles
================


My own personal configurations...

## Bash

* ~/.bash_tkhwang
* ~/.bashrc

```
cat <<'EOF' >> ~/.bashrc
# tkhwang-dotfiles configuration
[ -s ~/.bash_tkhwang ] && source ~/.bash_tkhwang
EOF
```

## Emacs

* [prelude](https://github.com/bbatsov/prelude)
* Install solarzied dartk theme

```
(M-x package-install RET solarized-theme).
```

* cp -r ./personal ~/.emacs.d/
* personal config

```
cat <<'EOF' >> ~/.emacs.d/init.el

;; tkhwang-dotfiles configuration
(require 'tkhwang-dotemacs)
EOF
```

## Powerline

* [How can I install and use powerline plugin?](http://askubuntu.com/questions/283908/how-can-i-install-and-use-powerline-plugin)

## Color-theme : Solarized

* [Gnome terminal](https://github.com/Anthony25/gnome-terminal-colors-solarized)


## Other tools

* [Sublime Text](http://www.sublimetext.com/3)


## Ubuntu

### Monaco font

* [monaco-font](https://github.com/cstrap/monaco-font)


