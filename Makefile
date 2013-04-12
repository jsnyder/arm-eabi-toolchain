# ARM EABI Toolchain Makefile
#
# Copyright (C) 2012 by James Snyder <jbsnyder@fanplastic.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#### HIGH LEVEL/SYSTEM CONFIG OPTIONS #####

SHELL   = /bin/bash
UNAME  := $(shell uname)
TARGET  = arm-none-eabi
PREFIX ?= $(HOME)/arm-cs-tools
PATH   := ${PREFIX}/bin:${PATH}

ifeq ($(UNAME), Linux)
PROCS  ?= $(shell grep -c ^processor /proc/cpuinfo)
else ifeq ($(UNAME), Darwin)
PROCS  ?= $(shell sysctl hw.ncpu | awk '{print $$2}')
else
PROCS  ?= 2
endif

MATCH_CS        ?= false
OPT_NEWLIB_SIZE ?= true

####    PRIMARY TOOLCHAIN VERSIONS    #####

CS_MAJ		?= 2012
CS_MIN		?= 09
CS_BASE		?= $(CS_MAJ).$(CS_MIN)
CS_REV 		?= 63
GCC_VERSION 	?= 4.7
MPC_VERSION 	?= 0.8.1
SOURCE_PACKAGE	?= 10925
BIN_PACKAGE	?= 10926
## https://sourcery.mentor.com/GNUToolchain/package10384/public/arm-none-eabi/arm-2012.03-56-arm-none-eabi.src.tar.bz2

####  PRIMARY TOOLCHAIN URLS / FILES  #####

CS_VERSION 	= $(CS_BASE)-$(CS_REV)

LOCAL_BASE 	= arm-$(CS_VERSION)-arm-none-eabi
LOCAL_SOURCE 	= $(LOCAL_BASE).src.tar.bz2
LOCAL_BIN 	= $(LOCAL_BASE)-i686-pc-linux-gnu.tar.bz2
SOURCE_URL 	= http://sourcery.mentor.com/sgpp/lite/arm/portal/package$(SOURCE_PACKAGE)/public/arm-none-eabi/$(LOCAL_SOURCE)
BIN_URL 	= http://sourcery.mentor.com/sgpp/lite/arm/portal/package$(BIN_PACKAGE)/public/arm-none-eabi/$(LOCAL_BIN)

SOURCE_MD5_CHCKSUM ?= b3671f2536f8db94ade739927e01a2c7
BIN_MD5_CHECKSUM ?= d094880c6ac3aea16d4bfb88077186f7


####    BUILD LABELING / TAGGING      #####
BUILD_ID	= $(shell git describe --always)
TODAY           = $(shell date "+%Y%m%d")

ifeq ($(strip $(BUILD_ID)),)
BUILD_ID = $(TODAY)
endif


ifeq ($(MATCH_CS),true)
NEWLIB_FLAGS?="-g -O2 -fno-unroll-loops"
PKG_TAG?="CS"
else
PKG_TAG?="JBS"
endif

BUG_URL ?= https://github.com/jsnyder/arm-eabi-toolchain
PKG_VERSION ?= "32-bit ARM EABI Toolchain $(PKG_TAG)-$(CS_BASE)-$(CS_REV)-$(BUILD_ID)"


############### BUILD RULES ###############

default: install-cross

.PHONY: install-tools
install-tools: cross-binutils cross-gcc cross-newlib cross-gdb

.PHONY: install-cross
install-cross: install-tools install-note

install-deps: gmp mpfr mpc

sudomode:
ifneq ($(USER),root)
	@echo Please run this target with sudo!
	@echo e.g.: sudo make targetname
	@exit 1
endif

.PHONY: install-note
install-note: install-tools
	@echo
	@echo ====== INSTALLATION NOTE ======
	@echo Your tools have now been installed at the following prefix:
	@echo $(PREFIX)
	@echo
	@echo Please be sure to add something similar to the following to your .bash_profile, .zshrc, etc:
	@echo export PATH=$(PREFIX)/bin:'$$PATH'
	@echo

$(LOCAL_SOURCE):
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) curl -LO $(SOURCE_URL)
else
	curl -LO $(SOURCE_URL)
endif

$(LOCAL_BIN):
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) curl -LO $(BIN_URL)
else
	curl -LO $(BIN_URL)
endif

downloadbin: $(LOCAL_BIN)
	@(t1=`openssl md5 $(LOCAL_BIN) | cut -f 2 -d " " -` && \
	[ "$$t1" = "$(BIN_MD5_CHECKSUM)" ] || \
	( echo "Bad Checksum! Please remove the following file and retry: $(LOCAL_BIN)" && false ))

downloadsrc: $(LOCAL_SOURCE)
	@(t1=`openssl md5 $(LOCAL_SOURCE) | cut -f 2 -d " " -` && \
	[ "$$t1" = "$(SOURCE_MD5_CHCKSUM)" ] || \
	( echo "Bad Checksum! Please remove the following file and retry: $(LOCAL_SOURCE)" && false ))

$(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2 : downloadsrc
ifeq ($(USER),root)
	@(tgt=`tar -jtf $(LOCAL_SOURCE) | grep  $*` && \
	sudo -u $(SUDO_USER) tar -jxvf $(LOCAL_SOURCE) $$tgt)
else
	@(tgt=`tar -jtf $(LOCAL_SOURCE) | grep  $*` && \
	tar -jxvf $(LOCAL_SOURCE) $$tgt)
endif

arm-$(CS_BASE): downloadbin
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) tar -jtf $(LOCAL_BIN) | grep -e '.*cs3.*[ah]$$' -e '.*\.ld' \
	-e '.*.\.inc' | xargs tar -jxvf $(LOCAL_BIN)
else
	tar -jtf $(LOCAL_BIN) | grep -e '.*cs3.*[ah]$$' -e '.*\.ld' \
	 -e '.*.\.inc'  | xargs tar -jxvf $(LOCAL_BIN)
endif

install-bin-extras: arm-$(CS_BASE)
ifeq ($(USER),root)
	pushd arm-$(CS_BASE) ; \
	sudo -u $(SUDO_USER) cp -r arm-none-eabi $(PREFIX) ; \
	popd ;
else
	pushd arm-$(CS_BASE) ; \
	cp -r arm-none-eabi $(PREFIX) ; \
	popd ;
endif

multilibbash: gcc-$(GCC_VERSION)-$(CS_BASE)
	pushd gcc-$(GCC_VERSION)-$(CS_BASE) && \
	patch -N -p0 < ../patches/gcc-multilib-bash.patch && \
	popd ;

gcc-$(GCC_VERSION)-$(CS_BASE) : $(LOCAL_BASE)/gcc-$(CS_VERSION).tar.bz2
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) tar -jxf $<
else
	tar -jxf $<
endif

mpc-$(MPC_VERSION) : $(LOCAL_BASE)/mpc-$(CS_VERSION).tar.bz2
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) tar -jxf $<
else
	tar -jxf $<
endif


%-$(CS_BASE) : $(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) tar -jxf $<
else
	tar -jxf $<
endif

gmp: gmp-$(CS_BASE) sudomode
	sudo -u $(SUDO_USER) mkdir -p build/gmp && cd build/gmp ; \
	pushd ../../gmp-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	sudo -u $(SUDO_USER) ../../gmp-$(CS_BASE)/configure --disable-shared && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) all && \
	$(MAKE) install

mpc: mpc-$(MPC_VERSION) sudomode
	sudo -u $(SUDO_USER) mkdir -p build/gmp && cd build/gmp ; \
	pushd ../../mpc-$(MPC_VERSION) ; \
	make clean ; \
	popd ; \
	sudo -u $(SUDO_USER) ../../mpc-$(MPC_VERSION)/configure --disable-shared && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) all && \
	$(MAKE) install

mpfr: gmp mpfr-$(CS_BASE) sudomode
	sudo -u $(SUDO_USER) mkdir -p build/mpfr && cd build/mpfr && \
	pushd ../../mpfr-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	sudo -u $(SUDO_USER) ../../mpfr-$(CS_BASE)/configure LDFLAGS="-Wl,-search_paths_first" --disable-shared && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) all && \
	$(MAKE) install

cross-binutils: binutils-$(CS_BASE)
	mkdir -p build/binutils && cd build/binutils && \
	pushd ../../binutils-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	../../binutils-$(CS_BASE)/configure --prefix=$(PREFIX)		\
	--target=$(TARGET) --with-pkgversion=$(PKG_VERSION)		\
	--with-sysroot="$(PREFIX)/$(TARGET)" --with-bugurl=$(BUG_URL)	\
	--disable-nls --disable-werror && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-host install-target

CS_SPECS='--with-specs=%{save-temps: -fverbose-asm}			\
-D__CS_SOURCERYGXX_MAJ__=$(CS_MAJ) -D__CS_SOURCERYGXX_MIN__=$(CS_MIN)	\
-D__CS_SOURCERYGXX_REV__=$(CS_REV) %{O2:%{!fno-remove-local-statics:	\
-fremove-local-statics}}						\
%{O*:%{O|O0|O1|O2|Os:;:%{!fno-remove-local-statics:			\
-fremove-local-statics}}}'

cross-gcc-first: cross-binutils gcc-$(GCC_VERSION)-$(CS_BASE) multilibbash 
	mkdir -p build/gcc-first && cd build/gcc-first && \
	pushd ../../gcc-$(GCC_VERSION)-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	../../gcc-$(GCC_VERSION)-$(CS_BASE)/configure			\
	--prefix=$(PREFIX) --with-pkgversion=$(PKG_VERSION)		\
	--with-bugurl=$(BUG_URL) --target=$(TARGET) $(DEPENDENCIES)	\
	--disable-libquadmath --enable-languages="c" --with-gnu-ld	\
	--with-gnu-as --disable-nls --disable-libssp	\
	--with-newlib --without-headers --disable-shared --enable-lto	\
	--disable-threads --disable-libmudflap --disable-libgomp	\
	--disable-libstdcxx-pch --disable-libunwind-exceptions		\
	--disable-decimal-float --enable-poison-system-directories 	\
	--with-sysroot="$(PREFIX)/$(TARGET)"				\
	--with-build-time-tools="$(PREFIX)/$(TARGET)/bin"		\
	--disable-libffi --enable-extra-sgxxlite-multilibs $(CS_SPECS) && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-target && \
	$(MAKE) install-gcc

cross-gcc: cross-binutils cross-gcc-first cross-newlib gcc-$(GCC_VERSION)-$(CS_BASE) multilibbash 
	mkdir -p build/gcc-final && cd build/gcc-final && \
	mkdir -p $(PREFIX)/$(TARGET)/usr/include && \
	../../gcc-$(GCC_VERSION)-$(CS_BASE)/configure			\
	--prefix=$(PREFIX) --with-pkgversion=$(PKG_VERSION)		\
	--with-bugurl=$(BUG_URL) --target=$(TARGET) $(DEPENDENCIES)	\
	--enable-languages="c,c++" --with-gnu-ld --with-gnu-as		\
	--with-newlib --disable-nls --disable-libssp			\
	--disable-shared --enable-threads --with-headers=yes		\
	--disable-libmudflap --disable-libgomp	 --enable-lto		\
	--disable-libstdcxx-pch	--enable-poison-system-directories 	\
	--with-sysroot="$(PREFIX)/$(TARGET)"				\
	--with-build-time-tools="$(PREFIX)/$(TARGET)/bin"		\
	--enable-extra-sgxxlite-multilibs $(CS_SPECS) && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-target && \
	$(MAKE) install-gcc



ifeq ($(OPT_NEWLIB_SIZE),true)
NEWLIB_FLAGS?="-ffunction-sections -fdata-sections			\
-DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fomit-frame-pointer	\
-fno-unroll-loops -D__BUFSIZ__=256 -mabi=aapcs"
else
NEWLIB_FLAGS?="-g -O2 -fno-unroll-loops"
endif

cross-newlib: cross-binutils cross-gcc-first newlib-$(CS_BASE)
	mkdir -p build/newlib && cd build/newlib && \
	pushd ../../newlib-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	../../newlib-$(CS_BASE)/configure --prefix=$(PREFIX)	\
	--target=$(TARGET) --disable-newlib-supplied-syscalls	\
	--disable-libgloss --disable-nls	\
	--with-build-time-tools="$(PREFIX)/bin"       \
	--enable-newlib-io-long-long --enable-newlib-register-fini && \
	$(MAKE) -j$(PROCS) CFLAGS_FOR_TARGET=$(NEWLIB_FLAGS) CCASFLAGS=$(NEWLIB_FLAGS) && \
	$(MAKE) install

cross-gdb: gdb-$(CS_BASE)
	mkdir -p build/gdb && cd build/gdb && \
	pushd ../../gdb-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	../../gdb-$(CS_BASE)/configure --prefix=$(PREFIX) --target=$(TARGET) --with-pkgversion=$(PKG_VERSION) --with-bugurl=$(BUG_URL) --disable-werror && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-host install-target

.PHONY : clean
clean:
	rm -rf build *-$(CS_BASE) binutils-* gcc-* gdb-* newlib-* $(LOCAL_BASE)
