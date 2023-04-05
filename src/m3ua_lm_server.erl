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
-export([register/7]).
-export([as_add/7, as_delete/1]).
-export([asp_status/2, asp_up/2, asp_down/2, asp_active/2,
			asp_inactive/2]).
-export([getstat/2, getstat/3, getcount/2]).

%% export the callbacks needed for gen_server behaviour
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
			terminate/2, code_change/3]).

-record(state,
		{sup :: undefined | pid(),
		ep_sup_sup :: undefined | pid(),
		eps = gb_trees:empty() :: gb_trees:tree(EP :: pid(),
				USAP :: pid()),
		fsms = gb_trees:empty() :: gb_trees:tree(EP :: pid(),
				Assoc :: gen_sctp:assoc_id()),
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

-spec as_add(Name, RC, NA, Keys, Mode, MinASP, MaxASP) -> Result
	when
		Name :: term(),
		RC :: 0..4294967295,
		NA :: 0..4294967295 | undefined,
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
as_add(Name, RC, NA, Keys, Mode, MinASP, MaxASP)
		when is_integer(RC),
		((NA == undefined) orelse is_integer(NA)),
		is_list(Keys), is_atom(Mode),
		is_integer(MinASP), is_integer(MaxASP) ->
	gen_server:call(m3ua, {as_add,
			Name, RC, NA, Keys, Mode, MinASP, MaxASP}).

-spec as_delete(RC) -> Result
	when
		RC :: 0..4294967295,
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Delete an Application Server (AS).
as_delete(RC) ->
	gen_server:call(m3ua, {as_delete, RC}).

-spec register(EndPoint, Assoc, RoutingContext, NA, Keys, Mode, AsName) ->
		Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		RoutingContext :: undefined | non_neg_integer(),
		NA :: pos_integer(),
		Keys :: [Key],
		Key :: {DPC, [SI], [OPC]},
		DPC :: pos_integer(),
		SI :: pos_integer(),
		OPC :: pos_integer(),
		Mode :: override | loadshare | broadcast,
		AsName :: term(),
		Result :: {ok, NewRoutingContext} | {error, Reason},
		NewRoutingContext :: non_neg_integer(),
		Reason :: term().
%% @doc Register a routing key for an application server.
register(EndPoint, Assoc, RoutingContext, NA, Keys, Mode, AsName) ->
	gen_server:call(m3ua, {'M-RK_REG', request,
			EndPoint, Assoc, RoutingContext, NA, Keys, Mode, AsName}).

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
		Result :: {ok, AssocStatus} | {error, Reason},
		AssocStatus :: #sctp_status{},
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

-spec getcount(EndPoint, Assoc) -> Result
	when
		EndPoint :: pid(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: {ok, Counts} | {error, inet:posix()},
		Counts :: #{atom() => non_neg_integer()}.
%% @doc Get M3UA statistics for an association.
getcount(EndPoint, Assoc)
		when is_pid(EndPoint), is_integer(Assoc) ->
	gen_server:call(m3ua, {getcount, EndPoint, Assoc}).

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
handle_call({as_add, Name, RC, NA, Keys, Mode, MinASP, MaxASP}, _From, State) ->
	F = fun() ->
				SortedKeys = m3ua:sort(Keys),
				AS = #m3ua_as{rc = RC, rk = {NA, SortedKeys, Mode},
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
handle_call({as_delete, RC}, _From, State) ->
	F = fun() ->
				mnesia:delete(m3ua_as, RC, write)
	end,
	case mnesia:transaction(F) of
		{atomic, ok} ->
			{reply, ok, State};
		{aborted, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call({'M-RK_REG', request, EndPoint, Assoc,
		RC, NA, Keys, Mode, AsName}, From,
		#state{fsms = Fsms, reqs = Reqs} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, Fsm} ->
			Ref = make_ref(),
			gen_fsm:send_event(Fsm, {'M-RK_REG', request,
					Ref, self(), RC, NA, Keys, Mode, AsName}),
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
			case catch gen_fsm:sync_send_all_state_event(Fsm, Event) of
				{'EXIT', Reason} ->
					{reply, {error, Reason}, State};
				Reply ->
					{reply, Reply, State}
			end;
		none ->
			{reply, {error, not_found}, State}
	end;
handle_call({getcount, EndPoint, Assoc}, _From,
		#state{fsms = Fsms} = State) ->
	case gb_trees:lookup({EndPoint, Assoc}, Fsms) of
		{value, Fsm} ->
			case catch gen_fsm:sync_send_all_state_event(Fsm, getcount) of
				{'EXIT', Reason} ->
					{reply, {error, Reason}, State};
				Reply ->
					{reply, {ok, Reply}, State}
			end;
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
handle_cast({_AspOp, confirm, Ref, {error, Reason}},
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
handle_cast({'M-RK_REG', confirm, Ref, Result},
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
handle_cast({'M-SCTP_ESTABLISH', indication, Fsm, EP, Assoc},
		#state{fsms = Fsms} = State) ->
	NewFsms = gb_trees:insert({EP, Assoc}, Fsm, Fsms),
	link(Fsm),
	{noreply, State#state{fsms = NewFsms}};
handle_cast({AspOp, confirm, Ref, Result},
		#state{reqs = Reqs} = State)
		when AspOp == 'M-ASP_DOWN'; AspOp == 'M-ASP_UP';
		AspOp == 'M-ASP_INACTIVE'; AspOp == 'M-ASP_ACTIVE' ->
	case gb_trees:lookup(Ref, Reqs) of
		{value, From} ->
			gen_server:reply(From, Result),
			NewReqs = gb_trees:delete(Ref, Reqs),
			{noreply, State#state{reqs = NewReqs}};
		none ->
			{noreply, State}
	end.

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
	{noreply, NewState};
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
	end.

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

