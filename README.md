tkhwang-dotfiles
================

My own personal configurations...

## Bash

* ~/.bash_tkhwang
* ~/.bashrc

```
cat <<'EOF' >> ~/.bashrc
# tkhwang-dotfiles configuration
if [ -f ~/.bash_tkhwang ]; then
      . ~/.bash_tkhwang
fi
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