#!/bin/bash

set -ex

gcc -I.. -Wall -g -c hello.c
gcc -L.. -o hello hello.o -lx86x

gcc -I.. -Wall -g -c xlock.c
gcc -L.. -o xlock xlock.o -lx86x
