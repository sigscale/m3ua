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
-include_lib("kernel/include/inet_sctp.hrl").

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
	{ok, [m3ua_as]} = m3ua_app:install(),
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
			asp_up, asp_down, register, asp_active, asp_inactive_to_down,
			asp_active_to_down, asp_active_to_inactive, get_sctp_status,
			mtp_transfer].

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
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp},
			{callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc).

asp_down() ->
	[{userdata, [{doc, "Bring Application Server Process (ASP) down."}]}].

asp_down(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp},
			{callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc).

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
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp},
			{callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [7,8], []}],
	{ok, RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, Keys, loadshare),
	true = is_integer(RoutingContext).

asp_active() ->
	[{userdata, [{doc, "Make Application Server Process (ASP) active."}]}].

asp_active(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp},
			{callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc).

asp_inactive_to_down() ->
	[{userdata, [{doc, "Make ASP inactive to down state"}]}].

asp_inactive_to_down(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp},
			{callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc).

asp_active_to_down() ->
	[{userdata, [{doc, "Make ASP active to down state"}]}].

asp_active_to_down(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp},
			{callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc).

asp_active_to_inactive() ->
	[{userdata, [{doc, "Make ASP active to inactive state"}]}].

asp_active_to_inactive(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp},
			{callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	ok = m3ua:asp_inactive(ClientEP, Assoc).

get_sctp_status() ->
	[{userdata, [{doc, "Get SCTP status of an association"}]}].
get_sctp_status(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp}]),
	{ok, ClientEP} = m3ua:open(),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	{ok, #sctp_status{assoc_id = AssocId}} = m3ua:sctp_status(ClientEP, Assoc).

mtp_transfer() ->
	[{userdata, [{doc, "Send MTP Transfer Message"}]}].
mtp_transfer(_Config) ->
	Port = rand:uniform(66559) + 1024,
	{ok, _ServerEP} = m3ua:open(Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	Asp = receive
		{asp, active, PID1} ->
			PID1
	end,
	Stream = 1,
	OPC = rand:uniform(1000),
	DPC = rand:uniform(1000),
	SIO = rand:uniform(10),
	SLS = rand:uniform(10),
	Data = crypto:strong_rand_bytes(100),
	ok = m3ua_asp_fsm:transfer(Asp, Assoc, Stream, OPC, DPC, SLS, SIO, Data),
	receive
		{asp, transfer, {Stream, DPC, OPC, SLS, SIO, Data}} ->
			ok
	end.



%%---------------------------------------------------------------------
%%  Internal functions
%%---------------------------------------------------------------------

