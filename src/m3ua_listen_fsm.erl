%%% m3ua_listen_fsm.erl
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
%%% @doc This {@link //stdlib/gen_fsm. gen_fsm} behaviour callback
%%% 	module implements the socket handler for incoming SCTP connections
%%%   in the {@link //m3ua. m3ua} application.
%%%
-module(m3ua_listen_fsm).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(gen_fsm).

%% export the callbacks needed for gen_fsm behaviour
-export([init/1, handle_event/3, handle_sync_event/4,
		handle_info/3, terminate/3, code_change/4]).

%% export the gen_fsm state callbacks
-export([listening/2]).

-include_lib("kernel/include/inet_sctp.hrl").

-record(statedata,
		{sup :: undefined | pid(),
		name :: term(),
		fsm_sup :: undefined | pid(),
		socket :: gen_sctp:sctp_socket(),
		port :: undefined | inet:port_number(),
		options :: [tuple()],
		role :: sgp | asp,
		registration :: dynamic | static,
		use_rc :: boolean(),
		local_port :: inet:port_number(),
		fsms = gb_trees:empty() :: gb_trees:tree(Assoc :: gen_sctp:assoc_id(),
				Fsm :: pid()),
		callback :: {Module :: atom(), State :: term()}}).

%%----------------------------------------------------------------------
%%  The m3ua_listen_fsm gen_fsm callbacks
%%----------------------------------------------------------------------

-spec init(Args :: [term()]) ->
	{ok, StateName :: atom(), StateData :: #statedata{}}
			| {ok, StateName :: atom(),
					StateData :: #statedata{}, timeout() | hibernate}
			| {stop, Reason :: term()} | ignore.
%% @doc Initialize the {@module} finite state machine.
%% @see //stdlib/gen_fsm:init/1
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
		{value, {role, asp}, O2} ->
			{asp, O2};
		{value, {role, sgp}, O2} ->
			{sgp, O2};
		false ->
			{sgp, Opts1}
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
			StateData = #statedata{sup = Sup, socket = Socket,
					role = Role, registration = Registration,
					use_rc = UseRC, options = Options,
					name = Name, callback = Callback},
			case gen_sctp:listen(Socket, true) of
				ok ->
					case inet:sockname(Socket) of
						{ok, {_, Port}} ->
							process_flag(trap_exit, true),
							NewStateData = StateData#statedata{port = Port},
							{ok, listening, NewStateData, 0};
						{error, Reason} ->
							gen_sctp:close(Socket),
							{stop, Reason}
					end;
				{error, Reason} ->
					gen_sctp:close(Socket),
					{stop, Reason}
			end;
		{error, Reason} ->
			{stop, Reason}
	end.

-spec listening(Event :: timeout | term(), StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(),
					NewStateData :: #statedata{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle events sent with {@link //stdlib/gen_fsm:send_event/2.
%% 	gen_fsm:send_event/2} in the <b>listening</b> state.
%% @private
%%
listening(timeout, #statedata{fsm_sup = undefined} = StateData) ->
   {next_state, listening, get_sup(StateData)};
listening({'M-SCTP_RELEASE', request, Ref, From},
		#statedata{socket = Socket} = StateData) ->
	gen_server:cast(From,
			{'M-SCTP_RELEASE', confirm, Ref, gen_sctp:close(Socket)}),
	{stop, {shutdown, {self(), release}}, StateData}.

-spec handle_event(Event :: term(), StateName :: atom(),
		StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(),
					NewStateData :: #statedata{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with
%% 	{@link //stdlib/gen_fsm:send_all_state_event/2.
%% 	gen_fsm:send_all_state_event/2}.
%% @see //stdlib/gen_fsm:handle_event/3
%% @private
%%
handle_event(_Event, _StateName, StateData) ->
	{stop, unimplemented, StateData}.

-spec handle_sync_event(Event :: term(), From :: {pid(), Tag :: term()},
		StateName :: atom(), StateData :: #statedata{}) ->
		{reply, Reply :: term(), NextStateName :: atom(),
		NewStateData :: #statedata{}} | {stop, Reason :: term(),
		Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with
%% 	{@link //stdlib/gen_fsm:sync_send_all_state_event/2.
%% 	gen_fsm:sync_send_all_state_event/2,3}.
%% @see //stdlib/gen_fsm:handle_sync_event/4
%% @private
%%
handle_sync_event(getassoc, _From, StateName,
		#statedata{fsms = Fsms} = StateData) ->
	{reply, gb_trees:keys(Fsms), StateName, StateData};
handle_sync_event({getstat, undefined}, _From, StateName,
		#statedata{socket = Socket} = StateData) ->
	{reply, inet:getstat(Socket), StateName, StateData};
handle_sync_event({getstat, Options}, _From, StateName,
		#statedata{socket = Socket} = StateData) ->
	{reply, inet:getstat(Socket, Options), StateName, StateData}.

-spec handle_info(Info :: term(), StateName :: atom(),
		StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(),
					NewStateData :: #statedata{}, timeout() | hibernate}
			| {stop, Reason :: normal | term(), NewStateData :: #statedata{}}.
%% @doc Handle a received message.
%% @see //stdlib/gen_fsm:handle_info/3
%% @private
handle_info({sctp, Socket, PeerAddr, PeerPort,
		{_AncData, #sctp_assoc_change{state = comm_up} = AssocChange}},
		listening, #statedata{fsm_sup = FsmSup, socket = Socket} = StateData) ->
	accept(Socket, PeerAddr, PeerPort, AssocChange, FsmSup, StateData);
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{_AncData, #sctp_paddr_change{}}}, StateName, StateData) ->
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, StateData};
handle_info({'EXIT', _Pid, {shutdown, {{_EP, Assoc}, _Reason}}},
		StateName, #statedata{fsms = Fsms} = StateData) ->
	NewFsms = gb_trees:delete(Assoc, Fsms),
	NewStateData = StateData#statedata{fsms = NewFsms},
	{next_state, StateName, NewStateData};
handle_info({'EXIT', Pid, _Reason}, StateName,
		#statedata{fsms = Fsms} = StateData) ->
	Fdel = fun Fdel({Assoc, P, _Iter}) when P ==  Pid ->
		       Assoc;
		   Fdel({_Key, _Val, Iter}) ->
		       Fdel(gb_trees:next(Iter));
		   Fdel(none) ->
		       none
	end,
	Iter = gb_trees:iterator(Fsms),
	Key = Fdel(gb_trees:next(Iter)),
	NewFsms = gb_trees:delete_any(Key, Fsms),
	NewStateData = StateData#statedata{fsms = NewFsms},
	{next_state, StateName, NewStateData}.

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		StateName :: atom(), StateData :: #statedata{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_fsm:terminate/3
%% @private
%%
terminate(normal = _Reason, _StateName, _StateData) ->
	ok;
terminate(shutdown = _Reason, _StateName, _StateData) ->
	ok;
terminate({shutdown, _} = _Reason, _StateName, _StateData) ->
	ok;
terminate(Reason, _StateName, StateData) ->
	error_logger:error_report(["Shutdown",
			{module, ?MODULE}, {pid, self()},
			{reason, Reason}, {statedata, StateData}]).

-spec code_change(OldVsn :: term() | {down, term()}, StateName :: atom(),
		StateData :: term(), Extra :: term()) ->
	{ok, NextStateName :: atom(), NewStateData :: #statedata{}}.
%% @doc Update internal state data during a release upgrade&#047;downgrade.
%% @see //stdlib/gen_fsm:code_change/4
%% @private
%%
code_change(_OldVsn, StateName, StateData, _Extra) ->
	{ok, StateName, StateData}.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

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
accept(Socket, Address, Port,
		#sctp_assoc_change{assoc_id = Assoc} = AssocChange,
		Sup, #statedata{fsms = Fsms, name = Name, callback = Cb,
		registration = Reg, use_rc = UseRC} = StateData) ->
	case gen_sctp:peeloff(Socket, Assoc) of
		{ok, NewSocket} ->
			case supervisor:start_child(Sup, [[NewSocket, Address, Port,
					AssocChange, self(), Name, Cb, Reg, UseRC], []]) of
				{ok, Fsm} ->
					case gen_sctp:controlling_process(NewSocket, Fsm) of
						ok ->
							inet:setopts(NewSocket, [{active, once}]),
							inet:setopts(Socket, [{active, once}]),
							NewFsms = gb_trees:insert(Assoc, Fsm, Fsms),
							link(Fsm),
							NewStateData = StateData#statedata{fsms = NewFsms},
							{next_state, listening, NewStateData};
						{error, Reason} ->
							{stop, Reason, StateData}
					end;
				{error, Reason} ->
					{stop, Reason, StateData}
			end;
		{error, Reason} ->
			{stop, Reason, StateData}
	end.

