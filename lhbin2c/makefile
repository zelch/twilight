
CC=gcc

lhbin2c: lhbin2c.o
	$(CC) -o $@ $^

.c.o:
	$(CC) -MD -Wall -Werror -c $< -o $@

clean:
	rm -f lhbin2c *.o *.d

.PHONY : clean

-include *.d
