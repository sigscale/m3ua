%%% m3ua_api_SUITE.erl
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
%%%  Test suite for the m3ua API.
%%%
-module(m3ua_api_SUITE).
-copyright('Copyright (c) 2015-2018 SigScale Global Inc.').

%% common_test required callbacks
-export([suite/0, sequences/0, all/0]).
-export([init_per_suite/1, end_per_suite/1]).
-export([init_per_testcase/2, end_per_testcase/2]).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").

%%---------------------------------------------------------------------
%%  Test server callback functions
%%---------------------------------------------------------------------

-spec suite() -> DefaultData :: [tuple()].
%% Require variables and set default values for the suite.
%%
suite() ->
	[{timetrap, {minutes, 1}}].

-spec init_per_suite(Config :: [tuple()]) -> Config :: [tuple()].
%% Initiation before the whole suite.
%%
init_per_suite(Config) ->
	ok = application:start(m3ua),
	Config.

-spec end_per_suite(Config :: [tuple()]) -> any().
%% Cleanup after the whole suite.
%%
end_per_suite(Config) ->
	ok = application:stop(m3ua),
	Config.

-spec init_per_testcase(TestCase :: atom(), Config :: [tuple()]) -> Config :: [tuple()].
%% Initiation before each test case.
%%
init_per_testcase(_TestCase, Config) ->
	Config.

-spec end_per_testcase(TestCase :: atom(), Config :: [tuple()]) -> any().
%% Cleanup after each test case.
%%
end_per_testcase(_TestCase, _Config) ->
	ok.

-spec sequences() -> Sequences :: [{SeqName :: atom(), Testcases :: [atom()]}].
%% Group test cases into a test sequence.
%%
sequences() ->
	[].

-spec all() -> TestCases :: [Case :: atom()].
%% Returns a list of all test cases in this test suite.
%%
all() ->
	[open, close, listen, connect, release, getstat_ep, getstat_assoc,
			asp_up, register].

%%---------------------------------------------------------------------
%%  Test cases
%%---------------------------------------------------------------------

open() ->
	[{userdata, [{doc, "Open an SCTP endpoint."}]}].

open(_Config) ->
	{ok, EP} = m3ua:open(),
	true = is_process_alive(EP),
	m3ua:close(EP).

close() ->
	[{userdata, [{doc, "Close an SCTP endpoint."}]}].

close(_Config) ->
	{ok, EP} = m3ua:open(),
	true = is_process_alive(EP),
	ok = m3ua:close(EP),
	false = is_process_alive(EP).

listen() ->
	[{userdata, [{doc, "Open an SCTP server endpoint."}]}].

listen(_Config) ->
	{ok, EP} = m3ua:open(0, [{sctp_role, server}]),
	true = is_process_alive(EP),
	ok = m3ua:close(EP),
	false = is_process_alive(EP).

connect() ->
	[{userdata, [{doc, "Connect client SCTP endpoint to server."}]}].

connect(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}]),
	{ok, ClientEP} = m3ua:open(),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	true = is_integer(Assoc).

release() ->
	[{userdata, [{doc, "Release SCTP association."}]}].

release(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}]),
	{ok, ClientEP} = m3ua:open(),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:sctp_release(ClientEP, Assoc).

asp_up() ->
	[{userdata, [{doc, "Bring Application Server Process (ASP) up."}]}].

asp_up(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp}]),
	{ok, ClientEP} = m3ua:open(),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc).

getstat_ep() ->
	[{userdata, [{doc, "Get SCTP option statistics for an endpoint."}]}].

getstat_ep(_Config) ->
	{ok, EP} = m3ua:open(),
	{ok, OptionValues} = m3ua:getstat_endpoint(EP),
	F = fun({Option, Value}) when is_atom(Option), is_integer(Value) ->
				true;
			(_) ->
				false
	end,
	true = lists:all(F, OptionValues),
	m3ua:close(EP).

getstat_assoc() ->
	[{userdata, [{doc, "Get SCTP option statistics for an association."}]}].

getstat_assoc(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, ServerEP} = m3ua:open(Port, [{sctp_role, server}]),
	{ok, ClientEP} = m3ua:open(),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	{ok, OptionValues} = m3ua:getstat_association(ClientEP, Assoc),
	F = fun({Option, Value}) when is_atom(Option), is_integer(Value) ->
				true;
			(_) ->
				false
	end,
	true = lists:all(F, OptionValues),
	m3ua:close(ClientEP),
	m3ua:close(ServerEP).

register() ->
	[{userdata, [{doc, "Register a routing key."}]}].

register(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp}]),
	{ok, ClientEP} = m3ua:open(),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [7,8], []}],
	{ok, RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, Keys, loadshare),
	true = is_integer(RoutingContext).

%%---------------------------------------------------------------------
%%  Internal functions
%%---------------------------------------------------------------------

