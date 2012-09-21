#!/bin/sh

HIBARI_HOME=${HOME}/nosql2/hibari/hibari/rel/hibari

TABLE=basho_bench_test
NODES='hibari@127.0.0.1'
# NODES='hibari1@127.0.0.1 hibari2@127.0.0.1 hibari3@127.0.0.1 hibari4@127.0.0.1'

# create-table [-bigdata] [-disklogging] [-syncwrites] [-varprefix] [-varprefixsep <char>] [-varprefixnum <num>] [-bricksperchain <num>] [-numnodesperblock <num>] [-blockmultfactor <num>]
#${HIBARI_HOME}/bin/hibari-admin create-table $TABLE -bricksperchain 3 $NODES
${HIBARI_HOME}/bin/hibari-admin create-table $TABLE $NODES
