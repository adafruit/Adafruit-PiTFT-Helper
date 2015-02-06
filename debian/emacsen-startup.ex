;; -*-emacs-lisp-*-
;;
;; Emacs startup file, e.g.  /etc/emacs/site-start.d/50adafruit-pitft-helper.el
;; for the Debian adafruit-pitft-helper package
;;
;; Originally contributed by Nils Naumann <naumann@unileoben.ac.at>
;; Modified by Dirk Eddelbuettel <edd@debian.org>
;; Adapted for dh-make by Jim Van Zandt <jrv@debian.org>

;; The adafruit-pitft-helper package follows the Debian/GNU Linux 'emacsen' policy and
;; byte-compiles its elisp files for each 'emacs flavor' (emacs19,
;; xemacs19, emacs20, xemacs20...).  The compiled code is then
;; installed in a subdirectory of the respective site-lisp directory.
;; We have to add this to the load-path:
(let ((package-dir (concat "/usr/share/"
                           (symbol-name debian-emacs-flavor)
                           "/site-lisp/adafruit-pitft-helper")))
;; If package-dir does not exist, the adafruit-pitft-helper package must have
;; removed but not purged, and we should skip the setup.
  (when (file-directory-p package-dir)
    (if (fboundp 'debian-pkg-add-load-path-item)
        (debian-pkg-add-load-path-item package-dir)
      (setq load-path (cons package-dir load-path)))
    (autoload 'adafruit-pitft-helper-mode "adafruit-pitft-helper-mode"
      "Major mode for editing adafruit-pitft-helper files." t)
    (add-to-list 'auto-mode-alist '("\\.adafruit-pitft-helper$" . adafruit-pitft-helper-mode))))

