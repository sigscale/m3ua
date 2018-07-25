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
-include_lib("kernel/include/inet_sctp.hrl").

-spec content_types_accepted() -> ContentTypes
	when
		ContentTypes :: [string()].
%% @doc Provide list of resource representations accepted.
content_types_accepted() ->
	["text/plain"].

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
	Body = [as_state(), asp_state(), sctp_state()],
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
			"Application Server (AS):\n# down | inactive | active | pending.\n",
			"# TYPE stc_m3ua_as_state guage\n"],
	as_state(AS, [HELP]);
as_state({error, Reason}) ->
	error_logger:error_report(["Failed to get application servers",
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
		UTF8 when is_list(UTF8) ->
			as_state2(UTF8, State, Acc);
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

%% @hidden
asp_state() ->
	asp_state(catch m3ua:get_assoc()).
%% @hidden
asp_state([]) ->
	[];
asp_state(Assocs) when is_list(Assocs) ->
	HELP = ["# HELP stc_m3ua_asp_state The current state of an\n"
			"# Application Server Process (ASP) or Signaling "
			"Gateway Process (SGP):\n# down | inactive | active.\n",
			"# TYPE stc_m3ua_asp_state guage\n"],
	asp_state(Assocs, [HELP]);
asp_state({'EXIT', Reason}) ->
	error_logger:error_report(["Failed to get associations",
			{module, ?MODULE}, {error, Reason}]),
	[].
%% @hidden
asp_state([{EP, Assoc} | T], Acc) ->
	NewAcc = case catch m3ua:get_ep(EP) of
		EndPoint when size(EndPoint) >= 4 ->
			Name = element(1, EndPoint),
			Role = atom_to_list(element(3, EndPoint)),
			asp_state1(Name, Role, catch m3ua:asp_status(EP, Assoc), Acc);
		{'EXIT', Reason} ->
			error_logger:error_report(["Failed to get endpoint",
					{module, ?MODULE}, {error, Reason}]),
			[]
	end,
	asp_state(T, NewAcc);
asp_state([], Acc) ->
	lists:reverse(["\n" | Acc]).
%% @hidden
asp_state1(Name, Role, State, Acc)
		when is_atom(Name), is_atom(State) ->
	asp_state2(atom_to_list(Name), Role, State, Acc);
asp_state1(Name, Role, State, Acc)
		when is_integer(Name), is_atom(State) ->
	asp_state2(integer_to_list(Name), Role, State, Acc);
asp_state1(Name, Role, State, Acc)
		when is_list(Name), is_atom(State) ->
	case catch unicode:characters_to_list(list_to_binary(Name), utf8) of
		Name1 when is_list(Name1) ->
			asp_state2(Name1, Role, State, Acc);
		_ ->
			asp_state2([], Role, State, Acc)
	end;
asp_state1(_Name, Role, State, Acc)
		when is_atom(State) ->
	asp_state2([], Role, State, Acc);
asp_state1(_Name, _, {'EXIT', Reason}, _) ->
	error_logger:error_report(["Failed to get ASP status",
			{module, ?MODULE}, {error, Reason}]),
	[].
%% @hidden
asp_state2(Name, Role, down, Acc) ->
	[["stc_m3ua_asp_state{endpoint=", Name,
			",role=", Role, ",state=down} 1\n",
	"stc_m3ua_asp_state{endpoint=", Name,
			",role=", Role, ",state=inactive} 0\n",
	"stc_m3ua_asp_state{endpoint=", Name,
			",role=", Role, ",state=active} 0\n"] | Acc];
asp_state2(Name, Role, inactive, Acc) ->
	[["stc_m3ua_asp_state{endpoint=", Name,
			",role=", Role, ",state=down} 0\n",
	"stc_m3ua_asp_state{endpoint=", Name,
			",role=", Role, ",state=inactive} 1\n",
	"stc_m3ua_asp_state{endpoint=", Name,
			",role=", Role, ",state=active} 0\n"] | Acc];
asp_state2(Name, Role, active, Acc) ->
	[["stc_m3ua_asp_state{endpoint=", Name,
			",role=", Role, ",state=down} 0\n",
	"stc_m3ua_asp_state{endpoint=", Name,
			",role=", Role, ",state=inactive} 0\n",
	"stc_m3ua_asp_state{endpoint=", Name,
			",state=active} 1\n"] | Acc].

%% @hidden
sctp_state() ->
	sctp_state(catch m3ua:get_assoc()).
%% @hidden
sctp_state([]) ->
	[];
sctp_state(Assocs) when is_list(Assocs) ->
	HELP = ["# HELP stc_m3ua_sctp_state The current state of an "
			"SCTP association:\n# closed | cooke-wait | cookie-echoed "
			"shutdown-pending\n#  | shutdown-received | shutdown-sent "
			"shutdown-ack-sent.\n",
			"# TYPE stc_m3ua_sctp_state guage\n"],
	sctp_state(Assocs, [HELP]);
sctp_state({'EXIT', Reason}) ->
	error_logger:error_report(["Failed to get associations",
			{module, ?MODULE}, {error, Reason}]),
	[].
%% @hidden
sctp_state([{EP, Assoc} | T], Acc) ->
	NewAcc = case catch m3ua:get_ep(EP) of
		EndPoint when size(EndPoint) >= 4 ->
			Name = element(1, EndPoint),
			Role = atom_to_list(element(2, EndPoint)),
			sctp_state1(Name, Role, m3ua:sctp_status(EP, Assoc), Acc);
		{'EXIT', Reason} ->
			error_logger:error_report(["Failed to get endpoint",
					{module, ?MODULE}, {error, Reason}]),
			[]
	end,
	sctp_state(T, NewAcc);
sctp_state([], Acc) ->
	lists:reverse(["\n" | Acc]).
%% @hidden
sctp_state1(Name, Role, {ok, #sctp_status{state = State}}, Acc)
		when is_atom(Name) ->
	sctp_state2(atom_to_list(Name), Role, State, Acc);
sctp_state1(Name, Role, {ok, #sctp_status{state = State}}, Acc)
		when is_integer(Name) ->
	sctp_state2(integer_to_list(Name), Role, State, Acc);
sctp_state1(Name, Role, {ok, #sctp_status{state = State}}, Acc)
		when is_list(Name) ->
	case catch unicode:characters_to_list(list_to_binary(Name), utf8) of
		Name1 when is_list(Name1) ->
			sctp_state2(Name1, Role, State, Acc);
		_ ->
			sctp_state2([], Role, State, Acc)
	end;
sctp_state1(_Name, Role, {ok, #sctp_status{state = State}}, Acc) ->
	sctp_state2([], Role, State, Acc);
sctp_state1(_Name, _, {error, Reason}, _) ->
	error_logger:error_report(["Failed to get SCTP status",
			{module, ?MODULE}, {error, Reason}]),
	[].
%% @hidden
sctp_state2(Name, Role, closed, Acc) ->
	[["stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=closed} 1\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-wait} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-echoed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=established} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-pending} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-received} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-sent} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-ack-sent} 0\n"] | Acc];
sctp_state2(Name, Role, cookie_wait, Acc) ->
	[["stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=closed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-wait} 1\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-echoed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=established} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-pending} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-received} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-sent} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-ack-sent} 0\n"] | Acc];
sctp_state2(Name, Role, cookie_echoed, Acc) ->
	[["stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=closed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-wait} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-echoed} 1\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=established} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-pending} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-received} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-sent} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-ack-sent} 0\n"] | Acc];
sctp_state2(Name, Role, established, Acc) ->
	[["stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=closed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-wait} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-echoed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=established} 1\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-pending} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-received} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-sent} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-ack-sent} 0\n"] | Acc];
sctp_state2(Name, Role, shutdown_pending, Acc) ->
	[["stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=closed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-wait} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-echoed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=established} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-pending} 1\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-received} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-sent} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-ack-sent} 0\n"] | Acc];
sctp_state2(Name, Role, shutdown_received, Acc) ->
	[["stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=closed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-wait} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-echoed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=established} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-pending} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-received} 1\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-sent} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-ack-sent} 0\n"] | Acc];
sctp_state2(Name, Role, shutdown_sent, Acc) ->
	[["stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=closed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-wait} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-echoed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=established} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-pending} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-received} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-sent} 1\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-ack-sent} 0\n"] | Acc];
sctp_state2(Name, Role, shutdown__asck_sent, Acc) ->
	[["stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=closed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-wait} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=cookie-echoed} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=established} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-pending} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-received} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-sent} 0\n",
	"stc_m3ua_sctp_state{endpoint=", Name,
			",role=", Role, ",state=shutdown-ack-sent} 1\n"] | Acc].

