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
-export([asp_status/2, asp_up/2, asp_down/2, asp_active/2,
			asp_inactive/2]).

-type assoc_id() :: term().

-type options() :: {mode, client | server}
						| {ip, inet:ip_address()}
						| {ifaddr, inet:ip_address()}
						| inet:address_family()
						| {port, inet:port_number()}
						| {type, seqpacket | stream}
						| sctp:option().
-export_type([options/0]).

-include_lib("kernel/include/inet_sctp.hrl").

%%----------------------------------------------------------------------
%%  The m3ua API
%%----------------------------------------------------------------------

-spec open() -> Result
	when
		Result :: {ok, EndPoint} | {error, Reason},
		EndPoint :: pid(),
		Reason :: term().
%% @doc Create a new endpoint for a server.
open() ->
	m3ua_lm_server:open([]).

-spec open(Port, Options) -> Result
	when
		Port :: inet:port_number(),
		Options :: [options()],
		Result :: {ok, EndPoint} | {error, Reason},
		EndPoint :: pid(),
		Reason :: term().
open(Port, Options) ->
	m3ua_lm_server:open([{port, Port} | Options]).

-spec close(EndPoint:: pid()) -> ok | {error, Reason :: term()}.
%% @doc Close a previously opened end point.
close(EP) when is_pid(EP) ->
	m3ua_lm_server:close(EP).

-spec sctp_establish(SAP, Address, Port, Options) -> Result
	when
		SAP :: pid(),
		Address :: inet:ip_address() | inet:hostname(),
		Port :: inet:port_number(),
		Options :: [gen_sctp:option()],
		Result :: {ok, Assoc} | {error, Reason},
		Assoc :: assoc_id(),
		Reason :: term().
%% @doc Establish an SCTP association.
sctp_establish(SAP, Address, Port, Options) ->
	m3ua_lm_server:sctp_establish(SAP, Address, Port, Options).

-spec sctp_release(SAP, Assoc) -> Result
	when
		SAP :: pid(),
		Assoc :: assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Release an established SCTP association.
sctp_release(SAP, Assoc) ->
	m3ua_lm_server:sctp_release(SAP, Assoc).

-spec sctp_status(SAP, Assoc) -> Result
	when
		SAP :: pid(),
		Assoc :: assoc_id(),
		Result :: {ok, AssocStatus} | {error, Reason},
		AssocStatus :: #sctp_status{},
		Reason :: term().
%% @doc Report the status of an SCTP association.
sctp_status(SAP, Assoc) ->
	m3ua_lm_server:sctp_status(SAP, Assoc).

-spec asp_status(SAP, Assoc) -> Result
	when
		SAP :: pid(),
		Assoc :: assoc_id(),
		Result :: {ok, AspState} | {error, Reason},
		AspState :: down | inactive | active,
		Reason :: term().
%% @doc Report the status of local or remote ASP.
asp_status(SAP, Assoc) ->
	m3ua_lm_server:asp_status(SAP, Assoc).

%%-spec as_status(SAP, ???) -> Result
%%	when
%%		SAP :: pid(),
%%		Result :: {ok, AsState} | {error, Reason},
%%		AsState :: down | inactive | active | pending,
%%		Reason :: term().
%%%% doc Report the status of an AS.
%%as_status(SAP, ???) ->
%%	todo.

-spec asp_up(SAP, Assoc) -> Result
	when
		SAP :: pid(),
		Assoc :: assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP start its operation
%%  and send an ASP Up message to its peer.
asp_up(SAP, Assoc) ->
	m3ua_lm_server:asp_up(SAP, Assoc).

-spec asp_down(SAP, Assoc) -> Result
	when
		SAP :: pid(),
		Assoc :: assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP stop its operation
%%  and send an ASP Down message to its peer.
asp_down(SAP, Assoc) ->
	m3ua_lm_server:asp_down(SAP, Assoc).

-spec asp_active(SAP, Assoc) -> Result
	when
		SAP :: pid(),
		Assoc :: assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Active message to its peer.
asp_active(SAP, Assoc) ->
	m3ua_lm_server:asp_active(SAP, Assoc).

-spec asp_inactive(SAP, Assoc) -> Result
	when
		SAP :: pid(),
		Assoc :: assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Inactive message to its peer.
asp_inactive(SAP, Assoc) ->
	m3ua_lm_server:asp_inactive(SAP, Assoc).

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

