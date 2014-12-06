ARM EABI Toolchain Builder
==========================

This toolchain builder builds a GCC and Newlib-based ARM EABI toolchain using the [Sourcery
CodeBench Lite](http://www.mentor.com/embedded-software/sourcery-tools/sourcery-codebench/editions
/lite-edition/) sources.  This Makefile was originally created to allow building a validated GCC
release on Mac OS X, as CodeBench Lite / G++ Lite were only provided for Windows and Linux, but this
build also includes some optimizations for Newlib that provide smaller binaries.

*NOTE:* Mentor have indicated that there won't be future ARM EABI releases of the free Lite edition
of CodeBench, so the 2014.05 release may be the last. You may also be able to use a modified version
of this makefile with the sources Mentor provides with the Professional version of CodeBench (which
they plan to continue supporting). If future source releases are made available, this Makefile will
be updated for them.  If not, we may start to build custom versions of other GCC/Newlib toolchain
sources.

This build system has been tested on Mac OS X 10.10.1. Small modifications may be needed in order to
make it work with other platforms.

Note: If you have previously built a toolchain of another version, out
of the same builder directory, make sure to do the following first
before building with newer sources:

```bash
make clean
```

Also, make sure that you don't have another
arm-non-eabi-[gcc,g++,ld,gdb] etc toolchain in your path when you
build, whether it is a previous version of this same toolchain or a
binary toolchain from another provider.  This may end up influencing
how newlib, in particular, gets compiled.


Requirements (OS X)
-------------------

You will need to have clang, make, binutils installed on your machine to compile all of
this. You can get most of these on Mac OS X, by just installing the Apple Developer Tools which are
free [here](http://developer.apple.com/Tools/).

For Xcode 4.3 or later, the command line tools are no longer bundled by default, and there is no
/Developer anymore. To install them, open Xcode, go to Preferences -> Downloads -> Components ->
Command Line Tools. This should install make, gcc etc.

You will also need libelf and texinfo first.  I recommend installing these from
[homebrew](https://github.com/mxcl/homebrew) for now. I'll add these to the Makefile once I have a
consistent configuration that can be used for both Linux & OS X.

With homebrew you can install those dependencies like this:

```bash
brew install libelf texinfo
```


Requirements (Ubuntu)
---------------------

These instructions should now also work on Ubuntu Linux, provided the
following packages have been installed prior to attempting the build:

```bash
sudo apt-get install curl flex bison texinfo \
      libelf-dev autoconf build-essential libncurses5-dev \
```


Main Build Instructions
-----------------------

Next build the toolchain:

```bash
make install-cross
```

*Note:* My most recent test on Mac OS X 10.8 with XCode Command Line Tools from April 2013, it was
necessary to use the instructions in the Installing gcc-4.2 section.

You should be able to also specify a specific install/prefix location
by building using the following type of invokation:

```bash
PREFIX=$HOME/arm-cs-tools make install-cross
```

By default the build attempts to determine the number of CPUs and sets
the number of parallel jobs automatically (Linux & OS X). If you're on
another platform or want to use a different number of jobs, you can
redefine PROCS:

```bash
PROCS=8 make install-cross
```

*NOTE:* If you are on Mac OS X and are running XCode 4.1 or a similar
 version and are trying to build 2011.03 or an earlier version of
 CodeSourcery's sources, you may find that it will fail during the
 build of libgcc as discussed in issue #10.  To work around this,
 build using using these two commands instead of the above:

```bash
CC=clang make cross-binutils cross-gcc cross-newlib

make cross-gdb
```

or with gcc-4.2:

```bash
CC=gcc-4.2 make install-cross
```

*NOTE: GCC 4.2 has been removed from recent versions of Apple's Command Line Tools for XCode, if you
*need this compiler you'll have to follow instructions in the gcc 4.2 section below.

This should build the compiler, newlib, gdb, etc.. and install them all into a
directory called arm-cs-tools in your home directory. If you want to install
to another location, feel free to change the export lines and to adjust the
definitions at the top of the Makefile.

Keep in mind that the Makefile does install at the end of each build.

Once you’re done, you’ll likely want to add the path where the compiler was
installed to to your .bash_profile, .zshrc, etc..:

```bash
export PATH=$HOME/arm-cs-tools/bin:$PATH
```

To clean up when you're done and you've installed the toolchain you
can clean up the intermediate files with the following command:

```bash
make clean
```

Installing gcc-4.2
------------------

First things first, see if it is installed. Write `gcc` in your commandline and double tab. If there
is no file called gcc-4.2 you most likely do not have it. One more check though is to check the gcc
version by doing `gcc -v`. Look at the last line of the output, if it looks like this

```
gcc version 4.2.1 (Based on Apple Inc. build 5658) (LLVM build 2336.11.00)
```

you may think you are in luck and you have gcc-4.2. Unfortunately it is not that simple. This is the
llvm version of gcc-4.2 from Apple and unfortunately does not work with the latest CodeSourcery
packages.

The correct gcc version is easy to install though using homebrew.

```bash
brew tap homebrew/dupes && brew install apple-gcc42
```

and then do

```bash
CC=gcc-4.2 make install-cross
```
###Note:
Homebrew-Dupes also offers a gcc formula which installs, at the time of this writing, GCC 4.7. I have not tried this version myself but might be worth a try since 4.2 is getting pretty dated.

Multilib Build Customization
----------------------------

By default, the toolchain will build with the the multilibs included in the binary builds of G++
Lite. If you want to build multilibs for a larger set of targets similar to the commercial release,
you can build like this:

```bash
FULL_MULTILIBS=true make install-cross
```

*NOTE:* Building with this option will take significantly longer.

Newlib Build Customization
--------------------------

By default, this build enables a number of extra optimizations (most
of which relate to reducing code size) for Newlib by defining the
following:

```bash
CFLAGS_FOR_TARGET="\
 -ffunction-sections -fdata-sections          \ # put code and data into separate sections allowing for link-time
 -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ \ # pick simpler, smaller code over larger optimized code
 -Os                                          \ # same as O2, but turns off optimizations that would increase code size
 -fomit-frame-pointer                         \ # don't keep the frame pointer in a register for functions that don't need one
 -fno-unroll-loops                            \ # don't unroll loops
 -D__BUFSIZ__=256                             \ # limit default buffer size to 256 rather than 1024
 -mabi=aapcs"                                 \ # enable use of arm procedure call standard (not sure if this is needed any more)
CCASFLAGS=$(CFLAGS_FOR_TARGET)
```

For an example of what the ```PREFER_SIZE_OVER_SPEED``` and
```__OPTIMIZE_SIZE__``` options do, take a look at the following
[memcpy.c](https://gist.github.com/1636109) extracted from
newlib. Often what one is giving up is manually unrolled loops or
hand-coded assembler that compiles to sizes larger than a simple C
implementation.


If you want something closer to standard options that CodeSourcery
uses simply prepend the make command as follows:

```bash
MATCH_CS=true make install-cross
```

For Newlib this changes the flags to these:

```bash
CFLAGS_FOR_TARGET="-g -O2 -fno-unroll-loops"
```

You can also define your own Newlib flags:

```bash
NEWLIB_FLAGS="-g -O2 -fno-unroll-loops" make install-cross
```

Additionally, there is an option to exclude float support from Newlib functions. At the moment this
should disable float support for IO functions:

```bash
NEWLIB_NOFLOAT=true make install-cross
```

Extras From Binary Distribution
-------------------------------

Some of the CodeSourcery CS3 libraries are distributed with G++ Lite,
but the sources for these are not made available, nor are the
licensing terms in the binary release of G++ Lite permissive of my
including a small compressed download of these libraries with this
build file.  However, I have added a make target that should be able
to pull down the binary Linux tarball extract these libraries and a
few extras, and place them into the correct directories.  To use this,
type the following *after* you have installed your toolchain:

```bash
make install-bin-extras
```

If you need the binary extras installed at a specific prefix, you can
use the following style of incantation:

```bash
PREFIX=/some/other/location make install-bin-extras
```

So, if you had placed your pre-built binaries at
/usr/local/arm-cs-tools, you could use the following:

```bash
PREFIX=/usr/local/arm-cs-tools make install-bin-extras
```

NOTE: use of these libraries is untested by the creator of the
Makefile.  It seemed simple enough to add this after a user had
mentioned a desire to have these libraries available.


Special Thanks
--------------

 * Rob Emanuele for the basis of this
   [Makefile](http://elua-development.2368040.n2.nabble.com/Building-GCC-for-Cortex-td2421927.html)
   as a starting point.

 * Liviu Ionescu for numerous comments suggestions/suggestions and fixes.
