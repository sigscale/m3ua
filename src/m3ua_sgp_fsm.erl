
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
%%%  <h2><a name="functions">Callbacks</a></h2>
%%%
%%%  <h3 class="function"><a name="transfer-4">transfer/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>transfer(EP, Assoc, Stream, OPC, DPC, SLS, SIO, Data) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EndPoint = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>OPC = pos_integer() </tt></li>
%%%    <li><tt>DCP = pos_integer() </tt></li>
%%%    <li><tt>SLS = non_neg_integer() </tt></li>
%%%    <li><tt>SIO = non_neg_integer() </tt></li>
%%%    <li><tt>Data = binary() </tt></li>
%%%  </ul></p>
%%%  </div><p>Called when data has arraived for application server (`AS'). </p>
%%%
%%%  <h3 class="function"><a name="pause-4">pause/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>pause(EP, Assoc, Stream, DPCs) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EndPoint = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = pos_integer() </tt></li>
%%%  </ul></p>
%%%  </div><p>Call when determines locally that an SS7 destination is unreachable</p>
%%%
%%%  <h3 class="function"><a name="resume-4">resume/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>resume(EP, Assoc, Stream, DPCs) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EndPoint = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = pos_integer() </tt></li>
%%%   </ul></p>
%%%  </div><p>Call when determines locally that an SS7 destination that was previously
%%%  unreachable is now reachable</p>
%%%
%%%  <h3 class="function"><a name="status-4">status/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>status(EP, Assoc, Stream, DPCs) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EndPoint = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = pos_integer() </tt></li>
%%%  </ul></p>
%%%  </div><p>Call when determines locally that the route to an SS7 destination is congested </p>
%%%
%%% @end
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
		rcs = gb_trees:empty() :: gb_trees:tree(),
		stream :: integer(),
		callback :: atom()}).

%%----------------------------------------------------------------------
%%  The m3ua_sgp_fsm API
%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%%  Interface functions
%%----------------------------------------------------------------------

-callback transfer(EP, Assoc, Stream, OPC, DPC, SLS, SIO, Data) -> ok
	when
		EP :: pos_integer(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		OPC :: pos_integer(),
		DPC :: pos_integer(),
		SLS :: non_neg_integer(),
		SIO :: non_neg_integer(),
		Data :: binary().
-callback pause(EP, Assoc, Stream, DPCs) -> ok
	when
		EP :: pos_integer(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		DPCs :: [DPC],
		DPC :: pos_integer().
-callback resume(EP, Assoc, Stream, DPCs) -> ok
	when
		EP :: pos_integer(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		DPCs :: [DPC],
		DPC :: pos_integer().
-callback status(EP, Assoc, Stream, DPCs) -> ok
	when
		EP :: pos_integer(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		DPCs :: [DPC],
		DPC :: pos_integer().

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
		inbound_streams = InStreams, outbound_streams = OutStreams},
		CbMode]) ->
	process_flag(trap_exit, true),
	Statedata = #statedata{sctp_role = SctpRole,
			socket = Socket, assoc = Assoc,
			peer_addr = Address, peer_port = Port,
			in_streams = InStreams, out_streams = OutStreams,
			callback = CbMode},
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
		{reply, Reply :: term(), NextStateName :: atom(),
		NewStateData :: #statedata{}} | {stop, Reason :: term(),
		Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with
%% 	{@link //stdlib/gen_fsm:sync_send_all_state_event/2.
%% 	gen_fsm:sync_send_all_state_event/2,3}.
%% @see //stdlib/gen_fsm:handle_sync_event/4
%% @private
%%
handle_sync_event({getstat, undefined}, _From, StateName,
		#statedata{socket = Socket} = StateData) ->
	{reply, inet:getstat(Socket), StateName, StateData};
handle_sync_event({getstat, Options}, _From, StateName,
		#statedata{socket = Socket} = StateData) ->
	{reply, inet:getstat(Socket, Options), StateName, StateData};
handle_sync_event(sctp_status, _From, StateName,
		#statedata{socket = Socket, assoc = Assoc} = StateData) ->
	Options = [{sctp_status, #sctp_status{assoc_id = Assoc}}],
	case inet:getopts(Socket, Options) of
		{ok, SCTPStatus} ->
			{_, Status} = lists:keyfind(sctp_status, 1, SCTPStatus),
			{reply, {ok, Status}, StateName, StateData};
		{error, Reason} ->
			{reply, {error, Reason}, StateName, StateData}
	end.

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
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[#sctp_sndrcvinfo{stream = Stream}], Data}},
		StateName, #statedata{socket = Socket} = StateData) when is_binary(Data) ->
	handle_sgp(Data, StateName, Stream, StateData);
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
	{next_state, StateName, StateData};
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
handle_sgp(M3UA, StateName, Stream, StateData) when is_binary(M3UA) ->
	handle_sgp(m3ua_codec:m3ua(M3UA), StateName, Stream, StateData);
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP}, down,
		_Stream, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
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
		_Stream, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			P0 = m3ua_codec:add_parameter(?ErrorCode, unexpected_message, []),
			EParams = m3ua_codec:parameters(P0),
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
handle_sgp(#m3ua{class = ?RKMMessage, type = ?RKMREGREQ, params = ReqParams},
		inactive, _Stream, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
	Parameters = m3ua_codec:parameters(ReqParams),
	RoutingKeys = m3ua_codec:get_all_parameter(?RoutingKey, Parameters),
	RC = generate_rc(),
	{RegResult, NewStateData} = register_asp_results(RoutingKeys, RC, StateData),
	RegRsp = #m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = RegResult},
	Packet = m3ua_codec:m3ua(RegRsp),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			inet:setopts(Socket, [{active, once}]),
			{next_state, inactive, NewStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, NewStateData};
		{error, Reason} ->
			{stop, Reason, NewStateData}
	end;
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC, params = Params},
		inactive, _Stream, #statedata{socket = Socket, assoc = Assoc, rcs = RCs} = StateData) ->
	try
		AspActive = m3ua_codec:parameters(Params),
		case m3ua_codec:find_parameter(?RoutingContext, AspActive) of
			{ok, [RC]} ->
				case gb_trees:lookup(RC, RCs) of
					{value, #m3ua_routing_key{tmt = Mode} = RK} ->
						NewRCs = gb_trees:update(RC, RK#m3ua_routing_key{status = active}, RCs),
						P0 = m3ua_codec:add_parameter(?TrafficModeType, Mode, []),
						P1 = m3ua_codec:add_parameter(?RoutingContext, [RC], P0),
						StateData1 = StateData#statedata{rcs = NewRCs},
						{?ASPTMMessage, ?ASPTMASPACACK, P1, StateData1};
					none ->
						P0 = m3ua_codec:add_parameter(?ErrorCode, no_configure_AS_for_ASP, []),
						P1 = m3ua_codec:add_parameter(?RoutingContext, [RC], P0),
						{?MGMTMessage, ?MGMTError, P1, StateData}
				end;
			{error, not_found} ->
				P0 = m3ua_codec:add_parameter(?ErrorCode, missing_parameter, []),
				{?MGMTMessage, ?MGMTError, P0, StateData}
		end
	of
		{Class, Type, Parameters, NewStateData} ->
			Message = #m3ua{class = Class, type = Type, params = Parameters},
			Packet = m3ua_codec:m3ua(Message),
			case gen_sctp:send(Socket, Assoc, 0, Packet) of
				ok ->
					inet:setopts(Socket, [{active, once}]),
					{next_state, active, NewStateData};
				{error, eagain} ->
					% @todo flow control
					{stop, eagain, NewStateData};
				{error, Reason} ->
					{stop, Reason, NewStateData}
			end
	catch
		_:Reason ->
			{stop, Reason, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN}, StateName,
		_Stream, #statedata{socket = Socket, assoc = Assoc} = StateData)
		when StateName == inactive; StateName == active ->
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
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA, params = Params}, active,
		_Stream, #statedata{socket = Socket, assoc = Assoc, rcs = RCs} = StateData) ->
	try
		AspInactive = m3ua_codec:parameters(Params),
		case m3ua_codec:find_parameter(?RoutingContext, AspInactive) of
			{ok, [RC]} ->
				case gb_trees:lookup(RC, RCs) of
					{value, #m3ua_routing_key{} = RK} ->
						P0 = m3ua_codec:add_parameter(?RoutingContext, [RC], []),
						NewRCs = gb_trees:update(RC, RK#m3ua_routing_key{status = inactive}, RCs),
						{?ASPTMMessage, ?ASPTMASPIAACK, P0, StateData#statedata{rcs = NewRCs}};
					none ->
						P0 = m3ua_codec:add_parameter(?ErrorCode, invalid_rc, []),
						P1 = m3ua_codec:add_parameter(?RoutingContext, [RC], P0),
						{?MGMTMessage, ?MGMTError, P1, StateData}
				end;
			{error, not_found} ->
				P0 = m3ua_codec:add_parameter(?ErrorCode, no_configure_AS_for_ASP, []),
				{?MGMTMessage, ?MGMTError, P0, StateData}
		end
	of
		{Class, Type, Parameters, NewStateData} ->
				Message = #m3ua{class = Class, type = Type, params = Parameters},
				Packet = m3ua_codec:m3ua(Message),
				case gen_sctp:send(Socket, Assoc, 0, Packet) of
					ok ->
						inet:setopts(Socket, [{active, once}]),
						{next_state, inactive, NewStateData};
					{error, eagain} ->
						% @todo flow control
						{stop, eagain, NewStateData};
					{error, Reason} ->
						{stop, Reason, NewStateData}
				end
		catch
			_:Reason ->
				{stop, Reason, StateData}
		end;
handle_sgp(#m3ua{class = ?TransferMessage, type = ?TransferMessageData} = Msg,
		active, Stream, #statedata{callback = CbMode, assoc = Assoc}) when CbMode /= undefined ->
	CbMode:transfer(self(), Assoc, Stream, Msg);
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMDUNA} = Msg, _StateName,
		Stream, #statedata{callback = CbMode, assoc = Assoc}) when CbMode /= undefined ->
	CbMode:pause(self(), Assoc, Stream, Msg);
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMDAUD} = Msg, _StateName,
		Stream, #statedata{callback = CbMode, assoc = Assoc})
		when CbMode /= undefined ->
	CbMode:resume(self(), Assoc, Stream, Msg);
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMSCON} = Msg, _StateName,
		Stream, #statedata{callback = CbMode, assoc = Assoc}) when CbMode /= undefined ->
	CbMode:status(self(), Assoc, Stream, Msg).

%% @hidden
register_asp_results(RoutingKeys, RC, StateData) ->
	register_asp_results(RoutingKeys, RC, [], StateData).
%% @hidden
register_asp_results([RoutingKey | T], RC, Acc, #statedata{rcs = RCs} = StateData) ->
	try
		case m3ua_codec:routing_key(RoutingKey) of
			#m3ua_routing_key{lrk_id = undefined} ->
				ErRR = #registration_result{status = invalid_rk, rc = RC},
				NewAcc = m3ua_codec:add_parameter(?RegistrationResult, ErRR, Acc),
				register_asp_results(T, RC, NewAcc, StateData);
			#m3ua_routing_key{rc = undefined, na = NA, tmt = Mode,
					key = Keys, lrk_id = LRKId} = RK ->
				SortedKeys = m3ua:sort(Keys),
				NewRCs = gb_trees:insert(RC, RK#m3ua_routing_key{key = SortedKeys}, RCs),
				RegResult = #registration_result{lrk_id = LRKId,
					status = registered, rc = RC},
				Asp = #m3ua_asp{id = LRKId, sgp = self()},
				gen_server:cast(m3ua_lm_server,
						{'M-RK_REG', {NA, SortedKeys, Mode}, Asp}),
				NewAcc = m3ua_codec:add_parameter(?RegistrationResult, RegResult, Acc),
				NewStateData = StateData#statedata{rcs = NewRCs},
				register_asp_results(T, RC, NewAcc, NewStateData);
			#m3ua_routing_key{lrk_id = LRKId, na = NA, tmt = Mode,
					key = Keys, rc = ExRC} = RK when LRKId /= undefined ->
				case gb_trees:lookup(ExRC, RCs) of
					{value, #m3ua_routing_key{key = ExKeys}} ->
						SortedKeys = m3ua:sort(Keys ++ ExKeys),
						NewRK = RK#m3ua_routing_key{key = SortedKeys},
						NewRCs = gb_trees:insert(ExRC, NewRK, RCs),
						RegResult = #registration_result{lrk_id = LRKId,
								status = registered, rc = ExRC},
						Asp = #m3ua_asp{id = LRKId, sgp = self()},
						gen_server:cast(m3ua_lm_server,
								{'M-RK_REG', {NA, SortedKeys, Mode}, Asp}),
						NewAcc = m3ua_codec:add_parameter(?RegistrationResult, RegResult, Acc),
						NewStateData = StateData#statedata{rcs = NewRCs},
						register_asp_results(T, RC, NewAcc, NewStateData);
					none ->
						ErRR = #registration_result{status = rk_change_refused, rc = RC},
						NewAcc = m3ua_codec:add_parameter(?RegistrationResult, ErRR, Acc),
						register_asp_results(T, RC, NewAcc, StateData)
				end;
			#m3ua_routing_key{}->
				ErRR = #registration_result{status = insufficient_resources, rc = RC},
				NewAcc = m3ua_codec:add_parameter(?RegistrationResult, ErRR, Acc),
				register_asp_results(T, RC, NewAcc, StateData)
		end
	catch
		_:_ ->
			ErRegResult = #registration_result{status = unknown, rc = RC},
			NewAcc1 = m3ua_codec:add_parameter(?RegistrationResult, ErRegResult, Acc),
			register_asp_results(T, RC, NewAcc1, StateData)
	end;
register_asp_results([], _RC, Acc, StateData) ->
	{Acc, StateData}.

%% @hidden
generate_rc() ->
	rand:uniform(256).
