%%% m3ua_callback.erl
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
%%% @doc This library module implements the default callback for the
%%%		m3ua_[asp|sgp]_fsm.
%%%
-module(m3ua_callback).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

%% export the m3ua_callback public API
-export([init/6, recv/9, send/11, pause/4, resume/4, status/4,
		register/5, asp_up/1, asp_down/1, asp_active/1,
		asp_inactive/1, notify/4, info/2, terminate/2]).

%% export the m3ua_callback private API
-export([cb/3]).

-include("m3ua.hrl").

%%----------------------------------------------------------------------
%%  The m3ua_callback public API
%%----------------------------------------------------------------------
-spec init(Module, Fsm, EP, EpName, Assoc, Options) -> Result
	when
		Module :: atom(),
		Fsm :: pid(),
		EP :: pid(),
		EpName :: term(),
		Assoc :: gen_sctp:assoc_id(),
		Options :: term(),
		Result :: {ok, Active, State} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		State :: term(),
		Reason :: term().
init(_Module, _Fsm, _EP, _EpName, _Assoc, _Options) ->
	{ok, once, []}.

-spec recv(Stream, RC, OPC, DPC, NI, SI, SLS, Data, State) -> Result
	when
		Stream :: pos_integer(),
		RC :: undefined | 0..4294967295,
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
recv(_Stream, _RC, _OPC, _DPC, _NI, _SI, _SLS, _Data, State) ->
	{ok, once, State}.

-spec send(From, Ref, Stream, RC, OPC, DPC, NI, SI, SLS, Data, State) -> Result
	when
		From :: pid(),
		Ref :: reference(),
		Stream :: pos_integer(),
		RC :: undefined | 0..4294967295,
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
send(_From, _Ref, _Stream, _RC, _OPC, _DPC, _NI, _SI, _SLS, _Data, State) ->
	{ok, once, State}.

-spec pause(Stream, RC, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		DPCs :: [DPC],
		RC :: undefined | 0..4294967295,
		DPC :: 0..16777215,
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
pause(_Stream, _RK, _DPCs, State) ->
	{ok, State}.

-spec resume(Stream, RC, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		DPCs :: [DPC],
		RC :: undefined | 0..4294967295,
		DPC :: 0..16777215,
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
resume(_Stream, _RK, _DPCs, State) ->
	{ok, State}.

-spec status(Stream, RC, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		DPCs :: [DPC],
		RC :: undefined | 0..4294967295,
		DPC :: 0..16777215,
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
status(_Stream, _RK, _DPCs, State) ->
	{ok, State}.

-spec register(RC, NA, Keys, TMT, State) -> Result
	when
		RC :: undefined | 0..4294967295,
		NA :: undefined | 0..4294967295,
		Keys :: [m3ua:key()],
		TMT :: m3ua:tmt(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
register(_RC, _NA, _Keys, _TMT, State) ->
	{ok, State}.

-spec asp_up(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
asp_up(State) ->
	{ok, State}.

-spec asp_down(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
asp_down(State) ->
	{ok, State}.

-spec asp_active(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
asp_active(State) ->
	{ok, State}.

-spec asp_inactive(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
asp_inactive(State) ->
	{ok, State}.

-spec notify(RCs, Status, AspID, State) -> Result
	when
		RCs :: [RC] | undefined,
		RC :: 0..4294967295,
		Status :: as_inactive | as_active | as_pending
				| insufficient_asp_active | alternate_asp_active
				| asp_failure,
		AspID :: undefined | pos_integer(),
		State :: term(),
		Result :: {ok, State}.
notify(_RCs, _Status, _AspID, State) ->
	{ok, State}.

-spec info(Info, State) -> Result
	when
		Info :: term(),
		State :: term(),
		Result :: {ok, Active, NewState} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		NewState :: term(),
		Reason :: term().
info(_Info, State) ->
	{ok, once, State}.

-spec terminate(Reason, State) -> Result
	when
		Reason :: term(),
		State :: term(),
		Result :: any().
terminate(_Reason, _State) ->
	ok.

%%----------------------------------------------------------------------
%%  The m3ua_callback private API
%%----------------------------------------------------------------------

-spec cb(Handler, Cb, Args) -> Result
	when
		Handler :: atom(),
		Cb :: atom() | #m3ua_fsm_cb{},
		Args :: [term()],
		Result :: term().
%% @private
cb(Handler, Cb, Args) when is_atom(Cb) ->
	apply(Cb, Handler, Args);
cb(init, #m3ua_fsm_cb{init = false}, Args) ->
	apply(?MODULE, init, Args);
cb(init, #m3ua_fsm_cb{init = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(recv, #m3ua_fsm_cb{recv = false}, Args) ->
	apply(?MODULE, recv, Args);
cb(recv, #m3ua_fsm_cb{recv = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(send, #m3ua_fsm_cb{send = false}, Args) ->
	apply(?MODULE, send, Args);
cb(send, #m3ua_fsm_cb{send = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(pause, #m3ua_fsm_cb{pause = false}, Args) ->
	apply(?MODULE, pause, Args);
cb(pause, #m3ua_fsm_cb{pause = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(resume, #m3ua_fsm_cb{resume = false}, Args) ->
	apply(?MODULE, resume, Args);
cb(resume, #m3ua_fsm_cb{resume = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(status, #m3ua_fsm_cb{status = false}, Args) ->
	apply(?MODULE, status, Args);
cb(status, #m3ua_fsm_cb{status = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(register, #m3ua_fsm_cb{register = false}, Args) ->
	apply(?MODULE, register, Args);
cb(register, #m3ua_fsm_cb{register = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(asp_up, #m3ua_fsm_cb{asp_up = false}, Args) ->
	apply(?MODULE, asp_up, Args);
cb(asp_up, #m3ua_fsm_cb{asp_up = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(asp_down, #m3ua_fsm_cb{asp_down = false}, Args) ->
	apply(?MODULE, asp_down, Args);
cb(asp_down , #m3ua_fsm_cb{asp_down = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(asp_active, #m3ua_fsm_cb{asp_active = false}, Args) ->
	apply(?MODULE, asp_active, Args);
cb(asp_active, #m3ua_fsm_cb{asp_active = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(asp_inactive, #m3ua_fsm_cb{asp_inactive = false}, Args) ->
	apply(?MODULE, asp_inactive, Args);
cb(asp_inactive, #m3ua_fsm_cb{asp_inactive = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(notify, #m3ua_fsm_cb{notify = false}, Args) ->
	apply(?MODULE, notify, Args);
cb(notify, #m3ua_fsm_cb{notify = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(info, #m3ua_fsm_cb{info = false}, Args) ->
	apply(?MODULE, info, Args);
cb(info, #m3ua_fsm_cb{info = F, extra = E}, Args) ->
	apply(F, Args ++ E);
cb(terminate, #m3ua_fsm_cb{terminate = false}, Args) ->
	apply(?MODULE, terminate, Args);
cb(terminate, #m3ua_fsm_cb{terminate = F, extra = E}, Args) ->
	apply(F, Args ++ E).

