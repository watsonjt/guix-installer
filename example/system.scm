;; THIS FILE is an example, your system.scm should have similiar noted changes
;; if within the guix-isntaller folder, with you system.scm
;;;; run sudo -E system -L "realpath to guix-installer modules folder" reconfigure -L "same path" system.scm


;; This is an operating system configuration generated
;; by the graphical installer.
;;

(use-modules (gnu) (guix packages) (gnu packages bootloaders) (nongnu packages linux) (my mapped-devices)) ;<----- include my mappped devices
(use-service-modules
  cups
  desktop
  networking
  ssh
  xorg)

;;ADD THESE procs to your system.scm
 (define-public grub-logger
   (package
    (inherit grub)
    (source (origin
              (inherit (package-source grub))
               (patches (append '("./grub-add-setup-data-log.patch" ) (search-patches    ;<-------- copy this patch to the dir with system.scm
                         "grub-efi-fat-serial-number.patch"
                         "grub-setup-root.patch")))))))
  
  (define grub-bootloader-log
    (bootloader
     (inherit grub-bootloader)
     (name '"grub-log")
     (package grub-logger))
  )



(operating-system
 (kernel linux)					
 (firmware (list linux-firmware))
  (locale "en_US.utf8")
  (timezone "America/Denver")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "dev")
  (users (cons* (user-account
                  (name "jon")
                  (comment "Jon Watson")
                  (group "users")
                  (home-directory "/home/jon")
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))
  (packages
    (append
      (list (specification->package "emacs")
            (specification->package "emacs-exwm")
            (specification->package
              "emacs-desktop-environment")
            (specification->package "nss-certs"))
      %base-packages))
  (services
    (append
      (list (service gnome-desktop-service-type)
            (set-xorg-configuration
              (xorg-configuration
                (keyboard-layout keyboard-layout))))
      %desktop-services))
  (bootloader
    (bootloader-configuration
      (bootloader grub-bootloader-log)                             ;<---------------------------- changed to grub-bootloader-log
      (target "/dev/sda")
      (keyboard-layout keyboard-layout)))
  (initrd-modules
    (append '("sata_nv") %base-initrd-modules))
  (mapped-devices
    (list (mapped-device
            (source
              (uuid "de932452-e89a-4934-a86c-1a445baa7561"))
            (target "guix")
            (type luks-auto-pass-device-mapping))))                ;<------------------------- changed to auto-pass device mapping
  (file-systems
    (cons* (file-system
             (mount-point "/")
             (device "/dev/mapper/guix")
             (type "ext4")
             (dependencies mapped-devices))                        
           %base-file-systems)))
