(import
 (owl toplevel)
 (prefix (sqlite) s3/)
 (common))

(define *timeout-seconds* 5)

(define spcut (string->regex "c/ /"))

(define (handle-client ptr ip port)
  (if (interact 'timeout ip)
      (let ((l (spcut (lcar (lines port)))))
        (if (> (len l) 1)
            (print-to port (add-link* ptr (car l) (cadr l)))
            (print-to port (add-link ptr (car l)))))
      (print-to port "You're on a timeout. Give yourself a sec to rest."))
  (close-port port))

(define (start-server ptr)
  (lets ((sock (open-tcp-socket *port*)))
    (print "listening on " *port*)
    (let loop ()
      (lets ((ip p (tcp-client sock)))
        (thread (string->symbol (str "client-" (time-ns))) (handle-client ptr ip p))
        (loop)))))

;; ips = alist of (ip . time)
(define (start-timeouter)
  (let loop ((ips #n))
    (lets ((to ip (next-mail)))
      (lets ((l (assoc ip ips)))
        (if l
            (if (> (- (time) *timeout-seconds*) (cdr l))
                (begin (mail to #t) (loop (map (λ (v) (if (equal? (car v) ip) (cons ip (time)) v))
                                               ips)))
                (begin (mail to #f) (loop ips)))
            (begin (mail to #t) (loop (append ips (list (cons ip (time)))))))))))

(λ (args)
  (thread 'timeout (start-timeouter))
  (let* ((dbloc (if (> (len args) 1) (lref args 1) "public/private/db.sqlite"))
         (ptr (s3/open dbloc)))
    (init-db ptr)
    (start-server ptr)))
