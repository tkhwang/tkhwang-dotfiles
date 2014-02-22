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

;; ----------------------------------------------------------------------------
(provide 'tkhwang-dotemacs) ; --------------------------------------------- END
;; ----------------------------------------------------------------------------
