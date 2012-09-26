#!/bin/sh
# -*- mode:shell-script; coding:utf-8 -*-

ALL_NODES=(riak1 riak2 riak3 riak4)

die() {
    echo $@
    exit 1
}

delete_node_data() {
   local N0=${#ALL_NODES[@]}
   local N=$(($N0 - 1))

   for I in `seq 0 $N`; do
       (
           local NODE=${ALL_NODES[$I]}
           cd $RIAK_HOME/rel/$NODE; rm -rf data/* || \
               die "node $NODE reset failed"
           echo deleted data on $NODE
       ) &
   done

   wait
}

delete_node_data

