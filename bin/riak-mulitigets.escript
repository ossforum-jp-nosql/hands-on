#!/usr/bin/env escript
%% -*- mode:erlang; coding:utf-8 -*-
%%! -smp enable -name riak_client@127.0.0.1 -pa /home/ossforum/riak-erlang-client/ebin -pa /home/ossforum/riak-erlang-client/deps/protobuffs/ebin -pa /home/ossforum/riak-erlang-client/deps/riak_pb/ebin -pa /home/ossforum/riak-erlang-client/deps/meck/ebin

main([BucketName, NumKeys]) ->
    Host = "127.0.0.1",
    Port = 8091,

    {ok, Conn} = riakc_pb_socket:start_link(Host, Port),
    lists:foreach(fun(R_Opt) ->
                          {NumOK, NumErr} = multigets(Conn,
                                                      list_to_binary(BucketName),
                                                      list_to_integer(NumKeys),
                                                      R_Opt),
                          io:format("~p  ok: ~p  error: ~p~n", [R_Opt, NumOK, NumErr])
                  end, [{r,all}, {pr,all}]);
main(_) ->
    io:format("usage: riak-multigets.escript <bucket-name> <number-of-keys>~n").


multigets(Conn, BucketNameBin, NumKeys, R_Opt) when NumKeys > 0 ->
    multigets0(Conn, BucketNameBin, NumKeys, R_Opt, 0, 0).

multigets0(_, _, 0, _, NumOK, NumErr) ->
    {NumOK, NumErr};
multigets0(Conn, BucketNameBin, NumKeys, R_Opt, NumOK, NumErr) ->
    N = integer_to_list(NumKeys),
    case get(Conn, BucketNameBin, list_to_binary("key" ++ N), R_Opt) of
        ok ->
            multigets0(Conn, BucketNameBin, NumKeys - 1, R_Opt, NumOK + 1, NumErr);
        _ ->
            multigets0(Conn, BucketNameBin, NumKeys - 1, R_Opt, NumOK, NumErr + 1)
    end.

get(Conn, BucketName, Key, R_Opt) ->
    element(1, riakc_pb_socket:get(Conn, BucketName, Key, [R_Opt])).
