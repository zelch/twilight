
#include <stdio.h>

// REFERENCEWINDOWSIZE must be >= REFERENCEMAXDIST+REFERENCEMAXSIZE*PACKETMAXSYMBOLS
// and should be a power of 2 for optimal performance with the numerous
// % operators (which become optimized to & (WINDOWSIZE - 1))
#define WINDOWSIZE 8192
#define REFERENCEMAXDIST 4096
#define REFERENCEMAXSIZE 18
#define PACKETMAXSYMBOLS 8
#define REFERENCEHASHBITS 12
#define REFERENCEHASHSIZE (1 << REFERENCEHASHBITS)
#define REFERENCEWINDOWSIZE (16384)

/*
typedef struct lzss_compress_hashitem_s
{
	lzss_compress_hashitem_s *next, *prev;
	int windowindex;
}
lzss_compress_hashitem_t;

typedef struct lzss_compress_state_s
{
	// current bit to conditionally set in the packet command byte
	int packetbit;
	// number of bytes in the packetbytes buffer currently (always at least 1)
	int packetsize;
	// byte 0 is the packet command byte, the remaining bytes are symbols
	unsigned char packetbytes[1+PACKETMAXSYMBOLS*2];

	// how many bytes are waiting to be written
	int outbuffersize;
	// output buffer
	unsigned char outbufferbytes[REFERENCEWINDOWSIZE];

	// initially 0, grows each time a byte is added, up to limit of REFERENCEWINDOWSIZE
	int windowsize;
	// initially 0, moves forward once window fills up
	int windowstart;
	// initially 0, moves forward up to REFERENCEMAXDIST bytes from windowstart
	int windowposition;
	// input buffer
	unsigned char windowbytes[REFERENCEWINDOWSIZE];

	// index into hashitems array, slides with window
	int hashposition;
	// hash table for quicker searches
	lzss_compress_hashitem_t hash[REFERENCEHASHSIZE];
	// hash item structures
	lzss_compress_hashitem_t hashitems[REFERENCEMAXDIST];
}
lzss_compress_state_t;
*/

unsigned int lzss_compressbuffertobuffer(const unsigned char *in, const unsigned char *inend, unsigned char *out, unsigned char *outend)
{
	int windowposition = 0;
	int windowstart = 0;
	int windowend = 0;
	int w;
	int l;
	int bestl;
	int bestcode;
	int packetbit;
	int packetsize;
	unsigned char *outstart;
	unsigned char packetbytes[1+PACKETMAXSYMBOLS*2];
	unsigned char window[REFERENCEWINDOWSIZE];
	outstart = out;
	for (;;)
	{
		// if window buffer has completely wrapped we can nudge it back
		if (windowstart >= REFERENCEWINDOWSIZE)
		{
			windowstart -= REFERENCEWINDOWSIZE;
			windowposition -= REFERENCEWINDOWSIZE;
			windowend -= REFERENCEWINDOWSIZE;
		}
		// if window buffer is running low, refill it to max
		if (windowend - windowposition < REFERENCEMAXSIZE * PACKETMAXSYMBOLS)
		{
			if (in < inend)
			{
				while (windowend - windowstart < REFERENCEWINDOWSIZE && in < inend)
					window[(windowend++) % REFERENCEWINDOWSIZE] = *in++;
			}
			else if (windowposition == windowend)
				break;
		}
		packetbit = 0x80;
		packetbytes[0] = 0;
		packetsize = 1;
		while (windowposition < windowend && packetbit)
		{
			while (windowposition - windowstart >= REFERENCEMAXSIZE)
			{
				// remove a hash entry which is too old
				windowstart++;
			}
			// find matching strings
			bestl = 1;
			for (w = windowstart;w < windowposition;w++)
			{
				// find how long a string match this is
				if (w + 3 <= windowend
				 && window[(w + 0) % REFERENCEWINDOWSIZE] == window[(windowposition + 0) % REFERENCEWINDOWSIZE]
				 && window[(w + 1) % REFERENCEWINDOWSIZE] == window[(windowposition + 1) % REFERENCEWINDOWSIZE]
				 && window[(w + 2) % REFERENCEWINDOWSIZE] == window[(windowposition + 2) % REFERENCEWINDOWSIZE])
				{
					for (l = 3;l < REFERENCEMAXSIZE && w + l < windowend && window[(w + l) % REFERENCEWINDOWSIZE] == window[(windowposition + l) % REFERENCEWINDOWSIZE];l++);
					// note that later matches of the same length (shorter
					// reference distance) are preferred by this
					if (bestl <= l)
					{
						bestl = l;
						bestcode = ((bestl - 3) << 12) | (windowposition - w - 1);
						// extra speed gain if a full match is found
						if (bestl >= REFERENCEMAXSIZE)
							break;
					}
				}
			}
			if (bestl >= 3)
			{
				packetbytes[0] |= packetbit;
				packetbytes[packetsize++] = (unsigned char)(bestcode >> 8);
				packetbytes[packetsize++] = (unsigned char)bestcode;
			}
			else
				packetbytes[packetsize++] = window[windowposition % REFERENCEWINDOWSIZE];
			packetbit >>= 1;
			while (bestl--)
			{
				// unlink old hash entry
				// link new hash entry
				windowposition++;
			}
		}
		if (out + packetsize > outend)
			return 0;
		for (l = 0;l < packetsize;l++)
			*out++ = packetbytes[l];
	}
	return out - outstart;
}

unsigned int lzss_compressbuffertofilebuffer(const unsigned char *indata, size_t insize, unsigned char *outfiledata, size_t outfilesize)
{
	int outdatasize;
	if ((outdatasize = lzss_compressbuffertobuffer(indata, indata + insize, outfiledata + 12, outfiledata + outfilesize)))
	{
		outfiledata[0] = 'L';
		outfiledata[1] = 'Z';
		outfiledata[2] = 'S';
		outfiledata[3] = 'S';
		outfiledata[4] = (unsigned char)(insize >> 24);
		outfiledata[5] = (unsigned char)(insize >> 16);
		outfiledata[6] = (unsigned char)(insize >>  8);
		outfiledata[7] = (unsigned char)(insize >>  0);
		outfiledata[8] = (unsigned char)(outdatasize >> 24);
		outfiledata[9] = (unsigned char)(outdatasize >> 16);
		outfiledata[10] = (unsigned char)(outdatasize >>  8);
		outfiledata[11] = (unsigned char)(outdatasize >>  0);
		return outdatasize + 12;
	}
	return 0;
}

#include "stdlib.h"

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
			if (infilesize >= 14)
			{
				// abort compression if it matches or exceeds the original file's size
				outfilesize = infilesize - 1;
				if ((indata = malloc(infilesize)))
				{
					if ((outdata = malloc(outfilesize)))
					{
						if (fread(indata, 1, infilesize, infile) == infilesize)
						{
							if ((outfilesize = lzss_compressbuffertofilebuffer(indata, infilesize, outdata, outfilesize)))
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
							}
							else
								fprintf(stderr, "compressing failed on file \"%s\" - the result is not smaller\n", argv[1]);
						}
						else
							fprintf(stderr, "error reading input file (fread returned %i for a %i byte read)\n", i, infilesize);
						free(outdata);
					}
					else
						fprintf(stderr, "unable to allocate memory for output data (%i bytes)\n", outfilesize);
					free(indata);
				}
				else
					fprintf(stderr, "unable to allocate memory for input data (%i bytes)\n", infilesize);
			}
			fclose(infile);
		}
		else
			fprintf(stderr, "unable to open input file \"%s\"\n", argv[1]);
	}
	return ret;
}

