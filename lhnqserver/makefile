OBJECTS= cmd.o common.o console.o cpu_noasm.o crc.o cvar.o host.o host_cmd.o mathlib.o model_alias.o model_brush.o model_shared.o model_sprite.o net_bsd.o net_udp.o net_dgrm.o net_main.o pr_cmds.o pr_edict.o pr_exec.o sv_main.o sv_move.o sv_phys.o sv_user.o sys.o world.o zone.o

OPTIMIZATIONS= -O6 -ffast-math -funroll-loops -fomit-frame-pointer -fexpensive-optimizations

CFLAGS= -Wall -Werror -I/usr/X11R6/include -I/usr/include/glide $(OPTIMIZATIONS)
#CFLAGS= -Wall -Werror -I/usr/X11/include -ggdb $(OPTIMIZATIONS)
#LDFLAGS= -L/usr/X11R6/lib -lm -lX11 -lXext -lXIE -lXxf86dga -lXxf86vm -lGL -ldl
LDFLAGS= -L/usr/X11R6/lib -lm -lX11 -lXext -lXIE -lXxf86dga -lXxf86vm -lGL -ldl -lasound

all: lhnqserver

.c.o:
	gcc $(CFLAGS) -c $*.c

lhnqserver: $(OBJECTS)
	gcc -o $@ $^ $(LDFLAGS)

clean:
	rm -f lhnqserver $(OBJECTS)
