Crouton
=======

 - [https://github.com/dnschneid/crouton](https://github.com/dnschneid/crouton#crouton-chromium-os-universal-chroot-environment)
 - Installs Linux into a chroot
	 - Make as many chroots as you like
	 - Chroots can be encrypted
 - Useful for running types of software that you can't use (or are severely limited) in Chrome OS
	 - Offline office apps (LibreOffice, etc.)
	 - Image editors (GIMP, Inkscape, etc.)
	 - [KMyMoney](https://kmymoney.org/)

Setup
-----

 1. Enter developer mode
	 - https://www.chromium.org/chromium-os/developer-information-for-chrome-os-devices
	 - If you can't find your device, the [generic instructions](https://www.chromium.org/a/chromium.org/dev/chromium-os/developer-information-for-chrome-os-devices/generic) should work for you
	 - Several caveats to using developer mode
		 - Entering developer mode will wipe all local files on the Chromebook
		 - Anecdotally, it seems to lock that machine to a single Google account
			 - Haven't found direct documentation of this yet, but I had my wife use my Chromebook for video chatting with the family while I was traveling for work, and returned to find the Chromebook was no longer in developer mode
		 - Disables [Verified Boot](https://www.chromium.org/chromium-os/chromiumos-design-docs/verified-boot), which technically make Chrome OS itself less secure since it gives you write access to the firmware partition, which is normally mounted read-only
		 - Shows an **OS Verification is OFF** warning for about 10 seconds on each restart, and (at least on my device) plays a few loud beeps
			 - Message (and beeps) can be bypassed by pressing `Ctrl + d`
 2. Set password to enable sudo access
	 - `Ctrl + Alt + F2` (`F2` is often `->`)
	 - Run `chromeos-setdevpasswd`
	 - `Ctrl + Alt + F1` (F1 is often `<-`) to go back to Chrome OS
 3. Install the [crouton Chrome extension](https://goo.gl/OVQOEt)
	 - Not required, but allows a chroot to run from a Chrome tab instead of a fullscreen window
 4. Download crouton from https://goo.gl/fd3zc
   - Run `sh ~/Downloads/crouton -h` to see help

Making Chroots
--------------

 - Requires crouton to be run using sudo (e.g. `sudo sh ~/Downloads/crouton .....`)
 - Pick your targets (`sh ~/Downloads/crouton -t list` to list them)
	 - Make sure `xiwi` is in your list of targets (this installs an X11 backend that lets it talk to the [crouton Chrome extension](https://goo.gl/OVQOEt)
 - Use `-e` to turn on encryption
 - Use `-n` to give your chroot a unique name
 - My main chroot was created using `sudo sh ~/Downloads/crouton -t xfce,xiwi,keyboard,extension,xorg -n xfce -e`
	 - `-d -f ~/Downloads/filename.tar.gz` can be used to prefetch the bootstrap and some of the files used to create the chroot, to speed up the creation of future chroots
			 - This will not actually install the chroot
			 - To install from a previously created bootstrap tarball, just use `-f` without `-d`

Launching Chroots
-----------------

- Depending on which desktop environment you choose in your targets, you will be given a different command to run (`startkde`, `startxfce4`, etc.) at the end of installing a chroot; these commands are needed to launch a graphical environment for your chroot
- `-b` to launch the chroot in the background (Allows you to close the shell tab)
- `-X xiwi-tab` to turn on xiwi (launches chroot in a tab)
- Command I use to launch my main chroot: `sudo startxfce4 -n xfce -b -X xiwi-tab`
- To exit a chroot, just logout

Other Useful Commands
---------------------

These commands all support `-h` for help

- `edit-chroot`
	- Can be used to delete chroots, change passphrase, backup and restore chroots, etc.
	- Run with `-b -f ~/Downloads/backup.tar.gz` to make a full backup of your chroot
	- Install a completely new chroot from a backup using `sudo sh ~/Downloads/crouton -n newchrootname -f ~/path/to/backup.tar.gz`
		- Does not appear to be a way to modify the encryption passphrase when backing up, so you'd have to change it first before backing up if you want to turn over the backup to someone else without giving them your passphrase
- `start-chroot`
	- Enters a chroot and gives you a shell (no graphical environment)
