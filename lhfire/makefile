OBJECTS= frame.o framebuffer.o main.o math.o particle.o render.o script.o

#K6/athlon optimizations
CPUOPTIMIZATIONS=-march=k6
#686 optimizations
#CPUOPTIMIZATIONS=-march=i686

#use this line for profiling
#PROFILEOPTION=-pg -g
#NOPROFILEOPTIMIZATIONS=
#use this line for no profiling
PROFILEOPTION=
NOPROFILEOPTIMIZATIONS=-fomit-frame-pointer

#note:
#the -Werror can be removed to compile even if there are warnings,
#this is used to ensure that all released versions are free of warnings.

#normal compile
OPTIMIZATIONS= -O6 -funroll-loops $(NOPROFILEOPTIMIZATIONS) -fexpensive-optimizations $(CPUOPTIMIZATIONS)
CFLAGS= -MD -Wall -Werror $(OPTIMIZATIONS) $(PROFILEOPTION)
#debug compile
#OPTIMIZATIONS= -O -g
#CFLAGS= -MD -Wall -Werror -ggdb $(OPTIMIZATIONS) $(PROFILEOPTION)

LDFLAGS= -lm $(PROFILEOPTION)

all: lhfire

.c.o:
	gcc $(CFLAGS) -c $*.c

lhfire: $(OBJECTS)
	gcc -o $@ $^ $(LDFLAGS)


clean:
	-rm -f lhfire $(OBJECTS) *.d

.PHONY: clean

-include *.d
