#!/bin/sh

IFS=$'\n'
for midi in ../Utils/*.mid
do
  ./extract-sf2.sh FluidR3_GM.sf2 "$midi"
done
