## $Id$
##
## This file is intended to be processed by automake

AUTOMAKE_OPTIONS = foreign dist-zip

SUBDIRS = gamedata

LIBS = @SDL_LIBS@ @LIBS@ -lm
CFLAGS = @CFLAGS@ @SDL_CFLAGS@

bin_PROGRAMS = nqx

nqx_SOURCES = \
	chase.c \
	cl_demo.c cl_input.c cl_main.c cl_model.c cl_parse.c cl_ents.c \
	cl_tent.c \
	client.h cmd.h common.c console.c console.h \
	gl_draw.c \
	gl_rlight.c gl_rmain.c gl_rsurf.c gl_screen.c gl_warp.c \
	host.c host_cmd.c keys.c keys.h menu.c \
	net.h net_bsd.c net_dgrm.c net_dgrm.h net_loop.c net_loop.h \
	net_main.c net_udp.c net_udp.h \
	pr_cmds.c pr_edict.c pr_exec.c progs.h progdefs.h protocol.h \
	r_part.c r_explosion.c render.h sbar.c screen.h server.h \
	snd_dma.c \
	sv_main.c sv_move.c sv_phys.c sv_user.c \
	sys.c teamplay.c vid_sdl.c \
        view.c world.c world.h \
	cdaudio.h mem.c sound.h cdmusic.c mix.c target.c \
	zone.h wad.h view.h vid.h twiconfig.h teamplay.h sys.h strlib.h \
	spritegn.h sbar.h quakedef.h qtypes.h pr_comp.h modelgen.h model.h \
	menu.h mathlib.h locs.h input.h host.h gl_warp_sin.h draw.h cvar.h \
	crc.h common.h collision.h cmd.h bspfile.h anorms.h anorm_dots.h \
	image.c image.h qlmp.c qlmp.h tga.c tga.h \
	dglfuncs.h dyngl.c dyngl.h gl_textures.c gl_textures.h glquake.h \
	light.h noise.c noise_textures.c pointers.c pointers.h \
	transform.c transform.h \
	buildnum.c cmd.c collision.c crc.c cvar.c locs.c mathlib.c \
	model.c parm.c strlib.c wad.c zone.c

EXTRA_DIST = \
	COPYING.BSD bootstrap

