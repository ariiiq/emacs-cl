;;;; -*- emacs-lisp -*-
;;;
;;; Copyright (C) 2003 Lars Brinkhoff.
;;; This file implements operators in chapter 21, Streams.

(IN-PACKAGE "EMACS-CL")

;;; System Class STREAM
;;; TODO: System Class BROADCAST-STREAM
;;; TODO: System Class CONCATENATED-STREAM
;;; TODO: System Class ECHO-STREAM
;;; TODO: System Class FILE-STREAM
;;; TODO: System Class STRING-STREAM
;;; TODO: System Class SYNONYM-STREAM
;;; TODO: System Class TWO-WAY-STREAM

(DEFSTRUCT (STREAM (:predicate STREAMP) (:copier nil))
  filename
  content
  index
  end
  fresh-line-p
  read-fn
  write-fn)

(defun stream-error (stream)
  (ERROR 'STREAM-ERROR (kw STREAM) stream))

(defvar *STANDARD-INPUT* nil)

(defvar *STANDARD-OUTPUT* nil)

(defvar *TERMINAL-IO* nil)

(defun input-stream (designator)
  (case designator
    ((nil)	*STANDARD-INPUT*)
    ((t)	*TERMINAL-IO*)
    (t		designator)))

(defun output-stream (designator)
  (case designator
    ((nil)	*STANDARD-OUTPUT*)
    ((t)	*TERMINAL-IO*)
    (t		designator)))

(defun INPUT-STREAM-P (stream)
  (not (null (STREAM-read-fn stream))))

(defun OUTPUT-STREAM-P (stream)
  (not (null (STREAM-read-fn stream))))

;;; TODO: INTERACTIVE-STREAM-P

;;; TODO: OPEN-STREAM-P

;;; TODO: STREAM-ELEMENT-TYPE

;;; STREAMP defined by defstruct.

;;; TODO: READ-BYTE

;;; TODO: WRITE-BYTE

(defun* PEEK-CHAR (&optional peek-type stream (eof-error-p T)
			     eof-value recursive-p)
  (loop
   (let ((char (READ-CHAR stream eof-error-p eof-value recursive-p)))
     (cond
       ((EQL char eof-value)
	(return-from PEEK-CHAR eof-value))
       ((or (eq peek-type nil)
	    (and (eq peek-type T) (not (whitespacep char)))
	    (and (not (eq peek-type T)) (CHAR= char peek-type)))
	(UNREAD-CHAR char stream)
	(return-from PEEK-CHAR char))))))

(defun* READ-CHAR (&optional stream-designator (eof-error-p T)
			     eof-value recursive-p)
  (let* ((stream (input-stream stream-designator))
	 (fn (STREAM-read-fn stream))
	 (ch (funcall (or fn (stream-error stream)) stream)))
    (if (eq ch :eof)
	(if eof-error-p
	    (ERROR 'END-OF-FILE (kw STREAM) stream)
	    eof-value)
	(CODE-CHAR ch))))

(cl:defun read-char-exclusive-ignoring-arg (arg)
  (let ((char (read-char-exclusive)))
    (if (eq char 13) 10 char)))

(cl:defun READ-CHAR-NO-HANG (&optional stream-designator (eof-error-p T)
				       eof-value recursive-p)
  (let ((stream (input-stream stream-designator)))
    (if (eq (STREAM-read-fn stream)
	    (cl:function read-char-exclusive-ignoring-arg))
	(when (LISTEN stream)
	  (READ-CHAR stream stream eof-error-p eof-value recursive-p))
	(READ-CHAR stream stream eof-error-p eof-value recursive-p))))

(cl:defun TERPRI (&optional stream-designator)
  (let ((stream (output-stream stream-designator)))
    (WRITE-CHAR (ch 10) stream))
  nil)

(cl:defun FRESH-LINE (&optional stream-designator)
  (let ((stream (output-stream stream-designator)))
    (unless (STREAM-fresh-line-p stream)
      (TERPRI stream))))

(cl:defun UNREAD-CHAR (char &optional stream-designator)
  (let ((stream (input-stream stream-designator)))
    (when (> (STREAM-index stream) 0)
      (decf (STREAM-index stream)))))

(cl:defun WRITE-CHAR (char &optional stream-designator)
  (let* ((stream (output-stream stream-designator))
	 (fn (STREAM-write-fn stream)))
    (unless fn
      (stream-error stream))
    (funcall fn (CHAR-CODE char) stream)
    (setf (STREAM-fresh-line-p stream) (ch= char 10))
    char))

(cl:defun READ-LINE (&optional stream-designator (eof-error-p T)
			       eof-value recursive-p)
  (let ((stream (input-stream stream-designator))
	(line ""))
    (catch 'READ-LINE
      (loop
       (let ((char (READ-CHAR stream eof-error-p eof-value recursive-p)))
	 (cond
	   ((EQL char eof-value)
	    (throw 'READ-LINE
	      (VALUES (if (= (length line) 0) eof-value line) t)))
	   ((ch= char 10)
	    (throw 'READ-LINE (VALUES line nil))))
	 (setq line (concat line (list (CHAR-CODE char)))))))))

(cl:defun WRITE-STRING (string &optional stream-designator &key (START 0) END)
  (unless END
    (setq END (LENGTH string)))
  (do ((stream (output-stream stream-designator))
       (i START (1+ i)))
      ((eq i END) string)
    (WRITE-CHAR (CHAR string i) stream)))

(cl:defun WRITE-LINE (string &optional stream-designator &key (START 0) END)
  (let ((stream (output-stream stream-designator)))
    (WRITE-STRING string stream (kw START) START (kw END) END)
    (TERPRI stream)
    string))

(cl:defun READ-SEQUENCE (seq stream &key (START 0) END)
  (unless END
    (setq END (LENGTH seq)))
  (catch 'READ-SEQUENCE
    (do ((i START (1+ i)))
	((eq i END)
	 i)
      (let ((char (READ-CHAR stream nil)))
	(if (null char)
	    (throw 'READ-SEQUENCE i)
	    (setf (ELT seq i) char))))))

(cl:defun WRITE-SEQUENCE (seq stream &key (START 0) END)
  (unless END
    (setq END (LENGTH seq)))
  (do ((i START (1+ i)))
      ((eq i END)
       seq)
    (WRITE-CHAR (ELT seq i) stream)))

(defun FILE-LENGTH (stream)
  (let ((len (file-attributes (STREAM-filename stream))))
    (cond
      ((integerp len)	len)
      ((null len)	nil)
      ;; TODO: return integer
      ((floatp len)	len)
      (t		(error "?")))))

(defun FILE-POSITION (stream &optional position)
  (if position
      ;; TODO: implement setting position
      (progn
	(setf (STREAM-index stream))
	T)
      (STREAM-index stream)))

(defun FILE-STRING-LENGTH (stream object)
  (LENGTH (let ((s (MAKE-STRING-OUTPUT-STREAM)))
	    (unwind-protect
		 (PRINT object s)
	      (CLOSE s)))))

(cl:defun OPEN (filespec &key (DIRECTION (kw INPUT)) (ELEMENT-TYPE 'CHARACTER)
		              IF-EXISTS IF-DOES-NOT-EXIST
			      (EXTERNAL-FORMAT (kw DEFAULT)))
  (MAKE-STREAM (kw filename) (when (eq DIRECTION (kw OUTPUT)) filespec)
	       (kw content) (let ((buffer (create-file-buffer filespec)))
			      (when (eq DIRECTION (kw INPUT))
				(save-current-buffer
				  (set-buffer buffer)
				  (insert-file-contents-literally filespec)))
			      buffer)
	       (kw index) 0
	       (kw read-fn)
	         (lambda (stream)
		   (save-current-buffer
		     (set-buffer (STREAM-content stream))
		     (if (= (STREAM-index stream) (buffer-size))
			 :eof
			 (char-after (incf (STREAM-index stream))))))
	       (kw write-fn)
	         (lambda (char stream)
		   (save-current-buffer
		     (set-buffer (STREAM-content stream))
		     (goto-char (incf (STREAM-index stream)))
		     (insert char)))))

;;; TODO: stream-external-format

(defmacro* WITH-OPEN-FILE ((stream filespec &rest options) &body body)
  `(WITH-OPEN-STREAM (,stream (OPEN ,filespec ,@options))
     ,@body))

(cl:defmacro WITH-OPEN-FILE ((stream filespec &rest options) &body body)
  `(WITH-OPEN-STREAM (,stream (OPEN ,filespec ,@options))
     ,@body))

(cl:defun CLOSE (stream &key ABORT)
  (when (STREAM-filename stream)
    (save-current-buffer
      (set-buffer (STREAM-content stream))
      (write-region 1 (1+ (buffer-size)) (STREAM-filename stream))))
  (when (bufferp (STREAM-content stream))
    (kill-buffer (STREAM-content stream)))
  T)

(cl:defmacro WITH-OPEN-STREAM ((var stream) &body body)
  `(LET ((,var ,stream))
     (UNWIND-PROTECT
	  (PROGN ,@body)
       (CLOSE ,var))))

(defmacro* WITH-OPEN-STREAM ((var stream) &body body)
  `(let ((,var ,stream))
     (unwind-protect
	  (progn ,@body)
       (CLOSE ,var))))

(cl:defun LISTEN (&optional stream-designator)
  (let ((stream (input-stream stream-designator)))
     (if (eq (STREAM-read-fn stream)
	     (cl:function read-char-exclusive-ignoring-arg))
	 (not (sit-for 0))
	 (not (eq (PEEK-CHAR nil stream :eof) :eof)))))

;;; TODO: clear-input

;;; TODO: finish-output, force-output, clear-output

(defun Y-OR-N-P (&optional format &rest args)
  (when format
    (FRESH-LINE *QUERY-IO*)
    (apply #'FORMAT *QUERY-IO* format args))
  (catch 'Y-OR-N-P
    (loop
     (let ((char (READ-CHAR *QUERY-IO*)))
       (cond
	 ((CHAR-EQUAL char (ch 89))
	  (throw 'Y-OR-N-P T))
	 ((CHAR-EQUAL char (ch 78))
	  (throw 'Y-OR-N-P nil))
	 (t
	  (WRITE-LINE "Please answer 'y' or 'n'. ")))))))

(defun YES-OR-NO-P (&optional format &rest args)
  (when format
    (FRESH-LINE *QUERY-IO*)
    (apply #'FORMAT *QUERY-IO* format args))
  (catch 'YES-OR-NO-P
    (loop
     (let ((line (READ-LINE *QUERY-IO*)))
       (cond
	 ((STRING-EQUAL line "yes")
	  (throw 'YES-OR-NO-P T))
	 ((STRING-EQUAL line "no")
	  (throw 'YES-OR-NO-P nil))
	 (t
	  (WRITE-LINE "Please answer 'yes' or 'no'. ")))))))

;;; TODO: make-synonym-stream

;;; TODO: synonym-stream-symbol

;;; TODO: broadcast-stream-streams

;;; TODO: make-broadcast-stream

(defun MAKE-TWO-WAY-STREAM (input output)
  (MAKE-STREAM (kw content) (cons input output)
	       (kw index) 0
	       (kw read-fn)
	         (lambda (stream)
		   (CHAR-CODE (READ-CHAR (car (STREAM-content stream)))))
	       (kw write-fn)
	         (lambda (char stream)
		   (WRITE-CHAR (CODE-CHAR char)
			       (cdr (STREAM-content stream))))))

(defun TWO-WAY-STREAM-INPUT-STREAM (stream)
  (car (STREAM-content stream)))

(defun TWO-WAY-STREAM-OUTPUT-STREAM (stream)
  (cdr (STREAM-content stream)))

;;; TODO: echo-stream-input-stream, echo-stream-output-stream

;;; TODO: make-echo-stream

;;; TODO: concatenated-stream-streams

;;; TODO: make-concatenated-stream

(defun GET-OUTPUT-STREAM-STRING (stream)
  (STREAM-content stream))

(cl:defun MAKE-STRING-INPUT-STREAM (string &optional (start 0) end)
  (MAKE-STREAM (kw content) (let ((substr (substring string start end)))
			      (if (> (length substr) 0)
				  substr
				  :eof))
	       (kw index) start
	       (kw end) (or end (LENGTH string))
	       (kw read-fn)
	         (lambda (stream)
		   (cond
		     ((eq (STREAM-content stream) :eof)
		      :eof)
		     ((= (STREAM-index stream) (STREAM-end stream))
		      (setf (STREAM-content stream) :eof))
		     (t
		      (aref (STREAM-content stream)
			    (1- (incf (STREAM-index stream)))))))
	       (kw write-fn) nil))

(cl:defun MAKE-STRING-OUTPUT-STREAM (&key (ELEMENT-TYPE 'CHARACTER))
  (MAKE-STREAM (kw content) ""
	       (kw index) 0
	       (kw read-fn) nil
	       (kw write-fn)
	         (lambda (char stream)
		   (setf (STREAM-content stream)
			 (concat (STREAM-content stream)
				 (list char))))))

(cl:defmacro WITH-INPUT-FROM-STRING ((var string &key INDEX START END)
				     &body body)
  (when (null START)
    (setq START 0))
  `(WITH-OPEN-STREAM (,var (MAKE-STRING-INPUT-STREAM ,string ,START ,END))
     ,@body))

(defmacro* WITH-OUTPUT-TO-STRING ((var &optional string &key ELEMENT-TYPE)
				  &body body)
  (when (null ELEMENT-TYPE)
    (setq ELEMENT-TYPE ''CHARACTER))
  (if string
      `(WITH-OPEN-STREAM (,var (make-fill-pointer-output-stream ,string))
	 ,@body)
      `(WITH-OPEN-STREAM (,var (MAKE-STRING-OUTPUT-STREAM
				,(kw ELEMENT-TYPE) ,ELEMENT-TYPE))
	 ,@body
	 (GET-OUTPUT-STREAM-STRING ,var))))

(cl:defmacro WITH-OUTPUT-TO-STRING ((var &optional string &key ELEMENT-TYPE)
				    &body body)
  (when (null ELEMENT-TYPE)
    (setq ELEMENT-TYPE '(QUOTE CHARACTER)))
  (if string
      `(WITH-OPEN-STREAM (,var (make-fill-pointer-output-stream ,string))
	 ,@body)
      `(WITH-OPEN-STREAM (,var (MAKE-STRING-OUTPUT-STREAM
				,(kw ELEMENT-TYPE) ,ELEMENT-TYPE))
	 ,@body
	 (GET-OUTPUT-STREAM-STRING ,var))))

(defvar *DEBUG-IO* nil)
(defvar *ERROR-OUTPUT* nil)
(defvar *QUERY-IO* nil)
;;; *STANDARD-INPUT* defined above.
;;; *STANDARD-OUTPUT* defined above.
(defvar *TRACE-OUTPUT* nil)
;;; *TERMINAL-IO* defined above.

;;; STREAM-ERROR, STREAM-ERROR-STREAM, and END-OF-FILE defined by
;;; cl-conditions.el.


(defun make-buffer-output-stream (buffer)
  (MAKE-STREAM (kw content) buffer
	       (kw index) 0
	       (kw read-fn) nil
	       (kw write-fn) (lambda (char stream)
			       (insert char)
			       (when (eq char 10)
				 (sit-for 0)))))

(defun make-read-char-exclusive-input-stream ()
  (MAKE-STREAM (kw content) nil
	       (kw index) 0
	       (kw read-fn) (cl:function read-char-exclusive-ignoring-arg)
	       (kw write-fn) nil))

(defun make-fill-pointer-output-stream (string)
  (MAKE-STREAM (kw content) string
	       (kw index) 0
	       (kw read-fn) nil
	       (kw write-fn) (lambda (char stream)
			       (VECTOR-PUSH-EXTEND
				(CODE-CHAR char)
				(STREAM-content stream)))))
