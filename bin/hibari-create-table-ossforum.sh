#!/bin/sh
# -*- mode:shell-script; coding:utf-8 -*-

TABLE=basho_bench_test
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

bootstrap
create_table

