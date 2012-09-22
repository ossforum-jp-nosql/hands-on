#!/bin/sh
# -*- mode:shell-script; coding:utf-8 -*-

ALL_NODES=(riak1 riak2 riak3)

die() {
    echo $@
    exit 1
}

stop() {
   local N0=${#ALL_NODES[@]}
   local N=$(($N0 - 1))

   for I in `seq 0 $N`; do
       (
           local NODE=${ALL_NODES[$N - $I]}
           cd $RIAK_HOME/rel/$NODE; ./bin/riak stop || \
               die "node $NODE stop failed"
           echo $NODE stopped
       ) &
   done

   wait
}

stop

