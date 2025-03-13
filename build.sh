#!/bin/bash

set -ex

rm -rf x86x.o
nasm -g -f elf64 -o x86x.o x86x.asm
nasm -g -f elf64 -o utils.o utils.asm
gcc -g -c -o demo.o demo.c
gcc -o demo demo.o x86x.o utils.o
