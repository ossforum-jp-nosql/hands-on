#!/usr/bin/env escript
%% -*- mode:erlang; coding:utf-8 -*-
%%! -smp enable -name riak_client@127.0.0.1 -pa /home/ossforum/riak-erlang-client/ebin -pa /home/ossforum/riak-erlang-client/deps/protobuffs/ebin -pa /home/ossforum/riak-erlang-client/deps/riak_pb/ebin -pa /home/ossforum/riak-erlang-client/deps/meck/ebin

main([BucketName, NumKeys]) ->
    Host = "127.0.0.1",
    Port = 8091,

    {ok, Conn} = riakc_pb_socket:start_link(Host, Port),
    {NumOK, NumErr} = multiputs(Conn, list_to_binary(BucketName), list_to_integer(NumKeys)),
    io:format("ok: ~p,  error: ~p~n", [NumOK, NumErr]);
main(_) ->
    io:format("usage: riak-multiputs.escript <bucket-name> <number-of-keys>~n").


multiputs(Conn, BucketNameBin, NumKeys) when NumKeys > 0 ->
    multiputs0(Conn, BucketNameBin, NumKeys, 0, 0).

multiputs0(_, _, 0, NumOK, NumErr) ->
    {NumOK, NumErr};
multiputs0(Conn, BucketNameBin, NumKeys, NumOK, NumErr) ->
    N = integer_to_list(NumKeys),
    case put(Conn, BucketNameBin, list_to_binary("key" ++ N), list_to_binary("value" ++ N)) of
        ok ->
            multiputs0(Conn, BucketNameBin, NumKeys - 1, NumOK + 1, NumErr);
        _ ->
            multiputs0(Conn, BucketNameBin, NumKeys - 1, NumOK, NumErr + 1)
    end.

put(Conn, BucketName, Key, Value) ->
    W = all,
    Obj =riakc_obj:new(BucketName, Key, Value),
    riakc_pb_socket:put(Conn, Obj, [{w, W}]).

