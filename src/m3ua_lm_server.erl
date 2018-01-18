%%% m3ua_lm_server.erl
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
%%% @doc This {@link //stdlib/gen_server. gen_server} behaviour callback
%%% 	module implements the layer management access point in the
%%% 	{@link //m3ua. m3ua} application.
%%%
-module(m3ua_lm_server).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(gen_server).

%% export the m3ua_lm_server API
-export([open/1, close/1]).
-export([sctp_establish/4, sctp_release/1, sctp_status/1]).
-export([asp_status/1, asp_up/1, asp_down/1, asp_active/1,
			asp_inactive/1]).

%% export the callbacks needed for gen_server behaviour
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
			terminate/2, code_change/3]).

-record(state,
		{sup :: pid(),
		server_sup :: pid(),
		client_sup :: pid(),
		eps = gb_trees:empty() :: gb_trees:tree(),
		saps = gb_trees:empty() :: gb_trees:tree(),
		reqs = gb_trees:empty() :: gb_trees:tree()}).

-include_lib("kernel/include/inet_sctp.hrl").

%%----------------------------------------------------------------------
%%  The m3ua_lm_server API
%%----------------------------------------------------------------------

-spec open(Args :: [term()]) -> {ok, EP :: pid()} | {error, Reason :: term()}.
%% @doc Open a new server end point (`EP').
%% @private
open(Args) when is_list(Args) ->
	gen_server:call(?MODULE, {open, Args}).

-spec close(EP :: pid()) -> ok | {error, Reason :: term()}.
%% @doc Close a previously opened end point (`EP').
%% @private
close(EP) ->
	gen_server:call(?MODULE, {close, EP}).

-spec sctp_establish(EndPoint, Address, Port, Options) -> Result
	when
		EndPoint :: pid(),
		Address :: inet:ip_address() | inet:hostname(),
		Port :: inet:port_number(),
		Options :: [gen_sctp:option()],
		Result :: {ok, SAP} | {error, Reason},
		SAP :: pid(),
		Reason :: term().
%% @doc Establish an SCTP association.
%% @private
sctp_establish(EndPoint, Address, Port, Options) ->
	gen_server:call(?MODULE, {sctp_establish,
			EndPoint, Address, Port, Options}).

-spec sctp_release(SAP) -> Result
	when
		SAP :: pid(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Release an established SCTP association.
%% @private
sctp_release(SAP) ->
	gen_server:call(?MODULE, {sctp_release, SAP}).

-spec sctp_status(SAP) -> Result
	when
		SAP :: pid(),
		Result :: {ok, AssocStatus} | {error, Reason},
		AssocStatus :: #sctp_status{},
		Reason :: term().
%% @doc Report the status of an SCTP association.
%% @private
sctp_status(SAP) ->
	gen_server:call(?MODULE, {sctp_status, SAP}).

-spec asp_status(SAP) -> Result
	when
		SAP :: pid(),
		Result :: {ok, AspState} | {error, Reason},
		AspState :: down | inactive | active,
		Reason :: term().
%% @doc Report the status of local or remote ASP.
%% @private
asp_status(SAP) ->
	gen_server:call(?MODULE, {asp_status, SAP}).

-spec asp_up(SAP) -> Result
	when
		SAP :: pid(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP start its operation
%%  and send an ASP Up message to its peer.
%% @private
asp_up(SAP) ->
	gen_server:call(?MODULE, {asp_up, SAP}).

-spec asp_down(SAP) -> Result
	when
		SAP :: pid(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP stop its operation
%%  and send an ASP Down message to its peer.
%% @private
asp_down(SAP) ->
	gen_server:call(?MODULE, {asp_down, SAP}).

-spec asp_active(SAP) -> Result
	when
		SAP :: pid(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Active message to its peer.
%% @private
asp_active(SAP) ->
	gen_server:call(?MODULE, {asp_active, SAP}).

-spec asp_inactive(SAP) -> Result
	when
		SAP :: pid(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Inactive message to its peer.
%% @private
asp_inactive(SAP) ->
	gen_server:call(?MODULE, {asp_inactive, SAP}).

%%----------------------------------------------------------------------
%%  The m3ua_lm_server gen_server callbacks
%%----------------------------------------------------------------------

-spec init(Args :: [term()]) ->
	{ok, State :: #state{}}
			| {ok, State :: #state{}, Timeout :: timeout()}
			| {stop, Reason :: term()} | ignore.
%% @doc Initialize the {@module} server.
%% @see //stdlib/gen_server:init/1
%% @private
%%
init([Sup] = _Args) when is_pid(Sup) ->
	process_flag(trap_exit, true),
	{ok, #state{sup = Sup}, 0}.

-spec handle_call(Request :: term(), From :: {pid(), Tag :: any()},
		State :: #state{}) ->
	{reply, Reply :: term(), NewState :: #state{}}
			| {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate}
			| {noreply, NewState :: #state{}}
			| {noreply, NewState :: #state{}, timeout() | hibernate}
			| {stop, Reason :: term(), Reply :: term(), NewState :: #state{}}
			| {stop, Reason :: term(), NewState :: #state{}}.
%% @doc Handle a request sent using {@link //stdlib/gen_server:call/2.
%% 	gen_server:call/2,3} or {@link //stdlib/gen_server:multi_call/2.
%% 	gen_server:multi_call/2,3,4}.
%% @see //stdlib/gen_server:handle_call/3
%% @private
%%
handle_call(Request, From, #state{server_sup = undefined,
		client_sup = undefined} = State) ->
	NewState = get_sups(State),
	handle_call(Request, From, NewState);
handle_call({open, Args}, {USAP, _Tag} = _From,
		#state{server_sup = ServerSup, eps = EndPoints} = State) ->
	case supervisor:start_child(ServerSup, [Args]) of
		{ok, EndPointSup} ->
			Children = supervisor:which_children(EndPointSup),
			{_, EP, _, _} = lists:keyfind(m3ua_endpoint_server,
					1, Children),
			NewEndPoints = gb_trees:insert(EP, USAP, EndPoints),
			NewState = State#state{eps = NewEndPoints},
			{reply, {ok, EP}, NewState};
		{error, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call({close, EP}, _From, #state{eps = EndPoints} = State) when is_pid(EP) ->
	try m3ua_endpoint_server:stop(EP) of
		ok ->
			NewEndPoints = gb_trees:delete(EP, EndPoints),
			NewState = State#state{eps = NewEndPoints},
			{reply, ok, NewState}
	catch
		exit:Reason ->
			{reply, {error, Reason}, State}
	end;
handle_call({sctp_establish, EndPoint, Address, Port, Options},
		_From, #state{saps = SAPs} = State) ->
	case gen_server:call(EndPoint, {establish, Address, Port, Options}) of
		{ok, SAP} ->
			NewSAPs = gb_trees:insert(SAP, EndPoint, SAPs),
			NewState = State#state{saps = NewSAPs},
			{reply, {ok, SAP}, NewState};
		{error, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call({sctp_release, _SAP}, _From, State) ->
	{reply, {error, not_implement}, State};
handle_call({sctp_status, _SAP}, _From, State) ->
	{reply, {error, not_implement}, State};
handle_call({asp_status, _SAP}, _From, State) ->
	{reply, {error, not_implement}, State};
handle_call({asp_up, SAP}, From, #state{reqs = Reqs} = State) ->
	Ref = make_ref(),
	gen_fsm:send_event(SAP, {asp_up, Ref, self()}),
	NewReqs = gb_trees:insert(Ref, From, Reqs),
	NewState = State#state{reqs = NewReqs},
	{noreply, NewState};
handle_call({asp_down, _SAP}, _From, State) ->
	{reply, {error, not_implement}, State};
handle_call({asp_active, _SAP}, _From, State) ->
	{reply, {error, not_implement}, State};
handle_call({asp_inactive, _SAP}, _From, State) ->
	{reply, {error, not_implement}, State}.

-spec handle_cast(Request :: term(), State :: #state{}) ->
	{noreply, NewState :: #state{}}
			| {noreply, NewState :: #state{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewState :: #state{}}.
%% @doc Handle a request sent using {@link //stdlib/gen_server:cast/2.
%% 	gen_server:cast/2} or {@link //stdlib/gen_server:abcast/2.
%% 	gen_server:abcast/2,3}.
%% @see //stdlib/gen_server:handle_cast/2
%% @private
%%
handle_cast(stop, State) ->
	{stop, normal, State};
handle_cast({asp_up, Ref, _ASP, _Identifier, _Info},
		#state{reqs = Reqs} = State) ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, ok);
		none ->
			{noreply, State}
	end.

-spec handle_info(Info :: timeout | term(), State::#state{}) ->
	{noreply, NewState :: #state{}}
			| {noreply, NewState :: #state{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewState :: #state{}}.
%% @doc Handle a received message.
%% @see //stdlib/gen_server:handle_info/2
%% @private
%%
handle_info(timeout, #state{server_sup = undefined,
		client_sup = undefined} = State) ->
	NewState = get_sups(State),
	{noreply, NewState}.

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State::#state{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_server:terminate/3
%% @private
%%
terminate(_Reason, _State) ->
	ok.

-spec code_change(OldVsn :: term() | {down, term()}, State :: #state{},
		Extra :: term()) ->
	{ok, NewState :: #state{}} | {error, Reason :: term()}.
%% @doc Update internal state data during a release upgrade&#047;downgrade.
%% @see //stdlib/gen_server:code_change/3
%% @private
%%
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

%% @hidden
get_sups(#state{sup = TopSup, server_sup = undefined,
		client_sup = undefined} = State) ->
	Siblings = supervisor:which_children(TopSup),
	{_, ServerSup, _, _} = lists:keyfind(m3ua_server_sup, 1, Siblings),
	{_, ClientSup, _, _} = lists:keyfind(m3ua_asp_sup, 1, Siblings),
	State#state{server_sup = ServerSup, client_sup = ClientSup}.

