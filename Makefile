DC=ldc

NAME=bin/coda

$(NAME):
	if [ ! -d "bin" ]; then \
		mkdir bin; \
	fi
	dub build --compiler=$(DC) --build=release

all: $(NAME)

allv:
	if [ ! -d "bin" ]; then \
		mkdir bin; \
	fi
	dub build --compiler=$(DC) --vverbose --build=release

.PHONY: test

test:
	dub test --compiler=$(DC)

clean:
	dub clean

fclean: clean
	rm -rf bin
	rm -rf .dub

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

.PHONY: all re uninstallWindows installWindows uninstall install fclean test


