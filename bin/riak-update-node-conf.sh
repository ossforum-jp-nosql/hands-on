#!/bin/bash
# -*- mode:shell-script; coding:utf-8 -*-

ALL_NODES=(riak1 riak2 riak3 riak4)
ALL_PROTOBUF_PORTS=(8091 8092 8093 8094)
ALL_HTTP_PORTS=(8081 8082 8083 8084)
ALL_HANDOFF_PORTS=(8191 8192 8193 8194)

RIAK_STORAGE_BACKEND=riak_kv_eleveldb_backend

die() {
    echo $@
    exit 1
}

check_riak_home() {
    if [ -z $RIAK_HOME ]; then
        die 'Please set $RIAK_HOME'
    fi

    if [ ! -e $RIAK_HOME ]; then
        die "\$RIAK_HOME '$RIAK_HOME' not found."
    fi
}

set_node_name() {
    local NODE_DIR=$1
    local NODE=$2
    perl -i.bak \
        -pe "s/riak@/${NODE}@/g;" \
        $NODE_DIR/etc/vm.args
}

set_storage_backend() {
    local NODE_DIR=$1
    perl -i.bak1 \
        -pe "s/{storage_backend,.*}/{storage_backend, $RIAK_STORAGE_BACKEND}/;" \
        $NODE_DIR/etc/app.config
}

set_ports() {
    local NODE_DIR=$1
    local PROTOBUF_PORT=$2
    local HTTP_PORT=$3
    local HANDOFF_PORT=$4
    perl -i.bak2 \
        -pe "s/{pb_port,.*}/{pb_port, $PROTOBUF_PORT}/;" \
        -pe "s/{http,.*}/{http, \[ {\"127.0.0.1\", $HTTP_PORT } \]}/;" \
        -pe "s/{handoff_port,.*}/{handoff_port, $HANDOFF_PORT}/;" \
        $NODE_DIR/etc/app.config
}

update_all_nodes() {
   local N0=${#ALL_NODES[@]}
   local N=$(($N0 - 1))

   for I in `seq 0 $N`; do
       (
           local NODE=${ALL_NODES[$I]}
           local NODE_DIR=$RIAK_HOME/rel/$NODE
           local PROTOBUF_PORT=${ALL_PROTOBUF_PORTS[$I]}
           local HTTP_PORT=${ALL_HTTP_PORTS[$I]}
           local HANDOFF_PORT=${ALL_HANDOFF_PORTS[$I]}

           if [ ! -e $NODE_DIR ]; then
               die "$NODE_DIR does not exist."
           fi

           set_node_name $NODE_DIR $NODE
           set_storage_backend $NODE_DIR
           set_ports $NODE_DIR $PROTOBUF_PORT $HTTP_PORT $HANDOFF_PORT
           echo "updated vm.args and app.config for ${NODE}"
       )
   done
}

# set -x
check_riak_home
update_all_nodes
