#!/bin/sh
# -*- mode:shell-script; coding:utf-8 -*-

ALL_NODES=(hibari1 hibari2 hibari3)

die() {
    echo $@
    exit 1
}

ping() {
   local N0=${#ALL_NODES[@]}
   local N=$(($N0 - 1))

   for I in `seq 0 $N`; do
       (
           local NODE=${ALL_NODES[$I]}
           echo -n "$NODE ... "
           cd $HIBARI_HOME/rel/$NODE; ./bin/hibari ping || \
               die "node $NODE ping failed"
       )
   done
}

ping

