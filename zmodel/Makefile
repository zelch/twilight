##### Win32 variables #####

WIN32_EXE=zmodel.exe
WIN32_LDFLAGS=-lm

##### Unix variables #####

UNIX_EXE=zmodel
UNIX_LDFLAGS=-lm

##### Common variables #####

CC=gcc
CFLAGS=-MD -Wall -O2
#CFLAGS=-MD -Wall -g -ggdb

ifdef windir
CMD_RM=del
else
CMD_RM=rm -f
endif

##### Commands #####

.PHONY: all mingw clean

all:
ifdef windir
	$(MAKE) EXE=$(WIN32_EXE) LDFLAGS="$(WIN32_LDFLAGS)" $(WIN32_EXE)
else
	$(MAKE) EXE=$(UNIX_EXE) LDFLAGS="$(UNIX_LDFLAGS)" $(UNIX_EXE)
endif

mingw:
	@$(MAKE) EXE=$(WIN32_EXE) LDFLAGS="$(WIN32_LDFLAGS)" $(WIN32_EXE)

.c.o:
	$(CC) $(CFLAGS) -c $*.c

$(EXE): zmodel.o
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	-$(CMD_RM) $(WIN32_EXE)
	-$(CMD_RM) $(UNIX_EXE)
	-$(CMD_RM) *.o
