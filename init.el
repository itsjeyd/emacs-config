(package-initialize)
(setq package-enable-at-startup nil)

(require 'use-package)
(setq use-package-always-ensure t)

(require 'bind-key)



;;;;;;;;;;;;;;
;;; Custom ;;;
;;;;;;;;;;;;;;

(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)



;;;;;;;;;;;;;
;;; Paths ;;;
;;;;;;;;;;;;;

(add-to-list 'load-path "~/.emacs.d/lisp/")



;;;;;;;;;;;;
;;; Keys ;;;
;;;;;;;;;;;;

(defvar custom-keys-mode-map (make-sparse-keymap)
  "Keymap for custom-keys-mode.")

(defvar custom-keys-mode-prefix-map (lookup-key global-map (kbd "M-s"))
  "Keymap for custom key bindings starting with M-s prefix.")

(define-key custom-keys-mode-map (kbd "M-s") custom-keys-mode-prefix-map)

(define-minor-mode custom-keys-mode
  "A minor mode for custom key bindings."
  :lighter ""
  :keymap 'custom-keys-mode-map
  :global t)

(defun prioritize-custom-keys
    (file &optional noerror nomessage nosuffix must-suffix)
  "Try to ensure that custom key bindings always have priority."
  (unless (eq (caar minor-mode-map-alist) 'custom-keys-mode)
    (let ((custom-keys-mode-map (assq 'custom-keys-mode minor-mode-map-alist)))
      (assq-delete-all 'custom-keys-mode minor-mode-map-alist)
      (add-to-list 'minor-mode-map-alist custom-keys-mode-map))))

(advice-add 'load :after #'prioritize-custom-keys)



;;;;;;;;;;;;;;;
;;; Backups ;;;
;;;;;;;;;;;;;;;

(setq backup-directory-alist '(("-autoloads.el\\'")
                               ("-loaddefs.el\\'")
                               ("." . "~/.emacs.d/backups")))


;;;;;;;;;;;;;;;
;;; Buffers ;;;
;;;;;;;;;;;;;;;

(use-package ibuffer
  :bind ("C-x C-b" . ibuffer)
  :config
  ;; Functions
  (defun ibuffer-group-buffers ()
    (ibuffer-switch-to-saved-filter-groups "Default"))

  ;; Hooks
  (add-hook 'ibuffer-mode-hook #'ibuffer-group-buffers)
  (add-hook 'ibuffer-mode-hook #'ibuffer-auto-mode)

  ;; Variables
  (setq-default ibuffer-saved-filter-groups
                '(("Default"
                   ("Dired" (mode . dired-mode))
                   ("Org" (mode . org-mode))
                   ("Temporary" (name . "\*.*\*"))))))

; Commands
(defvar temp-buffer-count 0)

(defun make-temp-buffer ()
  (interactive)
  (let ((temp-buffer-name (format "*temp-%d*" temp-buffer-count)))
    (switch-to-buffer temp-buffer-name)
    (org-mode)
    (message "New temp buffer (%s) created." temp-buffer-name))
  (setq temp-buffer-count (1+ temp-buffer-count)))

; Key Bindings
(global-set-key (kbd "C-c t") #'make-temp-buffer)
(define-key custom-keys-mode-prefix-map (kbd "r b") #'revert-buffer)

; Variables
(setq confirm-nonexistent-file-or-buffer nil)
(setq revert-without-query '(".*"))



;;;;;;;;;;;;;;;;;;;;
;;; Byte-Compile ;;;
;;;;;;;;;;;;;;;;;;;;

; Commands
(defun recompile-elisp-file ()
  (interactive)
  (when (and buffer-file-name (string-match "\\.el" buffer-file-name))
    (let ((byte-file (concat buffer-file-name "\\.elc")))
      (if (or (not (file-exists-p byte-file))
              (file-newer-than-file-p buffer-file-name byte-file))
          (byte-compile-file buffer-file-name)))))

(add-hook 'after-save-hook #'recompile-elisp-file)



;;;;;;;;;;;;;;;;
;;; Calendar ;;;
;;;;;;;;;;;;;;;;

(use-package calfw
  :defer t
  :config
  (setq cfw:face-item-separator-color "#6699cc")
  (setq cfw:render-line-breaker 'cfw:render-line-breaker-wordwrap)
  (when (eq (car custom-enabled-themes) 'sanityinc-tomorrow-eighties)
            (set-face-attribute 'cfw:face-title nil :foreground "#f99157")
            (set-face-attribute 'cfw:face-sunday nil :foreground "#cc99cc")
            (set-face-attribute 'cfw:face-header nil :foreground "#66cccc")
            (set-face-attribute 'cfw:face-holiday nil :foreground "#ffcc66")
            (set-face-attribute 'cfw:face-default-day nil :foreground "#66cccc")
            (set-face-attribute 'cfw:face-select nil :background "#99cc99" :foreground "#393939")
            (set-face-attribute 'cfw:face-today-title nil :background "#f2777a" :foreground "#393939")
            (set-face-attribute 'cfw:face-today nil :foreground "#99cc99")
            (set-face-attribute 'cfw:face-toolbar nil :background "#393939")
            (set-face-attribute 'cfw:face-toolbar-button-off nil :foreground "#7f7f7f" :weight 'normal)))

(use-package calfw-org
  :ensure calfw
  :commands cfw:open-org-calendar
  :config
  (defun cfw:org-create-source (&optional color)
    "Create org-agenda source."
    (make-cfw:source
     :name "org-agenda"
     :color (or color "#7aa37a")
     :data 'cfw:org-schedule-period-to-calendar)))

(use-package calfw-git
  :ensure nil
  :load-path "lisp/calfw-git"
  :commands cfw:git-open-calendar)

; Commands
(defun open-org-calendar ()
  "Open calendar in a separate frame."
  (interactive)
  (let ((cal-frame (make-frame '((minibuffer . nil)))))
    (select-frame cal-frame)
    (cfw:open-org-calendar)
    (toggle-window-dedicated)))



;;;;;;;;;;;;;;;;;;;
;;; Common Lisp ;;;
;;;;;;;;;;;;;;;;;;;

(use-package cl-lib)



;;;;;;;;;;;
;;; CSS ;;;
;;;;;;;;;;;

(use-package css-mode
  :commands css-mode
  :config

  (use-package rainbow-mode
    :commands rainbow-turn-on)

  ;; Hooks
  (add-hook 'css-mode-hook #'rainbow-turn-on)

  ;; Key Bindings
  (bind-key "C-c b" #'web-beautify-css css-mode-map))



;;;;;;;;;;;;;
;;; Dired ;;;
;;;;;;;;;;;;;

(use-package dired
  :ensure nil
  :config

  (use-package peep-dired
    :commands peep-dired
    :config
    (modeline-set-lighter 'peep-dired " 👁")

    ;; Functions
    (defun turn-off-openwith-mode ()
      (make-local-variable 'openwith-mode)
      (if (not peep-dired)
          (openwith-mode 1)
        (openwith-mode -1)))

    ;; Hooks
    (add-hook 'peep-dired-hook #'turn-off-openwith-mode)

    ;; Key Bindings
    (bind-keys :map peep-dired-mode-map
               ("n" . peep-dired-next-file)
               ("p" . peep-dired-prev-file)
               ("K" . peep-dired-kill-buffers-without-window)
               ("C-n" . dired-next-line)
               ("C-p" . dired-previous-line))

    ;; Variables
    (add-to-list 'peep-dired-ignored-extensions "mp3"))

  ;; Commands
  (defun dired-jump-to-top ()
    (interactive)
    (goto-char (point-min))
    (if dired-hide-details-mode
        (dired-next-line 3)
      (dired-next-line 4)))

  (defun dired-jump-to-bottom ()
    (interactive)
    (goto-char (point-max))
    (dired-next-line -1))

  ;; Commands
  (put 'dired-find-alternate-file 'disabled nil)

  ;; Hooks
  (add-hook 'dired-mode-hook #'dired-hide-details-mode)

  ;; Key Bindings
  (bind-keys :map dired-mode-map
             (")" . dired-hide-details-mode)
             ((vector 'remap 'beginning-of-buffer) . dired-jump-to-top)
             ((vector 'remap 'end-of-buffer) . dired-jump-to-bottom))

  ;; Variables
  (setq dired-dwim-target t)
  (setq dired-isearch-filenames "dwim")
  (setq dired-listing-switches "-alh --time-style=long-iso")
  (setq dired-recursive-copies 'always))

(use-package dired-x
  :ensure nil
  :bind ("C-x C-j" . dired-jump)
  :config
  ;; Hooks
  (add-hook 'dired-mode-hook #'dired-omit-mode)

  ;; Key Bindings
  (bind-key "M-o" #'dired-omit-mode dired-mode-map)

  ;; Variables
  (setq dired-omit-files "^\\...+$"))

(use-package direx
  :bind ("C-x C-d" . direx:jump-to-directory)
  :config

  ;; Key Bindings
  (bind-keys :map direx:direx-mode-map
             ("M-n" . direx:next-sibling-item)
             ("M-p" . direx:previous-sibling-item))

  ;; Variables
  (setq direx:closed-icon "▶ ")
  (setq direx:leaf-icon "  ")
  (setq direx:open-icon "▼ "))



;;;;;;;;;;;;;;;
;;; Editing ;;;
;;;;;;;;;;;;;;;

(use-package anchored-transpose
  :commands anchored-transpose)

(use-package annotate
  :commands annotate-mode
  :config
  (setq annotate-file "~/.emacs.d/annotations"))

(use-package auto-complete-config
  :ensure auto-complete
  :config
  (ac-config-default)
  (ac-flyspell-workaround)

  ;; Advice
  (defun ac-turn-off-line-truncation (orig &optional force)
    (toggle-truncate-lines -1)
    (funcall orig force)
    (toggle-truncate-lines 1))

  (advice-add 'ac-quick-help :around #'ac-turn-off-line-truncation)

  ;; Key Bindings
  (bind-keys :map ac-completing-map
             ("C-h" . ac-help)
             ("C-v" . ac-quick-help-scroll-down)
             ("M-v" . ac-quick-help-scroll-up))
  (bind-key "C-f" #'ac-stop ac-menu-map)

  ;; Variables
  (setq ac-auto-show-menum 0.2)
  (setq ac-comphist-file "~/.emacs.d/.ac-comphist.dat")
  (setq ac-ignore-case nil)
  (setq ac-quick-help-delay 0.5)
  (setq ac-use-menu-map t))

(use-package avy-zap
  :bind ("M-z" . avy-zap-up-to-char-dwim))

(use-package caps-lock
  :commands caps-lock-mode
  :init
  (bind-key "c l" #'caps-lock-mode custom-keys-mode-prefix-map))

(use-package change-inner
  :bind (("C-c i" . change-inner)
         ("C-c o" . change-outer)))

(use-package elec-pair
  :ensure nil
  :init
  (electric-pair-mode 1)

  ;; Pairs
  (defvar single-backticks '(?\` . ?\`)))

(use-package expand-region
  :commands er/expand-region
  :init
  (bind-key "@" #'er/expand-region custom-keys-mode-prefix-map))

(use-package iso-transl
  :ensure nil
  :defer t
  :config
  (bind-keys :map iso-transl-ctl-x-8-map
             ("a" . "⟶")
             ("l" . "⚡" )))

(use-package mark-lines
  :ensure nil
  :load-path "lisp/mark-lines"
  :commands mark-lines-next-line)

(use-package move-text
  :commands (move-text-up move-text-down)
  :config
  ;; Functions
  (defun follow-line (arg)
    (unless mark-active (forward-line (- arg))))

  ;; Hooks
  (advice-add 'move-text-up :after #'follow-line))

(use-package multiple-cursors
  :defer 5
  :config

  (use-package mc-hide-unmatched-lines-mode
    :ensure multiple-cursors
    :commands mc-hide-unmatched-lines-mode
    :config
    (setq hum/lines-to-expand 1))

  ;; Hydra
  (defhydra hydra-mc ()
    "MC"
    ("n" mc/mark-next-like-this "next")
    ("p" mc/mark-previous-like-this "prev")
    ("s" hydra-mc-symbols/body "symbols" :color blue)
    ("w" hydra-mc-words/body "words" :color blue)
    ("S" hydra-mc-skip/body "skip" :color blue)
    ("U" hydra-mc-unmark/body "unmark" :color blue)
    ("o" hydra-mc-operate/body "operate" :color blue)
    ("C-'" mc-hide-unmatched-lines-mode "hide unmatched"))

  (defhydra hydra-mc-symbols ()
    "MC (symbols)"
    ("n" mc/mark-next-symbol-like-this "next")
    ("p" mc/mark-previous-symbol-like-this "prev")
    ("q" hydra-mc/body "exit" :color blue))

  (defhydra hydra-mc-words ()
    "MC (words)"
    ("n" mc/mark-next-word-like-this "next")
    ("p" mc/mark-previous-word-like-this "prev")
    ("q" hydra-mc/body "exit" :color blue))

  (defhydra hydra-mc-skip ()
    "MC (skip)"
    ("n" mc/skip-to-next-like-this "next")
    ("p" mc/skip-to-previous-like-this "prev")
    ("q" hydra-mc/body "exit" :color blue))

  (defhydra hydra-mc-unmark ()
    "MC (unmark)"
    ("n" mc/unmark-next-like-this "next")
    ("p" mc/unmark-previous-like-this "prev")
    ("q" hydra-mc/body "exit" :color blue))

  (defhydra hydra-mc-operate ()
    "MC (operate)"
    ("n" mc/insert-numbers "number")
    ("s" mc/sort-regions "sort")
    ("r" mc/reverse-regions "reverse")
    ("q" hydra-mc/body "exit" :color blue))

  (defhydra hydra-mc-all ()
    "MC (all)"
    ("d" mc/mark-all-dwim "dwim")
    ("f" mc/mark-all-like-this-in-defun "defun")
    ("l" mc/mark-all-like-this "like this")
    ("r" mc/mark-all-in-region "region")
    ("R" mc/mark-all-in-region-regexp "region (regexp)")
    ("s" hydra-mc-symbols-all/body "symbols" :color blue)
    ("w" hydra-mc-words-all/body "words" :color blue))

  (defhydra hydra-mc-symbols-all ()
    "MC (all symbols)"
    ("l" mc/mark-all-symbols-like-this "like this")
    ("f" mc/mark-all-symbols-like-this-in-defun "defun")
    ("q" hydra-mc-all/body "exit" :color blue))

  (defhydra hydra-mc-words-all ()
    "MC (all words)"
    ("l" mc/mark-all-words-like-this "like this")
    ("f" mc/mark-all-words-like-this-in-defun "defun")
    ("q" hydra-mc-all/body "exit" :color blue))

  (defhydra hydra-mc-edit (:color blue)
    "MC (edit)"
    ("l" mc/edit-lines "lines")
    ("b" mc/edit-beginnings-of-lines "beginnings")
    ("e" mc/edit-ends-of-lines "ends"))

  ;; Key Bindings
  (bind-keys :map custom-keys-mode-prefix-map
             ("m" . hydra-mc/body)
             ("a" . hydra-mc-all/body)
             ("e" . hydra-mc-edit/body)))

(use-package utils
  :ensure nil
  :commands (flush-empty-lines sort-lines-and-uniquify unfill-paragraph))

; Advice
(defun record-current-position (arg)
  (when arg (push-mark)))

(advice-add 'set-mark-command :before #'record-current-position)

(defun determine-scope (beg end &optional region)
  "Determine scope for next invocation of `kill-region' or
`kill-ring-save': When called interactively with no active
region, operate on a single line. Otherwise, operate on region."
  (interactive
   (if mark-active
       (list (region-beginning) (region-end))
     (list (line-beginning-position) (line-beginning-position 2)))))

(advice-add 'kill-region :before #'determine-scope)
(advice-add 'kill-ring-save :before #'determine-scope)

; Commands
(defun kill-region-with-arg (arg)
  (interactive "P")
  (if arg
      (let ((beg (line-beginning-position))
            (end (line-beginning-position (+ arg 1))))
        (kill-region beg end)
        (message "Killed %d lines." arg))
    (call-interactively #'kill-region)))

(defun kill-ring-save-with-arg (arg)
  (interactive "P")
  (if arg
      (let ((beg (line-beginning-position))
            (end (line-beginning-position (+ arg 1))))
        (kill-ring-save beg end)
        (message "Copied %d lines." arg))
    (call-interactively #'kill-ring-save)))

(defun mark-line ()
  "Simple wrapper around `mark-lines-next-line' that marks the line
point is on and summons `hydra-mark-lines'."
  (interactive)
  (mark-lines-next-line 1)
  (hydra-mark-lines/body))

; Hooks
(add-hook 'before-save-hook #'delete-trailing-whitespace)

; Hydra
(defhydra hydra-mark-lines ()
  "Mark lines"
  ("m" next-line "next line")
  ("n" next-line "next line")
  ("p" previous-line "previous line"))

(defhydra hydra-move-text ()
  "Move text"
  ("u" move-text-up "up")
  ("d" move-text-down "down"))

; Key Bindings
(global-set-key (kbd "C-w") #'kill-region-with-arg)
(global-set-key (kbd "M-w") #'kill-ring-save-with-arg)
(global-set-key (kbd "M-=") #'count-words)
(global-set-key (kbd "C-c m") #'mark-line)
(define-key custom-keys-mode-prefix-map (kbd "u") #'hydra-move-text/body)
(define-key custom-keys-mode-prefix-map (kbd "d") #'hydra-move-text/body)

; Variables
(setq cua-enable-cua-keys nil)
(setq require-final-newline t)
(setq save-interprogram-paste-before-kill t)
(setq sentence-end-double-space nil)
(setq set-mark-command-repeat-pop t)
(setq tab-width 4)



;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Elisp Development ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package lispy-mnemonic
  :ensure nil
  :load-path "lisp/lispy-mnemonic"
  :commands lispy-mnemonic-mode
  :config
  (setq lispy-mnemonic-restore-bindings t))

(use-package lispy
  :defer t
  :config
  (setq lispy-avy-keys (number-sequence ?a ?i))
  (setq lispy-avy-style-char 'at-full)
  (setq lispy-avy-style-paren 'at-full)
  (setq lispy-avy-style-symbol 'at-full)
  (setq lispy-completion-method 'helm)
  (setq lispy-occur-backend 'helm)
  (setq lispy-window-height-ratio 0.8))

(use-package clojure-mode
  :commands clojure-mode
  :config

  (use-package cider
    :config
    (add-to-list 'ac-modes 'cider-mode)

    ;; Hooks
    (add-hook 'cider-mode-hook #'eldoc-mode)
    (add-hook 'cider-mode-hook #'ac-cider-setup)
    (add-hook 'cider-repl-mode-hook #'ac-cider-setup)

    ;; Variables
    (setq cider-repl-history-file "~/.emacs.d/.cider-history")
    (setq cider-repl-use-pretty-printing t)
    (setq nrepl-buffer-name-show-port t))

  (add-hook 'clojure-mode-hook #'lispy-mnemonic-mode))

(use-package eldoc
  :commands eldoc-mode
  :config
  (setq eldoc-minor-mode-string ""))

; Hooks
(add-hook 'emacs-lisp-mode-hook #'eldoc-mode)
(add-hook 'emacs-lisp-mode-hook #'lispy-mnemonic-mode)
(add-hook 'emacs-lisp-mode-hook #'prettify-symbols-mode)
(add-hook 'eval-expression-minibuffer-setup-hook #'eldoc-mode)



;;;;;;;;;;;;;;;;;;;;;;;;;
;;; File Associations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package openwith
  :config
  (openwith-mode t)
  (setq openwith-associations
        (list (list (openwith-make-extension-regexp '("pdf" "ps"))
                    "okular" '(file))
              (list (openwith-make-extension-regexp '("flac" "mp3" "wav"))
                    "gmusicbrowser" '(file))
              (list (openwith-make-extension-regexp '("avi" "flv" "mov" "mp4"
                                                      "mpeg" "mpg" "ogg" "wmv"))
                    "vlc" '(file))
              (list (openwith-make-extension-regexp '("bmp" "jpeg" "jpg" "png"))
                    "gwenview" '(file))
              (list (openwith-make-extension-regexp '("chm"))
                    "kchmviewer" '(file))
              (list (openwith-make-extension-regexp '("doc" "docx" "odt"))
                    "libreoffice" '("--writer" file))
              (list (openwith-make-extension-regexp '("ods" "xls" "xlsx"))
                    "libreoffice" '("--calc" file))
              (list (openwith-make-extension-regexp '("odp" "pps" "ppt" "pptx"))
                    "libreoffice" '("--impress" file))
              (list (openwith-make-extension-regexp '("odg"))
                    "libreoffice" '("--draw" file))
              (list (openwith-make-extension-regexp '("dia"))
                    "dia" '(file)))))



;;;;;;;;;;;;;
;;; Fonts ;;;
;;;;;;;;;;;;;

(set-face-attribute 'default nil :font "Monaco-10")

; Unicode Fonts
(use-package unicode-fonts
  :config
  (unicode-fonts-setup))



;;;;;;;;;;;
;;; Fun ;;;
;;;;;;;;;;;

(use-package emoji-cheat-sheet-plus
  :commands (emoji-cheat-sheet-plus-buffer emoji-cheat-sheet-plus-insert)
  :init
  (add-hook 'markdown-mode-hook #'emoji-cheat-sheet-plus-display-mode)
  :config
  (modeline-remove-lighter 'emoji-cheat-sheet-plus-display-mode)

  ;; Key Bindings
  (bind-keys :map emoji-cheat-sheet-plus-buffer-mode-map
             ("b" . backward-char)
             ("f" . forward-char)
             ("n" . next-line)
             ("p" . previous-line)))



;;;;;;;;;;;;
;;; Helm ;;;
;;;;;;;;;;;;

(use-package helm
  :defer 5
  :bind (("C-c k" . helm-show-kill-ring)
         ("C-c SPC" . helm-all-mark-rings))
  :config

  (use-package helm-config
    :ensure helm
    :config
    (setq helm-apropos-fuzzy-match t)
    (setq helm-buffers-fuzzy-matching t)
    (setq helm-imenu-fuzzy-matching t)
    (setq helm-lisp-fuzzy-completion t)
    (setq helm-locate-fuzzy-match t)
    (setq helm-projectile-fuzzy-match t)
    (setq helm-recentf-fuzzy-match t)
    (setq helm-semantic-fuzzy-match t)
    (setq helm-M-x-fuzzy-match t))

  ;; Hydra
  (defhydra hydra-helm-github ()
    "GitHub"
    ("c" helm-open-github-from-commit "commit")
    ("f" helm-open-github-from-file "file")
    ("i" helm-open-github-from-issues "issue")
    ("p" helm-open-github-from-pull-requests "pull request")
    ("s" helm-github-stars "starred repo"))

  ;; Key Bindings
  (bind-key "g" #'hydra-helm-github/body helm-command-map)

  ;; Variables
  (setq helm-truncate-lines t))

(use-package helm-firefox
  :commands helm-firefox-bookmarks
  :config
  (defun helm-get-firefox-user-init-dir ()
    "Return name of Firefox profile to list bookmarks for."
    "~/.mozilla/firefox/mwad0hks.default/"))



;;;;;;;;;;;;
;;; Help ;;;
;;;;;;;;;;;;

(find-function-setup-keys)

(use-package guide-key
  :defer 5
  :config
  (guide-key-mode t)
  (modeline-remove-lighter 'guide-key-mode)
  (setq guide-key/guide-key-sequence '("C-c" "C-x" "M-s"))
  (setq guide-key/popup-window-position 'bottom)
  (setq guide-key/recursive-key-sequence-flag t))

; Functions
(defun info-display-topic (topic)
  "Create command that opens up a separate *info* buffer for TOPIC."
  (let* ((bufname (format "*%s Info*" (capitalize topic)))
         (cmd-name (format "info-display-%s" topic))
         (cmd (intern cmd-name)))
    (if (fboundp cmd)
        cmd
      (eval `(defun ,cmd ()
               ,(format "Jump to %s info buffer, creating it if necessary.\nThis is *not* the buffer \\[info] would jump to, it is a separate entity." topic)
               (interactive)
               (if (get-buffer ,bufname)
                   (switch-to-buffer ,bufname)
                 (info ,topic ,bufname)))))))

; Hydra
(defhydra hydra-apropos (:color blue)
  "Apropos"
  ("a" apropos "apropos")
  ("c" apropos-command "cmd")
  ("d" apropos-documentation "doc")
  ("e" apropos-value "val")
  ("l" apropos-library "lib")
  ("o" apropos-user-option "opt")
  ("v" apropos-variable "var")
  ("i" info-apropos "info")
  ("t" tags-apropos "tags")
  ("z" hydra-customize-apropos/body "customize"))

(defhydra hydra-customize-apropos (:color blue)
  "Apropos (customize)"
  ("a" customize-apropos "apropos")
  ("f" customize-apropos-faces "faces")
  ("g" customize-apropos-groups "groups")
  ("o" customize-apropos-options "options"))

(defhydra hydra-info (:color blue)
  "Info"
  ("e" (funcall (info-display-topic "emacs")) "Emacs")
  ("l" (funcall (info-display-topic "elisp")) "Elisp")
  ("m" (funcall (info-display-topic "magit")) "Magit")
  ("o" (funcall (info-display-topic "org")) "Org Mode")
  ("s" (funcall (info-display-topic "sicp")) "SICP"))

; Key Bindings
(global-set-key (kbd "C-h a") #'hydra-apropos/body)
(define-key custom-keys-mode-prefix-map (kbd "i") #'hydra-info/body)

; Variables
(setq help-window-select t)
(setq apropos-sort-by-scores t)
(setq find-function-C-source-directory "~/emacs-24.4/src/")



;;;;;;;;;;;;
;;; HTML ;;;
;;;;;;;;;;;;

(use-package sgml-mode
  :commands sgml-mode
  :config
  (bind-key "C-c b" #'web-beautify-html sgml-mode-map))



;;;;;;;;;;;;;
;;; Hydra ;;;
;;;;;;;;;;;;;

(use-package hydra
  :defer t
  :config
  (when (eq (car custom-enabled-themes) 'sanityinc-tomorrow-eighties)
    (set-face-attribute 'hydra-face-blue nil :foreground "#6699cc")))



;;;;;;;;;;;
;;; Ido ;;;
;;;;;;;;;;;

(use-package ido
  :bind (("C-x b" . ido-switch-buffer)
         ("C-x d" . ido-dired)
         ("C-x C-f" . ido-find-file))
  :config

  (use-package flx-ido
    :config
    (flx-ido-mode 1))

  (use-package ido-ubiquitous
    :config

    (use-package ido-completing-read+
      :config
      (setq ido-cr+-max-items 50000))

    (ido-ubiquitous-mode 1)

    ;; Variables
    (push '(disable exact "unhighlight-regexp") ido-ubiquitous-command-overrides)
    (push '(disable prefix "sclang-dump-") ido-ubiquitous-command-overrides))

  (use-package recentf
    :commands recentf-mode
    :config
    ;; Advice
    (defun recentf-discard-autoloads (orig file)
      (if (not (string-match-p "-autoloads" (file-name-nondirectory file)))
          (funcall orig file)
        nil))

    (advice-add 'recentf-keep-default-predicate :around #'recentf-discard-autoloads)

    (defun recentf-set-buffer-file-name (orig)
      (if (eq major-mode 'dired-mode)
          (progn (setq buffer-file-name default-directory)
                 (funcall orig)
                 (setq buffer-file-name nil))
        (funcall orig)))

    (advice-add 'recentf-track-opened-file :around #'recentf-set-buffer-file-name)
    (advice-add 'recentf-track-closed-file :around #'recentf-set-buffer-file-name)

    ;; Commands
    (defun ido-recentf-open ()
      "Use `ido-completing-read' to \\[find-file] a recent file."
      (interactive)
      (if (find-file (ido-completing-read "Find recent file: " recentf-list))
          (message "Opening file...")
        (message "Aborting")))

    ;; Key Bindings
    (bind-key "C-x C-r" #'ido-recentf-open)

    ;; Variables
    (add-to-list 'recentf-used-hooks
                 '(dired-after-readin-hook recentf-track-opened-file))
    (setq recentf-max-saved-items 150)
    (setq recentf-save-file "~/.emacs.d/.recentf"))

  (ido-mode 'both)
  (ido-everywhere 1)
  (recentf-mode t)

  ;; Commands
  (defun ido-find-file-as-root ()
    "Like `ido-find-file', but automatically edit file with
  root-privileges if it is not writable by user."
    (interactive)
    (let ((file (ido-read-file-name "Edit as root: ")))
      (unless (file-writable-p file)
        (setq file (concat "/su:root@localhost:" file)))
      (find-file file)))

  ;; Key Bindings
  (bind-key "C-c f" #'ido-find-file-as-root)

  ;; Variables
  (add-to-list 'ido-ignore-buffers "\*Compile-Log\*")
  (add-to-list 'ido-ignore-buffers "\*Messages\*")
  (setq ido-create-new-buffer 'always)
  (setq ido-enable-flex-matching t)
  (setq ido-save-directory-list-file "~/.emacs.d/.ido.last")
  (setq ido-use-virtual-buffers t))

(use-package smex
  :bind (("M-x" . smex)
         ("<menu>" . smex-major-mode-commands))
  :config
  (setq smex-save-file "~/.emacs.d/.smex-items"))

; Variables
(setq gc-cons-threshold 7000000)



;;;;;;;;;;;;;;;;;
;;; Interface ;;;
;;;;;;;;;;;;;;;;;

(use-package linum
  :commands linum-mode
  :config

  (use-package linum-relative
    :config
    (let ((default-background-color (face-attribute 'default :background)))
      (set-face-attribute
       'linum-relative-current-face nil :background default-background-color)))

  ;; Faces
  (let ((default-background-color (face-attribute 'default :background)))
    (set-face-attribute 'linum nil :background default-background-color)))

(use-package rainbow-delimiters
  :config
  (add-hook 'org-mode-hook #'rainbow-delimiters-mode)
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(use-package whitespace
  :commands whitespace-mode
  :config
  (modeline-remove-lighter 'whitespace-mode)

  ;; Hooks
  (add-hook 'prog-mode-hook #'whitespace-mode)

  ;; Variables
  (setq whitespace-line-column nil)
  (setq whitespace-style '(face lines-tail)))

; Controls
(set-scroll-bar-mode nil)
(menu-bar-mode 0)
(tool-bar-mode 0)

; Cursor
(blink-cursor-mode -1)

(defvar default-cursor-color "#F2777A")
(defvar expandable-thing-before-point-color "#00FF7F")

; Theme
(defun customize-enabled-theme ()
  (let ((enabled-theme (car custom-enabled-themes))
        (cursor-preferred-color "#FF5A0E"))
    (cond ((eq enabled-theme 'base16-default)
           (set-cursor-color cursor-preferred-color))
          ((eq enabled-theme 'tronesque)
           (let ((fallback-color
                  (face-attribute 'show-paren-match :background)))
             (set-face-attribute
              'dired-directory nil :foreground fallback-color)
             (set-face-attribute
              'info-header-xref nil :foreground fallback-color)))
          ((eq enabled-theme 'wombat)
           (set-cursor-color cursor-preferred-color)))))

(defun customize-theme ()
  (let ((default-background-color (face-attribute 'default :background)))
    (set-face-attribute 'fringe nil :background default-background-color)))

(defun disable-custom-themes (theme &optional no-confirm no-enable)
  (mapc 'disable-theme custom-enabled-themes))

(advice-add 'load-theme :before #'disable-custom-themes)

(defun load-custom-theme-settings (theme &optional no-confirm no-enable)
  (customize-theme)
  (customize-enabled-theme))

(advice-add 'load-theme :after #'load-custom-theme-settings)

(load-theme 'sanityinc-tomorrow-eighties t)

; Tooltips
(tooltip-mode 0)

; Variables
(setq inhibit-startup-screen t)
(setq initial-scratch-message
      ";; Parentheses are just *hugs* for your function calls!\n\n")



;;;;;;;;;;;;;;;;;;;;;;;;
;;; Java Development ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

(use-package java
  :disabled
  :ensure nil)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; JavaScript Development ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package js2-mode
  :mode "\\.js\\'"
  :config

  (use-package js2-refactor
    :config
    (js2r-add-keybindings-with-prefix "C-c C-r"))

  (use-package tern
    :load-path "/usr/lib/node_modules/tern/emacs/"
    :ensure nil
    :config

    (use-package tern-auto-complete
      :load-path "/usr/lib/node_modules/tern/emacs/"
      :ensure nil
      :config
      (tern-ac-setup))

    ;; Commands
    (defun tern-delete-process ()
      (interactive)
      (delete-process "Tern"))

    ;; Key Bindings
    (unbind-key "C-c C-d" tern-mode-keymap)
    (unbind-key "C-c C-r" tern-mode-keymap)
    (bind-keys :prefix-map tern-mode-prefix-keymap
               :prefix "C-c C-t"
               :map tern-mode-keymap
               ("d" . tern-get-docs)
               ("h" . tern-highlight-refs)
               ("r" . tern-rename-variable)
               ("t" . tern-get-type)
               ("." . tern-find-definition)
               (":" . tern-find-definition-by-name)
               ("," . tern-pop-find-definition)
               ("TAB" . tern-ac-complete)))

  ;; Hooks
  (add-hook 'js2-mode-hook #'ac-js2-mode)
  (add-hook 'js2-mode-hook #'flycheck-mode)
  (add-hook 'js2-mode-hook #'js2-imenu-extras-mode)
  (add-hook 'js2-mode-hook #'tern-mode)

  ;; Key Bindings
  (unbind-key "C-c C-t" js2-mode-map)
  (bind-keys :map js2-mode-map
             ("RET" . js2-line-break)
             ("C-a" . js2-beginning-of-line)
             ("C-e" . js2-end-of-line)
             ("C-c b" . web-beautify-js)
             ("C-c C-e" . js2-mode-toggle-element)
             ("C-c C-l" . js2-display-error-list)
             ("C-c C-o" . js2-mode-toggle-hide-comments)
             ("C-x n d" . js2-narrow-to-defun)
             ("C-M-f" . js2-mode-forward-sexp)
             ("C-M-h" . js2-mark-defun)
             ("M-k" . js2r-kill))
  (bind-key "j n" #'js2-next-error custom-keys-mode-prefix-map)

  ;; Variables
  (setq-default js2-basic-offset 2)
  (setq js2-global-externs '("$" "jQuery" "_"))
  (setq js2-highlight-level 3)
  (setq js2-pretty-multiline-declarations 'dynamic))



;;;;;;;;;;;;;
;;; LaTeX ;;;
;;;;;;;;;;;;;

; TeX
(use-package tex-mode
  :commands latex-mode
  :config

  ; AUCTeX
  (use-package tex
    :ensure auctex
    :commands TeX-PDF-mode
    :config
    (setq-default TeX-master nil))

  (TeX-PDF-mode 1)
  (outline-minor-mode 1))

; BibTeX
(use-package bibtex
  :commands bibtex-mode
  :config
  (setq bibtex-maintain-sorted-entries t))



;;;;;;;;;;;;;;;;;;
;;; Minibuffer ;;;
;;;;;;;;;;;;;;;;;;

; Modes
(minibuffer-depth-indicate-mode 1)
(savehist-mode t)

; Prompts
(fset 'yes-or-no-p 'y-or-n-p)

; Variables
(setq echo-keystrokes 0.3)
(setq enable-recursive-minibuffers t)
(setq history-delete-duplicates t)
(setq history-length t)
(setq minibuffer-prompt-properties
      (append minibuffer-prompt-properties
              '(point-entered minibuffer-avoid-prompt)))



;;;;;;;;;;;;;;;;
;;; Modeline ;;;
;;;;;;;;;;;;;;;;

(use-package nyan-mode
  :config
  (nyan-mode t)
  (setq nyan-bar-length 16))

(use-package uniquify
  :ensure nil
  :defer t
  :config
  (setq uniquify-buffer-name-style 'forward))

; Functions
(defun modeline-set-lighter (minor-mode lighter)
  (when (assq minor-mode minor-mode-alist)
    (setcar (cdr (assq minor-mode minor-mode-alist)) lighter)))

(defun modeline-remove-lighter (minor-mode)
  (modeline-set-lighter minor-mode ""))

; Modes
(column-number-mode t)

; Variables
(setf (nth 5 mode-line-modes)
      '(:eval (if (buffer-narrowed-p) (string 32 #x27fa) "")))



;;;;;;;;;;;;;
;;; Modes ;;;
;;;;;;;;;;;;;

(add-to-list 'auto-mode-alist '("routes$" . conf-space-mode))



;;;;;;;;;;;;;;;;
;;; Movement ;;;
;;;;;;;;;;;;;;;;

(use-package avy
  :defer t
  :config
  ;; Commands
  (defun avy-move-region ()
    "Select two lines and move the text between them here."
    (interactive)
    (avy--with-avy-keys avy-move-region
      (let ((beg (car (avy--line)))
            (end (car (avy--line)))
            (pad (if (bolp) "" "\n")))
        (move-beginning-of-line nil)
        (save-excursion
          (save-excursion
            (goto-char end)
            (kill-region beg (line-end-position))
            (delete-char -1))
          (insert
           (current-kill 0)
           pad)))))

  ;; Hydra
  (defhydra hydra-avy-jump (:color blue)
    "Avy jump"
    ("c" avy-goto-char "char")
    ("w" avy-goto-word-0 "word")
    ("l" avy-goto-line "line")
    ("s" avy-goto-subword-0 "subword")
    ("C" goto-char "goto char")
    ("L" goto-line "goto line"))

  (defhydra hydra-avy-copy (:color blue)
    "Avy copy"
    ("l" avy-copy-line "line")
    ("r" avy-copy-region "region"))

  (defhydra hydra-avy-move (:color blue)
    "Avy move"
    ("l" avy-move-line "line")
    ("r" avy-move-region "region"))

  ;; Key Bindings
  (bind-key "M-g" #'hydra-avy-jump/body)
  (bind-keys :map custom-keys-mode-prefix-map
             ("C-w" . hydra-avy-move/body)
             ("M-w" . hydra-avy-copy/body))
  (bind-key "M-s a" #'avy-isearch isearch-mode-map)

  ;; Variables
  (setq avy-background t)
  (setq avy-keys (number-sequence ?a ?z))
  (setq avy-style 'at-full))

(defhydra hydra-move-by-page ()
  "Move by page"
  ("[" backward-page "prev page")
  ("]" forward-page "next page"))

(global-set-key (kbd "C-x [") #'hydra-move-by-page/body)
(global-set-key (kbd "C-x ]") #'hydra-move-by-page/body)



;;;;;;;;;;;;;;;;
;;; Org Mode ;;;
;;;;;;;;;;;;;;;;

(use-package org
  :ensure org-plus-contrib
  :commands org-mode
  :bind (("C-c a" . org-agenda)
         ("C-c l" . org-store-link))
  :config

  (use-package ob-ditaa
    :disabled
    :config
    (add-to-list 'org-babel-load-languages '(ditaa . t) t)
    (setq org-ditaa-jar-path "/usr/share/java/ditaa/ditaa-0_9.jar"))

  (use-package ob-plantuml
    :disabled
    :config

    (use-package plantuml-mode
      :config
      (setq plantuml-jar-path "/opt/plantuml/plantuml.jar"))

    (add-to-list 'org-babel-load-languages '(plantuml . t) t)
    (setq org-plantuml-jar-path "/opt/plantuml/plantuml.jar"))

  (use-package org-ac
    :config
    (org-ac/config-default)
    (setq org-ac/ac-trigger-command-keys '("\\" "SPC" ":" "[" "+")))

  (use-package org-agenda
    :ensure nil
    :config
    (setq org-agenda-files '("~/org/tasks.org")))

  (use-package org-capture
    :ensure nil
    :bind ("C-c c" . org-capture)
    :config
    ;; Functions
    (defun format-quote (selection)
      (if (= (length selection) 0)
          ""
        (format "#+BEGIN_QUOTE\n  %s\n  #+END_QUOTE\n\n  " selection)))

    ;; Variables
    (setq org-capture-templates
          '(("j" "Journal" entry (file+datetree "~/org/journal.org")
             "* %<%H:%M>\n%?")
            ("l" "Link" entry (file+datetree "~/org/links.org")
             "* %^{Title}\n  Source: %u, %c\n\n  %(format-quote \"%:initial\")%?"
             :kill-buffer t)
            ("z" "Quote" plain (file "~/org/quotes.org")
             "%?\n\n-" :empty-lines-before 2 :kill-buffer t))))

  (use-package org-footnote
    :ensure nil
    :config
    (setq org-footnote-define-inline t)
    (setq org-footnote-auto-label 'random))

  (use-package org-list
    :ensure nil
    :config
    ;; Advice
    (swap-args 'org-toggle-checkbox)

    ;; Key Bindings
    (bind-keys :map org-mode-map
               ("M-n" . org-next-item)
               ("M-p" . org-previous-item))

    ;; Variables
    (setq org-cycle-include-plain-lists 'integrate)
    (setq org-list-allow-alphabetical t)
    (setq org-list-demote-modify-bullet '(("-" . "+") ("+" . "-")))
    (setq org-list-use-circular-motion t))

  (use-package ox
    :ensure nil
    :commands org-export-dispatch
    :config
    (setq org-export-copy-to-kill-ring nil)
    (setq org-export-dispatch-use-expert-ui t)

    (use-package ox-latex
      :ensure nil
      :config
      (setq org-latex-table-caption-above nil))

    (use-package ox-md
      :ensure nil)

    (use-package ox-gfm))

  ;; Advice
  (defun org-handle-openwith (orig &optional include-linked refresh beg end)
    (openwith-mode -1)
    (funcall orig include-linked refresh beg end)
    (openwith-mode 1))

  (advice-add 'org-display-inline-images :around #'org-handle-openwith)

  (defun org-add-tags (property value)
    (let* ((props (org-entry-properties))
           (unnumbered (assoc "UNNUMBERED" props))
           (tags-entry (assoc "TAGS" props))
           (tags (if tags-entry (cdr tags-entry) "")))
      (when (and unnumbered (not (string-match-p ":notoc:" tags)))
        (org-set-tags-to (concat tags "notoc")))))

  (advice-add 'org-set-property :after #'org-add-tags)

  (defun org-export-unnumbered (orig headline info)
    (and (funcall orig headline info)
         (not (org-element-property :UNNUMBERED headline))))

  (advice-add 'org-export-numbered-headline-p :around #'org-export-unnumbered)

  (defun org-remove-tags (property)
    (let* ((props (org-entry-properties))
           (unnumbered (assoc "UNNUMBERED" props))
           (tags-entry (assoc "TAGS" props))
           (tags (if tags-entry (cdr tags-entry) "")))
      (when (and (not unnumbered) (string-match-p ":notoc:" tags))
        (org-set-tags-to (replace-regexp-in-string ":notoc:" "" tags)))))

  (advice-add 'org-delete-property :after #'org-remove-tags)

  ;; Babel
  (add-to-list 'org-babel-load-languages '(sh . t) t)
  (add-to-list 'org-babel-load-languages '(dot . t) t)
  (add-to-list 'org-babel-load-languages '(python . t) t)

  (org-babel-do-load-languages
   'org-babel-load-languages org-babel-load-languages)

  ;; Commands
  (defvar org-blocks-hidden nil)
  (defvar org-generic-drawer-regexp "^ +:[[:alpha:]]+:")

  (defun org-back-to-item ()
    (interactive)
    (re-search-backward "^ *[-+*]\\|^ *[1-9]+[)\.] " nil nil 1))

  (defun org-copy-link ()
    "Copy `org-mode' link at point."
    (interactive)
    (when (org-in-regexp org-bracket-link-regexp 1)
      (let ((link (org-link-unescape (org-match-string-no-properties 1))))
        (kill-new link)
        (message "Copied link: %s" link))))

  (defun org-export-all ()
    "Export all subtrees that are *not* tagged with :noexport:
  or :subtree: to separate files.

  Note that subtrees must have the :EXPORT_FILE_NAME: property set
  to a unique value for this to work properly."
    (interactive)
    (org-map-entries (lambda () (org-html-export-to-html nil t))
                     "-noexport-subtree"))

  (defun org-fill-paragraph-handle-lists (&optional num-paragraphs)
    (interactive "p")
    (save-excursion
      (let ((bound (if mark-active
                       (- (region-end) 2)
                     (progn
                       (org-back-to-item)
                       (while (>= num-paragraphs 0)
                         (call-interactively #'org-mark-element)
                         (setq num-paragraphs (1- num-paragraphs)))
                       (- (region-end) 2)))))
        (while (search-forward "\n" bound t)
          (replace-match " ")))
      (org-fill-paragraph)))

  (defun org-interleave ()
    (interactive)
    (unless (featurep 'pdf-view)
      (pdf-tools-install))
    (if (and (featurep 'interleave) interleave)
        (message "Interleave is already running.")
      (interleave)))

  (defun org-next-drawer (arg)
    (interactive "p")
    (org-next-block arg nil org-generic-drawer-regexp))

  (defun org-previous-drawer (arg)
    (interactive "p")
    (org-previous-block arg org-generic-drawer-regexp))

  (defun org-toggle-blocks ()
    (interactive)
    (if org-blocks-hidden
        (org-show-block-all)
      (org-hide-block-all))
    (setq-local org-blocks-hidden (not org-blocks-hidden)))

  ;; Emphasis
  (setcar org-emphasis-regexp-components " \t('\"`{-")
  (setcar (nthcdr 1 org-emphasis-regexp-components) "\[[:alpha:]- \t.,:!?;'\")}\\")
  (org-set-emph-re 'org-emphasis-regexp-components org-emphasis-regexp-components)

  ;; Faces
  (set-face-attribute 'org-done nil :strike-through t)
  (set-face-attribute 'org-headline-done nil :strike-through t)
  (when (eq (car custom-enabled-themes) 'sanityinc-tomorrow-eighties)
    (set-face-attribute 'org-block-begin-line nil :background "#393939")
    (set-face-attribute 'org-block-end-line nil :background "#393939"))

  ;; Functions
  (defvar org-bold-markup '(?\* . ?\*))
  (defvar org-italics-markup '(?/ . ?/))
  (defvar org-verbatim-markup '(?= . ?=))

  (defun org-add-electric-pairs ()
    (let ((org-electric-pairs `(,org-verbatim-markup
                                ,org-italics-markup
                                ,org-bold-markup)))
      (setq-local electric-pair-pairs
                  (append electric-pair-pairs org-electric-pairs))
      (setq-local electric-pair-text-pairs electric-pair-pairs)))

  (defun org-point-in-speed-command-position-p ()
    (or (looking-at org-outline-regexp)
        (looking-at "^#\+")
        (looking-at "^[[:blank:]]\\{2,\\}")
        (looking-at "^$")))

  ;; Hooks
  (add-hook 'org-mode-hook #'org-add-electric-pairs)
  (add-hook 'org-mode-hook #'org-toggle-blocks)
  (add-hook 'org-mode-hook #'turn-on-auto-fill)
  (add-hook 'org-mode-hook #'which-function-mode)

  ;; Key Bindings
  (defvar org-mode-extra-keys-map (lookup-key org-mode-map (kbd "C-c C-x")))
  (bind-keys :map org-mode-extra-keys-map
             ("c" . org-table-copy-down)
             ("d" . org-metadown)
             ("l" . org-metaleft)
             ("r" . org-metaright)
             ("u" . org-metaup)
             ("D" . org-shiftmetadown)
             ("L" . org-shiftmetaleft)
             ("R" . org-shiftmetaright)
             ("U" . org-shiftmetaup))
  (bind-keys :map org-mode-map
             ("<C-tab>" . pcomplete)
             ("RET" . org-return-indent)
             ("C-c c" . org-wrap-in-comment-block)
             ("C-c d" . org-toggle-link-display)
             ("C-M-h" . org-mark-element)
             ("C-M-q" . org-fill-paragraph-handle-lists)
             ("M-h" . mark-paragraph)
             ("M-s TAB" . org-force-cycle-archived)
             ("M-s t b" . org-toggle-blocks)
             ("M-s t h" . org-insert-todo-heading)
             ("M-s t s" . org-insert-todo-subheading)
             ("s-d" . org-shiftdown)
             ("s-l" . org-shiftleft)
             ("s-r" . org-shiftright)
             ("s-u" . org-shiftup))

  ;; Keyboard Macros
  (fset 'org-wrap-in-comment-block
        [?\C-o tab ?< ?o tab ?\C-w ?\C-w ?\C-u ?\C-x ?q ?\C-y ?\C-p ?\C-p ?\C-w ?\C-e ?\C-f])

  ;; Variables
  (setq org-blank-before-new-entry '((heading . t) (plain-list-item . auto)))
  (setq org-catch-invisible-edits 'error)
  (setq org-completion-use-ido t)
  (setq org-confirm-babel-evaluate nil)
  (setq org-edit-src-content-indentation 0)
  (setq org-enforce-todo-checkbox-dependencies t)
  (setq org-enforce-todo-dependencies t)
  (setq org-file-apps '((auto-mode . emacs) ("\\.pdf\\'" . emacs)))
  (setq org-fontify-done-headline t)
  (setq org-log-into-drawer t)
  (setq org-M-RET-may-split-line '((headline . nil) (item . t) (table . t)))
  (setq org-outline-path-complete-in-steps nil)
  (setq org-return-follows-link t)
  (setq org-special-ctrl-a/e 'reversed)
  (setq org-special-ctrl-k t)
  (setq org-src-fontify-natively t)
  (setq org-src-strip-leading-and-trailing-blank-lines t)
  (setq org-todo-repeat-to-state "RECURRING")
  (setq org-track-ordered-property-with-tag t)
  (setq org-use-speed-commands 'org-point-in-speed-command-position-p)
  (add-to-list 'org-speed-commands-user '("d" . org-next-drawer) t)
  (add-to-list 'org-speed-commands-user '("P" . org-previous-drawer) t)
  (add-to-list 'org-structure-template-alist
               '("o" "#+BEGIN_COMMENT\n?\n#+END_COMMENT") t))

(use-package org-drill
  :ensure org-plus-contrib
  :commands org-drill
  :config
  (setq org-drill-scope 'directory)
  (setq org-drill-hide-item-headings-p t))

(use-package org-protocol
  :ensure org-plus-contrib
  :defer 5)



;;;;;;;;;;;;;;;;;;;;;;;
;;; Package Manager ;;;
;;;;;;;;;;;;;;;;;;;;;;;

(use-package package
  :commands list-packages
  :config
  (add-to-list 'package-archives
               '("marmalade" . "https://marmalade-repo.org/packages/") t)
  (add-to-list 'package-archives
               '("melpa" . "http://melpa.org/packages/") t)
  (add-to-list 'package-archives
               '("org" . "http://orgmode.org/elpa/") t))

(use-package paradox
  :commands paradox-list-packages
  :config
  (setq paradox-automatically-star nil)
  (setq paradox-execute-asynchronously nil))



;;;;;;;;;;;;
;;; PDFs ;;;
;;;;;;;;;;;;

(use-package doc-view
  :commands doc-view-mode
  :init
  (add-hook 'doc-view-mode-hook #'pdf-tools-install)
  :config
  (setq doc-view-continuous t))

(use-package interleave
  :commands interleave
  :config
  (defun interleave-handle-openwith (orig &optional arg)
    (openwith-mode -1)
    (funcall orig arg)
    (openwith-mode 1))

  (advice-add 'interleave :around #'interleave-handle-openwith)

  (defun interleave--quit-handle-emojis (orig)
    (with-current-buffer *interleave--org-buffer*
      (emoji-cheat-sheet-plus-display-mode -1))
    (funcall orig)
    (with-current-buffer *interleave--org-buffer*
      (emoji-cheat-sheet-plus-display-mode 1)))

  (advice-add 'interleave--quit :around #'interleave--quit-handle-emojis))

(use-package pdf-tools
  :commands pdf-tools-install
  :config
  ;; Advice
  (defun pdf-outline-prepare-windows (&optional buffer no-select-window-p)
    (delete-other-windows)
    (split-window-right)
    (other-window 1))

  (advice-add 'pdf-outline :before #'pdf-outline-prepare-windows)

  (defun pdf-outline-adjust-window (&optional buffer no-select-window-p)
    (let ((current-width (window-total-width)))
      (when (> current-width 50)
        (shrink-window-horizontally (- current-width 50)))))

  (advice-add 'pdf-outline :after #'pdf-outline-adjust-window)

  ;; Variables
  (setq pdf-info-restart-process-p t)
  (setq pdf-util-fast-image-format '("png" . ".png")))



;;;;;;;;;;;;;;;;;;;
;;; Permissions ;;;
;;;;;;;;;;;;;;;;;;;

(use-package tramp
  :defer 5
  :commands ido-find-file)

; Usage: C-x C-f /sudo::/path/to/file



;;;;;;;;;;;;;;;;;;;
;;; Programming ;;;
;;;;;;;;;;;;;;;;;;;

(use-package flycheck
  :commands flycheck-mode
  :config
  ;; Functions
  (defun flycheck-mode-line-status-text (&optional status)
    "Get a text describing STATUS for use in the mode line.

  STATUS defaults to `flycheck-last-status-change' if omitted or nil."
    (let ((text (pcase (or status flycheck-last-status-change)
                  (`not-checked "")
                  (`no-checker "-")
                  (`running "*")
                  (`errored "!")
                  (`finished
                   (if flycheck-current-errors
                       (let-alist (flycheck-count-errors flycheck-current-errors)
                         (format ":%s/%s" (or .error 0) (or .warning 0)))
                     ""))
                  (`interrupted "-")
                  (`suspicious "?"))))
      (concat " ⚡" text)))

  (defun flycheck-setup ()
    (bind-keys :map custom-keys-mode-prefix-map
               ("f n" . flycheck-next-error)
               ("f p" . flycheck-previous-error)))

  ;; Hooks
  (add-hook 'flycheck-mode-hook #'flycheck-setup))

(use-package helm-dash
  :bind ("C-c d" . helm-dash-at-point)
  :init
  ;; Macros
  (defvar-local helm-dash-docsets nil)

  (defmacro helm-dash-setup (language docsets)
    "Create function that sets up `helm-dash' for specific LANGUAGE."
    (let ((fn-name (intern (format "helm-dash-%s" language)))
	  (current-docsets (mapconcat 'identity docsets ", ")))
      `(progn
	 (defun ,fn-name ()
	   ,(format "Set up `helm-dash' for %s.\n\nDocsets: %s"
		    language current-docsets)
	   (setq helm-dash-docsets ,docsets)
	   (setq helm-current-buffer (current-buffer))))))

  ;; Hooks
  (add-hook 'sh-mode-hook (helm-dash-setup "bash" ["Bash"]))
  (add-hook 'clojure-mode-hook (helm-dash-setup "clojure" ["Clojure"]))
  (add-hook 'java-mode-hook (helm-dash-setup "java" ["Android" "Java" "Play_Java"]))
  (add-hook 'LaTeX-mode-hook (helm-dash-setup "latex" ["LaTeX"]))
  (add-hook 'python-mode-hook (helm-dash-setup "python" ["Django" "Python 2" "Python 3"]))
  (add-hook 'inferior-python-mode-hook (helm-dash-setup "python" ["Django" "Python 2" "Python 3"]))
  (add-hook 'css-mode-hook (helm-dash-setup "css" ["Bootstrap 3" "CSS"]))
  (add-hook 'haml-mode-hook (helm-dash-setup "haml" ["Bootstrap 3" "HTML"]))
  (add-hook 'html-mode-hook (helm-dash-setup "html" ["Bootstrap 3" "HTML"]))
  (add-hook 'js2-mode-hook (helm-dash-setup "js" ["BackboneJS" "Bootstrap 3" "JavaScript" "jQuery" "UnderscoreJS"]))

  ;; Variables
  (setq helm-dash-common-docsets '("Emacs Lisp" "MySQL" "PostgreSQL" "SQLite"))
  (setq helm-dash-docsets-path "/storage/docsets/")
  (setq helm-dash-min-length 2))

(use-package yasnippet
  :commands yas-minor-mode
  :init
  (add-hook 'org-mode-hook #'yas-minor-mode)
  (add-hook 'prog-mode-hook #'yas-minor-mode)
  :config

  (use-package helm-c-yasnippet
    :bind ("C-c y" . helm-yas-complete)
    :config
    (setq helm-yas-not-display-dups nil)
    (setq helm-yas-display-key-on-candidate t))

  (yas-reload-all)
  (modeline-remove-lighter 'yas-minor-mode)

  ;; Functions
  (defun change-cursor-color-when-can-expand ()
    (set-cursor-color (if (last-thing-expandable-p)
			  expandable-thing-before-point-color
			default-cursor-color)))

  (defun last-thing-expandable-p ()
    (or (abbrev--before-point) (yasnippet-can-fire-p)))

  (defun yasnippet-can-fire-p (&optional field)
    (setq yas--condition-cache-timestamp (current-time))
    (let (relevant-snippets)
      (unless (and yas-expand-only-for-last-commands
		   (not (member last-command yas-expand-only-for-last-commands)))
	(setq relevant-snippets (if field
				    (save-restriction
				      (narrow-to-region (yas--field-start field)
							(yas--field-end field))
				      (yas--templates-for-key-at-point))
				  (yas--templates-for-key-at-point)))
	(and relevant-snippets (first relevant-snippets)))))

  ;; Hooks
  (add-hook 'post-command-hook #'change-cursor-color-when-can-expand)

  ;; Variables
  (add-to-list 'ac-sources 'ac-source-yasnippet)
  (setq yas-prompt-functions '(yas-ido-prompt yas-x-prompt yas-no-prompt))
  (setq yas-triggers-in-field t))

; Commands
(defun tim/electric-semicolon ()
  (interactive)
  (end-of-line)
  (when (not (looking-back ";"))
    (insert ";")))

(defun tim/enable-electric-semicolon ()
  (local-set-key (kbd ";") #'tim/electric-semicolon))

; Functions
(defun subword-setup ()
  (subword-mode 1)
  (modeline-remove-lighter 'subword-mode))

; Hooks
(add-hook 'java-mode-hook #'tim/enable-electric-semicolon)
(add-hook 'js2-mode-hook #'tim/enable-electric-semicolon)
(add-hook 'prog-mode-hook #'subword-setup)
(add-hook 'prog-mode-hook #'which-function-mode)

; Variables
(setq-default indent-tabs-mode nil)
(show-paren-mode t)



;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Project Management ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package projectile
  :defer 5
  :commands (projectile-find-file projectile-switch-project)
  :config

  (use-package helm-projectile
    :config
    (helm-projectile-on))

  (projectile-global-mode 1)

  ;; Variables
  (add-to-list 'projectile-globally-ignored-directories "doxygen")
  (setq projectile-cache-file "~/.emacs.d/.projectile.cache")
  (setq projectile-completion-system 'helm)
  (setq projectile-enable-caching t)
  (setq projectile-known-projects-file "~/.emacs.d/.projectile-bookmarks.eld")
  (setq projectile-mode-line
        '(:eval (format " %s[%s]"
                        (string #x1f5c0) (projectile-project-name)))))



;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Python Development ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package python
  :commands python-mode
  :config

  (use-package flycheck-pyflakes
    :config
    (add-to-list 'flycheck-disabled-checkers 'python-flake8)
    (add-to-list 'flycheck-disabled-checkers 'python-pylint))

  (use-package jedi
    :config

    (use-package jedi-direx
      :commands jedi-direx:pop-to-buffer)

    ;; Hooks
    (add-hook 'jedi-mode-hook #'jedi-direx:setup)

    ;; Key Bindings
    (bind-keys :map jedi-mode-map
               ("C-(" . jedi:get-in-function-call)
               ("C-)" . jedi:get-in-function-call)
               ("C-x D" . jedi-direx:pop-to-buffer))

    ;; Variables
    (setq jedi:complete-on-dot t)
    (setq jedi:get-in-function-call-delay 200)
    (setq jedi:use-shortcuts t))

  (use-package pony-mode
    :commands pony-mode
    :config
    ;; Commands
    (defun pony-shell-switch-to-shell ()
      (interactive)
      (let ((pony-shell-buffer (get-buffer "*ponysh*")))
        (if pony-shell-buffer
            (pop-to-buffer pony-shell-buffer)
          (call-interactively #'pony-shell))))

    ;; Key Bindings
    (bind-key "C-c C-p s" #'pony-shell-switch-to-shell pony-minor-mode-map))

  (use-package wenote
    :ensure nil)

  ;; Hooks
  (add-hook 'python-mode-hook #'flycheck-mode)
  (add-hook 'python-mode-hook #'jedi:setup)

  ;; Key Bindings
  (unbind-key "C-c C-f" python-mode-map)
  (unbind-key "C-c C-j" python-mode-map)
  (unbind-key "C-c C-l" python-mode-map)
  (unbind-key "C-c C-p" python-mode-map)
  (unbind-key "C-c C-s" python-mode-map)
  (unbind-key "C-c C-z" python-mode-map)
  (bind-keys :map python-mode-map
             ("M-a" . python-nav-backward-block) ; Default
             ("M-e" . python-nav-forward-block) ; Default
             ("C-M-a" . python-nav-backward-defun)
             ("C-M-b" . python-nav-backward-sexp-safe)
             ("C-M-e" . python-nav-forward-defun)
             ("C-M-f" . python-nav-forward-sexp-safe)
             ("C-M-u" . python-nav-backward-up-list) ; Default
             ("H-a" . python-nav-beginning-of-statement)
             ("H-b" . python-nav-backward-statement)
             ("H-e" . python-nav-end-of-statement)
             ("H-f" . python-nav-forward-statement)
             ("C-c RET" . python-nav-if-name-main)
             ("C-c C-c" . python-shell-switch-to-shell)
             ("C-c C-d" . python-eldoc-at-point)
             ("C-c C-r" . run-python)
             ("C-c C-s b" . python-shell-send-buffer)
             ("C-c C-s d" . python-shell-send-defun)
             ("C-c C-s f" . python-shell-send-file)
             ("C-c C-s r" . python-shell-send-region)
             ("C-c C-s s" . python-shell-send-string))

  ;; Variables
  (setq python-fill-docstring-style 'django)
  (setq python-shell-interpreter "ipython"))



;;;;;;;;;;;;;;;;;
;;; Scrolling ;;;
;;;;;;;;;;;;;;;;;

; Commands
(put 'scroll-left 'disabled nil)

; Hydra
(defhydra hydra-scroll ()
  "Scroll"
  ("<" scroll-left "left")
  (">" scroll-right "right"))

; Key Bindings
(global-set-key (kbd "C-x <") #'hydra-scroll/body)
(global-set-key (kbd "C-x >") #'hydra-scroll/body)

; Variables
(setq recenter-positions '(top middle bottom))
(setq scroll-preserve-screen-position 'always)



;;;;;;;;;;;;;;
;;; Search ;;;
;;;;;;;;;;;;;;

(use-package anzu
  :config
  (global-anzu-mode 1)
  (setq anzu-mode-lighter ""))

(use-package helm-swoop
  :bind ("C-c h" . helm-swoop)
  :config
  (bind-key "M-h" #'helm-swoop-from-isearch isearch-mode-map))

(use-package grep
  :ensure nil
  :bind ("C-c g" . rgrep)
  :config
  (defun rgrep-rename-buffer-after-search-string
      (orig regexp &optional files dir confirm)
    (funcall orig regexp files dir confirm)
    (with-current-buffer grep-last-buffer
      (rename-buffer (format "*grep-%s*" regexp))))

  (advice-add 'rgrep :around #'rgrep-rename-buffer-after-search-string))

(use-package smartscan
  :config
  (global-smartscan-mode t)
  (unbind-key "M-n" smartscan-map)
  (unbind-key "M-p" smartscan-map)
  (bind-keys :map smartscan-map
             ("s-n" . smartscan-symbol-go-forward)
             ("s-p" . smartscan-symbol-go-backward)))

;; Advice
(defun occur-rename-buffer-after-search-string
    (orig regexp &optional nlines)
  (funcall orig regexp nlines)
  (with-current-buffer "*Occur*"
    (rename-buffer (format "*Occur-%s*" regexp))))

(advice-add 'occur :around #'occur-rename-buffer-after-search-string)

(defun isearch-fake-success (orig)
  (let ((isearch-success t)
        (isearch-error nil))
    (funcall orig)))

(advice-add 'isearch-abort :around #'isearch-fake-success)

; Commands
(defun isearch-toggle-lazy-highlight-cleanup ()
  "Toggle `lazy-highlight-cleanup'.
- If `t' (ON), Isearch will *not* leave highlights around.
- If `nil' (OFF), matches will stay highlighted until the next
invocation of an Isearch command."
  (interactive)
  (setq lazy-highlight-cleanup (not lazy-highlight-cleanup))
  (message "Lazy highlight cleanup is now %s."
           (if lazy-highlight-cleanup "ON" "OFF")))

(defun isearch-hungry-delete ()
  "Delete the failed portion of the search string, or the last
char if successful."
  (interactive)
  (if (isearch-fail-pos)
      (while (isearch-fail-pos)
        (isearch-delete-char))
    (isearch-delete-char)))

;; Hooks
(add-hook 'occur-mode-hook #'next-error-follow-minor-mode)

; Key Bindings
(define-key isearch-mode-map (kbd "<backspace>") #'isearch-hungry-delete)
(define-key occur-mode-map "n" #'occur-next)
(define-key occur-mode-map "p" #'occur-prev)

; Variables
(setq isearch-allow-scroll t)



;;;;;;;;;;;;;;
;;; Server ;;;
;;;;;;;;;;;;;;

(use-package server
  :config
  (or (server-running-p)
      (server-start)))



;;;;;;;;;;;;;;;;
;;; Speedbar ;;;
;;;;;;;;;;;;;;;;

(use-package speedbar
  :defer t
  :config

  (use-package sr-speedbar
    :commands sr-speedbar-open
    :init
    (defalias 'speedbar 'sr-speedbar-open))

  ;; Variables
  (setq speedbar-tag-hierarchy-method
        '(speedbar-simple-group-tag-hierarchy speedbar-sort-tag-hierarchy))
  (setq speedbar-use-images nil))



;;;;;;;;;;;;;;;;;;;;;
;;; SuperCollider ;;;
;;;;;;;;;;;;;;;;;;;;;

(use-package sclang
  :disabled
  :ensure nil
  :config
  (add-hook 'sclang-mode-hook #'sclang-extensions-mode))



;;;;;;;;;;;;;;;;;
;;; Utilities ;;;
;;;;;;;;;;;;;;;;;

; Advice
(defun swap-args (fun)
  (if (not (equal (interactive-form fun) '(interactive "P")))
      (error "Can only swap args if interactive spec is (interactive \"P\").")
    (advice-add
     fun
     :around
     (lambda (orig &rest args)
       "Swap default behavior with \\[universal-argument] behavior."
       (if (car args)
           (apply orig (cons nil (cdr args)))
         (apply orig (cons '(4) (cdr args))))))))

(swap-args 'quit-window)

; Functions
(defun define-search-service (name url)
  "Create command for looking up query using a specific service."
  (eval `(defun ,(intern (downcase name)) ()
           ,(format "Look up query or contents of region (if any) on %s." name)
           (interactive)
           (let ((query (if mark-active
                            (buffer-substring (region-beginning) (region-end))
                          (read-string (format "%s: " ,name)))))
             (browse-url (concat ,url query))))))

(define-search-service
  "Google" "http://www.google.com/search?ie=utf-8&oe=utf-8&q=")
(define-search-service
  "StartPage" "https://startpage.com/do/metasearch.pl?query=")
(define-search-service
  "Thesaurus" "http://thesaurus.com/browse/")
(define-search-service
  "Urbandictionary" "http://www.urbandictionary.com/define.php?term=")
(define-search-service
  "Wiktionary" "https://en.wiktionary.org/wiki/")
(define-search-service
  "Wikipedia" "https://en.wikipedia.org/wiki/")

; Hydra
(defhydra hydra-search (:color blue)
  "Search"
  ("g" google "Google")
  ("s" startpage "StartPage")
  ("t" thesaurus "Thesaurus")
  ("u" urbandictionary "Urbandictionary")
  ("d" wiktionary "Wiktionary")
  ("w" wikipedia "Wikipedia"))

; Key Bindings
(global-set-key (kbd "C-c s") #'hydra-search/body)



;;;;;;;;;;;;;;;;;;;;;;;
;;; Version Control ;;;
;;;;;;;;;;;;;;;;;;;;;;;

(use-package browse-at-remote
  :commands browse-at-remote)

(use-package bts
  :commands (bts:summary-open bts:ticket-new)
  :config

  (use-package bts-github)

  (use-package wid-edit
    :ensure nil
    :config
    (set-face-attribute 'widget-field nil :box nil)))

(use-package magit
  :commands magit-status
  :init
  (bind-key "g s" #'magit-status custom-keys-mode-prefix-map)
  :config

  (use-package git-commit-mode
    :config
    ;; Functions
    (defun git-commit-add-electric-pairs ()
      (setq-local electric-pair-pairs
                  (cons single-backticks electric-pair-pairs)))

    ;; Hooks
    (add-hook 'git-commit-mode-hook #'git-commit-add-electric-pairs)
    (add-hook 'git-commit-mode-hook #'turn-on-orgstruct)
    (add-hook 'git-commit-mode-hook #'turn-on-auto-fill))

  ;; Commands
  (defun magit-log-all ()
    (interactive)
    (magit-key-mode-popup-logging)
    (magit-key-mode-toggle-option 'logging "--all"))

  (defun magit-ls-files ()
    "List tracked files of current repository."
    (interactive)
    (if (derived-mode-p 'magit-mode)
        (magit-git-command "ls-files" default-directory)
      (message "Not in a Magit buffer.")))

  ;; Hooks
  (add-hook 'magit-revert-buffer-hook #'git-gutter+-refresh)

  ;; Key Bindings
  (unbind-key "M-s" magit-mode-map)
  (unbind-key "M-S" magit-mode-map)
  (bind-keys :map magit-mode-map
             ("K" . magit-ls-files)
             ("l" . magit-log-all))

  ;; Variables
  (setq magit-auto-revert-mode-lighter "")
  (setq magit-diff-refine-hunk t)
  (setq magit-use-overlays nil))

; git-wip
(load "~/git-wip/emacs/git-wip.el")

(use-package git-wip-timemachine
  :ensure nil
  :load-path "lisp/git-wip-timemachine"
  :commands git-wip-timemachine)

(use-package git-gutter+
  :commands git-gutter+-mode
  :init
  (add-hook 'css-mode-hook #'git-gutter+-mode)
  (add-hook 'html-mode-hook #'git-gutter+-mode)
  (add-hook 'org-mode-hook #'git-gutter+-mode)
  (add-hook 'prog-mode-hook #'git-gutter+-mode)
  :config

  (use-package git-gutter-fringe+
    :config
    ;; Functions
    (defun git-gutter-fringe+-change-fringe ()
      (if linum-mode
          (setq-local git-gutter-fr+-side 'right-fringe)
        (setq-local git-gutter-fr+-side 'left-fringe))
      (git-gutter+-refresh))

    ;; Hooks
    (add-hook 'linum-mode-hook #'git-gutter-fringe+-change-fringe))

  (modeline-remove-lighter 'git-gutter+-mode)

  ;; Functions
  (defun git-gutter+-setup ()
    (setq-local git-gutter-fr+-side 'left-fringe))

  ;; Hooks
  (add-hook 'git-gutter+-mode-hook #'git-gutter+-setup)

  ;; Hydra
  (defhydra hydra-git-gutter+ (:color pink)
    "Git Gutter"
    ("n" git-gutter+-next-hunk "next")
    ("p" git-gutter+-previous-hunk "prev")
    ("d" git-gutter+-show-hunk "diff")
    ("s" git-gutter+-stage-hunks "stage")
    ("r" git-gutter+-revert-hunks "revert")
    ("u" git-gutter+-unstage-whole-buffer "unstage buffer")
    ("m" magit-status "magit" :color blue)
    ("C-g" nil "quit"))

  ;; Key Bindings
  (bind-key "g g" #'hydra-git-gutter+/body custom-keys-mode-prefix-map))

(use-package helm-github-stars
  :commands helm-github-stars
  :config
  (setq helm-github-stars-username "itsjeyd"))

(use-package helm-open-github
  :commands (helm-open-github-from-commit
             helm-open-github-from-file
             helm-open-github-from-issues
             helm-open-github-from-pull-requests)
  :config
  (defun helm-open-github-from-issues (arg)
  (interactive "P")
  (let ((host (helm-open-github--host))
        (url (helm-open-github--remote-url)))
    (when arg
      (remhash url helm-open-github--issues-cache))
    (if (not (string= host "github.com"))
        (helm-open-github--from-issues-direct host)
      (helm :sources '(helm-open-github--from-issues-source)
            :buffer  "*open github*")))))

(use-package github-browse-file
  :commands (github-browse-file github-browse-file-blame))

(use-package github-clone
  :commands github-clone)

; Variables
(setq magit-last-seen-setup-instructions "1.4.0")



;;;;;;;;;;;;;;;;;;
;;; Visibility ;;;
;;;;;;;;;;;;;;;;;;

; Commands
(put 'narrow-to-page 'disabled nil)
(put 'narrow-to-region 'disabled nil)

(defun narrow-to-region-indirect-buffer (start end)
  "Create indirect buffer based on current buffer and narrow it
to currently active region. Instead of using arbitrary numbering,
incorporate line numbers of point and mark into buffer name for
indirect buffer. This command makes it easy to quickly generate
multiple views of the contents of any given buffer.

Adapted from: http://paste.lisp.org/display/135818."
  (interactive "r")
  (with-current-buffer
      (clone-indirect-buffer
       (generate-new-buffer-name
        (concat (buffer-name)
                "-indirect-L"
                (number-to-string (line-number-at-pos start))
                "-L"
                (number-to-string (line-number-at-pos end))))
       'display)
    (narrow-to-region start end)
    (deactivate-mark)
    (goto-char (point-min))))

(defun hide-lines-below-current-column (orig &optional arg)
  "Use selective display to hide lines below current column.
With a prefix arg, clear selective display."
  (interactive "P")
  (if arg
      (funcall orig -1)
    (funcall orig (+ (current-column) 1))))

(advice-add 'set-selective-display :around #'hide-lines-below-current-column)

; Key Bindings
(global-set-key (kbd "C-x n i") #'narrow-to-region-indirect-buffer)
(define-key custom-keys-mode-prefix-map (kbd "t t") #'toggle-truncate-lines)

; Variables
(setq-default truncate-lines t)



;;;;;;;;;;;;;;
;;; Webdev ;;;
;;;;;;;;;;;;;;

(use-package web-beautify
  :commands (web-beautify-css web-beautify-html web-beautify-js))



;;;;;;;;;;;;;;;;;;;;;;;;
;;; Windows + Frames ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

(use-package ace-window
  :bind ("C-x o" . ace-window)
  :config
  (set-face-attribute 'aw-leading-char-face nil :height 2.0)
  (setq aw-keys (number-sequence ?a ?i))
  (setq aw-scope 'frame))

(use-package winner
  :config
  (winner-mode 1)
  (bind-key "C-c r" #'winner-redo)
  (bind-key "C-c u" #'winner-undo))

; Commands
(defun change-split (&optional arg)
  "Change arrangement of current window and `other-window' from 'stacked' to 'side-by-side'.
With a prefix arg, change arrangement from 'side-by-side' to 'stacked'."
  (interactive "P")
  (let ((split-function (progn
                          (if arg
                              (lambda () (split-window-below))
                            (lambda () (split-window-right)))))
        (current-buf (current-buffer))
        (other-buf (progn
                     (other-window 1)
                     (current-buffer))))
    (delete-other-windows)
    (funcall split-function)
    (switch-to-buffer current-buf)))

(defun kill-other-buffer-and-window ()
  "Kill the next buffer in line and closes the associated window.
I.e., if there are two windows, the active one stays intact, the
inactive one is closed. If there are several windows, the one
that would be reached by issuing C-x o once is closed, all others
stay intact. Should only be used if the frame is displaying more
than one window."
  (interactive)
  (other-window 1)
  (kill-buffer-and-window))

(defun split-root-window-below (&optional size)
  "Split root window vertically.
Optional argument SIZE specifies height of window that will be
added to the current window layout."
  (interactive "P")
  (split-root-window 'below size))

(defun split-root-window-right (&optional size)
  "Split root window horizontally.
Optional argument SIZE specifies width of window that will be
added to the current window layout."
  (interactive "P")
  (split-root-window 'right size))

(defun swap-windows ()
  "Call `ace-window' with a single prefix arg to swap arbitrary
window with current window."
  (interactive)
  (ace-window 4))

(defun toggle-window-dedicated ()
  "Control whether or not Emacs is allowed to display another
buffer in current window."
  (interactive)
  (message
   (if (let (window (get-buffer-window (current-buffer)))
         ; set-window-dedicated-p returns FLAG that was passed as
         ; second argument, thus can be used as COND for if:
         (set-window-dedicated-p window (not (window-dedicated-p window))))
       "%s: Can't touch this!"
     "%s is up for grabs.")
   (current-buffer)))

; Functions
(defun split-root-window (direction size)
  "Split root window of current frame.
DIRECTION specifies how root window will be split; possible
values are 'below and 'right. SIZE specifies height or width of
window that will be added to the current window layout."
  (split-window (frame-root-window)
                (and size (prefix-numeric-value size))
                direction))

; Hydra
(defhydra hydra-resize-window ()
  "Make window(s)"
  ("}" enlarge-window-horizontally "wider")
  ("{" shrink-window-horizontally "narrower")
  ("^" enlarge-window "taller")
  ("v" shrink-window "shorter")
  ("+" balance-windows "balanced")
  ("-" shrink-window-if-larger-than-buffer "fit"))

; Key Bindings
(global-set-key (kbd "C-c 2") #'split-root-window-below)
(global-set-key (kbd "C-c 3") #'split-root-window-right)
(global-set-key (kbd "C-x {") #'hydra-resize-window/body)
(global-set-key (kbd "C-x }") #'hydra-resize-window/body)
(global-set-key (kbd "C-x ^") #'hydra-resize-window/body)
(define-key custom-keys-mode-prefix-map (kbd "c s") #'change-split)
(define-key custom-keys-mode-prefix-map (kbd "k o") #'kill-other-buffer-and-window)
(define-key custom-keys-mode-prefix-map (kbd "k t") #'kill-buffer-and-window)
(define-key custom-keys-mode-prefix-map (kbd "s w") #'swap-windows)
(define-key custom-keys-mode-prefix-map (kbd "t d") #'toggle-window-dedicated)

; Variables
(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)



;;;;;;;;;;;;;;;
;;; Writing ;;;
;;;;;;;;;;;;;;;

(use-package flyspell
  :commands (flyspell-mode flyspell-prog-mode)
  :config
  (defun flyspell-buffer-again (&optional no-query force-save)
    (flyspell-buffer))

  (advice-add 'ispell-pdict-save :after #'flyspell-buffer-again))

(use-package markdown-mode
  :commands markdown-mode
  :config

  (use-package gh-md
    :commands (gh-md-render-region gh-md-render-buffer))

  ;; Functions
  (defun markdown-add-electric-pairs ()
    (setq-local electric-pair-pairs
                (cons single-backticks electric-pair-pairs)))

  ;; Hooks
  (add-hook 'markdown-mode-hook #'markdown-add-electric-pairs)
  (add-hook 'markdown-mode-hook #'turn-on-auto-fill))

(use-package synosaurus
  :commands (synosaurus-lookup synosaurus-choose-and-replace))

(use-package writeroom-mode
  :commands writeroom-mode
  :config
  ;; Functions
  (defun turn-off-git-gutter+ ()
    (if (not git-gutter+-mode)
        (git-gutter+-mode t)
      (git-gutter+-mode -1)))

  ;; Hooks
  (add-hook 'writeroom-mode-hook #'turn-off-git-gutter+))

; Commands
(defun ispell-word-then-abbrev (local)
  "Call `ispell-word'. Then create an abbrev for the correction made.
With prefix P, create local abbrev. Otherwise it will be global."
  (interactive "P")
  (let ((before (downcase (or (thing-at-point 'word) "")))
        after)
    (call-interactively #'ispell-word)
    (setq after (downcase (or (thing-at-point 'word) "")))
    (unless (string= after before)
      (define-abbrev
        (if local local-abbrev-table global-abbrev-table) before after))
      (message "\"%s\" now expands to \"%s\" %sally."
               before after (if local "loc" "glob"))))

; Hydra
(defhydra hydra-synosaurus (:color blue)
  "Synosaurus"
  ("l" synosaurus-lookup "look up")
  ("r" synosaurus-choose-and-replace "replace"))

; Key Bindings
(global-set-key (kbd "C-c S") #'hydra-synosaurus/body)
(define-key custom-keys-mode-prefix-map (kbd "s a") #'ispell-word-then-abbrev)

; Variables
(setq abbrev-file-name "~/.emacs.d/.abbrev_defs")
(setq-default abbrev-mode t)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(custom-keys-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(modeline-remove-lighter 'auto-complete-mode)
(modeline-set-lighter 'abbrev-mode " Abbr")
(modeline-set-lighter 'auto-fill-function (string 32 #x23ce))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(split-window-horizontally)
(toggle-frame-maximized)
(semantic-mode)
