%%% demo_as.erl
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
%%%
-module(demo_as).

-behaviour(m3ua_asp_fsm).

-include("m3ua.hrl").

-export([init/4, transfer/11, pause/7, resume/7, status/7,
		register/7, terminate/5]).
-export([asp_up/4, asp_down/4, asp_active/4, asp_inactive/4]).

%%----------------------------------------------------------------------
%%  The demo_as API 
%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%%  The m3ua_asp_fsm callback 
%%----------------------------------------------------------------------

init(_Module, _Asp, _EP, _Assoc) ->
	{ok, []}.

transfer(_Asp, _EP, _Assoc, Stream, _RK, OPC, DPC, SLS, SIO, Data, State) ->
	Msg = {Stream, OPC, DPC, SLS, SIO, Data},
%	State ! {asp, transfer, Msg},
	{ok, State}.

pause(_Asp, _EP, _Assoc, _Stream, _RK, _DPCs, State) ->
	{ok, State}.

resume(_Asp, _EP, _Assoc, _Stream, _RK, _DPCs, State) ->
	{ok, State}.

status(_Asp, _EP, _Assoc, _Stream, _RK, _DPCs, State) ->
	{ok, State}.

register(_Asp, _EP, _Assoc, _NA, _Keys, _TMT, State) ->
	{ok, State}.

asp_up(_Asp, _EP, _Assoc, State) ->
	{ok, State}.

asp_down(_Asp, _EP, _Assoc, State) ->
	{ok, State}.

asp_active(Asp, _EP, _Assoc, PID) ->
%	PID ! {asp, active, Asp},
	{ok, PID}.

asp_inactive(_Asp, _EP, _Assoc, State) ->
	{ok, State}.

terminate(_Asp, _EP, _Assoc, _Reason, _State) ->
	ok.

