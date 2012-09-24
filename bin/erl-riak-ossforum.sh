#!/bin/sh
# -*- mode:shell-script; coding:utf-8 -*-

rlwrap -adummy erl +A 4 -pa $HOME/riak-erlang-client/ebin -pa $HOME/riak-erlang-client/deps/*/ebin
