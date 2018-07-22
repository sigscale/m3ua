%%% m3ua_mib.erl
%%% vim: ts=3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2018 SigScale Global Inc.
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc This library module implements the SNMP MIB for the
%%%     {@link //m3ua. m3ua} application.
%%%
-module(m3ua_mib).
-copyright('Copyright (c) 2018 SigScale Global Inc.').

%% export the m3ua_mib public API
-export([load/0, load/1, unload/0, unload/1]).

%% export the m3ua_mib snmp agent callbacks
-export([ep_table/3, as_table/3]).

-include("m3ua.hrl").

%%----------------------------------------------------------------------
%%  The m3ua_mib public API
%%----------------------------------------------------------------------

-spec load() -> Result
	when
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Loads the SigScale M3UA MIB.
load() ->
	case code:priv_dir(m3ua) of
		PrivDir when is_list(PrivDir) ->
			MibDir = PrivDir ++ "/mibs/",
			Mibs = [MibDir ++ MIB || MIB <- mibs()],
			snmpa:load_mibs(Mibs);
		{error, Reason} ->
			{error, Reason}
	end.

-spec load(Agent) -> Result
	when
		Agent :: pid() | atom(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Loads the SigScale M3UA MIB.
load(Agent) ->
	case code:priv_dir(m3ua) of
		PrivDir when is_list(PrivDir) ->
			MibDir = PrivDir ++ "/mibs/",
			Mibs = [MibDir ++ MIB || MIB <- mibs()],
			snmpa:load_mibs(Agent, Mibs);
		{error, Reason} ->
			{error, Reason}
	end.

-spec unload() -> Result
	when
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Unloads the SigScale M3UA MIB.
unload() ->
	snmpa:unload_mibs(mibs()).

-spec unload(Agent) -> Result
	when
		Agent :: pid() | atom(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Unloads the SigScale M3UA MIB.
unload(Agent) ->
	snmpa:unload_mibs(Agent, mibs()).

%%----------------------------------------------------------------------
%% The m3ua_mib snmp agent callbacks
%----------------------------------------------------------------------

-spec ep_table(Operation, RowIndex, Columns) -> Result
	when
		Operation :: get | get_next,
		RowIndex :: ObjectId,
		ObjectId :: [integer()],
		Columns :: [Column],
		Column :: integer(),
		Result :: [Element] | {genErr, Column},
		Element :: {value, Value} | {ObjectId, Value},
		Value :: atom() | integer() | string() | [integer()].
%% @doc Handle SNMP requests for the endpoint (EP) table.
%% @private
ep_table(get_next, [] = _RowIndex, Columns) ->
	ep_table_get_next(catch m3ua:get_ep(), 1, Columns);
ep_table(get_next, [N], Columns) ->
	ep_table_get_next(catch m3ua:get_ep(), N + 1, Columns).

-spec as_table(Operation, RowIndex, Columns) -> Result
	when
		Operation :: get | get_next,
		RowIndex :: ObjectId,
		ObjectId :: [integer()],
		Columns :: [Column],
		Column :: integer(),
		Result :: [Element] | {genErr, Column},
		Element :: {value, Value} | {ObjectId, Value},
		Value :: atom() | integer() | string() | [integer()].
%% @doc Handle SNMP requests for the application server (AS) table.
%% @private
as_table(get_next, [] = _RowIndex, Columns) ->
	as_table_get_next(m3ua:get_as(), 1, Columns);
as_table(get_next, [N], Columns) ->
	as_table_get_next(m3ua:get_as(), N + 1, Columns).

%%----------------------------------------------------------------------
%% internal functions
%----------------------------------------------------------------------

%% @hidden
mibs() ->
	["SIGSCALE-M3UA-MIB"].

%% @hidden
ep_table_get_next(EPs, Index, Columns) when length(EPs) >= Index ->
	EP = lists:nth(Index, EPs),
	ep_table_get_next(EPs, catch m3ua:get_ep(EP), Index, Columns, []);
ep_table_get_next(EPs, _Index, Columns) when is_list(EPs) ->
	F = fun(N) -> N + 1 end,
	NextColumns = lists:map(F, Columns),
	ep_table_get_next(EPs, 1, NextColumns);
ep_table_get_next({'EXIT', _Reason}, _, _) ->
	{genErr, 0}.
%% @hidden
ep_table_get_next(EPs, EP, Index, [0 | T], Acc) when is_tuple(EP) ->
	ep_table_get_next(EPs, EP, Index, T, [{[1, Index], Index} | Acc]);
ep_table_get_next(EPs, EP, Index, [1 | T], Acc) when is_tuple(EP) ->
	ep_table_get_next(EPs, EP, Index, T, [{[1, Index], Index} | Acc]);
ep_table_get_next(EPs, {server, _, _} = EP, Index, [2 | T], Acc) ->
	ep_table_get_next(EPs, EP, Index, T, [{[2, Index], 1} | Acc]);
ep_table_get_next(EPs, {client, _, _, _} = EP, Index, [2 | T], Acc) ->
	ep_table_get_next(EPs, EP, Index, T, [{[2, Index], 2} | Acc]);
ep_table_get_next(EPs, EP, Index, [3 | T], Acc) ->
	case element(3, EP) of
		{Address, _} when size(Address) == 4 ->
			ep_table_get_next(EPs, EP, Index, T, [{[3, Index], ipv4} | Acc]);
		{Address, _} when size(Address) == 8 ->
			ep_table_get_next(EPs, EP, Index, T, [{[3, Index], ipv6} | Acc])
	end;
ep_table_get_next(EPs, EP, Index, [4 | T], Acc) ->
	{Address, _} = element(3, EP),
	Value = tuple_to_list(Address),
	ep_table_get_next(EPs, EP, Index, T, [{[4, Index], Value} | Acc]);
ep_table_get_next(EPs, EP, Index, [5 | T], Acc) ->
	{_, Port} = element(3, EP),
	ep_table_get_next(EPs, EP, Index, T, [{[5, Index], Port} | Acc]);
ep_table_get_next(EPs, {client, _, _, {Address, _}} = EP,
		Index, [6 | T], Acc) when size(Address) == 4 ->
	ep_table_get_next(EPs, EP, Index, T, [{[6, Index], ipv4} | Acc]);
ep_table_get_next(EPs, {client, _, _, {Address, _}} = EP,
		Index, [6 | T], Acc) when size(Address) == 8 ->
	ep_table_get_next(EPs, EP, Index, T, [{[6, Index], ipv6} | Acc]);
ep_table_get_next(EPs, {client, _, _, {Address, _}} = EP,
		Index, [7 | T], Acc) ->
	Value = tuple_to_list(Address),
	ep_table_get_next(EPs, EP, Index, T, [{[7, Index], Value} | Acc]);
ep_table_get_next(EPs, {client, _, _, {_, Port}} = EP, Index, [8 | T], Acc) ->
	ep_table_get_next(EPs, EP, Index, T, [{[8, Index], Port} | Acc]);
ep_table_get_next(EPs, {server, _, _} = EP, Index, [N | T], Acc)
		when N >= 6, N =< 8 ->
	case ep_table_get_next(EPs, Index + 1, [N]) of
		[NextResult] ->
			ep_table_get_next(EPs, EP, Index, T, [NextResult | Acc]);
		{genErr, C} ->
			{genErr, C}
	end;
ep_table_get_next(EPs, EP, Index, [9 | T], Acc) when element(2, EP) == sgp ->
	ep_table_get_next(EPs, EP, Index, T, [{[9, Index], sgp} | Acc]);
ep_table_get_next(EPs, EP, Index, [9 | T], Acc) when element(2, EP) == asp ->
	ep_table_get_next(EPs, EP, Index, T, [{[9, Index], asp} | Acc]);
ep_table_get_next(EPs, EP, Index, [9 | T], Acc) when element(2, EP) == ipsp ->
	ep_table_get_next(EPs, EP, Index, T, [{[9, Index], ipsp} | Acc]);
ep_table_get_next(EPs, EP, Index, [N | T], Acc) when N > 9 ->
	ep_table_get_next(EPs, EP, Index, T, [endOfTable | Acc]);
ep_table_get_next(_, _, _, [], Acc) ->
	lists:reverse(Acc);
ep_table_get_next(_, {'EXIT', _Reason}, _, _, _) ->
	{genErr, 0}.

%% @hidden
as_table_get_next({ok, ASs}, Index, Columns) when length(ASs) >= Index ->
	as_table_get_next(ASs, lists:nth(Index, ASs), Index, Columns, []);
as_table_get_next({ok, ASs}, _Index, Columns) ->
	F = fun(N) -> N + 1 end,
	NextColumns = lists:map(F, Columns),
	as_table_get_next({ok, ASs}, 1, NextColumns);
as_table_get_next({error, _Reason}, _, _) ->
	{genErr, 0}.
%% @hidden
as_table_get_next(ASs, AS, Index, [N | T], Acc) when N == 0; N == 1 ->
	as_table_get_next(ASs, AS, Index, T, [{[1, Index], Index} | Acc]);
as_table_get_next(ASs, AS, Index, [2 | T], Acc) ->
	as_table_get_next(ASs, AS, Index, T, [{[2, Index], element(7, AS)} | Acc]);
as_table_get_next(ASs, AS, Index, [3 | T], Acc) ->
	as_table_get_next(ASs, AS, Index, T, [{[3, Index], element(4, AS)} | Acc]);
as_table_get_next(ASs, {Name, _, _, _, _, _, _} = AS, Index, [4 | T], Acc)
		when is_atom(Name) ->
	Value = atom_to_list(Name),
	as_table_get_next(ASs, AS, Index, T, [{[4, Index], Value} | Acc]);
as_table_get_next(ASs, {Name, _, _, _, _, _, _} = AS, Index, [4 | T], Acc)
		when is_list(Name) ->
	case catch unicode:characters_to_list(list_to_binary(Name), utf8) of
		Value when is_list(Value) ->
			as_table_get_next(ASs, AS, Index, T, [{[4, Index], Value} | Acc]);
		_ ->
			case as_table_get_next({ok, ASs}, Index + 1, [4]) of
				[NextResult] ->
					as_table_get_next(ASs, AS, Index, T, [NextResult | Acc]);
				{genErr, C} ->
					{genErr, C}
			end
	end;
as_table_get_next(ASs, {Name, _, _, _, _, _, _} = AS, Index, [4 | T], Acc)
		when is_integer(Name) ->
	Value = integer_to_list(Name),
	as_table_get_next(ASs, AS, Index, T, [{[4, Index], Value} | Acc]);
as_table_get_next(ASs, AS, Index, [4 | T], Acc) ->
	case as_table_get_next({ok, ASs}, Index + 1, [4]) of
		[NextResult] ->
			as_table_get_next(ASs, AS, Index, T, [NextResult | Acc]);
		{genErr, C} ->
			{genErr, C}
	end;
as_table_get_next(ASs, AS, Index, [N | T], Acc) when N > 4 ->
	as_table_get_next(ASs, AS, Index, T, [endOfTable | Acc]);
as_table_get_next(_, _, _, [], Acc) ->
	lists:reverse(Acc).

