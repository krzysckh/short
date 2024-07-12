OSOURCE=/home/kpm/nmojeprogramy/owl/

OFLAGS=
CFLAGS=-DPRIM_CUSTOM -I$(OSOURCE)/c -I/usr/local/include -L/usr/local/lib
LDFLAGS=-lsqlite3 -lm -lpthread -static
all: public/short.cgi server
run: all
	mkdir -p public/private/
	[ -f public/private/db.sqlite ] || touch public/private/db.sqlite
	chmod 777 public/private/db.sqlite
	./server
public/short.cgi:
	ol -o - -x c short.scm | clang $(CFLAGS) -o public/short.cgi -x c - sqlite.c $(LDFLAGS)
server:
	ol -o - -x c server.scm | clang $(CFLAGS) -o server -x c - sqlite.c $(LDFLAGS)
clean:
	rm -f public/short.cgi server
