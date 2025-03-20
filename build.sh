#!/bin/bash

set -ex

rm -rf x86x.o
nasm -g -f elf64 -o x86x.o x86x.asm
nasm -g -f elf64 -o utils.o utils.asm
gcc -Wall -g -c -o xlock.o xlock.c
gcc -o xlock xlock.o x86x.o utils.o
