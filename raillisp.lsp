
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

(defcode dotimes (spec &rest body)
  (let* ((v (car (cdr spec))))
    (if (int? v)
        (untag-lit, v)
      (compile-r v)
      (untag-num,)))
  (untag-lit, 0)
  (do,)
  (set loop-vars (cons (car spec) loop-vars))
  (compile-list-nr body)
  (set loop-vars (cdr loop-vars))
  (loop,)
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

(defun repl ()
  (var expr nil)
  (cr)
  (while 1
    ;;(print-stack)
    (set expr (read-from-input))
    (if (and (equal? (type-of expr) 'xcons)
             (or (equal? (car expr) 'var)
                 (equal? (car expr) 'defun)))
        (println (eval expr))
      (if expr
          (progn
            (env-mark 'repl-mark)
            (eval (cons 'defun (cons 'repl_ (cons nil (cons expr nil)))))
            (cr)
            (println (funcall (function "repl_") nil))
            (env-revert 'repl-mark))
        nil))))

(defun map (fn lst)
  (while lst
    (funcall fn (list (car lst)))
    (set lst (cdr lst))))

(defun map! (fn lst)
  (while lst
    (setcar lst (funcall fn (list (car lst))))
    (set lst (cdr lst))))

(defun mapcar (fn lst)
  (var head nil)
  (var tail nil)
  (if lst
      (progn
        (set head (cons (funcall fn (list (car lst))) nil))
        (set lst (cdr lst))
        (set tail head))
    nil)
  (while lst
    (setcdr tail (cons (funcall fn (list (car lst))) nil))
    (set tail (cdr tail))
    (set lst (cdr lst)))
  head)

(defcode when (test &rest body)
  (compile-r test)
  (if,)
  (compile-progn body)
  (then,))

(defun caar (x) (car (car x)))
(defun cadr (x) (car (cdr x)))
(defun cdar (x) (cdr (car x)))
(defun cddr (x) (cdr (cdr x)))

(defun nthcdr (n list)
  (dotimes (_ n)
    (set list (cdr list)))
  list)

(defun nth (n list)
  (car (nthcdr n list)))

(defun last (list)
  (if list
      (nthcdr (1- (list-len list)) list)
    nil))

(defun list-copy (l)
  (mapcar identity l))

(defun append! (a b)
  (var end nil)
  (if a
      (progn
        (set end (last a))
        (if end
            (setcdr end b)
          nil))
    (set a b))
  a)

(defun append (a b)
  (append! (list-copy a) (list-copy b)))

(defun make-list (len init)
  (var lst nil)
  (dotimes (_ len)
    (set lst (cons init lst)))
  lst)

(defun count (l e)
  (var c 0)
  (var l l)
  (while l
    (if (equal? (car l) e)
        (set c (1+ c))
      nil)
    (set l (cdr l)))
  c)

(defun reverse (l)
  (var ret nil)
  (while l
    (set ret (cons (car l) ret))
    (set l (cdr l)))
  ret)

(defun nreverse (l)
  (var prev nil)
  (var next nil)
  (while l
    (set next (cdr l))
    (setcdr l prev)
    (set prev l)
    (set l next))
  prev)

(defun take (l n)
  (var head nil)
  (dotimes (_ n)
    (if l
        (progn (set head (cons (car l) head))
               (set l (cdr l)))
      nil))
  (nreverse head))

(defun subseq (lst start end)
  (take (nthcdr start lst) (- end start)))

(defun str-concat (a b)
  (var s (make-empty-str (+ (str-len a) (str-len b))))
  (str-move! s a 0)
  (str-move! s b (str-len a)))

(defun str->list (s)
  (var end (1- (str-len s)))
  (var l nil)
  (dotimes (i (1+ end))
    (set l (cons (str-ref s (- end i)) l)))
  l)

(defun list->str (char-list)
  (var len (list-len char-list))
  (var s (make-str len 0))
  (dotimes (i len)
    (str-set s i (car char-list))
    (set char-list (cdr char-list)))
  s)

(defun str-join (strings sep)
  (var strings-len 0)
  (var ret nil)
  (var sep-len (str-len sep))
  (let* ((len 0))
    (dolist (s strings)
      (set len (+ len (+ (str-len s) sep-len)))
      (set strings-len (1+ strings-len)))
    (set len (- len sep-len))
    (set ret (make-empty-str len)))
  (let* ((offset 0))
    (dotimes (i (1- strings-len))
      (let* ((s (car strings)))
        (set strings (cdr strings))
        (str-move! ret s offset)
        (set offset (+ offset (str-len s))))
      (str-move! ret sep offset)
      (set offset (+ offset sep-len)))
    (str-move! ret (car strings) offset))
  ret)

(defun str-copy (s)
  (str-move! (make-empty-str (str-len s)) s 0))

(defun str-start? (s sub)
  (str-sub-equal? s sub 0))

(defun str-end? (s sub)
  (str-sub-equal? s sub (- (str-len s) (str-len sub))))

(defun str-count (s sub)
  (var sub-len (str-len sub))
  (var count 0)
  (var i 0)
  (var end (- (str-len s) (1- sub-len)))
  (while (< i end)
    (if (str-sub-equal? s sub i)
        (progn (set count (1+ count))
               (set i (+ i sub-len)))
      (set i (1+ i))))
  count)

(defun make-vector (len init)
  (var v (make-empty-vec len))
  (dotimes (i len)
    (vec-set v i init))
  v)

(defun vec->list (v)
  (var ret nil)
  (var len (1- (vec-len v)))
  (dotimes (i (1+ len))
    (set ret (cons (vec-ref v (- len i)) ret)))
  ret)

(defun list->vec (l)
  (var len (list-len l))
  (var v (make-empty-vec len))
  (dotimes (i len)
    (vec-set v i (car l))
    (set l (cdr l)))
  v)

(defmacro vector (&rest objects)
  (cons 'list->vec (cons (cons 'list objects) nil)))

(defun vec-map (v fn)
  (dotimes (i (vec-len v))
    (funcall fn (list (vec-ref v i))))
  v)

(defun vec-map! (v fn)
  (dotimes (i (vec-len v))
    (vec-set v i (funcall fn (list (vec-ref v i))))))

(defun vec-copy (v)
  (vec-move! (make-empty-vec (vec-len v)) v 0))

(defun vec-append (a b)
  (var s (make-empty-vec (+ (vec-len a) (vec-len b))))
  (vec-move! s a 0)
  (vec-move! s b (vec-len a)))

(defun vec-index (v e)
  (var index -1)
  (var end (vec-len v))
  (var i 0)
  (while (< i end)
    (if (equal? (vec-ref v i) e)
        (progn (set index i)
               (set i end))
      (set i (1+ i))))
  index)

(defun vec-count (v e)
  (var c 0)
  (dotimes (i (vec-len v))
    (if (equal? (vec-ref v i) e)
        (set c (1+ c))
      nil))
  c)

(defun load (file)
  (if (str-end? file ".lsp")
      (load-lisp file)
    (load-forth file)))

(defun init ()
  (if (not (boundp '_noinit_))
      (progn
        (process-args)
        (if (= (list-len command-line-args) 0)
            (progn
              (print "// Raillisp ")
              (print raillisp-version)
              (println " \\\\")
              (repl))
          (load (car command-line-args))
          (bye))
        nil)))

(var lisp-init-time (- (utime) start-time))
(var lisp-dict-space (- (here) start-here))

(init)
