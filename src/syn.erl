%% ==========================================================================================================
%% Syn - A global Process Registry and Process Group manager.
%%
%% The MIT License (MIT)
%%
%% Copyright (c) 2015-2021 Roberto Ostinelli <roberto@ostinelli.net> and Neato Robotics, Inc.
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%% ==========================================================================================================
-module(syn).

%% API
-export([start/0, stop/0]).
%% scopes
-export([get_node_scopes/0, add_node_to_scope/1, add_node_to_scopes/1]).
-export([set_event_handler/1]).
%% registry
-export([lookup/1, lookup/2]).
-export([register/2, register/3, register/4]).
-export([unregister/1, unregister/2]).
-export([registry_count/1, registry_count/2]).
%% gen_server via interface
-export([register_name/2, unregister_name/1, whereis_name/1, send/2]).
%% groups
-export([get_members/1, get_members/2]).
-export([get_local_members/1, get_local_members/2]).
-export([join/2, join/3, join/4]).
-export([leave/2, leave/3]).
-export([groups_count/1, groups_count/2]).

%% ===================================================================
%% API
%% ===================================================================
-spec start() -> ok.
start() ->
    {ok, _} = application:ensure_all_started(syn),
    ok.

-spec stop() -> ok | {error, Reason :: any()}.
stop() ->
    application:stop(syn).

%% ----- \/ scopes ---------------------------------------------------
-spec get_node_scopes() -> [atom()].
get_node_scopes() ->
    syn_sup:get_node_scopes().

-spec add_node_to_scope(Scope :: atom()) -> ok.
add_node_to_scope(Scope) ->
    syn_sup:add_node_to_scope(Scope).

-spec add_node_to_scopes(Scopes :: [atom()]) -> ok.
add_node_to_scopes(Scopes) ->
    lists:foreach(fun(Scope) ->
        syn_sup:add_node_to_scope(Scope)
    end, Scopes).

-spec set_event_handler(module()) -> ok.
set_event_handler(Module) ->
    application:set_env(syn, event_handler, Module).

%% ----- \/ registry -------------------------------------------------
-spec lookup(Name :: any()) -> {pid(), Meta :: any()} | undefined.
lookup(Name) ->
    syn_registry:lookup(Name).

-spec lookup(Scope :: atom(), Name :: any()) -> {pid(), Meta :: any()} | undefined.
lookup(Scope, Name) ->
    syn_registry:lookup(Scope, Name).

-spec register(Name :: any(), Pid :: pid()) -> ok | {error, Reason :: any()}.
register(Name, Pid) ->
    syn_registry:register(Name, Pid).

-spec register(NameOrScope :: any(), PidOrName :: any(), MetaOrPid :: any()) -> ok | {error, Reason :: any()}.
register(NameOrScope, PidOrName, MetaOrPid) ->
    syn_registry:register(NameOrScope, PidOrName, MetaOrPid).

-spec register(Scope :: atom(), Name :: any(), Pid :: pid(), Meta :: any()) -> ok | {error, Reason :: any()}.
register(Scope, Name, Pid, Meta) ->
    syn_registry:register(Scope, Name, Pid, Meta).

-spec unregister(Name :: any()) -> ok | {error, Reason :: any()}.
unregister(Name) ->
    syn_registry:unregister(Name).

-spec unregister(Scope :: atom(), Name :: any()) -> ok | {error, Reason :: any()}.
unregister(Scope, Name) ->
    syn_registry:unregister(Scope, Name).

-spec registry_count(Scope :: atom()) -> non_neg_integer().
registry_count(Scope) ->
    syn_registry:count(Scope).

-spec registry_count(Scope :: atom(), Node :: node()) -> non_neg_integer().
registry_count(Scope, Node) ->
    syn_registry:count(Scope, Node).

%% ----- \/ gen_server via module interface --------------------------
-spec register_name(Name :: any(), Pid :: pid()) -> yes | no.
register_name(Name, Pid) ->
    case syn_registry:register(Name, Pid) of
        ok -> yes;
        _ -> no
    end.

-spec unregister_name(Name :: any()) -> any().
unregister_name(Name) ->
    case syn_registry:unregister(Name) of
        ok -> Name;
        _ -> nil
    end.

-spec whereis_name(Name :: any()) -> pid() | undefined.
whereis_name(Name) ->
    case syn_registry:lookup(Name) of
        {Pid, _Meta} -> Pid;
        undefined -> undefined
    end.

-spec send(Name :: any(), Message :: any()) -> pid().
send(Name, Message) ->
    case whereis_name(Name) of
        undefined ->
            {badarg, {Name, Message}};
        Pid ->
            Pid ! Message,
            Pid
    end.

%% ----- \/ groups ---------------------------------------------------
-spec get_members(GroupName :: term()) -> [{Pid :: pid(), Meta :: term()}].
get_members(GroupName) ->
    syn_groups:get_members(GroupName).

-spec get_members(Scope :: atom(), GroupName :: term()) -> [{Pid :: pid(), Meta :: term()}].
get_members(Scope, GroupName) ->
    syn_groups:get_members(Scope, GroupName).

-spec get_local_members(GroupName :: term()) -> [{Pid :: pid(), Meta :: term()}].
get_local_members(GroupName) ->
    syn_groups:get_local_members(GroupName).

-spec get_local_members(Scope :: atom(), GroupName :: term()) -> [{Pid :: pid(), Meta :: term()}].
get_local_members(Scope, GroupName) ->
    syn_groups:get_local_members(Scope, GroupName).

-spec join(GroupName :: any(), Pid :: pid()) -> ok | {error, Reason :: any()}.
join(GroupName, Pid) ->
    syn_groups:join(GroupName, Pid).

-spec join(GroupNameOrScope :: any(), PidOrGroupName :: any(), MetaOrPid :: any()) -> ok | {error, Reason :: any()}.
join(GroupNameOrScope, PidOrGroupName, MetaOrPid) ->
    syn_groups:join(GroupNameOrScope, PidOrGroupName, MetaOrPid).

-spec join(Scope :: atom(), GroupName :: any(), Pid :: pid(), Meta :: any()) -> ok | {error, Reason :: any()}.
join(Scope, GroupName, Pid, Meta) ->
    syn_groups:join(Scope, GroupName, Pid, Meta).

-spec leave(GroupName :: any(), Pid :: pid()) -> ok | {error, Reason :: any()}.
leave(GroupName, Pid) ->
    syn_groups:leave(GroupName, Pid).

-spec leave(Scope :: atom(), GroupName :: any(), Pid :: pid()) -> ok | {error, Reason :: any()}.
leave(Scope, GroupName, Pid) ->
    syn_groups:leave(Scope, GroupName, Pid).

-spec groups_count(Scope :: atom()) -> non_neg_integer().
groups_count(Scope) ->
    syn_groups:count(Scope).

-spec groups_count(Scope :: atom(), Node :: node()) -> non_neg_integer().
groups_count(Scope, Node) ->
    syn_groups:count(Scope, Node).
