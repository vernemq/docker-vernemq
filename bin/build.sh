#!/usr/bin/env bash
set -e

if [ "$1" = "swc" ]
then
    make swc
    mv _build/swc/rel/vernemq release
elif [ "$1" = "rpi32" ]
then
    make rpi32
    mv _build/rpi32/rel/vernemq release
else
    make rel
    mv _build/default/rel/vernemq release
fi
