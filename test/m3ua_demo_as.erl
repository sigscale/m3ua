%%% m3ua_demo_as.erl
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
-module(m3ua_demo_as).

-behaviour(m3ua_asp_fsm).

-include("m3ua.hrl").

-export([init/5, transfer/9, pause/4, resume/4, status/4,
		register/5, terminate/2]).
-export([asp_up/1, asp_down/1, asp_active/1, asp_inactive/1, notify/4]).

%%----------------------------------------------------------------------
%%  The m3ua_demo_as API
%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%%  The m3ua_asp_fsm callback
%%----------------------------------------------------------------------

init(_Module, _Asp, _EP, _EpName, _Assoc) ->
	{ok, []}.

transfer(_Stream, _RC, _OPC, _DPC, _NI, _SI, _SLS, _Data, State) ->
	{ok, State}.

pause(_Stream, _RCs, _DPCs, State) ->
	{ok, State}.

resume(_Stream, _RCs, _DPCs, State) ->
	{ok, State}.

status(_Stream, _RCs, _DPCs, State) ->
	{ok, State}.

register(_RC, _NA, _Keys, _TMT, State) ->
	{ok, State}.

asp_up(State) ->
	{ok, State}.

asp_down(State) ->
	{ok, State}.

asp_active(State) ->
	{ok, State}.

asp_inactive(State) ->
	{ok, State}.

notify(_RCs, _Status, _AspID, State) ->
	{ok, State}.

terminate(_Reason, _State) ->
	ok.

