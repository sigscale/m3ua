%%% m3ua_rest_prometheus.erl
%%% vim: ts=3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2016 - 2018 SigScale Global Inc.
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
%%% @doc This library module implements resource handling functions
%%% 	for a REST server in the {@link //ocs. ocs} application.
%%%
%%% This module exports metrics for Prometheus server to "scrape".
%%%
%%% @ref <a href="https://github.com/prometheus/prometheus">Prometheus.io</a>.
%%%
-module(m3ua_rest_prometheus).
-copyright('Copyright (c) 2016 - 2018 SigScale Global Inc.').

-export([content_types_accepted/0, content_types_provided/0,
		get_metrics/2]).

-include("m3ua.hrl").

-spec content_types_accepted() -> ContentTypes
	when
		ContentTypes :: [string()].
%% @doc Provide list of resource representations accepted.
content_types_accepted() ->
	[].

-spec content_types_provided() -> ContentTypes
	when
		ContentTypes :: [string()].
%% @doc Provides list of resource representations available.
content_types_provided() ->
	["text/plain"].

-spec get_metrics(Query, Headers) -> Result
	when
		Query :: [{Key :: string(), Value :: string()}],
		Headers :: [tuple()],
		Result :: {ok, Headers :: [tuple()], Body :: iolist()}
				| {error, ErrorCode :: integer()}.
%% @doc Body producing function for `GET /metrics'
%% requests.
get_metrics([] = _Query, _Headers) ->
	Body = [as_state()],
	{ok, [], Body}.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

%% @hidden
as_state() ->
	as_state(m3ua:get_as()).
%% @hidden
as_state({ok, []}) ->
	[];
as_state({ok, AS}) ->
	HELP = ["# HELP stc_m3ua_as_state The current state of an "
			"Application Server (AS).\n",
			"# TYPE stc_m3ua_as_state guage\n"],
	as_state(AS, [HELP]);
as_state({error, Reason}) ->
	error_logger:error_report(["Failed to get AS",
			{module, ?MODULE}, {error, Reason}]),
	[].
%% @hidden
as_state([{Name, _, _, _, _, _, State} | T], Acc) ->
	NewAcc = as_state1(Name, State, Acc),
	as_state(T, NewAcc);
as_state([], Acc) ->
	lists:reverse(["\n" | Acc]).
%% @hidden
as_state1(Name, State, Acc) when is_atom(Name) ->
	as_state2(atom_to_list(Name), State, Acc);
as_state1(Name, State, Acc) when is_integer(Name) ->
	as_state2(integer_to_list(Name), State, Acc);
as_state1(Name, State, Acc) when is_list(Name) ->
	case catch unicode:characters_to_list(list_to_binary(Name), utf8) of
		Name1 when is_list(Name1) ->
			as_state2(Name1, State, Acc);
		_ ->
			as_state2([], State, Acc)
	end;
as_state1(_Name, State, Acc) ->
	as_state2([], State, Acc).
%% @hidden
as_state2(Name, down, Acc) ->
	[["stc_m3ua_as_state{name=", Name, ",state=down} 1\n",
	"stc_m3ua_as_state{name=", Name, ",state=inactive} 0\n",
	"stc_m3ua_as_state{name=", Name, ",state=active} 0\n",
	"stc_m3ua_as_state{name=", Name, ",state=pending} 0\n"] | Acc];
as_state2(Name, inactive, Acc) ->
	[["stc_m3ua_as_state{name=", Name, ",state=down} 0\n",
	"stc_m3ua_as_state{name=", Name, ",state=inactive} 1\n",
	"stc_m3ua_as_state{name=", Name, ",state=active} 0\n",
	"stc_m3ua_as_state{name=", Name, ",state=pending} 0\n"] | Acc];
as_state2(Name, active, Acc) ->
	[["stc_m3ua_as_state{name=", Name, ",state=down} 0\n",
	"stc_m3ua_as_state{name=", Name, ",state=inactive} 0\n",
	"stc_m3ua_as_state{name=", Name, ",state=active} 1\n",
	"stc_m3ua_as_state{name=", Name, ",state=pending} 0\n"] | Acc];
as_state2(Name, pending, Acc) ->
	[["stc_m3ua_as_state{name=", Name, ",state=down} 0\n",
	"stc_m3ua_as_state{name=", Name, ",state=inactive} 0\n",
	"stc_m3ua_as_state{name=", Name, ",state=active} 0\n",
	"stc_m3ua_as_state{name=", Name, ",state=pending} 1\n"] | Acc].

