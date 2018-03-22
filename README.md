# Coda Compression Program
Simple compression and decompression program with optional encryption.

From most import to least important.
DMD and GDC is currently broken, please use ldc 1.7.0.
Botan is failing to compile on newest version of dlang compilers.

### Dependencies:
```
  dub
  A D compiler  - (ldc dmd gdc)
  botan         - for encryption
  zstd-d        - for compression
  zlib-dev      - parent lib for zstd
 ``` 
To install simply run make after downloading it.

### OSX and Linux:
```
  Then you have the option of adding bin to your path, or running make install. Which will require sudo accsess to put coda into your /usr/bin.
```
  
### Windows:
```
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
  coda -c -en -key= FILENAMES
  coda -d -de -key= FILENAMES

  -help					Show this menu
  --version				Show current version
  -v						Verbose mode
  -d  --decompress:		Decompress a coda file
  -c  --compress:			Compress files
  -cl --compressionLevel:	Set the compression level. Default is 9. A value between 1-22.
  -en  --encrypt			Also encrypt the data before compression.
    -k= --key=				Set the key for decyption. Must be less than 49.
  -de --decrypt				Also decrypt the data.
    -k= --key=				Set the key for decyption. Must be less than 49.
  -n= --name=				Set the name for the output file in compression. Useless for decompression.
```
