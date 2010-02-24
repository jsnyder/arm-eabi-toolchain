TARGET=arm-eabi
PREFIX=$(HOME)/arm-cs-tools/
PROCS=3

install-cross: cross-binutils cross-gcc cross-g++ cross-newlib cross-gdb
install-deps: gmp mpfr

sudomode:
ifneq ($(USER),root)
	@echo Please run this target with sudo!
	@echo e.g.:  sudo make targetname
	@exit 1
endif

gcc44patch:
	patch -N -p0 < gcc-44.patch

gmp: sudomode
	sudo -u $(SUDO_USER) mkdir -p build/gmp && cd build/gmp && \
	(./config.status || sudo -u $(SUDO_USER) ../../gmp-*/configure --disable-shared) && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) CFLAGS="-fast" all && \
	$(MAKE) install

mpfr: sudomode gmp
	sudo -u $(SUDO_USER) mkdir -p build/mpfr && cd build/mpfr && \
	(./config.status || sudo -u $(SUDO_USER) ../../mpfr-*/configure LDFLAGS="-Wl,-search_paths_first" --disable-shared) && \
	sudo -u $(SUDO_USER) $(MAKE) -j$(PROCS) CFLAGS="-fast" all && \
	$(MAKE) install

cross-binutils:
	mkdir -p build/binutils && cd build/binutils && \
	(./config.status || ../../binutils-*/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-nls --disable-werror) && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

cross-gcc: cross-binutils
	mkdir -p build/gcc && cd build/gcc && \
	(./config.status || ../../gcc-*/configure --prefix=$(PREFIX) --target=$(TARGET) --enable-languages="c" --with-gnu-ld --with-gnu-as --with-newlib --disable-nls --disable-libssp --with-newlib --without-headers --disable-shared --disable-threads --disable-libmudflap --disable-libgomp --disable-libstdcxx-pch --disable-libunwind-exceptions --disable-libffi --enable-extra-sgxxlite-multilibs) && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

cross-g++: cross-binutils cross-gcc cross-newlib
	mkdir -p build/g++ && cd build/g++ && \
	(./config.status || ../../gcc-*/configure --prefix=$(PREFIX) --target=$(TARGET) --enable-languages="c++" --with-gnu-ld --with-gnu-as --with-newlib --disable-nls --disable-libssp --with-newlib --without-headers --disable-shared --disable-threads --disable-libmudflap --disable-libgomp --disable-libstdcxx-pch --disable-libunwind-exceptions --disable-libffi --enable-extra-sgxxlite-multilibs) && \
	$(MAKE) -j$(PROCS) && \
	$(MAKE) install

cross-newlib: cross-binutils cross-gcc
	mkdir -p build/newlib && cd build/newlib && \
	(./config.status || ../../newlib-*/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-newlib-supplied-syscalls  --disable-libgloss --disable-nls --disable-shared) && \
	$(MAKE) -j$(PROCS) CFLAGS_FOR_TARGET="-ffunction-sections -fdata-sections -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fomit-frame-pointer -D__BUFSIZ__=256" && \
	$(MAKE) install

cross-gdb:
	mkdir -p build/gdb && cd build/gdb && \
	(./config.status || ../../gdb-*/configure --prefix=$(PREFIX) --target=$(TARGET) --disable-werror) && \
	$(MAKE) -j$(PROCS) && \
  $(MAKE) install

clean:
	rm -rf build
