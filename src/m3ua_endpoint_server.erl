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

%% export the callbacks needed for gen_server behaviour
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
			terminate/2, code_change/3]).

-include_lib("kernel/include/inet_sctp.hrl").

-record(state,
		{sup :: undefined | pid(),
		asp_sup :: undefined | pid(),
		sgp_sup :: undefined | pid(),
		socket :: gen_sctp:sctp_socket(),
		port :: undefined | inet:port_number(),
		options :: [tuple()],
		sctp_role :: client | server,
		m3ua_role :: sgp | asp,
		registration :: dynamic | static,
		use_rc :: boolean(),
		fsms = gb_trees:empty() :: gb_trees:tree(),
		callback :: {Module :: atom(), State :: term()}}).

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
init([Sup, [Callback, Opts]] = _Args) ->
	{SctpRole, Opts1} = case lists:keytake(sctp_role, 1, Opts) of
		{value, {sctp_role, R1}, O1} ->
			{R1, O1};
		false ->
			{client, Opts}
	end,
	{M3uaRole, Opts2} = case lists:keytake(m3ua_role, 1, Opts1) of
		{value, {m3ua_role, asp}, O2} ->
			{asp, O2};
		{value, {m3ua_role, sgp}, O2} ->
			{sgp, O2};
		false ->
			{asp, Opts1}
	end,
	{Registration, Opts3} = case lists:keytake(registration, 1, Opts2) of
		{value, {registration, R3}, O3} ->
			{R3, O3};
		false ->
			{dynamic, Opts2}
	end,
	{UseRC, Opts4} = case lists:keytake(use_rc, 1, Opts3) of
		{value, {use_rc, R4}, O4} ->
			{R4, O4};
		false ->
			{true, Opts3}
	end,
	Options = [{active, once},
			{sctp_events, #sctp_event_subscribe{adaptation_layer_event = true}},
			{sctp_default_send_param, #sctp_sndrcvinfo{ppid = 3}},
			{sctp_adaptation_layer, #sctp_setadaptation{adaptation_ind = 3}}
			| Opts4],
	case gen_sctp:open(Options) of
		{ok, Socket} ->
			State = #state{sup = Sup, socket = Socket, sctp_role = SctpRole,
					m3ua_role = M3uaRole, registration = Registration,
					use_rc = UseRC, options = Options,
					callback = Callback},
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
handle_call(getassoc, _From, #state{m3ua_role = Role, fsms = Fsms} = State) ->
	{reply, {Role, gb_trees:keys(Fsms)}, State};
handle_call({getstat, undefined}, _From, #state{socket = Socket} = State) ->
	{reply, inet:getstat(Socket), State};
handle_call({getstat, Options}, _From, #state{socket = Socket} = State) ->
	{reply, inet:getstat(Socket, Options), State}.

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
handle_cast({'M-SCTP_ESTABLISH', request, Ref, From, Address, Port, Options},
		#state{sctp_role = client, m3ua_role = asp, asp_sup = Sup} = State) ->
	connect(Address, Port, Options, Ref, From, Sup, State);
handle_cast({'M-SCTP_ESTABLISH', request, Ref, From, Address, Port, Options},
		#state{sctp_role = client, m3ua_role = sgp, sgp_sup = Sup} = State) ->
	connect(Address, Port, Options, Ref, From, Sup, State);
handle_cast({'M-SCTP_RELEASE', request, Ref, From}, #state{socket = Socket} = State) ->
	gen_server:cast(From,
			{'M-SCTP_RELEASE', confirm, Ref, gen_sctp:close(Socket)}),
	{stop, {shutdown, {self(), release}}, State};
handle_cast(timeout, State) ->
	{stop, not_implemented, State}.

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
		#state{sctp_role = server, m3ua_role = sgp,
		sgp_sup = FsmSup, socket = Socket} = State) ->
	accept(Socket, PeerAddr, PeerPort, AssocChange, FsmSup, State);
handle_info({sctp, Socket, PeerAddr, PeerPort, {_AncData,
		#sctp_assoc_change{state = comm_up} = AssocChange}},
		#state{sctp_role = server, m3ua_role = asp,
		asp_sup = FsmSup, socket = Socket} = State) ->
	accept(Socket, PeerAddr, PeerPort, AssocChange, FsmSup, State);
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{_AncData, #sctp_paddr_change{}}} = _Msg, State) ->
	inet:setopts(Socket, [{active, once}]),
	{noreply, State};
handle_info({'EXIT', _Pid, {shutdown,{{_EP, Assoc}, _Reason}}},
		#state{fsms = Fsms} = State) ->
	NewFsms = gb_trees:delete(Assoc, Fsms),
	NewState = State#state{fsms = NewFsms},
	{noreply, NewState};
handle_info({'EXIT', Pid, _Reason}, #state{fsms = Fsms} = State) ->
	Fdel = fun Fdel({Assoc, P, _Iter}) when P ==  Pid ->
		       Assoc;
		   Fdel({_Key, _Val, Iter}) ->
		       Fdel(gb_trees:next(Iter));
		   Fdel(none) ->
		       none
	end,
	Iter = gb_trees:iterator(Fsms),
	Key = Fdel(gb_trees:next(Iter)),
	NewFsms = gb_trees:delete(Key, Fsms),
	NewState = State#state{fsms = NewFsms},
	{noreply, NewState}.

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State::#state{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_server:terminate/3
%% @private
%%
terminate(normal = _Reason, _State) ->
	ok;
terminate(shutdown, _State) ->
	ok;
terminate({shutdown, _}, _State) ->
	ok;
terminate(Reason, State) ->
	error_logger:error_report(["Abnormal process termination",
			{module, ?MODULE}, {pid, self()},
			{reason, Reason}, {state, State}]).

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
connect(Address, Port, Options, Ref, From, FsmSup,
		#state{socket = Socket, fsms = Fsms, callback = Cb,
		registration = Reg, use_rc = UseRC} = State) ->
	case gen_sctp:connect(Socket, Address, Port, Options) of
		{ok, #sctp_assoc_change{assoc_id = Assoc} = AssocChange} ->
		   case supervisor:start_child(FsmSup, [[client, Socket,
					Address, Port, AssocChange, self(), Cb, Reg, UseRC], []]) of
				{ok, Fsm} ->
					case gen_sctp:controlling_process(Socket, Fsm) of
						ok ->
							inet:setopts(Socket, [{active, once}]),
							NewFsms = gb_trees:insert(Assoc, Fsm, Fsms),
							link(Fsm),
							gen_server:cast(From, {'CONNECT', Ref, {ok, self(), Fsm, Assoc}}),
							NewState = State#state{fsms = NewFsms},
							{noreply, NewState};
						{error, Reason} ->
							{stop, Reason, State}
					end;
				{error, Reason} ->
					{stop, Reason, State}
			end;
		{error, Reason} ->
			gen_server:cast(From, {'CONNECT', Ref, {error, Reason}}),
			{noreply, State}
	end.

%% @hidden
accept(Socket, Address, Port,
		#sctp_assoc_change{assoc_id = Assoc} = AssocChange,
		Sup, #state{fsms = Fsms, callback = Cb,
		registration = Reg, use_rc = UseRC} = State) ->
	case gen_sctp:peeloff(Socket, Assoc) of
		{ok, NewSocket} ->
			case supervisor:start_child(Sup, [[server, NewSocket,
					Address, Port, AssocChange, self(), Cb, Reg, UseRC], []]) of
				{ok, Fsm} ->
					case gen_sctp:controlling_process(NewSocket, Fsm) of
						ok ->
							inet:setopts(NewSocket, [{active, once}]),
							inet:setopts(Socket, [{active, once}]),
							NewFsms = gb_trees:insert(Assoc, Fsm, Fsms),
							link(Fsm),
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

