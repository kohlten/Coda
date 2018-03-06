import std.stdio : stderr, writeln;
import std.file : write, exists, isFile, read;
import std.conv : to, ConvException;
import std.json : JSONValue, parseJSON;
import std.string : indexOf;

const string VERSION = "v0.0.1";
const string HELP =
"Coda Compression Program
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
-u  --uecompress:		Decompress a coda file
-c  --compress:			Compress files
-cl --compressionLevel:	Set the compression level. Default is 9. A value between 1-22.
-e  --encrypt			Also encrypt the data before compression.
	-k= --key=				Set the key for decyption. Must be less than 49. If not provided, a random one will be generated.
-d --decrypt				Also decrypt the data.
	-k= --key=				Set the key for decyption. Must be less than 49. If not provided, a random one will be generated.
-n= --name=				Set the name for the output file in compression. Useless for decompression.
";

/*
*	TODO:
*		Add support for just encryption rather than both encryption and compression.
*		Add support for random generation of a key if none is provided.
*		Add support for compressing files within a folder and/or recursivly while still keeping the data structure while compressing.
*		Add better desciptions in the help.
*/		

/*
*	Flags to see what to do.
*/
ubyte compress = 0;
ubyte decompress = 0;
ubyte verbose = 0;
ubyte compressionLevel = 9;
ubyte encryptF = 0;
ubyte decryptF = 0;

/*
*	Return values based on errors.
*/
static enum : int {
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
ubyte[] encryptDecryptData(const ubyte[] data, string key, const ubyte type)
{
	//import secured.aes : encrypt, decrypt;
	//import secured.util : CryptographicException;
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
	auto state = globalState();
	Unique!AutoSeededRNG rng = new AutoSeededRNG;
	ubyte[] encData;
	if (type == 0)
	{
		try
			encData = cast(ubyte[]) CryptoBox.encrypt(data.ptr, data.length, key, *rng);
		catch(DecodingError)
			encData = null;
	}
	else
	{
		try
			encData = cast(ubyte[]) CryptoBox.decrypt(data.ptr, data.length, key);
		catch(DecodingError)
			encData = null;
	}
	
	return encData;
}

/*
*	Gets all the data from the list of files.
*	If it is unable to convert or read the file,
*	Throws a FileError
*/
string[] slurpFiles(const string[] files) {
	string[] data;
	string	slurped;
	int failedAmount;
	bool failed = false;

	foreach (file; files) {
		if (exists(file) && isFile(file))
		{
			slurped = cast(string) read(file);
			if (slurped)
				data ~= slurped; 
			else
			{
				failed = true;
				break;
			}
		}
		else
		{
			failedAmount += 1;
			writeln("Was unable to slurp " ~ file ~ ".");
		}
		if (failedAmount == files.length) {
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
ubyte[] compressUncompressData(const ubyte[] data, const ubyte type)
{
	//import std.zlib : compress, uncompress, ZlibException;
	import zstd : compress, uncompress, ZstdException;

	ubyte[] resultData;
	if (verbose)
		writeln("Datalen:", data.length);

	if (type == 0)
	{
		try
			resultData = cast(ubyte[]) compress(cast(char[]) data, 9);
		catch (ZstdException)
		{
			throwError("Failed to compresss! Are you sure its not encrypted or corrupt?");
			resultData = null;
		}
	} 
	else
	{
		try
			resultData = cast(ubyte[]) uncompress(data);
		catch (ZstdException)
		{
			throwError("Failed to decompress! Are you sure its not encrypted or corrupt?");
			resultData = null;
		}
	}
	return resultData;
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
	foreach (i; 1 .. argv.length)
	{
		switch (argv[i])
		{
			case "-c":
				goto case;
			case "--compress":
				compress = 1;
				break;
			case "-e":
				goto case;
			case "--uncompress":
				decompress = 1;
				break;
			case "-e":
				goto case;
			case "--encrypt":
				encryptF = 1;
				break;
			case "-d":
				goto case;
			case "--decrypt":
				decryptF = 1;
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
				if (argv[i][0 .. 2] == "-k" || argv[i][0 .. 5] == "--key")
					key = argv[i][indexOf(argv[i], "=") + 1 .. argv[i].length];
				else if (argv[i][0 .. 18] == "--compressionLevel" || argv[i][0 .. 3] == "-cl")
				{
					try
						compressionLevel = to!ubyte(argv[i][indexOf(argv[i], "=") + 1 .. argv[i].length]);
					catch(ConvException)
					{
						throwError("Error: " ~ to!(string)(argumentError) ~ " Invalid number!");
						return argumentError;
					}
				}
				else if (argv[i][0 .. 2] == "-n" || argv[i][0 .. 6] == "-name")
					outputFile = argv[i][indexOf(argv[i], "=") + 1 .. argv[i].length];
				else if (exists(argv[i]) && isFile(argv[i]))
					files ~= argv[i];
				else
				{
					throwError("Unknown option " ~ argv[i]);
					return argumentError;
				}
		}
	}
	if ((compress == 1 && decompress == 1) || (compress == 0 && decompress == 0) || (encryptF == 1 && decryptF == 1))
	{
		throwError("Error: " ~ to!(string)(argumentError) ~ " Not enough arguments! Do -help for help!");	
		return argumentError;
	}
	if (compress == 1 && decryptF == 1)
	{
		throwError("Error: " ~ to!(string)(argumentError) ~ " Cannot decrypt data to be compressed! Do -help for help!");	
		return argumentError;
	}
	else if (decompress == 1 && encryptF == 1)
	{
		throwError("Error: " ~ to!(string)(argumentError) ~ " Cannot encrypt data to be decompressed! Do -help for help!");	
		return argumentError;
	}
	if (compress)
	{
		string[] data = slurpFiles(files);
		if (!data)
		{
			throwError("Was unable to get any data. Please input valid files.");
			return failedToRead;
		}
		JSONValue json = JSONValue(string[string].init);
		foreach (i; 0 .. files.length)
			json[files[i]] = data[i];
		string jsonStr = json.toPrettyString;
		ubyte[] compressed = compressUncompressData(cast(ubyte[]) jsonStr, 0);
		if (!compressed)
			return failedToCompress;
		if (encryptF)
		{
			compressed = encryptDecryptData(compressed, key, 0);
			if (!jsonStr)
			{
				throwError("Error: " ~ to!(string)(failedToEncrypt) ~ " Failed to encrypt data!");
				return failedToEncrypt;
			}
		}
		if (verbose)
		{
			writeln("Uncompressed length:", jsonStr.length);
			writeln("Compressed length:", compressed.length);
		}
		write(outputFile ~ ".coda", compressed);
	} 
	else
	{
		ubyte[] data = cast(ubyte[]) slurpFiles(files)[0];
		if (decryptF)
			data = encryptDecryptData(data, key, 1);
		string uncompressed = cast(string) compressUncompressData(data, 1);
		if (uncompressed.length == 0)
			return failedToUncompress;
		JSONValue json = parseJSON(uncompressed);
		foreach (string jsonkey, JSONValue value; json)
		{
			if (verbose)
				writeln("File " ~ jsonkey ~ " is decompressed!");
			write(jsonkey, value.str);
		}
	}
	return ok;
}
