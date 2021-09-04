# Autopass
- Thanks to [mtottenh](https://github.com/mtottenh/grub2/tree/boot_data) for the grub patch code!
- Follow all the instructions from SystemCrafters - follow the example/system.scm to add functionality post system install
  - **NOTE** There is an error in the initrd call to e2fsck that dumps to the guile repl... just ^D or ,q the boot process will continue... this appears after the premount call in the init script.
    - This may be due to type mismatch in the file-system configuration in my system config and the device-mapping conf...
  - The password is stored in setup_data
    - DONE - ~~chmod so only root can read~~
	- DONE - ~~Password should always be stored in ..setup_data/0~~
     - ~~REBOOT the computer if you mistype the password as it is assumed in the first file, setup_data is added for each password entry i.e. ..0/ ..1/ ..2/~~
	- TODO - encrypt the password? use a service that allows you to type a pin and copy it to... ramfs,fifo,fd?
	       - Requires pin-set in grub, i.e. custom command/module that will call boot after getting pin and encrypting the setup_data 0 entry
	       - This also requires atleast entering the pin during initrd init script, I dont see the point, if someone gets root access they probably will crack a less entropy pin... probably not worth the extra work and complexity of adding a grub module... 
	- ~~TODO~~ - add options to zerofill setup_data after auto-pass, use proc/cmdline opt --zap
               - Setup_data may not be modified after grub hand-off, --zap cant happen till the initrd init script, so without ability to write to kernel memory (is it possible?) this TODO is a TODONT 
    - DONE - ~~reexport linux-initrd, and have only the auto-pass-initrd and my-open proc...~~
- example folder has an system.scm config to see changes necessary to reconigure 
  - I have not yet tested a full install from the SC guix-installer iso generated from this repo...
  - **DO NOT USE THIS TO INSTALL GUIX SYSTEM** ill get back to you if my computer was nuked...
 

# System Crafters Guix Installer

This repository runs _automated CI builds_ to produce a
[GNU Guix](https://guix.gnu.org) installation image using the
**full Linux kernel** from the
[Nonguix channel](https://gitlab.com/nonguix/nonguix). If you are using a
modern laptop or hardware that is incompatible with the **Linux Libre kernel**,
this installer image is for you!

You may take a look at the [image configuration](./installer.scm) and the
[build workflow](./.github/workflows/build.yaml) to be sure that we aren't adding
anything malicious to these builds!

**A new `.iso` image is produced at least once a week, sometimes more often if
we're making improvements to the configuration.**

## Table of Contents
- [System Crafters Guix Installer](#system-crafters-guix-installer)
  - [Instructions](#instructions)
  - [Attributions](#attributions)
  - [License](#license)

## Instructions

1. Download a recently built `.iso` from this repo's
   [release page](https://github.com/SystemCrafters/guix-installer/releases)
2. Flash the `.iso` file into a USB stick with at least `3Gb`.

### Flashing the ISO

As stated in _step #2_ at [Instructions](#instructions), you will need to flash
the `.iso` file into a USB stick.

**[*]nix**:

You should only need the `dd` utility (_coreutils_):

- `dd status=progress if=guix-installerYYYYMMDDHHMM.iso of=/dev/foo`
  - where `guix-installerYYYYMMDDHHMM.iso` is the name of the downloaded `.iso`
    image and `foo` the name of the targeted device to flash the image.

For the sake of providing an example, here's the full command:

```sh
dd status=progress if=guix-installer-202106150234.iso of=/dev/sdb
```

> NOTE #1: You can list your devices with `lsblk`.

> NOTE #2: If `dd` won't work, refer to the **Windows** section.

**Windows**:

- [balenaEtcher](https://www.balena.io/etcher) is a great **cross-platform**
  _FOSS_ utility for flashing _GNU/Linux_ images.
- If the above doesn't work, you might give [Rufus](https://rufus.ie/en_US/) a
  look.

## Attributions

- [@anntnzrb](https://github.com/anntnzrb) for providing the starting point for
  the _CI_ configuration.
- [@daviwil](https://github.com/daviwil) for releasing the finished _CI_
  configuration and getting everything up and running.
- The [System Crafters](https://systemcrafters.cc)' community.

## License

The code in this repository is licensed under the
[GNU General Public License v3](./LICENSE.txt).
