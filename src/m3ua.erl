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
-export([open/0, open/2, close/1]).
-export([sctp_establish/4, sctp_release/2, sctp_status/2]).
-export([getstat_endpoint/1, getstat_endpoint/2,
			getstat_association/2, getstat_association/3]).
-export([register/5, register/6]).
-export([asp_status/2, asp_up/2, asp_down/2, asp_active/2,
			asp_inactive/2]).

%% export the m3ua private API
-export([sort/1]).

-type options() :: {sctp_role, client | server}
						| {m3ua_role, sgp | asp}
						| {ip, inet:ip_address()}
						| {ifaddr, inet:ip_address()}
						| {port, inet:port_number()}
						| sctp:option().
-export_type([options/0]).

-include_lib("kernel/include/inet_sctp.hrl").

%%----------------------------------------------------------------------
%%  The m3ua public API
%%----------------------------------------------------------------------

-spec open() -> Result
	when
		Result :: {ok, EndPoint} | {error, Reason},
		EndPoint :: pid(),
		Reason :: term().
%% @equiv open(0, [])
open() ->
	open(0, []).

-spec open(Port, Options) -> Result
	when
		Port :: inet:port_number(),
		Options :: [options()],
		Result :: {ok, EndPoint} | {error, Reason},
		EndPoint :: pid(),
		Reason :: term().
%% @doc Create a new SCTP endpoint.
%%
%% 	Default options create an endpoint for an M3UA
%% 	Application Server Process (ASP) in client mode.
%%
open(Port, Options) when is_integer(Port), is_list(Options) ->
	m3ua_lm_server:open([{port, Port} | Options]).

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

-spec getstat_endpoint(EndPoint) -> Result
	when
		EndPoint :: pid(),
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{inet:stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics for an endpoint.
getstat_endpoint(EndPoint) when is_pid(EndPoint) ->
	gen_server:call(EndPoint, {getstat, undefined}).

-spec getstat_endpoint(EndPoint, Options) -> Result
	when
		EndPoint :: pid(),
		Options :: [inet:stat_option()],
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{inet:stat_option(), Count}],
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
		OptionValues :: [{inet:stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics for an association.
getstat_association(EndPoint, Assoc)
		when is_pid(EndPoint), is_integer(Assoc) ->
	m3ua_lm_server:getstat(EndPoint, Assoc).

-spec getstat_association(EndPoint, Assoc, Options) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Options :: [inet:stat_option()],
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{inet:stat_option(), Count}],
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
%% @doc Register a routing key for an application server.
register(EndPoint, Assoc, NA, Keys, Mode) ->
	register(EndPoint, Assoc, NA, Keys, Mode, self()).

-spec register(EndPoint, Assoc, NA, Keys, Mode, AS) -> Result
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
		AS :: pid() | {local, Name} | {global, GlobalName}
				| {via, Module, ViaName},
		Name :: atom(),
		GlobalName :: term(),
		Module :: atom(),
		ViaName :: term(),
		Result :: {ok, RoutingContext} | {error, Reason},
		RoutingContext :: pos_integer(),
		Reason :: term().
%% @doc Register a routing key for an application server.
register(EndPoint, Assoc, NA, Keys, Mode, AS)
		when is_pid(EndPoint), is_integer(Assoc), is_list(Keys),
		((NA == undefined) or is_integer(NA)),
		((Mode == overide) orelse (Mode == loadshare)
		orelse (Mode == broadcast)), (is_pid(AS)
		orelse ((element(1, AS) == local)
		and is_atom(element(2, AS))) orelse (element(1, AS) == global)
		orelse ((element(1, AS) == via) and is_atom(element(2, AS)))) ->
	m3ua_lm_server:register(EndPoint, Assoc, NA, Keys, Mode, AS).

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

%%----------------------------------------------------------------------
%%  The m3ua private API
%%----------------------------------------------------------------------
-spec sort(Keys) -> Keys
	when
		Keys :: [{DPC, [SI], [OPC]}],
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer().
%% @doc uniquly sort list of keys
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

