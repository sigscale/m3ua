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
%%%   for a Signaling Gateway Process (SGP).
%%%
%%% 	This behaviour module provides an MTP service primitives interface
%%% 	for an MTP user. A calback module name is provided in the
%%% 	`{callback, Module}' option when opening an `Endpoint'. MTP service
%%% 	primitive indications are delivered to the MTP user by calling the
%%% 	corresponding callback function as defined below.
%%%
%%%  <h2><a name="functions">Callbacks</a></h2>
%%%
%%%  <h3 class="function"><a name="init-4">init/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>init(Log, Sgp, EP, Assoc) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Module = atom()</tt></li>
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, State} | {error, Reason} </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>Initialize SGP callback handler.</p>
%%%  <p>Called when SGP is started.</p>
%%%
%%%  <h3 class="function"><a name="transfer-11">transfer/11</a></h3>
%%%  <div class="spec">
%%%  <p><tt>transfer(Sgp, EP, Assoc, Stream,
%%% 		RC, OPC, DPC, SLS, SIO, Data, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
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
%%%  <h3 class="function"><a name="pause-7">pause/7</a></h3>
%%%  <div class="spec">
%%%  <p><tt>pause(Sgp, EP, Assoc, Stream, RC, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
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
%%%  <h3 class="function"><a name="resume-7">resume/7</a></h3>
%%%  <div class="spec">
%%%  <p><tt>resume(Sgp, EP, Assoc, Stream, RC, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
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
%%%  <h3 class="function"><a name="status-6">status/6</a></h3>
%%%  <div class="spec">
%%%  <p><tt>status(Sgp, EP, Assoc, Stream, RC, DCPs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
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
%%%  <h3 class="function"><a name="register-7">register/7</a></h3>
%%%  <div class="spec">
%%%  <p><tt>register(Sgp, EP, Assoc, NA, Keys, TMT, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>NA = pos_integer()</tt></li>
%%%    <li><tt>Keys = [key()]</tt></li>
%%%    <li><tt>TMT = tmt()</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>Called when successfully processed an
%%%   incoming Registration Request message </p>
%%%
%%%  <h3 class="function"><a name="asp_up-4">asp_up/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_up(Sgp, EP, Assoc, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="asp_down-4">asp_down/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_down(Sgp, EP, Assoc, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="asp_active-4">asp_active/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_active(Sgp, EP, Assoc, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%%  <h3 class="function"><a name="asp_inactive-4">asp_inactive/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_inactive(Sgp, EP, Assoc, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Sgp = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>Assoc = pos_integer()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%
%%% @end
-module(m3ua_sgp_fsm).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(gen_fsm).

%% export the m3ua_sgp_fsm public API
-export([transfer/7]).

%% export the callbacks needed for gen_fsm behaviour
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3,
			terminate/3, code_change/4]).

%% export the gen_fsm state callbacks
-export([down/2, down/3, inactive/2, inactive/3, active/2, active/3]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-record(statedata,
		{sctp_role :: client | server,
		socket :: gen_sctp:sctp_socket() | undefined,
		peer_addr :: inet:ip_address(),
		peer_port :: inet:port_number(),
		in_streams :: non_neg_integer(),
		out_streams :: non_neg_integer(),
		assoc :: gen_sctp:assoc_id(),
		rks = [] :: [#{rc => pos_integer(), rk => routing_key()}],
		ual :: undefined | integer(),
		stream :: undefined | integer(),
		ep :: pid(),
		registration :: dynamic | static,
		use_rc :: boolean(),
		callback :: atom() | #m3ua_fsm_cb{},
		cb_state :: term()}).

%%----------------------------------------------------------------------
%%  Interface functions
%%----------------------------------------------------------------------

-callback init(Module, Sgp, EP, Assoc) -> Result
	when
		Module :: atom(),
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		Result :: {ok, State} | {error, Reason},
		State :: term(),
		Reason :: term().
-callback transfer(Sgp, EP, Assoc, Stream,
		RC, OPC, DPC, SLS, SIO, Data, State) -> Result
	when
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
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
-callback pause(Sgp, EP, Assoc, Stream, RC, DPCs, State) -> Result
	when
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		RC :: pos_integer() | undefined,
		DPCs :: [DPC],
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback resume(Sgp, EP, Assoc, Stream, RC, DPCs, State) -> Result
	when
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		RC :: pos_integer() | undefined,
		DPCs :: [DPC],
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback status(Sgp, EP, Assoc, Stream, RC, DPCs, State) -> Result
	when
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		RC :: pos_integer() | undefined,
		DPCs :: [DPC],
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback register(Sgp, EP, Assoc, NA, Keys, TMT, State) -> Result
	when
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		NA :: pos_integer(),
		Keys :: [key()],
		TMT :: tmt(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback asp_up(Sgp, EP, Assoc, State) -> Result
	when
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		State :: term(),
		Result :: {ok, State}.
-callback asp_down(Sgp, EP, Assoc, State) -> Result
	when
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		State :: term(),
		Result :: {ok, State}.
-callback asp_active(Sgp, EP, Assoc, State) -> Result
	when
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		State :: term(),
		Result :: {ok, State}.
-callback asp_inactive(Sgp, EP, Assoc, State) -> Result
	when
		Sgp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		State :: term(),
		Result :: {ok, State}.

%%----------------------------------------------------------------------
%%  The m3ua_sgp_fsm public API
%%----------------------------------------------------------------------

-spec transfer(SGP, Stream, OPC, DPC, SLS, SIO, Data) -> Result
	when
		SGP :: pid(),
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
transfer(SGP, Stream, OPC, DPC, SLS, SIO, Data)
		when is_pid(SGP), is_integer(Stream), Stream =/= 0,
		is_integer(OPC), is_integer(DPC), is_integer(SLS),
		is_integer(SIO), is_binary(Data) ->
	Params = {Stream, OPC, DPC, SLS, SIO, Data},
	gen_fsm:sync_send_event(SGP, {'MTP-TRANSFER', request, Params}).

%%----------------------------------------------------------------------
%%  The m3ua_sgp_fsm gen_fsm callbacks
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
init([SctpRole, Socket, Address, Port,
		#sctp_assoc_change{assoc_id = Assoc,
		inbound_streams = InStreams, outbound_streams = OutStreams},
		EP, Cb, Reg, UseRC]) ->
	Args = [?MODULE, self(), EP, Assoc],
	case m3ua_callback:cb(init, Cb, Args) of
		{ok, CbState} ->
			process_flag(trap_exit, true),
			Statedata = #statedata{sctp_role = SctpRole,
					socket = Socket, assoc = Assoc,
					peer_addr = Address, peer_port = Port,
					in_streams = InStreams, out_streams = OutStreams,
					callback = Cb, cb_state = CbState, ep = EP,
					registration = Reg, use_rc = UseRC},
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
down(timeout, #statedata{ep = EP, assoc = Assoc} = StateData) ->
	gen_server:cast(m3ua, {'M-SCTP_ESTABLISH', self(), EP, Assoc}),
	{next_state, down, StateData};
down({'M-RK_REG', request, Ref, From, NA, Keys, Mode, AS},
		#statedata{ep = EP, assoc = Assoc, callback = CbMod,
		cb_state = UState} = StateData) ->
	gen_server:cast(From,
			{'M-RK_REG', confirm, Ref, self(),
			undefined, NA, Keys, Mode, AS, EP, Assoc, CbMod, UState}),
	{next_state, down, StateData}.

-spec down(Event :: timeout | term(),
		From :: {pid(), Tag :: term()}, StateData :: #statedata{}) ->
		{reply, Reply :: term(),
				NextStateName :: atom(), NewStateData :: #statedata{}}
		| {stop, Reason :: term(),
				Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>down</b> state.
%% @private
%%
down({'MTP-TRANSFER', request, _Params}, _From, StateData) ->
	{reply, {error, unexpected_message}, down, StateData}.

-spec inactive(Event :: timeout | term(), StateData :: #statedata{}) ->
	{next_state, NextStateName :: atom(), NewStateData :: #statedata{}}
			| {next_state, NextStateName :: atom(),
					NewStateData :: #statedata{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle events sent with {@link //stdlib/gen_fsm:send_event/2.
%% 	gen_fsm:send_event/2} in the <b>inactive</b> state.
%% @private
%%
inactive({'M-RK_REG', request, Ref, From, NA, Keys, Mode, AS},
		#statedata{ep = EP, assoc = Assoc, callback = CbMod,
		cb_state = UState} = StateData) ->
	gen_server:cast(From,
			{'M-RK_REG', confirm, Ref, self(),
			undefined, NA, Keys, Mode, AS, EP, Assoc, CbMod, UState}),
	{next_state, inactive, StateData}.

-spec inactive(Event :: timeout | term(),
		From :: {pid(), Tag :: term()}, StateData :: #statedata{}) ->
		{reply, Reply :: term(), NextStateName :: atom(),
				NewStateData :: #statedata{}}
		| {stop, Reason :: term(),
				Reply :: term(), NewStateData :: #statedata{}}.
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
active({'M-RK_REG', request, Ref, From, NA, Keys, Mode, AS},
		#statedata{ep = EP, assoc = Assoc, callback = CbMod,
		cb_state = UState} = StateData) ->
	gen_server:cast(From,
			{'M-RK_REG', confirm, Ref, self(),
			undefined, NA, Keys, Mode, AS, EP, Assoc, CbMod, UState}),
	{next_state, active, StateData}.

-spec active(Event :: timeout | term(),
		From :: {pid(), Tag :: term()}, StateData :: #statedata{}) ->
		{reply, Reply :: term(),
				NextStateName :: atom(), NewStateData :: #statedata{}}
		| {stop, Reason :: term(),
				Reply :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with {@link //stdlib/gen_fsm:sync_send_event/2.
%% 	gen_fsm:sync_send_event/2,3} in the <b>active</b> state.
%% @private
%%
active({'MTP-TRANSFER', request, {Stream, OPC, DPC, SLS, SIO, Data}}, _From,
		#statedata{socket = Socket, assoc = Assoc, ep = EP} = StateData) ->
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
			| {next_state, NextStateName :: atom(),
					NewStateData :: #statedata{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewStateData :: #statedata{}}.
%% @doc Handle an event sent with
%% 	{@link //stdlib/gen_fsm:send_all_state_event/2.
%% 	gen_fsm:send_all_state_event/2}.
%% @see //stdlib/gen_fsm:handle_event/3
%% @private
%%
handle_event({'NTFY', NotifyFor, _RC}, StateName,
		#statedata{socket = Socket, assoc = Assoc, ep = EP} = StateData) ->
	Params = case NotifyFor of
		'AS_ACTIVE' ->
			[{?Status, {assc, active}}];
		'AS_INACTIVE' ->
			[{?Status, {assc, inactive}}];
		'AS_PENDING' ->
			[{?Status, {assc, pending}}]
	end,
	Notify = #m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params},
	Message = m3ua_codec:m3ua(Notify),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			inet:setopts(Socket, [{active, once}]),
			{next_state, StateName, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
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
handle_event({Indication,  State}, StateName, StateData)
		when Indication == 'M-ASP_UP'; Indication == 'M-ASP_DOWN';
		Indication == 'M-ASP_ACTIVE'; Indication == 'M-ASP_INACTIVE';
		Indication == 'M-RK_REG' ->
	NewStateData = StateData#statedata{cb_state = State},
	{next_state, StateName, NewStateData}.

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
		{[#sctp_sndrcvinfo{assoc_id = Assoc, stream = Stream}], Data}},
		StateName, #statedata{socket = Socket,
		assoc = Assoc} = StateData) when is_binary(Data) ->
	handle_sgp(Data, StateName, Stream, StateData);
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
		_StateName, #statedata{socket = Socket, assoc = AssocId,
		ep = EP} = StateData) ->
	{stop, {shutdown, {{EP, AssocId}, shutdown}}, StateData};
handle_info({sctp_error, Socket, PeerAddr, PeerPort,
		{[], #sctp_send_failed{flags = Flags, error = Error,
		info = Info, assoc_id = Assoc, data = Data}}},
		_StateName, #statedata{assoc = Assoc, ep = EP} = StateData) ->
	error_logger:error_report(["SCTP error",
		{error, gen_sctp:error_string(Error)}, {flags, Flags},
		{assoc, Assoc}, {info, Info}, {data, Data}, {socket, Socket},
		{peer, {PeerAddr, PeerPort}}]),
	{stop, {shutdown, {{EP, Assoc}, Error}}, StateData}.

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		StateName :: atom(), StateData :: #statedata{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_fsm:terminate/3
%% @private
%%
terminate(normal = _Reason, _StateName,
		#statedata{socket = undefined} = _StateData) ->
	ok;
terminate(normal = _Reason, _StateName,
		#statedata{socket = Socket} = _StateData) ->
	gen_sctp:close(Socket),
	ok;
terminate(shutdown, _StateName,
		#statedata{socket = undefined} = _StateData) ->
	ok;
terminate(shutdown, _StateName,
		#statedata{socket = Socket} = _StateData) ->
	gen_sctp:close(Socket),
	ok;
terminate({shutdown, _}, _StateName,
		#statedata{socket = undefined} = _StateData) ->
	ok;
terminate({shutdown, _}, _StateName,
		#statedata{socket = Socket} = _StateData) ->
	gen_sctp:close(Socket),
	ok;
terminate(Reason, StateName, #statedata{socket = undefined} = StateData) ->
	error_logger:error_report(["Abnormal process termination",
			{module, ?MODULE}, {pid, self()}, {reason, Reason},
			{statename, StateName}, {statedata, StateData}]);
terminate(Reason, StateName, #statedata{socket = Socket} = StateData) ->
	gen_sctp:close(Socket),
	error_logger:error_report(["Abnormal process termination",
			{module, ?MODULE}, {pid, self()}, {reason, Reason},
			{statename, StateName}, {statedata, StateData}]).

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
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP},
		down, _Stream, #statedata{socket = Socket, assoc = Assoc,
		callback = CbMod, cb_state = State, ep = EP} = StateData) ->
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			gen_server:cast(m3ua, {'M-ASP_UP',
					indication, CbMod, self(), EP, Assoc, State}),
			inet:setopts(Socket, [{active, once}]),
			{next_state, inactive, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP},
		inactive, _Stream, #statedata{socket = Socket,
		assoc = Assoc, ep = EP} = StateData) ->
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			P0 = m3ua_codec:add_parameter(?ErrorCode, unexpected_message, []),
			EParams = m3ua_codec:parameters(P0),
			ErrorMsg = #m3ua{class = ?MGMTMessage,
					type = ?MGMTError, params = EParams},
			Packet2 = m3ua_codec:m3ua(ErrorMsg),
			case gen_sctp:send(Socket, Assoc, 0, Packet2) of
				ok ->
					inet:setopts(Socket, [{active, once}]),
					{next_state, inactive, StateData};
				{error, eagain} ->
					% @todo flow control
					{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
				{error, Reason} ->
					{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
			end;
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?RKMMessage, type = ?RKMREGREQ} = Msg,
		inactive, _Stream, #statedata{socket = Socket, ep = EP,
		assoc = Assoc, callback = CbMod, cb_state = State} = StateData) ->
	gen_server:cast(m3ua,
			{'M-RK_REG', Msg, Socket, EP, Assoc, self(), CbMod, State}),
	inet:setopts(Socket, [{active, once}]),
	{next_state, inactive, StateData};
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC, params = Params},
		inactive, _Stream, #statedata{socket = Socket, assoc = Assoc, ep = EP,
		callback = CbMod, cb_state = State} = StateData) ->
	AspActive = m3ua_codec:parameters(Params),
	RCs = proplists:get_value(?RoutingContext, AspActive),
	Message = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK},
	Packet = m3ua_codec:m3ua(Message),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			gen_server:cast(m3ua, {'M-ASP_ACTIVE',
					indication, self(), EP, Assoc, RCs, CbMod, State}),
			inet:setopts(Socket, [{active, once}]),
			{next_state, active, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN}, StateName,
		_Stream, #statedata{socket = Socket, assoc = Assoc, callback = CbMod,
		cb_state = State, ep = EP} = StateData) when StateName == inactive;
		StateName == active ->
	AspActiveAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDNACK},
	Packet = m3ua_codec:m3ua(AspActiveAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			gen_server:cast(m3ua, {'M-ASP_DOWN',
					indication, CbMod, self(), EP, Assoc, State}),
			inet:setopts(Socket, [{active, once}]),
			{next_state, down, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA, params = Params},
		active, _Stream, #statedata{socket = Socket, assoc = Assoc, ep = EP,
		callback = CbMod, cb_state = State} = StateData) ->
	AspInActive = m3ua_codec:parameters(Params),
	RCs = proplists:get_value(?RoutingContext, AspInActive),
	Message = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK},
	Packet = m3ua_codec:m3ua(Message),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			gen_server:cast(m3ua, {'M-ASP_INACTIVE',
					indication, self(), EP, Assoc, RCs, CbMod, State}),
			inet:setopts(Socket, [{active, once}]),
			{next_state, inactive, StateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?TransferMessage,
		type = ?TransferMessageData, params = Params},
		_ActiveState, Stream,
		#statedata{socket = Socket, callback = CbMod, cb_state = State,
		assoc = Assoc, ep = EP} = StateData) when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = proplists:get_value(?RoutingContext, Parameters),
	#protocol_data{opc = OPC, dpc = DPC, si = SIO, sls = SLS,
			data = Data} = m3ua_codec:fetch_parameter(?ProtocolData, Parameters),
	Args = [self(), EP, Assoc, Stream, RC, OPC, DPC, SLS, SIO, Data, State],
	{ok, NewState} = m3ua_callback:cb(transfer, CbMod, Args),
	NewStateData = StateData#statedata{cb_state = NewState},
	inet:setopts(Socket, [{active, once}]),
	{next_state, active, NewStateData};
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMDUNA, params = Params},
		_StateName, Stream, #statedata{socket = Socket, callback = CbMod,
		cb_state = State, assoc = Assoc, ep = EP} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = proplists:get_value(?RoutingContext, Parameters),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	Args = [self(), EP, Assoc, Stream, RC, APCs, State],
	{ok, NewState} = m3ua_callback:cb(pause, CbMod, Args),
	NewStateData = StateData#statedata{cb_state = NewState},
	inet:setopts(Socket, [{active, once}]),
	{next_state, inactive, NewStateData};
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMDAVA, params = Params},
		_StateName, Stream, #statedata{socket = Socket, callback = CbMod,
		cb_state = State, assoc = Assoc, ep = EP} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = proplists:get_value(?RoutingContext, Parameters),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	Args = [self(), EP, Assoc, Stream, RC, APCs, State],
	{ok, NewState} = m3ua_callback:cb(resume, CbMod, Args),
	NewStateData = StateData#statedata{cb_state = NewState},
	inet:setopts(Socket, [{active, once}]),
	{next_state, active, NewStateData};
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMSCON, params = Params},
		StateName, Stream, #statedata{socket = Socket, callback = CbMod,
		cb_state = State, assoc = Assoc, ep = EP} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = proplists:get_value(?RoutingContext, Parameters),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	Args = [self(), EP, Assoc, Stream, RC, APCs, State],
	{ok, NewState} = m3ua_callback:cb(resume, CbMod, Args),
	NewStateData = StateData#statedata{cb_state = NewState},
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, NewStateData}.

-dialyzer({[nowarn_function, no_contracts], inet_getopts/2}).
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

