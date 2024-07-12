(import
 (owl toplevel)
 (owl regex)
 (prefix (owl sys) sys/)
 (prefix (sqlite) s3/)
 (common))

(define (count ptr)
  (caar* (s3/execute* ptr "select count(tid) from links" #n)))

(define (info ptr)
  (print "powered by short")
  (print "running on " (sys/getenv "SERVER_SOFTWARE") " with owl " *owl-version*)
  (print "there are currently " (count ptr) " links stored"))

(λ (args)
  (sys/chdir (fold (λ (a b) (string-append a b "/")) "/" (cdr (but-last ((string->regex "c/\\//") (sys/getenv "SCRIPT_FILENAME"))))))
  (let* ((ptr (s3/open "private/db.sqlite"))
         (uri (sys/getenv "REQUEST_URI"))
         (l (qsplit (if uri uri ""))))
    (init-db ptr)

    (cond
     ((string=? (lref* args 1) "add") ;; ran from command line, append next arg to db and print tid
      (print (add-link ptr (lref args 2)))
      0)
     ((> (len l) 1)
      (let ((l (get-link ptr (last l "a"))))
        (if (null? l)
            (P "Content-type: text/plain\r\n\r\ninvalid request: no such link")
            (P (string-append
                "Content-type: text/html\r\n"
                "Location: " l "\r\n\r\n"
                "<meta http-equiv=\"Refresh\" content=\"0; url='" l "'\" />")))))
     (else
      (P "Content-type: text/plain\r\n\r\n")
      (info ptr)))


    (s3/close ptr))
  0)
