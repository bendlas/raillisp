
(var start-time (utime))
(var start-here (here))

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
  (maybe-ret)
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

(defmacro when (test &rest body)
  (list 'if test (cons 'progn body) nil))

(defmacro unless (test &rest body)
  (cons 'when (cons (list 'not test) body)))

(defun println (obj)
  (print obj)
  (cr))

(defun map (fn lst)
  (var tmp lst)
  (while tmp
    (funcall fn (list (car tmp)))
    (set tmp (cdr tmp)))
  lst)

(defun map! (fn lst)
  (var curr lst)
  (while curr
    (setcar curr (funcall fn (list (car curr))))
    (set curr (cdr curr)))
  lst)

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

(defun caar (x) (car (car x)))
(defun cadr (x) (car (cdr x)))
(defun cdar (x) (cdr (car x)))
(defun cddr (x) (cdr (cdr x)))
(defun caaar (x) (car (car (car x))))
(defun caadr (x) (car (car (cdr x))))
(defun cadar (x) (car (cdr (car x))))
(defun caddr (x) (car (cdr (cdr x))))
(defun cdaar (x) (cdr (car (car x))))
(defun cdadr (x) (cdr (car (cdr x))))
(defun cddar (x) (cdr (cdr (car x))))
(defun cdddr (x) (cdr (cdr (cdr x))))

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

(defmacro pop (sym)
  (list 'progn (list 'var '__first (list 'car sym))
        (list 'set sym (list 'cdr sym))
        '__first))

(defmacro push (elt sym)
  (list 'progn (list 'set sym (list 'cons elt sym))))

(defun str-concat (a b)
  (var s (make-empty-str (+ (str-len a) (str-len b))))
  (str-move! s a 0 0 nil)
  (str-move! s b (str-len a) 0 nil))

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

(defun str-split (s char)
  (var ret nil)
  (var start 0)
  (var end 0)
  (var len (str-len s))
  (while (< end len)
    (if (eq? (str-ref s end) char)
        (let* ((length (- end start)))
          (set ret (cons (str-move! (make-empty-str length)
                                    s 0 start length)
                         ret))
          (set start (1+ end))
          (set end start))
      (set end (1+ end))))
  (when (< start end)
    (let* ((length (- end start)))
      (set ret (cons (str-move! (make-empty-str length)
                                s 0 start length)
                     ret))))
  (nreverse ret))

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
        (str-move! ret s offset 0 nil)
        (set offset (+ offset (str-len s))))
      (str-move! ret sep offset 0 nil)
      (set offset (+ offset sep-len)))
    (str-move! ret (car strings) offset 0 nil))
  ret)

(defun str-copy (s)
  (str-move! (make-empty-str (str-len s)) s 0 0 nil))

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

(defun vec-map (v fn)
  (dotimes (i (vec-len v))
    (funcall fn (list (vec-ref v i))))
  v)

(defun vec-map! (v fn)
  (dotimes (i (vec-len v))
    (vec-set v i (funcall fn (list (vec-ref v i)))))
  v)

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

(defun make-q ()
  (cons nil nil))

(defun q-put! (q item)
  (var new (cons item nil))
  (var tail (cdr q))
  (unless (car q)
    (setcar q new))
  (when tail
    (setcdr tail new))
  (setcdr q new)
  q)

(defun q-get! (q)
  (var first (car q))
  (when first
    (setcar q (cdr first))
    (when (eq? first (cdr q))
      (setcdr q nil)))
  (car first))

(defun q-len (q)
  (list-len (car q)))

(defun q->list (q)
  (list-copy (car q)))

(defun macroexpand-all (form)
  (set form (macroexpand form))
  (when (cons? form)
    (map! macroexpand-all form))
  form)

(defun repl ()
  (var expr nil)
  (var var-name nil)
  (cr)
  (while 1
    ;; (print-stack) (cr)
    (set expr (read-from-input))
    (set var-name nil)
    (cond ((not (equal? (type-of expr) 'cons))
           nil)
          ((equal? (car expr) 'var)
           (set var-name (cadr expr))
           (set expr (car (cddr expr)))
           (eval (list 'var var-name nil)))
          ((or (equal? (car expr) 'defun)
               (equal? (car expr) 'defmacro))
           (println (eval expr))
           (set expr nil)))
    (when expr
      (env-mark 'repl-mark)
      (eval (cons 'defun (cons 'repl_ (cons nil (cons expr nil)))))
      (cr)
      (println (if var-name
                   (eval (list 'set var-name (cons (intern "repl_") nil)))
                 (funcall (symbol-value (intern "repl_")) nil)))
      (env-revert 'repl-mark))))

(defun load (file)
  (if (str-end? file ".lsp")
      (load-lisp file)
    (load-forth file)))

(defun init (doinit)
  (when doinit
    (process-args)
    (if (= (list-len command-line-args) 0)
        (progn
          (print "// Raillisp ")
          (print raillisp-version)
          (println " \\\\")
          (repl))
      (load (car command-line-args))
      (bye))))

(var lisp-init-time (- (utime) start-time))
(var lisp-dict-space (- (here) start-here))
