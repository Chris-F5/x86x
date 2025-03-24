#!/bin/bash

set -ex

gcc -I.. -Wall -g -c xlock.c
gcc -L.. -o xlock xlock.o -lx86x
