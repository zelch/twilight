
#include <stdio.h>

#if 0
// This function extracts HAPI (total anihilation archive) variant of LZSS
// (note: this format is incredibly evil and backwards while still managing
// to achieve almost identical compression rates to LZSS)
int hapi_lzss_decompressbuffer(const unsigned char *in, const unsigned char *inend, unsigned char *out, unsigned char *outend)
{
	int i, commandbyte, code, historypos = 1;
	const unsigned char *copy;
	unsigned char *outcopyend, *outstart = out;
	unsigned char history[4096];
	// input file should not end with a command byte so make sure there are
	// at least two remaining bytes
	for (;;)
	{
		if (in == inend)
			return -1;
		commandbyte = *in++;
		for (i = 1;i <= 0x80;i <<= 1)
		{
			if (in == inend)
				return 1; // corrupt
			if (commandbyte & i)
			{
				code = *in++;
				if (in == inend)
					return 1; // corrupt
				code += (*in++) * 0x100;
				outcopyend = out + (code & 15) + 2;
				// EVIL!
				copypos = (code >> 4) & 0xFFF;
				// yes it can't reference to byte 0 of the window
				if (copypos == 0)
				{
					// termination symbol
					if (in == inend && out == outend)
						return 0; // successfully decoded
					else
						return 1; // corrupt (encountered termination symbol too early)
				}
				if (outcopyend > outend)
					return 1; // corrupt
				while (out < outcopyend)
					history[(historypos++) & 0xFFF] = *out++ = history[(copypos++) & 0xFFF];
			}
			else
			{
				if (out == outend)
					return 1; // corrupt
				history[(historypos++) & 0xFFF] = *out++ = *in++;
			}
		}
	}
	return 1; // never reached
}
#endif

#if 0
// This function extracts quickly, sacrificing overrun detection (it still
// knows if there was an error, but it may have read or written too much)
int lzss_decompressbuffer_fastandunsafe(const unsigned char *in, const unsigned char *inend, unsigned char *out, unsigned char *outend)
{
	int i, commandbyte, code;
	const unsigned char *copy;
	unsigned char *outcopyend;
	while (in < inend)
	{
		for (i = 0x80, commandbyte = *in++;i && in < inend;i >>= 1)
		{
			if (commandbyte & i)
			{
				for (code = (*in++) * 0x100, code += *in++, outcopyend = out + ((code >> 12) & 15) + 3, copy = out - ((code & 0xFFF) + 1), in++;out < outcopyend;)
					*out++ = *copy++;
			}
			else
				*out++ = *in++;
		}
	}
	return in != inend || out != outend; // corrupt if non-zero
}
#endif

// This function tries to extract quickly but safety comes first
int lzss_decompressbuffer(const unsigned char *in, const unsigned char *inend, unsigned char *out, unsigned char *outend)
{
	int i, commandbyte, code;
	const unsigned char *copy;
	unsigned char *outcopyend, *outstart = out;
	// input file should not end with a command byte so make sure there are
	// at least two remaining bytes
	while (in + 2 <= inend && out < outend)
	{
		commandbyte = *in++;
		for (i = 0x80;i && in < inend && out < outend;i >>= 1)
		{
			if (commandbyte & i)
			{
				code = (*in++) * 0x100;
				if (in == inend)
					return 1; // corrupt
				code += *in++;
				outcopyend = out + ((code >> 12) & 15) + 3;
				copy = out - ((code & 0xFFF) + 1);
				if (out < outstart || outcopyend > outend)
					return 1; // corrupt
				while (out < outcopyend)
					*out++ = *copy++;
			}
			else
				*out++ = *in++;
		}
	}
	return in != inend || out != outend; // corrupt if non-zero
}

#include <stdlib.h>

unsigned char *lzss_decompressfilebuffer_malloc(const unsigned char *in, size_t infilesize, size_t *outdatasizepointer)
{
	unsigned char *out;
	size_t uncompresseddatasize, compresseddatasize;
	if (infilesize >= 12 && in[0] == 'L' && in[1] == 'Z' && in[2] == 'S' && in[3] == 'S')
	{
		uncompresseddatasize = in[4] * 16777216 + in[5] * 65536 + in[6] * 256 + in[7];
		compresseddatasize = in[8] * 16777216 + in[9] * 65536 + in[10] * 256 + in[11];
		if (compresseddatasize + 12 <= infilesize && (out = malloc(uncompresseddatasize)))
		{
			if (!lzss_decompressbuffer(in + 12, in + 12 + compresseddatasize, out, out + uncompresseddatasize))
			{
				if (outdatasizepointer)
					*outdatasizepointer = uncompresseddatasize;
				return out;
			}
			free(out);
		}
	}
	return NULL;
}

int main(int argc, char **argv)
{
	int ret;
	size_t i, infilesize, outfilesize;
	unsigned char *indata, *outdata;
	FILE *infile, *outfile;
	ret = -1;
	if (argc == 3)
	{
		if ((infile = fopen(argv[1], "rb")))
		{
			fseek(infile, 0, SEEK_END);
			infilesize = ftell(infile);
			fseek(infile, 0, SEEK_SET);
			if ((indata = malloc(infilesize)))
			{
				if (fread(indata, 1, infilesize, infile) == infilesize)
				{
					if ((outdata = lzss_decompressfilebuffer_malloc(indata, infilesize, &outfilesize)))
					{
						outfile = fopen(argv[2], "wb");
						if (outfile)
						{
							if ((i = fwrite(outdata, 1, outfilesize, outfile) == outfilesize))
								ret = 0;
							else
								fprintf(stderr, "error writing output file (fwrite returned %i for a %i byte write)\n", i, outfilesize);
							fclose(outfile);
						}
						else
							fprintf(stderr, "unable to open output file \"%s\"\n", argv[2]);
						free(outdata);
					}
					else
						fprintf(stderr, "error decompressing file \"%s\" (corrupt or failed to allocate memory)\n", argv[1]);
				}
				else
					fprintf(stderr, "error reading input file (fread returned %i for a %i byte read)\n", i, infilesize);
				free(indata);
			}
			else
				fprintf(stderr, "unable to allocate memory for input data (%i bytes)\n", infilesize);
			fclose(infile);
		}
		else
			fprintf(stderr, "unable to open input file \"%s\"\n", argv[1]);
	}
	return ret;
}

