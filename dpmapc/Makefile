##### Win32 variables #####

WIN32_DPMAPC_EXE=dpmapc.exe
WIN32_LDFLAGS=

##### Unix variables #####

UNIX_DPMAPC_EXE=dpmapc
UNIX_LDFLAGS=-lm

##### Common variables #####

DPMAPCOBJECTS= dpmapc_loadmap.o dpmapc_util.o polygon.o dpmapc.o

CC=gcc
#CFLAGS=-MD -Wall -O2
CFLAGS=-MD -Wall -g -ggdb

##### Commands #####

.PHONY: all mingw clean

all:
ifdef windir
	$(MAKE) DPMAPC_EXE=$(WIN32_DPMAPC_EXE) LDFLAGS="$(WIN32_LDFLAGS)" $(WIN32_DPMAPC_EXE)
else
	$(MAKE) DPMAPC_EXE=$(UNIX_DPMAPC_EXE) LDFLAGS="$(UNIX_LDFLAGS)" $(UNIX_DPMAPC_EXE)
endif

mingw:
	$(MAKE) DPMAPC_EXE=$(WIN32_DPMAPC_EXE) LDFLAGS="$(WIN32_LDFLAGS)" $(WIN32_DPMAPC_EXE)

.c.o:
	$(CC) $(CFLAGS) -c $*.c -o $*.o

$(DPMAPC_EXE): $(DPMAPCOBJECTS)
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
ifdef windir
	del $(WIN32_DPMAPC_EXE)
	del *.o
	del *.d
else
	rm -f $(WIN32_DPMAPC_EXE) $(UNIX_DPMAPC_EXE) *.o *.d
endif

.PHONY: clean

-include *.d
