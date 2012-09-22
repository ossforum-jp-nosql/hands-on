#!/usr/bin/env escript
%% -*- mode:erlang; coding:utf-8 -*-
%%! -smp enable -name riak_client@127.0.0.1

main([BucketName, Key]) ->
    Node = 'riak1@127.0.0.1',
    Cookie = 'riak',

    true = erlang:set_cookie(node(), Cookie),

    case rpc:call(Node, riak_core_util, chash_key,
                  [{list_to_binary(BucketName), list_to_binary(Key)}]) of
        {badrpc, Error} ->
            io:format("error: ~p~n", [Error]);
        <<Hash:160/integer>> ->
            io:format("~s/~s: ~p~n", [BucketName, Key, Hash])
    end;
main(_) ->
    io:format("usage: riak-keyhash-ossforum.escript <bucket-name> <key>~n").
