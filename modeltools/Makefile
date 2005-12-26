##### Common variables #####

CC=gcc
CFLAGS=-MD -Wall
#CFLAGS=-MD -Wall -g

ifdef windir
CMD_RM=del
else
CMD_RM=rm -f
endif

##### Win32 variables #####

WIN32_EXE=modeltool.exe
WIN32_LDFLAGS=$(CFLAGS) -lm

##### Unix variables #####

UNIX_EXE=modeltool
UNIX_LDFLAGS=$(CFLAGS) -lm

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

$(EXE): modeltool.o file.o
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	-$(CMD_RM) $(WIN32_EXE)
	-$(CMD_RM) $(UNIX_EXE)
	-$(CMD_RM) *.o
	-$(CMD_RM) *.d
	-$(CMD_RM) *~
