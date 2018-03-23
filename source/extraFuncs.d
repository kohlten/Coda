import std.stdio : stderr, writeln;
import std.file;
import std.string : indexOf;
import std.conv;

/*
*	Simple exception class thrown for verbose data.
*/
class CompressionException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
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

	ubyte[] newData = cast(ubyte[]) data;
	auto state = globalState();
	Unique!AutoSeededRNG rng = new AutoSeededRNG;
	if (key.length == 0)
	{
		while (key.length < 50)
			key ~= (rng.nextByte() % 94) + 33;
		writeln("Your key is: " ~ key);
	}
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
		catch(DecodingError)
			encData = null;
	}
	
	return encData;
}

unittest
{
	writeln("Doing encryptDecryptData unittest");
	string data = "I love pepperoni pizza!";
	string key = "I hate pineapple";
	string encrypted = encryptDecryptData(data, key, 0);
	string decrypted = encryptDecryptData(encrypted, key, 1);
	assert(decrypted == data);
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

unittest
{
	writeln("Doing inArray unittest");
	string[] haystack = ["hello", "world", "i", "hate", "pineapple"];
	assert(inArray(haystack, "world", 0) > 0);
	assert(inArray(haystack, "pineapple", 5) > 0);
	assert(inArray(haystack, "apple", 0) == -1);
}

/*
*	Gets all the data from the list of files.
*	If unable to get any data from the files inputted,
*	will return null.
*/
string[] slurpFiles(const string[] files)
{
	string[] data;
	string slurped;
	int failedAmount;
	bool failed;

	if (files.length == 0)
		failed = true;
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
*	Compress or decompress all the data given to it.
*	If failed to compress, will throw ZstdException
*	and return null.
*/
string compressUncompressData(const string data, const ubyte compressionLevel, const ubyte type)
{
	import zstd : compress, uncompress, ZstdException;

	string resultData;

	if (type == 0)
	{
		try
			resultData = cast(string) compress(data, compressionLevel);
		catch(ZstdException)
			resultData = null;
	} 
	else
	{
		try
			resultData = cast(string) uncompress(data);
		catch(ZstdException)
			resultData = null;
	}
	return resultData;
}

unittest
{
	writeln("Doing compressUncompressData unittest");
	//Short string
	string data = "I like dogs!";

	string compressed = compressUncompressData(data, 22, 0);
	string uncompressed = compressUncompressData(compressed, 22, 1);
	assert(uncompressed == data);

	//Long string
	data = "";

	foreach(i; 0 .. 200)
		data ~= "The world is ending!\n";
	compressed = compressUncompressData(data, 22, 0);
	uncompressed = compressUncompressData(compressed, 22, 1);
	assert(uncompressed == data);
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
*	Simple exception class for invalid header
*/
class HeaderException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

/*
*	Create a header based off of all the lengths of the files and the names of the files
*	To create a lookup table for the file.
*	If ../ in the name, remove ../ until it can not be found in the string
*/
string createHeader(long[] lengths, string[] names)
{
	string header = "\xfe\xfe\xb2";

	if (lengths.length != names.length)
		throw new HeaderException("Names and lengths do not equal");
	foreach (i; 0 .. names.length)
	{
		while (names[i][0 .. 3] == "../")
			names[i] = names[i][3 .. names[i].length];
		header ~= names[i] ~ "\xb2" ~ to!string(lengths[i]) ~ "\xfe";
	}
	return (header ~ "\xb2\xfe\xfe");
}

unittest
{
	writeln("Doing header unittest");
	assert(createHeader([20, 20, 20, 20], ["../../../../../../hello.c", "../../../../../../hello.h", "../../../../../../goodbye.c", "../../../../../../goodbye.h"]) == 
		"\xfe\xfe\xb2hello.c\xb220\xfehello.h\xb220\xfegoodbye.c\xb220\xfegoodbye.h\xb220\xfe\xb2\xfe\xfe");
}

/*
*	Return the pieces of the string in the format:
*	name\xb2length
*/
string[] getNamesLengths(string data)
{
	string[] namesLengths;
	long start = 3;
	long end = indexOf(data, "\xb2\xfe\xfe");
	if (end < 3)
		throw new HeaderException("Header is too short!");
	foreach (long i; 3 .. end)
	{
		if (data[i] == '\xfe')
		{
			namesLengths ~= data[start .. i];
			start = i + 1;
		}
	}
	if (namesLengths.length == 0)
		throw new HeaderException("Invalid header data!");
	return namesLengths;
}

unittest
{
	writeln("Doing getNamesLengths unittest");
	assert(getNamesLengths("\xfe\xfe\xb2hello.c\xb220\xfehello.h\xb220\xfegoodbye.c\xb220\xfegoodbye.h\xb220\xfe\xb2\xfe\xfe") ==
		["hello.c\xb220", "hello.h\xb220", "goodbye.c\xb220", "goodbye.h\xb220"]);
}

struct FileInfo
{
	string name;
	long length;
}


/*
*	Check if header is valid first, then get the names and lengths
*	from the pieces from getNamesLengths.
*	If not valid, throw header Exception.
*/
FileInfo[] readHeader(string data)
{
	FileInfo[] outData;
	if (data[0 .. 3] != "\xfe\xfe\xb2")
		throw new HeaderException("Invalid header prefix!");
	long end = indexOf(data, "\xb2\xfe\xfe");
	if (end == -1)
		throw new HeaderException("Invalid header ending!");
	foreach (section; getNamesLengths(data))
	{
		long middle = indexOf(section, "\xb2");
		if (middle == -1)
			throw new HeaderException("Invalid header data!");
		string name = section[0 .. middle];
		long length = to!long(section[middle + 1 .. section.length]);
		outData ~= FileInfo(name, length);
	}
	return outData;
}

unittest
{
	writeln("Doing readHeader unittest");
	string header = createHeader([20, 20, 20, 20], ["hello.c", "hello.h", "goodbye.c", "goodbye.h"]);
	auto readHeader = readHeader(header);
	assert(readHeader == [FileInfo("hello.c", 20), FileInfo("hello.h", 20), FileInfo("goodbye.c", 20), FileInfo("goodbye.h", 20)]);
}

