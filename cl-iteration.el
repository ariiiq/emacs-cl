;;;; -*- emacs-lisp -*-
;;;
;;; Copyright (C) 2003 Lars Brinkhoff.
;;; This file implements operators in chapter 6, Iteration.

(IN-PACKAGE "EMACS-CL")

(defun var-inits (vars)
  (mapcar (lambda (var)
	    (if (symbolp var)
		var
		`(,(first var) ,(second var))))
	  vars))

(defun var-steps (vars)
  (mappend (lambda (var)
	     (print var)
	     (when (and (consp var) (= (length var) 3))
	       `(,(first var) ,(third var))))
	   vars))

(cl:defmacro DO (vars (test &rest result) &body body)
  (with-gensyms (block start)
    `(LET* ,(var-inits vars)
       (BLOCK ,block
	 (TAGBODY
	   ,start
	   (WHEN ,test (RETURN-FROM ,block (PROGN ,@result)))
	   ,@body
	   (PSETQ ,@(var-steps vars))
	   (GO ,start))))))

(cl:defmacro DO* (vars (test &rest result) &body body)
  (with-gensyms (block start)
    `(LET* ,(var-inits vars)
       (BLOCK ,block
	 (TAGBODY
	   ,start
	   (WHEN ,test (RETURN-FROM ,block (PROGN ,@result)))
	   ,@body
	   (SETQ ,@(var-steps vars))
	   (GO ,start))))))

(cl:defmacro DOTIMES ((var count &optional result) &body body)
  `(DO ((,var 0 (1+ ,var))
	(,end ,count))
       ((EQL ,var ,end)
	,result)
     ,@body))

(cl:defmacro DOLIST ((var list &optional result) &body body)
;   (with-gensyms (x)
;     `(DO* ((,x ,list (CDR ,x)))
;           ((NULL ,x)
; 	   ,result)
;        (LET ((,var (CAR ,x)))
; 	 ,@body))))
  `(PROGN
    (MAPC (LAMBDA (,var) ,@body) ,list)
    ,result))
