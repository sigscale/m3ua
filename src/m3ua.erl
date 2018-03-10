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
-export([open/1, open/3, close/1]).
-export([sctp_establish/4, sctp_release/2, sctp_status/2]).
-export([getstat_endpoint/1, getstat_endpoint/2,
			getstat_association/2, getstat_association/3]).
-export([as_add/6, as_delete/1, register/5, register/6]).
-export([get_ep/0, get_as/0, get_asp/0, get_sgp/0]).
-export([asp_status/2, asp_up/2, asp_down/2, asp_active/2,
			asp_inactive/2]).
-export([transfer/7]).

%% export the m3ua private API
-export([sort/1]).

-type option() :: {sctp_role, client | server}
		| {m3ua_role, sgp | asp}
		| {registration, dynamic | static}
		| {use_rc, boolean()}
		| {ip, inet:ip_address()}
		| {ifaddr, inet:ip_address()}
		| {port, inet:port_number()}
		| gen_sctp:option().
-export_type([option/0]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-type stat_option() ::
	'recv_cnt' | 'recv_max' | 'recv_avg' | 'recv_oct' | 'recv_dvi' |
	'send_cnt' | 'send_max' | 'send_avg' | 'send_oct' | 'send_pend'.

%%----------------------------------------------------------------------
%%  The m3ua public API
%%----------------------------------------------------------------------

-spec open(Callback) -> Result
	when
		Callback :: atom() | #m3ua_fsm_cb{},
		Result :: {ok, EndPoint} | {error, Reason},
		EndPoint :: pid(),
		Reason :: term().
%% @equiv open(0, [], Callback)
open(Callback) ->
	open(0, [], Callback).

-spec open(Port, Options, Callback) -> Result
	when
		Port :: inet:port_number(),
		Options :: [option()],
		Callback :: atom() | #m3ua_fsm_cb{},
		Result :: {ok, EndPoint} | {error, Reason},
		EndPoint :: pid(),
		Reason :: term().
%% @doc Create a new SCTP endpoint.
%%
%% 	Default options create an endpoint for an M3UA
%% 	Application Server Process (ASP) in client mode.
%%
open(Port, Options, Callback) when is_integer(Port), is_list(Options),
		((Callback == false) orelse is_atom(Callback) orelse is_tuple(Callback)) ->
	m3ua_lm_server:open([{port, Port} | Options], Callback).

-spec close(EndPoint:: pid()) -> ok | {error, Reason :: term()}.
%% @doc Close a previously opened endpoint.
close(EP) when is_pid(EP) ->
	m3ua_lm_server:close(EP).

-spec sctp_establish(EndPoint, Address, Port, Options) -> Result
	when
		EndPoint :: pid(),
		Address :: inet:ip_address() | inet:hostname(),
		Port :: inet:port_number(),
		Options :: [gen_sctp:option()],
		Result :: {ok, Assoc} | {error, Reason},
		Assoc :: pos_integer(),
		Reason :: term().
%% @doc Establish an SCTP association.
sctp_establish(EndPoint, Address, Port, Options) ->
	m3ua_lm_server:sctp_establish(EndPoint, Address, Port, Options).

-spec as_add(Name, NA, Keys, Mode, MinASP, MaxASP) -> Result
	when
		Name :: term(),
		NA :: undefined | pos_integer(),
		Keys :: [Key],
		MinASP :: pos_integer(),
		MaxASP :: pos_integer(),
		Key :: {DPC, [SI], [OPC]},
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer(),
		Mode :: overide | loadshare | broadcast,
		Result :: {ok, AS} | {error, Reason},
		AS :: #m3ua_as{},
		Reason :: term().
%% @doc Add an Application Server (AS).
as_add(Name, NA, Keys, Mode, MinASP, MaxASP)
		when ((NA == undefined) orelse is_integer(NA)),
		is_list(Keys), is_atom(Mode),
		is_integer(MinASP), is_integer(MaxASP) ->
	m3ua_lm_server:as_add(Name, NA, Keys, Mode, MinASP, MaxASP).

-spec as_delete(RoutingKey) -> Result
	when
		RoutingKey :: {NA, Keys, Mode},
		NA :: undefined | pos_integer(),
		Keys :: [Key],
		Key :: {DPC, [SI], [OPC]},
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer(),
		Mode :: overide | loadshare | broadcast,
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Delete an Application Server (AS).
as_delete(RoutingKey) ->
	m3ua_lm_server:as_delete(RoutingKey).

-spec getstat_endpoint(EndPoint) -> Result
	when
		EndPoint :: pid(),
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics for an endpoint.
getstat_endpoint(EndPoint) when is_pid(EndPoint) ->
	gen_server:call(EndPoint, {getstat, undefined}).

-spec getstat_endpoint(EndPoint, Options) -> Result
	when
		EndPoint :: pid(),
		Options :: [stat_option()],
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics for an endpoint.
getstat_endpoint(EndPoint, Options)
		when is_pid(EndPoint), is_list(Options)  ->
	gen_server:call(EndPoint, {getstat, Options}).

-spec getstat_association(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics for an association.
getstat_association(EndPoint, Assoc)
		when is_pid(EndPoint), is_integer(Assoc) ->
	m3ua_lm_server:getstat(EndPoint, Assoc).

-spec getstat_association(EndPoint, Assoc, Options) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Options :: [stat_option()],
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics for an association.
getstat_association(EndPoint, Assoc, Options)
		when is_pid(EndPoint), is_integer(Assoc), is_list(Options)  ->
	m3ua_lm_server:getstat(EndPoint, Assoc, Options).

-spec register(EndPoint, Assoc, NA, Keys, Mode) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		NA :: pos_integer(),
		Keys :: [Key],
		Key :: {DPC, [SI], [OPC]},
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer(),
		Mode :: overide | loadshare | broadcast,
		Result :: {ok, RoutingContext} | {error, Reason},
		RoutingContext :: pos_integer(),
		Reason :: term().
%% @equiv register(EndPoint, Assoc, NA, Keys, Mode, undefined)
register(EndPoint, Assoc, NA, Keys, Mode)
		when is_pid(EndPoint), is_integer(Assoc), is_list(Keys),
		((NA == undefined) or is_integer(NA)),
		((Mode == overide) orelse (Mode == loadshare)
		orelse (Mode == broadcast)) ->
	register(EndPoint, Assoc, NA, Keys, Mode, undefined).

-spec register(EndPoint, Assoc, NA, Keys, Mode, AsName) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		NA :: pos_integer(),
		Keys :: [Key],
		Key :: {DPC, [SI], [OPC]},
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer(),
		Mode :: overide | loadshare | broadcast,
		AsName :: term(),
		Result :: {ok, RoutingContext} | {error, Reason},
		RoutingContext :: pos_integer(),
		Reason :: term().
%% @doc Register a routing key for an application server.
register(EndPoint, Assoc, NA, Keys, Mode, AsName)
		when is_pid(EndPoint), is_integer(Assoc), is_list(Keys),
		((NA == undefined) or is_integer(NA)),
		((Mode == overide) orelse (Mode == loadshare)
		orelse (Mode == broadcast)) ->
	m3ua_lm_server:register(EndPoint, Assoc, NA, Keys, Mode, AsName).

-spec sctp_release(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Release an established SCTP association.
sctp_release(EndPoint, Assoc) ->
	m3ua_lm_server:sctp_release(EndPoint, Assoc).

-spec sctp_status(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: {ok, AssocStatus} | {error, Reason},
		AssocStatus :: #sctp_status{},
		Reason :: term().
%% @doc Report the status of an SCTP association.
sctp_status(EndPoint, Assoc) ->
	m3ua_lm_server:sctp_status(EndPoint, Assoc).

-spec asp_status(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: {ok, AspState} | {error, Reason},
		AspState :: down | inactive | active,
		Reason :: term().
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
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: asp_not_found | term().
%% @doc Requests that ASP start its operation
%%  and send an ASP Up message to its peer.
asp_up(EndPoint, Assoc) ->
	m3ua_lm_server:asp_up(EndPoint, Assoc).

-spec asp_down(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: asp_not_found | term().
%% @doc Requests that ASP stop its operation
%%  and send an ASP Down message to its peer.
asp_down(EndPoint, Assoc) ->
	m3ua_lm_server:asp_down(EndPoint, Assoc).

-spec asp_active(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: asp_not_found | term().
%% @doc Requests that ASP send an ASP Active message to its peer.
asp_active(EndPoint, Assoc) ->
	m3ua_lm_server:asp_active(EndPoint, Assoc).

-spec asp_inactive(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: asp_not_found | term().
%% @doc Requests that ASP send an ASP Inactive message to its peer.
asp_inactive(EndPoint, Assoc) ->
	m3ua_lm_server:asp_inactive(EndPoint, Assoc).

-spec transfer(Fsm, Stream, OPC, DPC, SLS, SIO, Data) -> Result
	when
		Fsm :: pid(),
		Stream :: pos_integer(),
		OPC :: pos_integer(),
		DPC :: pos_integer(),
		SLS :: non_neg_integer(),
		SIO :: non_neg_integer(),
		Data :: binary(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc MTP-TRANSFER request.
%%
%% Called by an MTP user to transfer data using the MTP service.
transfer(Fsm, Stream, OPC, DPC, SLS, SIO, Data)
		when is_pid(Fsm), is_integer(Stream), Stream =/= 0,
		is_integer(OPC), is_integer(DPC), is_integer(SLS),
		is_integer(SIO), is_binary(Data) ->
	Params = {Stream, OPC, DPC, SLS, SIO, Data},
	gen_fsm:sync_send_event(Fsm, {'MTP-TRANSFER', request, Params}).

-spec get_as() -> Result
	when
		Result :: {ok, [AS]} | {error, Reason},
		AS :: {Name, NA, Keys, TMT, MinASP, MaxASP, State},
		Name :: string(),
		NA :: pos_integer(),
		Keys :: [key()],
		TMT :: tmt(),
		MinASP :: pos_integer(),
		MaxASP :: pos_integer(),
		State :: down | inactive | active | pending,
		Reason :: term().
%% @doc Get all Application Servers (AS).
%%
get_as() ->
	Fold = fun(#m3ua_as{routing_key = {NA, Keys, TMT}, name = Name,
				min_asp = MinASP, max_asp = MaxASP, state = State}, Acc) ->
				[{Name, NA, Keys, TMT, MinASP, MaxASP, State} | Acc] 
	end,
	case mnesia:transaction(fun() -> mnesia:foldl(Fold, [], m3ua_as) end) of
		{atomic, ASs} ->
			{ok, ASs};
		{aborted, Reason} ->
			{error, Reason}
	end.

-spec get_ep() -> Result
	when
		Result :: {ok, [EP]} | {error, Reason},
		EP :: pid(),
		Reason :: term().
%% @doc Get all SCTP endpoints on local node.
%%
get_ep() ->
	get_ep(get_ep_sups(), []).
%% @hidden
get_ep([H | T], Acc) ->
	C = supervisor:which_children(H),
	{_, EP, _, _, _} = lists:keyfind(m3ua_endpoint_server, 1, C),
	get_ep(T, [EP | Acc]);
get_ep([], Acc) ->
	lists:reverse(Acc).

-spec get_asp() -> Result
	when
		Result :: {ok, [ASP]} | {error, Reason},
		ASP :: {EP, Assoc},
		EP :: pid(),
		Assoc :: pos_integer(),
		Reason :: term().
%% @doc Get all M3UA Application Server Processes (ASP) on local node.
%%
get_asp() ->
	get_asp(get_ep_sups(), []).
%% @hidden
get_asp([H | T], Acc) ->
	C = supervisor:which_children(H),
	{_, Sup, _, _} = lists:keyfind(m3ua_asp_sup, 1, C),
	P = [Pid || {_, Pid, _, _} <- supervisor:which_children(Sup)],
	get_asp(T, [P | Acc]);
get_asp([], Acc) ->
	lists:flatten(lists:reverse(Acc)).

-spec get_sgp() -> Result
	when
		Result :: {ok, [SGP]} | {error, Reason},
		SGP :: {EP, Assoc},
		EP :: pid(),
		Assoc :: pos_integer(),
		Reason :: term().
%% @doc Get all M3UA Signaling Gateway Processes (SGP) on local node.
%%
get_sgp() ->
	get_sgp(get_ep_sups(), []).
%% @hidden
get_sgp([H | T], Acc) ->
	C = supervisor:which_children(H),
	{_, Sup, _, _} = lists:keyfind(m3ua_sgp_sup, 1, C),
	P = [Pid || {_, Pid, _, _} <- supervisor:which_children(Sup)],
	get_sgp(T, [P | Acc]);
get_sgp([], Acc) ->
	lists:flatten(lists:reverse(Acc)).

%%----------------------------------------------------------------------
%%  The m3ua private API
%%----------------------------------------------------------------------

-spec sort(Keys) -> Keys
	when
		Keys :: [{DPC, [SI], [OPC]}],
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer().
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

