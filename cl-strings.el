;;;; -*- emacs-lisp -*-
;;;
;;; Copyright (C) 2003 Lars Brinkhoff.
;;; This file implements operators in chapter 16, Strings.

(IN-PACKAGE "EMACS-CL")

(defun SIMPLE-STRING-P (object)
  (stringp object))

(defun CHAR (string index)
  (cond
    ((SIMPLE-STRING-P string)
     (SCHAR string index))
    ((STRINGP string)
     (SCHAR (aref string 2) index))
    (t
     (error "type error"))))

(defsetf CHAR (string index) (char)
  `(cond
    ((SIMPLE-STRING-P string)
     (setf (SCHAR ,string ,index) ,char))
    ((STRINGP string)
     (setf (SCHAR (aref ,string 2) ,index) ,char))
    (t
     (error "type error"))))

(defun SCHAR (string index)
  (CODE-CHAR (aref string index)))

(defsetf SCHAR (string index) (char)
  `(aset ,string ,index (CHAR-CODE ,char)))

(defun STRING (x)
  (cond
    ((STRINGP x)	x)
    ((SYMBOLP x)	(SYMBOL-NAME x))
    ((CHARACTERP x)	(MAKE-STRING 1 :initial-element x))
    (t			(error))))

;;; TODO: string-upcase, string-downcase, string-capitalize,
;;; nstring-upcase, nstring-downcase, nstring-capitalize

;;; TODO: string-trim, string-left-trim, string-right-trim

(defun* STRING= (string1 string2 &key (start1 0) end1 (start2 0) end2)
  (string= (substring string1 start1 end1)
	   (substring string2 start2 end2)))

(defun* STRING/= (string1 string2 &key (start1 0) end1 (start2 0) end2)
  (not (STRING= string1 string2 :start1 start1 :end1 end1
		                :start2 start2 :end2 end2)))

(defun* STRING< (string1 string2 &key start1 end1 start2 end2)
  (let ((i 0)
	(len1 (LENGTH string1))
	(len2 (LENGTH string2)))
    (loop
      (when (eq i len1)
	(return-from STRING< (if (eq i len2) nil i)))
      (when (eq i len2)
	(return-from STRING< nil))
      (when (CHAR< (CHAR string1 i) (CHAR string2 i))
	(return-from STRING< i))
      (when (CHAR> (CHAR string1 i) (CHAR string2 i))
	(return-from STRING< nil))
      (incf i))))

(defun* STRING> (string1 string2 &key start1 end1 start2 end2)
  (let ((i 0)
	(len1 (LENGTH string1))
	(len2 (LENGTH string2)))
    (loop
      (when (eq i len1)
	(return-from STRING> nil))
      (when (eq i len2)
	(return-from STRING> i))
      (when (CHAR< (CHAR string1 i) (CHAR string2 i))
	(return-from STRING> nil))
      (when (CHAR> (CHAR string1 i) (CHAR string2 i))
	(return-from STRING> i))
      (incf i))))

(defun* STRING<= (string1 string2 &key start1 end1 start2 end2)
  (STRING> string2 string1 :start1 start2 :end1 end2
			   :start2 start1 :end2 end1))

(defun* STRING>= (string1 string2 &key start1 end1 start2 end2)
  (STRING< string2 string1 :start1 start2 :end1 end2
			   :start2 start1 :end2 end1))

;;; TODO: string-equal, string-not-equal, string-lessp,
;;; string-greaterp, string-not-greaterp, string-not-lessp

(defun STRINGP (object)
  (or (SIMPLE-STRING-P object)
      (vector-and-typep object 'string)))

(defun* MAKE-STRING (size &key initial-element element-type)
  (make-string size (if initial-element (CHAR-CODE initial-element) 0)))
