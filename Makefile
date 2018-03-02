CC=ldc2

.PHONY: all

all:
	dub build --compiler=$(CC) --build=release

.PHONY: allv

allv:
	dub build --compiler=$(CC) -v --build=release --nodeps

.PHONY: clean

clean:
	dub clean

.PHONY: fclean

fclean:
	make clean
	rm bin/coda

.PHONY: alloffline

alloffline:
	dub add-path dependencies
	dub build --compiler=$(CC) --build=release

.PHONY: allvoffine

allvoffline:
	dub add-path dependencies
	dub build --compiler=$(CC) -v --build=release