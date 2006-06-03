
#use this line for profiling
#PROFILEOPTION=-pg -g
#use this lines for no profiling
PROFILEOPTION=

#note:
#the -Werror can be removed to compile even if there are warnings,
#this is used to ensure that all released versions are free of warnings.

#normal compile
#OPTIMIZATIONS= -O6 -fexpensive-optimizations
#CFLAGS= -I/usr/include/SDL -MD -Wall -Werror $(OPTIMIZATIONS) $(PROFILEOPTION)
#debug compile
OPTIMIZATIONS=
CFLAGS= -I/usr/include/SDL -MD -Wall -ggdb $(OPTIMIZATIONS) $(PROFILEOPTION)
CPP=g++

LDFLAGS= -lm $(PROFILEOPTION)

TARGETS= lhterrain

all: $(TARGETS)

.c.o:
	$(CPP) $(CFLAGS) -c $*.c

.cpp.o:
	$(CPP) $(CFLAGS) -c $*.cpp

lhterrain: lhterrain.c mesh.cpp endian.o file.o image.o system.o texture.o
	$(CPP) -o $@ $^ $(LDFLAGS) -lSDL -lSDLmain -lpthread


clean:
	-rm -f $(TARGETS) *.exe *.o *.d

.PHONY: clean

-include *.d
