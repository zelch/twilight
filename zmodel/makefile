#normal compile
CFLAGS= -Wall -O2
#debug compile
#CFLAGS= -Wall -g -ggdb

LDFLAGS= -lm

all: zmodel

zmodel: zmodel.c
	gcc -o $@ $^ $(CFLAGS) $(LDFLAGS)

clean:
	-rm -f zmodel

.PHONY: clean

