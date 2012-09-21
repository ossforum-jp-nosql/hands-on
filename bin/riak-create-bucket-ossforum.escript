#!/usr/bin/env escript
%% -*- mode:erlang; coding:utf-8 -*-
%%! -smp enable -name riak_client@127.0.0.1 -pz /home/tatsuya/nosql2/riak/deps/riak_core/ebin -pz /home/tatsuya/nosql2/riak/deps/riak_kv/ebin

main(_Args) ->
    BucketNames = [<<"b1">>, <<"basho_bench_test">>],
    RiakNodes = ['riak1@127.0.0.1','riak2@127.0.0.1','riak3@127.0.0.1'],
    BucketProps = [{n_val, 3}, %% Number of replicas.
		   {r, quorum},
		   {w, quorum},
		   {dw, quorum}],

    Client = init_client(RiakNodes),
    [ case bucket_exists(Client, BucketName) of
          true ->
              io:format("Bucket ~p already exists on nodes ~p.~n",
                        [BucketName, RiakNodes]);
          false ->
              create_bucket(Client, BucketName, BucketProps)
      end
      || BucketName <- BucketNames ].

init_client(Nodes) ->
    Cookie = 'riak',
    [ erlang:set_cookie(N, Cookie) || N <- Nodes ],
    case riak:client_connect(hd(Nodes)) of
        {ok, Client} ->
            Client;
        {error, Reason} ->
            io:format("Failed get a riak:client_connect to ~p: ~p\n",
                      [hd(Nodes), Reason]),
	    halt(1)
    end.

bucket_exists(Client, BucketName) ->
    case Client:list_buckets() of
	{ok, []} ->
	    false;
	{ok, Buckets} ->
	    lists:member(BucketName, Buckets);
	{error, _Error} ->
	    false
    end.

create_bucket(Client, BucketName, BucketProps) ->
    %% Put an object to create a bucket.
    Key = <<"dummy">>,
    RObj = riak_object:new(BucketName, Key, <<"">>),
    ok = Client:put(RObj),

    %% Set the bucket properties
    ok = Client:set_bucket(BucketName, BucketProps),

    %% Display the basic bucket properties
    io:format("Created ~p~n", [basic_bucket_info(Client:get_bucket(BucketName))]),
    ok.

basic_bucket_info(BucketProps) ->
    Name  = proplists:get_value(name, BucketProps),
    N_Val = proplists:get_value(n_val, BucketProps),
    R     = proplists:get_value(r, BucketProps),
    W     = proplists:get_value(w, BucketProps),
    DW    = proplists:get_value(dw, BucketProps),
    {Name,
     {n_val, N_Val},
     {r, R},
     {w, W},
     {dw, DW}
    }.

%% [{name,test},
%%  {n_val,3},
%%  {rw,quorum},
%%  {r,quorum},
%%  {w,quorum},
%%  {dw,quorum},
%%  {allow_mult,false},
%%  {basic_quorum,false},
%%  {big_vclock,50},
%%  {chash_keyfun,{riak_core_util,chash_std_keyfun}},
%%  {last_write_wins,false},
%%  {linkfun,{modfun,riak_kv_wm_link_walker,mapreduce_linkfun}},
%%  {notfound_ok,true},
%%  {old_vclock,86400},
%%  {postcommit,[]},
%%  {pr,0},
%%  {precommit,[]},
%%  {pw,0},
%%  {small_vclock,50},
%%  {young_vclock,20}]
