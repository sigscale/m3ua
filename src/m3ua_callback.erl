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
%%%		m3ua_[asp | sgp]_fsm
%%%
-module(m3ua_callback).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

%% export the m3ua_callback public API
-export([init/3, transfer/11, pause/7, resume/7, status/7,
		register/7, asp_up/4, asp_down/4, asp_active/4,
		asp_inactive/4]).

%% export the m3ua_callback private API
-export([cb/3]).

-include("m3ua.hrl").

%%----------------------------------------------------------------------
%%  The m3ua_callback public API
%%----------------------------------------------------------------------
-spec init(Fsm, EP, Assoc) -> Result
	when
		Fsm :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		Result :: {ok, State} | {error, Reason},
		State :: term(),
		Reason :: term().
init(_Fsm, _EP, _Assoc) ->
	{ok, []}.

-spec transfer(Fsm, EP, Assoc, Stream, RC, OPC, DPC, SLS, SIO, Data, State) -> Result
	when
		Fsm :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		RC :: undefined | pos_integer(),
		OPC :: pos_integer(),
		DPC :: pos_integer(),
		SLS :: non_neg_integer(),
		SIO :: non_neg_integer(),
		Data :: binary(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
transfer(_Fsm, _EP, _Assoc, _Stream,
		_RK, _OPC, _DPC, _SLS, _SIO, _Data, State) ->
	{ok, State}.

-spec pause(Fsm, EP, Assoc, Stream, RC, DPCs, State) -> Result
	when
		Fsm :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		DPCs :: [DPC],
		RC :: undefined | pos_integer(),
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
pause(_Fsm, _EP, _Assoc, _Stream, _RK, _DPCs, State) ->
	{ok, State}.

-spec resume(Fsm, EP, Assoc, Stream, RC, DPCs, State) -> Result
	when
		Fsm :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		DPCs :: [DPC],
		RC :: undefined | pos_integer(),
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
resume(_Fsm, _EP, _Assoc, _Stream, _RK, _DPCs, State) ->
	{ok, State}.

-spec status(Fsm, EP, Assoc, Stream, RC, DPCs, State) -> Result
	when
		Fsm :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		Stream :: pos_integer(),
		DPCs :: [DPC],
		RC :: undefined | pos_integer(),
		DPC :: pos_integer(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
status(_Fsm, _EP, _Assoc, _Stream, _RK, _DPCs, State) ->
	{ok, State}.

-spec register(Asp, EP, Assoc, NA, Keys, TMT, State) -> Result
	when
		Asp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		NA :: pos_integer(),
		Keys :: [key()],
		TMT :: tmt(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
register(_Fsm, _EP, _Assoc, _NA, _Keys, _TMT, State) ->
	{ok, State}.

-spec asp_up(Asp, EP, Assoc, State) -> Result
	when
		Asp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		State :: term(),
		Result :: {ok, State}.
asp_up(_Fsm, _EP, _Assoc, State) ->
	{ok, State}.

-spec asp_down(Asp, EP, Assoc, State) -> Result
	when
		Asp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		State :: term(),
		Result :: {ok, State}.
asp_down(_Fsm, _EP, _Assoc, State) ->
	{ok, State}.

-spec asp_active(Asp, EP, Assoc, State) -> Result
	when
		Asp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		State :: term(),
		Result :: {ok, State}.
asp_active(_Fsm, _EP, _Assoc, State) ->
	{ok, State}.

-spec asp_inactive(Asp, EP, Assoc, State) -> Result
	when
		Asp :: pid(),
		EP :: pid(),
		Assoc :: pos_integer(),
		State :: term(),
		Result :: {ok, State}.
asp_inactive(_Fsm, _EP, _Assoc, State) ->
	{ok, State}.

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
cb(transfer, #m3ua_fsm_cb{transfer = false}, Args) ->
	apply(?MODULE, transfer, Args);
cb(transfer, #m3ua_fsm_cb{transfer = F, extra = E}, Args) ->
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
	apply(F, Args ++ E).
