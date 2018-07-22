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
-export([start/2, stop/1]).
-export([sctp_release/2, sctp_status/2]).
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
		eps = gb_trees:empty() :: gb_trees:tree(EP :: pid(),
				USAP :: pid()),
		fsms = gb_trees:empty() :: gb_trees:tree(EP :: pid(),
				Assoc :: gen_sctp:assoc_ip()),
		reqs = gb_trees:empty() :: gb_trees:tree(Ref :: reference(),
				From :: pid())}).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-type stat_option() ::
	'recv_cnt' | 'recv_max' | 'recv_avg' | 'recv_oct' | 'recv_dvi' |
	'send_cnt' | 'send_max' | 'send_avg' | 'send_oct' | 'send_pend'.

%%----------------------------------------------------------------------
%%  The m3ua_lm_server API
%%----------------------------------------------------------------------

-spec start(Callback, Options) -> Result
	when
		Callback :: atom() | #m3ua_fsm_cb{},
		Options :: [m3ua:option()],
		Result :: {ok, EP} | {error, Reason},
		EP :: pid(),
		Reason :: term().
%% @doc Open a new server end point (`EP').
%% @private
start(Callback, Options) when is_list(Options) ->
	gen_server:call(m3ua, {start, Callback, Options}).

-spec stop(EP :: pid()) -> ok | {error, Reason :: term()}.
%% @doc Close a previously opened end point (`EP').
%% @private
stop(EP) ->
	gen_server:call(m3ua, {stop, EP}).

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
		Mode :: override | loadshare | broadcast,
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
		Mode :: override | loadshare | broadcast,
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Delete an Application Server (AS).
as_delete(RoutingKey) ->
	gen_server:call(m3ua, {as_delete, RoutingKey}).

-spec register(EndPoint, Assoc, NA, Keys, Mode, AsName) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		NA :: pos_integer(),
		Keys :: [Key],
		Key :: {DPC, [SI], [OPC]},
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer(),
		Mode :: override | loadshare | broadcast,
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
		Assoc :: gen_sctp:assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Release an established SCTP association.
%% @private
sctp_release(EndPoint, Assoc) ->
	gen_server:call(m3ua, {'M-SCTP_RELEASE', request, EndPoint, Assoc}).

-spec sctp_status(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Report the status of an SCTP association.
%% @private
sctp_status(EndPoint, Assoc) ->
	gen_server:call(m3ua, {'M-SCTP_STATUS', request, EndPoint, Assoc}).

-spec asp_status(EndPoint, Assoc) -> AspState
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		AspState :: down | inactive | active.
%% @doc Report the status of local or remote ASP.
%% @private
asp_status(EndPoint, Assoc) ->
	gen_server:call(m3ua, {'M-ASP_STATUS', request, EndPoint, Assoc}).

-spec asp_up(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
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
		Assoc :: gen_sctp:assoc_id(),
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
		Assoc :: gen_sctp:assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Active message to its peer.
%% @private
asp_active(EndPoint, Assoc) ->
	gen_server:call(m3ua, {'M-ASP_ACTIVE', request, EndPoint, Assoc}).

-spec asp_inactive(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Requests that ASP send an ASP Inactive message to its peer.
%% @private
asp_inactive(EndPoint, Assoc) ->
	gen_server:call(m3ua, {'M-ASP_INACTIVE', request, EndPoint, Assoc}).

-spec getstat(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{stat_option(), Count}],
		Count :: non_neg_integer().
%% @doc Get socket statistics for an association.
getstat(EndPoint, Assoc)
		when is_pid(EndPoint), is_integer(Assoc) ->
	gen_server:call(m3ua, {getstat, EndPoint, Assoc, undefined}).

-spec getstat(EndPoint, Assoc, Options) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Options :: [stat_option()],
		Result :: {ok, OptionValues} | {error, inet:posix()},
		OptionValues :: [{stat_option(), Count}],
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
handle_call({start, Callback, Options}, {USAP, _Tag} = _From,
		#state{ep_sup_sup = EPSupSup, eps = EndPoints} = State) ->
	case supervisor:start_child(EPSupSup, [[Callback, Options]]) of
		{ok, EndPointSup} ->
			Find = fun F([{m3ua_listen_fsm, EP, _, _} | _]) ->
						EP;
					F([{m3ua_connect_fsm, EP, _, _} | _]) ->
						EP;
					F([_ | T]) ->
						F(T)
			end,
			EP = Find(supervisor:which_children(EndPointSup)),
			link(EP),
			NewEndPoints = gb_trees:insert(EP, USAP, EndPoints),
			NewState = State#state{eps = NewEndPoints},
			{reply, {ok, EP}, NewState};
		{error, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call({stop, EP}, From, #state{reqs = Reqs} = State) when is_pid(EP) ->
	try
		Ref = make_ref(),
		gen_fsm:send_event(EP, {'M-SCTP_RELEASE', request, Ref, self()}),
		NewReqs = gb_trees:insert(Ref, From, Reqs),
		NewState = State#state{reqs = NewReqs},
		{noreply, NewState}
	catch
		_:Reason ->
			{reply, {error, Reason}, State}
	end;
handle_call({'M-SCTP_RELEASE', request, EndPoint, Assoc},
		From, #state{reqs = Reqs, fsms = Fsms} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, Fsm} ->
			try
				Ref = make_ref(),
				gen_fsm:send_all_state_event(Fsm, {'M-SCTP_RELEASE', request, Ref, self()}),
				NewReqs = gb_trees:insert(Ref, From, Reqs),
				NewState = State#state{reqs = NewReqs},
				{noreply, NewState}
			catch
				_:Reason ->
					{reply, {error, Reason}, State}
			end;
		none ->
			{reply, {error, invalid_assoc}, State}
	end;
handle_call({'M-SCTP_STATUS', request, EndPoint, Assoc},
		From, #state{reqs = Reqs, fsms = Fsms} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, Fsm} ->
			try
				Ref = make_ref(),
				gen_fsm:send_all_state_event(Fsm, {'M-SCTP_STATUS', request, Ref, self()}),
				NewReqs = gb_trees:insert(Ref, From, Reqs),
				NewState = State#state{reqs = NewReqs},
				{noreply, NewState}
			catch
				_:Reason ->
					{reply, {error, Reason}, State}
			end;
		none ->
			{reply, {error, not_found}, State}
	end;
handle_call({'M-ASP_STATUS', request,  EndPoint, Assoc},
		From, #state{reqs = Reqs, fsms = Fsms} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, Fsm} ->
			Ref = make_ref(),
			gen_fsm:send_all_state_event(Fsm, {'M-ASP_STATUS', request, Ref, self()}),
			NewReqs = gb_trees:insert(Ref, From, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{reply, down, State}
	end;
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
		{value, Fsm} ->
			Ref = make_ref(),
			gen_fsm:send_event(Fsm,
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
handle_cast({'CONNECT', Ref, {ok, EP, AspFsm, Assoc}},
		#state{reqs = Reqs, fsms = Fsms} = State) ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, {ok, Assoc}),
			link(AspFsm),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewFsms = gb_trees:insert({EP, Assoc}, AspFsm, Fsms),
			NewState = State#state{fsms = NewFsms, reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({'CONNECT', Ref, {error, Reason}},
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
handle_cast({'M-SCTP_STATUS', confirm, Ref, Result},
		#state{reqs = Reqs} = State) ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, Result),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({'M-ASP_STATUS', confirm, Ref, Result},
		#state{reqs = Reqs} = State) ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, Result),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({'M-SCTP_RELEASE', confirm, Ref, Result},
		#state{reqs = Reqs} = State) ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, Result),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
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
handle_cast({'M-RK_REG', confirm, Ref, Asp, RegResult,
		NA, Keys, TMT, AS, EP, Assoc, CbMod, CbState}, State) ->
	reg_result(RegResult, NA, m3ua:sort(Keys), TMT,
			AS, Asp, EP, Assoc, CbMod, CbState, Ref, State);
handle_cast({'M-ASP_UP' = AspOp, confirm, Ref, {ok, CbMod, Asp, _EP, _Assoc,
		CbState, _Identifier, _Info}}, #state{reqs = Reqs} = State) ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			{ok, NewCbState} = m3ua_callback:cb(cb_func(AspOp), CbMod, [CbState]),
			ok = gen_fsm:send_all_state_event(Asp, {AspOp, NewCbState}),
			gen_server:reply(From, ok),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
handle_cast({'M-SCTP_ESTABLISH', indication, Fsm, EP, Assoc},
		#state{fsms = Fsms} = State) ->
	NewFsms = gb_trees:insert({EP, Assoc}, Fsm, Fsms),
	link(Fsm),
	{noreply, State#state{fsms = NewFsms}};
handle_cast({'M-ASP_DOWN' = AspOp, confirm, Ref, {ok, CbMod, Asp, _EP, _Assoc,
		CbState, _Identifier, _Info}}, #state{reqs = Reqs} = State) ->
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
	{ok, NewCbState} = m3ua_callback:cb(cb_func(AspOp), CbMod, [CbState]),
	ok = gen_fsm:send_all_state_event(Asp, {AspOp, NewCbState}),
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, Result),
			NewReqs = gb_trees:delete(Ref, Reqs),
			{noreply, State#state{reqs = NewReqs}};
		none ->
			{noreply, State}
	end;
handle_cast({AspOp, confirm, Ref, {ok, CbMod, Asp, _EP, _Assoc, CbState, _Identifier, _Info}},
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
	{ok, NewCbState} = m3ua_callback:cb(cb_func(AspOp), CbMod, [CbState]),
	ok = gen_fsm:send_all_state_event(Asp, {AspOp, NewCbState}),
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, Result),
			NewReqs = gb_trees:delete(Ref, Reqs),
			{noreply, State#state{reqs = NewReqs}};
		none ->
			{noreply, State}
	end;
handle_cast({'M-NOTIFY', indication, ASP, _EP, _Assoc,
		RC, Status, AspID, CbMod, CbState}, State)
		when (Status == as_inactive) orelse (Status == as_active)
		orelse (Status == as_pending) ->
	F = fun() ->
		case mnesia:read(m3ua_asp, ASP, read) of
			[] ->
				ok;
			ASPs ->
				F1 = fun(#m3ua_asp{rk = RK}) ->
					case mnesia:read(m3ua_as, RK, write) of
						[] ->
							ok;
						[#m3ua_as{} = AS] ->
							F2 = fun(as_active) ->
										active;
									(as_inactive) ->
										inactive;
									(as_pending) ->
										pending
							end,
							NewAS = AS#m3ua_as{state = F2(Status)},
							ok = mnesia:write(NewAS)
					end
				end,
				lists:foreach(F1, ASPs)
		end
	end,
	case mnesia:transaction(F) of
		{atomic, ok} ->
			CbArgs = [RC, Status, AspID, CbState],
			{ok, NewCbState} = m3ua_callback:cb(notify, CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(ASP, {'M-NOTIFY', NewCbState}),
			{noreply, State};
		{aborted, Reason} ->
			{stop, Reason, State}
	end;
handle_cast({'M-NOTIFY', indication, ASP, _EP, _Assoc,
		RC, Status, AspID, CbMod, CbState}, State)
		when (Status == insufficient_asp_active)
		orelse (Status == alternate_asp_active)
		orelse (Status == asp_failure) ->
	CbArgs = [RC, Status, AspID, CbState],
	{ok, NewCbState} = m3ua_callback:cb(notify, CbMod, CbArgs),
	ok = gen_fsm:send_all_state_event(ASP, {notify, NewCbState}),
	{noreply, State};
handle_cast({TrafficMaint, indication, Sgp, EP, Assoc, RCs, CbMod, CbState},
		State) when TrafficMaint == 'M-ASP_ACTIVE'; TrafficMaint == 'M-ASP_INACTIVE' ->
	traffic_maint(TrafficMaint, Sgp, EP, Assoc, RCs, CbMod, CbState, State);
handle_cast({StateMaint, indication, CbMod, Sgp, _EP, _Assoc, CbState}, #state{} = State) when
		StateMaint == 'M-ASP_UP'; StateMaint == 'M-ASP_DOWN' ->
 	F = fun() ->
			case mnesia:read(m3ua_asp, Sgp, write) of
				[] ->
					[];
				[#m3ua_asp{rk = RK} | _] ->
					case mnesia:read(m3ua_as, RK, write) of
						[] ->
							[];
						[#m3ua_as{asp = Asps, min_asp = Min} = AS]
								when StateMaint == 'M-ASP_DOWN' ->
							F = fun(#m3ua_as_asp{state = active}) -> true; (_) -> false end,
							Len = length(lists:filter(F, Asps)),
							case lists:keytake(Sgp, #m3ua_as_asp.fsm, Asps) of
								{value, #m3ua_as_asp{state = active} = Asp, RemAsp}
										when (Len - 1) >= Min ->
									NewAsp = Asp#m3ua_as_asp{state = inactive},
									NewAsps = [NewAsp | RemAsp],
									NewAS = AS#m3ua_as{asp = NewAsps},
									mnesia:write(NewAS),
									[];
								{value, Asp, RemAsp} ->
									NewAsp = Asp#m3ua_as_asp{state = inactive},
									NewAsps = [NewAsp | RemAsp],
									NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
									mnesia:write(NewAS),
									F2 = fun(#m3ua_as_asp{fsm = SGP, rc = RC}, Acc) ->
											[{SGP, RC, inactive} | Acc]
									end,
									lists:foldl(F2, [], NewAsps);
								false ->
									[]
							end;
						[#m3ua_as{}] when StateMaint == 'M-ASP_UP' ->
							[]
					end
			end
	end,
	case mnesia:transaction(F) of
		{atomic, NotifyFsms} ->
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(cb_func(StateMaint), CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(Sgp, {StateMaint, NewCbState}),
			F3 = fun({Fsm, RC, active}) ->
						ok = gen_fsm:send_all_state_event(Fsm, {'M-NOTIFY', 'AS_ACTIVE', RC});
					({Fsm, RC, inactive}) ->
						ok = gen_fsm:send_all_state_event(Fsm, {'M-NOTIFY', 'AS_INACTIVE', RC})
			end,
			ok = lists:foreach(F3, NotifyFsms),
			{noreply, State};
		{aborted, Reason} ->
			error_logger:error_report(["State maintenance indication failed",
						StateMaint, {reason, Reason}, {module, ?MODULE}]),
			{noreply, State}
	end;
handle_cast({'M-RK_REG', indication, RKs,
		Socket, EP, Assoc, Sgp, CbMod, CbState}, State) ->
	reg_request(RKs, Sgp, EP, Assoc, Socket, CbMod, CbState, State).

-spec handle_info(Info :: timeout | term(), State::#state{}) ->
	{noreply, NewState :: #state{}}
			| {noreply, NewState :: #state{}, timeout() | hibernate}
			| {stop, Reason :: term(), NewState :: #state{}}.
%% @doc Handle a received message.
%% @see //stdlib/gen_server:handle_info/2
%% @private
%%
handle_info({'EXIT', EP, {shutdown, {EP, _Reason}}},
		#state{eps = EPs} = State) ->
	NewEPs = gb_trees:delete(EP, EPs),
	NewState = State#state{eps = NewEPs},
	{noreply, NewState};
handle_info({'EXIT', _Pid, {shutdown, {{EP, Assoc}, _Reason}}},
		#state{fsms = Fsms} = State) ->
	NewFsms = gb_trees:delete({EP, Assoc}, Fsms),
	NewState = State#state{fsms = NewFsms},
	{noreply, NewState};
handle_info({'EXIT', Pid, _Reason},
		#state{eps = EPs, fsms = Fsms, reqs = Reqs} = State) ->
	case gb_trees:is_defined(Pid, EPs) of
		true ->
			NewState = State#state{eps = gb_trees:delete(Pid, EPs)},
			{noreply, NewState};
		false ->
			Fdel1 = fun F({Key, Fsm, _Iter}) when Fsm ==  Pid ->
						Key;
					F({_Key, _Val, Iter}) ->
						F(gb_trees:next(Iter));
					F(none) ->
						none
			end,
			Iter1 = gb_trees:iterator(Fsms),
			case Fdel1(gb_trees:next(Iter1)) of
				none ->
					Fdel2 = fun F({Key, {P, _},  _Iter}) when P ==  Pid ->
								Key;
							F({_Key, _Val, Iter}) ->
								F(gb_trees:next(Iter));
							F(none) ->
								none
					end,
					Iter2 = gb_trees:iterator(Reqs),
					case Fdel2(gb_trees:next(Iter2)) of
						none ->
							{noreply, State};
						Key2 ->
							NewReqs = gb_trees:delete(Key2, Reqs),
							NewState = State#state{reqs = NewReqs},
							{noreply, NewState}
					end;
				Key ->
					NewFsms = gb_trees:delete(Key, Fsms),
					NewState = State#state{fsms = NewFsms},
					{noreply, NewState}
			end
	end;
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
terminate(normal = _Reason, _State) ->
	ok;
terminate(shutdown = _Reason, _State) ->
	ok;
terminate({shutdown, _} = _Reason, _State) ->
	ok;
terminate(Reason, State) ->
	error_logger:error_report(["Shutdown",
			{module, ?MODULE}, {pid, self()},
			{reason, Reason}, {state, State}]).

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

%% @private
reg_request(RoutingKeys, SGP, EP, Assoc, Socket, CbMod, SGPState, State) ->
	reg_request(RoutingKeys, SGP, EP, Assoc, Socket, CbMod, SGPState, State, inactive, []).
%% @hidden
reg_request([RK | T], SGP, EP, Assoc, Socket, CbMod, SGPState, State, AsState, RegResults) ->
	try m3ua_codec:routing_key(RK)
	of
		#m3ua_routing_key{na = NA, key = Keys, tmt = Mode} = RoutingKey ->
			F = fun() ->
				case catch reg_request1(SGP, RoutingKey) of
					{reg, AsState1, RegResult1} ->
						{reg, AsState1, RegResult1};
					{not_reg, AsState1, RegResult1} ->
						{not_reg, AsState1, RegResult1};
					{error, Reason} ->
						{error, Reason}
				end
			end,
			case mnesia:transaction(F) of
				{atomic, {reg, NewAsState, RegRes}} ->
					CbArgs =	[NA, m3ua:sort(Keys), Mode, SGPState],
					case m3ua_callback:cb(cb_func('M-RK_REG'), CbMod, CbArgs) of
						{ok, NewCbState} ->
							ok = gen_fsm:send_all_state_event(SGP, {'M-RK_REG', NewCbState}),
							reg_request(T, SGP, EP, Assoc, Socket, CbMod,
									SGPState, State, NewAsState, RegRes ++ RegResults);
						{error, _Reason} ->
							reg_request(T, SGP, EP, Assoc, Socket,
									CbMod, SGPState, State, AsState, RegResults)
					end;
				{atomic, {not_reg, NewAsState, RegRes}} ->
					reg_request(T, SGP, EP, Assoc, Socket, CbMod,
							SGPState, State, NewAsState, RegRes ++ RegResults);
				{atomic, {error, _Reason}} ->
					reg_request(T, SGP, EP, Assoc, Socket,
							CbMod, SGPState, State, AsState, RegResults);
				{aborted, _Reason} ->
					reg_request(T, SGP, EP, Assoc, Socket,
							CbMod, SGPState, State, AsState, RegResults)
			end
	catch
		_:_ ->
			reg_request(T, SGP, EP, Assoc, Socket, CbMod, SGPState, State, AsState, RegResults)
	end;
reg_request([], _SGP, _EP, Assoc, Socket, _CbMod, _SGPState, State, AsState, RegResults) ->
	try
		RegResMsg = #m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = RegResults},
		RegResPacket = m3ua_codec:m3ua(RegResMsg),
		case gen_sctp:send(Socket, Assoc, 0, RegResPacket) of
			ok ->
				P0 = m3ua_codec:add_parameter(?Status, AsState, []),
				NtfyMsg = #m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = P0},
				NtfyPacket = m3ua_codec:m3ua(NtfyMsg),
				case gen_sctp:send(Socket, Assoc, 0, NtfyPacket) of
					ok ->
						inet:setopts(Socket, [{active, once}]),
						{noreply, State};
					{error, eagain} ->
						% @todo flow control
						{noreply, State};
					{error, _Reason} ->
						{noreply, State}
				end;
			{error, eagain} ->
				% @todo flow control
				{noreply, State};
			{error, _Reason} ->
				{noreply, State}
		end
	catch
		_:_ ->
			{noreply, State}
	end.
%% @hidden
reg_request1(_Sgp, #m3ua_routing_key{lrk_id = undefined, key = Keys,
		tmt = Mode, na = NA}) ->
	try
		RK = {NA, m3ua:sort(Keys), Mode},
		AsState = case mnesia:read(m3ua_as, RK) of
			[] ->
				as_inactive;
			[#m3ua_as{state = down}] ->
				as_down;
			[#m3ua_as{state = inactive}] ->
				as_inactive;
			[#m3ua_as{state = active}] ->
				as_active;
			[#m3ua_as{state = pending}] ->
				as_pending
		end,
		RegResult = #registration_result{status = unsupported_rk_parameter_field, rc = 0},
		Message = m3ua_codec:add_parameter(?RegistrationResult, RegResult, []),
		{not_reg, AsState, Message}
	catch
		_:Reason ->
			{error, Reason}
	end;
reg_request1(Sgp, #m3ua_routing_key{na = NA, key = Keys, tmt = Mode,
		rc = RC, lrk_id = LRKId}) ->
	SKeys = m3ua:sort(Keys),
	RK = {NA, SKeys, Mode},
	case mnesia:read(m3ua_as, RK, write) of
		[] when RC == undefined ->
			RC1 = erlang:phash2(rand:uniform(16#7FFFFFFF), 255),
			M3UAAsp1 = #m3ua_as_asp{fsm = Sgp, state = inactive},
			AS1 = #m3ua_as{state = inactive, routing_key = RK, asp = [M3UAAsp1]},
			Asp1 = #m3ua_asp{fsm = Sgp, rc = RC1, rk = RK},
			ok = mnesia:write(AS1),
			ok = mnesia:write(m3ua_asp, Asp1, write),
			RegRes = [{?RegistrationResult,
					#registration_result{lrk_id = LRKId, status = registered, rc = RC1}}],
			{reg, inactive, RegRes};
		[] ->
			case mnesia:read(m3ua_asp, Sgp, write) of
				[] ->
					M3UAAsp2 = #m3ua_as_asp{fsm = Sgp, state = inactive},
					AS2 = #m3ua_as{state = inactive, routing_key = RK, asp = [M3UAAsp2]},
					Asp2 = #m3ua_asp{fsm = Sgp, rc = RC, rk = RK},
					mnesia:write(AS2),
					mnesia:write(Asp2),
					RegRes = [{?RegistrationResult,
							#registration_result{lrk_id = LRKId, status = registered, rc = RC}}],
					{reg, inactive, RegRes};
				RegAsps ->
					case lists:keyfind(RC, #m3ua_asp.rc, RegAsps) of
						#m3ua_asp{rk = ExRK} = ExASP ->
							case mnesia:read(m3ua_as, ExRK, write) of
								[] ->
									M3UAAsp3 = #m3ua_as_asp{fsm = Sgp, state = inactive},
									AS3 = #m3ua_as{state = inactive, routing_key = RK, asp = [M3UAAsp3]},
									Asp3 = #m3ua_asp{fsm = Sgp, rc = RC, rk = RK},
									ok = mnesia:write(AS3),
									ok = mnesia:write(Asp3),
									RegRes = [{?RegistrationResult,
											#registration_result{lrk_id = LRKId, status = registered, rc = RC}}],
									{reg, inactive, RegRes};
								[#m3ua_as{state = State} = ExAS] ->
									NewKey = m3ua:sort(SKeys ++ element(2, ExRK)),
									AS3 = ExAS#m3ua_as{routing_key = setelement(2, ExRK, NewKey)},
									Asp3 = ExASP#m3ua_asp{rk = setelement(2, ExRK, NewKey)},
									ok = mnesia:write(AS3),
									ok = mnesia:write(Asp3),
									RegRes = [{?RegistrationResult,
											#registration_result{lrk_id = LRKId, status = registered, rc = RC}}],
									{reg, State, RegRes}
							end;
						false ->
							M3UAAsp4 = #m3ua_as_asp{fsm = Sgp, state = inactive},
							AS4 = #m3ua_as{routing_key = RK, asp = [M3UAAsp4]},
							Asp4 = #m3ua_asp{fsm = Sgp, rc = RC, rk = RK},
							ok = mnesia:write(AS4),
							ok = mnesia:write(Asp4),
							RegRes = [{?RegistrationResult,
									#registration_result{lrk_id = LRKId, status = registered, rc = RC}}],
							{reg, inactive, RegRes}
					end
			end;
		[#m3ua_as{asp = Asps, min_asp = Min, max_asp = Max, state = AsState} = AS] ->
			case lists:keyfind(Sgp, #m3ua_as_asp.fsm, Asps) of
				#m3ua_as_asp{} ->
					AlreadyReg = #registration_result{lrk_id = LRKId,
						status = rk_already_registered, rc = 0},
					AlreadyRegMsg = [{?RegistrationResult, AlreadyReg}],
					{not_reg, AsState, AlreadyRegMsg};
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
					ok = mnesia:write(AS5),
					ok = mnesia:write(Asp5),
					RegRes = [{?RegistrationResult,
							#registration_result{lrk_id = LRKId, status = registered, rc = NewRC1}}],
					{reg, NewAsState, RegRes}
			end
	end.

%% @hidden
reg_result([#registration_result{status = registered, rc = RC}],
		NA, Keys, TMT, AS, Asp, _EP, _Assoc, CbMod, CbState,  Ref,
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
			ok = gen_fsm:send_all_state_event(Asp,
					{'M-RK_REG', {RC, {NA, Keys, TMT}}}),
			{ok, RC};
		{aborted, Reason} ->
			{error, Reason}
	end,
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			CbArgs = [NA, Keys, TMT, CbState],
			{ok, NewCbState} = m3ua_callback:cb(cb_func('M-RK_REG'), CbMod, CbArgs),
			ok = gen_fsm:send_all_state_event(Asp, {'M-RK_REG', NewCbState}),
			gen_server:reply(From, Result),
			NewReqs = gb_trees:delete(Ref, Reqs),
			NewState = State#state{reqs = NewReqs},
			{noreply, NewState};
		none ->
			{noreply, State}
	end;
reg_result([#registration_result{status = Status}],
		_NA, _Keys, _TMT, _AS, _Asp, _Ep, _Assoc, _CbMod, _CbState,
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
traffic_maint(TrafficMaint, Sgp, _EP, _Assoc, RCs, CbMod, CbState, State) ->
	F = fun() -> traffic_maint1(TrafficMaint, Sgp, RCs) end,
	case mnesia:transaction(F) of
		{atomic, Fsms} ->
			CbArgs = [CbState],
			case m3ua_callback:cb(cb_func(TrafficMaint), CbMod, CbArgs) of
				{ok, NewCbState} ->
					ok = gen_fsm:send_all_state_event(Sgp, {TrafficMaint, NewCbState}),
					F2 = fun({Fsm, RC, active}) ->
								gen_fsm:send_all_state_event(Fsm, {'M-NOTIFY', 'AS_ACTIVE', RC});
							({Fsm, RC, inactive}) ->
								gen_fsm:send_all_state_event(Fsm, {'M-NOTIFY', 'AS_INACTIVE', RC})
					end,
					ok = lists:foreach(F2, Fsms),
					{noreply, State};
				{error, _Reason} ->
					{noreply, State}
			end;
		{aborted, _Reason} ->
			{noreply, State}
	end.
%% @hidden
traffic_maint1(TrafficMaint, Sgp, RCs) ->
	case mnesia:read(m3ua_asp, Sgp, write) of
		[] ->
			[];
		Asps ->
			FilteredAsps = filter_asps(RCs, Asps),
			traffic_maint2(FilteredAsps, TrafficMaint, Sgp, [])
	end.
%% @hidden
traffic_maint2([], _TrafficMaint, _Sgp, Notify) ->
	Notify;
traffic_maint2([#m3ua_asp{rk = RK, rc = RC} | T], TrafficMaint, Sgp, Notify) ->
	case mnesia:read(m3ua_as, RK, write) of
		[] ->
			traffic_maint2(T, TrafficMaint, Sgp, Notify);
		[#m3ua_as{state = active, asp = M3uaAsps} = AS] when TrafficMaint == 'M-ASP_ACTIVE'->
			case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
				{value, M_Asp, RemAsps} ->
					NewAsps = [M_Asp#m3ua_as_asp{state = active} | RemAsps],
					NewAS = AS#m3ua_as{asp = NewAsps},
					ok = mnesia:write(NewAS),
					traffic_maint2(T, TrafficMaint, Sgp, Notify);
				false ->
					traffic_maint2(T, TrafficMaint, Sgp, Notify)
			end;
		[#m3ua_as{state = active, min_asp = Min, asp = M3uaAsps} = AS]
				when TrafficMaint == 'M-ASP_INACTIVE'->
			F3 = fun(#m3ua_as_asp{state = active}) -> true; (_) -> false end,
			AspLen = length(lists:filter(F3, M3uaAsps)),
			case AspLen of
				Len when (Len - 1) < Min ->
					case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
						{value, M_Asp, RemAsps} ->
							NewAsps = [M_Asp#m3ua_as_asp{state = inactive} | RemAsps],
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							ok = mnesia:write(NewAS),
							NewNotify = fold_notify(M3uaAsps, RC, inactive, Notify),
							traffic_maint2(T, TrafficMaint, Sgp, NewNotify);
						false ->
							traffic_maint2(T, TrafficMaint, Sgp, Notify)
					end;
				_ ->
					case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
						{value, M_Asp, RemAsps} ->
							NewAsps = [M_Asp#m3ua_as_asp{state = inactive} | RemAsps],
							NewAS = AS#m3ua_as{asp = NewAsps},
							ok = mnesia:write(NewAS),
							traffic_maint2(T, TrafficMaint, Sgp, Notify);
						false ->
							traffic_maint2(T, TrafficMaint, Sgp, Notify)
					end
			end;
		[#m3ua_as{min_asp = Min, max_asp = Max, asp = M3uaAsps} = AS]
				when TrafficMaint == 'M-ASP_ACTIVE'->
			F3 = fun(#m3ua_as_asp{state = active}) -> true; (_) -> false end,
			AspLen = length(lists:filter(F3, M3uaAsps)),
			case AspLen of
				Len when (Len + 1) >= Min, ((Max == undefined) or (Max >= (Len + 1))) ->
					case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
						{value, M_Asp, RemAsps} ->
							NewAsps = [M_Asp#m3ua_as_asp{state = active} | RemAsps],
							NewAS = AS#m3ua_as{state = active, asp = NewAsps},
							ok = mnesia:write(NewAS),
							NewNotify = fold_notify(M3uaAsps, RC, active, Notify),
							traffic_maint2(T, TrafficMaint, Sgp, NewNotify);
						false ->
							traffic_maint2(T, TrafficMaint, Sgp, Notify)
					end;
				_Len ->
					case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
						{value, M_Asp, RemAsps} when AS#m3ua_as.state == inactive ->
							NewAsps = [M_Asp#m3ua_as_asp{state = active} | RemAsps],
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							ok = mnesia:write(NewAS),
							traffic_maint2(T, TrafficMaint, Sgp, Notify);
						{value, M_Asp, RemAsps} ->
							NewAsps = [M_Asp#m3ua_as_asp{state = active} | RemAsps],
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							ok = mnesia:write(NewAS),
							NewNotify = fold_notify(M3uaAsps, RC, inactive, Notify),
							traffic_maint2(T, TrafficMaint, Sgp, NewNotify);
						false ->
							traffic_maint2(T, TrafficMaint, Sgp, Notify)
					end
			end;
		[#m3ua_as{asp = M3uaAsps} = AS] when TrafficMaint == 'M-ASP_INACTIVE'->
				case lists:keytake(Sgp, #m3ua_as_asp.fsm, M3uaAsps) of
					{value, M_Asp, RemAsps} ->
						NewAsps = [M_Asp#m3ua_as_asp{state = inactive} | RemAsps],
						NewAS = AS#m3ua_as{asp = NewAsps},
						ok = mnesia:write(NewAS),
						traffic_maint2(T, TrafficMaint, Sgp, Notify);
					false ->
						traffic_maint2(T, TrafficMaint, Sgp, Notify)
				end
	end.
	
%% @private
cb_func('M-ASP_UP') -> asp_up;
cb_func('M-ASP_DOWN') -> asp_down;
cb_func('M-ASP_ACTIVE') -> asp_active;
cb_func('M-ASP_INACTIVE') -> asp_inactive;
cb_func('M-RK_REG') -> register.

-spec filter_asps(RCs, Asps) -> FilteredAsps
	when
		RCs :: [pos_integer()] | undefined,
		Asps :: [#m3ua_asp{}],
		FilteredAsps :: [#m3ua_asp{}].
%% @doc Filter matching ASPs with Routing Context
%% @private
%%
filter_asps(undefined, Asps) ->
	Asps;
filter_asps(RCs, Asps) ->
	filter_asps1(RCs, Asps, []).
%% @hidden
filter_asps1([RC | T], Asps, Acc) ->
	case lists:keyfind(RC, #m3ua_asp.rc, Asps) of
		#m3ua_asp{} = Asp ->
			filter_asps1(T, Asps, [Asp | Acc]);
		false ->
			filter_asps1(T, Asps, Acc)
	end;
filter_asps1([], _Asps, Acc) ->
	lists:reverse(Acc).

fold_notify([#m3ua_as_asp{fsm = Fsm} | T], RC, State, FoldNotify) ->
	fold_notify(T, RC, State, fold_notify1(Fsm, RC, State, FoldNotify, []));
fold_notify([], _RC, _State, FoldNotify) ->
	FoldNotify.
%% @hidden
fold_notify1(Fsm, RC, State, [{Fsm, RC, _} | T], Acc) ->
	lists:reverse(Acc) ++ [{Fsm, RC, State} | T];
fold_notify1(Fsm, RC, State, [H | T], Acc) ->
	fold_notify1(Fsm, RC, State, T, [H | Acc]);
fold_notify1(Fsm, RC, State, [], Acc) ->
	lists:reverse([{Fsm, RC, State} | Acc]).

