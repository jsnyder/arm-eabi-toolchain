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

You will also need gmp, mpfr and mpc first.  I recommend installing
these from [homebrew](https://github.com/mxcl/homebrew) for now.
I'll add these to the Makefile once I have a consistent configuration
that can be used for both Linux & OS X.

With homebrew you can install those dependencies like this:

> brew install mpfr gmp libmpc texinfo


Requirements (Ubuntu)
---------------------

These instructions should now also work on Ubuntu Linux, provided the following packages have been installed prior to attempting the build:

> sudo apt-get install curl flex bison libgmp3-dev libmpfr-dev autoconf build-essential libncurses5-dev libmpc-dev texinfo


Main Build Instructions
-----------------------

Next prep for building the main toolchain:

> mkdir -p $HOME/arm-cs-tools/bin
>
> export PATH=$HOME/arm-cs-tools/bin:$PATH

Next build the toolchain:

> make install-cross


*NOTE:* If you are on Mac OS X and are running XCode 4.1 or a similar version you may find that it will fail during the build of libgcc as discussed in issue #10.  To work around this, build using using these two commands instead of the above:

> CC=clang make cross-binutils cross-gcc cross-g++ cross-newlib
> make cross-gdb


This should build the compiler, newlib, gdb, etc.. and install them all into a
directory called arm-cs-tools in your home directory. If you want to install
to another location, feel free to change the export lines and to adjust the
definitions at the top of the Makefile.

Keep in mind that the Makefile does install at the end of each build.

Once you’re done, you’ll likely want to add the path where the compiler was
installed to to your .bash_profile, .zshrc, etc..:

> export PATH=$HOME/arm-cs-tools/bin:$PATH

Extras From Binary Distribution
-------------------------------

Some of the CodeSourcery CS3 libraries are distributed with G++ Lite, but the sources for these are not made available, nor are the licensing terms in the binary release of G++ Lite permissive of my including a small compressed download of these libraries with this build file.  However, I have added a make target that should be able to pull down the binary Linux tarball extract these libraries and a few extras, and place them into the correct directories.  To use this, type the following *after* you have installed your toolchain:

> make install-bin-extras

NOTE: use of these libraries is untested by the creator of the Makefile.  It seemed simple enough to add this after a user had mentioned a desire to have these libraries available.


Special Thanks
--------------

Special thanks to Rob Emanuele for the basis of this Makefile:
http://elua-development.2368040.n2.nabble.com/Building-GCC-for-Cortex-td2421927.html
