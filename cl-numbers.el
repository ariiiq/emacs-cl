;;; -*- emacs-lisp -*-
;;;
;;; Copyright (C) 2003 Lars Brinkhoff.
;;;
;;; This file implements operators in chapter 12, Numbers.

(in-package "CL")

(defun cl:= (number &rest numbers)
  (every (lambda (n) (two-arg-= number n)) numbers))

(defun two-arg-= (num1 num2)
  (cond
    ((and (or (integerp num1) (floatp num1))
	  (or (integerp num2) (floatp num2)))
     (= num1 num2))
    ((or (complexp num1) (complexp num2))
     (and (two-arg-= (realpart num1) (realpart num2))
	  (two-arg-= (imagpart num1) (imagpart num2))))
    ((or (cl::ratiop num1) (cl::ratiop num2))
     (and (two-arg-= (numerator num1) (numerator num2))
	  (two-arg-= (denominator num1) (denominator num2))))
    ((and (cl::bignump num1) (cl::bignump num2))
     (and (= (length num1) (length num2))
	  (every #'eql num1 num2)))
    ((and (cl:numberp num1) (cl:numberp num2))
     nil)
    (t
     (error "type error: = %s %s" num1 num2))))

;;; TODO: /=

(defun cl:< (number &rest numbers)
  (if (null numbers)
      t
      (and (two-arg-< number (first numbers))
	   (apply #'cl:< (first numbers) (rest numbers)))))

(defun two-arg-< (num1 num2)
  (cond
    ((and (or (integerp num1) (floatp num1))
	  (or (integerp num2) (floatp num2)))
     (< num1 num2))
    ((or (cl::ratiop num1) (cl::ratiop num2))
     ;; TODO
     (< (/ (numerator num1) (denominator num1))
	(/ (numerator num2) (denominator num2))))
    ((or (cl::bignump num1) (cl::bignump num2))
     ;; TODO
     nil)
    (t
     (error "type error: = %s %s" num1 num2))))

;;; TODO: >

(defun cl:<= (number &rest numbers)
  (if (null numbers)
      t
      (and (two-arg-<= number (first numbers))
	   (apply #'cl:<= (first numbers) (rest numbers)))))

(defun two-arg-<= (num1 num2)
  (cond
    ((and (or (integerp num1) (floatp num1))
	  (or (integerp num2) (floatp num2)))
     (<= num1 num2))
    ((or (cl::ratiop num1) (cl::ratiop num2))
     ;; TODO
     (<= (/ (numerator num1) (denominator num1))
	 (/ (numerator num2) (denominator num2))))
    ((or (cl::bignump num1) (cl::bignump num2))
     ;; TODO
     nil)
    (t
     (error "type error: = %s %s" num1 num2))))

;;; TODO: >=

;;; TODO: max

;;; TODO: min

(defun cl:minusp (num)
  (cond
    ((or (integerp num) (floatp num))
     (minusp num))
    ((cl::bignump num)
     (minusp (aref num (1- (length num)))))
    ((cl::ratiop num)
     (minusp (numerator num)))
    (t
     (error "type error"))))

(defun cl:plusp (num)
  (cond
    ((or (integerp num) (floatp num))
     (plusp num))
    ((cl::bignump num)
     (plusp (aref num (1- (length num)))))
    ((cl::ratiop num)
     (plusp (numerator num)))
    (t
     (error "type error"))))

(defun cl:zerop (num)
  (cond
    ((or (integerp num) (floatp num))
     (zerop num))
    ((cl::ratiop num)
     (zerop (numerator num)))
    ((complexp num)
     (and (cl:zerop (realpart num)) (cl:zerop (imagpart num))))
    (t
     (error "type error"))))

;;; TODO: FLOOR, FFLOOR, CEILING, FCEILING, TRUNCATE, FTRUNCATE, ROUND, FROUND

;;; TODO: SIN, COS, TAN

;;; TODO: ASIN, ACOS, ATAN

;;; TODO: (defconstast pi ...)

;;; TODO: SINH, COSH, TANH, ASINH, ACOSH, ATANH

(defun cl:* (&rest numbers)
  (reduce #'two-arg-* numbers :initial-value 1))

(defun two-arg-* (x y)
  (cond
    ((and (or (integerp x) (floatp x))
	  (or (integerp y) (floatp y)))
     (* x y))
    (t
     (error "TODO"))))

(defun cl:+ (&rest numbers)
  (reduce #'two-arg-+ numbers :initial-value 0))

(defun two-arg-+ (x y)
  (cond
    ((and (integerp x) (integerp y))
     (let ((sum (+ x y)))
       (cond
	 ((and (>= x 0) (>= y 0) (minusp sum))
	  (vector 'bignum sum 0))
	 ((and (minusp x) (minusp y) (>= sum 0))
	  (vector 'bignum sum -1))
	 (t
	  sum))))
    ((or (complexp x) (complexp y))
     (complex (two-arg-+ (realpart x) (realpart y))
	      (two-arg-+ (imagpart x) (imagpart y))))
    ((floatp x)
     (+ x (cl:float y)))
    ((floatp y)
     (+ (cl:float x) y))
    ((or (cl::ratiop x) (cl::ratiop y))
     (cl::ratio (two-arg-+ (cl:* (numerator x) (denominator y))
		       (cl:* (denominator y) (numerator x)))
	    (cl:* (denominator x) (denominator y))))
    ((or (cl::bignump x) (cl::bignump y))
     (cond
       ((integerp x)	(bignum+fixnum y x))
       ((integerp y)	(bignum+fixnum x y))
       (t		(bignum+bignum x y))))
    (t
     (error))))

(defun bignum+fixnum (x y)
  (let* ((x0 (aref x 1))
	 (sum (+ x0 y))
	 (new (copy-sequence x)))
    (aset new 1 sum)
    (cond
      ((and (minusp x0) (>= y 0) (>= sum 0))
       (bignum+bignum new [bignum 0 1]))
      ((and (>= x0 0) (minusp y) (minusp sum))
       (bignum+bignum new [bignum 0 -1])))
    new))

(defun bignum+bignum (x y)
  (list-bignum (bignum+ (bignum-list x) (bignum-list x))))

(defun* bignum-list (num &optional (index 1))
  (if (= index (length num))
      nil
      (cons (aref num index) (bignum-list num (1+ index)))))

(defun list-bignum (list)
  (let ((bignum (make-vector (1+ (length list)) 'bignum))
	(i 0))
    (dolist (n list)
      (aset bignum (incf i) n))
    bignum))

(defun* bignum+ (x y &optional (carry 0))
  (cond
    ((null x)
     (if (zerop carry)
	 y
	 (bignum+ y (list carry))))
    ((null y)
     (if (zerop carry)
	 x 
	 (bignum+ x (list carry))))
    (t
     (let* ((x0 (car x))
	    (y0 (car y))
	    (sum (+ x0 y0))
	    (new (copy-sequence x))
	    (carry 0))
       (aset new 1 sum)
       (cond
	 ((and (minusp x0) (>= y0 0) (>= 0 sum))
	   (setq carry 1))
	  ((and (>= x0 0) (minusp y0) (>= 0 sum))
	   (setq carry 1)))
	(let* ((x1 (aref x 2))
	       (y1 (aref y 2))
	       (sum (+ x1 y1 carry)))
	  (aset new 2 sum))
	new))

(defun cl:- (number &rest numbers)
  (if (null numbers)
      (cond
	((integerp number)
	 (if (eql number most-negative-fixnum)
	     (vector 'bignum 0)
	     (- number)))
	((floatp number)
	 (- number))
	((cl::ratiop number)
	 (vector 'ratio (- (numerator number)) (denominator number)))
	((complexp number)
	 (vector 'complex (- (realpart number)) (- (imagpart number))))
	((cl::bignump number)
	 0)
	(t
	 (error)))
      (dolist (num numbers number)
	(setq number (two-arg-- number num)))))

;;; TODO: two-arg--

(defun cl:/ (number &rest numbers)
  (if (null numbers)
      (cond
	((integerp number)
	 (vector 'ratio 1 number))
	((floatp number)
	 (/ 1.0 number))
	((cl::ratiop number)
	 (cl::ratio (denominator number) (numerator number)))
	((complexp number)
	 (let* ((r (realpart number))
		(i (imagpart number))
		(x (cl:- (cl:* r r) (cl:* i i))))
	   (complex (cl:/ r x) (cl:+ (cl:/ i) x))))
	((cl::bignump number)
	 0)
	(t
	 (error)))
      (dolist (num numbers number)
	(setq number (two-arg-/ number num)))))

(defun two-arg-/ (x y)
  (cond
    ((and (integerp x) (integerp y))
     (if (or (and (eql x most-negative-fixnum) (eql y -1))
	     (and (eql y most-negative-fixnum) (eql x -1)))
	 (vector 'bignum 0)
	 (/ x y)))
    ((or (complexp x) (complexp y))
     (let* ((rx (realpart x))
	    (ry (realpart y))
	    (ix (imagpart x))
	    (iy (imagpart y))
	    (div (cl:+ (cl:* ry ry) (cl:* iy iy))))
       (complex (cl:/ (cl:+ (cl:* rx ry) (cl:* ix iy)) div)
		(cl:/ (cl:- (cl:* ix ry) (cl:* rx iy)) div))))
    ((floatp x)
     (/ x (cl:float y)))
    ((floatp y)
     (/ (cl:float x) y))
    ((or (cl::ratiop x) (cl::ratiop y))
     (cl::ratio (cl:* (numerator x) (denominator y))
	    (cl:* (denominator x) (numerator y))))
    ;; bignum
    (t 0)))
  
(defun cl:1+ (number)
  (cl:+ number 1))

(defun cl:1- (number)
  (cl:- number 1))

(defun cl:abs (number)
  (cond
    ((integerp number)
     (if (eql number most-negative-fixnum)
	 (vector 'bignum 0)
	 (abs number)))
    ((floatp number)
     (abs number))
    ((cl::ratiop number)
     (vector 'ratio (cl:abs (numerator number)) (denominator number)))
    ((complexp number)
     (sqrt (+ (expt (realpart number) 2) (expt (imagpart number) 2))))
    ((cl::bignump number)
     0)
    (t
     (error))))

;;; TODO: EVENP, ODDP

;;; TODO: EXP, EXPT

(defun gcd (&rest numbers)
  (reduce #'two-arg-gcd numbers :initial-value 0))

(defun two-arg-gcd (x y)
  (if (and (integerp x) (integerp y))
      (progn
	(when (> y x)
	  (psetq x y y x))
	(while (not (zerop y))
	  (psetq y (% x y) x y))
	(abs x))
      0))

;;; TODO: INCF, DECF

;;; TODO: LCM

;;; TODO: LOG

;;; TODO: MOD, REM

;;; TODO: SIGNUM

;;; TODO: SQRT, ISQRT

;;; TODO: MAKE-RANDOM-STATE

;;; TODO: RANDOM

;;; TODO: RANDOM-STATE-P

;;; TODO: *RANDOM-STATE*

(defun cl:numberp (object)
  (or (numberp object)
      (and (vectorp object)
	   (let ((type (aref object 0)))
	     (or (eq type 'bignum)
		 (eq type 'ratio)
		 (eq type 'complex))))))

;;; TODO: CIS

(defun complex (realpart &optional imagpart)
  (check-type realpart 'real)
  (if (or (null imagpart) (zerop imagpart))
      realpart
      (progn
	(check-type realpart 'real)
	(when (floatp realpart)
	  (setq imagpart (float realpart)))
	(when (floatp imagpart)
	  (setq realpart (float realpart)))
	(vector 'complex realpart imagpart))))

(defun complexp (object)
  (and (vectorp object) (eq (aref object 0) 'complex)))

(defun conjugage (num)
  (complex (realpart num) (- (imagpart num))))

(defun phase (num)
  (atan (imagpart num) (realpart num)))

(defun realpart (num)
  (if (complexp num)
      (aref num 1)
      num))

(defun imagpart (num)
  (if (complexp num)
      (aref num 2)
      0))

(defun upgraded-complex-part-type (typespec &optional env)
  'real)

(defun realp (num)
  (or (rationalp num) (floatp num)))

(defun cl::ratio (num den)
  (let* ((gcd (gcd num den))
	 (num (cl:/ num gcd))
	 (den (cl:/ den gcd)))
    (cond
      ((eql den 1)
	num)
      ((minusp den)
       (vector 'ratio (cl:- num) den))
      (t
       (vector 'ratio num den)))))

(defun cl::ratiop (num)
  (and (vectorp num) (eq (aref num 0) 'ratio)))

(defun numerator (num)
  (if (cl::ratiop num)
      (aref num 1)
      num))

(defun denominator (num)
  (if (cl::ratiop num)
      (aref num 2)
      1))

;;; TODO: rational

;;; TODO: rationalize

(defun rationalp (num)
  (or (cl:integerp num) (cl::ratiop num)))

;;; TODO: ash

;;; TODO: integer-length

(defun cl::bignump (num)
  (and (vectorp num) (eq (aref num 0) 'bignum)))

(defun cl:integerp (num)
  (or (integerp num) (cl::bignump num)))

(defun* parse-integer (string &key (start 0) (end (length string))
			      (radix 10) junk-allowed)
  (let ((sign 1)
	(integer 0)
	(i start)
	char digit)
    (while (whitespacep (char string i))
      (incf i)
      (when (= i end)
	(if junk-allowed
	    (return-from parse-integer (values nil i))
	    (error))))
    (setq char (char string i))
    (when (find char "+-")
      (when (char= char (code-char 45))
	(setq sign -1))
      (incf i)
      (when (= i end)
	(if junk-allowed
	    (return-from parse-integer (values nil i))
	    (error)))
      (setq char (char string i)))
    (while (setq digit (digit-char-p char radix))
      (setq integer (+ (* integer radix) digit))
      (incf i)
      (when (= i end)
	(return-from parse-integer (values (* sign integer) i)))
      (setq char (char string i)))
    (cond
      (junk-allowed
       (values (* sign integer) i))
      (t
       (do ((j i (1+ j)))
	   ((= j end)
	    (values (* sign integer) i))
	 (unless (whitespacep (char string j))
	   (error)))))))

(defun cl:lognot (num)
  (cond
    ((integerp num)
     (lognot num))
    ((cl::bignump num)
     (let ((new (make-vector (length num) 0)))
       (aset new 0 'bignum)
       (dotimes (i (1- (length num)))
	 (aset new (1+ i) (lognot (aref num (1+ i)))))
       new))
    (t
     (error "type error"))))

(defun cl:logand (&rest numbers)
  (reduce #'two-arg-logand numbers :initial-value -1))

(defun two-arg-logand (x y)
  (cond
    ((and (integerp x) (integerp y))
     (logand x y))
    ((and (cl::bignump x) (integerp y))
     (let ((new (copy-sequence x)))
       (aset new 1 (logand (aref x 1) y))
       new))
    ((and (cl::bignump y) (integerp x))
     (let ((new (copy-sequence y)))
       (aset new 1 (logand (aref y 1) x))
       new))
    ((and (cl::bignump x) (cl::bignump y))
     0)))

(defun cl:logior (&rest numbers)
  (reduce #'two-arg-logior numbers :initial-value -1))

(defun two-arg-logior (x y)
  (cond
    ((and (integerp x) (integerp y))
     (logior x y))
    ((and (cl::bignump x) (integerp y))
     (let ((new (copy-sequence x)))
       (aset new 1 (logior (aref x 1) y))
       new))
    ((and (cl::bignump y) (integerp x))
     (let ((new (copy-sequence y)))
       (aset new 1 (logior (aref y 1) x))
       new))
    ((and (cl::bignump x) (cl::bignump y))
     0)))

(defun cl:lognand (x y)
  (cl:lognot (cl:logand x y)))

(defun cl:logandc1 (x y)
  (cl:logand (cl:lognot x) y))

(defun cl:logandc2 (x y)
  (cl:logand x (cl:lognot y)))

(defun cl:lognor (x y)
  (cl:lognot (cl:logior x y)))

(defun cl:logorc1 (x y)
  (cl:logior (cl:lognot x) y))

(defun cl:logorc2 (x y)
  (cl:logior x (cl:lognot y)))

(defun cl:logeqv (&rest numbers)
  (cl:lognot (apply #'cl:logxor numbers)))

;;; TODO: logxor

;;; TODO: logbitp

;;; TODO: logcount

;;; TODO: logtest

;;; TODO: byte, byte-size, byte-position

;;; TODO: deposit-field

;;; TODO: dpb

;;; TODO: ldb

;;; TODO: ldb-test

;;; TODO: mask-field

;;; TODO: decode-float, scale-float, float-radix, float-sign, float-digits,
;;; float-precision, integer-decode-float

(defun cl:float (num &optional prototype)
  (cond
    ((integerp num)
     (float num))
    ((floatp num)
     num)
    ((cl::ratiop num)
     (/ (cl:float (numerator num)) (cl:float (denominator num))))
    ((cl::bignump num)
     1.0)
    (t
     (error "type error"))))

;;; floatp ok as is

;;; TODO: ARITHMETIC-ERROR-OPERANDS, ARITHMETIC-ERROR-OPERATION
