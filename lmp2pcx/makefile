
CFLAGS= -MD -Wall -Werror
LDFLAGS=

all: lmp2pcx

.c.o:
	gcc $(CFLAGS) -c $*.c

lmp2pcx: lmp2pcx.o
	gcc -o $@ $^ $(LDFLAGS)

clean:
	-rm -f lmp2pcx *.o *.d

.PHONY: clean

-include *.d

