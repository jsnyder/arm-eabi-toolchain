SHELL = /bin/bash
TARGET=arm-none-eabi
PREFIX=$(HOME)/arm-cs-tools/
PROCS=6
BUG_URL="https://github.com/jsnyder/arm-eabi-toolchain/issues"
CS_BASE = 2010.09
CS_REV = 51
PACKAGE_VERSION="arm-eabi-toolchain $(CS_BASE)-$(CS_REV)"
GCC_VERSION = 4.5
MPC_VERSION = 0.8.1
CS_VERSION = $(CS_BASE)-$(CS_REV)
LOCAL_BASE = arm-$(CS_VERSION)-arm-none-eabi
LOCAL_SOURCE = $(LOCAL_BASE).src.tar.bz2
SOURCE_URL = http://www.codesourcery.com/sgpp/lite/arm/portal/package7812/public/arm-none-eabi/$(LOCAL_SOURCE)
MD5_CHECKSUM = 0ab992015a71443efbf3654f33ffc675

install-cross: cross-binutils cross-gcc cross-g++ cross-newlib cross-gdb
install-deps: gmp mpfr mpc

sudomode:
ifneq ($(USER),root)
	@echo Please run this target with sudo!
	@echo e.g.: sudo make targetname
	@exit 1
endif

$(LOCAL_SOURCE):
ifeq ($(USER),root)
	sudo -u $(SUDO_USER) curl -LO $(SOURCE_URL)
else
	curl -LO $(SOURCE_URL)
endif

download: $(LOCAL_SOURCE)
	@(t1=`openssl md5 $(LOCAL_SOURCE) | cut -f 2 -d " " -` && \
	test $$t1 = $(MD5_CHECKSUM) || \
	echo "Bad Checksum! Please remove the following file and retry:\n$(LOCAL_SOURCE)")

$(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2 : download
ifeq ($(USER),root)
	@(tgt=`tar -jtf $(LOCAL_SOURCE) | grep  $*` && \
	sudo -u $(SUDO_USER) tar -jxvf $(LOCAL_SOURCE) $$tgt)
else
	@(tgt=`tar -jtf $(LOCAL_SOURCE) | grep  $*` && \
	tar -jxvf $(LOCAL_SOURCE) $$tgt)
endif

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

gcc-optsize-patch: gcc-$(GCC_VERSION)-$(CS_BASE)/
	pushd gcc-$(GCC_VERSION)-$(CS_BASE) ; \
	patch -N -p1 < ../patches/gcc-optsize.patch ; \
	popd ;

gmp: gmp-$(CS_BASE)/ sudomode
	sudo -u $(SUDO_USER) mkdir -p build/gmp && cd build/gmp ; \
	pushd ../../gmp-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	sudo -u $(SUDO_USER) ../../gmp-$(CS_BASE)/configure --disable-shared && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) all && \
	$(MAKE) install

mpc: mpc-$(MPC_VERSION)/ sudomode
	sudo -u $(SUDO_USER) mkdir -p build/gmp && cd build/gmp ; \
	pushd ../../mpc-$(MPC_VERSION) ; \
	make clean ; \
	popd ; \
	sudo -u $(SUDO_USER) ../../mpc-$(MPC_VERSION)/configure --disable-shared && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) all && \
	$(MAKE) install

mpfr: gmp mpfr-$(CS_BASE)/ sudomode
	sudo -u $(SUDO_USER) mkdir -p build/mpfr && cd build/mpfr && \
	pushd ../../mpfr-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	sudo -u $(SUDO_USER) ../../mpfr-$(CS_BASE)/configure LDFLAGS="-Wl,-search_paths_first" --disable-shared && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) all && \
	$(MAKE) install

cross-binutils: binutils-$(CS_BASE)/
	mkdir -p build/binutils && cd build/binutils && \
	pushd ../../binutils-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	../../binutils-$(CS_BASE)/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-nls --disable-werror \
	--with-sysroot=$(PREFIX)/$(TARGET) --with-bugurl=$(BUG_URL) && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-host install-target

CFLAGS_FOR_TARGET="-ffunction-sections -fdata-sections -fomit-frame-pointer \
				  -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -g -Os \
				  -fno-unroll-loops -mabi=aapcs"
cross-gcc: cross-binutils gcc-$(GCC_VERSION)-$(CS_BASE)/ gcc-optsize-patch
	mkdir -p build/gcc && cd build/gcc && \
	pushd ../../gcc-$(GCC_VERSION)-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	../../gcc-$(GCC_VERSION)-$(CS_BASE)/configure --prefix=$(PREFIX) --target=$(TARGET) \
	--enable-languages="c" --with-gnu-ld --with-gnu-as --with-newlib --disable-nls \
	--disable-libssp --with-newlib --disable-shared --enable-target-optspace \
	--disable-threads --disable-libmudflap --disable-libgomp --disable-libstdcxx-pch \
	--disable-libunwind-exceptions --disable-libffi --enable-extra-sgxxlite-multilibs \
	--enable-libstdcxx-allocator=malloc --with-bugurl=$(BUG_URL) \
	--enable-cxx-flags=$(CFLAGS_FOR_TARGET) --with-sysroot=$(PREFIX)/$(TARGET) \
	--with-build-sysroot=$(PREFIX)/$(TARGET) --with-build-time-tools=$(PREFIX)/$(TARGET)/bin \
	CFLAGS_FOR_TARGET=$(CFLAGS_FOR_TARGET) LDFLAGS_FOR_TARGET="--sysroot=$(PREFIX)/$(TARGET)" \
	CPPFLAGS_FOR_TARGET="--sysroot=$(PREFIX)/$(TARGET)" && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-target && \
	$(MAKE) -C gcc install-common install-cpp install- install-driver install-headers install-man

cross-g++: cross-binutils cross-gcc cross-newlib gcc-$(GCC_VERSION)-$(CS_BASE)/ gcc-optsize-patch
	mkdir -p build/g++ && cd build/g++ && \
	../../gcc-$(GCC_VERSION)-$(CS_BASE)/configure --prefix=$(PREFIX) --target=$(TARGET) \
	--enable-languages="c++" --with-gnu-ld --with-gnu-as --with-newlib --disable-nls \
	--disable-libssp --with-newlib --disable-shared \
	--disable-threads --disable-libmudflap --disable-libgomp --disable-libstdcxx-pch \
	--disable-libunwind-exceptions --disable-libffi --enable-extra-sgxxlite-multilibs \
	--enable-libstdcxx-allocator=malloc --with-bugurl=$(BUG_URL) \
	--enable-cxx-flags=$(CFLAGS_FOR_TARGET) --with-sysroot=$(PREFIX)/$(TARGET) \
	--with-build-sysroot=$(PREFIX)/$(TARGET) --with-build-time-tools=$(PREFIX)/$(TARGET)/bin \
	CFLAGS_FOR_TARGET=$(CFLAGS_FOR_TARGET)  LDFLAGS_FOR_TARGET="--sysroot=$(PREFIX)/$(TARGET)" \
	CPPFLAGS_FOR_TARGET="--sysroot=$(PREFIX)/$(TARGET)" && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-target && \
	$(MAKE) -C gcc install-common install-cpp install- install-driver install-headers install-man

NEWLIB_FLAGS="-ffunction-sections -fdata-sections -DPREFER_SIZE_OVER_SPEED \
			 -D__OPTIMIZE_SIZE__ -g -Os -fomit-frame-pointer -fno-unroll-loops \
			 -D__BUFSIZ__=128 -mabi=aapcs -DSMALL_MEMORY"
cross-newlib: cross-binutils cross-gcc newlib-$(CS_BASE)/ 
	mkdir -p build/newlib && cd build/newlib && \
	pushd ../../newlib-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	../../newlib-$(CS_BASE)/configure --prefix=$(PREFIX) --target=$(TARGET) \
	--disable-newlib-supplied-syscalls --disable-libgloss --disable-nls \
	--disable-shared --enable-newlib-io-long-long --enable-target-optspace \
	--enable-newlib-multithread --enable-newlib-reent-small \
	--disable-newlib-atexit-alloc && \
	$(MAKE) -j$(PROCS) CFLAGS_FOR_TARGET=$(NEWLIB_FLAGS) CCASFLAGS=$(NEWLIB_FLAGS) && \
	$(MAKE) install

cross-gdb: gdb-$(CS_BASE)/
	mkdir -p build/gdb && cd build/gdb && \
	pushd ../../gdb-$(CS_BASE) ; \
	make clean ; \
	popd ; \
	../../gdb-$(CS_BASE)/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-werror && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) installdirs install-host install-target && \
	mkdir -p $(PREFIX)/man/man1 && \
	cp ../../gdb-$(CS_BASE)/gdb/gdb.1 $(PREFIX)/man/man1/arm-none-eabi-gdb.1

.PHONY : clean
clean:
	rm -rf build *-$(CS_BASE) binutils-* gcc-* gdb-* newlib-* mpc-* $(LOCAL_BASE)
