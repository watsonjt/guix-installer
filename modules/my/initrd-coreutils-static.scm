(define-module (my initrd-coreutils-static)
  #:use-module (guix packages)
  #:export (%initrd-static-binaries))

;;static-binaries is not exported... so force import


(define %static-binaries (module-ref (resolve-module '(gnu packages make-bootstrap)) '%static-binaries))

(define %initrd-static-binaries
  (package
   (inherit %static-binaries)
   (name "initrd-static-binaries")
   (synopsis "statically-linked minimal coreutils for initrd")
   (description "Binaries used during the initrd init")
   (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (ice-9 ftw)
                      (ice-9 match)
                      (srfi srfi-1)
                      (srfi srfi-26)
                      (guix build utils))

         (let ()
          (define (directory-contents dir)
            (map (cut string-append dir "/" <>)
                 (scandir dir (negate (cut member <> '("." ".."))))))

          (define (copy-directory source destination)
            (for-each (lambda (file)
			(define keep (list "chmod")) ;;<-------------------------------ADD/REMOVE binaries
			(define (predicate f) (not (null? (filter-map (lambda (y)
							  (string-contains f y)) keep))))
			(when (predicate file)
			  (format #t "copying ~s...~%" file)
                          (copy-file file
                                   (string-append destination "/"
                                                  (basename file)))))
                      (directory-contents source)))
	  
          (let* ((out (assoc-ref %outputs "out"))
                 (bin (string-append out "/bin")))
            (mkdir-p bin)

	    
            ;; Copy Coreutils binaries.
            (let* (
		   (coreutils (assoc-ref %build-inputs "coreutils"))
                   (source    (string-append coreutils "/bin")))
              (copy-directory source bin))

            #t)))))))

%initrd-static-binaries
