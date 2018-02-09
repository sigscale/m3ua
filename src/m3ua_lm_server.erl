%%% m3ua_lm_server.erl
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
%%% @doc This {@link //stdlib/gen_server. gen_server} behaviour callback
%%% 	module implements the layer management access point in the
%%% 	{@link //m3ua. m3ua} application.
%%%
-module(m3ua_lm_server).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(gen_server).

%% export the m3ua_lm_server API
-export([open/1, close/1]).
-export([sctp_establish/4, sctp_release/2, sctp_status/2]).
-export([register/6]).
-export([as_add/6, as_delete/1]).
-export([asp_status/2, asp_up/2, asp_down/2, asp_active/2,
			asp_inactive/2]).
-export([getstat/2, getstat/3]).

%% export the callbacks needed for gen_server behaviour
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
			terminate/2, code_change/3]).

-record(state,
		{sup :: pid(),
		ep_sup_sup :: pid(),
		eps = gb_trees:empty() :: gb_trees:tree(),
		fsms = gb_trees:empty() :: gb_trees:tree(),
		reqs = gb_trees:empty() :: gb_trees:tree()}).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

%%----------------------------------------------------------------------
%%  The m3ua_lm_server API
%%----------------------------------------------------------------------

-spec open(Args :: [term()]) -> {ok, EP :: pid()} | {error, Reason :: term()}.
%% @doc Open a new server end point (`EP').
%% @private
open(Args) when is_list(Args) ->
	gen_server:call(?MODULE, {open, Args}).

-spec close(EP :: pid()) -> ok | {error, Reason :: term()}.
%% @doc Close a previously opened end point (`EP').
%% @private
close(EP) ->
	gen_server:call(?MODULE, {close, EP}).

-spec sctp_establish(EndPoint, Address, Port, Options) -> Result
	when
		EndPoint :: pid(),
		Address :: inet:ip_address() | inet:hostname(),
		Port :: inet:port_number(),
		Options :: [gen_sctp:option()],
		Result :: {ok, Assoc} | {error, Reason},
		Assoc :: pos_integer(),
		Reason :: term().
%% @doc Establish an SCTP association.
%% @private
sctp_establish(EndPoint, Address, Port, Options) ->
	gen_server:call(?MODULE, {sctp_establish,
			EndPoint, Address, Port, Options}).

-spec as_add(Name, NA, Keys, Mode, MinASP, MaxASP) -> Result
	when
		Name :: term(),
		NA :: undefined | pos_integer(),
		Keys :: [Key],
		MinASP :: pos_integer(),
		MaxASP :: pos_integer(),
		Key :: {DPC, [SI], [OPC]},
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer(),
		Mode :: overide | loadshare | broadcast,
		Result :: {ok, AS} | {error, Reason},
		AS :: #m3ua_as{},
		Reason :: term().
%% @doc Add an Application Server (AS).
as_add(Name, NA, Keys, Mode, MinASP, MaxASP)
		when ((NA == undefined) orelse is_integer(NA)),
		is_list(Keys), is_atom(Mode),
		is_integer(MinASP), is_integer(MaxASP) ->
	gen_server:call(?MODULE, {as_add,
			Name, NA, Keys, Mode, MinASP, MaxASP}).

-spec as_delete(RoutingKey) -> Result
	when
		RoutingKey :: {NA, Keys, Mode},
		NA :: undefined | pos_integer(),
		Keys :: [Key],
		Key :: {DPC, [SI], [OPC]},
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer(),
		Mode :: overide | loadshare | broadcast,
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Delete an Application Server (AS).
as_delete(RoutingKey) ->
	gen_server:call(?MODULE, {as_delete, RoutingKey}).

-spec register(EndPoint, Assoc, NA, Keys, Mode, AS) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		NA :: pos_integer(),
		Keys :: [Key],
		Key :: {DPC, [SI], [OPC]},
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer(),
		Mode :: overide | loadshare | broadcast,
		AS :: pid() | {local, Name} | {global, GlobalName}
				| {via, Module, ViaName},
		Name :: atom(),
		GlobalName :: term(),
		Module :: atom(),
		ViaName :: term(),
		Result :: {ok, RoutingContext} | {error, Reason},
		RoutingContext :: pos_integer(),
		Reason :: term().
%% @doc Register a routing key for an application server.
register(EndPoint, Assoc, NA, Keys, Mode, AS) ->
	gen_server:call(?MODULE,
			{register, EndPoint, Assoc, NA, Keys, Mode, AS}).

-spec sctp_release(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Release an established SCTP association.
%% @private
sctp_release(EndPoint, Assoc) ->
	gen_server:call(?MODULE, {sctp_release, EndPoint, Assoc}).

-spec sctp_status(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Report the status of an SCTP association.
%% @private
sctp_status(EndPoint, Assoc) ->
	gen_server:call(?MODULE, {sctp_status, EndPoint, Assoc}).

-spec asp_status(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: {ok, AspState} | {error, Reason},
		AspState :: down | inactive | active,
		Reason :: term().
%% @doc Report the status of local or remote ASP.
%% @private
asp_status(EndPoint, Assoc) ->
	gen_server:call(?MODULE, {asp_status, EndPoint, Assoc}).

-spec asp_up(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP start its operation
%%  and send an ASP Up message to its peer.
%% @private
asp_up(EndPoint, Assoc) ->
	gen_server:call(?MODULE, {asp_up, EndPoint, Assoc}).

-spec asp_down(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP stop its operation
%%  and send an ASP Down message to its peer.
%% @private
asp_down(EndPoint, Assoc) ->
	gen_server:call(?MODULE, {asp_down, EndPoint, Assoc}).

-spec asp_active(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Active message to its peer.
%% @private
asp_active(EndPoint, Assoc) ->
	gen_server:call(?MODULE, {asp_active, EndPoint, Assoc}).

-spec asp_inactive(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Inactive message to its peer.
%% @private
asp_inactive(EndPoint, Assoc) ->
	gen_server:call(?MODULE, {asp_inactive, EndPoint, Assoc}).

-spec getstat(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{inet:stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics for an association.
getstat(EndPoint, Assoc)
		when is_pid(EndPoint), is_integer(Assoc) ->
	gen_server:call(?MODULE, {getstat, EndPoint, Assoc, undefined}).

-spec getstat(EndPoint, Assoc, Options) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Options :: [inet:stat_option()],
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{inet:stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics for an association.
getstat(EndPoint, Assoc, Options)
		when is_pid(EndPoint), is_integer(Assoc), is_list(Options)  ->
	gen_server:call(?MODULE, {getstat, EndPoint, Assoc, Options}).

%%----------------------------------------------------------------------
%%  The m3ua_lm_server gen_server callbacks
%%----------------------------------------------------------------------

-spec init(Args :: [term()]) ->
	{ok, State :: #state{}}
			| {ok, State :: #state{}, Timeout :: timeout()}
			| {stop, Reason :: term()} | ignore.
%% @doc Initialize the {@module} server.
%% @see //stdlib/gen_server:init/1
%% @private
%%
init([Sup] = _Args) when is_pid(Sup) ->
	process_flag(trap_exit, true),
	{ok, #state{sup = Sup}, 0}.

-spec handle_call(Request :: term(), From :: {pid(), Tag :: any()},
		State :: #state{}) ->
	{reply, Reply :: term(), NewState :: #state{}}
			| {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate}
			| {noreply, NewState :: #state{}}
			| {noreply, NewState :: #state{}, timeout() | hibernate}
			| {stop, Reason :: term(), Reply :: term(), NewState :: #state{}}
			| {stop, Reason :: term(), NewState :: #state{}}.
%% @doc Handle a request sent using {@link //stdlib/gen_server:call/2.
%% 	gen_server:call/2,3} or {@link //stdlib/gen_server:multi_call/2.
%% 	gen_server:multi_call/2,3,4}.
%% @see //stdlib/gen_server:handle_call/3
%% @private
%%
handle_call(Request, From, #state{ep_sup_sup = undefined} = State) ->
	NewState = get_sups(State),
	handle_call(Request, From, NewState);
handle_call({open, Args}, {USAP, _Tag} = _From,
		#state{ep_sup_sup = EPSupSup, eps = EndPoints} = State) ->
	case supervisor:start_child(EPSupSup, [Args]) of
		{ok, EndPointSup} ->
			Children = supervisor:which_children(EndPointSup),
			{_, EP, _, _} = lists:keyfind(m3ua_endpoint_server,
					1, Children),
			NewEndPoints = gb_trees:insert(EP, USAP, EndPoints),
			NewState = State#state{eps = NewEndPoints},
			{reply, {ok, EP}, NewState};
		{error, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call({close, EP}, _From, #state{eps = EndPoints} = State) when is_pid(EP) ->
	try m3ua_endpoint_server:stop(EP) of
		ok ->
			NewEndPoints = gb_trees:delete(EP, EndPoints),
			NewState = State#state{eps = NewEndPoints},
			{reply, ok, NewState}
	catch
		exit:Reason ->
			{reply, {error, Reason}, State}
	end;
handle_call({sctp_establish, EndPoint, Address, Port, Options},
		_From, #state{fsms = Fsms} = State) ->
	case gen_server:call(EndPoint, {establish, Address, Port, Options}) of
		{ok, AspFsm, Assoc} ->
			NewFsms = gb_trees:insert({EndPoint, Assoc}, AspFsm, Fsms),
			NewState = State#state{fsms = NewFsms},
			{reply, {ok, Assoc}, NewState};
		{error, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call({sctp_release, EndPoint, Assoc}, _From, #state{fsms = Fsms} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, _} ->
			case catch gen_server:call(EndPoint, {release, Assoc}) of
				ok ->
					NewFsms	= gb_trees:delete({EndPoint, Assoc}, Fsms),
					NewState = State#state{fsms = NewFsms},
					{reply, ok, NewState};
				{error, Reason} ->
					{reply, {error, Reason}, State};
				{'EXIT', Reason} ->
					{reply, {error, Reason}, State}
			end;
		none ->
			{reply, {error, invalid_assco}, State}
	end;
handle_call({sctp_status, EndPoint, Assoc}, _From, #state{fsms = Fsms} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, Fsm} ->
			Reply = gen_fsm:sync_send_all_state_event(Fsm, sctp_status),
			{reply, Reply, State};
		none ->
			{reply, {error, not_found}, State}
	end;
handle_call({asp_status, _EndPoint, _Assoc}, _From, State) ->
	{reply, {error, not_implement}, State};
handle_call({as_add, Name, NA, Keys, Mode, MinASP, MaxASP}, _From, State) ->
	F = fun() ->
				SortedKeys = m3ua:sort(Keys),
				AS = #m3ua_as{routing_key = {NA, SortedKeys, Mode},
						name = Name, min_asp = MinASP, max_asp = MaxASP},
				ok = mnesia:write(AS),
				AS
	end,
	case mnesia:transaction(F) of
		{atomic, AS} ->
			{reply, {ok, AS}, State};
		{aborted, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call({as_delete, RoutingKey}, _From, State) ->
	F = fun() ->
				SortedKey = m3ua:sort([RoutingKey]),
				mnesia:delete(m3ua_as, SortedKey, write)
	end,
	case mnesia:transaction(F) of
		{atomic, ok} ->
			{reply, ok, State};
		{aborted, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call({register, EndPoint, Assoc, NA, Keys, Mode, AS}, From,
		#state{fsms = Fsms, reqs = Reqs} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, AspFsm} ->
			Ref = make_ref(),
			gen_fsm:send_event(AspFsm,
					{register, Ref, self(), NA, Keys, Mode, AS}),
			NewReqs = gb_trees:insert(Ref, From, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{reply, {error, not_found}, State}
	end;
handle_call({AspOp, EndPoint, Assoc}, From,
		#state{fsms = Fsms, reqs = Reqs} = State)
		when AspOp == asp_up; AspOp == asp_down;
		AspOp == asp_active; AspOp == asp_inactive ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, AspFsm} ->
			Ref = make_ref(),
			gen_fsm:send_event(AspFsm, {AspOp, Ref, self()}),
			NewReqs = gb_trees:insert(Ref, From, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{reply, {error, not_found}, State}
	end;
handle_call({getstat, EndPoint, Assoc, Options}, _From,
		#state{fsms = Fsms} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, Fsm} ->
			Event = {getstat, Options},
			Reply = gen_fsm:sync_send_all_state_event(Fsm, Event),
			{reply, Reply, State};
		none ->
			{reply, {error, not_found}, State}
	end.

-spec handle_cast(Request :: term(), State :: #state{}) ->
	{noreply, NewState :: #state{}}
			| {noreply, NewState :: #state{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewState :: #state{}}.
%% @doc Handle a request sent using {@link //stdlib/gen_server:cast/2.
%% 	gen_server:cast/2} or {@link //stdlib/gen_server:abcast/2.
%% 	gen_server:abcast/2,3}.
%% @see //stdlib/gen_server:handle_cast/2
%% @private
%%
handle_cast(stop, State) ->
	{stop, normal, State};
handle_cast({_AspOp, Ref, _ASP, {error, Reason}},
		#state{reqs = Reqs} = State) ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, {error, Reason}),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({AspOp, Ref, {ok, RC, RK}},
		#state{reqs = Reqs} = State)
		when AspOp == register ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, {ok, RC}),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({AspOp, Ref, {ok, CbMod, Asp, EP, Assoc, UState, _Identifier, _Info}},
		#state{reqs = Reqs} = State)
		when AspOp == asp_up; AspOp == asp_down;
		AspOp == asp_active; AspOp == asp_inactive ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			{ok, NewUState} = apply(CbMod, AspOp, [Asp, EP, Assoc, UState]),
			gen_server:reply(From, ok),
			ok = gen_fsm:send_all_state_event(Asp, {AspOp, NewUState}),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({TrafficMaintIndication, CbMod, Sgp, EP, Assoc, RK, UState}, #state{} = State) when
		TrafficMaintIndication == 'M-ASP_ACTIVE'; TrafficMaintIndication == 'M-ASP_INACTIVE' ->
	F = fun() ->
		case mnesia:read(m3ua_as, RK, write) of
			[] ->
				ok;
			[#m3ua_as{max_asp = Max, min_asp = Min, asp = Asps}]
					when length(Asps) =< Max, length(Asps) >= Min ->
				ok;
			[#m3ua_as{}] ->
				ok
		end
	end,
	case mnesia:transaction(F) of
		{atomic, _} ->
			Function = case TrafficMaintIndication of
				'M-ASP_ACTIVE' -> asp_active;
				'M-ASP_INACTIVE' -> asp_inactive
			end,
			{ok, NewUState} = apply(CbMod, Function, [Sgp, EP, Assoc, UState]),
			ok = gen_fsm:send_all_state_event(Sgp, {TrafficMaintIndication, NewUState}),
			{noreply, State};
		{aborted, _Reason} ->
			{noreply, State}
	end;
handle_cast({StateMainIndication, CbMod, Sgp, EP, Assoc, UState}, #state{} = State) when
		StateMainIndication == 'M-ASP_UP'; StateMainIndication == 'M-ASP_DOWN' ->
	Function = case StateMainIndication of
		'M-ASP_UP' -> asp_up;
		'M-ASP_DOWN' -> asp_down
	end,
	{ok, NewUState} = apply(CbMod, Function, [Sgp, EP, Assoc, UState]),
	ok = gen_fsm:send_all_state_event(Sgp, {StateMainIndication, NewUState}),
	{noreply, State};
handle_cast({'M-RK_REG', Sgp, Socket, Assoc, Msg}, State) ->
	handle_registration(Msg, Sgp, Socket, Assoc, State).

-spec handle_info(Info :: timeout | term(), State::#state{}) ->
	{noreply, NewState :: #state{}}
			| {noreply, NewState :: #state{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewState :: #state{}}.
%% @doc Handle a received message.
%% @see //stdlib/gen_server:handle_info/2
%% @private
%%
handle_info(timeout, #state{ep_sup_sup = undefined} = State) ->
	NewState = get_sups(State),
	{noreply, NewState}.

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State::#state{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_server:terminate/3
%% @private
%%
terminate(_Reason, _State) ->
	ok.

-spec code_change(OldVsn :: term() | {down, term()}, State :: #state{},
		Extra :: term()) ->
	{ok, NewState :: #state{}} | {error, Reason :: term()}.
%% @doc Update internal state data during a release upgrade&#047;downgrade.
%% @see //stdlib/gen_server:code_change/3
%% @private
%%
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

%% @hidden
get_sups(#state{sup = TopSup, ep_sup_sup = undefined} = State) ->
	Siblings = supervisor:which_children(TopSup),
	{_, EPSupSup, _, _} = lists:keyfind(m3ua_endpoint_sup_sup, 1, Siblings),
	State#state{ep_sup_sup = EPSupSup}.

handle_registration(#m3ua{class = ?RKMMessage, type = ?RKMREGREQ, params = Params},
	Sgp, Socket, Assoc, State) ->
	Parameters = m3ua_codec:parameters(Params),
	RKs = m3ua_codec:get_all_parameter(?RoutingKey, Parameters),
	RC = rand:uniform(255),
	F = fun() ->
			handle_registration1(RKs, Sgp, Socket, Assoc, RC, inactive, [])
	end,
	case mnesia:transaction(F) of
		{atomic, ok} ->
			{noreply, State};
		{aborted, Reason} ->
			error_logger:error_report(["asp registration failed",
						{reason, Reason}, {module, ?MODULE}]),
			{noreply, State}
	end.
%% @hidden
handle_registration1([RoutingKey | T], Sgp, Socket, Assoc, RC, _AsState, Acc) ->
	#m3ua_routing_key{rc = NewRC, na = NA,
			tmt = Mode, key = Keys, lrk_id = LRKId} =
	case m3ua_codec:routing_key(RoutingKey) of
		#m3ua_routing_key{rc = undefined}  = RK ->
			RK#m3ua_routing_key{rc = RC};
		RK ->
			RK
	end,
	{Result, NewAsState} = handle_registration2(Sgp, NA, Mode, NewRC, LRKId, m3ua:sort(Keys)),
	handle_registration1(T, Sgp, Socket, Assoc, RC, Result ++ Acc, NewAsState);
handle_registration1([], _Sgp, Socket, Assoc, _RC, Acc, AsState) ->
	Message1 = #m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = Acc},
	Packet1 = m3ua_codec:m3ua(Message1),
	case gen_sctp:send(Socket, Assoc, 0, Packet1) of
		ok ->
			Params = m3ua_codec:add_parameter(?Status, {assc, AsState}, []),
			Message2 = #m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params},
			Packet2 = m3ua_codec:m3ua(Message2),
			case gen_sctp:send(Socket, Assoc, 0, Packet2) of
				ok ->
					inet:setopts(Socket, [{active, once}]),
					ok;
				{error, eagain} ->
					% @todo flow control
					throw(eagain);
				{error, Reason} ->
					throw(Reason)
			end;
		{error, eagain} ->
			% @todo flow control
			throw(eagain);
		{error, Reason} ->
			throw(Reason)
	end.
%% @hidden
handle_registration2(Sgp, NA, Mode, RC, LRKId, Keys) ->
	case mnesia:read(m3ua_as, {NA, Keys, Mode}) of
		[] ->
			RegResult = #registration_result{lrk_id = LRKId,
				status = registered, rc = RC},
			Asp = #m3ua_asp{sgp = Sgp, state = inactive},
			AS = #m3ua_as{asp = [Asp]},
			mnesia:write(AS),
			Message = m3ua_codec:add_parameter(?RegistrationResult, RegResult, []),
			{Message, inactive};
		[#m3ua_as{asp = Asps, min_asp = Min, max_asp = Max, state = AsState} = AS] ->
			case lists:keytake(Sgp, #m3ua_asp.sgp, Asps) of
				{value, _, _} ->
					RegResult = #registration_result{lrk_id = LRKId,
						status = rk_already_registered, rc = RC},
					Message = m3ua_codec:add_parameter(?RegistrationResult, RegResult, []),
					{Message, AsState};
				false ->
					F = fun(#m3ua_as{state = active}) -> true; (_) -> false end,
					ActiveLen = length(lists:filter(F, Asps)),
					NewAsState = case (ActiveLen >= Min) and (ActiveLen =< Max) of
						true ->
							active;
						false ->
							inactive
					end,
					Asp = #m3ua_asp{sgp = Sgp, state = inactive},
					NewAS = AS#m3ua_as{asp = [Asp | Asps]},
					mnesia:write(NewAS),
					RegResult = #registration_result{lrk_id = LRKId, status = registered, rc = RC},
					Message = m3ua_codec:add_parameter(?RegistrationResult, RegResult, []),
					{Message, NewAsState}
			end
	end.

