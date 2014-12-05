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

MATCH_CS           ?= false
OPT_NEWLIB_SIZE    ?= true
NEWLIB_NOFLOAT     ?= false
FULL_MULTILIBS     ?= false

####    PRIMARY TOOLCHAIN VERSIONS    #####

CS_MAJ			?= 2014
CS_MIN			?= 05
CS_BASE			?= $(CS_MAJ).$(CS_MIN)
CS_REV 			?= 28
GCC_VERSION 	?= 4.8
MPC_VERSION 	?= 2013.11
SOURCE_PACKAGE	?= 12773
BIN_PACKAGE		?= 12774

####  PRIMARY TOOLCHAIN URLS / FILES  #####

CS_VERSION 	= $(CS_BASE)-$(CS_REV)

LOCAL_BASE 	= arm-$(CS_VERSION)-arm-none-eabi
LOCAL_SOURCE 	= $(LOCAL_BASE).src.tar.bz2
LOCAL_BIN 	= $(LOCAL_BASE)-i686-pc-linux-gnu.tar.bz2
SOURCE_URL 	= https://sourcery.mentor.com/GNUToolchain/package$(SOURCE_PACKAGE)/public/arm-none-eabi/$(LOCAL_SOURCE)
BIN_URL 	= https://sourcery.mentor.com/GNUToolchain/package$(BIN_PACKAGE)/public/arm-none-eabi/$(LOCAL_BIN)

SOURCE_MD5_CHCKSUM ?= 0683c1a3512f88a5519e840919230c92
BIN_MD5_CHECKSUM ?= 02fc7078af9c9c7e792f026c772374ae

####    BUILD LABELING / TAGGING      #####
BUILD_ID   ?= $(shell git describe --always)
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

ifeq ($(NEWLIB_NOFLOAT),true)
NEWLIB_FLOAT?="--disable-newlib-io-float"
FLOAT_TAG?="NO_FLOAT_IO"
else
NEWLIB_FLOAT?=""
FLOAT_TAG?="FLOAT_IO"
endif

ifeq ($(FULL_MULTILIBS),true)
MULTILIB_FLAGS?="--enable-extra-sgxx-multilibs"
MULTILIB_TAG?="SGXX_ML"
else
MULTILIB_FLAGS?="--enable-extra-sgxxlite-multilibs"
MULTILIB_TAG?="SGXXLITE_ML"
endif

BUG_URL ?= https://github.com/jsnyder/arm-eabi-toolchain
PKG_VERSION ?= "32-bit ARM EABI Toolchain $(PKG_TAG)-$(FLOAT_TAG)-$(MULTILIB_TAG)-$(CS_BASE)-$(CS_REV)-$(BUILD_ID)"

STATICLIBS := $(CURDIR)/$(BUILD_PATH)/libs/

##############  BUILD VARS  ###############

BUILD_PATH	= build
CONFIG_STATUS	= config.status
MOD_CONFIG	= $(BUILD_PATH)/$(1)/$(CONFIG_STATUS)

############### BUILD RULES ###############

.SECONDARY:

.PRECIOUS: $(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2

default: install-cross

.PHONY: install-tools
install-tools: cross-binutils cross-gcc cross-gdb

.PHONY: install-cross
install-cross: install-tools install-note

.PHONY: install-deps
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

$(LOCAL_BIN).md5sum : $(LOCAL_BIN)
	@openssl md5 $< | cut -f 2 -d " " - > $@
	@([ "$$(<$@)" = "$(BIN_MD5_CHECKSUM)" ] || \
	( echo "Bad Checksum! Please remove the following file and retry: $(LOCAL_BIN)" && false ))

$(LOCAL_SOURCE).md5sum : $(LOCAL_SOURCE)
	@openssl md5 $< | cut -f 2 -d " " - > $@
	@([ "$$(<$@)" = "$(SOURCE_MD5_CHCKSUM)" ] || \
	( echo "Bad Checksum! Please remove the following file and retry: $(LOCAL_SOURCE)" && false ))

$(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2 : $(LOCAL_SOURCE).md5sum
ifeq ($(USER),root)
	@(tgt=`tar -jtf $(LOCAL_SOURCE) | grep  $*` && \
	sudo -u $(SUDO_USER) tar -jxvf $(LOCAL_SOURCE) $$tgt && \
	sudo -u $(SUDO_USER) touch $$tgt)
else
	@(tgt=`tar -jtf $(LOCAL_SOURCE) | grep  $*` && \
	tar -jxvf $(LOCAL_SOURCE) $$tgt && \
	touch $$tgt)
endif

arm-$(CS_BASE): $(LOCAL_BIN).md5sum
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
	pushd gcc-$(GCC_VERSION)-$(CS_BASE) ; \
	patch -N -p0 < ../patches/gcc-multilib-bash.patch ; \
	popd ;

gcc-$(GCC_VERSION)-$(CS_BASE) : $(LOCAL_BASE)/gcc-$(CS_VERSION).tar.bz2
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) tar -jxf $<
else
	tar -jxf $<
endif
	touch $@

mpc-$(MPC_VERSION) : $(LOCAL_BASE)/mpc-$(CS_VERSION).tar.bz2
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) tar -jxf $<
else
	tar -jxf $<
endif
	touch $@


%-$(CS_BASE) : $(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) tar -jxf $<
else
	tar -jxf $<
endif
	touch $@

$(call MOD_CONFIG,gmp) : gmp-$(CS_BASE)
	mkdir -p $(BUILD_PATH)/gmp && cd $(BUILD_PATH)/gmp ; \
	../../gmp-$(CS_BASE)/configure --disable-shared --prefix=$(STATICLIBS)

gmp: $(call MOD_CONFIG,gmp)
	cd $(BUILD_PATH)/$@ ; \
	$(MAKE) -j$(PROCS) all && \
	$(MAKE) install

$(call MOD_CONFIG,mpfr) : gmp mpfr-$(CS_BASE)
	mkdir -p $(BUILD_PATH)/mpfr && cd $(BUILD_PATH)/mpfr && \
	../../mpfr-$(CS_BASE)/configure --disable-shared --enable-static --prefix=$(STATICLIBS) --with-gmp=$(STATICLIBS)

mpfr: $(call MOD_CONFIG,mpfr)
	cd $(BUILD_PATH)/$@ ; \
	$(MAKE) -j$(PROCS) all && \
	$(MAKE) install

$(call MOD_CONFIG,mpc) : mpc-$(MPC_VERSION)
	mkdir -p $(BUILD_PATH)/mpc && cd $(BUILD_PATH)/mpc ; \
	../../mpc-$(CS_BASE)/configure --disable-shared --enable-static --prefix=$(STATICLIBS) --with-mpfr=$(STATICLIBS) --with-gmp=$(STATICLIBS)

mpc: $(call MOD_CONFIG,mpc)
	cd $(BUILD_PATH)/$@ ; \
	$(MAKE) -j$(PROCS) all && \
	$(MAKE) install

$(call MOD_CONFIG,binutils) : binutils-$(CS_BASE)
	mkdir -p $(BUILD_PATH)/binutils && cd $(BUILD_PATH)/binutils && \
	../../binutils-$(CS_BASE)/configure --prefix=$(PREFIX)		\
	--target=$(TARGET) --with-pkgversion=$(PKG_VERSION)		\
	--with-sysroot="$(PREFIX)/$(TARGET)" --with-bugurl=$(BUG_URL)	\
	--disable-nls --disable-werror

cross-binutils: $(call MOD_CONFIG,binutils)
	cd $(BUILD_PATH)/binutils ; \
	touch makeinfo && chmod +x makeinfo && export PATH=$$(pwd):$$PATH && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-host install-target

CS_SPECS='--with-specs=%{save-temps: -fverbose-asm}			\
-D__CS_SOURCERYGXX_MAJ__=$(CS_MAJ) -D__CS_SOURCERYGXX_MIN__=$(CS_MIN)	\
-D__CS_SOURCERYGXX_REV__=$(CS_REV) %{O2:%{!fno-remove-local-statics:	\
-fremove-local-statics}}						\
%{O*:%{O|O0|O1|O2|Os:;:%{!fno-remove-local-statics:			\
-fremove-local-statics}}}'

$(call MOD_CONFIG,gcc-first) : gmp mpfr mpc cross-binutils gcc-$(GCC_VERSION)-$(CS_BASE) multilibbash
	mkdir -p $(BUILD_PATH)/gcc-first && cd $(BUILD_PATH)/gcc-first && \
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
	--disable-libffi $(MULTILIB_FLAGS) $(CS_SPECS) \
	--with-gmp=$(STATICLIBS) --with-mpfr=$(STATICLIBS) --with-mpc=$(STATICLIBS)

cross-gcc-first: $(call MOD_CONFIG,gcc-first)
	cd $(BUILD_PATH)/gcc-first ; \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-target && \
	$(MAKE) install-gcc

$(call MOD_CONFIG,gcc-final) : gmp mpfr mpc cross-binutils cross-gcc-first cross-newlib gcc-$(GCC_VERSION)-$(CS_BASE) multilibbash
	mkdir -p $(BUILD_PATH)/gcc-final && cd $(BUILD_PATH)/gcc-final && \
	mkdir -p $(PREFIX)/$(TARGET)/usr/include && \
	../../gcc-$(GCC_VERSION)-$(CS_BASE)/configure			\
	--prefix=$(PREFIX) --with-pkgversion=$(PKG_VERSION)		\
	--with-bugurl=$(BUG_URL) --target=$(TARGET) $(DEPENDENCIES)	\
	--enable-languages="c,c++" --with-gnu-ld --with-gnu-as		\
	--with-newlib --disable-nls --disable-libssp			\
	--disable-shared --enable-threads --with-headers=yes		\
	--disable-libmudflap --disable-libgomp     --enable-lto		\
	--disable-libstdcxx-pch	--enable-poison-system-directories 	\
	--with-sysroot="$(PREFIX)/$(TARGET)"				\
	--with-build-time-tools="$(PREFIX)/$(TARGET)/bin"		\
	$(MULTILIB_FLAGS) $(CS_SPECS) \
	--with-gmp=$(STATICLIBS) --with-mpfr=$(STATICLIBS) --with-mpc=$(STATICLIBS)

cross-gcc: $(call MOD_CONFIG,gcc-final)
	cd $(BUILD_PATH)/gcc-final ; \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-target && \
	$(MAKE) install-gcc



ifeq ($(OPT_NEWLIB_SIZE),true)
NEWLIB_FLAGS?="-g -ffunction-sections -fdata-sections			\
-DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fomit-frame-pointer	\
-fno-unroll-loops -D__BUFSIZ__=256 -mabi=aapcs"
else
NEWLIB_FLAGS?="-g -O2 -fno-unroll-loops"
endif

$(call MOD_CONFIG,newlib) : cross-binutils cross-gcc-first newlib-$(CS_BASE)
	mkdir -p $(BUILD_PATH)/newlib && cd $(BUILD_PATH)/newlib && \
	../../newlib-$(CS_BASE)/configure --prefix=$(PREFIX)	\
	--target=$(TARGET) --disable-newlib-supplied-syscalls	\
	--disable-libgloss --disable-nls	\
	--with-build-time-tools="$(PREFIX)/bin"       \
	$(NEWLIB_FLOAT) \
	--enable-newlib-io-long-long --enable-newlib-register-fini
	

cross-newlib: $(call MOD_CONFIG,newlib)
	cd $(BUILD_PATH)/newlib ; \
	$(MAKE) -j$(PROCS) CFLAGS_FOR_TARGET=$(NEWLIB_FLAGS) CCASFLAGS=$(NEWLIB_FLAGS) && \
	$(MAKE) install

$(call MOD_CONFIG,gdb) : gdb-$(CS_BASE)
	mkdir -p $(BUILD_PATH)/gdb && cd $(BUILD_PATH)/gdb && \
	../../gdb-$(CS_BASE)/configure --prefix=$(PREFIX) --target=$(TARGET) --with-pkgversion=$(PKG_VERSION) --with-bugurl=$(BUG_URL) --disable-werror

cross-gdb: $(call MOD_CONFIG,gdb)
	cd $(BUILD_PATH)/gdb ; \
	touch makeinfo && chmod +x makeinfo && export PATH=$$(pwd):$$PATH && \
	$(MAKE) -j$(PROCS) CFLAGS="-Wno-error=return-type" && \
	$(MAKE) installdirs install-host install-target

.PHONY : clean
clean:
	rm -rf build *-$(CS_BASE) binutils-* gcc-* gdb-* newlib-* $(LOCAL_BASE)
