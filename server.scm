(import
 (owl toplevel)
 (prefix (sqlite) s3/)
 (common))

(define spcut (string->regex "c/ /"))
(define (handle-client ptr port)
  (let ((l (spcut (lcar (lines port)))))
    (if (> (len l) 1)
        (print-to port (add-link* ptr (car l) (cadr l)))
        (print-to port (add-link ptr (car l)))))
  (close-port port))

(define (start-server ptr)
  (lets ((sock (open-tcp-socket *port*)))
    (print "listening on " *port*)
    (let loop ()
      (lets ((_ p (tcp-client sock)))
        (thread (string->symbol (str "client-" (time-ns))) (handle-client ptr p))
        (loop)))))

(λ (args)
  (let* ((dbloc (if (> (len args) 1) (lref args 1) "public/private/db.sqlite"))
         (ptr (s3/open dbloc)))
    (init-db ptr)
    (start-server ptr)))
