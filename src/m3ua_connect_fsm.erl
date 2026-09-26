%%% m3ua_connect_fsm.erl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2015-2025 SigScale Global Inc.
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
%%% @doc This {@link //stdlib/gen_statem. gen_statem} behaviour callback
%%% 	module implements the socket handler for outgoing SCTP connections
%%%   in the {@link //m3ua. m3ua} application.
%%%
-module(m3ua_connect_fsm).
-copyright('Copyright (c) 2015-2025 SigScale Global Inc.').

-behaviour(gen_statem).

%% export the callbacks needed for gen_statem behaviour
-export([init/1, callback_mode/0, terminate/3, code_change/4]).

%% export the gen_statem state callbacks
-export([connecting/3, connected/3]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-record(statedata,
		{sup :: undefined | pid(),
		name :: term(),
		fsm_sup :: undefined | pid(),
		socket :: undefined | gen_sctp:sctp_socket(),
		options :: [tuple()],
		cb_options :: term(),
		role :: sgp | asp,
		static :: boolean(),
		use_rc :: boolean(),
		local_addr :: undefined | inet:ip_address(),
		local_port :: undefined | inet:port_number(),
		remote_addr :: inet:ip_address(),
		remote_port :: inet:port_number(),
		remote_opts :: [gen_sctp:option()],
		assoc :: gen_sctp:assoc_id(),
		fsm :: undefined | pid(),
		callback :: {Module :: atom(), State :: term()}}).

-define(RETRY_WAIT, 8000).
-define(ERROR_WAIT, 60000).

%%----------------------------------------------------------------------
%%  The m3ua_connect_fsm gen_statem callbacks
%%----------------------------------------------------------------------

-spec callback_mode() -> Result
	when
		Result :: gen_statem:callback_mode_result().
%% @doc Set the callback mode of the callback module.
%% @see //stdlib/gen_statem:callback_mode/0
%% @private
%%
callback_mode() ->
	[state_functions].

-spec init(Args :: [term()]) ->
	{ok, StateName :: atom(), StateData :: #statedata{}}
			| {ok, StateName :: atom(), StateData :: #statedata{},
					Actions :: [gen_statem:action()] | gen_statem:action()}
			| {stop, Reason :: term()} | ignore.
%% @doc Initialize the {@module} finite state machine.
%% @see //stdlib/gen_statem:init/1
%% @private
%%
init([Sup, Callback, Opts] = _Args) ->
	{Name, Opts1} = case lists:keytake(name, 1, Opts) of
		{value, {name, R1}, O1} ->
			{R1, O1};
		false ->
			{make_ref(), Opts}
	end,
	{Role, Opts2} = case lists:keytake(role, 1, Opts1) of
		{value, {role, sgp}, O2} ->
			{sgp, O2};
		{value, {role, asp}, O2} ->
			{asp, O2};
		false ->
			{sgp, Opts1}
	end,
	{Static, Opts3} = case lists:keytake(static, 1, Opts2) of
		{value, {static, R3}, O3} ->
			{R3, O3};
		false ->
			{false, Opts2}
	end,
	{UseRC, Opts4} = case lists:keytake(use_rc, 1, Opts3) of
		{value, {use_rc, R4}, O4} ->
			{R4, O4};
		false ->
			{true, Opts3}
	end,
	{CbOpts, Opts5} = case lists:keytake(cb_opts, 1, Opts4) of
		{value, {cb_opts, R5}, O5} ->
			{R5, O5};
		false ->
			{[], Opts4}
	end,
	PpiOptions = [{sctp_events, #sctp_event_subscribe{adaptation_layer_event = true}},
			{sctp_default_send_param, #sctp_sndrcvinfo{ppid = 3}},
			{sctp_adaptation_layer, #sctp_setadaptation{adaptation_ind = 3}}],
	Opts6 = case lists:keytake(ppi, 1, Opts5) of
		{value, {ppi, false}, O6} ->
			O6;
		{value, {ppi, true}, O6} ->
			[O6] ++ PpiOptions;
		false ->
			Opts5 ++ PpiOptions
	end,
	case lists:keytake(connect, 1, Opts6) of
		{value, {connect, Raddr, Rport, Ropts}, O7} ->
			Options = [{active, once}, {reuseaddr, true} | O7],
			process_flag(trap_exit, true),
			StateData = #statedata{sup = Sup, role = Role,
					name = Name, static = Static, use_rc = UseRC,
					options = Options, cb_options = CbOpts, callback = Callback,
					remote_addr = Raddr, remote_port = Rport,
					remote_opts = Ropts},
			{ok, connecting, StateData, {timeout, 0, timeout}};
		false ->
			{stop, badarg}
	end.

-spec connecting(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events received in the <b>connecting</b> state.
%% @private
%%
connecting(timeout, EventContent,
		#statedata{fsm_sup = undefined} = StateData) ->
	connecting(timeout, EventContent, get_sup(StateData));
connecting(timeout, _EventContent, #statedata{options = LocalOptions,
		remote_addr = RemoteAddress, remote_port = RemotePort,
		remote_opts = ConnectOptions, name = Name} = StateData) ->
	case gen_sctp:open(LocalOptions) of
		{ok, Socket} ->
			case inet:sockname(Socket) of
				{ok, {LocalAddress, LocalPort}} ->
					case gen_sctp:connect_init(Socket,
							RemoteAddress, RemotePort, ConnectOptions) of
						ok ->
							NewStateData = StateData#statedata{socket = Socket,
									local_addr = LocalAddress,
									local_port = LocalPort},
							{next_state, connecting, NewStateData};
						{error, ReasonConnect} ->
							error_logger:error_report(["Connect failed",
									{error, ReasonConnect}, {name, Name},
									{address, RemoteAddress}, {port, RemotePort},
									{options, ConnectOptions}]),
							gen_sctp:close(Socket),
							NewStateData = StateData#statedata{socket = undefined,
									local_addr = undefined,
									local_port = undefined},
							{next_state, connecting, NewStateData,
									{timeout, ?ERROR_WAIT, timeout}}
					end;
				{error, ReasonPort} ->
					error_logger:error_report(["Failed to get port number",
							{module, ?MODULE}, {error, ReasonPort},
							{state, StateData}]),
					gen_sctp:close(Socket),
					{stop, ReasonPort}
			end;
		{error, ReasonOpen} ->
			error_logger:error_report(["Failed to open socket",
					{module, ?MODULE}, {error, ReasonOpen},
					{options, LocalOptions}, {state, StateData}]),
			{stop, ReasonOpen}
	end;
connecting(cast, {'M-SCTP_RELEASE', request, Ref, From},
		#statedata{socket = Socket} = StateData) ->
	gen_server:cast(From, {'M-SCTP_RELEASE', confirm, Ref, gen_sctp:close(Socket)}),
	{stop, {shutdown, {self(), release}}, StateData};
connecting(EventType, EventContent, StateData) ->
	handle_event(EventType, EventContent, connecting, StateData).

-spec connected(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events received in the <b>connected</b> state.
%% @private
%%
connected(cast, {'M-SCTP_RELEASE', request, Ref, From},
		#statedata{socket = Socket} = StateData) ->
	gen_server:cast(From,
			{'M-SCTP_RELEASE', confirm, Ref, gen_sctp:close(Socket)}),
	{stop, {shutdown, {self(), release}}, StateData};
connected(EventType, EventContent, StateData) ->
	handle_event(EventType, EventContent, connected, StateData).

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		StateName :: atom(), StateData :: #statedata{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_statem:terminate/3
%% @private
%%
terminate(_Reason, _StateName, #statedata{socket = undefined}) ->
	ok;
terminate(_Reason, _StateName, #statedata{socket = Socket} = StateData) ->
	case gen_sctp:close(Socket) of
		ok ->
			ok;
		{error, Reason1} ->
			error_logger:error_report(["Failed to close socket",
					{module, ?MODULE}, {socket, Socket},
					{error, Reason1}, {state, StateData}])
	end.

-spec code_change(OldVsn :: term() | {down, term()}, StateName :: atom(),
		StateData :: term(), Extra :: term()) ->
	{ok, NextStateName :: atom(), NewStateData :: #statedata{}}.
%% @doc Update internal state data during a release upgrade&#047;downgrade.
%% @see //stdlib/gen_statem:code_change/4
%% @private
%%
code_change(_OldVsn, StateName, StateData, _Extra) ->
	{ok, StateName, StateData}.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

-spec handle_event(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateName :: atom(),
		StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events common to all states.
%% @hidden
handle_event({call, From}, getassoc, connecting,
		#statedata{assoc = undefined} = StateData) ->
	{next_state, connecting, StateData,
			[{reply, From, []}, {timeout, ?RETRY_WAIT, timeout}]};
handle_event({call, From}, getassoc, connected,
		#statedata{assoc = undefined} = StateData) ->
	{next_state, connected, StateData, {reply, From, []}};
handle_event({call, From}, getassoc, connecting,
		#statedata{assoc = Assoc} = StateData) ->
	{next_state, connecting, StateData,
			[{reply, From, [Assoc]}, {timeout, ?RETRY_WAIT, timeout}]};
handle_event({call, From}, getassoc, connected,
		#statedata{assoc = Assoc} = StateData) ->
	{next_state, connected, StateData, {reply, From, [Assoc]}};
handle_event({call, From}, {getstat, undefined}, connecting,
		#statedata{socket = Socket} = StateData) ->
	Reply = inet:getstat(Socket),
	{next_state, connecting, StateData,
			[{reply, From, Reply}, {timeout, ?RETRY_WAIT, timeout}]};
handle_event({call, From}, {getstat, undefined}, connected,
		#statedata{socket = Socket} = StateData) ->
	{next_state, connected, StateData, {reply, From, inet:getstat(Socket)}};
handle_event({call, From}, {getstat, Options}, connecting,
		#statedata{socket = Socket} = StateData) ->
	Reply = inet:getstat(Socket, Options),
	{next_state, connecting, StateData,
			[{reply, From, Reply}, {timeout, ?RETRY_WAIT, timeout}]};
handle_event({call, From}, {getstat, Options}, connected,
		#statedata{socket = Socket} = StateData) ->
	Reply = inet:getstat(Socket, Options),
	{next_state, connected, StateData, {reply, From, Reply}};
handle_event({call, From}, getep, StateName,
		#statedata{name = Name, role = Role,
		local_addr = Laddr, local_port = Lport,
		remote_addr = Raddr, remote_port = Rport} = StateData) ->
	Reply = {Name, client, Role, {Laddr, Lport}, {Raddr, Rport}},
	{next_state, StateName, StateData, {reply, From, Reply}};
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{_AncData, #sctp_assoc_change{state = comm_up,
		assoc_id = Assoc} = AssocChange}}, connecting,
		#statedata{socket = Socket} = StateData) ->
	NewStateData = StateData#statedata{socket = Socket, assoc = Assoc},
	handle_connect(AssocChange, NewStateData);
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{_AncData, #sctp_assoc_change{state = _Reason}}}, connecting,
		#statedata{socket = Socket} = StateData) ->
	gen_sctp:close(Socket),
	NewStateData = StateData#statedata{socket = undefined},
	{next_state, connecting, NewStateData, {timeout, ?RETRY_WAIT, timeout}};
handle_event(info, {'EXIT', Fsm, {shutdown, {{EP, _Assoc}, Reason}}},
		_StateName, #statedata{socket = Socket, fsm = Fsm} = StateData) ->
	gen_sctp:close(Socket),
	{stop, {shutdown, {EP, Reason}}, StateData};
handle_event(info, {'EXIT', Fsm, Reason}, _StateName,
		#statedata{socket = undefined, fsm = Fsm} = StateData) ->
	{stop, Reason, StateData};
handle_event(info, {'EXIT', Fsm, Reason}, _StateName,
		#statedata{socket = Socket, fsm = Fsm} = StateData) ->
	gen_sctp:close(Socket),
	{stop, Reason, StateData};
handle_event(cast, _EventContent, _StateName, StateData) ->
	{stop, unimplemented, StateData}.

%% @hidden
get_sup(#statedata{role = asp, sup = Sup} = StateData) ->
	Children = supervisor:which_children(Sup),
	{_, AspSup, _, _} = lists:keyfind(m3ua_asp_sup, 1, Children),
	StateData#statedata{fsm_sup = AspSup};
get_sup(#statedata{role = sgp, sup = Sup} = StateData) ->
	Children = supervisor:which_children(Sup),
	{_, SgpSup, _, _} = lists:keyfind(m3ua_sgp_sup, 1, Children),
	StateData#statedata{fsm_sup = SgpSup}.

%% @hidden
handle_connect(AssocChange, #statedata{socket = Socket,
		fsm_sup = Sup, remote_addr = Address, remote_port = Port,
		name = Name, cb_options = CbOpts, callback = Cb, static = Static,
		use_rc = UseRC} = StateData) ->
	case supervisor:start_child(Sup, [[Socket, Address, Port,
			AssocChange, self(), Name, Cb, Static, UseRC, CbOpts], []]) of
		{ok, Fsm} ->
			case gen_sctp:controlling_process(Socket, Fsm) of
				ok ->
					link(Fsm),
					NewStateData = StateData#statedata{fsm = Fsm},
					{next_state, connected, NewStateData};
				{error, Reason} ->
					{stop, Reason, StateData}
			end;
		{error, Reason} ->
			{stop, Reason, StateData}
	end.

