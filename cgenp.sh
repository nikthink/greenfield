#!/usr/bin/env bash


CRT_BASE_PATH=/usr/lib/

rm -f genp.o genp
as -o genp.o - &&
    ld -pie -o genp \
	    -dynamic-linker /lib64/ld-linux-x86-64.so.2 \
		"$CRT_BASE_PATH/Scrt1.o" "$CRT_BASE_PATH/crti.o" genp.o -lc "$CRT_BASE_PATH/crtn.o"
