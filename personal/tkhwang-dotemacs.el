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
;(add-to-list 'load-path "~/.emacs.d")
(add-to-list 'load-path "~/.emacs.d/personal")
(add-to-list 'load-path "~/.emacs.d/vendor")

;; ----------------------------------------------------------------------------
;; Enable menu-bar and tool-bar
;; ----------------------------------------------------------------------------
(menu-bar-mode 1)
;(tool-bar-mode 1)

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
    (set-frame-font "Monaco-10"))
(if (eq system-type 'darwin)
    (set-frame-font "Monaco-13"))
(if (eq system-type 'cygwin)
    (set-frame-font "Monaco-13"))

; Font config
; http://earthwithsun.com/questions/561885/setting-monospaced-font-on-emacs
(set-default-font "-apple-Monaco-normal-normal-normal-*-14-*-*-*-*-0-iso10646-1")

;; set input method toggle key to 'Shift-Space'
(global-set-key [?\S- ] 'toggle-input-method)

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


;; -----------------------------------------------------------------------------
;; markdown
;; -----------------------------------------------------------------------------
;; Markdown mode
;(require 'markdown-mode)
(autoload 'markdown-mode "markdown-mode"
  "Major mode for editing Markdown files" t)

(add-to-list 'auto-mode-alist '("\\.txt\\'"      . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'"       . markdown-mode))

;(add-hook 'markdown-mode-hook 'longlines-mode)

;; -----------------------------------------------------------------------------
;; Emacs tips
;; https://sites.google.com/site/steveyegge2/effective-emacs
;; -----------------------------------------------------------------------------

;Item 2: Invoke M-x without the Alt key
(global-set-key "\C-x\C-m" 'execute-extended-command)
(global-set-key "\C-c\C-m" 'execute-extended-command)

; Item 3: Prefer backward-kill-word over Backspace
(global-set-key "\C-w" 'backward-kill-word)
(global-set-key "\C-x\C-k" 'kill-region)
(global-set-key "\C-c\C-k" 'kill-region)

;; -----------------------------------------------------------------------------
;; Jedi.el - Python auto-completion for Emacs
;; http://tkf.github.io/emacs-jedi/latest/#jedi-el-python-auto-completion-for-emacs
;; -----------------------------------------------------------------------------
;; M-x package-install RET jedi RET
;; sudo pip install virtualenv
;; M-x jedi:install-server in Emacs
(add-hook 'python-mode-hook 'jedi:setup)
(setq jedi:complete-on-dot t)

;; -----------------------------------------------------------------------------
;; ascii-table
;; http://www.emacswiki.org/AsciiTable
;; -----------------------------------------------------------------------------
(autoload 'ascii-table "ascii-table" "Show ASCII table." t)
(defun ascii-table ()
  "Display basic ASCII table (0 thru 128)."
  (interactive)
  (setq buffer-read-only nil)        ;; Not need to edit the content, just read mode (added)
  (local-set-key "q" 'bury-buffer)   ;; Nice to have the option to bury the buffer (added)
  (switch-to-buffer "*ASCII*")
  (erase-buffer)
  (save-excursion (let ((i -1))
                    (insert "ASCII characters 0 thru 127.\n\n")
                    (insert " Hex  Dec  Char|  Hex  Dec  Char|  Hex  Dec  Char|  Hex  Dec  Char\n")
                    (while (< i 31)
                      (insert (format "%4x %4d %4s | %4x %4d %4s | %4x %4d %4s | %4x %4d %4s\n"
                                      (setq i (+ 1  i)) i (single-key-description i)
                                      (setq i (+ 32 i)) i (single-key-description i)
                                      (setq i (+ 32 i)) i (single-key-description i)
                                      (setq i (+ 32 i)) i (single-key-description i)))
                      (setq i (- i 96))))))

;; ----------------------------------------------------------------------------
(provide 'tkhwang-dotemacs) ; --------------------------------------------- END
;; ----------------------------------------------------------------------------
