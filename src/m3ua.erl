%%% m3ua.erl
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
%%% @doc This library module implements the public API for the
%%% 	{@link //m3ua. m3ua} application.
%%%
-module(m3ua).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

%% export the m3ua public API
-export([open/0, close/1]).

%%----------------------------------------------------------------------
%%  The m3ua API
%%----------------------------------------------------------------------

-spec open() -> {ok, EndPoint :: pid()} | {error, Reason :: term()}.
%% @doc Create a new endpoint for a server.
open() ->
	m3ua_lm_server:open([]).

-spec close(EndPoint:: pid()) -> ok | {error, Reason :: term()}.
%% @doc Close a previously opened end point.
close(EP) when is_pid(EP) ->
	m3ua_lm_server:close(EP).


%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

