.POSIX:
.SUFFIXES:
# .SUFFIXES: .s .o

CLIB_BASE_PATH=/usr/lib/

all: checkDependencies build

clean:
	rm -rf ./public/
	rm -fv content/notes/ir/irg.png

checkDependencies:
	@if [ ! -f /usr/bin/as ] || [ ! -f /usr/bin/ld ]; then \
		printf 'warning: %s\n' 'needed dependencies for a full build: as and ld from binutils' >> /dev/stderr; \
	fi

build:
	as -o main.o main.s
	ld -pie -o main \
		-dynamic-linker /lib64/ld-linux-x86-64.so.2 \
		"$(CLIB_BASE_PATH)/Scrt1.o" "$(CLIB_BASE_PATH)/crti.o" main.o -lc "$(CLIB_BASE_PATH)/crtn.o"
