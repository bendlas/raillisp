
(set start-time (utime))
(set start-here (here))

(var raillisp-version "0.1")

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

(defcode or (&rest conditions)
  (dolist (x conditions)
    (compile-r x)
    (if,)
    (return-lit t)
    (else,))
  (return-lit nil)
  (dolist (x conditions)
    (then,)))

(defun println (obj)
  (print obj)
  (cr))

(defmacro dotimes (spec &rest body)
  (list 'let* (list (list '--dotimes-limit-- (car (cdr spec)))
                    (list (car spec) 0))
        (list 'while (list '< (car spec) '--dotimes-limit--)
              (cons 'progn body)
              (list 'set (car spec) (list '+ (car spec) 1)))))

(defun repl ()
  (while 1
    (println (eval (read-from-input)))))

(defun mapcar (fn lst)
  (if lst ;TODO: non-recursive version
      (cons (funcall fn (list (car lst))) (mapcar fn (cdr lst)))
    lst))

(defcode when (test &rest body)
  (compile-r test)
  (if,)
  (compile-progn body)
  (then,))

(defun init ()
  (if (not (boundp '_testing_))
      (if (= (list-length command-line-args) 0)
          (progn
            (print "// Raillisp ")
            (print raillisp-version)
            (println " \\\\")
            (repl))
        (load (car command-line-args))
        (bye))
    nil))

(var lisp-init-time (- (utime) start-time))
(var lisp-dict-space (- (here) start-here))

(init)
