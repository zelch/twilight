COMMONOBJECTS= common/cmdlib.o common/mathlib.o common/bspfile.o
HQBSPOBJECTS= hqbsp/brush.o hqbsp/csg4.o hqbsp/map.o hqbsp/merge.o hqbsp/nodraw.o hqbsp/outside.o hqbsp/portals.o hqbsp/qbsp.o hqbsp/region.o hqbsp/surfaces.o hqbsp/solidbsp.o hqbsp/tjunc.o hqbsp/writebsp.o hqbsp/wad.o $(COMMONOBJECTS)
HVISOBJECTS= hvis/flow.o hvis/soundpvs.o hvis/vis.o $(COMMONOBJECTS)
HLIGHTOBJECTS= hlight/entities.o hlight/light.o hlight/ltface.o hlight/trace.o $(COMMONOBJECTS)

#AMD
#CPUOPTIONS= -march=k6
#Intel
#CPUOPTIONS= -march=i686
#other
CPUOPTIONS=

#profiling
PROFILEOPTIONS= -pg -g
#release
#PROFILEOPTIONS= -fomit-frame-pointer

OPTIMIZATIONS= -MD -O6 -funroll-loops $(PROFILEOPTIONS) -fexpensive-optimizations $(CPUOPTIONS)
#OPTIMIZATIONS= -MD -Werror -pg -g

CFLAGS= -Wall -Icommon $(OPTIMIZATIONS)
LDFLAGS= -lm $(PROFILEOPTIONS)

all: bin/hqbsp bin/hvis bin/hlight

bin/hqbsp: $(HQBSPOBJECTS)
	gcc -o $@ $^ $(LDFLAGS)

bin/hvis: $(HVISOBJECTS)
	gcc -o $@ $^ $(LDFLAGS)

bin/hlight: $(HLIGHTOBJECTS)
	gcc -o $@ $^ $(LDFLAGS)

.c.o:
	gcc $(CFLAGS) -c $*.c -o $*.o

clean:
	rm -f bin/hqbsp bin/hvis bin/hlight hqbsp/*.o hqbsp/*.d hvis/*.o hvis/*.d hlight/*.o hlight/*.d

.PHONY: clean

-include *.d
