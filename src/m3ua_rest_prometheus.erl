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
get_metrics(Query, Headers) ->
	Body = [as_state("dtag_frankfurt", "active")],
	{ok, [], Body}.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

%% @hidden
as_state(Name, State) when is_list(Name), is_list(State) ->
	["# HELP stc_m3ua_as_state The current state of an Application Server (AS).\n",
			"# TYPE stc_m3ua_as_state guage\n",
			"stc_m3ua_as_state{name=", Name, ",state=", State, "}\n"].

