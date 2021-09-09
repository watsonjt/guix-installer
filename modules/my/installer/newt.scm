;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2018, 2020 Mathieu Othacehe <m.othacehe@gmail.com>
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

(define-module (my installer newt)
  #:use-module (gnu installer record)
  #:use-module (gnu installer utils)
  #:use-module (gnu installer newt ethernet)
  #:use-module (gnu installer newt final)
  #:use-module (gnu installer newt parameters)
  #:use-module (gnu installer newt hostname)
  #:use-module (gnu installer newt keymap)
  #:use-module (gnu installer newt locale)
  #:use-module (gnu installer newt menu)
  #:use-module (gnu installer newt network)
  #:use-module (gnu installer newt page)
  ;;#:use-module (gnu installer newt partition)
  #:use-module (gnu installer newt services)
  #:use-module (gnu installer newt substitutes)
  #:use-module (gnu installer newt timezone)
  #:use-module (gnu installer newt user)
  #:use-module (gnu installer newt utils)
  #:use-module (gnu installer newt welcome)
  #:use-module (gnu installer newt wifi)
  #:use-module (my utils)
  #:use-module (my installer newt partition) ;<------ custom partition page
  #:use-module (guix config)
  #:use-module (guix discovery)
  #:use-module (guix i18n)
  #:use-module (srfi srfi-26)
  #:use-module (newt)
  #:export (my-newt-installer))

(copy-all-refs '(gnu installer newt) (current-module))

(define (my-partition-page)
  (run-my-partitioning-page))

(define my-newt-installer
  (installer
   (name 'newt)
   (init init)
   (exit exit)
   (exit-error exit-error)
   (final-page final-page)
   (keymap-page keymap-page)
   (locale-page locale-page)
   (menu-page menu-page)
   (network-page network-page)
   (substitutes-page substitutes-page)
   (timezone-page timezone-page)
   (hostname-page hostname-page)
   (user-page user-page)
   (partition-page my-partition-page)
   (services-page services-page)
   (welcome-page welcome-page)
   (parameters-menu parameters-menu)
   (parameters-page parameters-page)))
