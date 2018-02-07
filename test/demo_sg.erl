%%% demo_sg.erl
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
-module(demo_sg).

-behaviour(m3ua_sgp_fsm).

-export([transfer/11, pause/7, resume/7, status/7]).
-export([asp_up/4, asp_down/4, asp_active/4, asp_inactive/4]).

%%----------------------------------------------------------------------
%%  The demo_sg API 
%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%%  The m3ua_sgp_fsm callback 
%%----------------------------------------------------------------------

transfer(Sgp, _EP, Assoc, Stream, _RK, OPC, DPC, SLS, SIO, Data, State) ->
	Args = [Sgp, Assoc, Stream, DPC, OPC, SLS, SIO, Data],
	proc_lib:spawn(m3ua_sgp_fsm, transfer, Args),	
	{ok, State}.

pause(_Sgp, _EP, _Assoc, _Stream, _RK, _DPCs, State) ->
	{ok, State}.

resume(_Sgp, _EP, _Assoc, _Stream, _RK, _DPCs, State) ->
	{ok, State}.

status(_Sgp, _EP, _Assoc, _Stream, _RK, _DPCs, State) ->
	{ok, State}.

asp_up(_Sgp, _EP, _Assoc, State) ->
	State ! {sgp, asp_up, indication},
	{ok, State}.

asp_down(_Sgp, _EP, _Assoc, State) ->
	State ! {sgp, asp_down, indication},
	{ok, State}.

asp_active(_Sgp, _EP, _Assoc, State) ->
	State ! {sgp, asp_active, indication},
	{ok, State}.

asp_inactive(_Sgp, _EP, _Assoc, State) ->
	State ! {sgp, asp_inactive, indication},
	{ok, State}.

