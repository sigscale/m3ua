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
%%% 	the MTP user through calls to the corresponding callback functions
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
%%%    <li><tt>Assoc = gen_sctp:assoc_id()</tt></li>
%%%    <li><tt>Result = {ok, State} | {error, Reason} </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>Initialize ASP callback handler.</p>
%%%  <p>Called when ASP is started.</p>
%%%
%%%  <h3 class="function"><a name="transfer-9">transfer/9</a></h3>
%%%  <div class="spec">
%%%  <p><tt>transfer(Stream, RC, OPC, DPC, NI, SI, SLS,
%%%        Data, State) -&gt; Result</tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer() </tt></li>
%%%    <li><tt>RC = 0..4294967295 | undefined</tt></li>
%%%    <li><tt>OPC = 0..16777215</tt></li>
%%%    <li><tt>DPC = 0..16777215</tt></li>
%%%    <li><tt>NI = byte() </tt></li>
%%%    <li><tt>SI = byte() </tt></li>
%%%    <li><tt>SLS = byte() </tt></li>
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
%%%  <p><tt>pause(Stream, RCs, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RCs = [RC]</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = 16777215</tt></li>
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
%%%  <p><tt>resume(Stream, RCs, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RCs = [RC]</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>DPC = 16777215</tt></li>
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
%%%  <p><tt>status(Stream, RCs, DPCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RCs = [RC]</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>DPCs = [DPC]</tt></li>
%%%    <li><tt>DPC = 16777215</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>Called when congestion occurs for an SS7 destination
%%% 	or to indicate an unavailable remote user part.</p>
%%%
%%%  <h3 class="function"><a name="register-5">register/5</a></h3>
%%%  <div class="spec">
%%%  <p><tt>register(RC, NA, Keys, TMT, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>NA = 0..4294967295</tt></li>
%%%    <li><tt>Keys = [key()]</tt></li>
%%%    <li><tt>TMT = tmt()</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div><p>Called when Registration response from peer is success,
%%% 	or local static registration is complete.</p>
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
%%%  <p><tt>notify(RCs, Status, AspID, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>RCs = [RC]</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
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
		static = false :: boolean(),
		use_rc = true :: boolean(),
		rks = [] :: [{RC :: 0..4294967295,
				RK :: routing_key(), Active :: boolean()}],
		ual :: undefined | integer(),
		req :: undefined | tuple(),
		ep :: pid(),
		ep_name :: term(),
		callback :: atom() | #m3ua_fsm_cb{},
		cb_state :: term(),
		count = #{} :: #{atom() => non_neg_integer()}}).

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
		Assoc :: gen_sctp:assoc_id(),
		Result :: {ok, State} | {error, Reason},
		State :: term(),
		Reason :: term().
-callback transfer(Stream, RC, OPC, DPC, NI, SI, SLS, Data, State) -> Result
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
		Result :: {ok, NewState} | {error, Reason},
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
		DPCs :: [DPC],
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback register(RC, NA, Keys, TMT, State) -> Result
	when
		RC :: 0..4294967295,
		NA :: 0..4294967295 | undefined,
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
-callback notify(RCs, Status, AspID, State) -> Result
	when
		RCs :: [RC],
		RC :: 0..4294967295,
		Status :: as_inactive | as_active | as_pending
				| insufficient_asp_active | alternate_asp_active | asp_failure,
		AspID :: 0..4294967295,
		State :: term(),
		Result :: {ok, State}.
-callback terminate(Reason, State) -> Result
	when
		Reason :: term(),
		State :: term(),
		Result :: any().

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
		EP, EpName, Cb, Static, UseRC]) ->
	process_flag(trap_exit, true),
	CbArgs = [?MODULE, self(), EP, EpName, Assoc],
	case m3ua_callback:cb(init, Cb, CbArgs) of
		{ok, CbState} ->
			Statedata = #statedata{socket = Socket, assoc = Assoc,
					peer_addr = Address, peer_port = Port,
					in_streams = InStreams, out_streams = OutStreams,
					ep = EP, ep_name = EpName,
					callback = Cb, cb_state = CbState,
					static = Static, use_rc = UseRC},
			{ok, down, Statedata, 0};
		{error, Reason} ->
			gen_sctp:close(Socket),
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
down(timeout, #statedata{req = {'M-ASP_UP', Ref, From}} = StateData) ->
	gen_server:cast(From, {'M-ASP_UP', confirm, Ref, {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
down(timeout, #statedata{ep = EP, assoc = Assoc,
		callback = CbMod, cb_state = CbState} = StateData) ->
	gen_server:cast(m3ua, {'M-SCTP_ESTABLISH', indication, self(), EP, Assoc}),
	{ok, NewCbState} = m3ua_callback:cb(asp_down, CbMod, [CbState]),
	{next_state, down, StateData#statedata{cb_state = NewCbState}};
down({'M-ASP_UP', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP, count = Count} = StateData) ->
	AspUp = #m3ua{class = ?ASPSMMessage,
			type = ?ASPSMASPUP, params = <<>>},
	Packet = m3ua_codec:m3ua(AspUp),
	case gen_sctp:send(Socket, Assoc, 0, Packet) of
		ok ->
			Req = {'M-ASP_UP', Ref, From},
			UpOut = maps:get(up_out, Count, 0),
			NewCount = maps:put(up_out, UpOut + 1, Count),
			NewStateData = StateData#statedata{req = Req, count = NewCount},
			{next_state, down, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
down({AspOp, request, Ref, From},
		#statedata{req = Req} = StateData) when Req /= undefined ->
	gen_server:cast(From, {AspOp, confirm, Ref, {error, asp_busy}}),
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
inactive(timeout, #statedata{req = {'M-RK_REG', Ref, From, _RK}} = StateData) ->
	gen_server:cast(From, {'M-RK_REG', confirm, Ref, {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, inactive, NewStateData};
inactive(timeout, #statedata{req = {AspOp, Ref, From}} = StateData)
		when AspOp == 'M-ASP_ACTIVE'; AspOp == 'M-ASP_DOWN' ->
	gen_server:cast(From, {AspOp, confirm, Ref, {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
inactive({'M-RK_REG', request, _, _, _, _, _, _, _} = Event,
		#statedata{req = undefined} = StateData) ->
	handle_reg(Event, inactive, StateData);
inactive({'M-ASP_ACTIVE', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP, count = Count} = StateData) ->
	AspActive = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC},
	Message = m3ua_codec:m3ua(AspActive),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-ASP_ACTIVE', Ref, From},
			ActiveOut = maps:get(active_out, Count, 0),
			NewCount = maps:put(active_out, ActiveOut + 1, Count),
			NewStateData = StateData#statedata{req = Req, count = NewCount},
			{next_state, inactive, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
inactive({'M-ASP_DOWN', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP, count = Count} = StateData) ->
	AspDown = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN},
	Message = m3ua_codec:m3ua(AspDown),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-ASP_DOWN', Ref, From},
			DownOut = maps:get(down_out, Count, 0),
			NewCount = maps:put(down_out, DownOut + 1, Count),
			NewStateData = StateData#statedata{req = Req, count = NewCount},
			{next_state, inactive, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
inactive({AspOp, request, Ref, From},
		#statedata{req = Req} = StateData) when Req /= undefined ->
	gen_server:cast(From, {AspOp, confirm, Ref, {error, asp_busy}}),
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
active(timeout, #statedata{req = {'M-RK_REG', Ref, From, _RK}} = StateData) ->
	gen_server:cast(From, {'M-RK_REG', confirm, Ref, {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, active, NewStateData};
active(timeout, #statedata{req = {AspOp, Ref, From}} = StateData)
		when AspOp == 'M-ASP_INACTIVE'; AspOp == 'M-ASP_DOWN' ->
	gen_server:cast(From, {AspOp, Ref, self(), {error, timeout}}),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, down, NewStateData};
active({'M-ASP_INACTIVE', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP, count = Count} = StateData) ->
	AspInActive = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA},
	Message = m3ua_codec:m3ua(AspInActive),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-ASP_INACTIVE', Ref, From},
			InactiveOut = maps:get(inactive_out, Count, 0),
			NewCount = maps:put(inactive_out, InactiveOut + 1, Count),
			NewStateData = StateData#statedata{req = Req, count = NewCount},
			{next_state, active, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
active({'M-ASP_DOWN', request, Ref, From},
		#statedata{req = undefined, socket = Socket,
		assoc = Assoc, ep = EP, count = Count} = StateData) ->
	AspDown = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN},
	Message = m3ua_codec:m3ua(AspDown),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-ASP_DOWN', Ref, From},
			DownOut = maps:get(down_out, Count, 0),
			NewCount = maps:put(down_out, DownOut + 1, Count),
			NewStateData = StateData#statedata{req = Req, count = NewCount},
			{next_state, active, NewStateData, ?Tack};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
active({'M-RK_REG', request, _, _, _, _, _, _, _} = Event,
		#statedata{req = undefined} = StateData) ->
	handle_reg(Event, active, StateData);
active({AspOp, request, Ref, From},
		#statedata{req = Req} = StateData) when Req /= undefined ->
	gen_server:cast(From, {AspOp, confirm, Ref, {error, asp_busy}}),
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
active({'MTP-TRANSFER', request, {Stream, RC, OPC, DPC, NI, SI, SLS, Data}},
		_From, #statedata{socket = Socket, assoc = Assoc, count = Count,
		ep = EP, rks = RKs, use_rc = UseRC} = StateData) ->
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
			TransferOut = maps:get(transfer_out, Count, 0),
			NewCount = maps:put(transfer_out, TransferOut + 1, Count),
			NewStateData = StateData#statedata{count = NewCount},
			{reply, ok, active, NewStateData};
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
handle_event({'M-ASP_STATUS', request, Ref, From}, StateName, StateData) ->
	gen_server:cast(From, {'M-ASP_STATUS', confirm, Ref, StateName}),
	{next_state, StateName, StateData}.

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
		{[#sctp_sndrcvinfo{stream = Stream}], Data}},
		StateName, #statedata{socket = Socket} = StateData)
		when is_binary(Data) ->
	handle_asp(Data, StateName, Stream, StateData);
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_assoc_change{state = comm_lost, assoc_id = Assoc}}}, _,
		#statedata{socket = Socket, ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, comm_lost}}, StateData};
handle_info({sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_adaptation_event{adaptation_ind = UAL, assoc_id = Assoc}}},
		StateName, #statedata{socket = Socket, assoc = Assoc} = StateData) ->
	inet:setopts(Socket, [{active, once}]),
	{next_state, StateName, StateData#statedata{ual = UAL}};
% @todo Track peer address states.
handle_info({sctp, Socket, _, _,
		{[], #sctp_paddr_change{addr = {PeerAddr, PeerPort},
		state = addr_confirmed, assoc_id = Assoc}}}, StateName,
		#statedata{socket = Socket,assoc = Assoc} = StateData) ->
	inet:setopts(Socket, [{active, once}]),
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
		StateName, #statedata{static = false, socket = Socket,
		assoc = Assoc, ep = EP} = StateData)  ->
	RK = #m3ua_routing_key{rc = RC, na = NA, tmt = Mode, key = Keys,
			lrk_id = generate_lrk_id(), as = AS},
	RoutingKey = m3ua_codec:routing_key(RK),
	Params = m3ua_codec:parameters([{?RoutingKey, RoutingKey}]),
	RegReq = #m3ua{class = ?RKMMessage, type = ?RKMREGREQ, params = Params},
	Message = m3ua_codec:m3ua(RegReq),
	case gen_sctp:send(Socket, Assoc, 0, Message) of
		ok ->
			Req = {'M-RK_REG', Ref, From, RK},
			NewStateData = StateData#statedata{req = Req},
			{next_state, StateName, NewStateData, ?Tack};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_reg({'M-RK_REG', request, Ref, From, RC, NA, Keys, Mode, AS},
		StateName, #statedata{static = true, rks = RKs, req = undefined,
		assoc = Assoc, ep = EP, callback = CbMod,
		cb_state = CbState} = StateData) when is_integer(RC) ->
	SortedKeys = m3ua:sort(Keys),
	RK = {NA, SortedKeys, Mode},
	case reg_tables(RC, RK, AS) of
		{ok, RC} ->
			NewRKs = case lists:keytake(RC, 1, RKs) of
				{value, {RC, _OldKeys, Active}, RKs1} ->
					[{RC, RK, Active} | RKs1];
				false ->
					[{RC, RK, inactive} | RKs]
			end,
			CbArgs = [RC, NA, SortedKeys, Mode, CbState],
			{ok, NewCbState} = m3ua_callback:cb(register, CbMod, CbArgs),
			NewStateData = StateData#statedata{rks = NewRKs,
					cb_state = NewCbState},
			gen_server:cast(From,
					{'M-RK_REG', confirm, Ref, {ok, RC}}),
			{next_state, StateName, NewStateData};
		{stop, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end.

%% @hidden
handle_asp(M3UA, StateName, Stream, StateData) when is_binary(M3UA) ->
	handle_asp(m3ua_codec:m3ua(M3UA), StateName, Stream, StateData);
handle_asp(#m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params},
		StateName, _Stream, #statedata{socket = Socket, callback = CbMod,
		cb_state = CbState, count = Count} = StateData) ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, undefined),
	Status = m3ua_codec:fetch_parameter(?Status, Parameters),
	AspId = proplists:get_value(?ASPIdentifier, Parameters),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, []),
	CbArgs = [RCs, Status, AspId, CbState],
	{ok, NewCbState} = m3ua_callback:cb(notify, CbMod, CbArgs),
	inet:setopts(Socket, [{active, once}]),
	NotifyIn = maps:get(notify_in, Count, 0),
	NewCount = maps:put(notify_in, NotifyIn + 1, Count),
	{next_state, StateName, StateData#statedata{count = NewCount,
			cb_state = NewCbState}};
handle_asp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK, params = Params},
		down, _Stream, #statedata{req = Request,
		socket = Socket, callback = CbMod, cb_state = CbState,
		ep = EP, assoc = Assoc, count = Count} = StateData) ->
	AspUpAck = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspUpAck, undefined),
	NewState = inactive,
	case state_traffic_maint(RCs, NewState, StateData) of
		ok ->
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_up, CbMod, CbArgs),
			NewStateData = case Request of
				{'M-ASP_UP', Ref, From} ->
					gen_server:cast(From, {'M-ASP_UP', confirm, Ref, ok}),
					StateData#statedata{req = undefined, cb_state = NewCbState};
				_ ->
					StateData#statedata{cb_state = NewCbState}
			end,
			inet:setopts(Socket, [{active, once}]),
			UpAckIn = maps:get(up_ack_in, Count, 0),
			NewCount = maps:put(up_ack_in, UpAckIn + 1, Count),
			NextStateData = NewStateData#statedata{count = NewCount},
			{next_state, NewState, NextStateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_asp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDNACK, params = Params},
		StateName, _Stream, #statedata{req = Request,
		socket = Socket, callback = CbMod, cb_state = CbState, ep = EP,
		assoc = Assoc, count = Count} = StateData)
		when StateName == inactive; StateName == active ->
	AspDownAck = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspDownAck, undefined),
	NewState = down,
	case state_traffic_maint(RCs, NewState, StateData) of
		ok ->
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_down, CbMod, CbArgs),
			NewStateData = case Request of
				{'M-ASP_DOWN', Ref, From} ->
					gen_server:cast(From, {'M-ASP_DOWN', confirm, Ref, ok}),
					StateData#statedata{req = undefined, cb_state = NewCbState};
				_ ->
					StateData#statedata{cb_state = NewCbState}
			end,
			inet:setopts(Socket, [{active, once}]),
			DownAckIn = maps:get(down_ack_in, Count, 0),
			NewCount = maps:put(down_ack_in, DownAckIn + 1, Count),
			NextStateData = NewStateData#statedata{count = NewCount},
			{next_state, NewState, NextStateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK, params = Params},
		inactive, _Stream, #statedata{req = Request,
		socket = Socket, callback = CbMod, cb_state = CbState, ep = EP,
		assoc = Assoc, count = Count} = StateData) ->
	AspActiveAck = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspActiveAck, undefined),
	NewState = active,
	case state_traffic_maint(RCs, NewState, StateData) of
		ok ->
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_active, CbMod, CbArgs),
			NewStateData = case Request of
				{'M-ASP_ACTIVE', Ref, From} ->
					gen_server:cast(From, {'M-ASP_ACTIVE', confirm, Ref, ok}),
					StateData#statedata{req = undefined, cb_state = NewCbState};
				_ ->
					StateData#statedata{cb_state = NewCbState}
			end,
			inet:setopts(Socket, [{active, once}]),
			ActiveAckIn = maps:get(active_ack_in, Count, 0),
			NewCount = maps:put(active_ack_in, ActiveAckIn + 1, Count),
			NextStateData = NewStateData#statedata{count = NewCount},
			{next_state, NewState, NextStateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_asp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK, params = Params},
		active, _Stream, #statedata{req = Request,
		socket = Socket, callback = CbMod, cb_state = CbState, ep = EP,
		assoc = Assoc, count = Count} = StateData) ->
	AspInactiveAck = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspInactiveAck, undefined),
	NewState = inactive,
	case state_traffic_maint(RCs, NewState, StateData) of
		ok ->
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_inactive, CbMod, CbArgs),
			NewStateData = case Request of
				{'M-ASP_INACTIVE', Ref, From} ->
					gen_server:cast(From, {'M-ASP_INACTIVE', confirm, Ref, ok}),
					StateData#statedata{req = undefined, cb_state = NewCbState};
				_ ->
					StateData#statedata{cb_state = NewCbState}
			end,
			inet:setopts(Socket, [{active, once}]),
			InactiveAckIn = maps:get(inactive_ack_in, Count, 0),
			NewCount = maps:put(inactive_ack_in, InactiveAckIn + 1, Count),
			NextStateData = NewStateData#statedata{count = NewCount},
			{next_state, NewState, NextStateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_asp(#m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = Params},
		StateName, _Stream, #statedata{socket = Socket, rks = RKs,
		req = {'M-RK_REG', Ref, From,
		#m3ua_routing_key{na = NA, tmt = Mode, as = AS, key = Keys}},
		callback = CbMod, cb_state = CbState, ep = EP,
		assoc = Assoc} = StateData)
		when StateName == inactive; StateName == active ->
   Parameters = m3ua_codec:parameters(Params),
   RegResult = m3ua_codec:get_all_parameter(?RegistrationResult, Parameters),
	SortedKeys = m3ua:sort(Keys),
	RK = {NA, SortedKeys, Mode},
	RKsResult = case RegResult of
		[#registration_result{status = registered, rc = RC}] ->
			reg_tables(RC, RK, AS);
		[#registration_result{status = Status}] ->
			{error, Status}
	end,
	case RKsResult of
		{ok, RC1} ->
			NewRKs = case lists:keytake(RC1, 1, RKs) of
				{value, {RC1, _OldKeys, Active}, RKs1} ->
					[{RC1, RK, Active} | RKs1];
				false ->
					[{RC1, RK, inactive} | RKs]
			end,
			CbArgs = [RC1, NA, Keys, Mode, CbState],
			{ok, NewCbState} = m3ua_callback:cb(register, CbMod, CbArgs),
			gen_server:cast(From, {'M-RK_REG', confirm, Ref, {ok, RC1}}),
			inet:setopts(Socket, [{active, once}]),
			NewStateData = StateData#statedata{req = undefined,
					rks = NewRKs, cb_state = NewCbState},
			{next_state, StateName, NewStateData};
		{error, Status1} ->
			gen_server:cast(From, {'M-RK_REG', confirm, Ref, {error, Status1}}),
			inet:setopts(Socket, [{active, once}]),
			NewStateData = StateData#statedata{req = undefined},
			{next_state, StateName, NewStateData};
		{stop, Reason1} ->
			{stop, {shutdown, {{EP, Assoc}, Reason1}}, StateData}
	end;
handle_asp(#m3ua{class = ?MGMTMessage, type = ?MGMTError, params = Params},
		StateName, _Stream, #statedata{req = {'M-RK_REG', Ref, From, _RK},
		socket = Socket} = StateData) ->
	Parameters = m3ua_codec:parameters(Params),
	{ok, Reason} = m3ua_codec:find_parameter(?ErrorCode, Parameters),
	gen_server:cast(From, {'M-RK_REG', confirm, Ref, {error, Reason}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, StateName, NewStateData};
handle_asp(#m3ua{class = ?MGMTMessage, type = ?MGMTError, params = Params},
		StateName, _Stream, #statedata{req = {AspOp, Ref, From},
		socket = Socket} = StateData) ->
	Parameters = m3ua_codec:parameters(Params),
	{ok, Reason} = m3ua_codec:find_parameter(?ErrorCode, Parameters),
	gen_server:cast(From, {AspOp, confirm, Ref, {error, Reason}}),
	inet:setopts(Socket, [{active, once}]),
	NewStateData = StateData#statedata{req = undefined},
	{next_state, StateName, NewStateData};
handle_asp(#m3ua{class = ?TransferMessage,
		type = ?TransferMessageData, params = Params}, active, Stream,
		#statedata{callback = CbMod, cb_state = CbState,
		socket = Socket, count = Count} = StateData) when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = case m3ua_codec:find_parameter(?RoutingContext, Parameters) of
		{ok, [RC1]} ->
			RC1;
		{error, not_found} ->
			undefined
	end,
	#protocol_data{opc = OPC, dpc = DPC,
			ni = NI, si = SI, sls = SLS, data = Data} =
			m3ua_codec:fetch_parameter(?ProtocolData, Parameters),
	CbArgs = [Stream, RC, OPC, DPC, NI, SI, SLS, Data, CbState],
	{ok, NewCbState} = m3ua_callback:cb(transfer, CbMod, CbArgs),
	inet:setopts(Socket, [{active, once}]),
	TransferIn = maps:get(transfer_in, Count, 0),
	NewCount = maps:put(transfer_in, TransferIn + 1, Count),
	NewStateData = StateData#statedata{cb_state = NewCbState, count = NewCount},
	{next_state, active, NewStateData};
handle_asp(#m3ua{class = ?SSNMMessage, type = ?SSNMDUNA, params = Params},
		StateName, Stream, #statedata{callback = CbMod, cb_state = CbState,
		socket = Socket, count = Count} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, []),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	CbArgs = [Stream, RCs, APCs, CbState],
	{ok, NewCbState} = m3ua_callback:cb(pause, CbMod, CbArgs),
	inet:setopts(Socket, [{active, once}]),
	DunaIn = maps:get(duna_in, Count, 0),
	NewCount = maps:put(duna_in, DunaIn + 1, Count),
	NewStateData = StateData#statedata{cb_state = NewCbState, count = NewCount},
	{next_state, StateName, NewStateData};
handle_asp(#m3ua{class = ?SSNMMessage, type = ?SSNMDAVA, params = Params},
		StateName, Stream, #statedata{callback = CbMod, cb_state = CbState,
		socket = Socket, count = Count} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, []),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	CbArgs = [Stream, RCs, APCs, CbState],
	{ok, NewCbState} = m3ua_callback:cb(resume, CbMod, CbArgs),
	inet:setopts(Socket, [{active, once}]),
	DavaIn = maps:get(dava_in, Count, 0),
	NewCount = maps:put(dava_in, DavaIn + 1, Count),
	NewStateData = StateData#statedata{cb_state = NewCbState, count = NewCount},
	{next_state, StateName, NewStateData};
handle_asp(#m3ua{class = ?SSNMMessage, type = ?SSNMSCON, params = Params},
		StateName, Stream, #statedata{callback = CbMod, cb_state = CbState,
		socket = Socket} = StateData) when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, []),
	APCs = m3ua_codec:get_all_parameter(?AffectedPointCode, Parameters),
	CbArgs = [Stream, RCs, APCs, CbState],
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
	rand:uniform(16#ffffffff).

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

-spec get_rc(DPC, OPC, SI, RKs) -> RC
	when
		DPC :: 0..4294967295,
		OPC :: 0..4294967295,
		SI :: 0..4294967295,
		RKs :: [{RC, RK, Active}],
		RC :: 0..4294967295,
		RK :: {NA, Keys, TMT},
		NA :: byte(),
		Keys :: [{DPC, [SI], [OPC]}],
		TMT :: tmt(),
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
reg_tables(RC, RK, Name) ->
	Fsm = self(),
	F = fun() ->
			case mnesia:read(m3ua_as, RC, write) of
				[] ->
					ASPs = [#m3ua_as_asp{fsm = Fsm, state = inactive}],
					AS = #m3ua_as{rc = RC, rk = RK, name = Name, asp = ASPs},
					mnesia:write(AS),
					ASP = #m3ua_asp{fsm = Fsm, rc = RC, rk = RK},
					mnesia:write(ASP);
				[#m3ua_as{asp = ASPs} = AS] ->
					NewASPs = case lists:keymember(Fsm, #m3ua_as_asp.fsm, ASPs) of
						true ->
							ASPs;
						false ->
							[#m3ua_as_asp{fsm = Fsm, state = inactive} | ASPs]
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
state_traffic_maint(undefined, Event, #statedata{rks = RKs} = StateData) ->
	RCs = [RC || {RC, _, _} <- RKs],
	state_traffic_maint(RCs, Event, StateData);
state_traffic_maint(RCs, AspState, _StateData) ->
	state_traffic_maint1(RCs, AspState).
%% @hidden
state_traffic_maint1([RC | T], AspState) ->
	F = fun() ->
			case mnesia:read(m3ua_as, RC, write) of
					[] ->
						ok;
					[#m3ua_as{asp = ASPs} = AS] ->
						case lists:keytake(self(), #m3ua_as_asp.fsm, ASPs) of
							{value, ASP, Rest} ->
								NewASP = ASP#m3ua_as_asp{state = AspState},
								mnesia:write(AS#m3ua_as{asp = [NewASP | Rest]});
							false ->
								ok
						end
			end
	end,
	case mnesia:transaction(F) of
		{atomic, ok} ->
			state_traffic_maint1(T, AspState);
		{aborted, Reason} ->
			{error, Reason}
	end;
state_traffic_maint1([], _) ->
	ok.

