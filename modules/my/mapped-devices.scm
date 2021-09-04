;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2016 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2017, 2018 Mark H Weaver <mhw@netris.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (my mapped-devices)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module ((guix modules) #:hide (file-name->module-name))
  #:use-module (guix i18n)
  #:use-module ((guix diagnostics)
                #:select (source-properties->location
                          formatted-message
                          &fix-hint
                          &error-location))
  #:use-module (guix deprecation)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (gnu system uuid)
  #:use-module (gnu system mapped-devices)
  #:autoload   (gnu build file-systems) (find-partition-by-luks-uuid)
  #:autoload   (gnu build linux-modules)
                 (missing-modules)
  #:autoload   (gnu packages cryptsetup) (cryptsetup-static)
  #:autoload   (gnu packages linux) (mdadm-static lvm2-static)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-35)
  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (my initrd-coreutils-static)
  #:re-export (%mapped-device
            mapped-device
            mapped-device?
            mapped-device-source
            mapped-device-target
            mapped-device-targets
            mapped-device-type
            mapped-device-location

            mapped-device-kind
            mapped-device-kind?
            mapped-device-kind-open
            mapped-device-kind-close
            mapped-device-kind-check

            device-mapping-service-type
            device-mapping-service

            check-device-initrd-modules           ;XXX: needs a better place

            luks-device-mapping
            raid-device-mapping
            lvm-device-mapping)
  #:export (luks-auto-pass-device-mapping
	    %setup_data_0))

(define %setup_data_0 "/sys/kernel/boot_params/setup_data/0/data") ;;gexp cant find source to this file, so hardcode for now


(define (open-luks-auto-pass-device source targets)
  "Return a gexp that maps SOURCE to TARGET as a LUKS device, using
'cryptsetup'."
  (with-imported-modules (source-module-closure
                          '((gnu build file-systems)(ice-9 popen)(ice-9 rdelim)))
    (match targets
      ((target)
       #~(let ((source #$(if (uuid? source)
                             (uuid-bytevector source)
                             source)))
           ;; XXX: 'use-modules' should be at the top level.
           (use-modules (rnrs bytevectors) ;bytevector?
                        ((gnu build file-systems)
                         #:select (find-partition-by-luks-uuid))
			((ice-9 popen)
			 #:select (open-pipe*))
			((ice-9 rdelim)
			 #:select (read-line)))
	   
           ;; Use 'cryptsetup-static', not 'cryptsetup', to avoid pulling the
           ;; whole world inside the initrd (for when we're in an initrd).
	   ;;; Redirecting cryptesetup stdin...
	   ;;;; with-input-from-port redirects the thunk-process stdin to the given file
	   ;;;; open-pipe* when OPEN_READ sets its output port to thunk-process output port,
	   ;;;;  and inhereits the thunk-process stdin/input-port... is there an easier way
	   ;;;;   while still using execvp?
	   ;;;;NOTE-using with-input-from-port so the port can be non-buffering
	     
	    (define output-from-cryptsetup (with-input-from-port 
	       (open-file "/sys/kernel/boot_params/setup_data/0/data" "r0") ; <--password from grub
	      (lambda () (open-pipe* OPEN_READ #$(file-append cryptsetup-static "/sbin/cryptsetup")
                           "open" "-d" "-" "--type" "luks"

                           ;; Note: We cannot use the "UUID=source" syntax here
                           ;; because 'cryptsetup' implements it by searching the
                           ;; udev-populated /dev/disk/by-id directory but udev may
                           ;; be unavailable at the time we run this.
                           (if (bytevector? source)
                               (or (let loop ((tries-left 10))
                                     (and (positive? tries-left)
                                          (or (find-partition-by-luks-uuid source)
                                              ;; If the underlying partition is
                                              ;; not found, try again after
                                              ;; waiting a second, up to ten
                                              ;; times.  FIXME: This should be
                                              ;; dealt with in a more robust way.
                                              (begin (sleep 1)
                                                     (loop (- tries-left 1))))))
                                   (error "LUKS partition not found" source))
                               source)
                           #$target))))
 
	    ;; if stdin cryptsetup and chmod succeeded then return true, otherwise call old open-luks-device method
	    (if (and (eof-object? (read-line output-from-cryptsetup))
		     (eof-object? (read-line (open-pipe* OPEN_READ #$(file-append %initrd-static-binaries "/bin/chmod") "400"
						      "/sys/kernel/boot_params/setup_data/0/data"))))
		#t
		((module-ref (resolve-module '(gnu system mapped-devices)) 'open-luks-device) source targets)))))))

(define close-luks-device (module-ref (resolve-module '(gnu system mapped-devices)) 'close-luks-device)) 
(define check-luks-device (module-ref (resolve-module '(gnu system mapped-devices)) 'check-luks-device))

(define luks-auto-pass-device-mapping
   ;; The type of LUKS mapped devices.
  (mapped-device-kind
   (open open-luks-auto-pass-device)
   (close close-luks-device)
   (check check-luks-device)))

;;; my  mapped-devices.scm ends here
