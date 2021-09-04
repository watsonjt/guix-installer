;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2016 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2019 Mathieu Othacehe <m.othacehe@gmail.com>
;;; Copyright © 2019, 2020 Tobias Geerinckx-Rice <me@tobias.gr>
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

(define-module (my linux-initrd)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module ((guix store)
                #:select (%store-prefix))
  #:use-module ((guix derivations)
                #:select (derivation->output-path))
  #:use-module (guix modules)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages disk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages file-systems)
  #:use-module (gnu packages guile)
  #:use-module ((gnu packages xorg)
                #:select (console-setup xkeyboard-config))
  #:use-module ((gnu packages make-bootstrap)
                #:select (%guile-static-stripped))
  #:use-module (gnu system file-systems)
  #:use-module (my mapped-devices)
  #:use-module (gnu system linux-initrd)
  #:use-module (gnu system keyboard)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 vlist)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (gnu system uuid)
  #:autoload   (gnu packages cryptsetup) (cryptsetup-static)
  #:re-export (expression->initrd
            %base-initrd-modules
            raw-initrd
            file-system-packages
            base-initrd
	    luks-auto-pass-device-mapping
	    )
  #:export (initrd-auto-pass))

;;needed access to private ref...
(define flat-linux-module-directory (module-ref (resolve-module '(gnu system linux-initrd)) 'flat-linux-module-directory))

(define* (initrd-auto-pass file-systems
                      #:key
                      (linux linux-libre)
                      (linux-modules '())
                      (mapped-devices '())
                      (keyboard-layout #f)
                      (helper-packages '())
                      qemu-networking?
                      volatile-root?
                      (on-error 'debug))
  "This is a copy of raw-initrd - code changes are in (my mapped-devices)"
  (define device-mapping-commands
    ;; List of gexps to open the mapped devices.
    (map (lambda (md)
	   ;;TODO make custom mapped-device-kind and record..
	   ;;this will not work if there is a non-luks device :(
	   ;;(module-ref (resolve-module '(my linux-initrd)) 'my-open-luks-device)
	   (let* ((source  (mapped-device-source md))
                  (targets (mapped-device-targets md))
                  (type    (mapped-device-type md))
                  (open    (mapped-device-kind-open type)))
             (open source targets)))                       ;;if fail, hard code replace open here
         mapped-devices))

  (define kodir
    (flat-linux-module-directory linux linux-modules))

  (expression->initrd
   (with-imported-modules (source-module-closure
                           '((gnu build linux-boot)
                             (guix build utils)
                             (guix build bournish)
                             (gnu system file-systems)
                             (gnu build file-systems)))
     #~(begin
         (use-modules (gnu build linux-boot)
                      (gnu system file-systems)
                      ((guix build utils) #:hide (delete))
                      (guix build bournish)   ;add the 'bournish' meta-command
                      (srfi srfi-1)           ;for lvm-device-mapping
                      (srfi srfi-26)
		      

                      ;; FIXME: The following modules are for
                      ;; LUKS-DEVICE-MAPPING.  We should instead propagate
                      ;; this info via gexps.
                      ((gnu build file-systems)
                       #:select (find-partition-by-luks-uuid))
                      (rnrs bytevectors))

	 
	 
         (with-output-to-port (%make-void-port "w")
           (lambda ()
             (set-path-environment-variable "PATH" '("bin" "sbin")
                                            '#$helper-packages)))
	 
         (parameterize ((current-warning-port (%make-void-port "w")))
           (boot-system #:mounts
                        (map spec->file-system
                             '#$(map file-system->spec file-systems))
                        #:pre-mount (lambda ()
                                      (and #$@device-mapping-commands))
                        #:linux-modules '#$linux-modules
                        #:linux-module-directory '#$kodir
                        #:keymap-file #+(and=> keyboard-layout
                                               keyboard-layout->console-keymap)
                        #:qemu-guest-networking? #$qemu-networking?
                        #:volatile-root? '#$volatile-root?
                        #:on-error '#$on-error))))
   #:name "initrd-auto-pass"))

;;; my linux-initrd.scm ends here
