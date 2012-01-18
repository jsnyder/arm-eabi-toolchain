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

> brew install mpfr gmp libmpc libelf texinfo


Requirements (Ubuntu)
---------------------

These instructions should now also work on Ubuntu Linux, provided the following packages have been installed prior to attempting the build:

> sudo apt-get install curl flex bison libgmp3-dev libmpfr-dev libelf-dev autoconf build-essential libncurses5-dev libmpc-dev texinfo


Main Build Instructions
-----------------------

Next prep for building the main toolchain:

> mkdir -p $HOME/arm-cs-tools/bin
>
> export PATH=$HOME/arm-cs-tools/bin:$PATH

Next build the toolchain:

> make install-cross

You should be able to also specify a specific install/prefix location by building using the following type of invokation:

> PREFIX=$HOME/arm-cs-tools make install-cross


*NOTE:* If you are on Mac OS X and are running XCode 4.1 or a similar version you may find that it will fail during the build of libgcc as discussed in issue #10.  To work around this, build using using these two commands instead of the above:

> CC=clang make cross-binutils cross-gcc cross-newlib
>
> make cross-gdb


This should build the compiler, newlib, gdb, etc.. and install them all into a
directory called arm-cs-tools in your home directory. If you want to install
to another location, feel free to change the export lines and to adjust the
definitions at the top of the Makefile.

Keep in mind that the Makefile does install at the end of each build.

Once you’re done, you’ll likely want to add the path where the compiler was
installed to to your .bash_profile, .zshrc, etc..:

> export PATH=$HOME/arm-cs-tools/bin:$PATH

To clean up when you're done and you've installed the toolchain you can clean up the intermediate files with the following command:

> make clean

Newlib Build Customization
--------------------------

By default, this build enables a number of extra optimizations (most of which relate to reducing code size) for Newlib by defining the following:

```bash
CFLAGS_FOR_TARGET="\
        -ffunction-sections -fdata-sections          \ # put code and data into separate sections allowing for link-time
        -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ \ # choose code paths within newlib known to generate smaller code, potentially at the cost of speed
        -Os                                          \ # same as O2, but turns off optimizations that would increase code size
        -fomit-frame-pointer                         \ # don't keep the frame pointer in a register for functions that don't need one
        -fno-unroll-loops                            \ # don't unroll loops
        -D__BUFSIZ__=256                             \ # limit __BUFSIZ__ allocation size default to 256 bytes
        -mabi=aapcs"                                   # enable use of arm procedure call standard (not sure if this is needed any more)
CCASFLAGS=$(CFLAGS_FOR_TARGET)
```

If you want the standard options that CodeSourcery uses when building Newlib, which are as follows:

> CFLAGS_FOR_TARGET="-g -O2 -fno-unroll-loops"

Simply prepend the make command as follows:

> OPT_NEWLIB_SIZE=false make install-cross

or define your own Newlib flags:

> NEWLIB_FLAGS="-g -O2 -fno-unroll-loops" make install-cross



Extras From Binary Distribution
-------------------------------

Some of the CodeSourcery CS3 libraries are distributed with G++ Lite, but the sources for these are not made available, nor are the licensing terms in the binary release of G++ Lite permissive of my including a small compressed download of these libraries with this build file.  However, I have added a make target that should be able to pull down the binary Linux tarball extract these libraries and a few extras, and place them into the correct directories.  To use this, type the following *after* you have installed your toolchain:

> make install-bin-extras

If you need the binary extras installed at a specific prefix, you can use the following style of incantation:

> PREFIX=/some/other/location make install-bin-extras

So, if you had placed your pre-built binaries at /usr/local/arm-cs-tools, you could use the following:

> PREFIX=/usr/local/arm-cs-tools make install-bin-extras

NOTE: use of these libraries is untested by the creator of the Makefile.  It seemed simple enough to add this after a user had mentioned a desire to have these libraries available.


Special Thanks
--------------

Special thanks to Rob Emanuele for the basis of this Makefile:
http://elua-development.2368040.n2.nabble.com/Building-GCC-for-Cortex-td2421927.html
