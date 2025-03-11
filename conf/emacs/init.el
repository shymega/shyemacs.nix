(setq debug-on-error t)

(advice-add 'use-package-ensure-elpa :override (lambda (&rest _) nil))

(let ((normal-gc-cons-threshold gc-cons-threshold)
      (normal-gc-cons-percentage gc-cons-percentage)
      (normal-file-name-handler-alist file-name-handler-alist)
      (init-gc-cons-threshold most-positive-fixnum)
      (init-gc-cons-percentage 0.6))
  (setq gc-cons-threshold init-gc-cons-threshold
        gc-cons-percentage init-gc-cons-percentage
        file-name-handler-alist nil)
  (add-hook 'after-init-hook
            `(lambda ()
               (setq gc-cons-threshold ,normal-gc-cons-threshold
                     gc-cons-percentage ,normal-gc-cons-percentage
                     file-name-handler-alist ',normal-file-name-handler-alist))))

(setq inhibit-startup-echo-area-message t)
(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)
(setq frame-inhibit-implied-resize t)
(advice-add #'x-apply-session-resources :override #'ignore)

(defvar windows-p (eq system-type 'windows))
(defvar linux-p (eq system-type 'gnu/linux))
(defvar macos-p (eq system-type 'mac))

(setq make-backup-files       nil
      create-lockfiles        nil
      auto-save-default       nil
      inhibit-startup-message t
      frame-title-format      'none
      ring-bell-function      'ignore)
(dolist (mode
         '(tool-bar-mode
           tooltip-mode
	   menu-bar-mode
           scroll-bar-mode
           blink-cursor-mode))
  (funcall mode 0))

(fset 'yes-or-no-p 'y-or-n-p)

(require 'server)
(unless (server-running-p)
  (server-start))

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq debug-on-error nil)
	    (setq initial-scratch-message (format ";; Scratch buffer - started on %s\n\n" (current-time-string)))
            (message ";; Loaded Emacs in %.03fs"
                     (float-time (time-subtract after-init-time before-init-time)))))
