%%% m3ua_endpoint_server.erl
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
%%% 	module implements the socket listener for incoming SCTP connections
%%%   in the {@link //m3ua. m3ua} application.
%%%
-module(m3ua_endpoint_server).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(gen_server).

%% export the m3ua_endpoint_server API
-export([stop/1]).

%% export the callbacks needed for gen_server behaviour
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
			terminate/2, code_change/3]).

-include_lib("kernel/include/inet_sctp.hrl").

-record(state,
		{sup :: pid(),
		asp_sup :: pid(),
		sgp_sup :: pid(),
		socket :: gen_sctp:sctp_socket(),
		port :: inet:port_number(),
		options :: [tuple()],
		sctp_role :: client | server,
		m3ua_role :: sgp | asp,
		fsms = gb_trees:empty() :: gb_trees:tree(),
		callback :: {Module :: atom(), State :: term()}}).

%%----------------------------------------------------------------------
%%  The m3ua_endpoint_server API
%%----------------------------------------------------------------------

-spec stop(EP :: pid()) -> ok.
%% @doc Close the socket and terminate the endpoint (`EP') server process.
stop(EP) when is_pid(EP) ->
	gen_server:call(EP, stop).

%%----------------------------------------------------------------------
%%  The m3ua_endpoint_server gen_server callbacks
%%----------------------------------------------------------------------

-spec init(Args :: [term()]) ->
	{ok, State :: #state{}}
			| {ok, State :: #state{}, Timeout :: timeout()}
			| {stop, Reason :: term()} | ignore.
%% @doc Initialize the {@module} server.
%% @see //stdlib/gen_server:init/1
%% @private
%%
init([Sup, Opts] = _Args) ->
	{SctpRole, Opts1} = case lists:keytake(sctp_role, 1, Opts) of
		{value, {sctp_role, R1}, O1} ->
			{R1, O1};
		false ->
			{client, Opts}
	end,
	{M3uaRole, Opts2} = case lists:keytake(m3ua_role, 1, Opts1) of
		{value, {m3ua_role, R2}, O2} ->
			{R2, O2};
		false ->
			{asp, Opts1}
	end,
	{CallBack, Opts3} = case lists:keytake(callback, 1, Opts2) of
		{value, {callback, R3}, O3} ->
			{R3, O3};
		false ->
			{undefined, Opts2}
	end,
	Options = [{active, once},
			{sctp_events, #sctp_event_subscribe{adaptation_layer_event = true}}
			| Opts3],
	case gen_sctp:open(Options) of
		{ok, Socket} ->
			State = #state{sup = Sup, socket = Socket,
					sctp_role = SctpRole, m3ua_role = M3uaRole,
					options = Options, callback = CallBack},
			init1(State);
		{error, Reason} ->
			{stop, Reason}
	end.
%% @hidden
init1(#state{sctp_role = server, socket = Socket} = State) ->
	case gen_sctp:listen(Socket, true) of
		ok ->
			init2(State);
		{error, Reason} ->
			gen_sctp:close(Socket),
			{stop, Reason}
	end;
init1(#state{sctp_role = client} = State) ->
	init2(State).
%% @hidden
init2(#state{socket = Socket} = State) ->
	case inet:sockname(Socket) of
		{ok, {_, Port}} ->
			process_flag(trap_exit, true),
			NewState = State#state{port = Port},
			{ok, NewState, 0};
		{error, Reason} ->
			gen_sctp:close(Socket),
			{stop, Reason}
	end.

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
handle_call(Request, From, #state{sgp_sup = undefined,
		asp_sup = undefined} = State) ->
	NewState = get_sup(State),
	handle_call(Request, From, NewState);
handle_call({establish, Address, Port, Options}, _From,
		#state{sctp_role = client, asp_sup = Sup} = State) ->
	connect(Address, Port, Options, Sup, State);
handle_call({getstat, undefined}, _From, #state{socket = Socket} = State) ->
	{reply, inet:getstat(Socket), State};
handle_call({getstat, Options}, _From, #state{socket = Socket} = State) ->
	{reply, inet:getstat(Socket, Options), State};
handle_call(stop, _From, State) ->
	{stop, normal, ok, State}.

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
	{stop, normal, State}.

-spec handle_info(Info :: timeout | term(), State::#state{}) ->
	{noreply, NewState :: #state{}}
			| {noreply, NewState :: #state{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewState :: #state{}}.
%% @doc Handle a received message.
%% @see //stdlib/gen_server:handle_info/2
%% @private
%%
handle_info(timeout, #state{sgp_sup = undefined, asp_sup = undefined} = State) ->
	NewState = get_sup(State),
   {noreply, NewState};
handle_info({sctp, Socket, PeerAddr, PeerPort, {_AncData,
		#sctp_assoc_change{state = comm_up} = AssocChange}},
		#state{sctp_role = server, sgp_sup = Sup,
		socket = Socket} = State) ->
	accept(Socket, PeerAddr, PeerPort, AssocChange, Sup, State);
handle_info({sctp, Socket, PeerAddr, PeerPort, {_AncData,
		#sctp_assoc_change{state = comm_up} = AssocChange}},
		#state{sctp_role = server, sgp_sup = Sup,
		socket = Socket} = State) ->
	accept(Socket, PeerAddr, PeerPort, AssocChange, Sup, State);
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{_AncData, #sctp_paddr_change{}}} = _Msg, State) ->
	inet:setopts(Socket, [{active, once}]),
	{noreply, State}.

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
get_sup(#state{sup = Sup, asp_sup = undefined, sgp_sup = undefined} = State) ->
	Children = supervisor:which_children(Sup),
	{_, SgpSup, _, _} = lists:keyfind(m3ua_sgp_sup, 1, Children),
	{_, AspSup, _, _} = lists:keyfind(m3ua_asp_sup, 1, Children),
	State#state{asp_sup = AspSup, sgp_sup = SgpSup}.

%% @hidden
connect(Address, Port, Options, FsmSup,
		#state{socket = Socket, fsms = Fsms, callback = CbMode} = State) ->
	case gen_sctp:connect(Socket, Address, Port, Options) of
		{ok, #sctp_assoc_change{assoc_id = Assoc}  = AssocChange} ->
			case gen_sctp:peeloff(Socket, Assoc) of
				{ok, NewSocket} ->
				   case supervisor:start_child(FsmSup,
							[[client, NewSocket, Address, Port, AssocChange, CbMode],
							[{debug, [trace]}]]) of
						{ok, Fsm} ->
							case gen_sctp:controlling_process(NewSocket, Fsm) of
								ok ->
									inet:setopts(NewSocket, [{active, once}]),
									inet:setopts(Socket, [{active, once}]),
									NewFsms = gb_trees:insert(Assoc, Fsm, Fsms),
									NewState = State#state{fsms = NewFsms},
									{reply, {ok, Fsm, Assoc}, NewState};
								{error, Reason} ->
									{stop, Reason, State}
							end;
						{error, Reason} ->
							{stop, Reason, State}
					end;
				{error, Reason} ->
					{stop, Reason, State}
			end;
		{error, Reason} ->
			{reply, {error, Reason}, State}
	end.

%% @hidden
accept(Socket, Address, Port,
		#sctp_assoc_change{assoc_id = Assoc} = AssocChange,
		Sup, #state{fsms = Fsms, callback = CbMode} = State) ->
	case gen_sctp:peeloff(Socket, Assoc) of
		{ok, NewSocket} ->
			case supervisor:start_child(Sup, [[server,
					NewSocket, Address, Port, AssocChange, CbMode], [{debug, [trace]}]]) of
				{ok, Fsm} ->
					case gen_sctp:controlling_process(NewSocket, Fsm) of
						ok ->
							inet:setopts(NewSocket, [{active, once}]),
							inet:setopts(Socket, [{active, once}]),
							NewFsms = gb_trees:insert(Assoc, Fsm, Fsms),
							NewState = State#state{fsms = NewFsms},
							{noreply, NewState};
						{error, Reason} ->
							{stop, Reason, State}
					end;
				{error, Reason} ->
					{stop, Reason, State}
			end;
		{error, Reason} ->
			{stop, Reason, State}
	end.

