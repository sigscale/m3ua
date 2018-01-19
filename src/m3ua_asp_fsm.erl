%%% m3ua_asp_fsm.erl
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
%%% @doc This {@link //stdlib/gen_fsm. gen_fsm} behaviour callback module
%%% 	implements a communicating finite state machine within the
%%% 	{@link //m3ua. m3ua} application handling an outgoing SCTP
%%%   association to a server.
%%%
-module(m3ua_asp_fsm).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(gen_fsm).

%% export the m3ua_asp_fsm API
-export([]).

%% export the callbacks needed for gen_fsm behaviour
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3,
			terminate/3, code_change/4]).

%% export the gen_fsm state callbacks
-export([down/2, down/3, inactive/2, inactive/3, active/2, active/3]).

-record(statedata,
		{sctp_role :: client | server,
		socket :: scpt:sctp_socket(),
		peer_addr :: inet:ip_address(),
		peer_port :: inet:port_number(),
		in_streams :: non_neg_integer(),
		out_streams :: non_neg_integer(),
		assoc :: gen_sctp:assoc_id(),
		ual :: non_neg_integer(),
		req :: tuple()}).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

%%----------------------------------------------------------------------
%%  The m3ua_asp_fsm API
%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%%  The m3ua_asp_fsm gen_fsm callbacks
%%----------------------------------------------------------------------

-spec init(Args :: [term()]) ->
	{ok, StateName :: atom(), StateData :: #statedata{}}
			| {ok, StateName :: atom(), StateData :: #statedata{}, timeout() | hibernate}
			| {stop, Reason :: term()} | ignore.
%% @doc Initialize the {@module} finite state machine.
%% @see //stdlib/gen_fsm:init/1
%% @private
%%
init([SctpRole, Socket, Address, Port,
		#sctp_assoc_change{assoc_id = Assoc,
		inbound_streams = InStreams, outbound_streams = OutStreams}]) ->
	process_flag(trap_exit, true),
	Statedata = #statedata{sctp_role = SctpRole,
			socket = Socket, assoc = Assoc,
			peer_addr = Address, peer_port = Port,
			in_streams = InStreams, out_streams = OutStreams},
	{ok, down, Statedata}.

-spec down(Event :: timeout | term(), StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(), NewStateData :: #statedata{},
				timeout() | hibernate}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle events sent with {@link //stdlib/gen_fsm:send_event/2.
%% 	gen_fsm:send_event/2} in the <b>down</b> state.
%% @private
%%
down({asp_up, Ref, From}, #statedata{req = undefined, socket = Socket,
		assoc = Assoc} = StateData) ->
	AspUp = #m3ua{class = ?ASPSMMessage,
			type = ?ASPSMASPUP, params = <<>>},
	Packet = m3ua_codec:m3ua(AspUp),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			Req = {asp_up, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, down, NewStateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end.

-spec down(Event :: timeout | term(), From :: {pid(), Tag :: term()},
		StateData :: #statedata{}) -> {stop, Reason :: term(), Reply :: term(),
            NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>down</b> state.
%% @private
%%
down(Event, _From, StateData) ->
	{stop, Event, not_implemeted, StateData}.

-spec inactive(Event :: timeout | term(), StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(), NewStateData :: #statedata{},
				timeout() | hibernate}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle events sent with {@link //stdlib/gen_fsm:send_event/2.
%% 	gen_fsm:send_event/2} in the <b>inactive</b> state.
%% @private
%%
inactive({asp_active, Ref, From}, #statedata{req = undefined, socket = Socket,
		assoc = Assoc} = StateData) ->
	P0 = m3ua_codec:add_parameter(?TrafficModeType, loadshare, []),
	Params = m3ua_codec:parameters(P0),
	AspActive = #m3ua{class = ?ASPTMMessage,
		type = ?ASPTMASPAC, params = Params},
	Message = m3ua_codec:m3ua(AspActive),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {asp_active, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, inactive, NewStateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
inactive({asp_down, Ref, From}, #statedata{req = undefined, socket = Socket,
		assoc = Assoc} = StateData) ->
	AspDown = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN},
	Message = m3ua_codec:m3ua(AspDown),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {asp_down, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, inactive, NewStateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end.

-spec inactive(Event :: timeout | term(), From :: {pid(), Tag :: term()},
		StateData :: #statedata{}) -> {stop, Reason :: term(), Reply :: term(),
            NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>inactive</b> state.
%% @private
%%
inactive(Event, _From, StateData) ->
	{stop, Event, not_implemeted, StateData}.

-spec active(Event :: timeout | term(), StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(), NewStateData :: #statedata{},
				timeout() | hibernate}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle events sent with {@link //stdlib/gen_fsm:send_event/2.
%% 	gen_fsm:send_event/2} in the <b>active</b> state.
%% @private
%%
active({asp_inactive, Ref, From}, #statedata{req = undefined, socket = Socket,
		assoc = Assoc} = StateData) ->
	AspInActive = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA},
	Message = m3ua_codec:m3ua(AspInActive),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {asp_inactive, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, active, NewStateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
active({asp_down, Ref, From}, #statedata{req = undefined, socket = Socket,
		assoc = Assoc} = StateData) ->
	AspDown = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN},
	Message = m3ua_codec:m3ua(AspDown),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {asp_down, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, active, NewStateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end.

-spec active(Event :: timeout | term(), From :: {pid(), Tag :: term()},
		StateData :: #statedata{}) -> {stop, Reason :: term(), Reply :: term(),
            NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>active</b> state.
%% @private
%%
active(Event, _From, StateData) ->
	{stop, Event, not_implemeted, StateData}.

-spec handle_event(Event :: term(), StateName :: atom(),
		StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(), NewStateData :: #statedata{},
				timeout() | hibernate}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with
%% 	{@link //stdlib/gen_fsm:send_all_state_event/2.
%% 	gen_fsm:send_all_state_event/2}.
%% @see //stdlib/gen_fsm:handle_event/3
%% @private
%%
handle_event(_Event, _StateName, StateData) ->
	{stop, not_implemented, StateData}.

-spec handle_sync_event(Event :: term(), From :: {pid(), Tag :: term()},
		StateName :: atom(), StateData :: #statedata{}) ->
	{reply, Reply :: term(), NextStateName :: atom(), NewStateData :: term()}
			| {reply, Reply :: term(), NextStateName :: atom(),
				NewStateData :: #statedata{}, timeout() | hibernate}
			| {next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(), NewStateData :: #statedata{},
				timeout() | hibernate}
			| {stop, Reason :: term(), Reply :: term(),
				NewStateData :: #statedata{}}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with
%% 	{@link //stdlib/gen_fsm:sync_send_all_state_event/2.
%% 	gen_fsm:sync_send_all_state_event/2,3}.
%% @see //stdlib/gen_fsm:handle_sync_event/4
%% @private
%%
handle_sync_event(_Event, _From, _StateName, StateData) ->
	{stop, not_implemented, StateData}.

-spec handle_info(Info :: term(), StateName :: atom(),
		StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(), NewStateData :: #statedata{},
				timeout() | hibernate}
			| {stop, Reason :: normal | term(), NewStateData :: #statedata{}}.
%% @doc Handle a received message.
%% @see //stdlib/gen_fsm:handle_info/3
%% @private
%%
handle_info({sctp, Socket, _PeerAddr, _PeerPort, {_AncData, Data}},
		_StateName, #statedata{socket = Socket} = StateData)
		when is_binary(Data) ->
	case catch m3ua_codec:m3ua(Data) of
		#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK} ->
			{next_state, inactive, StateData};
		{'EXIT', Reason} ->
			{stop, Reason, StateData}
	end;
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_assoc_change{state = comm_lost, assoc_id = Assoc}}},
		StateName, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, StateData};
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_adaptation_event{adaptation_ind = UAL, assoc_id = Assoc}}},
		StateName, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, StateData#statedata{ual = UAL}};
% @todo Track peer address states.
handle_info({sctp, Socket, _, _,
		{[], #sctp_paddr_change{addr = {PeerAddr, PeerPort},
		state = addr_confirmed, assoc_id = Assoc}}}, StateName,
		#statedata{socket = Socket, assoc = Assoc} = StateData) ->
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{peer_addr = PeerAddr,
			peer_port = PeerPort},
	{next_state, StateName, NewStateData};
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_shutdown_event{assoc_id = AssocId}}},
		_StateName, #statedata{socket = Socket, assoc = AssocId} =
		StateData) ->
	{stop, shutdown, StateData}.

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		StateName :: atom(), StateData :: #statedata{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_fsm:terminate/3
%% @private
%%
terminate(_Reason, _StateName, _StateData) ->
	ok.

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
handle_down(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
		#statedata{req = {asp_up, Ref, From}, socket = Socket} = StateData) ->
	gen_server:cast(From, {asp_up, Ref, self(), undefined, undefined}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData}.

%% @hidden
handle_inactive(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK},
		#statedata{req = {asp_active, Ref, From}, socket = Socket} = StateData) ->
	gen_server:cast(From, {asp_active, Ref, self(), undefined, undefined}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, active, NewStateData};
handle_inactive(#m3ua{class = ?ASPTMMessage, type = ?ASPSMASPDNACK},
		#statedata{req = {asp_down, Ref, From}, socket = Socket} = StateData) ->
	gen_server:cast(From, {asp_down, Ref, self(), undefined, undefined}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData}.

%% @hidden
handle_active(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK},
		#statedata{req = {asp_inactive, Ref, From}, socket = Socket} = StateData) ->
	gen_server:cast(From, {asp_inactive, Ref, self(), undefined, undefined}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData};
handle_active(#m3ua{class = ?ASPTMMessage, type = ?ASPSMASPDNACK},
		#statedata{req = {asp_down, Ref, From}, socket = Socket} = StateData) ->
	gen_server:cast(From, {asp_down, Ref, self(), undefined, undefined}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData}.


