(require 'cl)
(setq max-lisp-eval-depth 10000)
(setq max-specpdl-size 5000)

;;; Fake an IN-PACKAGE macro.
(defmacro IN-PACKAGE (name) nil)

(defvar *cl-files*
'("utils"

  "cl-evaluation"
  "cl-flow"
  "cl-numbers"
  "cl-conses"
  "cl-arrays"
  "cl-sequences"
  "cl-structures"
  "cl-iteration"

  "cl-characters"
  "cl-strings"
  "cl-symbols"
  "cl-packages"

  "cl-types"
  "cl-typep"
  "cl-subtypep"

  "cl-hash"
  "cl-streams"
  "cl-reader"
  "cl-printer"
  "cl-environment"
  "cl-system"
  "interaction"
  "cl-eval"

  "populate"))

(defun load-cl ()
  (let ((load-path (cons "~/src/emacs-cl" load-path))
	(debug-on-error t))
    (mapc #'load *cl-files*)
    (populate-packages)
    (garbage-collect)
    (message "Emacs CL is loaded")))

(defun compile-cl ()
  (dolist (file *cl-files*)
    (byte-compile-file (concat file ".el"))))

(load-cl)
(IN-PACKAGE "CL-USER")
