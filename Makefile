TARGET=arm-none-eabi
PREFIX=$(HOME)/Projects/arm-eabi-tools/
PROCS=3
CS_BASE = 2010q1
CS_REV = 188
CS_VERSION = $(CS_BASE)-$(CS_REV)
LOCAL_BASE = arm-$(CS_VERSION)-arm-none-eabi
LOCAL_SOURCE = $(LOCAL_BASE).src.tar.bz2
SOURCE_URL = http://www.codesourcery.com/sgpp/lite/arm/portal/package6492/public/arm-none-eabi/$(LOCAL_SOURCE)
MD5_CHECKSUM = 3bbd7c7d6f60606d0bc7843fbbdbb648


install-cross: cross-binutils cross-gcc cross-g++ cross-newlib cross-gdb
install-deps: gmp mpfr

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

%-4.4-$(CS_BASE) : $(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2
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

gcc44patch: gcc-4.4-$(CS_BASE)
	patch -N -p0 < patches/gcc-44.patch

multilibbash: gcc-4.4-$(CS_BASE)
	patch -N -p0 < patches/gcc-multilib-bash.patch

gmp: gmp-$(CS_BASE) sudomode
	sudo -u $(SUDO_USER) mkdir -p build/gmp && cd build/gmp ; \
	pushd ../../gmp-* ; \
	make clean ; \
	popd ; \
	sudo -u $(SUDO_USER) ../../gmp-*/configure --disable-shared && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) all && \
	$(MAKE) install

mpfr: gmp mpfr-$(CS_BASE) sudomode
	sudo -u $(SUDO_USER) mkdir -p build/mpfr && cd build/mpfr && \
	pushd ../../mpfr-* ; \
	make clean ; \
	popd ; \
	sudo -u $(SUDO_USER) ../../mpfr-*/configure LDFLAGS="-Wl,-search_paths_first" --disable-shared && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) all && \
	$(MAKE) install

cross-binutils: binutils-$(CS_BASE)
	mkdir -p build/binutils && cd build/binutils && \
	pushd ../../binutils-* ; \
	make clean ; \
	popd ; \
	../../binutils-*/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-nls --disable-werror && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

cross-gcc: cross-binutils gcc-4.4-$(CS_BASE) gcc44patch multilibbash
	mkdir -p build/gcc && cd build/gcc && \
	pushd ../../gcc-* ; \
	make clean ; \
	popd ; \
	../../gcc-*/configure --prefix=$(PREFIX) --target=$(TARGET) --enable-languages="c" --with-gnu-ld --with-gnu-as --with-newlib --disable-nls --disable-libssp --with-newlib --without-headers --disable-shared --disable-libmudflap --disable-libgomp --disable-libstdcxx-pch --disable-libunwind-exceptions --disable-libffi --enable-extra-sgxxlite-multilibs && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

cross-g++: cross-binutils cross-gcc cross-newlib gcc-4.4-$(CS_BASE) gcc44patch multilibbash
	mkdir -p build/g++ && cd build/g++ && \
	../../gcc-*/configure --prefix=$(PREFIX) --target=$(TARGET) --enable-languages="c++" --with-gnu-ld --with-gnu-as --with-newlib --disable-nls --disable-libssp --with-newlib --without-headers --disable-shared --disable-libmudflap --disable-libgomp --disable-libstdcxx-pch --disable-libunwind-exceptions --disable-libffi --enable-extra-sgxxlite-multilibs --enable-libstdcxx-allocator=malloc --enable-cxx-flags="-ffunction-sections -fdata-sections -fomit-frame-pointer" && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

NEWLIB_FLAGS="-ffunction-sections -fdata-sections -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fno-unroll-loops -fomit-frame-pointer -D__BUFSIZ__=256 -DREENTRANT_SYSCALLS_PROVIDED -D__DYNAMIC_REENT__ -D_WANT_REENT_SMALL"
cross-newlib: cross-binutils cross-gcc newlib-$(CS_BASE)
	mkdir -p build/newlib && cd build/newlib && \
	pushd ../../newlib-* ; \
	make clean ; \
	popd ; \
	../../newlib-*/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-newlib-supplied-syscalls --disable-libgloss --disable-nls --disable-shared --enable-newlib-io-long-long && \
	$(MAKE) -j$(PROCS) CFLAGS_FOR_TARGET=$(NEWLIB_FLAGS) CCASFLAGS=$(NEWLIB_FLAGS) && \
	$(MAKE) install

cross-gdb: gdb-$(CS_BASE)
	mkdir -p build/gdb && cd build/gdb && \
	pushd ../../gdb-* ; \
	make clean ; \
	popd ; \
	../../gdb-*/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-werror && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

.PHONY : clean
clean:
	rm -rf build *-$(CS_BASE) gcc-* gdb-* newlib-* $(LOCAL_BASE)
