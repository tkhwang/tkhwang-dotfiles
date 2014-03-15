;; ----------------------------------------------------------------------------
;; My own configuration ------------------------------------------------- BEGIN
;; ----------------------------------------------------------------------------

;; ----------------------------------------------------------------------------
;; Path
;; ----------------------------------------------------------------------------
;(setq load-path (cons (expand-file-name "~") load-path))
;(setq load-path (cons (expand-file-name "~/.emacs.d") load-path))
;(setq load-path (cons (expand-file-name "~/.emacs.d/personal") load-path))

(add-to-list 'load-path "~")
(add-to-list 'load-path "~/.emacs.d")
(add-to-list 'load-path "~/.emacs.d/personal")
(add-to-list 'load-path "~/.emacs.d/vendor")

;; ----------------------------------------------------------------------------
;; Enable menu-bar and tool-bar
;; ----------------------------------------------------------------------------
(menu-bar-mode 1)
(tool-bar-mode 1)

;; ----------------------------------------------------------------------------
;; Backup File
;; ----------------------------------------------------------------------------
(setq make-backup-files nil)

;; -----------------------------------------------------------------------------
;; Global key binding
;; -----------------------------------------------------------------------------
(global-set-key "\C-l" 'goto-line)      ; [Ctrl]-[L]

;; -----------------------------------------------------------------------------
;; Visible BELL
;; -----------------------------------------------------------------------------
(setq visible-bell t)

;; -----------------------------------------------------------------------------
;; Theme : solarized-dark
;; -----------------------------------------------------------------------------
(load-theme 'solarized-dark t)

;; -----------------------------------------------------------------------------
;; Font : Monaco configuration
;; -----------------------------------------------------------------------------
(if (eq system-type 'linux/gnu)
    (set-frame-font "Monaco-11"))
(if (eq system-type 'darwin)
    (set-frame-font "Monaco-13"))
(if (eq system-type 'cygwin)
    (set-frame-font "Monaco-13"))

;; -----------------------------------------------------------------------------
;; clean-auto-indent
;; https://github.com/pmarinov/clean-aindent
;; -----------------------------------------------------------------------------
;; = Installation and use
;;
;; Add "(require 'clean-aindent)" to your init.el. This will make
;; "Enter" execute clean-aindent() and M-backspace execute
;; bsunindent()
;;
;; To deactivate in your currend session do "M-x
;; clean-aindent-done". To uninstall permanently remove the "require"
;; function from init.el.
(require 'clean-aindent)

;; -----------------------------------------------------------------------------
;; powerline
;; https://github.com/milkypostman/powerline
;; -----------------------------------------------------------------------------
(require 'powerline)
(powerline-default-theme)


;; ----------------------------------------------------------------------------
(provide 'tkhwang-dotemacs) ; --------------------------------------------- END
;; ----------------------------------------------------------------------------
