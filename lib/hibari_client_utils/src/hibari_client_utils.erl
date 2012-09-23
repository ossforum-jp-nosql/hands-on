%%%-------------------------------------------------------------------
%%% Copyright (c) 2012 Clodian, KK & Inc.  All rights reserved.
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

-export([hibari_init/2,
         wait_for_tables/2,
         go_async/2,
         go_sync/2,
         checkpoint/2
        ]).

-export([start_net_kernel/1,
         ping/1
        ]).

-define(RPC_TIMEOUT, 15000).

%% ====================================================================
%% API
%% ====================================================================

%% TODO: Use erlando
hibari_init(Table, HibariNode) ->
    case start_app(sasl) of
        ok ->
            case start_app(gmt_util) of
                ok ->
                    case start_app(gdss_client) of
                        ok ->
                            case add_client_monitor(HibariNode, node()) of
                                ok ->
                                    wait_for_tables(HibariNode, [Table]),
                                    table_exists(HibariNode, Table);
                                Err1 ->
                                    Err1
                            end;
                        Err2 ->
                            Err2
                    end;
                Err3 ->
                    Err3
            end;
        Err4 ->
            Err4
    end.

wait_for_tables(GDSSAdmin, Tables) ->
    [ ok = gmt_loop:do_while(fun poll_table/1, {GDSSAdmin,not_ready,Tab})
      || {Tab,_,_} <- Tables ],
    ok.

go_async(GDSSAdmin, Table) ->
    go_sync(GDSSAdmin, Table, false).

go_sync(GDSSAdmin, Table) ->
    go_sync(GDSSAdmin, Table, true).

checkpoint(GDSSAdmin, Table) ->
    [rpc(Node, brick_server, checkpoint, [Brick, Node])
     || {Brick, Node} <- running_bricks(GDSSAdmin, Table)].

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

add_client_monitor(HibariNode, ClientNode) ->
    rpc(HibariNode, brick_admin, add_client_monitor, [ClientNode]).

%% delete_client_monitor(HibariNode, ClientNode) ->
%%     rpc(HibariNode, brick_admin, delete_client_monitor, [ClientNode]).

poll_table({GDSSAdmin,not_ready,Tab} = T) ->
    TabCh = gmt_util:atom_ify(gmt_util:list_ify(Tab) ++ "_ch1"),
    case rpc(GDSSAdmin, brick_sb, get_status, [chain, TabCh]) of
        {ok, healthy} ->
            {false, ok};
        _ ->
            ok = timer:sleep(50),
            {true, T}
    end.

table_exists(HibariNode, Table) ->
    case rpc(HibariNode, brick_admin, get_table_info, [Table]) of
        {ok, _} ->
            ok;
        error ->
            io:format("Table '~p' does not exist on Hibari ~p.\n",
                      [Table, HibariNode]),
            halt(1)
    end.

go_sync(GDSSAdmin, Table, Bool) ->
    [rpc(Node, brick_server, set_do_sync, [{Brick, Node}, Bool])
     || {Brick, Node} <- running_bricks(GDSSAdmin, Table)],
    SyncStatus = get_sync_properties(GDSSAdmin, Table),
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

get_sync_properties(GDSSAdmin, Table) ->
    BrickStatusList = [rpc(Node, brick_server, status, [Brick, Node])
                       || {Brick, Node} <- running_bricks(GDSSAdmin, Table)],
    lists:map(fun({ok, BrickStatus}) ->
                      BrickImpl = proplists:get_value(implementation, BrickStatus, undefined),
                      proplists:get_value(do_sync, BrickImpl, undefined)
              end,
              BrickStatusList).

running_bricks(GDSSAdmin, Table) ->
    {ok, Properties} = rpc(GDSSAdmin, brick_admin, get_table_info,
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
