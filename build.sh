#!/bin/bash

set -ex

rm -rf libx86x.a x86x.o utils.o
nasm -g -f elf64 -o x86x.o x86x.asm
nasm -g -f elf64 -o utils.o utils.asm
ar rcs libx86x.a x86x.o utils.o
