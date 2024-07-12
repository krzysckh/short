(define-library (sqlite)
  (import
   (owl toplevel))

  (export
   open
   close
   execute
   execute*
   )

  (begin
    (define (prim n . vs)
      (let ((L (length vs)))
        (cond
         ((= L 0) (sys-prim n #f #f #f))
         ((= L 1) (sys-prim n (car vs) #f #f))
         ((= L 2) (sys-prim n (car vs) (cadr vs) #f))
         (else
          (sys-prim n (car vs) (cadr vs) (caddr vs))))))

    (define (type! pred v)
      (when (not (pred v))
        (error "invalid type for value " v)))

    (define (open name)
      (type! string? name)
      (prim 100 (c-string name)))

    (define (close ptr)
      (type! self ptr) ;; ptr is a bytevector, but it might be an opaque type so idc just check if !#f
      (prim 101 ptr))

    (define (execute ptr sql)
      (type! self ptr)
      (type! string? sql)
      (prim 102 ptr (c-string sql)))

    (define (execute* ptr sql bind)
      (type! self ptr)
      (type! string? sql)
      (type! list? bind)
      (prim 103 ptr (c-string sql) (map (λ (v) (if (string? v) (c-string v) v)) bind)))
    ))
