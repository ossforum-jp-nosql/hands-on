#!/usr/bin/env escript
%% -*- mode:erlang; coding:utf-8 -*-
%%! -smp enable -name riak_client@127.0.0.1 -pa /home/ossforum/riak/deps/riak_core/ebin

main([]) ->
    Node = 'riak1@127.0.0.1',
    Cookie = 'riak',

    true = erlang:set_cookie(node(), Cookie),

    case rpc:call(Node, riak_core_ring_manager, get_my_ring, []) of
        {badrpc, Error1} ->
            io:format("error: ~p~n", [Error1]);
        {ok, Ring} ->
            {RingSize, RingList} = ring_info(Ring),
            io:format("Ring Size: ~p~n~n", [RingSize]),
            io:format("~p~n",   [add_ring_num(RingSize, RingList)])
    end;
main(_) ->
    io:format("usage: riak-preflist-ossforum.escript <bucket-name> <key>~n").

%% {Size, List}
ring_info({_,_,_,RingInfo,_,_,_,_,_,_,_}) ->
    RingInfo.

add_ring_num(RingSize, Ring) ->
    [ {ring_num(RingSize, Hash), Hash, Node} || {Hash, Node} <- Ring ].

ring_num(_, 0) ->
    1;
ring_num(RingSize, Hash) ->
    MaxValue = 1461501637330902918203684832716283019655932542976,
    Step = MaxValue / RingSize,
    round(Hash / Step) + 1.
