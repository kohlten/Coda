import std.stdio : stderr, writeln;
import std.file : write, exists, isFile, read, isDir, dirEntries, SpanMode, mkdir;
import std.conv : to, ConvException;
import std.json : JSONValue, parseJSON;
import std.string : indexOf;
import std.algorithm : canFind;
import std.array : split;
import std.utf;

immutable string VERSION = "v0.0.3";
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
*		DONE: Add support for compressing files within a folder and/or recursivly while still keeping the data structure while compressing.
*		Add better desciptions in the help.
*		Seperate main into more functions.
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
*	Simple exception class thrown for verbose data.
*/
class CompressionException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

/*
*	If verbose, show stack data to see where the issue is.
*	Otherwise, output generic errors
*/
void throwError(const string errorMsg)
{
	if (verbose)
		throw new CompressionException(errorMsg);
	else 
	{
		stderr.writeln(errorMsg);
	}
}

/*
*	Encrypt or decrypt data based on a key.
*	If the key is not correct, will throw CryptographicException.
*/
string encryptDecryptData(const string data, string key, const ubyte type)
{
	import botan.libstate.global_state : globalState;
	import botan.constructs.cryptobox : CryptoBox;
	import botan.rng.rng : Unique;
	import botan.rng.auto_rng : AutoSeededRNG;
	import botan.utils.exceptn : DecodingError;

	if (key.length == 0)
	{
		throwError("Must include a key!");
		return null;
	}
	ubyte[] newData = cast(ubyte[]) data;
	auto state = globalState();
	Unique!AutoSeededRNG rng = new AutoSeededRNG;
	string encData;
	if (!type)
	{
		try
			encData = cast(string) CryptoBox.encrypt(newData.ptr, newData.length, key, *rng);
		catch(DecodingError)
			encData = null;
	}
	else
	{
		try
			encData = cast(string) CryptoBox.decrypt(newData.ptr, newData.length, key);
		catch(DecodingError e)
			encData = null;
	}
	
	return encData;
}

/*
*	Check if needle is in haystack starting from start.
*/
size_t inArray(string[] haystack, string needle, size_t start)
{
	foreach (i; start .. haystack.length)
	{
		if (haystack[i] == needle)
			return i;
	}
	return -1;
}

/*
*	Gets all the data from the list of files.
*	If it is unable to convert or read the file,
*	Throws a FileError
*/
string[] slurpFiles(const string[] files)
{
	string[] data;
	string slurped;
	int failedAmount;
	bool failed = false;

	foreach (file; files)
	{
		if (exists(file) && isFile(file))
		{
			slurped = cast(string) read(file);
			if (slurped)
				data ~= slurped; 
			else
			{
				writeln("Was unable to slurp " ~ file ~ ".");
				failedAmount += 1;
				continue;
			}
		}
		else
		{
			failedAmount += 1;
			writeln("Was unable to slurp " ~ file ~ ".");
		}
		if (failedAmount == files.length)
		{
			failed = true;
			break;
		}
	}
	if (failed)
		data = null;
	return data;
}

/*
*	Compress or decompress all the data given to it by
*	chunking it into an acceptable buffer size.
*/
string compressUncompressData(const string data, const ubyte type)
{
	import zstd : compress, uncompress, ZstdException;

	string resultData;

	if (type == 0)
	{
		try
			resultData = cast(string) compress(data, 9);
		catch (ZstdException)
		{
			throwError("Failed to compresss! Are you sure its not encrypted or corrupt?");
			resultData = null;
		}
	} 
	else
	{
		try
			resultData = cast(string) uncompress(data);
		catch (ZstdException)
		{
			throwError("Failed to decompress! Are you sure its not encrypted or corrupt?");
			resultData = null;
		}
	}
	if (verbose)
	{
		if (compressing)
		{
			writeln("Original Length: ", data.length);
			writeln("Compressed Length: ", resultData.length);
			writeln("Compression ratio: ", cast(float) data.length /  cast(float) resultData.length);
		}
		else
		{
			writeln("Original Length: ", resultData.length);
			writeln("Compressed Length: ", data.length);
			writeln("Compression ratio: ", cast(float) resultData.length / cast(float) data.length);
		}
	}
	return resultData;
}

/*
*	Find all files from the root directory by checking whether its a directory or a file first.
*	If its a directory, enter it and find everything within that folder.
*	If its a file, add it to output.
*	Once it is done iterating for all the files,
*	returns the files with their path from the root dir.
*/
string[] goThroughDirs(string[] files)
{
	string[] output;
	foreach (i; 0 .. files.length)
	{
		if (isDir(files[i]))
		{
			foreach (file; dirEntries(files[i], SpanMode.depth))
			{
				if (isFile(file))
					output ~= file;
				else
					files ~= file;
			}
		}
		else if (isFile(files[i]))
			output ~= files[i];
	}
	return output;
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
	string[] files;
	string key;
	string outputFile = "out";
	bool skip = false;
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
						throwError("Error: " ~ to!(string)(argumentError) ~ " Invalid number!");
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
						throwError("Unknown option " ~ argv[i]);
						return argumentError;
					}
			}
		}
		else
			skip = false;
	}
	if ((compressing == 1 && decompressing == 1) || (compressing == 0 && decompressing == 0) || (encryptF == 1 && decryptF == 1))
	{
		throwError("Error: " ~ to!(string)(argumentError) ~ " Not enough arguments! Do -help for help!");	
		return argumentError;
	}
	if (compressing == 1 && decryptF == 1)
	{
		throwError("Error: " ~ to!(string)(argumentError) ~ " Cannot decrypt data to be compressed! Do -help for help!");	
		return argumentError;
	}
	else if (decompressing == 1 && encryptF == 1)
	{
		throwError("Error: " ~ to!(string)(argumentError) ~ " Cannot encrypt data to be decompressed! Do -help for help!");	
		return argumentError;
	}
	if (compressing)
	{
		files = goThroughDirs(files);
		string[] data = slurpFiles(files);
		if (!data)
		{
			throwError("Was unable to get any data. Please input valid files.");
			return failedToRead;
		}
		JSONValue json = JSONValue(string[string].init);
		foreach (i; 0 .. files.length)
		{
			try
			{
				data[i] = toUTF8(data[i]);
				validate(data[i]);
			}
			catch (UTFException)
			{
				writeln("WARNING: File " ~ files[i] ~ " is invalid!");
				continue;
			}
			if (verbose)
				writeln(files[i] ~ " is compressed!");
			json[files[i]] = data[i];
		}
		string prettyString = json.toPrettyString;
		if (encryptF)
			prettyString = encryptDecryptData(prettyString, key, 0);
		string compressed = compressUncompressData(prettyString, 0);
		if (canFind(".", outputFile))
			write(outputFile, compressed);
		else
			write(outputFile ~ ".coda", compressed);
	} 
	else
	{
		string data = slurpFiles(files)[0];
		data = compressUncompressData(data, 1);
		if (decryptF)
			data = encryptDecryptData(data, key, 1);
		if (!data)
		{
			throwError("Failed to uncompress!");
			return failedToUncompress;
		}
		auto json = parseJSON(data);
		foreach (string jsonkey, JSONValue value; json)
		{
			if (canFind(jsonkey, "/"))
			{
				string[] dirs = jsonkey.split("/");
				dirs = dirs[0 .. dirs.length - 1];
				string current;
				foreach (i; 0 .. dirs.length)
				{
					current ~= dirs[i] ~ "/";
					if (!exists(current))
						mkdir(current);
				}
			}
			if (verbose)
				writeln(jsonkey);
			write(jsonkey, value.str);
		}
}
	return ok;
}
