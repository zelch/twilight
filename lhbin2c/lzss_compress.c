
#include <stdio.h>

#define REFERENCEMAXDIST 4096
#define REFERENCEMAXSIZE 18
#define PACKETMAXSYMBOLS 8
// this only needs 17 bytes (1+symbols*2) but is padded to a multiple of 8
#define PACKETMAXBYTES 24 
#define REFERENCEHASHBITS 12
#define REFERENCEHASHSIZE (1 << REFERENCEHASHBITS)
#define MINWINDOWBUFFERSIZE (REFERENCEMAXDIST+REFERENCEMAXSIZE*PACKETMAXSYMBOLS)
// WINDOWBUFFERSIZE must be >= REFERENCEMAXDIST+REFERENCEMAXSIZE*PACKETMAXSYMBOLS
#define WINDOWBUFFERSIZE (REFERENCEMAXDIST*2)

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
	unsigned char outbufferbytes[WINDOWBUFFERSIZE];

	// initially 0, grows each time a byte is added, up to limit of WINDOWBUFFERSIZE
	int WINDOWBUFFERSIZE;
	// initially 0, moves forward once window fills up
	int windowstart;
	// initially 0, moves forward up to REFERENCEMAXDIST bytes from windowstart
	int windowposition;
	// input buffer
	unsigned char windowbytes[WINDOWBUFFERSIZE];

	// index into hashitems array, slides with window
	int hashposition;
	// hash table for quicker searches
	lzss_compress_hashitem_t hash[REFERENCEHASHSIZE];
	// hash item structures
	lzss_compress_hashitem_t hashitems[REFERENCEMAXDIST];
}
lzss_compress_state_t;
*/

#if 0
// works
unsigned int lzss_compressbuffertobuffer(const unsigned char *in, const unsigned char *inend, unsigned char *out, unsigned char *outend)
{
	int windowposition = 0;
	int windowstart = 0;
	int windowend = inend - in;
	int w;
	int l;
	int maxl;
	int c, c1, c2;
	int bestl;
	int bestcode;
	int packetbit;
	int packetsize;
	const unsigned char *search, *inpos;
	unsigned char *outstart;
	unsigned char packetbytes[PACKETMAXBYTES];
	outstart = out;
	while (windowposition < windowend)
	{
		for (packetbit = 0x80, packetbytes[0] = 0, packetsize = 1;windowposition < windowend && packetbit;packetbit >>= 1)
		{
			if (windowstart < windowposition - REFERENCEMAXDIST)
				windowstart = windowposition - REFERENCEMAXDIST;
			// find matching strings
			bestl = 1;
			maxl = windowend - windowposition;
			if (maxl > REFERENCEMAXSIZE)
				maxl = REFERENCEMAXSIZE;
			inpos = in + windowposition;
			c = inpos[0];
			if (maxl >= 3)
			{
				c1 = inpos[1];
				c2 = inpos[2];
				for (w = windowposition-1;w >= windowstart;w--)
				{
					// find how long a string match this is
					search = in + w;
					if (search[0] == c && search[1] == c1 && search[2] == c2)
					{
						for (l = 3;l < maxl && search[l] == inpos[l];l++);
						// this prefers the closest match of the longest length
						if (bestl < l)
						{
							bestl = l;
							bestcode = ((bestl - 3) << 12) | (windowposition - w - 1);
							// extra speed gain if a full match is found
							if (bestl >= maxl)
								break;
						}
					}
				}
			}
			if (bestl >= 3)
			{
				packetbytes[0] |= packetbit;
				packetbytes[packetsize++] = (unsigned char)(bestcode >> 8);
				packetbytes[packetsize++] = (unsigned char)bestcode;
				windowposition += bestl;
			}
			else
				packetbytes[packetsize++] = in[windowposition++];
		}
		if (out + packetsize > outend)
			return 0;
		for (l = 0;l < packetsize;l++)
			*out++ = packetbytes[l];
	}
	return out - outstart;
}
#elif 0
//broken, needs more debugging
unsigned int lzss_compressbuffertobuffer(const unsigned char *in, const unsigned char *inend, unsigned char *out, unsigned char *outend)
{
	int windowposition = 0;
	int windowstart = 0;
	int windowend = 0;
	int w;
	int l;
	int maxl;
	int c, c1, c2;
	int bestl;
	int bestcode;
	int packetbit;
	int packetsize;
	unsigned char *outstart;
	unsigned char packetbytes[PACKETMAXBYTES];
	unsigned char window[WINDOWBUFFERSIZE];
	outstart = out;
	for (;;)
	{
		// if window buffer has completely wrapped we can nudge it back
		if (windowstart >= WINDOWBUFFERSIZE)
		{
			windowstart -= WINDOWBUFFERSIZE;
			windowposition -= WINDOWBUFFERSIZE;
			windowend -= WINDOWBUFFERSIZE;
		}
		// if window buffer is running low, refill it to max
		if (windowend - windowposition < REFERENCEMAXSIZE * PACKETMAXSYMBOLS)
		{
			if (in < inend)
			{
				while (windowend - windowstart < WINDOWBUFFERSIZE && in < inend)
					window[(windowend++) % WINDOWBUFFERSIZE] = *in++;
			}
			else if (windowposition == windowend)
				break;
		}
		for (packetbit = 0x80, packetbytes[0] = 0, packetsize = 1;windowposition < windowend && packetbit;packetbit >>= 1)
		{
			while (windowstart < windowposition - REFERENCEMAXDIST)
			{
				// remove a hash entry which is too old
				windowstart++;
			}
			// find matching strings
			maxl = windowend - windowposition;
			if (maxl > REFERENCEMAXSIZE)
				maxl = REFERENCEMAXSIZE;
			bestl = 1;
			c = window[(windowposition + 0) % WINDOWBUFFERSIZE];
			if (maxl >= 3)
			{
				c1 = window[(windowposition + 1) % WINDOWBUFFERSIZE];
				c2 = window[(windowposition + 2) % WINDOWBUFFERSIZE];
				for (w = windowposition-1;w >= windowstart;w--)
				{
					// find how long a string match this is
					if (w + 3 <= windowend
					 && window[(w + 0) % WINDOWBUFFERSIZE] == c
					 && window[(w + 1) % WINDOWBUFFERSIZE] == c1
					 && window[(w + 2) % WINDOWBUFFERSIZE] == c2)
					{
						for (l = 3;l < maxl && window[(w + l) % WINDOWBUFFERSIZE] == window[(windowposition + l) % WINDOWBUFFERSIZE];l++);
						// this prefers the closest match of the longest length
						if (bestl <= l)
						{
							bestl = l;
							bestcode = ((bestl - 3) << 12) | (windowposition - w - 1);
							// extra speed gain if a full match is found
							if (bestl >= maxl)
								break;
						}
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
				packetbytes[packetsize++] = c;
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
#elif 0
typedef struct lzss_state_s
{
	int packetbit;
	int packetsize;
	int windowstart, windowposition, windowend;
	unsigned char window[WINDOWBUFFERSIZE*2];
	unsigned char packetbytes[PACKETMAXBYTES];
}
lzss_state_t;

void lzss_state_packetreset(lzss_state_t *state)
{
	state->packetbit = 0x80; // current bit to set if encoding a reference
	state->packetsize = 1; // size of packet
	state->packetbytes[0] = 0; // command byte indicating contents of packet
}

void lzss_state_start(lzss_state_t *state)
{
	lzss_state_packetreset(state);
	state->windowstart = 0; // start of search window
	state->windowposition = 0; // current position in search window
	state->windowend = 0; // end of search window
}

// returns number of bytes needed to fill the buffer
unsigned int lzss_state_wantbytes(lzss_state_t *state)
{
	return WINDOWBUFFERSIZE - (state->windowend - state->windowstart);
}

// appends supplied bytes to buffer
// do not feed more bytes than lzss_state_wantbytes returned! (less is fine)
void lzss_state_feedbytes(lzss_state_t *state, const unsigned char *in, unsigned int inlength)
{
	if ((int)inlength > WINDOWBUFFERSIZE - (state->windowend - state->windowstart))
		return; // error!
	while (inlength--)
	{
		if (state->windowstart >= WINDOWBUFFERSIZE)
		{
			state->windowstart -= WINDOWBUFFERSIZE;
			state->windowposition -= WINDOWBUFFERSIZE;
			state->windowend -= WINDOWBUFFERSIZE;
		}
		// poke byte into two positions because when we wrap the buffer later we
		// want the data to already be there
		state->window[state->windowend] = *in;
		if (state->windowend >= WINDOWBUFFERSIZE)
			state->window[state->windowend - WINDOWBUFFERSIZE] = *in;
		in++;
		state->windowend++;
	}
}

// compress some data if the buffer is sufficiently full or flush is true
void lzss_state_compress(lzss_state_t *state, int flush)
{
	int w, l, maxl, bestl, bestcode;
	unsigned char c, c1, c2;
	while (state->packetbit && (maxl = (state->windowend - state->windowposition)) >= (flush ? 1 : REFERENCEMAXSIZE))
	{
		if (maxl > REFERENCEMAXSIZE)
			maxl = REFERENCEMAXSIZE;
		c = state->window[state->windowposition];
		bestl = 1;
		if (maxl >= 3 && state->windowposition)
		{
			c1 = state->window[state->windowposition+1];
			c2 = state->window[state->windowposition+2];
			w = state->windowposition-1;
			for (;;)	
			{
				if (state->window[w] == c && state->window[w+1] == c1 && state->window[w+2] == c2)
				{
					for (l = 3;l < maxl && state->window[w+l] == state->window[state->windowposition+l];l++);
					if (bestl < l)
					{
						bestl = l;
						bestcode = ((bestl - 3) << 12) | (state->windowposition - w - 1);
						if (bestl == maxl)
							break;
					}
				}
				if (w == state->windowstart)
					break;
				w--;
			}
		}
		if (bestl >= 3)
		{
			state->packetbytes[0] |= state->packetbit;
			state->packetbytes[state->packetsize++] = (unsigned char)(bestcode >> 8);
			state->packetbytes[state->packetsize++] = (unsigned char)bestcode;
		}
		else
			state->packetbytes[state->packetsize++] = c;
		state->packetbit >>= 1;
		state->windowposition += bestl;
		while (state->windowstart < state->windowposition - REFERENCEMAXDIST)
			state->windowstart++;
	}
}

unsigned int lzss_state_packetfull(lzss_state_t *state)
{
	return !state->packetbit; 
}

unsigned int lzss_state_getpacketsize(lzss_state_t *state)
{
	return state->packetsize >= 2 ? state->packetsize : 0;
}

void lzss_state_getpacketbytes(lzss_state_t *state, unsigned char *out)
{
	int i;
	// copy the bytes to output
	for (i = 0;i < state->packetsize;i++)
		out[i] = state->packetbytes[i];
	// reset the packet
	lzss_state_packetreset(state);
}

unsigned int lzss_compressbuffertobuffer(const unsigned char *in, const unsigned char *inend, unsigned char *out, unsigned char *outend)
{
	unsigned char *outstart = out;
	unsigned int b;
	lzss_state_t state;

	lzss_state_start(&state);

	// this code is a little complex because it implements the flush stage as
	// just a few checks (otherwise it would take two copies of this code)

	// while the buffer is not empty, or there is more input
	while (state.windowposition != state.windowend || in != inend)
	{
		// keep compressing until it stops making new packets
		// (this means the buffer is not full enough anymore)
		// in == inend is setting the flush flag, which will finish the file,
		// and a packet is written if the packet is full or flush is true
		lzss_state_compress(&state, in == inend);
		b = lzss_state_getpacketsize(&state);
		if (in == inend ? b : lzss_state_packetfull(&state))
		{
			// write a packet
			if (out + b > outend)
				return 0; // error: made file bigger
			lzss_state_getpacketbytes(&state, out);
			out += b;
		}
		else
		{
			// fill up buffer if needed
			if (in < inend && (b = lzss_state_wantbytes(&state)))
			{
				if (b > (unsigned int)(inend - in))
					b = (unsigned int)(inend - in);
				lzss_state_feedbytes(&state, in, b);
				in += b;
			}
		}
	}
	return out - outstart;
}
#else
#define WINDOWBUFFERSIZE2 (WINDOWBUFFERSIZE*2)
#define HASHSIZE (4096)
typedef struct lzss_state_s
{
	int hashindex[HASHSIZE]; // contains hash indexes
	int hashnext[WINDOWBUFFERSIZE2]; // contains hash indexes
	int packetbit;
	int packetsize;
	int windowstart, windowposition, windowend;
	unsigned char packetbytes[PACKETMAXBYTES];
	unsigned char window[WINDOWBUFFERSIZE2];
}
lzss_state_t;

void lzss_state_packetreset(lzss_state_t *state)
{
	state->packetbit = 0x80; // current bit to set if encoding a reference
	state->packetsize = 1; // size of packet
	state->packetbytes[0] = 0; // command byte indicating contents of packet
}

void lzss_state_start(lzss_state_t *state)
{
	int i;
	lzss_state_packetreset(state);
	state->windowstart = 0; // start of search window
	state->windowposition = 0; // current position in search window
	state->windowend = 0; // end of search window
	for (i = 0;i < HASHSIZE;i++)
		state->hashindex[i] = -1;
}

// returns number of bytes needed to fill the buffer
unsigned int lzss_state_wantbytes(lzss_state_t *state)
{
	return WINDOWBUFFERSIZE - (state->windowend - state->windowstart);
}

// appends supplied bytes to buffer
// do not feed more bytes than lzss_state_wantbytes returned! (less is fine)
void lzss_state_feedbytes(lzss_state_t *state, const unsigned char *in, unsigned int inlength)
{
	int i, pos;
	if ((int)inlength > WINDOWBUFFERSIZE - (state->windowend - state->windowstart))
		return; // error!
	while (inlength--)
	{
		if (state->windowstart >= WINDOWBUFFERSIZE)
		{
			for (i = 0;i < HASHSIZE;i++)
			{
				if (state->hashindex[i] >= state->windowstart)
				{
					state->hashindex[i] -= WINDOWBUFFERSIZE;
					pos = state->hashindex[i];
					state->hashnext[pos] = state->hashnext[pos + WINDOWBUFFERSIZE];
					while (state->hashnext[pos] >= state->windowstart)
					{
						state->hashnext[pos] -= WINDOWBUFFERSIZE;
						pos = state->hashnext[pos];
						state->hashnext[pos] = state->hashnext[pos + WINDOWBUFFERSIZE];
					}
					state->hashnext[pos] = -1;
				}
				else
					state->hashindex[i] = -1;
			}
			for (i = state->windowstart;i < state->windowend;i++)
				state->window[i - WINDOWBUFFERSIZE] = state->window[i];
			state->windowstart -= WINDOWBUFFERSIZE;
			state->windowposition -= WINDOWBUFFERSIZE;
			state->windowend -= WINDOWBUFFERSIZE;
		}
		state->window[state->windowend] = *in;
		state->windowend++;
		in++;
	}
}

// compress some data if the buffer is sufficiently full or flush is true
void lzss_state_compress(lzss_state_t *state, int flush)
{
	int w, l, maxl, bestl, bestcode, hash;
	unsigned char c, c1, c2;
	while (state->packetbit && (maxl = (state->windowend - state->windowposition)) >= (flush ? 1 : REFERENCEMAXSIZE))
	{
		if (maxl > REFERENCEMAXSIZE)
			maxl = REFERENCEMAXSIZE;
		c = state->window[state->windowposition];
		bestl = 1;
		if (maxl >= 3 && state->windowposition > state->windowstart)
		{
			c1 = state->window[state->windowposition+1];
			c2 = state->window[state->windowposition+2];
			for (w = state->hashindex[(c + c1 * 16 + c2 * 256) % HASHSIZE];w >= state->windowstart;w = state->hashnext[w])
			{
				if (w < state->windowposition && state->window[w] == c && state->window[w+1] == c1 && state->window[w+2] == c2)
				{
					for (l = 3;l < maxl && state->window[w+l] == state->window[state->windowposition+l];l++);
					if (bestl < l)
					{
						bestl = l;
						bestcode = ((bestl - 3) << 12) | (state->windowposition - w - 1);
						if (bestl == maxl)
							break;
					}
				}
			}
		}
		if (bestl >= 3)
		{
			state->packetbytes[0] |= state->packetbit;
			state->packetbytes[state->packetsize++] = (unsigned char)(bestcode >> 8);
			state->packetbytes[state->packetsize++] = (unsigned char)bestcode;
		}
		else
			state->packetbytes[state->packetsize++] = c;
		state->packetbit >>= 1;
		while (bestl--)
		{
			// add hash entry
			if (state->windowposition + 3 <= state->windowend)
			{
				hash = (state->window[state->windowposition] + state->window[state->windowposition + 1] * 16 + state->window[state->windowposition + 2] * 256) % HASHSIZE;
				state->hashnext[state->windowposition] = state->hashindex[hash];
				state->hashindex[hash] = state->windowposition;
			}
			state->windowposition++;
		}
		if (state->windowstart < state->windowposition - REFERENCEMAXDIST)
			state->windowstart = state->windowposition - REFERENCEMAXDIST;
	}
}

unsigned int lzss_state_packetfull(lzss_state_t *state)
{
	return !state->packetbit; 
}

unsigned int lzss_state_getpacketsize(lzss_state_t *state)
{
	return state->packetsize >= 2 ? state->packetsize : 0;
}

void lzss_state_getpacketbytes(lzss_state_t *state, unsigned char *out)
{
	int i;
	// copy the bytes to output
	for (i = 0;i < state->packetsize;i++)
		out[i] = state->packetbytes[i];
	// reset the packet
	lzss_state_packetreset(state);
}

unsigned int lzss_compressbuffertobuffer(const unsigned char *in, const unsigned char *inend, unsigned char *out, unsigned char *outend)
{
	unsigned char *outstart = out;
	unsigned int b;
	lzss_state_t state;

	lzss_state_start(&state);

	// this code is a little complex because it implements the flush stage as
	// just a few checks (otherwise it would take two copies of this code)

	// while the buffer is not empty, or there is more input
	while (state.windowposition != state.windowend || in != inend)
	{
		// keep compressing until it stops making new packets
		// (this means the buffer is not full enough anymore)
		// in == inend is setting the flush flag, which will finish the file,
		// and a packet is written if the packet is full or flush is true
		lzss_state_compress(&state, in == inend);
		b = lzss_state_getpacketsize(&state);
		if (in == inend ? b : lzss_state_packetfull(&state))
		{
			// write a packet
			if (out + b > outend)
				return 0; // error: made file bigger
			lzss_state_getpacketbytes(&state, out);
			out += b;
		}
		else
		{
			// fill up buffer if needed
			if (in < inend && (b = lzss_state_wantbytes(&state)))
			{
				if (b > (unsigned int)(inend - in))
					b = (unsigned int)(inend - in);
				lzss_state_feedbytes(&state, in, b);
				in += b;
			}
		}
	}
	return out - outstart;
}
#endif

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
						if ((i = fread(indata, 1, infilesize, infile)) == infilesize)
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

