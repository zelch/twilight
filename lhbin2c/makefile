
CC=gcc

all: lhbin2c lzss_compress lzss_decompress

lhbin2c: lhbin2c.o
	$(CC) -g -ggdb -o $@ $^

lzss_compress: lzss_compress.o
	$(CC) -g -ggdb -o $@ $^

lzss_decompress: lzss_decompress.o
	$(CC) -g -ggdb -o $@ $^

.c.o:
	$(CC) -g -ggdb -MD -Wall -Werror -c $< -o $@

clean:
	rm -f lhbin2c lzss_compress lzss_decompress *.o *.d

.PHONY : clean

-include *.d
