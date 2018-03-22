CC=ldc2

.PHONY: all

all:
	if [ ! -d "bin" ]; then \
		mkdir bin; \
	fi
	dub build --compiler=$(CC) --build=release

.PHONY: allv

allv:
	if [ ! -d "bin" ]; then \
		mkdir bin; \
	fi
	dub build --compiler=$(CC) --vverbose --build=release

.PHONY: clean

clean:
	dub clean

.PHONY: fclean

fclean: clean
	rm -rf bin
	rm -rf .dub
	
.PHONY: install

install:
	sudo cp bin/coda /usr/bin
	
.PHONY: uninstall

uninstall:
	sudo rm usr/bin/coda

.PHONY: installWindows	

installWindows:
	mkdir C:/Program\ Files/Coda
	copy bin/coda C:/Program\ Files/coda/

.PHONY: uninstallWindows

uninstallWindows:
	del C:/Program\ Files/Coda/coda
	rmdir C:/Program\ Files/Coda

.PHONY: re

re: fclean all