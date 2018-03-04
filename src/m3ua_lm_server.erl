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
-export([open/2, close/1]).
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
		{sup :: undefined | pid(),
		ep_sup_sup :: undefined | pid(),
		eps = gb_trees:empty() :: gb_trees:tree(),
		fsms = gb_trees:empty() :: gb_trees:tree(),
		reqs = gb_trees:empty() :: gb_trees:tree()}).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

%%----------------------------------------------------------------------
%%  The m3ua_lm_server API
%%----------------------------------------------------------------------

-spec open(Args, Callback) -> Result 
	when
		Args :: [term()],
		Callback :: atom() | #m3ua_fsm_cb{},
		Result :: {ok, EP} | {error, Reason},
		EP :: pid(),
		Reason :: term().
%% @doc Open a new server end point (`EP').
%% @private
open(Args, Callback) when is_list(Args) ->
	gen_server:call(m3ua, {open, Args, Callback}).

-spec close(EP :: pid()) -> ok | {error, Reason :: term()}.
%% @doc Close a previously opened end point (`EP').
%% @private
close(EP) ->
	gen_server:call(m3ua, {close, EP}).

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
	gen_server:call(m3ua, {'M-SCTP_ESTABLISH',
			request, EndPoint, Address, Port, Options}).

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
	gen_server:call(m3ua, {as_add,
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
	gen_server:call(m3ua, {as_delete, RoutingKey}).

-spec register(EndPoint, Assoc, NA, Keys, Mode, AsName) -> Result
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
		AsName :: term(),
		Result :: {ok, RoutingContext} | {error, Reason},
		RoutingContext :: pos_integer(),
		Reason :: term().
%% @doc Register a routing key for an application server.
register(EndPoint, Assoc, NA, Keys, Mode, AsName) ->
	gen_server:call(m3ua,
			{'M-RK_REG', request, EndPoint, Assoc, NA, Keys, Mode, AsName}).

-spec sctp_release(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Release an established SCTP association.
%% @private
sctp_release(EndPoint, Assoc) ->
	gen_server:call(m3ua, {'M-SCTP_RELEASE', request, EndPoint, Assoc}).

-spec sctp_status(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Report the status of an SCTP association.
%% @private
sctp_status(EndPoint, Assoc) ->
	gen_server:call(m3ua, {'M-SCTP_STATUS', request, EndPoint, Assoc}).

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
	gen_server:call(m3ua, {'M-ASP_STATUS', request, EndPoint, Assoc}).

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
	gen_server:call(m3ua, {'M-ASP_UP', request, EndPoint, Assoc}).

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
	gen_server:call(m3ua, {'M-ASP_DOWN', request, EndPoint, Assoc}).

-spec asp_active(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Active message to its peer.
%% @private
asp_active(EndPoint, Assoc) ->
	gen_server:call(m3ua, {'M-ASP_ACTIVE', request, EndPoint, Assoc}).

-spec asp_inactive(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: pos_integer(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Inactive message to its peer.
%% @private
asp_inactive(EndPoint, Assoc) ->
	gen_server:call(m3ua, {'M-ASP_INACTIVE', request, EndPoint, Assoc}).

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
	gen_server:call(m3ua, {getstat, EndPoint, Assoc, undefined}).

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
	gen_server:call(m3ua, {getstat, EndPoint, Assoc, Options}).

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
handle_call({open, Args, Callback}, {USAP, _Tag} = _From,
		#state{ep_sup_sup = EPSupSup, eps = EndPoints} = State) ->
	case supervisor:start_child(EPSupSup, [[Callback, Args]]) of
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
handle_call({'M-SCTP_ESTABLISH', request, EndPoint, Address, Port, Options},
		_From, #state{fsms = Fsms} = State) ->
	case gen_server:call(EndPoint, {'M-SCTP_ESTABLISH', request, Address, Port, Options}) of
		{ok, AspFsm, Assoc} ->
			NewFsms = gb_trees:insert({EndPoint, Assoc}, AspFsm, Fsms),
			NewState = State#state{fsms = NewFsms},
			{reply, {ok, Assoc}, NewState};
		{error, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call({'M-SCTP_RELEASE', request, EndPoint, Assoc}, _From, #state{fsms = Fsms} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, _} ->
			case catch gen_server:call(EndPoint, {'M-SCTP_RELEASE', request,  Assoc}) of
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
handle_call({'M-SCTP_STATUS', request, EndPoint, Assoc}, _From, #state{fsms = Fsms} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, Fsm} ->
			Reply = gen_fsm:sync_send_all_state_event(Fsm, {'M-SCTP_STATUS', request}),
			{reply, Reply, State};
		none ->
			{reply, {error, not_found}, State}
	end;
handle_call({'M-ASP_STATUS', request,  _EndPoint, _Assoc}, _From, State) ->
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
handle_call({'M-RK_REG', request, EndPoint, Assoc, NA, Keys, Mode, AsName}, From,
		#state{fsms = Fsms, reqs = Reqs} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, AspFsm} ->
			Ref = make_ref(),
			gen_fsm:send_event(AspFsm,
					{'M-RK_REG', request,  Ref, self(), NA, Keys, Mode, AsName}),
			NewReqs = gb_trees:insert(Ref, From, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{reply, {error, not_found}, State}
	end;
handle_call({AspOp, request, EndPoint, Assoc}, From,
		#state{fsms = Fsms, reqs = Reqs} = State)
		when AspOp == 'M-ASP_UP'; AspOp == 'M-ASP_DOWN';
		AspOp == 'M-ASP_ACTIVE'; AspOp == 'M-ASP_INACTIVE' ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, AspFsm} ->
			Ref = make_ref(),
			gen_fsm:send_event(AspFsm, {AspOp, request, Ref, self()}),
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
handle_cast({_AspOp, confirm, Ref, _ASP, {error, Reason}},
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
handle_cast({'M-RK_REG', confirm, Ref, Asp,
		#m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = Params},
		NA, Keys, TMT, AS, EP, Assoc, CbMod, UState}, State) ->
	Parameters = m3ua_codec:parameters(Params),
	RegResults = m3ua_codec:get_all_parameter(?RegistrationResult, Parameters),
	reg_result(RegResults, NA, m3ua:sort(Keys), TMT,
			AS, Asp, EP, Assoc, CbMod, UState, Ref, State);
handle_cast({'M-ASP_UP' = AspOp, confirm, Ref, {ok, CbMod, Asp, EP, Assoc,
		UState, _Identifier, _Info}}, #state{reqs = Reqs} = State) ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, ok),
			CbArgs = [Asp, EP, Assoc, UState],
			{ok, NewUState} = m3ua_callback:cb(cb_func(AspOp), CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(Asp, {AspOp, NewUState}),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({'M-ASP_DOWN' = AspOp, confirm, Ref, {ok, CbMod, Asp, EP, Assoc,
		UState, _Identifier, _Info}}, #state{reqs = Reqs} = State) ->
	F = fun() ->
		case mnesia:read(m3ua_asp, Asp, write) of
			[] ->
				ok;
			Asps ->
				F1 = fun(#m3ua_asp{rk = RK}) ->
					case mnesia:read(m3ua_as, RK, write) of
						[] ->
							ok;
						[#m3ua_as{asp = ASPs} = AS] ->
							case lists:keytake(Asp, #m3ua_as_asp.fsm, ASPs) of
								{value, ASP1, RemASPs} ->
									NewAS = AS#m3ua_as{asp = [ASP1#m3ua_as_asp{state = inactive} | RemASPs]},
									mnesia:write(NewAS);
								false ->
									ok
							end
					end
				end,
				ok = lists:foreach(F1, Asps)
		end
	end,
	Result = case mnesia:transaction(F) of
		{atomic, ok} ->
			ok;
		{aborted, Reason} ->
			{error, Reason}
	end,
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, Result),
			CbArgs = [Asp, EP, Assoc, UState],
			{ok, NewUState} = m3ua_callback:cb(cb_func(AspOp), CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(Asp, {AspOp, NewUState}),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({AspOp, confirm, Ref, {ok, CbMod, Asp, EP, Assoc, UState, _Identifier, _Info}},
		#state{reqs = Reqs} = State) when  AspOp == 'M-ASP_ACTIVE'; AspOp == 'M-ASP_INACTIVE' ->
	F = fun() ->
			case mnesia:read(m3ua_asp, Asp, write) of
				[] ->
					ok;
				Asps ->
					F1 = fun(#m3ua_asp{rk = RK}) ->
						case mnesia:read(m3ua_as, RK, write) of
							[] ->
								ok;
							[#m3ua_as{asp = ASPs} = AS] ->
								case lists:keytake(Asp, #m3ua_as_asp.fsm, ASPs) of
									{value, ASP1, RemAsps} when AspOp == 'M-ASP_ACTIVE' ->
										NewASP1 = ASP1#m3ua_as_asp{state = active},
										NewAS = AS#m3ua_as{asp = [NewASP1 | RemAsps]},
										mnesia:write(NewAS);
									{value, ASP1, RemAsps} when AspOp == 'M-ASP_INACTIVE' ->
										NewASP1 = ASP1#m3ua_as_asp{state = inactive},
										NewAS = AS#m3ua_as{asp = [NewASP1 | RemAsps]},
										mnesia:write(NewAS);
									false ->
										ok
								end
						end
					end,
					lists:foreach(F1, Asps)
			end
	end,
	Result = case mnesia:transaction(F) of
		{atomic, ok} ->
			ok;
		{aborted, Reason} ->
			{error, Reason}
	end,
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, Result),
			CbArgs = [Asp, EP, Assoc, UState],
			{ok, NewUState} = m3ua_callback:cb(cb_func(AspOp), CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(Asp, {AspOp, NewUState}),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({'M-NOTIFY', indication, Asp, Status, ASPIdentifier, RC}, State) ->
	handle_notify(Status, Asp, ASPIdentifier, RC, State);
handle_cast({TrafficMaintIndication, CbMod, Sgp, EP, Assoc, UState, RCs}, State) ->
	F = fun() ->
		case mnesia:read(m3ua_asp, Sgp, write) of
			[] ->
				ok;
			Asps ->
				FilteredAsps = case RCs of
					undefined ->
						Asps;
					_ ->
						F1 = fun(RC, Acc) ->
							case lists:keyfind(RC, #m3ua_asp.rc, Asps) of
								 #m3ua_asp{} = MatchAsp ->
									[MatchAsp | Acc];
								false ->
									Acc
							end
						end,
						lists:foldl(F1, [], RCs)
				end,
				F2 = fun(#m3ua_asp{rk = RK, rc = RC}) ->
						case mnesia:read(m3ua_as, RK, write) of
							[] ->
								ok;
							[#m3ua_as{state = active, asp = M3uaAsps} = AS]
									when TrafficMaintIndication == 'M-ASP_ACTIVE'->
								case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
									{value, M_Asp, RemAsps} ->
										NewAsps = [M_Asp#m3ua_as_asp{state = active} | RemAsps],
										NewAS = AS#m3ua_as{asp = NewAsps},
										ok = mnesia:write(NewAS);
									false ->
										ok
								end;
							[#m3ua_as{state = active, min_asp = Min, asp = M3uaAsps} = AS]
									when TrafficMaintIndication == 'M-ASP_INACTIVE'->
								F3 = fun(#m3ua_as_asp{state = active}) -> true; (_) -> false end,
								AspLen = length(lists:filter(F3, M3uaAsps)),
								case AspLen of
									Len when (Len - 1) < Min ->
										case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
											{value, M_Asp, RemAsps} ->
												NewAsps = [M_Asp#m3ua_as_asp{state = inactive} | RemAsps],
												NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
												ok = mnesia:write(NewAS),
												F4 = fun(#m3ua_as_asp{fsm = SGP}) ->
													gen_fsm:send_all_state_event(SGP, {'NTFY', 'AS_INACTIVE', RC})
												end,
												lists:foreach(F4, M3uaAsps);
											false ->
												ok
										end;
									_ ->
										case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
											{value, M_Asp, RemAsps} ->
												NewAsps = [M_Asp#m3ua_as_asp{state = inactive} | RemAsps],
												NewAS = AS#m3ua_as{asp = NewAsps},
												ok = mnesia:write(NewAS);
											false ->
												ok
										end
								end;
							[#m3ua_as{min_asp = Min, max_asp = Max, asp = M3uaAsps} = AS]
									when TrafficMaintIndication == 'M-ASP_ACTIVE'->
								F3 = fun(#m3ua_as_asp{state = active}) -> true; (_) -> false end,
								AspLen = length(lists:filter(F3, M3uaAsps)),
								case AspLen of
									Len when (Len + 1) >= Min, ((Max == undefined) or (Max >= (Len + 1))) ->
										case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
											{value, M_Asp, RemAsps} ->
												NewAsps = [M_Asp#m3ua_as_asp{state = active} | RemAsps],
												NewAS = AS#m3ua_as{state = active, asp = NewAsps},
												ok = mnesia:write(NewAS),
												F4 = fun(#m3ua_as_asp{fsm = SGP}) ->
													gen_fsm:send_all_state_event(SGP, {'NTFY', 'AS_ACTIVE', RC})
												end,
												lists:foreach(F4, M3uaAsps);
											false ->
												ok
										end;
									_Len ->
										case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
											{value, M_Asp, RemAsps} when AS#m3ua_as.state == inactive ->
												NewAsps = [M_Asp#m3ua_as_asp{state = active} | RemAsps],
												NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
												ok = mnesia:write(NewAS);
											{value, M_Asp, RemAsps} ->
												NewAsps = [M_Asp#m3ua_as_asp{state = active} | RemAsps],
												NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
												ok = mnesia:write(NewAS),
												F4 = fun(#m3ua_as_asp{fsm = SGP}) ->
													gen_fsm:send_all_state_event(SGP, {'NTFY', 'AS_INACTIVE', RC})
												end,
												lists:foreach(F4, M3uaAsps);
											false ->
												ok
										end
								end;
							[#m3ua_as{asp = M3uaAsps} = AS] 
									when TrafficMaintIndication == 'M-ASP_INACTIVE'->
								case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
									{value, M_Asp, RemAsps} ->
										NewAsps = [M_Asp#m3ua_as_asp{state = inactive} | RemAsps],
										NewAS = AS#m3ua_as{asp = NewAsps},
										ok = mnesia:write(NewAS);
									false ->
										ok
								end
						end
				end,
				lists:foreach(F2, FilteredAsps)
		end
	end,
	case mnesia:transaction(F) of
		{atomic, _} ->
			CbArgs = [Sgp, EP, Assoc, UState],
			{ok, NewUState} = m3ua_callback:cb(cb_func(TrafficMaintIndication), CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(Sgp, {TrafficMaintIndication, NewUState}),
			{noreply, State};
		{aborted, _Reason} ->
erlang:display({?MODULE, ?LINE, _Reason}),
			{noreply, State}
	end;
handle_cast({StateMainIndication, CbMod, Sgp, EP, Assoc, UState}, #state{} = State) when
		StateMainIndication == 'M-ASP_UP'; StateMainIndication == 'M-ASP_DOWN' ->
 	F = fun() ->
			case mnesia:read(m3ua_asp, Sgp, write) of
				[] ->
					ok;
				[#m3ua_asp{rk = RK} | _] ->
					case mnesia:read(m3ua_as, RK, write) of
						[] ->
							ok;
						[#m3ua_as{asp = Asps, min_asp = Min} = AS]
								when StateMainIndication == 'M-ASP_DOWN' ->
							F = fun(#m3ua_as_asp{state = active}) -> true; (_) -> false end,
							Len = length(lists:filter(F, Asps)),
							case lists:keytake(Sgp, #m3ua_as_asp.fsm, Asps) of
								{value, #m3ua_as_asp{state = active} = Asp, RemAsp}
										when (Len - 1) >= Min ->
									NewAsp = Asp#m3ua_as_asp{state = inactive},
									NewAsps = [NewAsp | RemAsp],
									NewAS = AS#m3ua_as{asp = NewAsps},
									mnesia:write(NewAS);
								{value, Asp, RemAsp} ->
									NewAsp = Asp#m3ua_as_asp{state = inactive},
									NewAsps = [NewAsp | RemAsp],
									NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
									F4 = fun(#m3ua_as_asp{fsm = SGP, rc = RC}) ->
										gen_fsm:send_all_state_event(SGP, {'NTFY', 'AS_INACTIVE', RC})
									end,
									lists:foreach(F4, NewAsps),
									mnesia:write(NewAS);
								false ->
									ok
							end;
						[#m3ua_as{}] when StateMainIndication == 'M-ASP_UP' ->
							ok
					end
			end
	end,
	case mnesia:transaction(F) of
		{atomic, ok} ->
			CbArgs = [Sgp, EP, Assoc, UState],
			{ok, NewUState} = m3ua_callback:cb(cb_func(StateMainIndication), CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(Sgp, {StateMainIndication, NewUState}),
			{noreply, State};
		{aborted, Reason} ->
			error_logger:error_report(["State maintenance indication failed",
						StateMainIndication, {reason, Reason}, {module, ?MODULE}]),
			{noreply, State}
	end;
handle_cast({'M-RK_REG', Socket, EP, Assoc, Sgp, Msg, CbMod, UState}, State) ->
	handle_registration(Msg, EP, Assoc, Sgp, Socket, 'M-RK_REG', CbMod, UState, State).

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
		EP, Assoc, Sgp, Socket, AspOp, CbMod, UState, State) ->
	Parameters = m3ua_codec:parameters(Params),
	RKs = m3ua_codec:get_all_parameter(?RoutingKey, Parameters),
	RC = rand:uniform(255),
	F = fun() ->
			handle_registration1(RKs, EP, Assoc, Sgp,
					Socket, RC, AspOp, CbMod, UState, inactive, [])
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
handle_registration1([RoutingKey | T], EP, Assoc, Sgp,
		Socket, RC, AspOp, CbMod, UState, _AsState, Acc) ->
	RKs = m3ua_codec:routing_key(RoutingKey),
	{Result, NewAsState} =
		handle_registration2(RKs, EP, Assoc, Sgp, AspOp, CbMod, UState),
	handle_registration1(T, EP, Assoc, Sgp, Socket,
			RC, AspOp, CbMod, UState, NewAsState, Result ++ Acc);
handle_registration1([], _EP, Assoc, _Sgp, Socket,
		_RC, _AspOp, _CbMod, _UState, AsState, Acc) ->
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
handle_registration2(#m3ua_routing_key{lrk_id = undefined, key = Keys},
		_EP, _Assoc, _Sgp, _AspOp, _CbMod, _UState) ->
	AsState = case mnesia:read(m3ua_as, m3ua:sort(Keys)) of
		[] ->
			inactive;
		[#m3ua_as{state = State}] ->
			State
	end,
	RegResult = #registration_result{status = unsupported_rk_parameter_field_, rc = 0},
	Message = m3ua_codec:add_parameter(?RegistrationResult, RegResult, []),
	{Message, AsState};
handle_registration2(#m3ua_routing_key{na = NA, key = Keys, tmt = Mode,
		rc = RC, lrk_id = LRKId}, EP, Assoc, Sgp, AspOp, CbMod, UState) ->
	SortedKeys = m3ua:sort(Keys),
	RK = {NA, SortedKeys, Mode},
	case mnesia:read(m3ua_as, {NA, Keys, Mode}, write) of
		[] when RC == undefined ->
			NewRC = erlang:phash2(rand:uniform(16#7FFFFFFF), 255),
			M3UAAsp1 = #m3ua_as_asp{fsm = Sgp, state = inactive},
			AS1 = #m3ua_as{state = inactive, routing_key = RK, asp = [M3UAAsp1]},
			Asp1 = #m3ua_asp{fsm = Sgp, rc = NewRC, rk = RK},
			ok = mnesia:write(AS1),
			ok = mnesia:write(Asp1),
			Registered1 = #registration_result{lrk_id = LRKId, status = registered, rc = NewRC},
			RegisteredMsg1 = [{?RegistrationResult, Registered1}],
			CbArgs =	[Sgp, EP, Assoc, NA, SortedKeys, Mode, UState],
			{ok, NewUState} = m3ua_callback:cb(cb_func(AspOp), CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(Sgp, {AspOp, NewUState}),
			{RegisteredMsg1, inactive};
		[] ->
			case mnesia:read(m3ua_asp, Sgp, write) of
				[] ->
					M3UAAsp2 = #m3ua_as_asp{fsm = Sgp, state = inactive},
					AS2 = #m3ua_as{state = inactive, routing_key = RK, asp = [M3UAAsp2]},
					Asp2 = #m3ua_asp{fsm = Sgp, rc = RC, rk = RK},
					mnesia:write(AS2),
					mnesia:write(Asp2),
					Registered2 = #registration_result{lrk_id = LRKId, status = registered, rc = RC},
					RegisteredMsg2 = [{?RegistrationResult, Registered2}],
					CbArgs =	[Sgp, EP, Assoc, NA, SortedKeys, Mode, UState],
					{ok, NewUState} = m3ua_callback:cb(cb_func(AspOp), CbMod, CbArgs),
					ok = gen_fsm:send_all_state_event(Sgp, {AspOp, NewUState}),
					{RegisteredMsg2, inactive};
				RegAsps ->
					case lists:keytake(RC, #m3ua_asp.rc, RegAsps) of
						{value, #m3ua_asp{rk = ExRK} = ExASP, _} ->
							case mnesia:read(m3ua_as, ExRK, write) of
								[] ->
									M3UAAsp3 = #m3ua_as_asp{fsm = Sgp, state = inactive},
									AS3 = #m3ua_as{state = inactive, routing_key = RK, asp = [M3UAAsp3]},
									Asp3 = #m3ua_asp{fsm = Sgp, rc = RC, rk = RK},
									mnesia:write(AS3),
									mnesia:write(Asp3),
									Registered2 = #registration_result{lrk_id = LRKId, status = registered, rc = RC},
									RegisteredMsg2 = [{?RegistrationResult, Registered2}],
									CbArgs =	[Sgp, EP, Assoc, NA, SortedKeys, Mode, UState],
									{ok, NewUState} = m3ua_callback:cb(cb_func(AspOp), CbMod, CbArgs),
									ok = gen_fsm:send_all_state_event(Sgp, {AspOp, NewUState}),
									{RegisteredMsg2, inactive};
								[#m3ua_as{state = State} = ExAS] ->
									NewKey = m3ua:sort(SortedKeys ++ element(2, ExRK)),
									AS3 = ExAS#m3ua_as{routing_key = setelement(2, ExRK, NewKey)},
									Asp3 = ExASP#m3ua_asp{rk = setelement(2, ExRK, NewKey)},
									mnesia:write(AS3),
									mnesia:write(Asp3),
									Registered2 = #registration_result{lrk_id = LRKId, status = registered, rc = RC},
									RegisteredMsg2 = [{?RegistrationResult, Registered2}],
									CbArgs =	[Sgp, EP, Assoc, NA, SortedKeys, Mode, UState],
									{ok, NewUState} = m3ua_callback:cb(cb_func(AspOp), CbMod, CbArgs),
									ok = gen_fsm:send_all_state_event(Sgp, {AspOp, NewUState}),
									{RegisteredMsg2, State}
							end;
						false ->
							M3UAAsp4 = #m3ua_as_asp{fsm = Sgp, state = inactive},
							AS4 = #m3ua_as{routing_key = RK, asp = [M3UAAsp4]},
							Asp4 = #m3ua_asp{fsm = Sgp, rc = RC, rk = RK},
							mnesia:write(AS4),
							mnesia:write(Asp4),
							Registered3 = #registration_result{lrk_id = LRKId, status = registered, rc = RC},
							RegisteredMsg3 = [{?RegistrationResult, Registered3}],
							CbArgs =	[Sgp, EP, Assoc, NA, SortedKeys, Mode, UState],
							{ok, NewUState} = m3ua_callback:cb(cb_func(AspOp), CbMod, CbArgs),
							ok = gen_fsm:send_all_state_event(Sgp, {AspOp, NewUState}),
							{RegisteredMsg3, inactive}
					end
			end;
		[#m3ua_as{asp = Asps, min_asp = Min, max_asp = Max, state = AsState} = AS] ->
			case lists:keytake(Sgp, #m3ua_as_asp.fsm, Asps) of
				{value, #m3ua_as_asp{}, _} ->
					AlreadyReg = #registration_result{lrk_id = LRKId,
						status = rk_already_registered, rc = 0},
					AlreadyRegMsg = [{?RegistrationResult, AlreadyReg}],
					{AlreadyRegMsg, AsState};
				false ->
					NewRC1 = case RC of
						undefined ->
							erlang:phash2(rand:uniform(16#7FFFFFFF), 255);
						_ ->
							RC
					end,
					F = fun(#m3ua_as{state = active}) -> true; (_) -> false end,
					ActiveLen = length(lists:filter(F, Asps)),
					NewAsState = case (ActiveLen >= Min) and (ActiveLen =< Max) of
						true ->
							active;
						false ->
							inactive
					end,
					M3UAAsp5 = #m3ua_as_asp{fsm = Sgp, state = inactive},
					AS5 = AS#m3ua_as{state = NewAsState, routing_key = RK, asp = [M3UAAsp5 | Asps]},
					Asp5 = #m3ua_asp{fsm = Sgp, rc = NewRC1, rk = RK},
					mnesia:write(AS5),
					mnesia:write(Asp5),
					Registered4 = #registration_result{lrk_id = LRKId, status = registered, rc = NewRC1},
					RegisteredMsg4 = [{?RegistrationResult, Registered4}],
					CbArgs =	[Sgp, EP, Assoc, NA, SortedKeys, Mode, UState],
					{ok, NewUState} = m3ua_callback:cb(cb_func(AspOp), CbMod, CbArgs),
					ok = gen_fsm:send_all_state_event(Sgp, {AspOp, NewUState}),
					{RegisteredMsg4, NewAsState}
			end
	end.

%% @hidden
reg_result([#registration_result{status = registered, rc = RC} | []],
		NA, Keys, TMT, AS, Asp, EP, Assoc, CbMod, UState,  Ref,
		#state{reqs = Reqs} = State) ->
	RK = {NA, Keys, TMT},
	F = fun() ->
			case mnesia:read(m3ua_as, RK, write) of
				[] ->
					M3UAAsps = [#m3ua_as_asp{fsm  = Asp, rc = RC, state = inactive}],
					M3UAAS = #m3ua_as{routing_key = RK, name = AS, asp = M3UAAsps},
					ASP = #m3ua_asp{fsm = Asp, rc = RC, rk = RK},
					ok = mnesia:write(M3UAAS),
					ok = mnesia:write(m3ua_asp, ASP, write);
				[#m3ua_as{asp = ExAsps} = ExAS] ->
					M3UAAsp = #m3ua_as_asp{fsm  = Asp, rc = RC, state = inactive},
					M3UAAS = ExAS#m3ua_as{name = AS, asp = [M3UAAsp | ExAsps]},
					ASP = #m3ua_asp{fsm = Asp, rk = RK},
					ok = mnesia:write(M3UAAS),
					ok = mnesia:write(m3ua_asp, ASP, write)
			end
	end,
	Result = case mnesia:transaction(F) of
		{atomic, ok} ->
			{ok, RC};
		{aborted, Reason} ->
			{error, Reason}
	end,
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, Result),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			CbArgs =	[Asp, EP, Assoc, NA, Keys, TMT, UState],
			{ok, NewUState} = m3ua_callback:cb(cb_func('M-RK_REG'), CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(Asp, {'M-RK_REG', NewUState}),
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
reg_result([#registration_result{status = Status} | []],
		_NA, _Keys, _TMT, _AS, _Asp, _Ep, _Assoc, _CbMod, _UState,
		Ref, #state{reqs = Reqs} = State) ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, {error, Status}),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end.

%% @hidden
handle_notify({assc, AsState}, Asp, _ASPIdentifier, _RC, State) ->
	F = fun() ->
		case mnesia:read(m3ua_asp, Asp, read) of
			[] ->
				ok;
			Asps ->
				F1 = fun(#m3ua_asp{rk = RK}) ->
					case mnesia:read(m3ua_as, RK, write) of
						[] ->
							ok;
						[#m3ua_as{} = AS] ->
							NewAS = AS#m3ua_as{state = AsState},
							ok = mnesia:write(NewAS)
					end
				end,
				lists:foreach(F1, Asps)
		end
	end,
	case mnesia:transaction(F) of
		{atomic, ok} ->
			{noreply, State};
		{aborted, Reason} ->
			error_logger:error_report(["Update AS table failed",
					{asp, Asp}, {reason, Reason}, {module, ?MODULE}]),
			{noreply, State}
	end;
handle_notify({other, AsState}, Asp, _ASPIdentifier, _RC, State) ->
	error_logger:error_report(["AS state change error",
			{asp, Asp}, {reason, AsState}, {module, ?MODULE}]),
	{noreply, State}.
	
%% @private
cb_func('M-ASP_UP') -> asp_up;
cb_func('M-ASP_DOWN') -> asp_down;
cb_func('M-ASP_ACTIVE') -> asp_active;
cb_func('M-ASP_INACTIVE') -> asp_inactive;
cb_func('M-RK_REG') -> register.

