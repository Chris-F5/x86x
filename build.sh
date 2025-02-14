#!/bin/bash

set -ex

rm -rf x86x.o
nasm -g -f elf64 -o x86x.o x86x.asm
gcc -g -c -o demo.o demo.c
gcc -o demo demo.o x86x.o
