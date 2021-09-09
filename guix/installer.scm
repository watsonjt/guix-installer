;;; Copyright © 2019 Alex Griffin <a@ajgrf.com>
;;; Copyright © 2019 Pierre Neidhardt <mail@ambrevar.xyz>
;;; Copyright © 2019 David Wilson <david@daviwil.com>
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Generate a bootable image (e.g. for USB sticks, etc.) with:
;; $ guix system image -t iso9660 installer.scm

(define-module (nongnu system install)
  #:use-module (gnu services)
  #:use-module (gnu system)
  #:use-module (gnu system file-systems)
  #:use-module (gnu system keyboard)
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages bootloaders)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mtools)
  #:use-module (gnu packages package-management)
  #:use-module (nongnu packages linux)
  #:use-module (guix)
  #:use-module (guix modules)
  #:use-module (my system install)
  #:export (installation-os-nonfree))

(define-public grub-logger
  (package
   (inherit grub)
   (source (origin
	     (inherit (package-source grub))
             (patches (append '("./grub-add-setup-data-log.patch") (search-patches
                       "grub-efi-fat-serial-number.patch"
                       "grub-setup-root.patch")))))))

(define grub-bootloader-log
  (bootloader
   (inherit grub-bootloader)
   (name '"grub-log")
   (package grub-logger)))


(define installation-os-nonfree
  (operating-system
    (inherit my-installation-os)
    (kernel linux)
    (firmware (list linux-firmware))
    (bootloader (bootloader-configuration
		 (bootloader grub-bootloader-log)
		 (target "/dev/sda")))

    ;; Add the 'net.ifnames' argument to prevent network interfaces
    ;; from having really long names.  This can cause an issue with
    ;; wpa_supplicant when you try to connect to a wifi network.
    (kernel-arguments '("quiet" "modprobe.blacklist=radeon" "net.ifnames=0"))

    ;; (services
    ;;  (cons*
    ;;   ;; Include the channel file so that it can be used during installation
    ;;   (simple-service 'channel-file etc-service-type
    ;;                   (list `("channels.scm" ,(local-file "channels.scm"))))
    ;;   (operating-system-user-services my-installation-os)))

    ;; Add some extra packages useful for the installation process
    (packages
     (append (list git curl stow vim emacs-no-x-toolkit)
             (operating-system-packages my-installation-os)))))

installation-os-nonfree
