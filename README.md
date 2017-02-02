tkhwang-dotfiles
================

My own personal configurations...

## Font

- [Install Monaco font in Linux](https://gist.github.com/rogerleite/99819#file-install_monaco_font-sh)
- [PT Mono for powerline](https://github.com/wedens/dotfiles/blob/master/fonts/PT%20Mono%20for%20Powerline.ttf)



## Bash

* [bash-it](https://github.com/Bash-it/bash-it)
* [autojump](https://github.com/wting/autojump)
* Terminal colors : Solarized dark
	- [Gnome terminal](https://github.com/metalelf0/gnome-terminal-colors)
	- [Terminator-solarized](https://github.com/ghuntley/terminator-solarized)
* My configuration : `~/.bash_tkhwang`

```
cat <<'EOF' >> ~/.bashrc
# tkhwang-dotfiles configuration
[ -s ~/.bash_tkhwang ] && source ~/.bash_tkhwang
EOF
```

## vim

- [pathogen.vim](https://github.com/tpope/vim-pathogen)


## Powerline

- Ubuntu : [How can I install and use powerline plugin?](http://askubuntu.com/questions/283908/how-can-i-install-and-use-powerline-plugin)
- Mac : [Coderwall | Setup Vim, Powerline and iTerm2 on Mac OS X](https://coderwall.com/p/yiot4q/setup-vim-powerline-and-iterm2-on-mac-os-x)
	 - [GitHub - powerline/fonts: Patched fonts for Powerline users.](https://github.com/powerline/fonts)


##  [Sublime Text](http://www.sublimetext.com/3)

- [Theme - Soda Solarized​Dark](https://packagecontrol.io/packages/Theme%20-%20Soda%20SolarizedDark)
- [All Autocomplete](https://packagecontrol.io/packages/All%20Autocomplete)
- [knockdown](https://github.com/aziz/knockdown/)

```
{
    "color_scheme": "Packages/Color Scheme - Default/Solarized (Dark).tmTheme",
    "font_face": "Monaco",
    "font_size": 12
}
```



## Emacs

### New : [spacemacs](https://github.com/syl20bnr/spacemacs) usage

[syl20bnr/spacemacs: A community-driven Emacs distribution - The best editor is neither Emacs nor Vim, it's Emacs *and* Vim!](https://github.com/syl20bnr/spacemacs)

* Default font change from `Source Code Pro`  to `Monaco`.

```lisp
   ;; Default font, or prioritized list of fonts. `powerline-scale' allows to
   ;; quickly tweak the mode-line size to make separators look not too crappy.
   dotspacemacs-default-font '("Monaco"
                               :size 13
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)
```

* personal config

`.spacemacs` configuration 추가 설정 필요. (T.B.D)

### Old : [prelude](https://github.com/bbatsov/prelude) usage

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
