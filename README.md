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

### system-wide installation in Ubuntu

#### Powerline installation

```sh
sudo apt-get install python-pip git
sudo pip install git+git://github.com/Lokaltog/powerline
```

#### Font Installation:

```sh
wget https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf
sudo mv PowerlineSymbols.otf /usr/share/fonts/
sudo fc-cache -vf
sudo mv 10-powerline-symbols.conf /etc/fonts/conf.d/
```

### vim : `~/.vimrc`

```sh
set rtp+=/usr/local/lib/python2.7/dist-packages/powerline/bindings/vim/

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256
```

### tmux : `~/.tmux.conf`

```sh
source /usr/local/lib/python2.7/dist-packages/powerline/bindings/tmux/powerline.conf
set-option -g default-terminal "screen-256color"
```

## Color-theme : Solarized

* [Gnome terminal](https://github.com/Anthony25/gnome-terminal-colors-solarized)

## Other tools

* [Sublime Text](http://www.sublimetext.com/3)


## Ubuntu

### Monaco font

* [monaco-font](https://github.com/cstrap/monaco-font)


