#!/bin/sh
# -*- mode:shell-script; coding:utf-8 -*-

TABLES=(basho_bench_test_simple basho_bench_test_sequential basho_bench_test_random)
NODES='hibari1@127.0.0.1 hibari2@127.0.0.1 hibari3@127.0.0.1'

die() {
    echo $@
    exit 1
}

bootstrap() {
    ${HIBARI_HOME}/rel/hibari1/bin/hibari-admin bootstrap || \
        die "Bootstrapping Hibari cluster failed."
}

create_table() {
    local TABLE=$1
    # create-table <table name>
    #    [-bigdata]
    #    [-disklogging]
    #    [-syncwrites]
    #    [-varprefix]
    #    [-varprefixsep <char>]
    #    [-varprefixnum <num>]
    #    [-bricksperchain <num>]
    #    [-numnodesperblock <num>]
    #    [-blockmultfactor <num>]

    ${HIBARI_HOME}/rel/hibari1/bin/hibari-admin create-table $TABLE \
        -bricksperchain 3 $NODES || \
        die "Can't create table $TABLE"
    echo Table $TABLE created
}

create_tables() {
   local N0=${#TABLES[@]}
   local N=$(($N0 - 1))

   for I in `seq 0 $N`; do
       (
           local TABLE=${TABLES[$I]}
           create_table $TABLE
       )
   done
}

bootstrap
create_tables
