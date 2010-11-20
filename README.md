**IMPORTANT NOTE**

This contains additions specific to my FreeRTOS port (github.com/hugovincent/mbed-freertos)
and shouldn't be used for normal, non-FreeRTOS builds.

-- Hugo Vincent

***Changes from Upstream Version***

(Upstream by jsynder at github.com/jsnyder/arm-eabi-toolchain/). Changes in this version:

* Patch against newlib for use with FreeRTOS (github.com/hugovincent/mbed-freertos)
	* Binary size and performance optimisations.
	* Newlib is built without non-reentant versions of many functions - instead these are provided by the libraries portion of mbed-freertos in a thread-safe, reentrant way.
	* Compile-time options to build extra POSIXy functions into the standard library (e.g. signal, nanosleep, fcntl, rename) and to exclude functions not suitable on mbed-freertos (e.g. getpwent, getut, getpass, sigset, getlogin). 
	* Fix some unsuitable function prototypes in the standard library.
	* Fixes to enable POSIX timer APIs.
	* Reductions in buffer sizes and so on within the libraries (to better suit the low-RAM environment).
	* Fixes to make signals work better with my FreeRTOS signal machinery. 
* gcc and g++ run-time libraries are built with a custom set of compiler flags to reduce binary size of the finished firmware images, and for compatibility with some other mbed code (i.e. -fshort-wchar is used for compatibility with Keil MDK libraries, e.g. the mbed library). 
* The C++ standard libraries are built to use malloc as their standard allocator (so you can provide a single, shared, optimised allocator in your application that is used both by your application and by libstdc++ for `new` et al.)
* Some changes to do with exception handling and stack unwinding, for better compatibility with the unwinder in mbed-freertos.

* * *


ARM EABI Toolchain Builder
==========================

This build system has been tested on Mac OS X 10.6 (should also work on 10.5).
Small modifications may be needed in order to make it work with other
platforms.

Note: If you have previously built a toolchain of another version, out of the same builder directory, make sure to do the following first before building with newer sources:

> make clean


Requirements (OS X)
-------------------

You will need to have GCC, make, binutils and latex installed on your machine
to compile all of this. You can get all of these on Mac OS X, by
just installing the Apple Developer Tools which are free
[here](http://developer.apple.com/Tools/). 

If you haven’t installed gmp, mpc or mpfr, install them first:

> sudo make install-deps

NOTE: The first time you run this, it will attempt to download the tarball for
the CodeSourcery sources, which may take some time. It should not need to do
this again for later steps (files needed will be extracted).


Requirements (Ubuntu)
---------------------

These instructions should now also work on Ubuntu Linux, provided the following packages have been installed prior to attempting the build:

> sudo apt-get install curl flex bison libgmp3-dev libmpfr-dev autoconf build-essential libncurses5-dev libmpc-dev


Main Build Instructions
-----------------------

Next prep for building the main toolchain:

> mkdir -p $HOME/arm-cs-tools/bin
>
> export PATH=$HOME/arm-cs-tools/bin:$PATH

(or add the PATH export to your bashrc or other suitable location, as below).
Next build the toolchain:

> make install-cross

This should build the compiler, newlib, gdb, etc.. and install them all into a
directory called arm-cs-tools in your home directory. If you want to install
to another location, feel free to change the export lines and to adjust the
definitions at the top of the Makefile.

Keep in mind that the Makefile does install at the end of each build.

Once you’re done, you’ll likely want to add the path where the compiler was
installed to to your .bash_profile, .zshrc, etc..:

> export PATH=$HOME/arm-cs-tools/bin:$PATH

Special Thanks
--------------

Special thanks to Rob Emanuele for the basis of this Makefile:
http://elua-development.2368040.n2.nabble.com/Building-GCC-for-Cortex-td2421927.html
