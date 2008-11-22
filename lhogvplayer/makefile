
#normal compile
FLAGS= -lm -Wall -O2 -fexpensive-optimizations
#profile compile
#FLAGS= -lm -Wall -O2 -fexpensive-optimizations -pg -g
#debug compile
#FLAGS= -lm -Wall -ggdb

all:
ifdef windir
	$(MAKE) lhogvplayer.exe
else
	$(MAKE) lhogvplayer
endif

mingw:
	$(MAKE) lhogvplayer.exe

lhogvplayer: lhogvplayer.c lhogv.c
	$(CC) -o $@ $^ -ltheoradec -lvorbis -logg `sdl-config --cflags` `sdl-config --libs` $(FLAGS)

lhogvplayer.exe: lhogvplayer.c lhogv.c
	$(CC) -o $@ $^ -ltheoradec -lvorbis -logg `sdl-config --cflags` `sdl-config --libs` $(FLAGS)



clean:
	-rm -f lhogvplayer lhogvplayer.exe

.PHONY: clean

-include *.d
