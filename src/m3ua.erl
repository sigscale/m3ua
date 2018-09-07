%%% m3ua.erl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2015-2018 SigScale Global Inc.
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
%%% @doc This library module implements the public API for the
%%% 	{@link //m3ua. m3ua} application.
%%%
-module(m3ua).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

%% export the m3ua public API
-export([start/1, start/3, stop/1]).
-export([sctp_release/2, sctp_status/2]).
-export([getstat/1, getstat/2, getstat/3, getcount/2]).
-export([as_add/7, as_delete/1, register/6, register/7]).
-export([get_ep/0, get_ep/1, get_as/0, get_assoc/0, get_assoc/1]).
-export([asp_status/2, asp_up/2, asp_down/2, asp_active/2,
			asp_inactive/2]).
-export([transfer/9, transfer/10, cast/9]).

%% export the m3ua private API
-export([sort/1, keymember/4, keymember/5]).

-type option() :: {name, term()}
		| {connect, inet:ip_address(), inet:port_number(), [gen_sctp:option()]}
		| {role, sgp | asp}
		| {static, boolean()}
		| {use_rc, boolean()}
		| gen_sctp:option().
%% Options used to configure SCTP endpoint and M3UA process behaviour.
-export_type([option/0]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-type stat_option() ::
	'recv_cnt' | 'recv_max' | 'recv_avg' | 'recv_oct' | 'recv_dvi' |
	'send_cnt' | 'send_max' | 'send_avg' | 'send_oct' | 'send_pend'.

%%----------------------------------------------------------------------
%%  The m3ua public API
%%----------------------------------------------------------------------

-spec start(Callback) -> Result
	when
		Callback :: atom() | #m3ua_fsm_cb{},
		Result :: {ok, EndPoint} | {error, Reason},
		EndPoint :: pid(),
		Reason :: term().
%% @equiv start(Callback, 0, [])
start(Callback) ->
	start(Callback, 0, []).

-spec start(Callback, Port, Options) -> Result
	when
		Port :: inet:port_number(),
		Options :: [option()],
		Callback :: atom() | #m3ua_fsm_cb{},
		Result :: {ok, EndPoint} | {error, Reason},
		EndPoint :: pid(),
		Reason :: term().
%% @doc Start an M3UA service on a new SCTP endpoint.
%%
%% 	Default options create an endpoint for an M3UA
%% 	Signaling Gateway Process (SGP) in server mode.
%%
start(Callback, Port, Options) when is_integer(Port), is_list(Options),
		((Callback == false) orelse is_atom(Callback) orelse is_tuple(Callback)) ->
	m3ua_lm_server:start(Callback, [{port, Port} | Options]).

-spec stop(EndPoint:: pid()) -> ok | {error, Reason :: term()}.
%% @doc Close a previously opened endpoint.
stop(EP) when is_pid(EP) ->
	m3ua_lm_server:stop(EP).

-spec as_add(Name, RoutingContext, NA, Keys, Mode, MinASP, MaxASP) -> Result
	when
		Name :: term(),
		RoutingContext :: 0..4294967295,
		NA :: 0..4294967295 | undefined,
		Keys :: [Key],
		MinASP :: pos_integer(),
		MaxASP :: pos_integer(),
		Key :: {DPC, [SI], [OPC]},
		DPC :: 0..16777215,
		SI :: byte(),
		OPC :: 0..16777215,
		Mode :: override | loadshare | broadcast,
		Result :: {ok, AS} | {error, Reason},
		AS :: #m3ua_as{},
		Reason :: term().
%% @doc Add an Application Server (AS).
as_add(Name, RoutingContext, NA, Keys, Mode, MinASP, MaxASP)
		when is_integer(RoutingContext),
		((NA == undefined) orelse is_integer(NA)),
		is_list(Keys), is_atom(Mode),
		is_integer(MinASP), is_integer(MaxASP) ->
	m3ua_lm_server:as_add(Name, RoutingContext, NA, Keys, Mode, MinASP, MaxASP).

-spec as_delete(RoutingContext) -> Result
	when
		RoutingContext :: 0..4294967295,
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Delete an Application Server (AS).
as_delete(RoutingContext) ->
	m3ua_lm_server:as_delete(RoutingContext).

-spec getstat(EndPoint) -> Result
	when
		EndPoint :: pid(),
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get all socket statistics for an endpoint.
getstat(EndPoint) when is_pid(EndPoint) ->
	gen_fsm:sync_send_all_state_event(EndPoint, {getstat, undefined}).

-spec getstat(EndPoint, AssocOrOptions) -> Result
	when
		EndPoint :: pid(),
		AssocOrOptions :: Assoc | Options,
		Assoc :: gen_sctp:assoc_id(),
		Options :: [stat_option()],
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics.
%%
%% 	Get socket statistics for an endpoint with `Options'
%% 	specifying the specific statistics to retrieve or
%% 	get all socket statistics for the association `Assoc'.
%%
getstat(EndPoint, Options)
		when is_pid(EndPoint), is_list(Options)  ->
	gen_fsm:sync_send_all_state_event(EndPoint, {getstat, Options});
getstat(EndPoint, Assoc)
		when is_pid(EndPoint), is_integer(Assoc) ->
	m3ua_lm_server:getstat(EndPoint, Assoc).

-spec getstat(EndPoint, Assoc, Options) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Options :: [stat_option()],
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get specific socket statistics for an association.
getstat(EndPoint, Assoc, Options)
		when is_pid(EndPoint), is_integer(Assoc), is_list(Options)  ->
	m3ua_lm_server:getstat(EndPoint, Assoc, Options).

-spec getcount(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: {ok, Counters} | {error, Reason},
		Counters :: #{MessageType => Total},
		MessageType :: up_out | up_in | up_ack_in | up_ack_out
				| down_out | down_in | down_ack_in | down_ack_out
				| active_out | active_in | active_ack_in | active_ack_out
				| inactive_out | inactive_in | inactive_ack_in | inactive_ack_out
				| notify_out | notify_in | daud_out | daud_in
				| duna_out | duna_in | dava_in | dava_out 
				| dupu_out | dupu_in | transfer_in | transfer_out,
		Total :: non_neg_integer(),
		Reason :: term().
%% @doc Get M3UA message statistics counters.
%%
getcount(EndPoint, Assoc)
		when is_pid(EndPoint), is_integer(Assoc) ->
	m3ua_lm_server:getcount(EndPoint, Assoc).

-spec register(EndPoint, Assoc, RoutingContext, NA, Keys, Mode) ->
		Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		RoutingContext :: 0..4294967295 | undefined,
		NA :: 0..4294967295 | undefined,
		Keys :: [Key],
		Key :: {DPC, [SI], [OPC]},
		DPC :: 0..16777215,
		SI :: byte(),
		OPC :: 0..16777215,
		Mode :: override | loadshare | broadcast,
		Result :: {ok, NewRoutingContext} | {error, Reason},
		NewRoutingContext :: non_neg_integer(),
		Reason :: term().
%% @equiv register(EndPoint, Assoc, RoutingContext, NA, Keys, Mode, undefined)
register(EndPoint, Assoc, RoutingContext, NA, Keys, Mode) ->
	register(EndPoint, Assoc, RoutingContext, NA, Keys, Mode, undefined).

-spec register(EndPoint, Assoc, RoutingContext, NA, Keys, Mode, AsName) ->
		Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		RoutingContext :: 0..4294967295 | undefined,
		NA :: 0..4294967295 | undefined,
		Keys :: [Key],
		Key :: {DPC, [SI], [OPC]},
		DPC :: 0..16777215,
		SI :: byte(),
		OPC :: 0..16777215,
		Mode :: override | loadshare | broadcast,
		AsName :: term(),
		Result :: {ok, RoutingContext} | {error, Reason},
		RoutingContext :: non_neg_integer(),
		Reason :: term().
%% @doc Register a routing key for an application server.
%%
%% 	Creates a new routing keys registration when `RoutingContext'
%% 	is `undefined' or updates the routing keys for the existing
%% 	registration of `RoutingContext'.
%%
register(EndPoint, Assoc, RoutingContext, NA, Keys, Mode, AsName)
		when is_pid(EndPoint), is_integer(Assoc), is_list(Keys),
		((RoutingContext == undefined) or is_integer(RoutingContext)),
		((NA == undefined) or is_integer(NA)),
		((Mode == override) orelse (Mode == loadshare)
		orelse (Mode == broadcast)) ->
	m3ua_lm_server:register(EndPoint, Assoc,
			RoutingContext, NA, Keys, Mode, AsName).

-spec sctp_release(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Release an established SCTP association.
sctp_release(EndPoint, Assoc) ->
	m3ua_lm_server:sctp_release(EndPoint, Assoc).

-spec sctp_status(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: {ok, AssocStatus} | {error, Reason},
		AssocStatus :: #sctp_status{},
		Reason :: term().
%% @doc Report the status of an SCTP association.
sctp_status(EndPoint, Assoc) ->
	m3ua_lm_server:sctp_status(EndPoint, Assoc).

-spec asp_status(EndPoint, Assoc) -> AspState
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		AspState :: down | inactive | active.
%% @doc Report the status of local or remote ASP.
asp_status(EndPoint, Assoc) ->
	m3ua_lm_server:asp_status(EndPoint, Assoc).

%%-spec as_status(SAP, ???) -> Result
%%	when
%%		SAP :: pid(),
%%		Result :: {ok, AsState} | {error, Reason},
%%		AsState :: down | inactive | active | pending,
%%		Reason :: term().
%%%% doc Report the status of an AS.
%%as_status(SAP, ???) ->
%%	todo.

-spec asp_up(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: asp_not_found | term().
%% @doc Requests that ASP start its operation
%%  and send an ASP Up message to its peer.
asp_up(EndPoint, Assoc) ->
	m3ua_lm_server:asp_up(EndPoint, Assoc).

-spec asp_down(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: asp_not_found | term().
%% @doc Requests that ASP stop its operation
%%  and send an ASP Down message to its peer.
asp_down(EndPoint, Assoc) ->
	m3ua_lm_server:asp_down(EndPoint, Assoc).

-spec asp_active(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: asp_not_found | term().
%% @doc Requests that ASP send an ASP Active message to its peer.
asp_active(EndPoint, Assoc) ->
	m3ua_lm_server:asp_active(EndPoint, Assoc).

-spec asp_inactive(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: asp_not_found | term().
%% @doc Requests that ASP send an ASP Inactive message to its peer.
asp_inactive(EndPoint, Assoc) ->
	m3ua_lm_server:asp_inactive(EndPoint, Assoc).

-spec transfer(Fsm, Stream, RC, OPC, DPC, NI, SI, SLS, Data) -> Result
	when
		Fsm :: pid(),
		Stream :: pos_integer(),
		RC :: 0..4294967295 | undefined,
		OPC :: 0..16777215,
		DPC :: 0..16777215,
		NI :: byte(),
		SI :: byte(),
		SLS :: byte(),
		Data :: binary(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc MTP-TRANSFER request.
%%
%% Called by an MTP user to transfer data using the MTP service.
transfer(Fsm, Stream, RC, OPC, DPC, NI, SI, SLS, Data)
		when is_pid(Fsm), is_integer(Stream), Stream =/= 0,
		((RC == undefined) or is_integer(RC)),
		is_integer(OPC), is_integer(DPC), is_integer(NI),
		is_integer(SI), is_integer(SLS), is_binary(Data) ->
	Params = {Stream, RC, OPC, DPC, NI, SI, SLS, Data},
	gen_fsm:sync_send_event(Fsm, {'MTP-TRANSFER', request, Params}).

-spec transfer(Fsm, Stream, RC, OPC, DPC, NI, SI, SLS, Data, Timeout) -> Result
	when
		Fsm :: pid(),
		Stream :: pos_integer(),
		RC :: 0..4294967295 | undefined,
		OPC :: 0..16777215,
		DPC :: 0..16777215,
		NI :: byte(),
		SI :: byte(),
		SLS :: byte(),
		Data :: binary(),
		Timeout :: pos_integer() | infinity,
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc MTP-TRANSFER request.
%%
%% Called by an MTP user to transfer data using the MTP service.
transfer(Fsm, Stream, RC, OPC, DPC, NI, SI, SLS, Data, Timeout)
		when is_pid(Fsm), is_integer(Stream), Stream =/= 0,
		((RC == undefined) or is_integer(RC)),
		is_integer(OPC), is_integer(DPC), is_integer(NI),
		is_integer(SI), is_integer(SLS), is_binary(Data),
		(is_integer(Timeout) or (Timeout == infinity))->
	Params = {Stream, RC, OPC, DPC, NI, SI, SLS, Data},
	gen_fsm:sync_send_event(Fsm, {'MTP-TRANSFER', request, Params}, Timeout).

-spec cast(Fsm, Stream, RC, OPC, DPC, NI, SI, SLS, Data) -> Ref
	when
		Fsm :: pid(),
		Stream :: pos_integer(),
		RC :: 0..4294967295 | undefined,
		OPC :: 0..16777215,
		DPC :: 0..16777215,
		NI :: byte(),
		SI :: byte(),
		SLS :: byte(),
		Data :: binary(),
		Ref :: reference().
%% @doc MTP-TRANSFER request.
%%
%% Called by an MTP user to transfer data asynchronously.
cast(Fsm, Stream, RC, OPC, DPC, NI, SI, SLS, Data)
		when is_pid(Fsm), is_integer(Stream), Stream =/= 0,
		((RC == undefined) or is_integer(RC)),
		is_integer(OPC), is_integer(DPC), is_integer(NI),
		is_integer(SI), is_integer(SLS), is_binary(Data) ->
	Ref = make_ref(),
	Params = {Stream, RC, OPC, DPC, NI, SI, SLS, Data},
	gen_fsm:send_event(Fsm, {'MTP-TRANSFER', request, Ref, self(), Params}),
	Ref.

-spec get_as() -> Result
	when
		Result :: {ok, [AS]} | {error, Reason},
		AS :: {Name, RC, NA, Keys, TMT, MinASP, MaxASP, State},
		Name :: string(),
		RC :: 0..4294967295,
		NA :: 0..4294967295 | undefined,
		Keys :: [key()],
		TMT :: tmt(),
		MinASP :: pos_integer(),
		MaxASP :: pos_integer(),
		State :: down | inactive | active | pending,
		Reason :: term().
%% @doc Get all Application Servers (AS).
%%
get_as() ->
	Fold = fun(#m3ua_as{rc = RC, rk = {NA, Keys, TMT}, name = Name,
				min_asp = MinASP, max_asp = MaxASP, state = State}, Acc) ->
				[{Name, RC, NA, Keys, TMT, MinASP, MaxASP, State} | Acc]
	end,
	case mnesia:transaction(fun() -> mnesia:foldl(Fold, [], m3ua_as) end) of
		{atomic, ASs} ->
			{ok, ASs};
		{aborted, Reason} ->
			{error, Reason}
	end.

-spec get_ep() -> Result
	when
		Result :: [EP],
		EP :: pid().
%% @doc Get all SCTP endpoints on local node.
%%
get_ep() ->
	get_ep(get_ep_sups(), []).
%% @hidden
get_ep([H | T], Acc) ->
	EP = find_ep(supervisor:which_children(H)),
	get_ep(T, [EP | Acc]);
get_ep([], Acc) ->
	lists:reverse(Acc).

-spec get_ep(EP) -> Result
	when
		EP :: pid(),
		Result :: {Name, server, Role, Local} | {Name, client, Role, Local, Remote},
		Name :: term(),
		Role :: asp | sgp,
		Local :: {Address, Port},
		Remote :: {Address, Port},
		Address :: inet:ip_address(),
		Port :: inet:port_number().
%% @doc Get SCTP endpoint details.
%%
get_ep(EP) when is_pid(EP) ->
	gen_fsm:sync_send_all_state_event(EP, getep).

-spec get_assoc() -> Result
	when
		Result :: [{EP, Assoc}],
		EP :: pid(),
		Assoc :: gen_sctp:assoc_id().
%% @doc Get all SCTP associations.
%%
get_assoc() ->
	get_assoc(get_ep_sups(), []).
%% @hidden
get_assoc([H | T], Acc) ->
	EP = find_ep(supervisor:which_children(H)),
	L = [{EP, Assoc} || Assoc <- get_assoc(EP)],
	get_assoc(T, [L | Acc]);
get_assoc([], Acc) ->
	lists:flatten(lists:reverse(Acc)).

-spec get_assoc(EP) -> Result
	when
		EP :: pid(),
		Result :: [Assoc],
		Assoc :: gen_sctp:assoc_id().
%% @doc Get SCTP associations on local endpoint.
%%
get_assoc(EP) when is_pid(EP) ->
	gen_fsm:sync_send_all_state_event(EP, getassoc).

%%----------------------------------------------------------------------
%%  The m3ua private API
%%----------------------------------------------------------------------

-spec sort(Keys) -> Keys
	when
		Keys :: [{DPC, [SI], [OPC]}],
		DPC :: 0..16777215,
		SI :: byte(),
		OPC :: 0..16777215.
%% @doc Uniquely sort list of routing keys.
%% @private
sort(Keys) when is_list(Keys) ->
	sort(Keys, []).
%% @hidden
sort([{DPC, SIs, OPCs} | T], Acc) when is_integer(DPC) ->
	SortedSIs = lists:sort(SIs),
	SortedOPCs = lists:sort(OPCs),
	sort(T, [{DPC, SortedSIs, SortedOPCs} | Acc]);
sort([], Acc) ->
	lists:sort(Acc).

-spec keymember(DPC, OPC, SI, RoutingKeys) -> boolean()
	when
		NA :: byte(),
		DPC :: 0..4294967295,
		SI :: 0..4294967295,
		OPC :: 0..4294967295,
		RoutingKeys :: [{NA, Keys, TMT}],
		Keys :: [{DPC, [SI], [OPC]}],
		TMT :: tmt().
%% @equiv keymember(undefined, DPC, OPC, SI, RoutingKeys)
%% @private
keymember(DPC, OPC, SI, RoutingKeys) ->
	keymember(undefined, DPC, OPC, SI, RoutingKeys).

-spec keymember(NA, DPC, OPC, SI, RoutingKeys) -> boolean()
	when
		NA :: 0..4294967295 | undefined,
		DPC :: 0..4294967295,
		SI :: 0..4294967295,
		OPC :: 0..4294967295,
		RoutingKeys :: [{NA, Keys, TMT}],
		Keys :: [{DPC, [SI], [OPC]}],
		TMT :: tmt().
%% @doc Test if destination matches any of the routing keys.
%% @private
keymember(undefined, DPC, OPC, SI, [{_, Keys, _TMT} | T] = _RoutingKeys)
		when is_integer(DPC), is_integer(OPC), is_integer(SI) ->
	keymember1(undefined, DPC, OPC, SI, T, Keys);
keymember(NA, DPC, OPC, SI, [{NA, Keys, _TMT} | T] = _RoutingKeys)
		when is_integer(NA), is_integer(DPC),
		is_integer(OPC), is_integer(SI) ->
	keymember1(NA, DPC, OPC, SI, T, Keys);
keymember(NA, DPC, OPC, SI, [_ | T] = _RoutingKeys)
		when ((NA == undefined) or is_integer(NA)), is_integer(DPC),
		is_integer(OPC), is_integer(SI) ->
	keymember(NA, DPC, OPC, SI, T);
keymember(NA, DPC, OPC, SI, [] = _RoutingKeys)
		when ((NA == undefined) or is_integer(NA)), is_integer(DPC),
		is_integer(OPC), is_integer(SI) ->
	false.
%% @hidden
keymember1(_, DPC, _, _, _, [{DPC, [], []} | _]) ->
	true;
keymember1(NA, DPC, OPC, SI, RoutingKeys, [{DPC, SIs, []} | T]) ->
	case lists:member(SI, SIs) of
		true ->
			true;
		false ->
			keymember1(NA, DPC, OPC, SI, RoutingKeys, T)
	end;
keymember1(NA, DPC, OPC, SI, RoutingKeys, [{DPC, [], OPCs} | T]) ->
	case lists:member(OPC, OPCs) of
		true ->
			true;
		false ->
			keymember1(NA, DPC, OPC, SI, RoutingKeys, T)
	end;
keymember1(NA, DPC, OPC, SI, RoutingKeys, [{DPC, SIs, OPCs} | T]) ->
	case lists:member(SI, SIs) of
		true ->
			case lists:member(OPC, OPCs) of
				true ->
					true;
				false ->
					keymember1(NA, DPC, OPC, SI, RoutingKeys, T)
			end;
		false ->
			keymember1(NA, DPC, OPC, SI, RoutingKeys, T)
	end;
keymember1(NA, DPC, OPC, SI, RoutingKeys, [_ | T]) ->
	keymember1(NA, DPC, OPC, SI, RoutingKeys, T);
keymember1(NA, DPC, OPC, SI, RoutingKeys, []) ->
	keymember(NA, DPC, OPC, SI, RoutingKeys).

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

%% @hidden
get_ep_sups() ->
	get_ep_sups(whereis(m3ua_sup)).
%% @hidden
get_ep_sups(TopSup) when is_pid(TopSup) ->
	Children1 = supervisor:which_children(TopSup),
	{_, Sup2,  _, _} = lists:keyfind(m3ua_endpoint_sup_sup, 1, Children1),
	[S || {_, S, _, _} <- supervisor:which_children(Sup2)];
get_ep_sups(undefined) ->
	[].

%% @hidden
find_ep([{m3ua_listen_fsm, EP, _, _} | _]) ->
	EP;
find_ep([{m3ua_connect_fsm, EP, _, _} | _]) ->
	EP;
find_ep([_ | T]) ->
	find_ep(T).

