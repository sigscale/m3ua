%%% m3ua_app.erl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2015-2024 SigScale Global Inc.
%%% @end
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc This {@link //stdlib/application. application} behaviour callback
%%% 	module starts and stops the
%%% 	{@link //m3ua. m3ua} application.
%%%
-module(m3ua_app).
-copyright('Copyright (c) 2015-2024 SigScale Global Inc.').

-behaviour(application).

%% callbacks needed for application behaviour
-export([start/2, stop/1, config_change/3]).
%% optional callbacks for application behaviour
-export([prep_stop/1, start_phase/3]).
%% export the m3ua private API for installation
-export([install/0, install/1]).

-record(state, {}).

-define(WAITFORSCHEMA, 10000).
-define(WAITFORTABLES, 10000).

-include("m3ua.hrl").

%%----------------------------------------------------------------------
%%  The m3ua_app aplication callbacks
%%----------------------------------------------------------------------

-type start_type() :: normal | {takeover, node()} | {failover, node()}.
-spec start(StartType :: start_type(), StartArgs :: term()) ->
	{'ok', pid()} | {'ok', pid(), State :: #state{}}
			| {'error', Reason :: term()}.
%% @doc Starts the application processes.
%% @see //kernel/application:start/1
%% @see //kernel/application:start/2
%%
start(normal = _StartType, _Args) ->
	Tables = [m3ua_as, m3ua_asp],
	case mnesia:wait_for_tables(Tables, 60000) of
		ok ->
			start1();
		{timeout, BadTabList} ->
			case force(BadTabList) of
				ok ->
					start1();
				{error, Reason} ->
					error_logger:error_report(["m3ua application failed to start",
							{reason, Reason}, {module, ?MODULE}]),
					{error, Reason}
			end;
		{error, Reason} ->
			{error, Reason}
	end.
%% @hidden
start1() ->
	Fclean = fun() ->
			MatchHead = #m3ua_asp{fsm = '$1',  _ = '_'},
			MatchCond = [{'==', {node}, {node, '$1'}}],
			MatchBody = ['$1'],
			MatchSpec = [{MatchHead, MatchCond, MatchBody}],
			LocalPids = mnesia:select(m3ua_asp, MatchSpec, write),
			Fdel = fun(Pid) ->
						mnesia:delete(m3ua_asp, Pid, write)
			end,
			lists:foreach(Fdel, LocalPids)
	end,
	case mnesia:transaction(Fclean) of
		{atomic, ok} ->
			start2();
		{aborted, Reason} ->
			{error, Reason}
	end.
%% @hidden
start2() ->
	Node = node(),
	Filter = fun(#m3ua_as_asp{fsm = Pid}) when node(Pid) == Node ->
				false;
			(_) ->
				true
	end,
	Fold = fun(#m3ua_as{asp = ASPs} = R, Acc) ->
			case lists:filter(Filter, ASPs) of
				ASPs ->
					Acc;
				NewASPs ->
					mnesia:write(R#m3ua_as{asp = NewASPs})
			end
	end,
	Fclean = fun() ->
			mnesia:foldl(Fold, ok, m3ua_as)
	end,
	case mnesia:transaction(Fclean) of
		{atomic, ok} ->
			start3();
		{aborted, Reason} ->
			{error, Reason}
	end.
%% @hidden
start3() ->
	case supervisor:start_link({local, m3ua_sup}, m3ua_sup, []) of
		{ok, Sup} ->
			{ok, Sup};
		{error, Reason} ->
			error_logger:error_report(["m3ua application failed to start",
					{reason, Reason}, {module, ?MODULE}]),
			{error, Reason}
	end.

-spec start_phase(Phase :: atom(), StartType :: start_type(),
		PhaseArgs :: term()) -> ok | {error, Reason :: term()}.
%% @doc Called for each start phase in the application and included
%% 	applications.
%% @see //kernel/app
%%
start_phase(_Phase, _StartType, _PhaseArgs) ->
	ok.

-spec prep_stop(State :: #state{}) -> #state{}.
%% @doc Called when the application is about to be shut down,
%% 	before any processes are terminated.
%% @see //kernel/application:stop/1
%%
prep_stop(State) ->
	State.

-spec stop(State :: #state{}) -> any().
%% @doc Called after the application has stopped to clean up.
%%
stop(_State) ->
	ok.

-spec config_change(Changed :: [{Par :: atom(), Val :: atom()}],
		New :: [{Par :: atom(), Val :: atom()}],
		Removed :: [Par :: atom()]) -> ok.
%% @doc Called after a code  replacement, if there are any
%% 	changes to the configuration  parameters.
%%
config_change(_Changed, _New, _Removed) ->
	ok.

-spec install() -> Result
	when
		Result :: {ok, Tables} | {error, Reason},
		Tables :: [atom()],
		Reason :: term().
%% @equiv install([node() | nodes()])
install() ->
	Nodes = [node() | nodes()],
	install(Nodes).

-spec install(Nodes) -> Result
	when
		Nodes :: [node()],
		Result :: {ok, Tables} | {error, Reason},
		Tables :: [atom()],
		Reason :: term().
%% @doc Initialize M3UA tables.
%% 	`Nodes' is a list of the nodes where
%% 	{@link //m3ua. m3ua} tables will be replicated.
%%
%% 	If {@link //mnesia. mnesia} is not running an attempt
%% 	will be made to create a schema on all available nodes.
%% 	If a schema already exists on any node
%% 	{@link //mnesia. mnesia} will be started on all nodes
%% 	using the existing schema.
%%
%% @private
%%
install(Nodes) when is_list(Nodes) ->
	case mnesia:system_info(is_running) of
		no ->
			case mnesia:create_schema(Nodes) of
				ok ->
					error_logger:info_report("Created mnesia schema",
							[{nodes, Nodes}]),
					install1(Nodes);
				{error, {_, {already_exists, _}}} ->
						error_logger:info_report("mnesia schema already exists",
						[{nodes, Nodes}]),
					install1(Nodes);
				{error, Reason} ->
					error_logger:error_report(["Failed to create schema",
							mnesia:error_description(Reason),
							{nodes, Nodes}, {error, Reason}]),
					{error, Reason}
			end;
		_ ->
			install2(Nodes)
	end.
%% @hidden
install1([Node] = Nodes) when Node == node() ->
	case mnesia:start() of
		ok ->
			error_logger:info_msg("Started mnesia~n"),
			install2(Nodes);
		{error, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
					{error, Reason}]),
			{error, Reason}
	end;
install1(Nodes) ->
	case rpc:multicall(Nodes, mnesia, start, [], 60000) of
		{Results, []} ->
			F = fun(ok) ->
						false;
					(_) ->
						true
			end,
			case lists:filter(F, Results) of
				[] ->
					error_logger:info_report(["Started mnesia on all nodes",
							{nodes, Nodes}]),
					install2(Nodes);
				NotOKs ->
					error_logger:error_report(["Failed to start mnesia"
							" on all nodes", {nodes, Nodes}, {errors, NotOKs}]),
					{error, NotOKs}
			end;
		{Results, BadNodes} ->
			error_logger:error_report(["Failed to start mnesia"
					" on all nodes", {nodes, Nodes}, {results, Results},
					{badnodes, BadNodes}]),
			{error, {Results, BadNodes}}
	end.
%% @hidden
install2(Nodes) ->
	case mnesia:wait_for_tables([schema], ?WAITFORSCHEMA) of
		ok ->
			install3(Nodes, []);
		{error, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason};
		{timeout, Tables} ->
			error_logger:error_report(["Timeout waiting for tables",
					{tables, Tables}]),
			{error, timeout}
	end.
%% @hidden
install3(Nodes, Tables) ->
	case mnesia:create_table(m3ua_as, [{ram_copies, Nodes},
			{user_properties, [{m3ua, true}]},
			{attributes, record_info(fields, m3ua_as)},
			{index, [rk]}]) of
		{atomic, ok} ->
			error_logger:info_msg("Created new m3ua_as table.~n"),
			install4(Nodes, [m3ua_as | Tables]);
		{aborted, {not_active, _, Node} = Reason} ->
			error_logger:error_report(["Mnesia not started on node",
					{node, Node}]),
			{error, Reason};
		{aborted, {already_exists, m3ua_as}} ->
			error_logger:info_msg("Found existing m3ua_as table.~n"),
			install4(Nodes, [m3ua_as | Tables]);
		{aborted, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install4(Nodes, Tables) ->
	case mnesia:create_table(m3ua_asp, [{ram_copies, Nodes},
			{user_properties, [{m3ua, true}]},
			{attributes, record_info(fields, m3ua_asp)}]) of
		{atomic, ok} ->
			error_logger:info_msg("Created new m3ua_asp table.~n"),
			{ok, [m3ua_asp | Tables]};
		{aborted, {not_active, _, Node} = Reason} ->
			error_logger:error_report(["Mnesia not started on node",
					{node, Node}]),
			{error, Reason};
		{aborted, {already_exists, m3ua_asp}} ->
			error_logger:info_msg("Found existing m3ua_asp table.~n"),
			{ok, [m3ua_asp | Tables]};
		{aborted, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason}
	end.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

-spec force(Tables) -> Result
	when
		Tables :: [TableName],
		Result :: ok | {error, Reason},
		TableName :: atom(),
		Reason :: term().
%% @doc Try to force load bad tables.
force([H | T]) ->
	case mnesia:force_load_table(H) of
		yes ->
			force(T);
		ErrorDescription ->
			{error, ErrorDescription}
	end;
force([]) ->
	ok.

