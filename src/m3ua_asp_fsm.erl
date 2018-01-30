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
%%%  <h2><a name="functions">Callbacks</a></h2>
%%%
%%%  <h3 class="function"><a name="transfer-4">transfer/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>transfer(EP, Assoc, Stream, Data) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EndPoint = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>Data = term()</tt></li>
%%%  </ul></p>
%%%  </div><p>Called when data has arraived for application server (`AS'). </p>
%%%
%%%  <h3 class="function"><a name="pause-4">pause/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>pause(EP, Assoc, Stream, Data) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EndPoint = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>Data = term()</tt></li>
%%%  </ul></p>
%%%  </div><p>Call when determines locally that an SS7 destination is unreachable</p>
%%%
%%%  <h3 class="function"><a name="resume-4">resume/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>resume(EP, Assoc, Stream, Data) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EndPoint = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>Data = term()</tt></li>
%%%   </ul></p>
%%%  </div><p>Call when determines locally that an SS7 destination that was previously
%%%  unreachable is now reachable</p>
%%%
%%%  <h3 class="function"><a name="status-4">status/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>status(EP, Assoc, Stream, Data) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EndPoint = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>Data = term()</tt></li>
%%%  </ul></p>
%%%  </div><p>Call when determines locally that the route to an SS7 destination is congested </p>
%%%
%%% @end
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
		socket :: gen_sctp:sctp_socket(),
		peer_addr :: inet:ip_address(),
		peer_port :: inet:port_number(),
		in_streams :: non_neg_integer(),
		out_streams :: non_neg_integer(),
		assoc :: gen_sctp:assoc_id(),
		ual :: non_neg_integer(),
		req :: tuple(),
		rc :: pos_integer(),
		mode :: override | loadshare | broadcast}).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").


-define(Tack, 2000).

%%----------------------------------------------------------------------
%%  The m3ua_asp_fsm API
%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%%  Interface functions
%%----------------------------------------------------------------------

-callback transfer(EP, Assoc, Stream, Data) -> ok
	when
		EP :: pos_integer(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		Data :: term().
-callback pause(EP, Assoc, Stream, Data) -> ok
	when
		EP :: pos_integer(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		Data :: term().
-callback resume(EP, Assoc, Stream, Data) -> ok
	when
		EP :: pos_integer(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		Data :: term().
-callback status(EP, Assoc, Stream, Data) -> ok
	when
		EP :: pos_integer(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		Data :: term().

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
down(timeout, #statedata{req = {asp_up, Ref, From}} = StateData) ->
	gen_server:cast(From, {asp_up, Ref, self(), {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
down({asp_up, Ref, From}, #statedata{req = undefined, socket = Socket,
		assoc = Assoc} = StateData) ->
	AspUp = #m3ua{class = ?ASPSMMessage,
			type = ?ASPSMASPUP, params = <<>>},
	Packet = m3ua_codec:m3ua(AspUp),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			Req = {asp_up, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, down, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
down({AspOp, Ref, From}, #statedata{req = Req} = StateData) when Req /= undefined ->
	gen_server:cast(From, {AspOp, Ref, self(), {error, asp_busy}}),
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
inactive(timeout, #statedata{req = {AspOp, Ref, From}} = StateData)
		when AspOp == asp_active; AspOp == register; AspOp == asp_down ->
	gen_server:cast(From, {AspOp, Ref, self(), {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
inactive({register, Ref, From, NA, Keys, Mode, AS},
		#statedata{req = undefined, socket = Socket, assoc = Assoc,
		rc = RC} = StateData)  ->
	RK = #m3ua_routing_key{na = NA, tmt = Mode, key = Keys,
			lrk_id = generate_lrk_id(), rc = RC, as = AS},
	RoutingKey = m3ua_codec:routing_key(RK),
	Params = m3ua_codec:parameters([{?RoutingKey, RoutingKey}]),
	RegReq = #m3ua{class = ?RKMMessage, type = ?RKMREGREQ, params = Params},
	Message = m3ua_codec:m3ua(RegReq),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {register, Ref, From, RK},
			NewStateData = StateData#statedata{req = Req, mode = Mode},
			{next_state, inactive, NewStateData, ?Tack};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
inactive({asp_active, Ref, From}, #statedata{req = undefined, socket = Socket,
		assoc = Assoc, rc = RC, mode = Mode} = StateData) ->
	P0 = m3ua_codec:add_parameter(?TrafficModeType, Mode, []),
	P1 = m3ua_codec:add_parameter(?RoutingContext, [RC], P0),
	Params = m3ua_codec:parameters(P1),
	AspActive = #m3ua{class = ?ASPTMMessage,
		type = ?ASPTMASPAC, params = Params},
	Message = m3ua_codec:m3ua(AspActive),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {asp_active, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, inactive, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
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
			{next_state, inactive, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
inactive({AspOp, Ref, From}, #statedata{req = Req} = StateData) when Req /= undefined ->
	gen_server:cast(From, {AspOp, Ref, self(), {error, asp_busy}}),
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
active(timeout, #statedata{req = {AspOp, Ref, From}} = StateData)
		when AspOp == inactive; AspOp == down ->
	gen_server:cast(From, {AspOp, Ref, self(), {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
active({asp_inactive, Ref, From}, #statedata{req = undefined, socket = Socket,
		assoc = Assoc, rc = RC} = StateData) ->
	P0 = m3ua_codec:add_parameter(?RoutingContext, [RC], []),
	AspInActive = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA, params = P0},
	Message = m3ua_codec:m3ua(AspInActive),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {asp_inactive, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, active, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
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
			{next_state, active, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end;
active({AspOp, Ref, From}, #statedata{req = Req} = StateData) when Req /= undefined ->
	gen_server:cast(From, {AspOp, Ref, self(), {error, asp_busy}}),
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
handle_info({sctp, Socket, _PeerAddr, _PeerPort, {_AncData, Data}},
		StateName, #statedata{socket = Socket} = StateData)
		when is_binary(Data) ->
	handle_asp(Data, StateName, StateData);
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
handle_asp(M3UA, StateName, StateData) when is_binary(M3UA) ->
	handle_asp(m3ua_codec:m3ua(M3UA), StateName, StateData);
handle_asp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK}, down,
		#statedata{req = {asp_up, Ref, From}, socket = Socket} = StateData) ->
	gen_server:cast(From, {asp_up, Ref, {ok, self(), undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData};
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK}, inactive,
		#statedata{req = {asp_active, Ref, From}, socket = Socket} = StateData) ->
	gen_server:cast(From, {asp_active, Ref, {ok, self(), undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, active, NewStateData};
%% @todo handle RC and RK
handle_asp(#m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = Params},
		inactive, #statedata{socket = Socket, req = {register, Ref, From,
		#m3ua_routing_key{lrk_id = LRKId, na = NA, tmt = TMT, as = AS, key = Keys}}} =
		StateData) ->
	Params1 = m3ua_codec:parameters(Params),
	case m3ua_codec:fetch_parameter(?RegistrationResult, Params1) of
		#registration_result{lrk_id = LRKId, status = registered, rc = RC} ->
			Rsp = {NA, Keys, TMT, inactive, AS},
			gen_server:cast(From, {register, Ref, {ok, RC, Rsp}}),
			inet:setopts(Socket, [{active, once}]),
			NewStateData = StateData#statedata{req = undefined, rc = RC},
			{next_state, inactive, NewStateData};
		#registration_result{status = Status} ->
			gen_server:cast(From, {register, Ref, {error, Status}}),
			inet:setopts(Socket, [{active, once}]),
			{next_state, inactive, StateData}
	end;
handle_asp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDNACK}, StateName,
		#statedata{req = {asp_down, Ref, From}, socket = Socket} = StateData)
		when StateName == inactive; StateName == active ->
	gen_server:cast(From, {asp_down, Ref, {ok, self(), undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK}, active,
		#statedata{req = {asp_inactive, Ref, From}, socket = Socket} = StateData) ->
	gen_server:cast(From, {asp_inactive, Ref, {ok, self(), undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData};
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPSMASPDNACK}, active,
		#statedata{req = {asp_down, Ref, From}, socket = Socket} = StateData) ->
	gen_server:cast(From, {asp_down, Ref, {ok, self(), undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
handle_asp(#m3ua{class = ?MGMTMessage, type = ?MGMTError, params = Params}, active,
		#statedata{req = {AspOp, Ref, From}, socket = Socket} = StateData) ->
	Parameters = m3ua_codec:parameters(Params),
	{ok, Reason} = m3ua_codec:find_parameter(?ErrorCode, Parameters),
	gen_server:cast(From, {AspOp, Ref, self(), {error, Reason}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData}.

%% @hidden
generate_lrk_id() ->
	random:uniform(256).

