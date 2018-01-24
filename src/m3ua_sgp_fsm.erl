%%% m3ua_sgp_fsm.erl
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
%%% 	{@link //m3ua. m3ua} application handling an SCTP association
%%%   originated from a client.
%%%
-module(m3ua_sgp_fsm).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(gen_fsm).

%% export the m3ua_sgp_fsm API
-export([]).

%% export the callbacks needed for gen_fsm behaviour
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3,
			terminate/3, code_change/4]).

%% export the gen_fsm state callbacks
-export([down/2, down/3, inactive/2, inactive/3, active/2, active/3]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-record(statedata,
		{sctp_role :: client | server,
		socket :: gen_sctp:sctp_socket(),
		peer_addr :: inet:ip_address(),
		peer_port :: inet:port_number(),
		in_streams :: non_neg_integer(),
		out_streams :: non_neg_integer(),
		assoc :: gen_sctp:assoc_id(),
		ual :: non_neg_integer(),
		rcs = gb_trees:empty() :: gb_trees:tree()}).

%%----------------------------------------------------------------------
%%  The m3ua_sgp_fsm API
%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%%  The m3ua_sgp_fsm gen_fsm callbacks
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
down(_Event, #statedata{} = StateData) ->
	{next_state, down, StateData}.

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
inactive(_Event, #statedata{} = StateData) ->
	{next_state, inactive, StateData}.

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
active(_Event, #statedata{} = StateData) ->
	{next_state, active, StateData}.

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
		{stop, Reason :: term(), NewStateData :: #statedata{}}.
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
		{stop, Reason :: term(), Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with
%% 	{@link //stdlib/gen_fsm:sync_send_all_state_event/2.
%% 	gen_fsm:sync_send_all_state_event/2,3}.
%% @see //stdlib/gen_fsm:handle_sync_event/4
%% @private
%%
handle_sync_event(Event, _From, _StateName, StateData) ->
	{stop, Event, not_implemented, StateData}.

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
handle_info({sctp, Socket, _PeerAddr, _PeerPort, {_AncData, Data}}, StateName,
		#statedata{socket = Socket} = StateData) when is_binary(Data) ->
	handle_sgp(Data, StateName, StateData);
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_assoc_change{state = comm_lost, assoc_id = Assoc}}}, StateName,
		#statedata{socket = Socket, assoc = Assoc} = StateData) ->
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
% @todo Dispatch data to user!
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[#sctp_sndrcvinfo{assoc_id = Assoc}], _Data}}, StateName,
		#statedata{socket = Socket, assoc = Assoc} = StateData) ->
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, StateData}.

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
handle_sgp(M3UA, StateName, StateData) when is_binary(M3UA) ->
	handle_sgp(m3ua_codec:m3ua(M3UA), StateName, StateData);
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP}, down,
		#statedata{socket = Socket, assoc = Assoc} = StateData) ->
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			inet:setopts(Socket, [{active, once}]),
			{next_state, inactive, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP}, inactive,
		#statedata{socket = Socket, assoc = Assoc} = StateData) ->
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			P0 = m3ua_codec:add_parameter(?ErrorCode, unexpected_message),
			EParams = m3ua_codec:parameter(P0),
			ErrorMsg = #m3ua{class = ?MGMTMessage, type = ?MGMTError, params = EParams},
			Packet2 = m3ua_codec:m3ua(ErrorMsg),
			case gen_sctp:send(Socket, Assoc, 0, Packet2) of
				ok ->
					inet:setopts(Socket, [{active, once}]),
					{next_state, inactive, StateData};
				{error, eagain} ->
					% @todo flow control
					{stop, eagain, StateData};
				{error, Reason} ->
					{stop, Reason, StateData}
			end;
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
%% @todo  Registraction - handle registration status
%% RFC4666 - Section-3.6.2
handle_sgp(#m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = ReqParams},
		inactive, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
	Parameters = m3ua_codec:parameters(ReqParams),
	RoutingKeys = m3ua_codec:get_all_parameter(Parameters),
	RC = generate_rc(),
	{RegResult, NewStateData} = register_asp_results(RoutingKeys, RC, StateData),
	RspParams = m3ua_codec:parameters(RegResult),
	RegRsp = #m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = RspParams},
	Packet = m3ua_codec:m3ua(RegRsp),
	gen_sctp:send(Socket, Assoc, 0, Packet),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			inet:setopts(Socket, [{active, once}]),
			{next_state, inactive, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC, params = Params},
		inactive, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
	AspActive = m3ua_codec:parameters(Params),
	case {m3ua_codec:find_parameter(?RoutingContext, AspActive),
					m3ua_codec:find_parameter(?RoutingKey, AspActive)} of
		{{ok, _RC}, {ok, _RK}} ->
			AspActiveAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK},
			Packet = m3ua_codec:m3ua(AspActiveAck),
			case gen_sctp:send(Socket, Assoc, 0, Packet) of
				ok ->
					inet:setopts(Socket, [{active, once}]),
					{next_state, active, StateData};
				{error, eagain} ->
					% @todo flow control
					{stop, eagain, StateData};
				{error, Reason} ->
					{stop, Reason, StateData}
			end;
		{{error, not_found}, {ok, _RK}} ->
			P0 = m3ua_codec:add_parameter(?ErrorCode, missing_parameter, []),
			EParams = m3ua_coec:parameters(P0),
			ErrorMsg = #m3ua{class = ?MGMTMessage, type = ?MGMTError, params = EParams},
			Packet = m3ua_codec:m3ua(ErrorMsg),
			case gen_sctp:send(Socket, Assoc, 0, Packet) of
				ok ->
					inet:setopts(Socket, [{active, once}]),
					{next_state, active, StateData};
				{error, eagain} ->
					% @todo flow control
					{stop, eagain, StateData};
				{error, Reason} ->
					{stop, Reason, StateData}
			end;
		{{error, not_found}, {error, not_found}} ->
			P0 = m3ua_codec:add_parameter(?ErrorCode, invalid_routing_context, []),
			EParams = m3ua_coec:parameters(P0),
			ErrorMsg = #m3ua{class = ?MGMTMessage, type = ?MGMTError, params = EParams},
			Packet = m3ua_codec:m3ua(ErrorMsg),
			case gen_sctp:send(Socket, Assoc, 0, Packet) of
				ok ->
					inet:setopts(Socket, [{active, once}]),
					{next_state, active, StateData};
				{error, eagain} ->
					% @todo flow control
					{stop, eagain, StateData};
				{error, Reason} ->
					{stop, Reason, StateData}
			end
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN}, StateName,
		#statedata{socket = Socket, assoc = Assoc} = StateData)
		when StateName == inactive; StateName == down ->
	AspActiveAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDNACK},
	Packet = m3ua_codec:m3ua(AspActiveAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			inet:setopts(Socket, [{active, once}]),
			{next_state, down, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA}, active,
		#statedata{socket = Socket, assoc = Assoc} = StateData) ->
	AspInactiveAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK},
	Packet = m3ua_codec:m3ua(AspInactiveAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			inet:setopts(Socket, [{active, once}]),
			{next_state, inactive, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end.

%% @hidden
register_asp_results(RoutingKeys, RC, StateData) ->
	register_asp_results(RoutingKeys, RC, <<>>, StateData).
%% @hidden
register_asp_results([RoutingKey | T], RC, Result,
		#statedata{assoc = Assoc, rcs = RCs} = StateData) ->
	try
		Params = m3ua_codec:parameters(RoutingKey),
		LRKId = m3ua_codec:fetch_parameter(?LocalRoutingKeyIdentifier, Params),
		DPC = m3ua_codec:fetch_parameter(?DestinationPointCode, Params),
		NA = case m3ua_code:find_parameter(?NetworkAppearance, Params) of
			{ok, NetworkAppearance} ->
				NetworkAppearance;
			{error, not_found} ->
				undefined
		end,
		SIs = case m3ua_code:find_parameter(?ServiceIndicators, Params) of
			{ok, ServiceIndicators} ->
				ServiceIndicators;
			{error, not_found} ->
				undefined
		end,
		OPCs = case m3ua_codec:find_parameter(?OriginatingPointCodeList, Params) of
			{ok, OriginatingPointCodeList} ->
				OriginatingPointCodeList;
			{error, not_found} ->
				undefined
		end,
		TMT = case m3ua_codec:find_parameter(?TrafficModeType, Params) of
			{ok, TrafficModeType} ->
				TrafficModeType;
			{error, not_found} ->
				undefined
		end,
		%% {{EP, Assoc, RC}, NA, [{DPC, [S1], [OPC]}], TMT, Status, As}
		NewRCs = gb_trees:insert({self(), Assoc, RC},
				{NA, [{DPC, SIs, OPCs}], TMT, undefined, undefine}, RCs),
		P0 = m3ua_codec:add_parameter(?LocalRoutingKeyIdentifier, LRKId, []) ,
		P1 = m3ua_codec:add_parameter(?RegistrationStatus, registered, P0) ,
		P2 = m3ua_codec:add_parameter(?RoutingContext, RC, P1),
		RegParams= m3ua_codec:parameters(P2),
		Message = m3ua_codec:add_parameter(?RegistrationResult, RegParams, []),
		NewStateData = StateData#statedata{rcs = NewRCs},
		register_asp_results(T, <<Result/binary, Message/binary>>, NewStateData)
	catch
		_:_ ->
			ErP0 = m3ua_codec:add_parameter(?RegistrationStatus, unknown, []) ,
			ErP1 = m3ua_codec:add_parameter(?RoutingContext, RC, ErP0),
			ErRegParams= m3ua_codec:parameters(ErP1),
			ErMessage = m3ua_codec:add_parameter(?RegistrationResult, ErRegParams, []),
			register_asp_results(T, <<Result/binary, ErMessage/binary>>, StateData)
	end;
register_asp_results([], _RC, Result, StateData) ->
	{Result, StateData}.

%% @hidden
generate_rc() ->
	rand:uniform(256).
