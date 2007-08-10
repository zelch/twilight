#use this line for profiling
PROFILEOPTION=-pg -g
NOPROFILEOPTIMIZATIONS=
#use this line for no profiling
#PROFILEOPTION=
#NOPROFILEOPTIMIZATIONS=-fomit-frame-pointer
#use these lines for debugging without profiling
#PROFILEOPTION=
#NOPROFILEOPTIMIZATIONS=

#note:
#the -Werror can be removed to compile even if there are warnings,
#this is used to ensure that all released versions are free of warnings.

#normal compile
#CFLAGS= -MD -Wall -O $(PROFILEOPTION)
#debug compile
CFLAGS= -MD -Wall -ggdb $(PROFILEOPTION)

LDFLAGS= -lm $(PROFILEOPTION)

all: dpmapgen2d

.c.o:
	gcc $(CFLAGS) -c $*.c

dpmapgenold: dpmapgenold.o
	gcc -o $@ $^ $(LDFLAGS)

dpmapgen: dpmapgen.o
	gcc -o $@ $^ $(LDFLAGS)

dpmapgen2d: dpmapgen2d.o
	gcc -o $@ $^ $(LDFLAGS)

clean:
	-rm -f dpmapgenold dpmapgen dpmapgen2d *.o *.d

.PHONY: clean

-include *.d
