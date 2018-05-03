DC=dmd
NAME=bin/coda

$(NAME):
	dub build --compiler=$(DC)
all: $(NAME)

clean:
	dub clean
fclean: clean
	rm -rf bin
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


