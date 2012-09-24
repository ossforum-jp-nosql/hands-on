%%%-------------------------------------------------------------------
%%% Copyright (c) 2012 Cloudian, KK & Inc.  All rights reserved.
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%-------------------------------------------------------------------

-module(hibari_client_utils).

-export([connect/1,
         wait_for_tables/2,
         go_async/2,
         go_sync/2,
         checkpoint/2
        ]).

-export([start_net_kernel/1,
         set_cookie/2,
         ping/1
        ]).

-define(RPC_TIMEOUT, 15000).

%% ====================================================================
%% API
%% ====================================================================

%% TODO: Use erlando
connect(HibariAdmin) ->
    case start_app(sasl) of
        ok ->
            case start_app(gmt_util) of
                ok ->
                    case start_app(gdss_client) of
                        ok ->
                            add_client_monitor(HibariAdmin, node());
                        Err1 ->
                            Err1
                    end;
                Err2 ->
                    Err2
            end;
        Err3 ->
            Err3
    end.

wait_for_tables(HibariAdmin, Tables) ->
    [ ok = gmt_loop:do_while(fun poll_table/1, {HibariAdmin, not_ready, Tab})
      || {Tab,_,_} <- Tables ],
    ok.

go_async(HibariAdmin, Table) ->
    go_sync(HibariAdmin, Table, false).

go_sync(HibariAdmin, Table) ->
    go_sync(HibariAdmin, Table, true).

checkpoint(HibariAdmin, Table) ->
    [rpc(Node, brick_server, checkpoint, [Brick, Node])
     || {Brick, Node} <- running_bricks(HibariAdmin, Table)].

start_net_kernel(Node) ->
    case net_kernel:start(Node) of
        {ok, _} ->
            ok;
        {error, {already_started, _}} ->
            ok;
        {error, {{already_started, _}, _}} ->
            ok;
        {error, Reason}=Result ->
            io:format("Failed to start net_kernel for ~p: ~p\n", [?MODULE, Reason]),
            Result
    end.

set_cookie(HibariNodes, Cookie) ->
    [ erlang:set_cookie(Node, Cookie) || Node <- HibariNodes ],
    ok.

ping(Node) ->
    case net_adm:ping(Node) of
        pong ->
            ok;
        pang ->
            io:format("Failed to ping node ~p\n", [Node]),
            halt(1)
    end.


%% ====================================================================
%% Internal functions
%% ====================================================================

add_client_monitor(HibariAdmin, ClientNode) ->
    rpc(HibariAdmin, brick_admin, add_client_monitor, [ClientNode]).

%% delete_client_monitor(HibariAdmin, ClientNode) ->
%%     rpc(HibariAdmin, brick_admin, delete_client_monitor, [ClientNode]).

poll_table({HibariAdmin,not_ready,Tab} = T) ->
    TabCh = gmt_util:atom_ify(gmt_util:list_ify(Tab) ++ "_ch1"),
    case rpc(HibariAdmin, brick_sb, get_status, [chain, TabCh]) of
        {ok, healthy} ->
            {false, ok};
        _ ->
            ok = timer:sleep(50),
            {true, T}
    end.

%% table_exists(HibariAdmin, Table) ->
%%     case rpc(HibariAdmin, brick_admin, get_table_info, [Table]) of
%%         {ok, _} ->
%%             ok;
%%         error ->
%%             io:format("Table '~p' does not exist on Hibari ~p.\n",
%%                       [Table, HibariAdmin]),
%%             halt(1)
%%     end.

go_sync(HibariAdmin, Table, Bool) ->
    [rpc(Node, brick_server, set_do_sync, [{Brick, Node}, Bool])
     || {Brick, Node} <- running_bricks(HibariAdmin, Table)],
    SyncStatus = get_sync_properties(HibariAdmin, Table),
    Result = lists:foldl(fun(Status, Acc) ->
                                 Status =:= Bool andalso Acc
                         end,
                         true,
                         SyncStatus),
    case Result of
        true ->
            ok;
        false ->
            {error, SyncStatus}
    end.

get_sync_properties(HibariAdmin, Table) ->
    BrickStatusList = [rpc(Node, brick_server, status, [Brick, Node])
                       || {Brick, Node} <- running_bricks(HibariAdmin, Table)],
    lists:map(fun({ok, BrickStatus}) ->
                      BrickImpl = proplists:get_value(implementation, BrickStatus, undefined),
                      proplists:get_value(do_sync, BrickImpl, undefined)
              end,
              BrickStatusList).

running_bricks(HibariAdmin, Table) ->
    {ok, Properties} = rpc(HibariAdmin, brick_admin, get_table_info,
                        [{global, brick_admin}, Table]),
    GHash = proplists:get_value(ghash, Properties),
    Chains = lists:usort(brick_hash:all_chains(GHash, current)
                         ++
                         brick_hash:all_chains(GHash, new)),
    [Brick || {_Chain, Bricks} <- Chains, Brick <- Bricks].


start_app(App) when is_atom(App) ->
    case application:start(App) of
        ok ->
            ok;
        {error, {already_started, App}} ->
            ok;
        {error, Reason}=Result ->
            io:format("Failed to start ~p for ~p: ~p\n", [App, ?MODULE, Reason]),
            Result
    end.

rpc(Node, M, F, A) ->
    case rpc:call(Node, M, F, A, ?RPC_TIMEOUT) of
        {badrpc, Reason} ->
            io:format("RPC(~p:~p:~p) to ~p failed: ~p\n", [M, F, A, Node, Reason]),
            halt(1);
        Reply ->
            Reply
    end.
