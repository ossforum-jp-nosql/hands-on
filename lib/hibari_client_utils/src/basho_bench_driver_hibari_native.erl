%%%-------------------------------------------------------------------
%%% Copyright (c) 2012 Cloudian, KK & Inc.  All rights reserved.
%%% Copyright (c) 2008-2011 Gemini Mobile Technologies, Inc.  All rights reserved.
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

-module(basho_bench_driver_hibari_native).

-export([init/0,
         new/1,
         run/4,
         terminate/2]).

-include("basho_bench.hrl").

-record(state, { id, table }).

%% ====================================================================
%% API
%% ====================================================================

new(Id) ->
    if Id =:= 1 -> init();
       true     -> ok
    end,
    Table  = basho_bench_config:get(hibari_table, tab1),
    {ok, #state { id = Id, table = Table }}.

run(get, KeyGen, _ValGen, #state{table=Table}=State) ->
    case brick_simple:get(Table, KeyGen()) of
        {ok, _TS, _Val} ->
            {ok, State};
        key_not_exist ->
            {ok, State};
        {error, Reason} ->
            {error, Reason, State}
    end;
run(put, KeyGen, ValGen, #state{table=Table}=State) ->
    case brick_simple:set(Table, KeyGen(), ValGen()) of
        ok ->
            {ok, State};
        Reason ->
            {error, Reason, State}
    end;
run(delete, KeyGen, _ValGen, #state{table=Table}=State) ->
    case brick_simple:delete(Table, KeyGen()) of
        ok ->
            {ok, State};
        key_not_exist ->
            {ok, State};
        {error, Reason} ->
            {error, Reason, State}
    end.

terminate({'EXIT', Reason}, #state{id=Id}) ->
    ?WARN("Worker ~p crashed: ~p~n", [Id, Reason]),
    ok;
terminate(normal, _) ->
    ok.


%% ====================================================================
%% Private Functions
%% ====================================================================

init() ->
    MyNode  = basho_bench_config:get(hibari_mynode, [basho_bench, shortnames]),
    ok = hibari_client_utils:start_net_kernel(MyNode),

    HibariAdminNode = basho_bench_config:get(hibari_node, 'hibari1@127.0.0.1'),
    HibariNodes = ['hibari1@127.0.0.1', 'hibari2@127.0.0.1', 'hibari3@127.0.0.1'],

    Table  = basho_bench_config:get(hibari_table, tab1),
    Cookie = 'hibari',
    hibari_client_utils:set_cookie(HibariNodes, Cookie),
    hibari_client_utils:connect(HibariAdminNode),
    hibari_client_utils:wait_for_tables(HibariAdminNode, [Table]).

