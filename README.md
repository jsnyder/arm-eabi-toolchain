ARM EABI Toolchain Builder
==========================

This build system has been tested on Mac OS X 10.6 (should also work on 10.5).
Small modifications may be needed in order to make it work with other
platforms.

Requirements
------------

To build this toolchain, you’ll need to first acquire sources for GCC,
binutils, Newlib & GDB. In this example we’ll be using CodeSourcery’s G++ Lite
sources which include all of these, and have been validated by CS’s QA
process.

In addition, you will need to have GCC, make, binutils and latex installed on
your machine to compile all of this. You can all of these on Mac OS X, except
LaTeX, by just installing the Apple Developer Tools which are free here. LaTeX
can be acquired from here: http://tug.org/mactex/ (It should be possible to do
this build without using LaTeX, which is just used for documentation, if I
find a solution, I’ll update the Makefile)


Build Instructions
------------------

If you haven’t installed gmp or mpfr, install them first:

> sudo make install-deps


Next prep for building the main toolchain:

> mkdir -p $HOME/arm-cs-tools/bin
> export PATH=$HOME/arm-cs-tools/bin:$PATH

Next build the toolchain:

> make install-cross
