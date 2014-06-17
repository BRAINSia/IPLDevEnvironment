#!/bin/sh

# SYSTEM=$(sw_vers | awk '"ProductName:" == $1 {print $3$4}')  # OSX
VERSION=$(sw_vers | awk '"ProductVersion:" == $1 {split($2,version,"."); print version[1]"."version[2]}')  # 10.9
OSTAG=${SYSTEM}_${VERSION}  #Darwin_10.9
echo $OSTAG
