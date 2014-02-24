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

;; 한글 저장은 어떻게 되는 것인가?
;;
;; 버퍼에 쩍힌 영역에 따라 다르게 저장된다.  현재 default는 CP949로
;; 저장되며, 만약 확장영역의 한글이 적히면 utf-8로 저장할 것인지
;; 물어본다.
(setq inhibit-startup-message t)
(setq byte-compile-verbose      nil
      byte-compile-warnings     nil)

(if (eq window-system 'w32)
    (progn
      ;; http://oldpie.yoonkn.com/cgi-bin/moin.cgi/EmacsFontSet
      ;; http://oldpie.yoonkn.com/cgi-bin/moin.cgi/dreamstorm/emacs
      ;; http://www.emacswiki.org/cgi-bin/wiki/FontSets
      ;; by hosung 2008-05-20
      ;; http://www.gnu.org/software/emacs/windows/faq5.html#windows-font
      ;; M-x set-default-font <RET> <TAB>하면 폰트리스트가 나온다.
      ;; 폰트크기 18은 맨 첫줄을 따라 가는 것 같다. ksc5601에서 작게 해도 한글이 작아지지는 않는다.
      ;; ksc5601에서 c는 실제 p로 나오는데 어떤 것을 해도 상관 없다.
      ;; 맨끝의 0을 *로 하면 정상적으로 폰트가 출력되지 않는다.
      ;;
      ;; 이와 같이 ksc5601로 하면 확장문자에 대하여 네모박스로 출력되는 문제가 있다.
      (setq initial-frame-alist '((top . 10) (left . 100)))
      (setq default-frame-alist
        (append
         '(
           (font . "-*-Monaco-normal-r-*-*-12-102-120-120-c-*-iso8859-1")
           (width . 140)
           (height . 47)
           )
         default-frame-alist))))

;; -----------------------------------------------------------------------------
;; Font
;; -----------------------------------------------------------------------------
(if (eq system-type 'gnu/linux)
    (set-default-font "Monaco-11"))
(if (eq system-type 'darwin)
    (set-default-font "Monaco-13"))
(if (eq system-type 'cygwin)
    (set-default-font "Monaco-12"))




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
