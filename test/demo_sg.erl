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

-export([transfer/10, pause/6, resume/6, status/6]).
-export([asp_up/4, asp_down/4, asp_active/4, asp_inactive/4]).

%%----------------------------------------------------------------------
%%  The demo_sg API 
%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%%  The m3ua_sgp_fsm callback 
%%----------------------------------------------------------------------

transfer(Sgp, EP, Assoc, Stream, OPC, DPC, SLS, SIO, Data, State) ->
	Args = [Sgp, Assoc, Stream, DPC, OPC, SLS, SIO, Data],
	proc_lib:spawn(m3ua_sgp_fsm, transfer, Args),	
	{ok, Sgp}.

pause(Sgp, _EP, _Assoc, _Stream, _DPCs, State) ->
	{ok, State}.

resume(Sgp, _EP, _Assoc, _Stream, _DPCs, State) ->
	{ok, State}.

status(Sgp, _EP, _Assoc, _Stream, _DPCs, State) ->
	{ok, State}.

asp_up(Sgp, EP, Assoc, State) ->
	{ok, State}.

asp_down(Sgp, EP, Assoc, State) ->
	{ok, State}.

asp_active(Sgp, EP, Assoc, State) ->
	{ok, State}.

asp_inactive(Sgp, EP, Assoc, State) ->
	{ok, State}.
