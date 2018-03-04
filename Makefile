CC=ldc2

.PHONY: all
mkdir bin

all:
	dub build --compiler=$(CC) --build=release

.PHONY: allv

allv:
	dub build --compiler=$(CC) -v --build=release

.PHONY: clean

clean:
	dub clean

.PHONY: fclean

fclean:
	make clean
	rm bin/coda
	
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
