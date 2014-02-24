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

;; �ѱ� ������ ��� �Ǵ� ���ΰ�?
;;
;; ���ۿ� ½�� ������ ���� �ٸ��� ����ȴ�.  ���� default�� CP949��
;; ����Ǹ�, ���� Ȯ�念���� �ѱ��� ������ utf-8�� ������ ������
;; �����.
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
      ;; M-x set-default-font <RET> <TAB>�ϸ� ��Ʈ����Ʈ�� ���´�.
      ;; ��Ʈũ�� 18�� �� ù���� ���� ���� �� ����. ksc5601���� �۰� �ص� �ѱ��� �۾������� �ʴ´�.
      ;; ksc5601���� c�� ���� p�� �����µ� � ���� �ص� ��� ����.
      ;; �ǳ��� 0�� *�� �ϸ� ���������� ��Ʈ�� ��µ��� �ʴ´�.
      ;;
      ;; �̿� ���� ksc5601�� �ϸ� Ȯ�幮�ڿ� ���Ͽ� �׸�ڽ��� ��µǴ� ������ �ִ�.
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
