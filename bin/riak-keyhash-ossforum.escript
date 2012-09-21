#!/usr/bin/env escript
%% -*- mode:erlang; coding:utf-8 -*-
%%! -smp enable -name riak_client@127.0.0.1 -pa /home/tatsuya/nosql2/riak/deps/riak_core/ebin -pa /home/tatsuya/nosql2/riak/deps/riak_kv/ebin -pa /home/tatsuya/nosql2/riak/deps/mochiweb/ebin -pa /home/tatsuya/nosql2/riak/deps/*/ebin

main([BucketName, Key]) ->
    Node = 'riak1@127.0.0.1',
    Cookie = 'riak'

    true = erlang:set_cookie(node(), Cookie),

    {ok, Ring} = rpc:call(Node, riak_core_ring_manager, get_my_ring, []),
    HashBin = rpc:call(Node, riak_core_util,
                       chash_key, [{list_to_binary(BucketName), list_to_binary(Key)}]),
    <<HashInt:160/integer>> = HashBin,
    io:format("~s/~s: ~p~n", [BucketName, Key, HashInt]).
