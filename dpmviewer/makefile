
#compiler to use
CC=gcc

SDL_CONFIG?=sdl-config

#use this line for profiling
#PROFILEOPTION=-pg -g
#use this lines for no profiling
PROFILEOPTION=

#note:
#the -Werror can be removed to compile even if there are warnings,
#this is used to ensure that all released versions are free of warnings.

#normal compile
OPTIMIZATIONS= -O2 -fexpensive-optimizations
CFLAGS= -MD -Wall -Werror $(OPTIMIZATIONS) $(PROFILEOPTION) `$(SDL_CONFIG) --cflags`
#debug compile
#OPTIMIZATIONS=
#CFLAGS= -MD -Wall -ggdb $(OPTIMIZATIONS) $(PROFILEOPTION) `$(SDL_CONFIG) --cflags`

LDFLAGS= -lm $(PROFILEOPTION) `$(SDL_CONFIG) --libs`

TARGETS= dpmviewer

all: $(TARGETS)

.c.o:
	$(CC) $(CFLAGS) -c $*.c

dpmviewer: dpmviewer.o
	$(CC) -o $@ $^ $(LDFLAGS)


clean:
	-rm -f $(TARGETS) *.exe *.o *.d

.PHONY: clean

-include *.d
