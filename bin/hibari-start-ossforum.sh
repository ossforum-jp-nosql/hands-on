#!/bin/sh
# -*- coding:utf-8 -*-

HIBARI_HOME=${HOME}/nosql2/hibari/hibari/rel
# ALL_NODES=(hibari1 hibari2 hibari3)
ALL_NODES=(hibari)

die() {
    echo $@
    exit 1
}

start() {
   local N0=${#ALL_NODES[@]}
   local N=$(($N0 - 1))

   for I in `seq 0 $N`; do
       (
           local NODE=${ALL_NODES[$I]}
           cd $HIBARI_HOME/$NODE; ./bin/hibari start || \
               die "node $NODE start failed"
           echo $NODE started
       ) &
   done

   wait
}

start

