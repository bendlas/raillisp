
(set start-time (utime))
(set start-here (here))

(defcode if (test true &rest false)
  (compile-r test)
  (if,)
  (compile true)
  (else,)
  (compile-progn false)
  (then,))

(defcode while (test &rest body)
  (begin,)
  (compile-r test)
  (while,)
  (compile-list-nr body)
  (repeat,)
  (maybe-ret))

(defmacro dolist (spec &rest body)
  (list 'let* (list (list '--tail-- (car (cdr spec)))
                    (list (car spec) 'nil))
        (list 'while '--tail--
              (list 'set (car spec) '(car --tail--))
              '(set --tail-- (cdr --tail--))
              (cons 'progn body))))

(defcode cond (&rest forms)
  (dolist (x forms)
    (compile-r (car x))
    (if,)
    (compile-progn (cdr x))
    (else,))
  (dolist (x forms)
    (then,)))

(defcode and (&rest conditions)
  (dolist (x conditions)
    (compile-r x)
    (if,))
  (return-lit t)
  (dolist (x conditions)
    (else,)
    (return-lit nil)
    (then,)))


(def println (obj)
     (print obj)
     (cr))

(var lisp-init-time (- (utime) start-time))
(var lisp-dict-space (- (here) start-here))
