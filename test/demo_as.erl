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

-export([transfer/10, pause/6, resume/6, status/6]).
-export([asp_up/4, asp_down/4, asp_active/4, asp_inactive/4]).

%%----------------------------------------------------------------------
%%  The demo_as API 
%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%%  The m3ua_asp_fsm callback 
%%----------------------------------------------------------------------

transfer(Sgp, EP, Assoc, Stream, OPC, DPC, SLS, SIO, Data, State) ->
	Msg = {Stream, OPC, DPC, SLS, SIO, Data},
	State ! {asp, transfer, Msg},
	{ok, State}.

pause(Sgp, _EP, _Assoc, _Stream, _DPCs, State) ->
	{ok, State}.

resume(Sgp, _EP, _Assoc, _Stream, _DPCs, State) ->
	{ok, State}.

status(Sgp, _EP, _Assoc, _Stream, _DPCs, State) ->
	{ok, State}.

asp_up(Sgp, _EP, _Assoc, State) ->
	{ok, State}.

asp_down(Sgp, _EP, _Assoc, State) ->
	{ok, State}.

asp_active(Sgp, _EP, _Assoc, PID) ->
	PID ! {asp, active, Sgp},
	{ok, PID}.

asp_inactive(Sgp, _EP, _Assoc, State) ->
	{ok, State}.

