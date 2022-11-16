%%% m3ua_sgp_fsm.erl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2015-2021 SigScale Global Inc.
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
%%% 	for an MTP user. A callback module name is provided when starting
%%% 	an `Endpoint'. MTP service primitive indications are delivered to
%%% 	the MTP user through calls to the corresponding callback functions
%%% 	as defined below.
%%%
%%%  <h2><a name="functions">Callbacks</a></h2>
%%%
%%%  <h3 class="function"><a name="init-5">init/5</a></h3>
%%%  <div class="spec">
%%%  <p><tt>init(Module, SGP, EP, EpName, Assoc, Options) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Module = atom()</tt></li>
%%%    <li><tt>SGP = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>EpName = term()</tt></li>
%%%    <li><tt>Assoc = gen_sctp:assoc_id()</tt></li>
%%%    <li><tt>Options = term()</tt></li>
%%%    <li><tt>Result = {ok, Active, State} | {ok, Active, State, RKs} | {error, Reason}</tt></li>
%%%    <li><tt>Active = true | false | once | pos_integer()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>RKs = [{RC, RK, AsName}]</tt></li>
%%%    <li><tt>RC = 0..4294967295 | undefined</tt></li>
%%%    <li><tt>RK = {NA, Keys, TMT}</tt></li>
%%%    <li><tt>NA = 0..4294967295 | undefined</tt></li>
%%%    <li><tt>Keys = [m3ua:key()]</tt></li>
%%%    <li><tt>Mode = m3ua:tmt()</tt></li>
%%%    <li><tt>AsName = term()</tt></li>
%%%    <li><tt>Reason = term()</tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>Initialize SGP callback handler.</p>
%%%  <p>Called when SGP is started.</p>
%%%
%%%  <h3 class="function"><a name="recv-9">recv/9</a></h3>
%%%  <div class="spec">
%%%  <p><tt>recv(Stream, RC, OPC, DPC, NI, SI, SLS,
%%%         Data, State) -&gt; Result</tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RC = 0..4294967295 | undefined </tt></li>
%%%    <li><tt>OPC = 0..16777215</tt></li>
%%%    <li><tt>DPC = 0..16777215</tt></li>
%%%    <li><tt>NI = byte() </tt></li>
%%%    <li><tt>SI = byte() </tt></li>
%%%    <li><tt>SLS = byte() </tt></li>
%%%    <li><tt>Data = binary() </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, Active, NewState} | {error, Reason}</tt></li>
%%%    <li><tt>Active = true | false | once | pos_integer()</tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>MTP-TRANSFER indication.</p>
%%%  <p>Called when data has arrived for the MTP user.</p>
%%%
%%%  <h3 class="function"><a name="send-11">send/11</a></h3>
%%%  <div class="spec">
%%%  <p><tt>send(From, Ref, Stream, RC, OPC, DPC, NI, SI, SLS,
%%%        Data, State) -&gt; Result</tt>
%%%  <ul class="definitions">
%%%    <li><tt>From = pid()</tt></li>
%%%    <li><tt>Ref = reference()</tt></li>
%%%    <li><tt>Stream = pos_integer() </tt></li>
%%%    <li><tt>RC = 0..4294967295 | undefined</tt></li>
%%%    <li><tt>OPC = 0..16777215</tt></li>
%%%    <li><tt>DPC = 0..16777215</tt></li>
%%%    <li><tt>NI = byte() </tt></li>
%%%    <li><tt>SI = byte() </tt></li>
%%%    <li><tt>SLS = byte() </tt></li>
%%%    <li><tt>Data = binary() </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, Active, NewState} | {error, Reason}</tt></li>
%%%    <li><tt>Active = true | false | once | pos_integer()</tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>MTP-TRANSFER confirm.</p>
%%%  <p>Called when data has been sent by the MTP user.</p>
%%%
%%%  <h3 class="function"><a name="pause-4">pause/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>pause(Stream, RCs, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RCs = [RC]</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = 0..16777215</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>MTP-PAUSE indication.</p>
%%%  <p>Called when an SS7 destination is unreachable.</p>
%%%
%%%  <h3 class="function"><a name="resume-4">resume/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>resume(Stream, RCs, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RCs = [RC]</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = 0..16777215</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%   </ul></p>
%%%  </div>
%%%  <p>MTP-RESUME indication.</p>
%%%  <p>Called when a previously unreachable SS7 destination
%%%  becomes reachable.</p>
%%%
%%%  <h3 class="function"><a name="status-4">status/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>status(Stream, RCs, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>RCs = [RC]</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = 0..16777215</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>MTP-STATUS indication.</p>
%%%  <p>Called when congestion occurs for an SS7 destination
%%% 	or to indicate an unavailable remote user part.</p>
%%%
%%%  <h3 class="function"><a name="register-5">register/5</a></h3>
%%%  <div class="spec">
%%%  <p><tt>register(RC, NA, Keys, TMT, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>NA = 0..4294967295</tt></li>
%%%    <li><tt>Keys = [m3ua:key()]</tt></li>
%%%    <li><tt>TMT = m3ua:tmt()</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-RK_REG indication.</p>
%%%  <p>Called after successfully processing an
%%%   incoming Registration request or static registration completes.</p>
%%%
%%%  <h3 class="function"><a name="asp_up-1">asp_up/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_up(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-ASP_UP indication.</p>
%%%  <p>Called when ASP UP ACK is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="asp_down-1">asp_down/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_down(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-ASP_DOWN indication.</p>
%%%  <p>Called when ASP DOWN ACK is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="asp_active-1">asp_active/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_active(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-ASP_ACTIVE indication.</p>
%%%  <p>Called when ASP ACTIVE ACK is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="asp_inactive-1">asp_inactive/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_inactive(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-ASP_INACTIVE indication.</p>
%%%  <p>Called when ASP INACTIVE ACK is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="notify-4">notify/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>notify(RCs, Status, AspID, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>RCs = [RC] | undefined</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>Status = as_inactive | as_active | as_pending
%%%         | insufficient_asp_active | alternate_asp_active
%%%         | asp_failure</tt></li>
%%%    <li><tt>AspID = 0..4294967295</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State}</tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-NOTIFY indication.</p>
%%%  <p>Called when NOTIFY is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="info-2">info/2</a></h3>
%%%  <div class="spec">
%%%  <p><tt>info(Info, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Info = term()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, Active, NewState} | {error, Reason}</tt></li>
%%%    <li><tt>Active = true | false | once | pos_integer()</tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>Handle info callback.</p>
%%%  <p>Called when other information is received by SGP.</p>
%%%
%%%  <h3 class="function"><a name="terminate-2">terminate/2</a></h3>
%%%  <div class="spec">
%%%  <p><tt>terminate(Reason, State)</tt>
%%%  <ul class="definitions">
%%%    <li><tt>Reason = term()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>Terminate ASP.</p>
%%%  <p>Called when an ASP shall be shutdown.</p>
%%%
%%% @end
-module(m3ua_sgp_fsm).
-copyright('Copyright (c) 2015-2021 SigScale Global Inc.').

-behaviour(gen_fsm).

%% export the callbacks needed for gen_fsm behaviour
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3,
			terminate/3, code_change/4]).

%% export the gen_fsm state callbacks
-export([down/2, down/3, inactive/2, inactive/3, active/2, active/3]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-record(statedata,
		{socket :: gen_sctp:sctp_socket() | undefined,
		active :: true | false | once | pos_integer(),
		peer_addr :: inet:ip_address(),
		peer_port :: inet:port_number(),
		in_streams :: non_neg_integer(),
		out_streams :: non_neg_integer(),
		assoc :: gen_sctp:assoc_id(),
		rks = [] :: [{RC :: 0..4294967295,
				RK :: m3ua:routing_key(), Active :: boolean()}],
		ual :: undefined | integer(),
		stream :: undefined | pos_integer(),
		ep :: pid(),
		ep_name :: term(),
		static :: boolean(),
		use_rc :: boolean(),
		callback :: atom() | #m3ua_fsm_cb{},
		cb_opts :: term(),
		cb_state :: term(),
		count = #{} :: #{atom() => non_neg_integer()}}).

%%----------------------------------------------------------------------
%%  Interface functions
%%----------------------------------------------------------------------

-callback init(Module, SGP, EP, EpName, Assoc, Options) -> Result
	when
		Module :: atom(),
		SGP :: pid(),
		EP :: pid(),
		EpName :: term(),
		Assoc :: gen_sctp:assoc_id(),
		Options :: term(),
		Result :: {ok, Active, State} | {ok, Active, State, ASs} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		State :: term(),
		ASs :: [{RC, RK, AsName}],
		RC :: 0..4294967295,
		RK :: {NA, Keys, TMT},
		NA :: 0..4294967295 | undefined,
		Keys :: [m3ua:key()],
		TMT :: m3ua:tmt(),
		AsName :: term(),
		Reason :: term().
-callback recv(Stream, RC, OPC, DPC, NI, SI, SLS, Data, State) -> Result
	when
		Stream :: pos_integer(),
		RC :: 0..4294967295 | undefined,
		OPC :: 0..16777215,
		DPC :: 0..16777215,
		NI :: byte(),
		SI :: byte(),
		SLS :: byte(),
		Data :: binary(),
		State :: term(),
		Result :: {ok, Active, NewState} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		NewState :: term(),
		Reason :: term().
-callback send(From, Ref, Stream, RC, OPC, DPC, NI, SI, SLS, Data, State) -> Result
	when
		From :: pid(),
		Ref :: reference(),
		Stream :: pos_integer(),
		RC :: 0..4294967295 | undefined,
		OPC :: 0..16777215,
		DPC :: 0..16777215,
		NI :: byte(),
		SI :: byte(),
		SLS :: byte(),
		Data :: binary(),
		State :: term(),
		Result :: {ok, Active, NewState} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		NewState :: term(),
		Reason :: term().
-callback pause(Stream, RCs, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		RCs :: [RC],
		RC :: 0..4294967295,
		DPCs :: [DPC],
		DPC :: 0..16777215,
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback resume(Stream, RCs, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		RCs :: [RC],
		RC :: 0..4294967295,
		DPCs :: [DPC],
		DPC :: 0..16777215,
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback status(Stream, RCs, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		RCs :: [RC],
		RC :: 0..4294967295,
		DPCs :: [DPC],
		DPC :: 0..16777215,
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback register(RC, NA, Keys, TMT, State) -> Result
	when
		RC :: 0..4294967295,
		NA :: 0..4294967295 | undefined,
		Keys :: [m3ua:key()],
		TMT :: m3ua:tmt(),
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
-callback notify(RCs, Status, AspID, State) -> Result
	when
		RCs :: [RC] | undefined,
		RC :: 0..4294967295,
		Status :: as_inactive | as_active | as_pending
				| insufficient_asp_active | alternate_asp_active | asp_failure,
		AspID :: 0..4294967295,
		State :: term(),
		Result :: {ok, State}.
-callback info(Info, State) -> Result
	when
		Info :: term(),
		State :: term(),
		Result :: {ok, Active, NewState} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		NewState :: term(),
		Reason :: term().
-callback terminate(Reason, State) -> Result
	when
		Reason :: term(),
		State :: term(),
		Result :: any().

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
init([Socket, Address, Port,
		#sctp_assoc_change{assoc_id = Assoc,
		inbound_streams = InStreams, outbound_streams = OutStreams},
		EP, EpName, Cb, Static, UseRC, CbOpts]) ->
	process_flag(trap_exit, true),
	CbArgs = [?MODULE, self(), EP, EpName, Assoc, CbOpts],
	case m3ua_callback:cb(init, Cb, CbArgs) of
		{ok, Active, CbState} ->
			case inet:setopts(Socket, [{active, Active}]) of
				ok ->
					Statedata = #statedata{socket = Socket, active = Active,
							assoc = Assoc, peer_addr = Address, peer_port = Port,
							in_streams = InStreams, out_streams = OutStreams,
							ep = EP, ep_name = EpName,
							callback = Cb, cb_opts = CbOpts, cb_state = CbState,
							static = Static, use_rc = UseRC},
					{ok, down, Statedata, 0};
				{error, Reason} ->
					{stop, Reason}
			end;
		{ok, Active, CbState, RKs} when is_list(RKs) ->
			StateData = #statedata{socket = Socket, active = Active,
					assoc = Assoc, peer_addr = Address, peer_port = Port,
					in_streams = InStreams, out_streams = OutStreams,
					callback = Cb, cb_opts = CbOpts, cb_state = CbState,
					ep = EP, ep_name = EpName,
					static = Static, use_rc = UseRC},
			init1(RKs, StateData, []);
		{error, Reason} ->
			gen_sctp:close(Socket),
			{stop, Reason}
	end.
%% @hidden
init1([{RC, RK, Name} | T], StateData, Acc) ->
	case reg_tables(RC, RK, Name, down) of
		{ok, RC} ->
			init1(T, StateData, [{RC, RK, inactive} | Acc]);
		{stop, Reason} ->
			{stop, Reason}
	end;
init1([], #statedata{socket = Socket, active = Active} = StateData, Acc) ->
	case inet:setopts(Socket, [{active, Active}]) of
		ok ->
			NewStateData = StateData#statedata{rks = lists:reverse(Acc)},
			{ok, down, NewStateData, 0};
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
down(timeout, #statedata{ep = EP, assoc = Assoc,
		callback = CbMod, cb_state = CbState} = StateData) ->
	gen_server:cast(m3ua, {'M-SCTP_ESTABLISH', indication, self(), EP, Assoc}),
	{ok, NewCbState} = m3ua_callback:cb(asp_down, CbMod, [CbState]),
	{next_state, down, StateData#statedata{cb_state = NewCbState}}.

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
inactive({'M-RK_REG', request, _, _, _, _, _, _, _} = Event, StateData) ->
	handle_reg(Event, inactive, StateData);
inactive({'MTP-TRANSFER', request, _Ref, _From, _Params}, StateData) ->
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
active({'M-RK_REG', request, _, _, _, _, _, _, _} = Event, StateData) ->
	handle_reg(Event, active, StateData);
active({'MTP-TRANSFER', request, Ref, From,
		{Stream, RC, OPC, DPC, NI, SI, SLS, Data}},
		#statedata{socket = Socket, assoc = Assoc, ep = EP,
		rks = RKs, use_rc = UseRC, callback = CbMod, cb_state = CbState,
		count = Count} = StateData) ->
	ProtocolData = #protocol_data{opc = OPC, dpc = DPC,
			ni = NI, si = SI, sls = SLS, data = Data},
	P0 = m3ua_codec:add_parameter(?ProtocolData, ProtocolData, []),
	P1 = case UseRC of
		true when is_integer(RC) ->
			m3ua_codec:add_parameter(?RoutingContext, [RC], P0);
		true ->
			RC1 = get_rc(DPC, OPC, SI, RKs),
			m3ua_codec:add_parameter(?RoutingContext, [RC1], P0);
		false ->
			P0
	end,
	TransferMsg = #m3ua{class = ?TransferMessage,
			type = ?TransferMessageData, params = P1},
	Packet = m3ua_codec:m3ua(TransferMsg),
	case gen_sctp:send(Socket, Assoc, Stream, Packet) of
		ok ->
			CbArgs = [From, Ref, Stream,
					RC, OPC, DPC, NI, SI, SLS, Data, CbState],
			case m3ua_callback:cb(send, CbMod, CbArgs) of
				{ok, Active, NewCbState} ->
					NewStateData = StateData#statedata{cb_state = NewCbState},
					case inet:setopts(Socket, [{active, Active}]) of
						ok ->
							TransferOut = maps:get(transfer_out, Count, 0),
							NewCount = maps:put(transfer_out, TransferOut + 1, Count),
							NextStateData = NewStateData#statedata{count = NewCount},
							{next_state, active, NextStateData};
						{error, Reason} ->
							{stop, {shutdown, {{EP, Assoc}, Reason}}, NewStateData}
					end;
				{error, Reason} ->
					{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
			end;
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end.

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
active({'MTP-TRANSFER', request, {Stream, RC, OPC, DPC, NI, SI, SLS, Data}},
		{From, Ref}, #statedata{socket = Socket, assoc = Assoc, ep = EP,
		rks = RKs, use_rc = UseRC, callback = CbMod, cb_state = CbState,
		count = Count} = StateData) ->
	ProtocolData = #protocol_data{opc = OPC, dpc = DPC,
			ni = NI, si = SI, sls = SLS, data = Data},
	P0 = m3ua_codec:add_parameter(?ProtocolData, ProtocolData, []),
	P1 = case UseRC of
		true when is_integer(RC) ->
			m3ua_codec:add_parameter(?RoutingContext, [RC], P0);
		true ->
			RC1 = get_rc(DPC, OPC, SI, RKs),
			m3ua_codec:add_parameter(?RoutingContext, [RC1], P0);
		false ->
			P0
	end,
	TransferMsg = #m3ua{class = ?TransferMessage,
			type = ?TransferMessageData, params = P1},
	Packet = m3ua_codec:m3ua(TransferMsg),
	case gen_sctp:send(Socket, Assoc, Stream, Packet) of
		ok ->
			CbArgs = [From, Ref, Stream,
					RC, OPC, DPC, NI, SI, SLS, Data, CbState],
			case m3ua_callback:cb(send, CbMod, CbArgs) of
				{ok, Active, NewCbState} ->
					NewStateData = StateData#statedata{cb_state = NewCbState},
					case inet:setopts(Socket, [{active, Active}]) of
						ok ->
							TransferOut = maps:get(transfer_out, Count, 0),
							NewCount = maps:put(transfer_out, TransferOut + 1, Count),
							NextStateData = NewStateData#statedata{count = NewCount},
							{reply, ok, active, NextStateData};
						{error, Reason} ->
							{stop, {shutdown, {{EP, Assoc}, Reason}}, NewStateData}
					end;
				{error, Reason} ->
					{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
			end;
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
handle_event({'M-SCTP_RELEASE', request, Ref, From}, _StateName,
		#statedata{ep = EP, assoc = Assoc, socket = Socket} = StateData) ->
	gen_server:cast(From,
			{'M-SCTP_RELEASE', confirm, Ref, gen_sctp:close(Socket)}),
	NewStateData = StateData#statedata{socket = undefined},
	{stop, {shutdown, {{EP, Assoc}, shutdown}}, NewStateData};
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
handle_event({'M-NOTIFY', AsState, _RC}, StateName,
		#statedata{socket = Socket, active = Active, ep = EP,
		assoc = Assoc, count = Count} = StateData) ->
	Params = m3ua_codec:store_parameter(?Status, AsState, []),
	Notify = #m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params},
	Packet = m3ua_codec:m3ua(Notify),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			inet:setopts(Socket, [{active, Active}]),
			NotifyIn = maps:get(notify_out, Count, 0),
			NewCount = maps:put(notify_out, NotifyIn + 1, Count),
			NewStateData = StateData#statedata{count = NewCount},
			{next_state, StateName, NewStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_event({'M-ASP_STATUS', request, Ref, From}, StateName, StateData) ->
	gen_server:cast(From, {'M-ASP_STATUS', confirm, Ref, StateName}),
	{next_state, StateName, StateData}.

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
		#statedata{assoc = Assoc} = StateData) ->
	{reply, Assoc, StateName, StateData};
handle_sync_event({getstat, undefined}, _From, StateName,
		#statedata{socket = Socket} = StateData) ->
	{reply, inet:getstat(Socket), StateName, StateData};
handle_sync_event({getstat, Options}, _From, StateName,
		#statedata{socket = Socket} = StateData) ->
	{reply, inet:getstat(Socket, Options), StateName, StateData};
handle_sync_event(getcount, _From, StateName,
		#statedata{count = Counters} = StateData) ->
	{reply, Counters, StateName, StateData}.

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
		{[], #sctp_assoc_change{state = comm_lost, assoc_id = Assoc}}}, _,
		#statedata{socket = Socket, ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, comm_lost}}, StateData};
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_assoc_change{state = restart, assoc_id = Assoc}}},
		StateName, #statedata{socket = Socket, active = Active,
		assoc = Assoc} = StateData) ->
	inet:setopts(Socket, [{active, Active}]),
	{next_state, StateName, StateData};
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_adaptation_event{adaptation_ind = UAL, assoc_id = Assoc}}},
		StateName, #statedata{socket = Socket, active = Active,
		assoc = Assoc} = StateData) ->
	inet:setopts(Socket, [{active, Active}]),
	{next_state, StateName, StateData#statedata{ual = UAL}};
% @todo Track peer address states.
handle_info({sctp, Socket, _, _,
		{[], #sctp_paddr_change{addr = {PeerAddr, PeerPort},
		state = addr_confirmed, assoc_id = Assoc}}}, StateName,
		#statedata{socket = Socket, active = Active,
		assoc = Assoc} = StateData) ->
	inet:setopts(Socket, [{active, Active}]),
	NewStateData = StateData#statedata{peer_addr = PeerAddr,
			peer_port = PeerPort},
	{next_state, StateName, NewStateData};
handle_info({sctp, Socket, _, _,
		{[], #sctp_paddr_change{state = addr_unreachable}}}, _StateName,
		#statedata{socket = Socket, ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, addr_unreachable}}, StateData};
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_shutdown_event{assoc_id = Assoc}}}, _StateName,
		#statedata{socket = Socket, ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, shutdown}}, StateData};
handle_info({sctp_error, Socket, PeerAddr, PeerPort,
		{[], #sctp_send_failed{flags = Flags, error = Error,
		info = Info, assoc_id = Assoc, data = Data}}},
		_StateName, #statedata{assoc = Assoc, ep = EP} = StateData) ->
	error_logger:error_report(["SCTP error",
		{error, gen_sctp:error_string(Error)}, {flags, Flags},
		{assoc, Assoc}, {info, Info}, {data, Data}, {socket, Socket},
		{peer, {PeerAddr, PeerPort}}]),
	{stop, {shutdown, {{EP, Assoc}, Error}}, StateData};
handle_info({'EXIT', EP, {shutdown, {EP, Reason}}}, _StateName,
		#statedata{ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData};
handle_info({'EXIT', Socket, Reason}, _StateName,
		#statedata{socket = Socket, ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData};
handle_info(Info, StateName, #statedata{socket = Socket,
		ep = EP, assoc = Assoc, callback = CbMod,
		cb_state = CbState} = StateData) ->
	case m3ua_callback:cb(info, CbMod, [Info, CbState]) of
		{ok, Active, NewCbState} ->
			NewStateData = StateData#statedata{cb_state = NewCbState},
			case inet:setopts(Socket, [{active, Active}]) of
				ok ->
					{next_state, StateName, NewStateData};
				{error, Reason} ->
					{stop, {shutdown, {{EP, Assoc}, Reason}}, NewStateData}
			end;
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end.

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		StateName :: atom(), StateData :: #statedata{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_fsm:terminate/3
%% @private
%%
terminate(Reason, StateName, #statedata{socket = undefined} = StateData) ->
	terminate1(Reason, StateName, StateData);
terminate(Reason, StateName, #statedata{socket = Socket} = StateData) ->
	case gen_sctp:close(Socket) of
		ok ->
			ok;
		{error, Reason1} ->
			error_logger:error_report(["Failed to close socket",
					{module, ?MODULE}, {socket, Socket},
					{error, Reason1}, {state, StateData}])
	end,
	terminate1(Reason, StateName, StateData).
%% @hidden
terminate1(Reason, _StateName, #statedata{rks = RKs} = StateData) ->
	Fsm = self(),
	Fdel = fun F([{RC, _RK, _Active} | T]) ->
				[#m3ua_as{asp = L1} = AS] = mnesia:read(m3ua_as, RC, write),
				L2 = lists:keydelete(Fsm, #m3ua_as_asp.fsm, L1),
				mnesia:write(AS#m3ua_as{asp = L2}),
				mnesia:delete(m3ua_asp, Fsm, write),
				F(T);
			F([]) ->
				ok
	end,
	mnesia:transaction(Fdel, [RKs]),
	terminate2(Reason, StateData).
%% @hidden
terminate2(_, #statedata{callback = undefined}) ->
	ok;
terminate2(Reason, #statedata{callback = CbMod, cb_state = CbState}) ->
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
handle_reg({'M-RK_REG', request, Ref, From, RC, NA, Keys, Mode, AS},
		StateName, #statedata{static = true, rks = RKs,
		assoc = Assoc, ep = EP, callback = CbMod,
		cb_state = CbState} = StateData) when is_integer(RC) ->
	SortedKeys = m3ua:sort(Keys),
	RK = {NA, SortedKeys, Mode},
	case reg_tables(RC, RK, AS, inactive) of
		{ok, RC} ->
			NewRKs = update_rks(RC, RK, inactive, RKs),
			CbArgs = [RC, NA, SortedKeys, Mode, CbState],
			{ok, NewCbState} = m3ua_callback:cb(register, CbMod, CbArgs),
			NewStateData = StateData#statedata{rks = NewRKs,
					cb_state = NewCbState},
			gen_server:cast(From, {'M-RK_REG', confirm, Ref, {ok, RC}}),
			{next_state, StateName, NewStateData};
		{stop, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_reg(_, _, #statedata{ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, bad_routing_context}}, StateData}.

%% @hidden
handle_sgp(M3UA, StateName, Stream, StateData) when is_binary(M3UA) ->
	handle_sgp(m3ua_codec:m3ua(M3UA), StateName, Stream, StateData);
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP, params = Params},
		down, _Stream, #statedata{socket = Socket, active = Active,
		assoc = Assoc, ep = EP, callback = CbMod, cb_state = CbState,
		count = Count} = StateData) ->
	AspUp = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspUp, undefined),
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_up, StateData),
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_up, CbMod, CbArgs),
			inet:setopts(Socket, [{active, Active}]),
			UpIn = maps:get(up_in, Count, 0),
			UpAckOut = maps:get(up_ack_out, Count, 0),
			NewCount = maps:put(up_in, UpIn + 1, Count),
			NextCount = maps:put(up_ack_out, UpAckOut + 1, NewCount),
			NextStateData = NewStateData#statedata{cb_state = NewCbState,
					count = NextCount},
			{next_state, inactive, NextStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP},
		inactive, _Stream, #statedata{socket = Socket, active = Active,
		assoc = Assoc, ep = EP, count = Count} = StateData) ->
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
					inet:setopts(Socket, [{active, Active}]),
					UpIn = maps:get(up_in, Count, 0),
					UpAckOut = maps:get(up_ack_out, Count, 0),
					NewCount = maps:put(up_in, UpIn + 1, Count),
					NextCount = maps:put(up_ack_out, UpAckOut + 1, NewCount),
					NewStateData = StateData#statedata{count = NextCount},
					{next_state, inactive, NewStateData};
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
handle_sgp(#m3ua{class = ?RKMMessage, type = ?RKMREGREQ, params = Params},
		StateName, _Stream, StateData)
		when StateName == inactive; StateName == active ->
	Parameters = m3ua_codec:parameters(Params),
	RKs = m3ua_codec:get_all_parameter(?RoutingKey, Parameters),
	reg_request(RKs, StateName, StateData);
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC, params = Params},
		inactive, _Stream, #statedata{socket = Socket, active = Active,
		assoc = Assoc, ep = EP, callback = CbMod, cb_state = CbState,
		count = Count} = StateData) ->
	AspActive = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspActive, undefined),
	AspActiveAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK},
	Packet = m3ua_codec:m3ua(AspActiveAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_active, StateData),
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_active, CbMod, CbArgs),
			inet:setopts(Socket, [{active, Active}]),
			ActiveIn = maps:get(active_in, Count, 0),
			ActiveAckOut = maps:get(active_ack_out, Count, 0),
			NewCount = maps:put(active_in, ActiveIn + 1, Count),
			NextCount = maps:put(active_ack_out, ActiveAckOut + 1, NewCount),
			NextStateData = NewStateData#statedata{cb_state = NewCbState,
					count = NextCount},
			{next_state, active, NextStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN, params = Params},
		StateName, _Stream, #statedata{socket = Socket, active = Active,
		assoc = Assoc, ep = EP, callback = CbMod, cb_state = CbState,
		count = Count} = StateData)
		when StateName == inactive; StateName == active ->
	AspDown = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspDown, undefined),
	AspDownAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDNACK},
	Packet = m3ua_codec:m3ua(AspDownAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_down, StateData),
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_down, CbMod, CbArgs),
			inet:setopts(Socket, [{active, Active}]),
			DownIn = maps:get(down_in, Count, 0),
			DownAckOut = maps:get(down_ack_out, Count, 0),
			NewCount = maps:put(down_in, DownIn + 1, Count),
			NextCount = maps:put(down_ack_out, DownAckOut + 1, NewCount),
			NextStateData = NewStateData#statedata{cb_state = NewCbState,
					count = NextCount},
			{next_state, down, NextStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA, params = Params},
		active, _Stream, #statedata{socket = Socket, active = Active,
		assoc = Assoc, ep = EP, callback = CbMod, cb_state = CbState,
		count = Count} = StateData) ->
	AspInActive = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspInActive, undefined),
	AspInActiveAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK},
	Packet = m3ua_codec:m3ua(AspInActiveAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_inactive, StateData),
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_inactive, CbMod, CbArgs),
			inet:setopts(Socket, [{active, Active}]),
			InactiveIn = maps:get(inactive_in, Count, 0),
			InactiveAckOut = maps:get(inactive_ack_out, Count, 0),
			NewCount = maps:put(inactive_in, InactiveIn + 1, Count),
			NextCount = maps:put(inactive_ack_out, InactiveAckOut + 1, NewCount),
			NextStateData = NewStateData#statedata{cb_state = NewCbState,
					count = NextCount},
			{next_state, inactive, NextStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?TransferMessage,
		type = ?TransferMessageData, params = Params},
		_ActiveState, Stream, #statedata{socket = Socket,
		ep = EP, assoc = Assoc, callback = CbMod,
		cb_state = CbState, count = Count} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = case m3ua_codec:find_parameter(?RoutingContext, Parameters) of
		{ok, [RC1]} ->
			RC1;
		{error, not_found} ->
			undefined
	end,
	#protocol_data{opc = OPC, dpc = DPC, ni = NI, si = SI, sls = SLS,
			data = Data} = m3ua_codec:fetch_parameter(?ProtocolData, Parameters),
	CbArgs = [Stream, RC, OPC, DPC, NI, SI, SLS, Data, CbState],
	case m3ua_callback:cb(recv, CbMod, CbArgs) of
		{ok, Active, NewCbState} ->
			inet:setopts(Socket, [{active, Active}]),
			TransferIn = maps:get(transfer_in, Count, 0),
			NewCount = maps:put(transfer_in, TransferIn + 1, Count),
			NewStateData = StateData#statedata{active = Active,
					cb_state = NewCbState, count = NewCount},
			{next_state, active, NewStateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMDUNA, params = Params},
		StateName, Stream, #statedata{socket = Socket, active = Active,
		callback = CbMod, cb_state = CbState, count = Count} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, []),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	CbArgs = [Stream, RCs, APCs, CbState],
	{ok, NewCbState} = m3ua_callback:cb(pause, CbMod, CbArgs),
	inet:setopts(Socket, [{active, Active}]),
	DunaIn = maps:get(duna_in, Count, 0),
	NewCount = maps:put(duna_in, DunaIn + 1, Count),
	NewStateData = StateData#statedata{cb_state = NewCbState, count = NewCount},
	{next_state, StateName, NewStateData};
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMDAVA, params = Params},
		StateName, Stream, #statedata{socket = Socket, active = Active,
		callback = CbMod, cb_state = CbState, count = Count} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, []),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	CbArgs = [Stream, RCs, APCs, CbState],
	{ok, NewCbState} = m3ua_callback:cb(resume, CbMod, CbArgs),
	inet:setopts(Socket, [{active, Active}]),
	DavaIn = maps:get(dava_in, Count, 0),
	NewCount = maps:put(dava_in, DavaIn + 1, Count),
	NewStateData = StateData#statedata{cb_state = NewCbState, count = NewCount},
	{next_state, StateName, NewStateData};
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMSCON, params = Params},
		StateName, Stream, #statedata{socket = Socket, active = Active,
		callback = CbMod, cb_state = CbState} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, []),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	CbArgs = [Stream, RCs, APCs, CbState],
	{ok, NewCbState} = m3ua_callback:cb(resume, CbMod, CbArgs),
	NewStateData = StateData#statedata{cb_state = NewCbState},
	inet:setopts(Socket, [{active, Active}]),
	{next_state, StateName, NewStateData};
handle_sgp(#m3ua{class = ?MGMTMessage, type = ?MGMTError, params = Params},
		StateName, _Stream, #statedata{assoc = Assoc, ep = EP,
		socket = Socket, active = Active} = StateData) ->
	Parameters = m3ua_codec:parameters(Params),
	ErrorCode = proplists:get_value(?ErrorCode, Parameters),
	error_logger:error_report(["M3UA protocol error",
			{module, ?MODULE}, {state, StateName}, {endpoint, EP},
			{association, Assoc}, {error, ErrorCode}]),
	inet:setopts(Socket, [{active, Active}]),
	{next_state, StateName, StateData};
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMBEAT, params = Params},
		StateName, _Stream, #statedata{socket = Socket, active = Active,
		assoc = Assoc, ep = EP, count = Count} = StateData) ->
	BeatAck = #m3ua{class = ?ASPSMMessage,
			type = ?ASPSMBEATACK, params = Params},
	Packet = m3ua_codec:m3ua(BeatAck),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			inet:setopts(Socket, [{active, Active}]),
			UpIn = maps:get(beat_in, Count, 0),
			UpAckOut = maps:get(beat_ack_out, Count, 0),
			NewCount = maps:put(beat_in, UpIn + 1, Count),
			NextCount = maps:put(beat_ack_out, UpAckOut + 1, NewCount),
			NewStateData = StateData#statedata{count = NextCount},
			{next_state, StateName, NewStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end.

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

%% @private
reg_request(RoutingKeys, StateName, StateData) ->
	reg_request(RoutingKeys, StateName, StateData, [], []).
%% @hidden
reg_request([H | T], StateName, #statedata{socket = Socket,
		active = Active, ep = EP, assoc = Assoc, rks = RKs,
		callback = CbMod, cb_state = CbState,
		count = Count} = StateData, RegResults, Notifies) ->
	try m3ua_codec:routing_key(H)
	of
		#m3ua_routing_key{rc = RC, na = NA,
				key = Keys, tmt = Mode, lrk_id = LrkId} ->
			SortedKeys = m3ua:sort(Keys),
			RK = {NA, SortedKeys, Mode},
			F = fun() -> reg_request1(RC, RK, LrkId) end,
			case mnesia:transaction(F) of
				{atomic, {reg, AsState, #registration_result{rc = NewRC} = RR}} ->
					NewRKs = update_rks(NewRC, RK, AsState, RKs),
					CbArgs = [NewRC, NA, SortedKeys, Mode, CbState],
					{ok, NewCbState} = m3ua_callback:cb(register, CbMod, CbArgs),
					NewStateData = StateData#statedata{rks = NewRKs,
							cb_state = NewCbState},
					RegResult = {?RegistrationResult, RR},
					reg_request(T, StateName, NewStateData, [RegResult | RegResults], Notifies);
				{atomic, {reg, AsState, #registration_result{rc = NewRC} = RR, Notify}} ->
					NewRKs = update_rks(NewRC, RK, AsState, RKs),
					CbArgs = [NewRC, NA, SortedKeys, Mode, CbState],
					{ok, NewCbState} = m3ua_callback:cb(register, CbMod, CbArgs),
					NewStateData = StateData#statedata{rks = NewRKs,
							cb_state = NewCbState},
					RegResult = {?RegistrationResult, RR},
					reg_request(T, StateName, NewStateData, [RegResult | RegResults], [Notify | Notifies]);
				{atomic, {not_reg, AsState, #registration_result{rc = NewRC} = RR}} ->
					NewRKs = update_rks(NewRC, RK, AsState, RKs),
					NewStateData = StateData#statedata{rks = NewRKs},
					RegResult = {?RegistrationResult, RR},
					reg_request(T, StateName, NewStateData, [RegResult | RegResults], Notifies);
				{atomic, {not_reg, #registration_result{} = RR}} ->
					RegResult = {?RegistrationResult, RR},
					reg_request(T, StateName, StateData, [RegResult | RegResults], Notifies);
				{aborted, _Reason} ->
					RegResult = {?RegistrationResult, #registration_result{lrk_id = LrkId,
							status = rk_change_refused, rc = RC}},
					reg_request(T, StateName, StateData, [RegResult | RegResults], Notifies)
			end
	catch
		_:_Reason ->
			P0 = m3ua_codec:add_parameter(?ErrorCode, unexpected_parameter, []),
			ErrorParams = m3ua_codec:parameters(P0),
			ErrorMsg = #m3ua{class = ?MGMTMessage, type = ?MGMTError, params = ErrorParams},
			Packet = m3ua_codec:m3ua(ErrorMsg),
			case gen_sctp:send(Socket, Assoc, 0, Packet) of
				ok ->
					ErrorOut = maps:get(error_out, Count, 0),
					NewCount = maps:put(eror_out, ErrorOut + 1, Count),
					NewStateData = StateData#statedata{count = NewCount},
					inet:setopts(Socket, [{active, Active}]),
					{next_state, StateName, NewStateData};
				{error, eagain} ->
					% @todo flow control
					{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
				{error, Reason} ->
					{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
			end
	end;
reg_request([], StateName, #statedata{socket = Socket,
		ep = EP, assoc = Assoc} = StateData, RegResults, Notifies) ->
	RegResMsg = #m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = lists:reverse(RegResults)},
	RegResPacket = m3ua_codec:m3ua(RegResMsg),
	case gen_sctp:send(Socket, Assoc, 0, RegResPacket) of
		ok ->
			send_notify(Notifies, StateName, StateData);
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end.
%% @hidden
reg_request1(RC, RK, LrkId) when is_integer(RC) ->
	SGP = self(),
	case mnesia:read(m3ua_as, RC, write) of
		[] ->
			RegRes = #registration_result{lrk_id = LrkId,
					status = rk_change_refused, rc = RC},
			{not_reg, RegRes};
		[#m3ua_as{rk = RK, state = AsState, asp = SGPs} = AS] ->
			case lists:keymember(SGP, #m3ua_as_asp.fsm, SGPs) of
				true ->
					RegRes = #registration_result{lrk_id = LrkId,
							status = rk_already_registered, rc = RC},
					{not_reg, AsState, RegRes};
				false ->
					NewSGPs = [#m3ua_as_asp{fsm = SGP, state = inactive} | SGPs],
					mnesia:write(AS#m3ua_as{asp = NewSGPs}),
					mnesia:write(#m3ua_asp{fsm = SGP, rc = RC, rk = RK}),
					RegRes = #registration_result{lrk_id = LrkId,
							status = registered, rc = RC},
					{reg, AsState, RegRes}
			end;
		[#m3ua_as{state = AsState, asp = SGPs} = AS] ->
			case lists:keymember(SGP, #m3ua_as_asp.fsm, SGPs) of
				true ->
					mnesia:write(AS#m3ua_as{rk = RK}),
					RegRes = #registration_result{lrk_id = LrkId,
							status = registered, rc = RC},
					{reg, AsState, RegRes};
				false ->
					NewSGPs = [#m3ua_as_asp{fsm = SGP, state = inactive} | SGPs],
					mnesia:write(AS#m3ua_as{rk = RK, asp = NewSGPs}),
					mnesia:write(#m3ua_asp{fsm = SGP, rc = RC, rk = RK}),
					RegRes = #registration_result{lrk_id = LrkId,
							status = registered, rc = RC},
					{reg, AsState, RegRes}
			end
	end;
reg_request1(undefined, RK, LrkId) ->
	SGP = self(),
	case mnesia:index_read(m3ua_as, RK, #m3ua_as.rk) of
		[] ->
			RC = rand:uniform(16#FFFFFFFF), % @todo better RC assignment
			ASASP = #m3ua_as_asp{fsm = SGP, state = inactive},
			AS = #m3ua_as{rc = RC, rk = RK, state = inactive, asp = [ASASP]},
			mnesia:write(AS),
			ASP = #m3ua_asp{fsm = SGP, rc = RC, rk = RK},
			mnesia:write(ASP),
			RegRes = #registration_result{lrk_id = LrkId,
					status = registered, rc = RC},
			{reg, inactive, RegRes, {as_inactive, RC}};
		[#m3ua_as{rc = RC, state = AsState, asp = SGPs} = AS] ->
			case lists:keymember(SGP, #m3ua_as_asp.fsm, SGPs) of
				true ->
					RegRes = #registration_result{lrk_id = LrkId,
							status = rk_already_registered, rc = RC},
					{not_reg, AsState, RegRes};
				false ->
					NewSGPs = [#m3ua_as_asp{fsm = SGP, state = inactive} | SGPs],
					NewAS = case AsState of
						active ->
							AS#m3ua_as{asp = NewSGPs};
						_ ->
							AS#m3ua_as{asp = NewSGPs, state = inactive}
					end,
					mnesia:write(NewAS),
					mnesia:write(#m3ua_asp{fsm = SGP, rc = RC, rk = RK}),
					RegRes = #registration_result{lrk_id = LrkId,
							status = registered, rc = RC},
					{reg, NewAS#m3ua_as.state, RegRes}
			end
	end.

%% @hidden
send_notify([{Status, RC} | T] = _Notifies, StateName,
		#statedata{socket = Socket, ep = EP, assoc = Assoc,
		callback = CbMod, cb_state = CbState, count = Count} = StateData) ->
	P0 = m3ua_codec:add_parameter(?Status, Status, []),
	P1 = m3ua_codec:add_parameter(?RoutingContext, [RC], P0),
	Message = #m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = P1},
	Packet = m3ua_codec:m3ua(Message),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			CbArgs = [RC, Status, undefined, CbState],
			{ok, NewCbState} = m3ua_callback:cb(notify, CbMod, CbArgs),
			NotifyOut = maps:get(notify_out, Count, 0),
			NewCount = maps:put(notify_out, NotifyOut + 1, Count),
			NewStateData = StateData#statedata{cb_state = NewCbState, count = NewCount},
			send_notify(T, StateName, NewStateData);
	{error, eagain} ->
		% @todo flow control
		{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
	{error, Reason} ->
		{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
send_notify([], StateName,
		#statedata{socket = Socket, active = Active} = StateData) ->
	inet:setopts(Socket, [{active, Active}]),
	{next_state, StateName, StateData}.

-spec get_rc(DPC, OPC, SI, RKs) -> RC
	when
		DPC :: 0..16777215,
		OPC :: 0..16777215,
		SI :: byte(),
		RKs :: [{RC, RK, Active}],
		RC :: 0..4294967295,
		RK :: {NA, Keys, TMT},
		NA :: 0..4294967295,
		Keys :: [{DPC, [SI], [OPC]}],
		TMT :: m3ua:tmt(),
		Active :: boolean().
%% @doc Find routing context matching destination.
%% @hidden
get_rc(DPC, OPC, SI, [{RC, RK, _} | T] = _RoutingKeys)
		when is_integer(DPC), is_integer(OPC), is_integer(SI) ->
	case m3ua:keymember(DPC, OPC, SI, [RK]) of
		true ->
			RC;
		false ->
			get_rc(DPC, OPC, SI, T)
	end.

%% @hidden
reg_tables(RC, RK, Name, AspState) ->
	Fsm = self(),
	F = fun() ->
			case mnesia:read(m3ua_as, RC, write) of
				[] ->
					ASPs = [#m3ua_as_asp{fsm = Fsm, state = AspState}],
					AS = #m3ua_as{rc = RC, rk = RK, name = Name, asp = ASPs},
					mnesia:write(AS),
					ASP = #m3ua_asp{fsm = Fsm, rc = RC, rk = RK},
					mnesia:write(ASP);
				[#m3ua_as{asp = ASPs} = AS] ->
					NewASPs = case lists:keymember(Fsm, #m3ua_as_asp.fsm, ASPs) of
						true ->
							ASPs;
						false ->
							[#m3ua_as_asp{fsm = Fsm, state = AspState} | ASPs]
					end,
					NewAS = AS#m3ua_as{rk = RK, name = Name, asp = NewASPs},
					mnesia:write(NewAS),
					ASP = #m3ua_asp{fsm = Fsm, rc = RC, rk = RK},
					mnesia:write(ASP)
			end
	end,
	case mnesia:transaction(F) of
		{atomic, ok} ->
			{ok, RC};
		{aborted, Reason} ->
			{stop, Reason}
	end.

%% @hidden
update_rks(RC, RK, Active, RKs) ->
	case lists:keytake(RC, 1, RKs) of
		{value, {RC, _OldKeys, Active}, RKs1} ->
			[{RC, RK, Active} | RKs1];
		false ->
			[{RC, RK, inactive} | RKs]
	end.

%% @hidden
state_traffic_maint(undefined, Event, #statedata{rks = RKs} = StateData) ->
	RCs = [RC || {RC, _, _} <- RKs],
	state_traffic_maint1(RCs, Event, StateData);
state_traffic_maint(RCs, Event, StateData) ->
	state_traffic_maint1(RCs, Event, StateData).
%% @hidden
state_traffic_maint1([RC | T], Event,
		#statedata{ep = EP, assoc = Assoc} = StateData) ->
	F = fun() -> state_traffic_maint2(RC, Event) end,
	case mnesia:transaction(F) of
		{atomic, NotifyFsms} ->
			F3 = fun({Fsm, pending}) ->
						ok = gen_fsm:send_all_state_event(Fsm, {'M-NOTIFY', as_pending, RC});
					({Fsm, inactive}) ->
						ok = gen_fsm:send_all_state_event(Fsm, {'M-NOTIFY', as_inactive, RC});
					({Fsm, active}) ->
						ok = gen_fsm:send_all_state_event(Fsm, {'M-NOTIFY', as_active, RC});
					({Fsm, down}) ->
						ok = gen_fsm:send_all_state_event(Fsm, {'M-NOTIFY', as_inactive, RC})
			end,
			ok = lists:foreach(F3, NotifyFsms),
			state_traffic_maint1(T, Event, StateData);
		{aborted, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
state_traffic_maint1([], _Event, StateData) ->
	StateData.
%% @hidden
state_traffic_maint2(RC, Event) ->
	Fcount = fun(#m3ua_as_asp{state = active}, {NA, NIA}) ->
				{NA + 1, NIA};
			(#m3ua_as_asp{state = inactive}, {NA, NIA}) ->
				{NA, NIA + 1};
			(_, Acc) ->
				Acc
	end,
	Fdown = fun(#m3ua_as_asp{fsm = Fsm}, Acc) ->
				[{Fsm, down} | Acc]
	end,
	Finactive = fun(#m3ua_as_asp{fsm = Fsm}, Acc) ->
				[{Fsm, inactive} | Acc]
	end,
	Factive = fun(#m3ua_as_asp{fsm = Fsm}, Acc) ->
				[{Fsm, active} | Acc]
	end,
	case mnesia:read(m3ua_as, RC, write) of
		[] ->
			[];
		[#m3ua_as{asp = Asps, state = AsState, min_asp = Min} = AS] ->
			case lists:keytake(self(), #m3ua_as_asp.fsm, Asps) of
				{value, Asp, RemAsp} ->
					AspState = case Event of
						asp_down ->
							down;
						asp_up ->
							inactive;
						asp_inactive ->
							inactive;
						asp_active ->
							active
					end,
					NewAsp = Asp#m3ua_as_asp{state = AspState},
					NewAsps = [NewAsp | RemAsp],
					case lists:foldl(Fcount, {0, 0}, NewAsps) of
						{0, 0} when AsState == down ->
							NewAS = AS#m3ua_as{state = down, asp = NewAsps},
							mnesia:write(NewAS),
							[];
						{0, 0} ->
							% @todo pending state with recovery timer T(r)
							NewAS = AS#m3ua_as{state = down, asp = NewAsps},
							mnesia:write(NewAS),
							lists:foldl(Fdown, [], NewAsps);
						{0, NumInactive} when NumInactive > 0, AsState == inactive ->
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							mnesia:write(NewAS),
							[];
						{0, NumInactive} when NumInactive > 0 ->
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							mnesia:write(NewAS),
							lists:foldl(Finactive, [], NewAsps);
						{NumActive, NumInactive} when AsState == inactive,
								NumActive < Min, NumInactive > 0 ->
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							mnesia:write(NewAS),
							[];
						{NumActive, _NumInactive}
								when AsState == inactive, NumActive >= Min ->
							NewAS = AS#m3ua_as{state = active, asp = NewAsps},
							mnesia:write(NewAS),
							lists:foldl(Factive, [], NewAsps);
						{_NumActive, _NumInactive} ->
							NewAS = AS#m3ua_as{asp = NewAsps},
							mnesia:write(NewAS),
							[]
					end;
				false ->
					[]
			end
	end.

