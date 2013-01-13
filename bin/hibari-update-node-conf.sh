#!/bin/bash
# -*- mode:shell-script; coding:utf-8 -*-

ALL_NODES=(hibari1 hibari2 hibari3)

die() {
    echo $@
    exit 1
}

check_hibari_home() {
    if [ -z $HIBARI_HOME ]; then
        die 'Please set $HIBARI_HOME'
    fi

    if [ ! -e $HIBARI_HOME ]; then
        die "\$HIBARI_HOME '$HIBARI_HOME' not found."
    fi
}

set_node_name() {
    local NODE_DIR=$1
    local NODE=$2
    perl -i.bak \
        -pe "s/hibari@/${NODE}@/g;" \
        $NODE_DIR/releases/*/vm.args
    perl -i.bak \
        -pe "s/{gdss_admin,[^}]*}/\{gdss_admin, 2000, \['hibari1\@127.0.0.1'\]}/;" \
        -pe "s/{network_monitor_monitored_nodes,[^}]*}/{network_monitor_monitored_nodes, \['hibari1\@127.0.0.1', 'hibari2\@127.0.0.1', 'hibari3\@127.0.0.1'\]}/;" \
        $NODE_DIR/releases/*/sys.config
}

update_all_nodes() {
   local N0=${#ALL_NODES[@]}
   local N=$(($N0 - 1))

   for I in `seq 0 $N`; do
       (
           local NODE=${ALL_NODES[$I]}
           local NODE_DIR=$HIBARI_HOME/rel/$NODE

           if [ ! -e $NODE_DIR ]; then
               die "$NODE_DIR does not exist."
           fi

           set_node_name $NODE_DIR $NODE
           echo "updated vm.args and sys.config for ${NODE}"
       )
   done
}

# set -x
check_hibari_home
update_all_nodes
