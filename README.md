ARM EABI Toolchain Builder
==========================

This build system has been tested on Mac OS X 10.6 (should also work on 10.5).
Small modifications may be needed in order to make it work with other
platforms.

Requirements (OS X)
-------------------

You will need to have GCC, make, binutils and latex installed on your machine
to compile all of this. You can get all of these on Mac OS X, except LaTeX, by
just installing the Apple Developer Tools which are free
[here](http://developer.apple.com/Tools/). LaTeX can be acquired from here:
[http://tug.org/mactex/](http://tug.org/mactex/) (It should be possible to do
this build without using LaTeX, which is just used for documentation, if I
find a solution, I’ll update the Makefile)

If you haven’t installed gmp or mpfr, install them first:

> sudo make install-deps

NOTE: The first time you run this, it will attempt to download the tarball for
the CodeSourcery sources, which may take some time. It should not need to do
this again for later steps (files needed will be extracted).


Requirements (Ubuntu)
---------------------

These instructions should now also work on Ubuntu Linux, provided the following packages have been installed prior to attempting the build:

> sudo apt-get install curl flex bison libgmp3-dev libmpfr-dev autoconf texinfo build-essential texlive libncurses5-dev


Main Build Instructions
-----------------------

Next prep for building the main toolchain:

> mkdir -p $HOME/arm-cs-tools/bin
>
> export PATH=$HOME/arm-cs-tools/bin:$PATH

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
