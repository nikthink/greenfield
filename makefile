.POSIX:
.SUFFIXES:
# .SUFFIXES: .s .o

CRT_BASE_PATH=/usr/lib

all: checkDependencies build

clean:
	rm -fv main.o main cat_name.o cat_name

checkDependencies:
	@if [ ! -f /usr/bin/as ] || [ ! -f /usr/bin/ld ]; then \
		printf 'warning: %s\n' 'needed dependencies for a full build: as and ld from binutils' >> /dev/stderr; \
	fi

build:
	as -o main.o main.s
	ld -pie -o main \
		-dynamic-linker /lib64/ld-linux-x86-64.so.2 \
		"$(CRT_BASE_PATH)/Scrt1.o" "$(CRT_BASE_PATH)/crti.o" main.o -lc "$(CRT_BASE_PATH)/crtn.o"
