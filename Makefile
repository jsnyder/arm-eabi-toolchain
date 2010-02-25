TARGET=arm-eabi
PREFIX=$(HOME)/arm-cs-tools/
PROCS=3
CS_VERSION = 2009q3-68
LOCAL_BASE = arm-$(CS_VERSION)-arm-none-eabi
LOCAL_SOURCE = $(LOCAL_BASE).src.tar.bz2
SOURCE_URL = http://www.codesourcery.com/sgpp/lite/arm/portal/package5352/public/arm-none-eabi/$(LOCAL_SOURCE)
MD5_CHECKSUM = 121805e970e78291247ab6bd29bcab73


install-cross: cross-binutils cross-gcc cross-g++ cross-newlib cross-gdb
install-deps: gmp mpfr

sudomode:
ifneq ($(USER),root)
	@echo Please run this target with sudo!
	@echo e.g.:  sudo make targetname
	@exit 1
endif

$(LOCAL_SOURCE):
	curl -LO $(SOURCE_URL)

download: $(LOCAL_SOURCE)
	@(t1=`md5 $(LOCAL_SOURCE) | cut -f 4 -d " " -` && \
	test $$t1 = $(MD5_CHECKSUM) || \
	echo "Bad Checksum! Please remove the following file and retry:\n$(LOCAL_SOURCE)")

$(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2 : download
	tar -jxvf $(LOCAL_SOURCE) --include='*$@*'

%-stable : $(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2
	tar -jxf $<

%-4.4 : $(LOCAL_BASE)/%-$(CS_VERSION).tar.bz2
	tar -jxf $<

gcc44patch: gcc-4.4
	patch -N -p0 < gcc-44.patch

gmp: sudomode gmp-stable
	sudo -u $(SUDO_USER) mkdir -p build/gmp && cd build/gmp && \
	(./config.status || sudo -u $(SUDO_USER) ../../gmp-*/configure --disable-shared) && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) CFLAGS="-fast" all && \
	$(MAKE) install

mpfr: sudomode gmp mpfr-stable
	sudo -u $(SUDO_USER) mkdir -p build/mpfr && cd build/mpfr && \
	(./config.status || sudo -u $(SUDO_USER) ../../mpfr-*/configure LDFLAGS="-Wl,-search_paths_first" --disable-shared) && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) CFLAGS="-fast" all && \
	$(MAKE) install

cross-binutils: binutils-stable
	mkdir -p build/binutils && cd build/binutils && \
	(./config.status || ../../binutils-*/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-nls --disable-werror) && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

cross-gcc: cross-binutils gcc-4.4 gcc44patch
	mkdir -p build/gcc && cd build/gcc && \
	(./config.status || ../../gcc-*/configure --prefix=$(PREFIX) --target=$(TARGET) --enable-languages="c" --with-gnu-ld --with-gnu-as --with-newlib --disable-nls --disable-libssp --with-newlib --without-headers --disable-shared --disable-threads --disable-libmudflap --disable-libgomp --disable-libstdcxx-pch --disable-libunwind-exceptions --disable-libffi --enable-extra-sgxxlite-multilibs) && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

cross-g++: cross-binutils cross-gcc cross-newlib gcc-4.4 gcc44patch
	mkdir -p build/g++ && cd build/g++ && \
	(./config.status || ../../gcc-*/configure --prefix=$(PREFIX) --target=$(TARGET) --enable-languages="c++" --with-gnu-ld --with-gnu-as --with-newlib --disable-nls --disable-libssp --with-newlib --without-headers --disable-shared --disable-threads --disable-libmudflap --disable-libgomp --disable-libstdcxx-pch --disable-libunwind-exceptions --disable-libffi --enable-extra-sgxxlite-multilibs) && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

cross-newlib: cross-binutils cross-gcc newlib-stable
	mkdir -p build/newlib && cd build/newlib && \
	(./config.status || ../../newlib-*/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-newlib-supplied-syscalls  --disable-libgloss --disable-nls --disable-shared) && \
	$(MAKE) -j$(PROCS) CFLAGS_FOR_TARGET="-ffunction-sections -fdata-sections -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fomit-frame-pointer -D__BUFSIZ__=256" && \
	$(MAKE) install

cross-gdb: gdb-stable
	mkdir -p build/gdb && cd build/gdb && \
	(./config.status || ../../gdb-*/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-werror) && \
	$(MAKE) -j$(PROCS) && \
  $(MAKE) install

clean:
	rm -rf build
