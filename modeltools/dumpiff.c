
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "file.h"

void dumpiffchunks(const unsigned char *data, size_t datasize, int indentlevel, int alignsize, const unsigned char *filedatastart, int isriff)
{
	int i, riff;
	unsigned int chunksize;
	const unsigned char *dataend = data + datasize, *chunkdata;
	char chunkid[8];
	while (data < dataend)
	{
		if (data + 8 <= dataend)
		{
			riff = isriff;
			chunkid[0] = data[0];
			chunkid[1] = data[1];
			chunkid[2] = data[2];
			chunkid[3] = data[3];
			chunkid[4] = 0;
			if (!strcmp(chunkid, "RIFF"))
				riff = 1;
			if (riff)
				chunksize = data[4] + data[5] * 256u + data[6] * 65536u + data[7] * 16777216u;
			else
				chunksize = data[4] * 16777216u + data[5] * 65536u + data[6] * 256u + data[7];
			for (i = 0;i < 4;i++)
				if (chunkid[i] < ' ' || chunkid[i] >= 127)
					break;
			if (i == 4)
			{
				if (data + 8 + chunksize <= dataend)
				{
					printf("%4s%10d ", chunkid, chunksize);
					for (i = 0;i < indentlevel;i++)
						printf(" ");
					printf("%4s ", chunkid);
					chunkdata = data + 8;
					if (!strcmp(chunkid, "RIFF")
					 || !strcmp(chunkid, "AIFF")
					 || !strcmp(chunkid, "FORM") || !strcmp(chunkid, "FOR4") || !strcmp(chunkid, "FOR8")
					 || !strcmp(chunkid, "LIST") || !strcmp(chunkid, "LIS4") || !strcmp(chunkid, "LIS8"))
					{
						if (chunksize >= 4)
						{
							char newcontext[8];
							newcontext[0] = data[8];
							newcontext[1] = data[9];
							newcontext[2] = data[10];
							newcontext[3] = data[11];
							newcontext[4] = 0;
							printf("%4s\n", newcontext);
							dumpiffchunks(data + 12, chunksize - 4, indentlevel + 1, chunkid[3] == '8' ? 8 : (chunkid[3] == '4' ? 4 : 2), filedatastart, riff);
						}
						else
							printf("invalid FORM chunk size %u encountered at position %u\n", chunksize, (unsigned int)(data - filedatastart));
					}
					else
					{
						int dumpsize = 16;
						for (i = 0;i < dumpsize;i++)
							printf("%c", i < chunksize ? (chunkdata[i] >= ' ' && chunkdata[i] < 127 ? chunkdata[i] : '.') : ' ');
						printf(" ");
						for (i = 0;i < dumpsize && i < chunksize;i++)
							printf("%02x", chunkdata[i]);
						printf("\n");
					}
					data = data + ((8 + chunksize + alignsize - 1) & ~(alignsize - 1));
				}
				else
				{
					printf("invalid chunk size %u encountered at position %u\n", chunksize, (unsigned int)(data - filedatastart));
					data = dataend;
				}
			}
			else
			{
				printf("invalid chunk id encountered at position %u\n", (unsigned int)(data - filedatastart));
				data = dataend;
			}
		}
		else
		{
			printf("insufficient remaining space for another chunk at position %u\n", (unsigned int)(data - filedatastart));
			data = dataend;
		}
	}
}

int main(int argc, char **argv)
{
	int i, ret = 0;
	void *data;
	int datasize;
	for (i = 1;i < argc;i++)
	{
		printf("Dumping file %s\n", argv[i]);
		if (readfile(argv[i], &data, &datasize) == 0)
		{
			dumpiffchunks(data, datasize, 0, 4, data, 0);
			free(data);
		}
		else
		{
			printf("load failed\n");
			ret = 1;
		}
	}
	return 0;
}

