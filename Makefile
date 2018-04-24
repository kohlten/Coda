DC=dmd
NAME=bin/coda
LIBS=libsecured.a
LIBIFLAGS=-Idepends/SecureD/source -Idepends/openssl-d/
LIBSRC=depends/SecureD/source/secured/*.d
IFLAGS=-Isource/ -Idepends/SecureD/source -Idepends/openssl-d -Idepends/zstd-d/source -I/usr/local/lib
SRC=source/*.d depends/zstd-d/source/zstd/c/zstd.d depends/zstd-d/source/zstd/*.d libsecured.a
LLFLAGS=-L=-Ldepends/zlib/ -L=-lz -L=-Ldepends/zstd//lib -L=-lzstd -L=-lssl -L=-lcrypto
DLFLAGS=-L-Ldepends/zlib -L-lz -L-Ldepends/zstd//lib -L-lzstd -L-lssl -L-lcrypto -g

$(NAME):
	if [ ! -d "obj" ]; then \
			mkdir obj; \
	fi
	make depends
ifeq ($(DC), ldc2)
	$(DC) -lib -of$(LIBS) -od=obj -Oz -O3 -d-version=OpenSSL -d-version=Have_secured -d-version=Have_openssl $(LIBIFLAGS) $(LIBSRC)
	$(DC) -ofbin/coda -d-version=OpenSSL -od=obj -Oz -O3 -d-version=Have_coda -d-version=Have_zstd -d-version=Have_secured -d-version=Have_openssl $(IFLAGS)  $(SRC) $(LLFLAGS) -vcolumns
endif
ifeq ($(DC), dmd)
	$(DC) -c -v -of=$(LIBS) -od=obj -version=OpenSSL -version=Have_secured -version=Have_openssl $(LIBIFLAGS) $(LIBSRC)
	$(DC) -v -of=bin/coda -version=OpenSSL -od=obj -version=Have_coda -version=Have_zstd -version=Have_secured -version=Have_openssl $(IFLAGS) $(SRC) $(DLFLAGS)
endif
ifeq ($(DC), gdc)
	$(DC) -lib -offilename $(LIBS) -od=obj -O3 --release -version=OpenSSL -version=Have_secured -version=Have_openssl $(LIBIFLAGS) $(LIBSRC)
	$(DC) -offilename bin/coda -version=OpenSSL -od=obj -O3 --release -version=Have_coda -version=Have_zstd -version=Have_secured -version=Have_openssl $(IFLAGS) $(SRC) $(DLFLAGS)
endif

all: $(NAME)

depends:
	if [ ! -d "depends" ]; then \
		mkdir depends; \
	fi
	-git clone https://github.com/etcimon/botan-math.git depends/botan-math
	-git clone https://github.com/etcimon/botan.git depends/botan
	-git clone https://github.com/repeatedly/zstd-d.git depends/zstd-d
	-git clone https://github.com/LightBender/SecureD.git depends/SecureD
	-git clone https://github.com/etcimon/memutils.git depends/memutils
	-git clone https://github.com/D-Programming-Deimos/openssl.git depends/openssl-d
	-git clone https://github.com/facebook/zstd.git depends/zstd
	-git clone https://github.com/madler/zlib.git depends/zlib
	-cd depends/zstd && make && cd lib && rm *.dylib
	-cd depends/zlib && ./configure && make

clean:
	-rm -rf obj
	cd depends/zstd && make clean

fclean: clean
	-rm -rf bin
	-rm libsecured.a
	-rm -rf depends

install:
	sudo cp bin/coda /usr/bin

uninstall:
	sudo rm usr/bin/coda	

installWindows:
	mkdir C:/Program\ Files/Coda
	copy bin/coda C:/Program\ Files/coda/

uninstallWindows:
	del C:/Program\ Files/Coda/coda
	rmdir C:/Program\ Files/Coda

re: fclean all

.PHONY: all re uninstallWindows installWindows uninstall install fclean


