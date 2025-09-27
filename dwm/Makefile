# dwm - dynamic window manager
# See LICENSE file for copyright and license details.

include config.mk

SRC = drw.c dwm.c util.c slstatus.c
OBJ = ${SRC:.c=.o}

COM =\
	components/battery\
	components/cpu\
	components/datetime\
	components/ram\
	components/run_command\

all: dwm

.c.o:
	${CC} -c ${CFLAGS} $<

components/%.o: components/%.c
	${CC} -c ${CFLAGS} -o $@ $<

${OBJ}: config.h config.mk slstatus_config.h

dwm: ${OBJ} $(COM:=.o)
	${CC} -o $@ ${OBJ} ${LDFLAGS} $(COM:=.o)

clean:
	rm -f dwm ${OBJ} $(COM:=.o) dwm-${VERSION}.tar.gz

dist: clean
	mkdir -p dwm-${VERSION}
	mkdir -p dwm-${VERSION}/components
	cp -R LICENSE Makefile README config.h slstatus_config.h config.mk\
		dwm.1 slstatus.1 drw.h util.h arg.h ${SRC} dwm.png transient.c dwm-${VERSION}
	cp -R $(COM:=.c) "dwm-${VERSION}/components"
	tar -cf dwm-${VERSION}.tar dwm-${VERSION}
	gzip dwm-${VERSION}.tar
	rm -rf dwm-${VERSION}

install: all
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f dwm ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/dwm
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < dwm.1 > ${DESTDIR}${MANPREFIX}/man1/dwm.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/dwm.1

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/dwm\
		${DESTDIR}${MANPREFIX}/man1/dwm.1

.PHONY: all clean dist install uninstall