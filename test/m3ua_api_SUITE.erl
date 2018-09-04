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

-include("m3ua.hrl").
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
	PrivDir = ?config(priv_dir, Config),
	application:load(mnesia),
	ok = application:set_env(mnesia, dir, PrivDir),
	{ok, [m3ua_asp, m3ua_as]} = m3ua_app:install(),
	ok = application:start(m3ua),
	Config.

-spec end_per_suite(Config :: [tuple()]) -> any().
%% Cleanup after the whole suite.
%%
end_per_suite(_Config) ->
	ok = application:stop(m3ua).

-spec init_per_testcase(TestCase :: atom(), Config :: [tuple()]) -> Config :: [tuple()].
%% Initiation before each test case.
%%
init_per_testcase(TC, Config) when TC == sg_state_active; TC == as_state_active;
		TC == sg_state_down; TC == as_state_down ->
	case is_alive() of
			true ->
				Config;
			false ->
				{skip, not_alive}
	end;
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
	[start, stop, listen, connect, release, getstat_ep, getstat_assoc,
			getcount, asp_up, asp_down, register, asp_active,
			asp_inactive_to_down, asp_active_to_down,
			asp_active_to_inactive, get_sctp_status, get_ep, mtp_transfer,
			asp_up_indication, asp_active_indication,
			asp_inactive_indication, asp_down_indication,
			sg_state_active, as_state_active, sg_state_down, as_state_down].

%%---------------------------------------------------------------------
%%  Test cases
%%---------------------------------------------------------------------

start() ->
	[{userdata, [{doc, "Open an SCTP endpoint."}]}].

start(_Config) ->
	{ok, EP} = m3ua:start(#m3ua_fsm_cb{}),
	true = is_process_alive(EP),
	m3ua:stop(EP).

stop() ->
	[{userdata, [{doc, "Close an SCTP endpoint."}]}].

stop(_Config) ->
	{ok, EP} = m3ua:start(#m3ua_fsm_cb{}),
	true = is_process_alive(EP),
	ok = m3ua:stop(EP),
	false = is_process_alive(EP).

listen() ->
	[{userdata, [{doc, "Open an SCTP server endpoint."}]}].

listen(_Config) ->
	{ok, EP} = m3ua:start(#m3ua_fsm_cb{}, 0, [{ip, {127,0,0,1}}]),
	true = is_process_alive(EP),
	ok = m3ua:stop(EP),
	false = is_process_alive(EP).

connect() ->
	[{userdata, [{doc, "Connect client SCTP endpoint to server."}]}].

connect(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, [{role, sgp}]),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[_Assoc] = m3ua:get_assoc(ClientEP).

release() ->
	[{userdata, [{doc, "Release SCTP association."}]}].

release(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:sctp_release(ClientEP, Assoc).

asp_up() ->
	[{userdata, [{doc, "Bring Application Server Process (ASP) up."}]}].

asp_up(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc).

asp_down() ->
	[{userdata, [{doc, "Bring Application Server Process (ASP) down."}]}].

asp_down(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc).

getstat_ep() ->
	[{userdata, [{doc, "Get SCTP option statistics for an endpoint."}]}].

getstat_ep(_Config) ->
	{ok, EP} = m3ua:start(m3ua_demo_as),
	{ok, OptionValues} = m3ua:getstat(EP),
	F = fun({Option, Value}) when is_atom(Option), is_integer(Value) ->
				true;
			(_) ->
				false
	end,
	true = lists:all(F, OptionValues),
	m3ua:stop(EP).

getstat_assoc() ->
	[{userdata, [{doc, "Get SCTP option statistics for an association."}]}].

getstat_assoc(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	{ok, OptionValues} = m3ua:getstat(ClientEP, Assoc),
	F = fun({Option, Value}) when is_atom(Option), is_integer(Value) ->
				true;
			(_) ->
				false
	end,
	true = lists:all(F, OptionValues),
	m3ua:stop(ClientEP),
	m3ua:stop(ServerEP).

getcount() ->
	[{userdata, [{doc, "Get M3UA statistics for an ASP."}]}].

getcount(_Config) ->
	Port = rand:uniform(64511) + 1024,
	NA = 0,
	Keys = [{rand:uniform(16383), [], []}],
	Mode = loadshare,
	Ref = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	{ok, _RC} = m3ua:register(ClientEP, Assoc, undefined, NA, Keys, Mode),
	{ok, #{up_out := 1, up_ack_in := 1}} = m3ua:getcount(ClientEP, Assoc),
	ok = m3ua:asp_active(ClientEP, Assoc),
	{ok, #{active_out := 1, active_ack_in := 1}} = m3ua:getcount(ClientEP, Assoc),
	ok = m3ua:asp_inactive(ClientEP, Assoc),
	{ok, #{inactive_out := 1, inactive_ack_in := 1}} = m3ua:getcount(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc),
	{ok, #{down_out := 1, down_ack_in := 1}} = m3ua:getcount(ClientEP, Assoc),
	m3ua:stop(ClientEP),
	m3ua:stop(ServerEP).

register() ->
	[{userdata, [{doc, "Register a routing key."}]}].

register(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [7,8], []}],
	{ok, RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, undefined, Keys, loadshare),
	true = is_integer(RoutingContext).

asp_active() ->
	[{userdata, [{doc, "Make Application Server Process (ASP) active."}]}].

asp_active(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc).

asp_inactive_to_down() ->
	[{userdata, [{doc, "Make ASP inactive to down state"}]}].

asp_inactive_to_down(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc).

asp_active_to_down() ->
	[{userdata, [{doc, "Make ASP active to down state"}]}].

asp_active_to_down(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc).

asp_active_to_inactive() ->
	[{userdata, [{doc, "Make ASP active to inactive state"}]}].

asp_active_to_inactive(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	ok = m3ua:asp_inactive(ClientEP, Assoc).

get_sctp_status() ->
	[{userdata, [{doc, "Get SCTP status of an association"}]}].
get_sctp_status(_Config) ->
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	{ok, #sctp_status{assoc_id = Assoc}} = m3ua:sctp_status(ClientEP, Assoc).

get_ep() ->
	[{userdata, [{doc, "Get SCTP endpoints."}]}].

get_ep(_Config) ->
	Port = rand:uniform(64511) + 1024,
	{ok, ServerEP} = m3ua:start(#m3ua_fsm_cb{}, Port, []),
	{ok, ClientEP} = m3ua:start(#m3ua_fsm_cb{}, 0,
			[{name, Port}, {role, asp},
			{connect, {127,0,0,1}, Port, []}]),
	EndPoints = m3ua:get_ep(),
	true = lists:member(ServerEP, EndPoints),
	true = lists:member(ClientEP, EndPoints),
	{_, server, sgp, {{0,0,0,0}, Port}} = m3ua:get_ep(ServerEP),
	{Port, client, asp, {{0,0,0,0}, _},
			{{127,0,0,1}, Port}} = m3ua:get_ep(ClientEP),
	m3ua:stop(ClientEP),
	m3ua:stop(ServerEP).

mtp_transfer() ->
	[{userdata, [{doc, "Send MTP Transfer Message"}]}].
mtp_transfer(_Config) ->
	AspActive = fun(ASP, Pid) ->
				Pid ! {asp, active, ASP},
				{ok, []}
	end,
	AspInit = fun(_, ASP, _, _, _, _) ->
				{ok, once, ASP}
	end,
	Ref = make_ref(),
	SgpInit = fun(_, SGP, _, _, _, Pid) ->
				Pid ! Ref,
				{ok, once, SGP}
	end,
	SgpTransfer = fun(Stream, RC, OPC, DPC, NI, SI, SLS, Data, _State, Pid) ->
				Pid !  {sgp, transfer, {Stream, RC, DPC, OPC, NI, SI, SLS, Data}},
				{ok, once, []}
	end,
	AspTransfer = fun(Stream, RC, OPC, DPC, NI, SI, SLS, Data, _, Pid) ->
				Pid ! {asp, transfer, {Stream, RC, OPC, DPC, NI, SI, SLS, Data}},
				{ok, once, []}
	end,
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:start(#m3ua_fsm_cb{init = SgpInit,
			transfer = SgpTransfer, extra = [self()]}, Port, []),
	{ok, ClientEP} = m3ua:start(#m3ua_fsm_cb{init = AspInit,
			asp_active = AspActive, transfer = AspTransfer, extra = [self()]},
			0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	DPC = rand:uniform(16383),
	Keys = [{DPC, [], []}],
	{ok, RC} = m3ua:register(ClientEP, Assoc,
			undefined, undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	Asp = receive
		{asp, active, Pid} ->
			Pid
	end,
	Stream = 1,
	OPC = rand:uniform(16383),
	NI = rand:uniform(4),
	SI = rand:uniform(10),
	SLS = rand:uniform(10),
	Data = crypto:strong_rand_bytes(100),
	proc_lib:spawn(m3ua, transfer, [Asp, Stream, RC, OPC, DPC, NI, SI, SLS, Data]),
	receive
		{sgp, transfer, {Stream, RC, DPC, OPC, NI, SI, SLS, Data}} ->
			ok
	end.

asp_up_indication() ->
	[{userdata, [{doc, "Received M-ASP_UP indication"}]}].

asp_up_indication(_Config) ->
	Fup = fun(_, Pid) ->
		Pid ! {sgp, asp_up, indication},
		{ok, []}
	end,
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	Cb = callback(Ref),
	{ok, _ServerEP} = m3ua:start(Cb#m3ua_fsm_cb{asp_up = Fup}, Port, []),
	{ok, ClientEP} = m3ua:start(#m3ua_fsm_cb{}, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	receive
		{sgp, asp_up, indication} ->
			ok
	end.

asp_active_indication() ->
	[{userdata, [{doc, "Received M-ASP_ACTIVE indication"}]}].

asp_active_indication(_Config) ->
	Fact = fun(_, Pid) ->
		Pid ! {sgp, asp_active, indication},
		{ok, []}
	end,
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	Cb = callback(Ref),
	{ok, _ServerEP} = m3ua:start(Cb#m3ua_fsm_cb{asp_active = Fact}, Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	receive
		{sgp, asp_active, indication} ->
			ok
	end.

asp_inactive_indication() ->
	[{userdata, [{doc, "Received M-ASP_INACTIVE indication"}]}].

asp_inactive_indication(_Config) ->
	Finact = fun(_, Pid) ->
		Pid ! {sgp, asp_inactive, indication},
		{ok, []}
	end,
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	Cb = callback(Ref),
	{ok, _ServerEP} = m3ua:start(Cb#m3ua_fsm_cb{asp_inactive = Finact},
			Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	ok = m3ua:asp_inactive(ClientEP, Assoc),
	receive
		{sgp, asp_inactive, indication} ->
			ok
	end.

asp_down_indication() ->
	[{userdata, [{doc, "Received M-ASP_DOWN indication"}]}].

asp_down_indication(_Config) ->
	Fdown = fun(_, Pid) ->
		Pid ! {sgp, asp_down, indication},
		{ok, []}
	end,
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	Cb = callback(Ref),
	{ok, _ServerEP} = m3ua:start(Cb#m3ua_fsm_cb{asp_down = Fdown}, Port, []),
	{ok, ClientEP} = m3ua:start(m3ua_demo_as, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(Ref),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc),
	receive
		{sgp, asp_down, indication} ->
			ok
	end.

sg_state_active() ->
	[{userdata, [{doc, "SG traffic maintenance for AS state"}]}].

sg_state_active(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(4294967295),
	DPC = rand:uniform(16777215),
	SIs = [rand:uniform(255) || _ <- lists:seq(1, 5)],
	OPCs = [rand:uniform(16777215) || _ <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RC = rand:uniform(4294967295),
	Name = make_ref(),
	{ok, _AS} = m3ua:as_add(Name, RC, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(m3ua_demo_as)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "as" ++ integer_to_list(erlang:unique_integer([positive])),
	{ok, AsNode} = slave:start_link(Host, Node, ErlFlags),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, start,
			[m3ua_demo_as, 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, start,
			[m3ua_demo_as, 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, start,
			[m3ua_demo_as, 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(Ref),
	wait(Ref),
	wait(Ref),
	[Assoc1] = m3ua:get_assoc(ClientEP1),
	[Assoc2] = m3ua:get_assoc(ClientEP2),
	[Assoc3] = m3ua:get_assoc(ClientEP3),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	#m3ua_as{state = down, asp = []} = get_as(RC),
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP1, Assoc1, undefined, NA, Keys, Mode]),
	#m3ua_as{state = inactive, asp = Asps1} = get_as(RC),
	true = is_all_state(inactive, Asps1),
	1 = length(Asps1),
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP2, Assoc2, undefined, NA, Keys, Mode]),
	#m3ua_as{state = inactive, asp = Asps2} = get_as(RC),
	true = is_all_state(inactive, Asps2),
	2 = length(Asps2),
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP3, Assoc3, undefined, NA, Keys, Mode]),
	#m3ua_as{state = inactive, asp = Asps3} = get_as(RC),
	true = is_all_state(inactive, Asps3),
	3 = length(Asps3),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP1, Assoc1]),
	#m3ua_as{state = inactive, asp = Asps4} = get_as(RC),
	1 = count_state(active, Asps4),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	#m3ua_as{state = inactive, asp = Asps5} = get_as(RC),
	2 = count_state(active, Asps5),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	#m3ua_as{state = active, asp = Asps6} = get_as(RC),
	3 = count_state(active, Asps6).

as_state_active() ->
	[{userdata, [{doc, "AS traffic maintenance for AS state"}]}].

as_state_active(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(4294967295),
	DPC = rand:uniform(16777215),
	SIs = [rand:uniform(255) || _ <- lists:seq(1, 5)],
	OPCs = [rand:uniform(16777215) || _ <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RC = rand:uniform(4294967295),
	Name = make_ref(),
	{ok, _AS} = m3ua:as_add(Name, RC, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:start(#m3ua_fsm_cb{}, Port, []),
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(?MODULE)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "as" ++ integer_to_list(erlang:unique_integer([positive])),
	{ok, AsNode} = slave:start_link(Host, Node, ErlFlags),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	Ref1 = make_ref(),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, start,
			[callback(Ref1), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	Ref2 = make_ref(),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, start,
			[callback(Ref2), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	Ref3 = make_ref(),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, start,
			[callback(Ref3), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(Ref1),
	wait(Ref2),
	wait(Ref3),
	[Assoc1] = m3ua:get_assoc(ClientEP1),
	[Assoc2] = m3ua:get_assoc(ClientEP2),
	[Assoc3] = m3ua:get_assoc(ClientEP3),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	{ok, _RoutingContext1} = rpc:call(AsNode, m3ua, register,
			[ClientEP1, Assoc1, undefined, NA, Keys, Mode]),
	{ok, _RoutingContext2} = rpc:call(AsNode, m3ua, register,
			[ClientEP2, Assoc2, undefined, NA, Keys, Mode]),
	{ok, _RoutingContext3} = rpc:call(AsNode, m3ua, register,
			[ClientEP3, Assoc3, undefined, NA, Keys, Mode]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	{_RC, as_active} = wait(Ref1),
	{_RC, as_active} = wait(Ref2),
	{_RC, as_active} = wait(Ref3).

sg_state_down() ->
	[{userdata, [{doc, "SG state maintenance for AS state"}]}].

sg_state_down(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(4294967295),
	DPC = rand:uniform(16777215),
	SIs = [rand:uniform(255) || _ <- lists:seq(1, 5)],
	OPCs = [rand:uniform(16777215) || _ <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RC = rand:uniform(4294967295),
	Name = make_ref(),
	{ok, _AS} = m3ua:as_add(Name, RC, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	Ref = make_ref(),
	{ok, _ServerEP} = m3ua:start(callback(Ref), Port, []),
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(m3ua_demo_as)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "as" ++ integer_to_list(erlang:unique_integer([positive])),
	{ok, AsNode} = slave:start_link(Host, Node, ErlFlags),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, start,
			[m3ua_demo_as, 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, start,
			[m3ua_demo_as, 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, start,
			[m3ua_demo_as, 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(Ref),
	wait(Ref),
	wait(Ref),
	[Assoc1] = m3ua:get_assoc(ClientEP1),
	[Assoc2] = m3ua:get_assoc(ClientEP2),
	[Assoc3] = m3ua:get_assoc(ClientEP3),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	{ok, _RoutingContext1} = rpc:call(AsNode, m3ua, register,
			[ClientEP1, Assoc1, undefined, NA, Keys, Mode]),
	{ok, _RoutingContext2} = rpc:call(AsNode, m3ua, register,
			[ClientEP2, Assoc2, undefined, NA, Keys, Mode]),
	{ok, _RoutingContext3} = rpc:call(AsNode, m3ua, register,
			[ClientEP3, Assoc3, undefined, NA, Keys, Mode]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	#m3ua_as{state = active, asp = Asps1} = get_as(RC),
	true = is_all_state(active, Asps1),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP2, Assoc2]),
	#m3ua_as{state = active, asp = Asps2} = get_as(RC),
	1 = count_state(active, Asps2),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP3, Assoc3]),
	#m3ua_as{state = down, asp = Asps3} = get_as(RC),
	true = is_all_state(down, Asps3).

as_state_down() ->
	[{userdata, [{doc, "AS state maintenance for AS state"}]}].

as_state_down(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(4294967295),
	DPC = rand:uniform(16777215),
	SIs = [rand:uniform(255) || _ <- lists:seq(1, 5)],
	OPCs = [rand:uniform(16777215) || _ <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RC = rand:uniform(4294967295),
	Name = make_ref(),
	{ok, _AS} = m3ua:as_add(Name, RC, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:start(#m3ua_fsm_cb{}, Port, []),
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(?MODULE)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "as" ++ integer_to_list(erlang:unique_integer([positive])),
	{ok, AsNode} = slave:start_link(Host, Node, ErlFlags),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	Ref1 = make_ref(),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, start,
			[callback(Ref1), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	Ref2 = make_ref(),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, start,
			[callback(Ref2), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	Ref3 = make_ref(),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, start,
			[callback(Ref3), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(Ref1),
	wait(Ref2),
	wait(Ref3),
	[Assoc1] = m3ua:get_assoc(ClientEP1),
	[Assoc2] = m3ua:get_assoc(ClientEP2),
	[Assoc3] = m3ua:get_assoc(ClientEP3),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	{ok, _RoutingContext1} = rpc:call(AsNode, m3ua, register,
			[ClientEP1, Assoc1, undefined, NA, Keys, Mode]),
	{ok, _RoutingContext2} = rpc:call(AsNode, m3ua, register,
			[ClientEP2, Assoc2, undefined, NA, Keys, Mode]),
	{ok, _RoutingContext3} = rpc:call(AsNode, m3ua, register,
			[ClientEP3, Assoc3, undefined, NA, Keys, Mode]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP2, Assoc2]),
	ok = flush(Ref1),
	ok = flush(Ref2),
	ok = flush(Ref3),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP3, Assoc3]),
	{_RC, as_inactive} = wait(Ref1),
	{_RC, as_inactive} = wait(Ref2),
	{_RC, as_inactive} = wait(Ref3).

%%---------------------------------------------------------------------
%%  Internal functions
%%---------------------------------------------------------------------

callback(Ref) ->
	Finit = fun(_Module, _Asp, _EP, _EpName, _Assoc, Pid) ->
				Pid ! Ref,
				{ok, once, []}
	end,
	Fnotify = fun(RC, Status, _AspID, State, Pid) ->
				Pid ! {Ref, RC, Status},
				{ok, State}
	end,
	#m3ua_fsm_cb{init = Finit, notify = Fnotify, extra = [self()]}.

wait(Ref) ->
	receive
		Ref ->
			ok;
		{Ref, RC, Status} ->
			{RC, Status}
	end.

flush(Ref) ->
	receive
		Ref ->
			flush(Ref);
		{Ref, _RC, _Status} ->
			flush(Ref)
	after
		0 ->
			ok
	end.

is_all_state(IsAspState, Asps) ->
	F = fun(#m3ua_as_asp{state = AspState}) when AspState == IsAspState ->
			true;
		(_) ->
			false
	end,
	lists:all(F, Asps).

count_state(IsAspState, Asps) ->
	F = fun(#m3ua_as_asp{state = AspState}, Acc) when AspState == IsAspState ->
				Acc + 1;
			(_, Acc) ->
				Acc
	end,
	lists:foldl(F, 0, Asps).

get_as(RC) ->
	F = fun() ->
			[#m3ua_as{}] = mnesia:read(m3ua_as, RC, read)
	end,
	case mnesia:transaction(F) of
		{atomic, [AS]} ->
			AS;
		{aboarted, Reason} ->
			Reason
	end.

