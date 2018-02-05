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
%%% 	{@link //m3ua. m3ua} application handling an SCTP association
%%%   for an Application Server Process (ASP).
%%%
%%% 	This behaviour module provides an MTP service primitives interface
%%% 	for an MTP user. A calback module name is provided in the
%%% 	`{callback, Module}' option when opening an `Endpoint'. MTP service
%%% 	primitive indications are delivered to the MTP user by calling the
%%% 	corresponding callback function as defined below.
%%%
%%%  <h2><a name="functions">Callbacks</a></h2>
%%%
%%%  <h3 class="function"><a name="init-1">init/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>init(Args)
%%% 		-&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Args = [{Sgp, Address, Port, Assoc, InStreams, OutStreams}] </tt></li>
%%%    <li><tt>Sgp = pid() </tt></li>
%%%    <li><tt>Address = inet:ip_address() | inet:hostname() </tt></li>
%%%    <li><tt>Port = inet:port_number() </tt></li>
%%%    <li><tt>Assoc = pos_integer() </tt></li>
%%%    <li><tt>InStreams = pos_integer() </tt></li>
%%%    <li><tt>OutStreams = pos_integer() </tt></li>
%%%    <li><tt>Result = {ok, State} | {error, Reason} </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="transfer-9">transfer/9</a></h3>
%%%  <div class="spec">
%%%  <p><tt>transfer(EP, Assoc, Stream, OPC, DPC, SLS, SIO, Data, State)
%%% 		-&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>OPC = pos_integer() </tt></li>
%%%    <li><tt>DPC = pos_integer() </tt></li>
%%%    <li><tt>SLS = non_neg_integer() </tt></li>
%%%    <li><tt>SIO = non_neg_integer() </tt></li>
%%%    <li><tt>Data = binary() </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>MTP-TRANSFER indication.</p>
%%%  <p>Called when data has arrived for the MTP user.</p>
%%%
%%%  <h3 class="function"><a name="pause-5">pause/5</a></h3>
%%%  <div class="spec">
%%%  <p><tt>pause(EP, Assoc, Stream, Data, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = pos_integer() </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>MTP-PAUSE indication.</p>
%%%  <p>Called when an SS7 destination is unreachable.</p>
%%%
%%%  <h3 class="function"><a name="resume-5">resume/5</a></h3>
%%%  <div class="spec">
%%%  <p><tt>resume(EP, Assoc, Stream, Data, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = pos_integer() </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%   </ul></p>
%%%  </div><p>MTP-RESUME indication.</p>
%%%  <p>Called when a previously unreachable SS7 destination
%%%  becomes reachable.</p>
%%%
%%%  <h3 class="function"><a name="status-5">status/5</a></h3>
%%%  <div class="spec">
%%%  <p><tt>status(EP, Assoc, Stream, Data, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = pos_integer() </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>Called when congestion occurs for an SS7 destination
%%% 	or to indicate an unavailable remote user part.</p>
%%%
%%%  <h3 class="function"><a name="asp_up-1">asp_up/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_up(Asp) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Asp = pid()</tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="asp_down-1">asp_down/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_down(Asp) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Asp = pid()</tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="asp_active-1">asp_active/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_active(Asp) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Asp = pid()</tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="asp_inactive-1">asp_inactive/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_inactive(Asp) -&gt; ok </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Asp = pid()</tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%% @end
-module(m3ua_asp_fsm).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(gen_fsm).

%% export the m3ua_asp_fsm public API
-export([transfer/8]).

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
		mode :: override | loadshare | broadcast,
		callback :: atom(),
		as_state :: term()}).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-define(Tack, 2000).

%%----------------------------------------------------------------------
%%  Interface functions
%%----------------------------------------------------------------------

-callback init(Args) -> Result
	when
		Args :: [{Sgp, Address, Port, Assoc, InStreams, OutStreams}],
		Sgp :: pid(),
		Address :: inet:ip_address() | inet:hostname(),
		Port :: inet:port_number(),
		Assoc :: pos_integer(),
		InStreams :: pos_integer(),
		OutStreams :: pos_integer(),
		Result :: {ok, State} | {error, Reason},
		State :: term(),
		Reason :: term().
-callback transfer(EP, Assoc, Stream, OPC, DPC, SLS, SIO, Data, State) -> Result
	when
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		OPC :: pos_integer(),
		DPC :: pos_integer(),
		SLS :: non_neg_integer(),
		SIO :: non_neg_integer(),
		Data :: binary(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback pause(EP, Assoc, Stream, DPCs, State) -> Result 
	when
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		DPCs :: [DPC],
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback resume(EP, Assoc, Stream, DPCs, State) -> Result 
	when
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		DPCs :: [DPC],
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback status(EP, Assoc, Stream, DPCs, State) -> Result
	when
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		DPCs :: [DPC],
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback asp_up(Asp) -> ok
	when
		Asp :: pid().
-callback asp_down(Asp) -> ok
	when
		Asp :: pid().
-callback asp_active(Asp) -> ok
	when
		Asp :: pid().
-callback asp_inactive(Asp) -> ok
	when
		Asp :: pid().

%%----------------------------------------------------------------------
%%  The m3ua_asp_fsm public API
%%----------------------------------------------------------------------

-spec transfer(ASP, Assoc, Stream, OPC, DPC, SLS, SIO, Data) -> Result
	when
		ASP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		OPC :: pos_integer(),
		DPC :: pos_integer(),
		SLS :: non_neg_integer(),
		SIO :: non_neg_integer(),
		Data :: binary(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc MTP-TRANSFER request.
%%
%% Called by an MTP user to transfer data using the MTP service.
transfer(ASP, Assoc, Stream, OPC, DPC, SLS, SIO, Data)
		when is_pid(ASP), is_integer(Assoc),
		is_integer(Stream), Stream =/= 0,
		is_integer(OPC), is_integer(DPC), is_integer(SLS),
		is_integer(SIO), is_binary(Data) ->
	Params = {Assoc, Stream, OPC, DPC, SLS, SIO, Data},
	gen_fsm:sync_send_event(ASP, {'MTP-TRANSFER', request, Params}).

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
		inbound_streams = InStreams, outbound_streams = OutStreams},
		CbMod]) ->
	Args = [{self(), Address, Port, Assoc, InStreams, OutStreams}],
	case CbMod of
		undefined ->
			process_flag(trap_exit, true),
			Statedata = #statedata{sctp_role = SctpRole,
					socket = Socket, assoc = Assoc,
					peer_addr = Address, peer_port = Port,
					in_streams = InStreams, out_streams = OutStreams,
					callback = CbMod},
			{ok, down, Statedata};
		CbMod ->
			case CbMod:init(Args) of
				{ok, AsState} ->
					process_flag(trap_exit, true),
					Statedata = #statedata{sctp_role = SctpRole,
							socket = Socket, assoc = Assoc,
							peer_addr = Address, peer_port = Port,
							in_streams = InStreams, out_streams = OutStreams,
							callback = CbMod, as_state = AsState},
					{ok, down, Statedata};
				{error, Reason} ->
					{stop, Reason}
			end
	end.

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

-spec down(Event :: timeout | term(),
		From :: {pid(), Tag :: term()}, StateData :: #statedata{}) ->
		{reply, Reply :: term(), NextStateName :: atom(), NewStateData :: #statedata{}}
		| {stop, Reason :: term(), Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>down</b> state.
%% @private
%%
down({'MTP-TRANSFER', request, _Params}, _From, StateData) ->
	{reply, {error, unexpected_message}, down, StateData}.

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

-spec inactive(Event :: timeout | term(),
		From :: {pid(), Tag :: term()}, StateData :: #statedata{}) ->
		{reply, Reply :: term(), NextStateName :: atom(), NewStateData :: #statedata{}}
		| {stop, Reason :: term(), Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>inactive</b> state.
%% @private
%%
inactive({'MTP-TRANSFER', request, _Params}, _From, StateData) ->
	{reply, {error, unexpected_message}, down, StateData}.

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

-spec active(Event :: timeout | term(),
		From :: {pid(), Tag :: term()}, StateData :: #statedata{}) ->
		{reply, Reply :: term(), NextStateName :: atom(), NewStateData :: #statedata{}}
		| {stop, Reason :: term(), Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>active</b> state.
%% @private
%%
active({'MTP-TRANSFER', request, {Assoc, Stream, OPC, DPC, SLS, SIO, Data}},
		_From, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
	ProtocolData = #protocol_data{opc = OPC, dpc = DPC, si = SIO, sls = SLS, data = Data},
	P0 = m3ua_codec:add_parameter(?ProtocolData, ProtocolData, []),
	TransferMsg = #m3ua{class = ?TransferMessage, type = ?TransferMessageData, params = P0},
	Packet = m3ua_codec:m3ua(TransferMsg),
	case gen_sctp:send(Socket, Assoc, Stream, Packet) of
		ok ->
			{reply, ok, down, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, eagain, StateData};
		{error, Reason} ->
			{stop, Reason, StateData}
	end.

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
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[#sctp_sndrcvinfo{stream = Stream}], Data}},
		StateName, #statedata{socket = Socket} = StateData)
		when is_binary(Data) ->
	handle_asp(Data, StateName, Stream, StateData);
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
handle_asp(M3UA, StateName, Stream, StateData) when is_binary(M3UA) ->
	handle_asp(m3ua_codec:m3ua(M3UA), StateName, Stream, StateData);
handle_asp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK}, down,
		_Stream, #statedata{req = {asp_up, Ref, From}, socket = Socket,
		callback = CbMod} = StateData) ->
	gen_server:cast(From, {asp_up, Ref, {ok, self(), CbMod, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData};
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK}, inactive,
		_Stream, #statedata{req = {asp_active, Ref, From}, socket = Socket,
		callback = CbMod} = StateData) ->
	gen_server:cast(From, {asp_active, Ref, {ok, self(), CbMod, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, active, NewStateData};
%% @todo handle RC and RK
handle_asp(#m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = Params},
		inactive, _Stream, #statedata{socket = Socket, req = {register, Ref, From,
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
		_Stream, #statedata{req = {asp_down, Ref, From}, socket = Socket,
		callback = CbMod} = StateData)
		when StateName == inactive; StateName == active ->
	gen_server:cast(From, {asp_down, Ref, {ok, self(), CbMod, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK}, active,
		_Stream, #statedata{req = {asp_inactive, Ref, From}, socket = Socket,
		callback = CbMod} = StateData) ->
	gen_server:cast(From, {asp_inactive, Ref, {ok, self(), CbMod, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData};
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPSMASPDNACK}, active,
		_Stream, #statedata{req = {asp_down, Ref, From}, socket = Socket,
		callback = CbMod} = StateData) ->
	gen_server:cast(From, {asp_down, Ref, {ok, self(), CbMod, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
handle_asp(#m3ua{class = ?MGMTMessage, type = ?MGMTError, params = Params}, active,
		_Stream, #statedata{req = {AspOp, Ref, From}, socket = Socket} = StateData) ->
	Parameters = m3ua_codec:parameters(Params),
	{ok, Reason} = m3ua_codec:find_parameter(?ErrorCode, Parameters),
	gen_server:cast(From, {AspOp, Ref, self(), {error, Reason}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
handle_asp(#m3ua{class = ?TransferMessage, type = ?TransferMessageData, params = Params},
		active, Stream, #statedata{callback = CbMod, assoc = Assoc} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	#protocol_data{opc = OPC, dpc = DPC, si = SIO, sls = SLS, data = Data} =
			m3ua_codec:fetch_parameter(?ProtocolData, Parameters),
	CbMod:transfer(self(), Assoc, Stream, OPC, DPC, SLS, SIO, Data),
	{next_state, active, StateData};
handle_asp(#m3ua{class = ?SSNMMessage, type = ?SSNMDUNA, params = Params},
		_StateName, Stream, #statedata{callback = CbMod, assoc = Assoc} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	APCs = m3ua_codec:get_all_paramter(?AffectedPointCode, Parameters),
	CbMod:pause(self(), Assoc, Stream, APCs),
	{next_state, inactive, StateData};
handle_asp(#m3ua{class = ?SSNMMessage, type = ?SSNMDAVA, params = Params},
		_StateName, Stream, #statedata{callback = CbMod, assoc = Assoc} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	APCs = m3ua_codec:get_all_paramter(?AffectedPointCode, Parameters),
	CbMod:resume(self(), Assoc, Stream, APCs),
	{next_state, active, StateData};
handle_asp(#m3ua{class = ?SSNMMessage, type = ?SSNMSCON, params = Params},
		StateName, Stream, #statedata{callback = CbMod, assoc = Assoc} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	APCs = m3ua_codec:get_all_paramter(?AffectedPointCode, Parameters),
	CbMod:status(self(), Assoc, Stream, APCs),
	{next_state, StateName, StateData}.

%% @hidden
generate_lrk_id() ->
	random:uniform(256).

