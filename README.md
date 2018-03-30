# Coda Compression Program
Simple compression and decompression program with optional encryption.

From most import to least important.

### Dependencies:
```
  dub
  A D compiler  - (ldc dmd gdc)
  openssl       - for encryption
 ```
To install simply run make after downloading it.
To make using a different compiler than ldc run
```
make all DC=< compiler >
```
If you wish to build using dub run
```
dub build --compiler=<  compiler >
```
but I would suggest using make.
Make wil
### OSX and Linux:
```
  apt-get install libzstd-dev then run make.
  Then you have the option of adding bin to your path, or running make install. Which will require sudo accsess to put coda into your /usr/bin.
```
  
### Windows:
```
Get the libzstd library then run make.
  To add it to your path go to advanced system variables and add the location to the path or make installWindows. Will be installed into your C:/Program Files/Coda.
  
 Although you can install on windows, it is untested on windows.
 ```
If you wish to help, please either contact me at alex.strole004@gmail.com or add a pull request with your updated code.
Thanks!
 
### Help:
```
Coda Compression Program
Made by: Alex Strole

Rewritten in D!

coda --version
coda -help
coda -d FILENAME
coda -c FILENAMES
coda -c -e -key FILENAMES
coda -u -d -key FILENAMES

--help					Show this menu
--version				Show current version
-v						Verbose mode
-u  --uncompress:		Decompress a coda file
-c  --compress:			Compress files
-l --compressionLevel:	Set the compression level. Default is 9. A value between 1-22.
-e  --encrypt			Also encrypt the data before compression.
	-k --key				Set the key for decyption. If not provided, a random one will be generated.
-d --decrypt				Also decrypt the data.
	-k --key				Set the key for decyption. If not provided, a random one will be generated.
-n --name				Set the name for the output file in compression. Useless for decompression.
```
