(define-module (my utils)
  #:export (copy-all-refs))

(define* (copy-all-refs module-spec-from module-obj #:optional (less '()))
  (let* ((m (resolve-module module-spec-from))
	 (plist (hash-map->list cons (struct-ref m 0)))
	 (entries (if (null? less)
		      plist
		      (filter (lambda (x) (not (member (car x) less))) plist))))
    (for-each (lambda (x)
		(let
		    ((symbol (car x))
		     (var-ref (variable-ref (cdr x))))
		  (module-define! module-obj symbol var-ref))) entries) #t) 
  )
