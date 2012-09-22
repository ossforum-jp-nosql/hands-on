#!/bin/sh
# -*- mode:shell-script; coding:utf-8 -*-

ALL_NODES=(riak1 riak2 riak3)

die() {
    echo $@
    exit 1
}

build_cluster() {
   local N0=${#ALL_NODES[@]}
   local N=$(($N0 - 1))

   local BASE_NODE=${ALL_NODES[0]}
   local SECOND_NODE=${ALL_NODES[1]}

   for I in `seq 1 $N`; do
       (
           local NODE=${ALL_NODES[$I]}
           cd $RIAK_HOME/rel/$NODE; ./bin/riak-admin cluster join ${BASE_NODE}@127.0.0.1 || \
               die "node $NODE join failed"
       )
   done

   cd $RIAK_HOME/rel/$SECOND_NODE; \
       ./bin/riak-admin cluster plan && \
       ./bin/riak-admin cluster commit || \
       die "Failed committing cluster changes"

   riak-admin member-status
}

build_cluster

