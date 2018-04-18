%%% m3ua_endpoint_sup.erl
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
%%% @docfile "{@docsrc supervision.edoc}"
%%%
-module(m3ua_endpoint_sup).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

-behaviour(supervisor).

%% export the callback needed for supervisor behaviour
-export([init/1]).

%%----------------------------------------------------------------------
%%  The supervisor callback
%%----------------------------------------------------------------------

-spec init(Args :: [term()]) ->
	{ok, {{supervisor:strategy(), non_neg_integer(), pos_integer()},
			[supervisor:child_spec()]}} | ignore.
%% @doc Initialize the {@module} supervisor.
%% @see //stdlib/supervisor:init/1
%% @private
%%
init([Callback, Opts] = _Args) ->
	ChildSpec2 = case lists:keyfind(role, 1, Opts) of
		{role, sgp} ->
			supervisor(m3ua_sgp_sup, []);
		{role, asp} ->
			supervisor(m3ua_asp_sup, []);
		false ->
			supervisor(m3ua_sgp_sup, [])
	end,
	case lists:keyfind(connect, 1, Opts) of
		{connect, _, _, _} ->
			ChildSpec1 = fsm(m3ua_connect_fsm, [self(), Callback, Opts]),
			{ok, {{one_for_all, 10, 60}, [ChildSpec1, ChildSpec2]}};
		false ->
			ChildSpec1 = fsm(m3ua_listen_fsm, [self(), Callback, Opts]),
			{ok, {{one_for_all, 10, 60}, [ChildSpec1, ChildSpec2]}}
	end.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

-spec supervisor(StartMod :: atom(), Args :: [term()]) ->
	supervisor:child_spec().
%% @doc Build a supervisor child specification for a
%% 	{@link //stdlib/supervisor. supervisor} behaviour.
%% @private
%%
supervisor(StartMod, Args) ->
	StartArgs = [StartMod, Args],
	StartFunc = {supervisor, start_link, StartArgs},
	{StartMod, StartFunc, permanent, infinity, supervisor, [StartMod]}.

-spec fsm(StartMod :: atom(), Args :: [term()]) ->
	supervisor:child_spec().
%% @doc Build a supervisor child specification for a
%% 	{@link //stdlib/gen_fsm. gen_fsm} behaviour.
%% @private
fsm(StartMod, Args) ->
	StartArgs = [StartMod, Args, []],
	StartFunc = {gen_fsm, start_link, StartArgs},
	{StartMod, StartFunc, transient, 4000, worker, [StartMod]}.

