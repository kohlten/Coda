import std.stdio : writeln;
import std.exception : ErrnoException;
import std.conv : to, ConvException;
import std.algorithm : canFind;
import std.array : split;
import std.string;
import std.file : exists, isFile, isDir, mkdir;
import extraFuncs;

immutable string VERSION = "v0.0.6";
immutable string HELP =
"Coda Compression Program
Made by: Alex Strole

Rewritten in D!

coda --version
coda -help
coda -d FILENAME
coda -c FILENAMES
coda -c -e -key FILENAMES
coda -u -d -key FILENAMES

-help					Show this menu
--version				Show current version
-v						Verbose mode
-u  --uncompress:		Decompress a coda file
-c  --compress:			Compress files
-cl --compressionLevel:	Set the compression level. Default is 9. A value between 1-22.
-e  --encrypt			Also encrypt the data before compression.
	-k --key				Set the key for encyption.
-d --decrypt				Also decrypt the data.
	-k --key				Set the key for decyption.
-n --name				Set the name for the output file in compression. Useless for decompression.
";

/*
*	TODO:
*		Add support for just encryption rather than both encryption and compression.
*		Add support for random generation of a key if none is provided.
*		Add better desciptions in the help.
*		Add better handling of flags.
*		Optimise the code to run faster.
*		Add handling for ../../
*		Add more unittests
*/	

/*
*	Flags to see what to do.
*/
ubyte compressing = 0;
ubyte decompressing = 0;
ubyte verbose = 0;
ubyte compressionLevel = 9;
ubyte encryptF = 0;
ubyte decryptF = 0;	

/*
*	Return values based on errors.
*/
static enum : int
{
	ok = 0,
	argumentError = 1,
	failedToCompress = -1,
	failedToUncompress = -2,
	failedToRead = -3,
	failedToEncrypt = -4,
	failedToDecrypt = -5,
}

/*
*	First check if there are correct arguments.
*	Then, if compressing, slurp all the files inputted and put them into a json.
*	Then compress that data.
*	If encrypting, will encrypt after compressing.
*	If decompressing, do in the backwards order of compressing to get the data back.
*	Will then for each file, write them.
*/
int main(string[] argv)
{
	import std.datetime.stopwatch;
	import std.stdio : File;

	string[] files;
	string key;
	string outputFile = "out";
	bool skip = false;
	auto time = StopWatch(AutoStart.no);
	foreach (i; 1 .. argv.length)
	{
		if (!skip)
		{
			switch (argv[i])
			{
				case "-c": goto case;
				case "--compress":
					compressing = 1;
					break;
				case "-u": goto case;
				case "--uncompress":
					decompressing = 1;
					break;
				case "-e": goto case;
				case "--encrypt":
					encryptF = 1;
					break;
				case "-d": goto case;
				case "--decrypt":
					decryptF = 1;
					break;
				case "-k": goto case;
				case "--key":
					key = argv[i + 1];
					skip = true;
					break;
				case "-cl": goto case;
				case "--compressionLevel":
					try
						compressionLevel = to!ubyte(argv[i + 1]);
					catch(ConvException)
					{
						writeln("Error: " ~ to!(string)(argumentError) ~ " Invalid number!");
						return argumentError;
					}
					skip = true;
					break;
				case "-n": goto case;
				case "--name":
					outputFile = argv[i + 1];
					skip = true;
					break;
				case "-v": 
					verbose = 1;
					break;
				case "--version":
					writeln(VERSION);
					return 0;
				case "-help":
					writeln(HELP);
					return 0;
				default:
					if (exists(argv[i]) && (isFile(argv[i]) || isDir(argv[i])))
						files ~= argv[i];
					else
					{
						writeln("Unknown file or option " ~ argv[i]);
						return argumentError;
					}
			}
		}
		else
			skip = false;
	}
	if ((compressing == 1 && decompressing == 1) || (compressing == 0 && decompressing == 0) || (encryptF == 1 && decryptF == 1))
	{
		writeln("Error: " ~ to!(string)(argumentError) ~ " Not enough arguments! Do -help for help!");	
		return argumentError;
	}
	if (compressing == 1 && decryptF == 1)
	{
		writeln("Error: " ~ to!(string)(argumentError) ~ " Cannot decrypt data to be compressed! Do -help for help!");	
		return argumentError;
	}
	else if (decompressing == 1 && encryptF == 1)
	{
		writeln("Error: " ~ to!(string)(argumentError) ~ " Cannot encrypt data to be decompressed! Do -help for help!");	
		return argumentError;
	}
	time.start();
	if (compressing)
	{
		files = goThroughDirs(files);
		string[] data = slurpFiles(files);
		if (!data)
		{
			writeln("Was unable to get any data. Please input valid files.");
			return failedToRead;
		}
		long[] lengths;
		long ulength;
		string outData;
		foreach (i; 0 .. files.length)
		{
			ulength += data[i].length;
			lengths ~= data[i].length;
			outData ~= data[i];
		}
		outData = compressUncompressData(createHeader(lengths, files) ~ outData, compressionLevel, 0);
		if (!outData)
		{
				writeln("Was unable to compress data.");
				return failedToCompress;
		}
		long clength = outData.length;
		if (encryptF)
		{
			outData = encryptDecryptData(outData, key, 0);
			if (!outData)
			{
				writeln("Was unable to encrypt data.");
				return failedToEncrypt;
			}
		}
		if (canFind(outputFile, "."))
		{
			File outFile = File(outputFile, "wb");
			outFile.rawWrite(outData);
		}
		else
		{
			File outFile = File(outputFile ~ ".coda", "wb");
			outFile.rawWrite(outData);
		}
		if (verbose)
		{
			writeln("Original Length: ", ulength);
			writeln("Compressed Length: ", clength);
			writeln("Compression ratio: ", cast(float) ulength /  cast(float) clength);
			writeln("Took " ~ to!string(time.peek()) ~ " seconds to complete.");
		}
	} 
	else
	{
		string data = slurpFiles(files)[0];
		if (decryptF)
		{
			data = encryptDecryptData(data, key, 1);
			if (!data)
			{
				writeln("Failed to decrypt!");
				return failedToDecrypt;
			}
		}
		data = compressUncompressData(data, 0, 1);
		if (!data)
		{
			writeln("Failed to uncompress!");
			return failedToUncompress;
		}
		auto header = readHeader(data);
		long start = 0;
		data = data[indexOf(data, "\xb2\xfe\xfe") + 3 .. data.length];
		foreach (file; header)
		{
			if (canFind(file.name, "/"))
			{
				string[] dirs = file.name.split("/");
				dirs = dirs[0 .. dirs.length - 1];
				string current;
				foreach (i; 0 .. dirs.length)
				{
					current ~= dirs[i] ~ "/";
					if (!exists(current))
						mkdir(current);
				}
			}
			try
			{
				File openFile = File(file.name, "wb");
				openFile.rawWrite(data[start .. file.length + start]);
			}
			catch (ErrnoException e)
				writeln("Was unable to write to file " ~ file.name ~ " with error " ~ to!string(e)[0 .. to!string(e).indexOf('\n')]);
			start += file.length;
		}
		if (verbose)
			writeln("Took " ~ to!string(time.peek()) ~ " seconds to complete.");
	}
	return ok;
}
