OBJECTS= cmd.o common.o console.o cpu_noasm.o crc.o cvar.o host.o host_cmd.o mathlib.o model_alias.o model_brush.o model_shared.o model_sprite.o net_dgrm.o net_main.o pr_cmds.o pr_edict.o pr_exec.o sv_main.o sv_move.o sv_phys.o sv_user.o sys.o world.o zone.o
UNIXOBJECTS= net_udp.o net_bsd.o $(OBJECTS)
WIN32OBJECTS= net_wins.o net_wipx.o net_win.o $(OBJECTS)

OPTIMIZATIONS= -O6 -ffast-math -funroll-loops -fomit-frame-pointer -fexpensive-optimizations
#OPTIMIZATIONS= -O -g

CFLAGS= -Wall -Wno-trigraphs $(OPTIMIZATIONS)
#CFLAGS= -Wall -ggdb $(OPTIMIZATIONS)
LDFLAGS= -lm

all: lhnqserver

mingw: lhnqserver.exe

.PHONY: all mingw clean

.c.o:
	gcc $(CFLAGS) -c $*.c

lhnqserver: $(UNIXOBJECTS)
	gcc -o $@ $(UNIXOBJECTS) $(LDFLAGS)

lhnqserver.exe: $(WIN32OBJECTS)
	gcc -o $@ $(WIN32OBJECTS) $(LDFLAGS) -lwsock32 -lwinmm

clean:
	rm -f lhnqserver lhnqserver.exe *.o *.d
