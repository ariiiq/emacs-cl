;;;; -*- emacs-lisp -*-
;;;
;;; Copyright (C) 2003 Lars Brinkhoff.
;;; This file implements operators in chapter 5, Data and Control Flow.

(defvar *setf-definitions* (make-hash-table))

;;; TODO: apply

(defmacro* (DEFUN name lambda-list &body body)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (SETF (FDEFINITION ,name) (function* (lambda ,lambda-list ,@body)))))

(defun FDEFINITION (name)
  (cond
    ((symbop name)
     (symbol-function name))
    ((and (consp name) (eq (first name) 'SETF) (eq (cddr name) nil))
     (gethash (second name) *setf-definitions*))
    (t
     (error))))

(defsetf FDEFINITION (name) (fn)
  `(cond
    ((symbolp ,name)
     (setf (symbol-function ,name) ,fn))
    ((and (consp ,name) (eq (first ,name) 'SETF) (eq (cddr ,name) nil))
     (setf (gethash (second ,name) *setf-definitions*) ,fn))
    (t
     (error "type error"))))

;;; TODO: fboundp

;;; TODO: fmakunbound

;;; TODO: flet, labels, macrolet

(defun FUNCALL (fn &rest args)
  (cond
    ((symbolp fn)
     (apply fn args))
    ((and (consp fn) (eq (first fn) 'setf) (null (cddr fn)))
     (apply (FDEFINITION fn) args))
    (t
     (error))))

;;; TODO: function

;;; TODO: function-lambda-expression

(defun FUNCTIONP (object)
  (functionp object))

(defun COMPILED-FUNCTION-P (object)
  (compiled-function-p object))

;;; TODO: call-argument-limit

(defvar lambda-list-keywords
        '(&allow-other-keys &aux &body &environment &key &optional
	  &rest &whole))

(defmacro* DEFCONSTANT (name initial-value &optional documentation)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
    (defvar ,name ,initial-value)
    (pushnew ',name *constants*)
    ',name))

(defun expand-tagbody-forms (body start end)
  (do ((clauses nil)
       (clause (list (list start)))
       (forms body (cdr forms)))
      ((null forms)
       (setq clause (append clause (list (list 'go end))))
       (setq clauses (append clauses `(,clause)))
       clauses)
    (let ((form (first forms)))
      (cond
	((atom form)
	 (setq clause (append clause `((go ,form))))
	 (setq clauses (append clauses `(,clause)))
	 (setq clause `((,form))))
	(t
	 (setq clause (append clause `(,form))))))))

(defmacro* tagbody (&body body)
  (let ((pc (gensym))
	(start (gensym))
	(end (gensym))
	(throw-tag (gensym)))
    `(let ((,pc ',start))
      (macrolet ((go (tag)
		   (list 'throw
			 (list 'quote ',throw-tag)
			 (list 'quote tag))))
	(while (not (eq ,pc ',end))
	  (setq ,pc
		(catch ',throw-tag
		  (case ,pc
		    ,@(expand-tagbody-forms body start end))))))
      nil)))

(DEFCONSTANT NIL 'NIL)

(defun NOT (x)
  (if (eq x 'NIL)
      'T
      'NIL))

(DEFCONSTANT T 'T)

(setf (symbol-function 'EQ) (symbol-function 'eq))

(defun EQL (x y)
  (or (eq x y)
      (cond
	((and (characterp x) (characterp y))
	 (eq (char-code x) (char-code y)))
	((and (cl::bignump x) (cl::bignump y))
	 (and (eq (length x) (length y))
	      (every #'eq x y)))
	((and (cl::ratiop x) (cl::ratiop y))
	 (and (EQL (numerator x) (numerator y))
	      (EQL (denominator x) (denominator y))))
	((and (complexp x) (complexp y))
	 (and (EQL (realpart x) (realpart y))
	      (EQL (imagpart x) (imagpart y))))
	(t
	 NIL))))

(defun EQUAL (x y)
  (or (EQL x y)
      (cond
	((and (consp x) (consp y))
	 (and (EQUAL (car x) (car y))
	      (EQUAL (cdr x) (cdr y))))
	((and (STRINGP x) (STRINGP y))
	 (and (eq (LENGTH x) (LENGTH y))
	      (EVERY #'eq x y)))
	((and (BIT-STRING-P x) (BIT-STRING-P y))
	 (and (eq (LENGTH x) (LENGTH y))
	      (EVERY #'eq x y)))
	;; TODO: pathnames
	(t
	 NIL))))

;; (defvar *multiple-values-variable* nil)

;; (defmacro* cl:multiple-value-bind (vars form &body body)
;;   (let ((vals (gensym))
;; 	(empty (gensym))
;; 	(old (gensym)))
;;     `(let ((,vals ',empty)
;; 	   (,old *multiple-values-variable*))
;;       (setq *multiple-values-variable* ',vals)
;;       (let ((,(car vars) ,form)
;; 	    ,@(cdr vars))
;; 	(unless (eq ,vals ',empty)
;; 	  (dolist (var ',vars)
;; 	    (set var (car-safe ,vals))
;; 	    (setq ,vals (cdr-safe ,vals))))
;; 	(setq *multiple-values-variable* ,old)
;; 	,@body))))

;; (defmacro cl:multiple-value-call (function &rest forms)
;;   `(apply ,function
;;     (append ,@(mapcan (lambda (form)
;; 			`((cl:multiple-value-list ,form)))
;; 		      forms))))

;; (defmacro cl:multiple-value-list (form)
;;   (let ((vals (gensym))
;; 	(empty (gensym))
;; 	(list (gensym)))
;;     `(let* ((,vals ',empty)
;; 	    (*multiple-values-variable* ',vals)
;; 	    (,list (list ,form)))
;;       (unless (eq ,vals ',empty)
;; 	(setq ,list ,vals))
;;       ,list)))

;; ;;; multiple-value-prog1 first-form form* => first-form-results

;; (defmacro* cl:multiple-value-setq (vars form &body body)
;;   (let ((vals (gensym))
;; 	(empty (gensym)))
;;     `(let ((,vals ',empty)
;; 	   (*multiple-values-variable* ',vals))
;;       (setq ,(car vars) ,form)
;;       (unless (eq ,vals ',empty)
;; 	(dolist (var ',vars)
;; 	  (set var (car-safe ,vals))
;; 	  (setq ,vals (cdr-safe ,vals))))
;;       ,@body)))

;; (defun cl:values (&rest vals)
;;   (cl:values-list vals))

;; (defun cl:values-list (list)
;;   (when *multiple-values-variable*
;;     (set *multiple-values-variable* list))
;;   (car list))

(defmacro* DEFSETF (access-fn &rest args)
  (if (<= (length args) 2)
      `(DEFINE-SETF-EXPANDER ,access-fn (&rest args2)
	(let ((fn ',(first args))
	      (var (gensym))
	      (temps (mapcar (lambda (x) (gensym)) args2)))
	  (values temps
		  args2
		  (list var)
		  `(,fn ,@temps ,var)
		  ())))
      `(long-form-defsetf ,access-fn ,@args)))

(defmacro* long-form-defsetf (access-fn lambda-list variables &body body)
  `(DEFINE-SETF-EXPANDER ,access-fn ,lambda-list
    (values ()
            ()
            ',variables
            ,(cons 'progn body))))

(defvar *setf-expanders* (make-hash-table))

(defmacro* DEFINE-SETF-EXPANDER (access-fn lambda-list &body body)
  (setq lambda-list (copy-list lambda-list))
  (remf lambda-list '&environment)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
    (setf (gethash ',access-fn *setf-expanders*)
          (lambda ,lambda-list ,@body))))

(defun GET-SETF-EXPANSION (place &optional env)
  (let ((fn (gethash (first place) *setf-expanders*)))
    (if fn
	(apply fn (rest place))
	(let ((temps (mapcar (lambda (x) (gensym)) (rest place)))
	      (var (gensym)))
	  (values temps
		  (rest place)
		  (list var)
		  `(FUNCALL '(SETF ,(first place)) ,var ,@temps)
		  ())))))

(defmacro* SETF (place value &environment env)
  (multiple-value-bind (temps values variables setter getter)
      (GET-SETF-EXPANSION place env)
    `(let* ,(MAPCAR #'list temps values)
      (let ((,(first variables) ,value))
	,setter))))
