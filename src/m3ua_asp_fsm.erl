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
%%% 	for an MTP user. A callback module name is provided when starting
%%% 	an `Endpoint'. MTP service primitive indications are delivered to
%%% 	the MTP user through calls to the corresponding callback function
%%% 	as defined below.
%%%
%%%  <h2><a name="functions">Callbacks</a></h2>
%%%
%%%  <h3 class="function"><a name="init-5">init/5</a></h3>
%%%  <div class="spec">
%%%  <p><tt>init(Module, Asp, EP, EpName, Assoc) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Module = atom()</tt></li>
%%%    <li><tt>Asp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>EpName = term()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>Result = {ok, State} | {error, Reason} </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>Initialize ASP callback handler.</p>
%%%  <p>Called when ASP is started.</p>
%%%
%%%  <h3 class="function"><a name="transfer-8">transfer/8</a></h3>
%%%  <div class="spec">
%%%  <p><tt>transfer(Stream, RC, OPC, DPC, SLS, SIO,
%%%        Data, State) -&gt; Result</tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RC = pos_integer() | undefined </tt></li>
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
%%%  <h3 class="function"><a name="pause-4">pause/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>pause(Stream, RC, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RC = pos_integer() | undefined </tt></li>
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
%%%  <h3 class="function"><a name="resume-4">resume/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>resume(Stream, RC, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RC = pos_integer() | undefined </tt></li>
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
%%%  <h3 class="function"><a name="status-4">status/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>status(Stream, RC, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RC = pos_integer() | undefined </tt></li>
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
%%%  <h3 class="function"><a name="register-4">register/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>register(NA, Keys, TMT, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>NA = pos_integer()</tt></li>
%%%    <li><tt>Keys = [key()]</tt></li>
%%%    <li><tt>TMT = tmt()</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>Called when Registration Response message with a
%%%   registration status of successful from its peer</p>
%%%
%%%  <h3 class="function"><a name="asp_up-1">asp_up/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_up(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State}</tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="asp_down-1">asp_down/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_down(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State}</tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="asp_active-1">asp_active/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_active(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State}</tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="asp_inactive-1">asp_inactive/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_inactive(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State}</tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="notify-4">notify/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>notify(RC, Status, AspID, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>RC = pos_integer()</tt></li>
%%%    <li><tt>Status = as_inactive | as_active | as_pending
%%%         | insufficient_asp_active | alternate_asp_active
%%%         | asp_failure</tt></li>
%%%    <li><tt>AspID = pos_integer()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State}</tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="terminate-2">terminate/2</a></h3>
%%%  <div class="spec">
%%%  <p><tt>terminate(Reason, State)</tt>
%%%  <ul class="definitions">
%%%    <li><tt>Reason = term()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%  </ul></p>
%%%  </div><p>Called when an ASP terminates.</p>
%%%
%%% @end
-module(m3ua_asp_fsm).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(gen_fsm).

%% export the m3ua_asp_fsm public API
-export([transfer/7]).

%% export the callbacks needed for gen_fsm behaviour
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3,
			terminate/3, code_change/4]).

%% export the gen_fsm state callbacks
-export([down/2, down/3, inactive/2, inactive/3, active/2, active/3]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-record(statedata,
		{socket :: gen_sctp:sctp_socket() | undefined,
		peer_addr :: inet:ip_address(),
		peer_port :: inet:port_number(),
		in_streams :: non_neg_integer(),
		out_streams :: non_neg_integer(),
		assoc :: gen_sctp:assoc_id(),
		registration :: dynamic | static,
		use_rc :: boolean(),
		rks = [] :: [#{rc => pos_integer(), rk => routing_key()}],
		ual :: undefined | integer(),
		req :: undefined | tuple(),
		ep :: pid(),
		ep_name :: term(),
		callback :: atom() | #m3ua_fsm_cb{},
		cb_state :: term()}).

-define(Tack, 2000).

%%----------------------------------------------------------------------
%%  Interface functions
%%----------------------------------------------------------------------

-callback init(Module, Asp, EP, EpName, Assoc) -> Result
	when
		Module :: atom(),
		Asp :: pid(),
		EP :: pid(),
		EpName :: term(),
		Assoc :: pos_integer(),
		Result :: {ok, State} | {error, Reason},
		State :: term(),
		Reason :: term().
-callback transfer(Stream, RC, OPC, DPC, SLS, SIO, Data, State) -> Result
	when
		Stream :: pos_integer(),
		RC :: pos_integer() | undefined,
		OPC :: pos_integer(),
		DPC :: pos_integer(),
		SLS :: non_neg_integer(),
		SIO :: non_neg_integer(),
		Data :: binary(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback pause(Stream, RC, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		DPCs :: [DPC],
		RC :: pos_integer() | undefined,
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback resume(Stream, RC, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		DPCs :: [DPC],
		RC :: pos_integer() | undefined,
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback status(Stream, RC, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		DPCs :: [DPC],
		RC :: pos_integer() | undefined,
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback register(NA, Keys, TMT, State) -> Result
	when
		NA :: pos_integer(),
		Keys :: [key()],
		TMT :: tmt(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback asp_up(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
-callback asp_down(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
-callback asp_active(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
-callback asp_inactive(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
-callback notify(RC, Status, AspID, State) -> Result
	when
		RC :: pos_integer(),
		Status :: as_inactive | as_active | as_pending
				| insufficient_asp_active | alternate_asp_active | asp_failure,
		AspID :: pos_integer(),
		State :: term(),
		Result :: {ok, State}.
-callback terminate(Reason, State) -> Result
	when
		Reason :: term(),
		State :: term(),
		Result :: any().

%%----------------------------------------------------------------------
%%  The m3ua_asp_fsm public API
%%----------------------------------------------------------------------

-spec transfer(ASP, Stream, OPC, DPC, SLS, SIO, Data) -> Result
	when
		ASP :: pid(),
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
transfer(ASP, Stream, OPC, DPC, SLS, SIO, Data)
		when is_pid(ASP), is_integer(Stream), Stream =/= 0,
		is_integer(OPC), is_integer(DPC), is_integer(SLS),
		is_integer(SIO), is_binary(Data) ->
	Params = {Stream, OPC, DPC, SLS, SIO, Data},
	gen_fsm:sync_send_event(ASP, {'MTP-TRANSFER', request, Params}).

%%----------------------------------------------------------------------
%%  The m3ua_asp_fsm gen_fsm callbacks
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
init([Socket, Address, Port,
		#sctp_assoc_change{assoc_id = Assoc,
		inbound_streams = InStreams, outbound_streams = OutStreams},
		EP, EpName, Cb, Reg, UseRC]) ->
	CbArgs = [?MODULE, self(), EP, EpName, Assoc],
	case m3ua_callback:cb(init, Cb, CbArgs) of
		{ok, CbState} ->
			process_flag(trap_exit, true),
			Statedata = #statedata{socket = Socket, assoc = Assoc,
					peer_addr = Address, peer_port = Port,
					in_streams = InStreams, out_streams = OutStreams,
					ep = EP, ep_name = EpName, callback = Cb,
					cb_state = CbState, registration = Reg, use_rc = UseRC},
			{ok, down, Statedata, 0};
		{error, Reason} ->
			{stop, Reason}
	end.

-spec down(Event :: timeout | term(), StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(),
						NewStateData :: #statedata{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle events sent with {@link //stdlib/gen_fsm:send_event/2.
%% 	gen_fsm:send_event/2} in the <b>down</b> state.
%% @private
%%
down(timeout, #statedata{req = {asp_up, Ref, From}} = StateData) ->
	gen_server:cast(From, {'M-ASP_UP', confirm, Ref, self(), {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
down(timeout, #statedata{ep = EP, assoc = Assoc} = StateData) ->
	gen_server:cast(m3ua, {'M-SCTP_ESTABLISH', indication, self(), EP, Assoc}),
	{next_state, down, StateData};
down({'M-ASP_UP', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP} = StateData) ->
	AspUp = #m3ua{class = ?ASPSMMessage,
			type = ?ASPSMASPUP, params = <<>>},
	Packet = m3ua_codec:m3ua(AspUp),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			Req = {'M-ASP_UP', request, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, down, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
down({AspOp, request, Ref, From},
		#statedata{req = Req} = StateData) when Req /= undefined ->
	gen_server:cast(From, {AspOp, confirm, Ref, self(), {error, asp_busy}}),
	{next_state, down, StateData}.

-spec down(Event :: timeout | term(),
		From :: {pid(), Tag :: term()}, StateData :: #statedata{}) ->
		{reply, Reply :: term(),
				NextStateName :: atom(), NewStateData :: #statedata{}}
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
	gen_server:cast(From, {AspOp, confirm, Ref, self(), {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
inactive({'M-RK_REG', request, Ref, From, NA, Keys, Mode, AS},
		#statedata{registration = static, ep = EP,
		assoc = Assoc, callback = CbMod,
		cb_state = CbState} = StateData) ->
	gen_server:cast(From,
			{'M-RK_REG', confirm, Ref, self(),
			undefined, NA, Keys, Mode, AS, EP, Assoc, CbMod, CbState}),
	{next_state, inactive, StateData};
inactive({'M-RK_REG', request, Ref, From, NA, Keys, Mode, AS},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP} = StateData)  ->
	RK = #m3ua_routing_key{na = NA, tmt = Mode, key = Keys,
			lrk_id = generate_lrk_id(), as = AS},
	RoutingKey = m3ua_codec:routing_key(RK),
	Params = m3ua_codec:parameters([{?RoutingKey, RoutingKey}]),
	RegReq = #m3ua{class = ?RKMMessage, type = ?RKMREGREQ, params = Params},
	Message = m3ua_codec:m3ua(RegReq),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-RK_REG', request, Ref, From, RK},
			NewStateData = StateData#statedata{req = Req},
			{next_state, inactive, NewStateData, ?Tack};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
inactive({'M-ASP_ACTIVE', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP} = StateData) ->
	AspActive = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC},
	Message = m3ua_codec:m3ua(AspActive),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-ASP_ACTIVE', request, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, inactive, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
inactive({'M-ASP_DOWN', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP} = StateData) ->
	AspDown = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN},
	Message = m3ua_codec:m3ua(AspDown),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-ASP_DOWN', request, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, inactive, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
inactive({AspOp, request, Ref, From},
		#statedata{req = Req} = StateData) when Req /= undefined ->
	gen_server:cast(From, {AspOp, confirm, Ref, self(), {error, asp_busy}}),
	{next_state, inactive, StateData}.

-spec inactive(Event :: timeout | term(),
		From :: {pid(), Tag :: term()}, StateData :: #statedata{}) ->
		{reply, Reply :: term(), NextStateName :: atom(),
				NewStateData :: #statedata{}}
		| {stop, Reason :: term(), Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>inactive</b> state.
%% @private
%%
inactive({'MTP-TRANSFER', request, _Params}, _From, StateData) ->
	{reply, {error, unexpected_message}, down, StateData}.

-spec active(Event :: timeout | term(), StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(),
					NewStateData :: #statedata{}, timeout() | hibernate}
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
active({'M-RK_REG', request, Ref, From, NA, Keys, Mode, AS},
		#statedata{registration = static, ep = EP,
		assoc = Assoc, callback = CbMod,
		cb_state = CbState} = StateData) ->
	gen_server:cast(From,
			{'M-RK_REG', confirm, Ref, self(),
			undefined, NA, Keys, Mode, AS, EP, Assoc, CbMod, CbState}),
	{next_state, active, StateData};
active({'M-ASP_INACTIVE', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP} = StateData) ->
	AspInActive = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA},
	Message = m3ua_codec:m3ua(AspInActive),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-ASP_INACTIVE', request, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, active, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
active({'M-ASP_DOWN', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP} = StateData) ->
	AspDown = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN},
	Message = m3ua_codec:m3ua(AspDown),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-ASP_DOWN', request, Ref, From},
			NewStateData = StateData#statedata{req = Req},
			{next_state, active, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
active({AspOp, request, Ref, From},
		#statedata{req = Req} = StateData) when Req /= undefined ->
	gen_server:cast(From, {AspOp, confirm, Ref, self(), {error, asp_busy}}),
	{next_state, active, StateData}.

-spec active(Event :: timeout | term(),
		From :: {pid(), Tag :: term()}, StateData :: #statedata{}) ->
		{reply, Reply :: term(),
				NextStateName :: atom(), NewStateData :: #statedata{}}
		| {stop, Reason :: term(), Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>active</b> state.
%% @private
%%
active({'MTP-TRANSFER', request, {Stream, OPC, DPC, SLS, SIO, Data}},
		_From, #statedata{socket = Socket, assoc = Assoc, ep = EP} = StateData) ->
	ProtocolData = #protocol_data{opc = OPC, dpc = DPC,
			si = SIO, sls = SLS, data = Data},
	P0 = m3ua_codec:add_parameter(?ProtocolData, ProtocolData, []),
	TransferMsg = #m3ua{class = ?TransferMessage,
			type = ?TransferMessageData, params = P0},
	Packet = m3ua_codec:m3ua(TransferMsg),
	case gen_sctp:send(Socket, Assoc, Stream, Packet) of
		ok ->
			{reply, ok, active, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
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
handle_event({'M-NOTIFY', _NotifyFor, _RC}, StateName, StateData) ->
	% @todo do need to send notify ?
	{next_state, StateName, StateData};
handle_event({'M-RK_REG', {RC, RK}}, StateName,
		#statedata{rks = RKs} = StateData) ->
	NewRKs = [#{rc => RC, rk => RK} | RKs],
	NewStateData = StateData#statedata{rks = NewRKs},
	{next_state, StateName, NewStateData};
handle_event({'M-SCTP_RELEASE', request, Ref, From},
		_StateName, #statedata{socket = Socket} = StateData) ->
	gen_server:cast(From,
			{'M-SCTP_RELEASE', confirm, Ref, gen_sctp:close(Socket)}),
	NewStateData = StateData#statedata{socket = undefined},
	{stop, shutdown, NewStateData};
handle_event({'M-SCTP_STATUS', request, Ref, From},
		StateName, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
	Options = [{sctp_status, #sctp_status{assoc_id = Assoc}}],
	case inet_getopts(Socket, Options) of
		{ok, SCTPStatus} ->
			{_, Status} = lists:keyfind(sctp_status, 1, SCTPStatus),
			gen_server:cast(From,
					{'M-SCTP_STATUS', confirm, Ref, {ok, Status}}),
			{next_state, StateName, StateData};
		{error, Reason} ->
			gen_server:cast(From,
					{'M-SCTP_STATUS', confirm, Ref, {error, Reason}}),
			{next_state, StateName, StateData}
	end;
handle_event({Callback, CbState}, StateName, StateData)
		when (Callback == 'M-ASP_UP') orelse (Callback == 'M-ASP_DOWN')
		orelse (Callback == 'M-ASP_ACTIVE') orelse (Callback == 'M-ASP_INACTIVE')
		orelse (Callback == 'M-RK_REG') orelse (Callback == 'M-NOTIFY') ->
	NewStateData = StateData#statedata{cb_state = CbState},
	{next_state, StateName, NewStateData}.

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
handle_sync_event(getassoc, _From, StateName,
		#statedata{assoc = Assoc} = StateData) ->
	{reply, Assoc, StateName, StateData};
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
handle_info({sctp, Socket, _, _,
		{[], #sctp_paddr_change{addr = {_PeerAddr, _PeerPort},
		state = addr_unreachable}}}, _StateName,
		#statedata{socket = Socket} = StateData) ->
	{stop, addr_unreachable, StateData};
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_shutdown_event{assoc_id = AssocId}}},
		_StateName, #statedata{socket = Socket, assoc = AssocId,
		ep = EP} = StateData) ->
	{stop, {shutdown, {{EP, AssocId}, shutdown}}, StateData};
handle_info({sctp_error, Socket, PeerAddr, PeerPort,
		{[], #sctp_send_failed{flags = Flags, error = Error,
		info = Info, assoc_id = Assoc, data = Data}}},
		_StateName, #statedata{ep = EP} = StateData) ->
	error_logger:error_report(["SCTP error",
		{error, gen_sctp:error_string(Error)}, {flags, Flags},
		{assoc, Assoc}, {info, Info}, {data, Data}, {socket, Socket},
		{peer, {PeerAddr, PeerPort}}]),
	{stop, {shutdown, {{EP, Assoc}, Error}}, StateData};
handle_info({Ref, ok}, StateName, StateData) when is_reference(Ref) ->
	% late result arrival of timed out transfer request
	{next_state, StateName, StateData};
handle_info({'EXIT', EP, {shutdown, {EP, Reason}}}, _StateName,
		#statedata{ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData};
handle_info({'EXIT', Socket, Reason}, _StateName,
		#statedata{socket = Socket, ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}.

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		StateName :: atom(), StateData :: #statedata{}) -> any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_fsm:terminate/3
%% @private
%%
terminate(Reason, _StateName, #statedata{socket = undefined,
		callback = CbMod, cb_state = CbState} = _StateData)
		when CbMod /= undefined,
		((Reason == normal) orelse (Reason == shutdown)
		orelse ((element(1, Reason) == shutdown))) ->
	m3ua_callback:cb(terminate, CbMod, [Reason, CbState]);
terminate(Reason, _StateName, #statedata{socket = Socket,
		callback = CbMod, cb_state = CbState} = _StateData)
		when ((Reason == normal) orelse (Reason == shutdown)
		orelse ((element(1, Reason) == shutdown))) ->
	gen_sctp:close(Socket),
	m3ua_callback:cb(terminate, CbMod, [Reason, CbState]);
terminate(Reason, StateName, #statedata{socket = undefined,
		callback = CbMod, cb_state = CbState, ep = EP,
		assoc = Assoc} = StateData) ->
	error_logger:error_report(["Shutdown",
			{module, ?MODULE}, {pid, self()}, {endpoint, EP},
			{association, Assoc}, {reason, Reason},
			{statename, StateName}, {statedata, StateData}]),
	m3ua_callback:cb(terminate, CbMod, [Reason, CbState]);
terminate(Reason, StateName, #statedata{socket = Socket,
		callback = CbMod, cb_state = CbState, ep = EP,
		assoc = Assoc} = StateData) ->
	gen_sctp:close(Socket),
	error_logger:error_report(["Shutdown",
			{module, ?MODULE}, {pid, self()}, {endpoint, EP},
			{association, Assoc}, {reason, Reason},
			{statename, StateName}, {statedata, StateData}]),
	m3ua_callback:cb(terminate, CbMod, [Reason, CbState]).

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
handle_asp(#m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params},
		StateName, _Stream, #statedata{socket = Socket, callback = CbMod,
		cb_state = CbState, ep = EP, assoc = Assoc} = StateData) ->
	Parameters = m3ua_codec:parameters(Params),
	Status = m3ua_codec:fetch_parameter(?Status, Parameters),
	ASPId = proplists:get_value(?ASPIdentifier, Parameters),
	RC = proplists:get_value(?RoutingContext, Parameters),
	gen_server:cast(m3ua, {'M-NOTIFY', indication, self(),
			EP, Assoc, RC, Status, ASPId, CbMod, CbState}),
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, StateData};
handle_asp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
		down, _Stream, #statedata{req = {'M-ASP_UP', request, Ref, From},
		socket = Socket, callback = CbMod, cb_state = State, ep = EP,
		assoc = Assoc} = StateData) ->
	gen_server:cast(From, {'M-ASP_UP', confirm, Ref,
			{ok, CbMod, self(), EP, Assoc, State, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData};
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK},
		inactive, _Stream, #statedata{req = {'M-ASP_ACTIVE', request, Ref, From},
		socket = Socket, callback = CbMod, cb_state = State, ep = EP,
		assoc = Assoc} = StateData) ->
	gen_server:cast(From, {'M-ASP_ACTIVE', confirm, Ref,
			{ok, CbMod, self(), EP, Assoc, State, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, active, NewStateData};
handle_asp(#m3ua{class = ?RKMMessage, type = ?RKMREGRSP} = Msg,
		inactive, _Stream, #statedata{socket = Socket,
		req ={'M-RK_REG', request, Ref, From,
		#m3ua_routing_key{na = NA, tmt = TMT, as = AS, key = Keys}},
		callback = CbMod, cb_state = CbState, ep = EP,
		assoc = Assoc} = StateData) ->
	gen_server:cast(From,
			{'M-RK_REG', confirm, Ref, self(),
			Msg, NA, Keys, TMT, AS, EP, Assoc, CbMod, CbState}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData};
handle_asp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDNACK},
		StateName, _Stream, #statedata{req = {'M-ASP_DOWN', request, Ref, From},
		socket = Socket, callback = CbMod, cb_state = State, ep = EP,
		assoc = Assoc} = StateData) when StateName == inactive;
		StateName == active ->
	gen_server:cast(From, {'M-ASP_DOWN', confirm, Ref,
			{ok, CbMod, self(), EP, Assoc, State, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK},
		active, _Stream, #statedata{req = {'M-ASP_INACTIVE', request, Ref, From},
		socket = Socket, callback = CbMod, cb_state = State, ep = EP,
		assoc = Assoc} = StateData) ->
	gen_server:cast(From, {'M-ASP_INACTIVE', confirm, Ref,
			{ok, CbMod, self(), EP, Assoc, State, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData};
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPSMASPDNACK},
		active, _Stream, #statedata{req = {'M-ASP_DOWN', request, Ref, From},
		socket = Socket, callback = CbMod, cb_state = CbState, ep = EP,
		assoc = Assoc} = StateData) ->
	gen_server:cast(From, {'M-ASP_DOWN', confirm, Ref,
			{ok, CbMod, self(), EP, Assoc, CbState, undefined, undefined}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
handle_asp(#m3ua{class = ?MGMTMessage, type = ?MGMTError, params = Params},
		active, _Stream, #statedata{req = {AspOp, request, Ref, From},
		socket = Socket} = StateData) ->
	Parameters = m3ua_codec:parameters(Params),
	{ok, Reason} = m3ua_codec:find_parameter(?ErrorCode, Parameters),
	gen_server:cast(From, {AspOp, confirm, Ref, self(), {error, Reason}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
handle_asp(#m3ua{class = ?TransferMessage,
		type = ?TransferMessageData, params = Params}, active, Stream,
		#statedata{callback = CbMod, cb_state = CbState,
		socket = Socket} = StateData) when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = proplists:get_value(?RoutingContext, Parameters),
	#protocol_data{opc = OPC, dpc = DPC, si = SIO, sls = SLS, data = Data} =
			m3ua_codec:fetch_parameter(?ProtocolData, Parameters),
	CbArgs = [Stream, RC, OPC, DPC, SLS, SIO, Data, CbState],
	{ok, NewCbState} = m3ua_callback:cb(transfer, CbMod, CbArgs),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{cb_state = NewCbState},
	{next_state, active, NewStateData};
handle_asp(#m3ua{class = ?SSNMMessage, type = ?SSNMDUNA, params = Params},
		StateName, Stream, #statedata{callback = CbMod, cb_state = CbState,
		socket = Socket} = StateData) when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = proplists:get_value(?RoutingContext, Parameters),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	CbArgs = [Stream, RC, APCs, CbState],
	{ok, NewCbState} = m3ua_callback:cb(pause, CbMod, CbArgs),
	NewStateData = StateData#statedata{cb_state = NewCbState},
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, NewStateData};
handle_asp(#m3ua{class = ?SSNMMessage, type = ?SSNMDAVA, params = Params},
		StateName, Stream, #statedata{callback = CbMod, cb_state = CbState,
		socket = Socket} = StateData) when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = proplists:get_value(?RoutingContext, Parameters),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	CbArgs = [Stream, RC, APCs, CbState],
	{ok, NewCbState} = m3ua_callback:cb(resume, CbMod, CbArgs),
	NewStateData = StateData#statedata{cb_state = NewCbState},
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, NewStateData};
handle_asp(#m3ua{class = ?SSNMMessage, type = ?SSNMSCON, params = Params},
		StateName, Stream, #statedata{callback = CbMod, cb_state = CbState,
		socket = Socket} = StateData) when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = proplists:get_value(?RoutingContext, Parameters),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	CbArgs = [Stream, RC, APCs, CbState],
	{ok, NewCbState} = m3ua_callback:cb(status, CbMod, CbArgs),
	NewStateData = StateData#statedata{cb_state = NewCbState},
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, NewStateData};
handle_asp(#m3ua{class = ?MGMTMessage, type = ?MGMTError, params = Params},
		StateName, _Stream,
		#statedata{assoc = Assoc, ep = EP, socket = Socket} = StateData) ->
	Parameters = m3ua_codec:parameters(Params),
	ErrorCode = proplists:get_value(?ErrorCode, Parameters),
	error_logger:error_report(["M3UA protocol error",
			{module, ?MODULE}, {state, StateName}, {endpoint, EP},
			{association, Assoc}, {error, ErrorCode}]),
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, StateData}.

%% @hidden
generate_lrk_id() ->
	random:uniform(256).

-dialyzer({[nowarn_function, no_contracts, no_return], inet_getopts/2}).
-spec inet_getopts(Socket, Options) -> Result
	when
		Socket :: gen_sctp:sctp_socket(),
		Options :: [gen_sctp:option()],
		Result :: {ok, OptionValues} | {error, Posix},
		OptionValues :: [gen_sctp:option()],
		Posix :: inet:posix().
%% @hidden
inet_getopts(Socket, Options) ->
	case catch inet:getopts(Socket, Options) of
		{'EXIT', Reason} -> % fake dialyzer out 
			{error, Reason};
		Result ->
			Result
	end.

