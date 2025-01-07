%%% m3ua_mib.erl
%%% vim: ts=3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2018-2025 SigScale Global Inc.
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
-copyright('Copyright (c) 2018-2025 SigScale Global Inc.').

%% export the m3ua_mib public API
-export([load/0, load/1, unload/0, unload/1]).

%% export the m3ua_mib snmp agent callbacks
-export([ep_table/3, as_table/3, asp_sgp_table/3, asp_stat_table/3]).

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
ep_table(get, RowIndex, Columns) ->
	ep_table_get(catch m3ua:get_ep(), RowIndex, Columns);
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
as_table(get, RowIndex, Columns) ->
	as_table_get(m3ua:get_as(), RowIndex, Columns);
as_table(get_next, [] = _RowIndex, Columns) ->
	as_table_get_next(m3ua:get_as(), 1, Columns);
as_table(get_next, [N], Columns) ->
	as_table_get_next(m3ua:get_as(), N + 1, Columns).

-spec asp_sgp_table(Operation, RowIndex, Columns) -> Result
	when
		Operation :: get | get_next,
		RowIndex :: ObjectId,
		ObjectId :: [integer()],
		Columns :: [Column],
		Column :: integer(),
		Result :: [Element] | {genErr, Column},
		Element :: {value, Value} | {ObjectId, Value},
		Value :: atom() | integer() | string() | [integer()].
%% @doc Handle SNMP requests for the ASP/SGP table.
%% @private
asp_sgp_table(get, [AsIndex, AspIndex] = _RowIndex, Columns) ->
	F = fun() ->
		case mnesia:all_keys(m3ua_as) of
			Keys when length(Keys) >= AsIndex, AsIndex > 0 ->
				mnesia:read(m3ua_as, lists:nth(AsIndex, Keys));
			_Keys ->
				mnesia:abort(noSuchInstance)
		end
	end,
	case mnesia:transaction(F) of
		{atomic, [#m3ua_as{name = Name, asp = ASPs}]} ->
         States = [State || #m3ua_as_asp{state = State} <- ASPs],
			asp_sgp_table_get({Name, States}, AspIndex, Columns, []);
		{aborted, noSuchInstance} ->
			{noValue, noSuchInstance};
		{aborted, _Reason} ->
			genErr
	end;
asp_sgp_table(get_next, [] = _RowIndex, Columns) ->
	asp_sgp_table(get_next, [1, 0], Columns);
asp_sgp_table(get_next, [AsIndex, AspIndex], Columns) ->
	F = fun() ->
		mnesia:all_keys(m3ua_as)
	end,
	case mnesia:transaction(F) of
		{atomic, Keys} ->
			asp_sgp_table_get_next(Keys, AsIndex, AspIndex + 1, Columns);
		{aborted, _Reason} ->
			{genErr, hd(Columns)}
	end.

-spec asp_stat_table(Operation, RowIndex, Columns) -> Result
	when
		Operation :: get | get_next,
		RowIndex :: ObjectId,
		ObjectId :: [integer()],
		Columns :: [Column],
		Column :: integer(),
		Result :: [Element] | {genErr, Column} | genErr,
		Element :: {value, Value} | {ObjectId, Value},
		Value :: atom() | integer() | string() | [integer()].
%% @doc Handle SNMP requests for the ASP statistics table.
%% @private
asp_stat_table(get, [N] = _RowIndex, Columns) ->
	case catch m3ua:get_assoc() of
		ASPs when is_list(ASPs) ->
			case lists:keyfind(N, 2, ASPs) of
				{EP, Assoc} ->
					case m3ua:getcount(EP, Assoc) of
						{ok, Counts} ->
							asp_stat_table_get(Counts, Columns, []);
						{error, _Reason} ->
							genErr
					end;
				false ->
					{noValue, noSuchInstance}
			end;
		{'EXIT', _Reason} ->
			genErr
	end;
asp_stat_table(get_next, [] = _RowIndex, Columns) ->
	asp_stat_table(get_next, [0], Columns);
asp_stat_table(get_next, [N], [C | _] = Columns)
		when C =< 14 ->
	case catch m3ua:get_assoc() of
		[] ->
			[endOfTable || _ <- Columns];
		ASPs when is_list(ASPs) ->
			F1 = fun({_, A}) when A < (N + 1)->
						true;
					(_) ->
						false
			end,
			case lists:dropwhile(F1, lists:keysort(2, ASPs)) of
				[{EP, Assoc} | _] ->
					case m3ua:getcount(EP, Assoc) of
						{ok, Counts} ->
							asp_stat_table_get_next(Counts, Assoc, Columns, []);
						{error, _Reason} ->
							genErr
					end;
				[] ->
					F2 = fun(X) -> X + 1 end,
					NextColumns = lists:map(F2, Columns),
					asp_stat_table(get_next, [1], NextColumns)
			end;
		{'EXIT', _Reason} ->
			genErr
	end;
asp_stat_table(get_next, _, Columns) ->
	[endOfTable || _ <- Columns].

%%----------------------------------------------------------------------
%% internal functions
%----------------------------------------------------------------------

%% @hidden
mibs() ->
	["SIGSCALE-M3UA-MIB"].

-spec ep_table_get(EPs, Index, Columns) -> Result
	when
		EPs :: [pid()],
		Index :: pos_integer(),
		Columns :: [Column],
		Column :: non_neg_integer(),
		Result :: [Element] | {noValue, noSuchInstance} | genErr,
		Element :: {value, Value} | {noValue, noSuchInstance},
		Value :: atom() | integer() | string() | [integer()].
%% @hidden
ep_table_get(EPs, [Index], Columns)
		when length(EPs) >= Index, Index > 0 ->
	EP = lists:nth(Index, EPs),
	ep_table_get1(catch m3ua:get_ep(EP), Columns, []);
ep_table_get(EPs, _Index, _Columns) when is_list(EPs) ->
	{noValue, noSuchInstance};
ep_table_get({'EXIT', _Reason}, _, _) ->
	genErr.
%% @hidden
ep_table_get1({_, server, _, _} = EP, [2 | T], Acc) ->
	ep_table_get1(EP, T, [{value, 1} | Acc]);
ep_table_get1({_, client, _, _, _} = EP, [2 | T], Acc) ->
	ep_table_get1(EP, T, [{value, 2} | Acc]);
ep_table_get1(EP, [3 | T], Acc) when is_tuple(EP) ->
	case element(4, EP) of
		{Address, _} when size(Address) == 4 ->
			ep_table_get1(EP, T, [{value, ipv4} | Acc]);
		{Address, _} when size(Address) == 8 ->
			ep_table_get1(EP, T, [{value, ipv6} | Acc])
	end;
ep_table_get1(EP, [4 | T], Acc) when is_tuple(EP) ->
	{Address, _} = element(4, EP),
	Value = tuple_to_list(Address),
	ep_table_get1(EP, T, [{value, Value} | Acc]);
ep_table_get1(EP, [5 | T], Acc) when is_tuple(EP) ->
	{_, Port} = element(4, EP),
	ep_table_get1(EP, T, [{value, Port} | Acc]);
ep_table_get1({_, client, _, _, {Address, _}} = EP,
		[6 | T], Acc) when size(Address) == 4 ->
	ep_table_get1(EP, T, [{value, ipv4} | Acc]);
ep_table_get1({_, client, _, _, {Address, _}} = EP,
		[6 | T], Acc) when size(Address) == 8 ->
	ep_table_get1(EP, T, [{value, ipv6} | Acc]);
ep_table_get1({_, client, _, _, {Address, _}} = EP,
		[7 | T], Acc) ->
	Value = tuple_to_list(Address),
	ep_table_get1(EP, T, [{value, Value} | Acc]);
ep_table_get1({_, client, _, _, {_, Port}} = EP,
		[8 | T], Acc) ->
	ep_table_get1(EP, T, [{value, Port} | Acc]);
ep_table_get1({_, server, _, _} = EP, [N | T], Acc)
		when N >= 6, N =< 8 ->
	ep_table_get1(EP, T, [{noValue, noSuchInstance} | Acc]);
ep_table_get1(EP, [9 | T], Acc) when is_tuple(EP) ->
	ep_table_get1(EP, T, [{value, element(3, EP)} | Acc]);
ep_table_get1(EP, [_N | T], Acc) when is_tuple(EP) ->
	ep_table_get1(EP, T, [{noValue, noSuchInstance} | Acc]);
ep_table_get1(EP, [], Acc) when is_tuple(EP) ->
	lists:reverse(Acc);
ep_table_get1({'EXIT', _Reason}, _, _) ->
	genErr.

-spec ep_table_get_next(EPs, Index, Columns) -> Result
	when
		EPs :: [pid()],
		Index :: pos_integer(),
		Columns :: [Column],
		Column :: non_neg_integer(),
		Result :: [Element] | {genErr, Column},
		Element :: {NextOid, NextValue} | endOfTable,
		NextOid :: [integer()],
		NextValue :: atom() | integer() | string() | [integer()].
%% @hidden
ep_table_get_next([], _Index, Columns) ->
	[endOfTable || _ <- Columns];
ep_table_get_next(EPs, Index, Columns) when length(EPs) >= Index ->
	EP = lists:nth(Index, EPs),
	ep_table_get_next(EPs, catch m3ua:get_ep(EP), Index, Columns, []);
ep_table_get_next(EPs, _Index, Columns) when is_list(EPs) ->
	F = fun(N) -> N + 1 end,
	NextColumns = lists:map(F, Columns),
	ep_table_get_next(EPs, 1, NextColumns);
ep_table_get_next({'EXIT', _Reason}, _, [N | _]) ->
	{genErr, N}.
%% @hidden
ep_table_get_next(EPs, EP, Index, [N | T], Acc)
		when is_tuple(EP), N < 2 ->
	ep_table_get_next(EPs, EP, Index, T, [{[2, Index], Index} | Acc]);
ep_table_get_next(EPs, {_, server, _, _} = EP, Index, [2 | T], Acc) ->
	ep_table_get_next(EPs, EP, Index, T, [{[2, Index], 1} | Acc]);
ep_table_get_next(EPs, {_, client, _, _, _} = EP, Index, [2 | T], Acc) ->
	ep_table_get_next(EPs, EP, Index, T, [{[2, Index], 2} | Acc]);
ep_table_get_next(EPs, EP, Index, [3 | T], Acc) ->
	case element(4, EP) of
		{Address, _} when size(Address) == 4 ->
			ep_table_get_next(EPs, EP, Index, T, [{[3, Index], ipv4} | Acc]);
		{Address, _} when size(Address) == 8 ->
			ep_table_get_next(EPs, EP, Index, T, [{[3, Index], ipv6} | Acc])
	end;
ep_table_get_next(EPs, EP, Index, [4 | T], Acc) ->
	{Address, _} = element(4, EP),
	Value = tuple_to_list(Address),
	ep_table_get_next(EPs, EP, Index, T, [{[4, Index], Value} | Acc]);
ep_table_get_next(EPs, EP, Index, [5 | T], Acc) ->
	{_, Port} = element(4, EP),
	ep_table_get_next(EPs, EP, Index, T, [{[5, Index], Port} | Acc]);
ep_table_get_next(EPs, {_, client, _, _, {Address, _}} = EP,
		Index, [6 | T], Acc) when size(Address) == 4 ->
	ep_table_get_next(EPs, EP, Index, T, [{[6, Index], ipv4} | Acc]);
ep_table_get_next(EPs, {_, client, _, _, {Address, _}} = EP,
		Index, [6 | T], Acc) when size(Address) == 8 ->
	ep_table_get_next(EPs, EP, Index, T, [{[6, Index], ipv6} | Acc]);
ep_table_get_next(EPs, {_, client, _, _, {Address, _}} = EP,
		Index, [7 | T], Acc) ->
	Value = tuple_to_list(Address),
	ep_table_get_next(EPs, EP, Index, T, [{[7, Index], Value} | Acc]);
ep_table_get_next(EPs, {_, client, _, _, {_, Port}} = EP, Index, [8 | T], Acc) ->
	ep_table_get_next(EPs, EP, Index, T, [{[8, Index], Port} | Acc]);
ep_table_get_next(EPs, {_, server, _, _} = EP, Index, [N | T], Acc)
		when N >= 6, N =< 8 ->
	case ep_table_get_next(EPs, Index + 1, [N]) of
		[NextResult] ->
			ep_table_get_next(EPs, EP, Index, T, [NextResult | Acc]);
		{genErr, C} ->
			{genErr, C}
	end;
ep_table_get_next(EPs, EP, Index, [9 | T], Acc) ->
	ep_table_get_next(EPs, EP, Index, T, [{[9, Index], element(3, EP)} | Acc]);
ep_table_get_next(EPs, EP, Index, [N | T], Acc) when N > 9 ->
	ep_table_get_next(EPs, EP, Index, T, [endOfTable | Acc]);
ep_table_get_next(_, _, _, [], Acc) ->
	lists:reverse(Acc);
ep_table_get_next(_, {'EXIT', _Reason}, _, [N | _],  _) ->
	{genErr, N}.

-spec as_table_get(GetAsResult, Index, Columns) -> Result
	when
		GetAsResult :: {ok, [AS]} | {error, Reason :: term()},
		AS :: {Name, NA, Keys, TMT, MinASP, MaxASP, State},
		Name :: term(),
		NA :: undefined | pos_integer(),
		Keys :: [tuple()],
		TMT :: override | loadshare | broadcast,
		MinASP :: pos_integer(),
		MaxASP :: pos_integer(),
		State :: down | inactive | active | pending,
		Index :: pos_integer(),
		Columns :: [Column],
		Column :: non_neg_integer(),
		Result :: [Element] | {noValue, noSuchInstance} | genErr,
		Element :: {value, Value} | {noValue, noSuchInstance},
		Value :: atom() | integer() | string() | [integer()].
%% @hidden
as_table_get({ok, ASs}, [Index], Columns)
		when length(ASs) >= Index, Index > 0 ->
	as_table_get1(lists:nth(Index, ASs), Columns, []);
as_table_get({ok, _ASs}, _Index, _Columns) ->
	{noValue, noSuchInstance};
as_table_get({error, _Reason}, _, _) ->
	genErr.
%% @hidden
as_table_get1(AS, [N | T], Acc) when N < 2 ->
	as_table_get1(AS, [2 | T], Acc);
as_table_get1(AS, [2 | T], Acc) ->
	as_table_get1(AS, T, [{value, element(8, AS)} | Acc]);
as_table_get1(AS, [3 | T], Acc) ->
	as_table_get1(AS, T, [{value, element(5, AS)} | Acc]);
as_table_get1({Name, _, _, _, _, _, _, _} = AS, [4 | T], Acc)
		when is_atom(Name) ->
	as_table_get1(AS, T, [{value, atom_to_list(Name)} | Acc]);
as_table_get1({Name, _, _, _, _, _, _, _} = AS, [4 | T], Acc)
		when is_list(Name) ->
	case catch unicode:characters_to_list(list_to_binary(Name), utf8) of
		Value when is_list(Value) ->
			as_table_get1(AS, T, [{value, Value} | Acc]);
		_ ->
			as_table_get1(AS, T, [{noValue, noSuchInstance} | Acc])
	end;
as_table_get1({Name, _, _, _, _, _, _, _} = AS, [4 | T], Acc)
		when is_integer(Name) ->
	as_table_get1(AS, T, [{value, integer_to_list(Name)} | Acc]);
as_table_get1(AS, [4 | T], Acc) ->
	as_table_get1(AS, T, [{noValue, noSuchInstance} | Acc]);
as_table_get1(AS, [N | T], Acc) when N > 4 ->
	as_table_get1(AS, T, [{noValue, noSuchInstance} | Acc]);
as_table_get1(_, [], Acc) ->
	lists:reverse(Acc).

-spec as_table_get_next(GetAsResult, Index, Columns) -> Result
	when
		GetAsResult :: {ok, [AS]} | {error, Reason :: term()},
		AS :: {Name, RC, NA, Keys, TMT, MinASP, MaxASP, State},
		Name :: term(),
		RC :: 0..4294967295,
		NA :: undefined | 0..4294967295,
		Keys :: [tuple()],
		TMT :: override | loadshare | broadcast,
		MinASP :: pos_integer(),
		MaxASP :: pos_integer(),
		State :: down | inactive | active | pending,
		Index :: pos_integer(),
		Columns :: [Column],
		Column :: non_neg_integer(),
		Result :: [Element] | {genErr, Column},
		Element :: {NextOid, NextValue} | endOfTable,
		NextOid :: [integer()],
		NextValue :: atom() | integer() | string() | [integer()].
%% @hidden
as_table_get_next({ok, []}, _Index, Columns) ->
	[endOfTable || _ <- Columns];
as_table_get_next({ok, ASs}, Index, Columns) when length(ASs) >= Index ->
	as_table_get_next(ASs, lists:nth(Index, ASs), Index, Columns, []);
as_table_get_next({ok, ASs}, _Index, Columns) ->
	F = fun(N) -> N + 1 end,
	NextColumns = lists:map(F, Columns),
	as_table_get_next({ok, ASs}, 1, NextColumns);
as_table_get_next({error, _Reason}, _, [N | _]) ->
	{genErr, N}.
%% @hidden
as_table_get_next(ASs, AS, Index, [N | T], Acc) when N < 2 ->
	as_table_get_next(ASs, AS, Index, [2 | T], Acc);
as_table_get_next(ASs, AS, Index, [2 | T], Acc) ->
	as_table_get_next(ASs, AS, Index, T, [{[2, Index], element(8, AS)} | Acc]);
as_table_get_next(ASs, AS, Index, [3 | T], Acc) ->
	as_table_get_next(ASs, AS, Index, T, [{[3, Index], element(5, AS)} | Acc]);
as_table_get_next(ASs, {Name, _, _, _, _, _, _, _} = AS, Index, [4 | T], Acc)
		when is_atom(Name) ->
	Value = atom_to_list(Name),
	as_table_get_next(ASs, AS, Index, T, [{[4, Index], Value} | Acc]);
as_table_get_next(ASs, {Name, _, _, _, _, _, _, _} = AS, Index, [4 | T], Acc)
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
as_table_get_next(ASs, {Name, _, _, _, _, _, _, _} = AS, Index, [4 | T], Acc)
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

-spec asp_sgp_table_get(AS, Index, Columns, Acc) -> Result
	when
		AS :: {Name, [State]},
		Name :: term(),
		State :: down | inactive | active,
		Index :: pos_integer(),
		Columns :: [Column],
		Acc :: [Element],
		Column :: non_neg_integer(),
		Result :: [Element] | {noValue, noSuchInstance} | genErr,
		Element :: {value, Value} | {noValue, noSuchInstance},
		Value :: atom() | integer() | string() | [integer()].
%% @hidden
asp_sgp_table_get({_, States} = AS, Index, [3 | T], Acc)
		when length(States) >= Index, Index > 0 ->
	asp_sgp_table_get(AS, Index, T, [{value, lists:nth(Index, States)} | Acc]);
asp_sgp_table_get({Name, _} = AS, Index, [4 | T], Acc) when is_atom(Name) ->
	asp_sgp_table_get(AS, Index, T, [{value, atom_to_list(Name)} | Acc]);
asp_sgp_table_get({Name, _} = AS, Index, [4 | T], Acc) when is_list(Name) ->
	case catch unicode:characters_to_list(list_to_binary(Name), utf8) of
		Value when is_list(Value) ->
			asp_sgp_table_get(AS, Index, T, [{value, Value} | Acc]);
		_ ->
			asp_sgp_table_get(AS, Index, T, [{noValue, noSuchInstance} | Acc])
	end;
asp_sgp_table_get({Name, _} = AS, Index, [4 | T], Acc) when is_integer(Name) ->
	asp_sgp_table_get(AS, Index, T, [{value, integer_to_list(Name)} | Acc]);
asp_sgp_table_get(AS, Index, [_ | T], Acc) ->
	asp_sgp_table_get(AS, Index, T, [{noValue, noSuchInstance} | Acc]);
asp_sgp_table_get(_, _, [], Acc) ->
	lists:reverse(Acc).

-spec asp_sgp_table_get_next(AsKeys, AsIndex, AspIndex, Columns) -> Result
	when
		AsKeys :: [term()],
		AsIndex :: pos_integer(),
		AspIndex :: pos_integer(),
		Columns :: [Column],
		Column :: non_neg_integer(),
		Result :: [Element] | {genErr, Column},
		Element :: {NextOid, NextValue} | endOfTable,
		NextOid :: [integer()],
		NextValue :: atom() | integer() | string() | [integer()].
%% @hidden
asp_sgp_table_get_next([], _AsIndex, _AspIndex, Columns) ->
	[endOfTable || _ <- Columns];
asp_sgp_table_get_next(AsKeys, 0, AspIndex, Columns) ->
	asp_sgp_table_get_next(AsKeys, 1, AspIndex, Columns);
asp_sgp_table_get_next(AsKeys, AsIndex, 0, Columns) ->
	asp_sgp_table_get_next(AsKeys, AsIndex, 1, Columns);
asp_sgp_table_get_next(AsKeys, AsIndex, AspIndex, Columns)
		when length(AsKeys) >= AsIndex ->
	F = fun() ->
		[#m3ua_as{name = Name, asp = ASPs}] = mnesia:read(m3ua_as,
				lists:nth(AsIndex, AsKeys)),
		{Name, [ASP#m3ua_as_asp.state || ASP <- ASPs]} 
	end,
	case mnesia:transaction(F) of
		{atomic, AS} when length(AS) < AspIndex ->
			asp_sgp_table_get_next(AsKeys, AsIndex + 1, 1, Columns);
		{atomic, AS} ->
			asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex, Columns, []);
		{aborted, _Reason} ->
			{genErr, hd(Columns)}
	end;
asp_sgp_table_get_next(AsKeys, _AsIndex, _AspIndex, [N | _] = Columns)
		when N < 4 ->
	F = fun(C) -> C + 1 end,
	NextColumns = lists:map(F, Columns),
	asp_sgp_table_get_next(AsKeys, 1, 1, NextColumns);
asp_sgp_table_get_next(_, _AsIndex, _AspIndex, Columns) ->
	[endOfTable || _ <- Columns].
%% @hidden
asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex, [N | T], Acc)
		when N < 3 ->
	asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex, [3 | T], Acc);
asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex, [N | T], Acc)
		when N > 4 ->
	asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex, T, [endOfTable | Acc]);
asp_sgp_table_get_next(AsKeys, {_, States} = AS, AsIndex, AspIndex, [3 | T], Acc)
		when AspIndex =< length(States) ->
	asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex,
			T, [{[3, AsIndex, AspIndex], lists:nth(AspIndex, States)} | Acc]);
asp_sgp_table_get_next(AsKeys, {Name, States} = AS, AsIndex, AspIndex, [4 | T], Acc)
		when AspIndex =< length(States), is_atom(Name) ->
	Value = atom_to_list(Name),
	asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex,
			T, [{[4, AsIndex, AspIndex], Value} | Acc]);
asp_sgp_table_get_next(AsKeys, {Name, States} = AS, AsIndex, AspIndex, [4 | T], Acc)
		when AspIndex =< length(States), is_list(Name) ->
	case catch unicode:characters_to_list(list_to_binary(Name), utf8) of
		Value when is_list(Value) ->
			asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex,
					T, [{[4, AsIndex, AspIndex], Value} | Acc]);
		_ when length(States) < AspIndex ->
			case asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex + 1, [4], []) of
				[NextResult] ->
					asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex,
							T, [NextResult | Acc]);
				{genErr, C} ->
					{genErr, C}
			end;
		_ ->
			case asp_sgp_table_get_next(AsKeys, AsIndex + 1, 1, [4]) of
				[NextResult] ->
					asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex,
							T, [NextResult | Acc]);
				{genErr, C} ->
					{genErr, C}
			end
	end;
asp_sgp_table_get_next(AsKeys, {Name, States} = AS, AsIndex, AspIndex, [4 | T], Acc)
		when AspIndex =< length(States), is_integer(Name) ->
	Value = integer_to_list(Name),
	asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex,
			T, [{[4, AsIndex, AspIndex], Value} | Acc]);
asp_sgp_table_get_next(AsKeys, {_, States} = AS, AsIndex, AspIndex, [N | T], Acc)
	when length(AsKeys) < AsIndex, length(States) < AspIndex ->
	case asp_sgp_table_get_next(AsKeys, AsIndex + 1, 1, [N]) of
		[NextResult] ->
			asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex,
					T, [NextResult | Acc]);
		{genErr, C} ->
			{genErr, C}
	end;
asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex, [_N | T], Acc) ->
	asp_sgp_table_get_next(AsKeys, AS, AsIndex, AspIndex,
			T, [endOfTable | Acc]);
asp_sgp_table_get_next(_, _, _, _, [], Acc) ->
	lists:reverse(Acc).

-spec asp_stat_table_get(Counts, Columns, Acc) -> Result
	when
		Counts :: #{},
		Columns :: [Column],
		Acc :: [Element],
		Column :: non_neg_integer(),
		Result :: [Element] | {noValue, noSuchInstance} | genErr,
		Element :: {value, Value} | {noValue, noSuchInstance},
		Value :: atom() | integer() | string() | [integer()].
%% @hidden
asp_stat_table_get(Counts, [2 | T], Acc) ->
	Count = maps:get(up_out, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [3 | T], Acc) ->
	Count = maps:get(active_out, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [4 | T], Acc) ->
	Count = maps:get(down_out, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [5 | T], Acc) ->
	Count = maps:get(inactive_out, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [6 | T], Acc) ->
	Count = maps:get(up_ack_in, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [7 | T], Acc) ->
	Count = maps:get(active_ack_in, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [8 | T], Acc) ->
	Count = maps:get(down_ack_in, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [9 | T], Acc) ->
	Count = maps:get(inactive_ack_in, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [10 | T], Acc) ->
	Count = maps:get(notify_in, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [11 | T], Acc) ->
	Count = maps:get(daud_out, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [12 | T], Acc) ->
	Count = maps:get(duna_in, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [13 | T], Acc) ->
	Count = maps:get(dava_in, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [14 | T], Acc) ->
	Count = maps:get(dupu_in, Counts, 0),
	asp_stat_table_get(Counts, T, [{value, Count} | Acc]);
asp_stat_table_get(Counts, [_ | T], Acc) ->
	asp_stat_table_get(Counts, T, [{noValue, noSuchInstance} | Acc]);
asp_stat_table_get(_, [], Acc) ->
	lists:reverse(Acc).

-spec asp_stat_table_get_next(Counts, Index, Columns, Acc) -> Result
	when
		Counts :: #{},
		Index :: pos_integer(),
		Columns :: [Column],
		Column :: non_neg_integer(),
		Acc :: [Element],
		Result :: [Element] | {genErr, Column},
		Element :: {NextOid, NextValue} | endOfTable,
		NextOid :: [integer()],
		NextValue :: atom() | integer() | string() | [integer()].
%% @hidden
asp_stat_table_get_next(Counts, Index, [N | T], Acc) when N < 2 ->
	asp_stat_table_get_next(Counts, Index, [2 | T], Acc);
asp_stat_table_get_next(Counts, Index, [2 | T], Acc) ->
	Count = maps:get(up_out, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[2, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [3 | T], Acc) ->
	Count = maps:get(active_out, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[3, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [4 | T], Acc) ->
	Count = maps:get(down_out, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[4, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [5 | T], Acc) ->
	Count = maps:get(inactive_out, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[5, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [6 | T], Acc) ->
	Count = maps:get(up_ack_in, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[6, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [7 | T], Acc) ->
	Count = maps:get(active_ack_in, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[7, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [8 | T], Acc) ->
	Count = maps:get(down_ack_in, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[8, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [9 | T], Acc) ->
	Count = maps:get(inactive_ack_in, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[9, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [10 | T], Acc) ->
	Count = maps:get(notify_in, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[10, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [11 | T], Acc) ->
	Count = maps:get(daud_out, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[11, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [12 | T], Acc) ->
	Count = maps:get(duna_in, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[12, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [13 | T], Acc) ->
	Count = maps:get(dava_in, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[13, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [14 | T], Acc) ->
	Count = maps:get(dupu_in, Counts, 0),
	asp_stat_table_get_next(Counts, Index, T, [{[14, Index], Count} | Acc]);
asp_stat_table_get_next(Counts, Index, [_N | T], Acc) ->
	asp_stat_table_get_next(Counts, Index, T, [endOfTable | Acc]);
asp_stat_table_get_next(_, _, [], Acc) ->
	lists:reverse(Acc).

