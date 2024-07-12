(define-library (common)
  (import
   (owl toplevel)
   (owl regex)
   (owl thread)
   (prefix (sqlite) s3/))

  (export
   *port*
   P
   caar*
   but-last*
   but-last
   init-db
   last-id
   new-id
   has-id?
   add-link
   add-link*
   get-link
   qsplit
   lref*
   )

  (begin
    (define *port* 9420)

    (define (P s) (write-bytes stdout (string->list s)))
    (define (caar* v) (car* (car* v)))
    (define (but-last* l)
      (let loop ((l l) (acc ()))
        (if (null? (cdr* l))
            (values acc (car* l))
            (loop (cdr l) (append acc (list (car l)))))))

    (define (but-last l)
      (let loop ((l l) (acc ()))
        (if (null? (cdr* l))
            acc
            (loop (cdr l) (append acc (list (car l)))))))

    (define (init-db ptr)
      (s3/execute ptr "create table if not exists links (id integer primary key, tid text, target text, custom integer)"))

    (define (last-id ptr)
      (let ((v (caar* (s3/execute* ptr "select tid from links where custom = 0 order by id desc limit 1" #n))))
        (if (null? v) "a" v)))

    (define (new-id ptr)
      (let ((lid (string->list (last-id ptr))))
        (if (> (+ (last lid 0) 1) #\z)
            (list->string (make-list (+ (length lid) 1) #\a))
            (lets ((l r (but-last* lid)))
              (list->string (append l (list (+ r 1))))))))

    (define (has-id? ptr id)
      (not (null? (s3/execute* ptr "select tid from links where tid = ?" (list id)))))

    (define maxlen 1024)
    (define (sanity-check l id)
      (and (< (string-length l) maxlen)
           (< (string-length id) maxlen)))

    (define (add-link ptr l)
      (if (sanity-check l "")
          (let ((id (new-id ptr)))
            (s3/execute* ptr "insert into links (tid, target, custom) values (?,?,0)" (list id l))
            id)
          "link or id too long"))

    (define (add-link* ptr l id)
      (if (sanity-check l id)
          (if (has-id? ptr id)
              "id already points to other link."
              (begin
                (s3/execute* ptr "insert into links (tid, target, custom) values (?,?,1)" (list id l))
                id))
          "link or id too long"))

    (define (get-link ptr tid)
      (caar* (s3/execute* ptr "select target from links where tid = ?" (list tid))))

    (define qsplit (string->regex "c/\\?/"))

    (define (lref* l n)
      (try (λ () (lref l n)) ""))
    ))
