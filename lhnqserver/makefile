OBJECTS= cmd.o common.o console.o cpu_noasm.o crc.o cvar.o host.o host_cmd.o mathlib.o model_alias.o model_brush.o model_shared.o model_sprite.o net_bsd.o net_dgrm.o net_main.o pr_cmds.o pr_edict.o pr_exec.o sv_main.o sv_move.o sv_phys.o sv_user.o sys.o world.o zone.o

OPTIMIZATIONS= -O6 -ffast-math -funroll-loops -fomit-frame-pointer -fexpensive-optimizations
#OPTIMIZATIONS= -O -g

CFLAGS= -Wall -Wno-trigraphs $(OPTIMIZATIONS)
#CFLAGS= -Wall -ggdb $(OPTIMIZATIONS)
LDFLAGS= -lm

all: lhnqserver
mingw: lhnqserver.exe

.c.o:
	gcc $(CFLAGS) -c $*.c

lhnqserver: net_udp.o $(OBJECTS)
	gcc -o $@ $(OBJECTS) $(LDFLAGS)

lhnqserver.exe: net_wins.o $(OBJECTS)
	gcc -o $@ $(OBJECTS) $(LDFLAGS)

clean:
	rm -f lhnqserver lhnqserver.exe $(OBJECTS)
