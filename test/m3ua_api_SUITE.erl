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

-include_lib("m3ua.hrl").
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
	{ok, [asp, m3ua_as]} = m3ua_app:install(),
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
init_per_testcase(TC, Config) when TC == as_state_change_traffic_maintenance;
		TC == as_state_active; TC  == as_state_inactive; TC == as_side_state_changes_1;
		TC ==  as_side_state_changes_2 ->
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
	[open, close, listen, connect, release, getstat_ep, getstat_assoc,
			asp_up, asp_down, register, asp_active, asp_inactive_to_down,
			asp_active_to_down, asp_active_to_inactive, get_sctp_status,
			mtp_transfer, asp_up_indication, asp_active_indication,
			asp_inactive_indication, asp_down_indication,
			as_state_change_traffic_maintenance, as_state_active,
			as_state_inactive, as_side_state_changes_1, as_side_state_changes_2].

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
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}]),
	{ok, ClientEP} = m3ua:open(),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	true = is_integer(Assoc).

release() ->
	[{userdata, [{doc, "Release SCTP association."}]}].

release(_Config) ->
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}]),
	{ok, ClientEP} = m3ua:open(),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:sctp_release(ClientEP, Assoc).

asp_up() ->
	[{userdata, [{doc, "Bring Application Server Process (ASP) up."}]}].

asp_up(_Config) ->
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp},
			{callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc).

asp_down() ->
	[{userdata, [{doc, "Bring Application Server Process (ASP) down."}]}].

asp_down(_Config) ->
	Port = rand:uniform(64511) + 1024,
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
	Port = rand:uniform(64511) + 1024,
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
	Port = rand:uniform(64511) + 1024,
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
	Port = rand:uniform(64511) + 1024,
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
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp},
			{callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc).

asp_active_to_down() ->
	[{userdata, [{doc, "Make ASP active to down state"}]}].

asp_active_to_down(_Config) ->
	Port = rand:uniform(64511) + 1024,
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
	Port = rand:uniform(64511) + 1024,
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
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port, [{sctp_role, server}, {m3ua_role, sgp}]),
	{ok, ClientEP} = m3ua:open(),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	{ok, #sctp_status{assoc_id = AssocId}} = m3ua:sctp_status(ClientEP, Assoc).

mtp_transfer() ->
	[{userdata, [{doc, "Send MTP Transfer Message"}]}].
mtp_transfer(_Config) ->
	Port = rand:uniform(64511) + 1024,
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

asp_up_indication() ->
	[{userdata, [{doc, "Received M-ASP_UP indication"}]}].

asp_up_indication(_Config) ->
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
erlang:display({?MODULE, ?LINE, self()}),
	ok = m3ua:asp_up(ClientEP, Assoc),
	receive
		{sgp, asp_up, indication} ->
			ok
	end.

asp_active_indication() ->
	[{userdata, [{doc, "Received M-ASP_ACTIVE indication"}]}].

asp_active_indication(_Config) ->
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	receive
		{sgp, asp_active, indication} ->
			ok
	end.

asp_inactive_indication() ->
	[{userdata, [{doc, "Received M-ASP_INACTIVE indication"}]}].

asp_inactive_indication(_Config) ->
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	ok = m3ua:asp_inactive(ClientEP, Assoc),
	receive
		{sgp, asp_inactive, indication} ->
			ok
	end.

asp_down_indication() ->
	[{userdata, [{doc, "Received M-ASP_DOWN indication"}]}].

asp_down_indication(_Config) ->
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]),
	{ok, ClientEP} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc} = m3ua:sctp_establish(ClientEP, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RoutingContext} = m3ua:register(ClientEP, Assoc,
			undefined, Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc),
	receive
		{sgp, asp_down, indication} ->
			ok
	end.

as_state_change_traffic_maintenance() ->
	[{userdata, [{doc, "Maintain and notify AS
			state changes with traffice maintenance messages"}]}].

as_state_change_traffic_maintenance(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(10),
	DPC = rand:uniform(255),
	SIs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	OPCs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RK = {NA, Keys, Mode},
	{ok, _AS} = m3ua:as_add(undefined, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]),
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(demo_as)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "as" ++ integer_to_list(erlang:unique_integer([positive])),
	{ok, AsNode} = slave:start_link(Host, Node, ErlFlags),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, open, [0, [{callback, {demo_as, self()}}]]),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, open, [0, [{callback, {demo_as, self()}}]]),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, open, [0, [{callback, {demo_as, self()}}]]),
	{ok, Assoc1} = rpc:call(AsNode, m3ua, sctp_establish, [ClientEP1, {127,0,0,1}, Port, []]),
	{ok, Assoc2} = rpc:call(AsNode, m3ua, sctp_establish, [ClientEP2, {127,0,0,1}, Port, []]),
	{ok, Assoc3} = rpc:call(AsNode, m3ua, sctp_establish, [ClientEP3, {127,0,0,1}, Port, []]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	F1  = fun() ->
		F2 = fun() ->
			case mnesia:read(m3ua_as, RK, read)  of
				[] ->
					not_found;
				[#m3ua_as{} = As] ->
					As
			end
		end,
		case mnesia:transaction(F2) of
			{atomic, As1} ->
				As1;
			{aboarted, Reason} ->
				Reason
		end
	end,
	IsAllState = fun(IsAspState, Asps) ->
			F = fun(#m3ua_asp{state = AspState}) when AspState == IsAspState ->
					true;
				(_) ->
					false
			end,
			lists:all(F, Asps)
	end,
	FilterState = fun(IsAspState, Asps) ->
			F = fun(#m3ua_asp{state = AspState}) when AspState == IsAspState ->
					true;
				(_) ->
					false
			end,
			lists:filter(F, Asps)
	end,
	%% Initial state down
	#m3ua_as{state = down, asp = []} = F1(),
	{ok, _RoutingContext1} = rpc:call(AsNode, m3ua, register, [ClientEP1, Assoc1, NA, Keys, Mode]),
	%% Registered ASP 1
	#m3ua_as{state = inactive, asp = Asps1} = F1(),
	true = IsAllState(inactive, Asps1),
	1 = length(Asps1),
	%% Registered ASP 2
	{ok, _RoutingContext2} = rpc:call(AsNode, m3ua, register, [ClientEP2, Assoc2, NA, Keys, Mode]),
	#m3ua_as{state = inactive, asp = Asps2} = F1(),
	true = IsAllState(inactive, Asps2),
	2 = length(Asps2),
	%% Registered ASP 3
	{ok, _RoutingContext3} = rpc:call(AsNode, m3ua, register, [ClientEP3, Assoc3, NA, Keys, Mode]),
	#m3ua_as{state = inactive, asp = Asps3} = F1(),
	true = IsAllState(inactive, Asps3),
	3 = length(Asps3),
	%% Active ASP 1
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP1, Assoc1]),
	#m3ua_as{state = inactive, asp = Asps4} = F1(),
	1 = length(FilterState(active, Asps4)),
	%% Active ASP 2
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	#m3ua_as{state = inactive, asp = Asps5} = F1(),
	2 = length(FilterState(active, Asps5)),
	%% Active ASP 3
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	#m3ua_as{state = active, asp = Asps6} = F1(),
	3 = length(FilterState(active, Asps6)).

as_state_active() ->
	[{userdata, [{doc, "Suffient ASPs, AS state change to active"}]}].

as_state_active(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(10),
	DPC = rand:uniform(255),
	SIs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	OPCs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RK = {NA, Keys, Mode},
	{ok, _AS} = m3ua:as_add(undefined, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]),
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(demo_as)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "as" ++ integer_to_list(erlang:unique_integer([positive])),
	{ok, AsNode} = slave:start_link(Host, Node, ErlFlags),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, open, [0, [{callback, {demo_as, self()}}]]),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, open, [0, [{callback, {demo_as, self()}}]]),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, open, [0, [{callback, {demo_as, self()}}]]),
	{ok, Assoc1} = rpc:call(AsNode, m3ua, sctp_establish, [ClientEP1, {127,0,0,1}, Port, []]),
	{ok, Assoc2} = rpc:call(AsNode, m3ua, sctp_establish, [ClientEP2, {127,0,0,1}, Port, []]),
	{ok, Assoc3} = rpc:call(AsNode, m3ua, sctp_establish, [ClientEP3, {127,0,0,1}, Port, []]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	F1  = fun() ->
		F2 = fun() ->
			case mnesia:read(m3ua_as, RK, read)  of
				[] ->
					not_found;
				[#m3ua_as{} = As] ->
					As
			end
		end,
		case mnesia:transaction(F2) of
			{atomic, As1} ->
				As1;
			{aboarted, Reason} ->
				Reason
		end
	end,
	FilterState = fun(IsAspState, Asps) ->
			F = fun(#m3ua_asp{state = AspState}) when AspState == IsAspState ->
					true;
				(_) ->
					false
			end,
			lists:filter(F, Asps)
	end,
	{ok, _RoutingContext1} = rpc:call(AsNode, m3ua, register, [ClientEP1, Assoc1, NA, Keys, Mode]),
	{ok, _RoutingContext2} = rpc:call(AsNode, m3ua, register, [ClientEP2, Assoc2, NA, Keys, Mode]),
	{ok, _RoutingContext3} = rpc:call(AsNode, m3ua, register, [ClientEP3, Assoc3, NA, Keys, Mode]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	#m3ua_as{state = inactive, asp = Asps5} = F1(),
	2 = length(FilterState(active, Asps5)),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	#m3ua_as{state = active, asp = Asps6} = F1(),
	3 = length(FilterState(active, Asps6)).

as_state_inactive() ->
	[{userdata, [{doc, "Insuffient ASPs, AS state change active to inactive"}]}].

as_state_inactive(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(10),
	DPC = rand:uniform(255),
	SIs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	OPCs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RK = {NA, Keys, Mode},
	{ok, _AS} = m3ua:as_add(undefined, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	{ok, _ServerEP} = m3ua:open(Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]),
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(demo_as)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "as" ++ integer_to_list(erlang:unique_integer([positive])),
	{ok, AsNode} = slave:start_link(Host, Node, ErlFlags),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, open, [0, [{callback, {demo_as, self()}}]]),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, open, [0, [{callback, {demo_as, self()}}]]),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, open, [0, [{callback, {demo_as, self()}}]]),
	{ok, Assoc1} = rpc:call(AsNode, m3ua, sctp_establish, [ClientEP1, {127,0,0,1}, Port, []]),
	{ok, Assoc2} = rpc:call(AsNode, m3ua, sctp_establish, [ClientEP2, {127,0,0,1}, Port, []]),
	{ok, Assoc3} = rpc:call(AsNode, m3ua, sctp_establish, [ClientEP3, {127,0,0,1}, Port, []]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	F1  = fun() ->
		F2 = fun() ->
			case mnesia:read(m3ua_as, RK, read)  of
				[] ->
					not_found;
				[#m3ua_as{} = As] ->
					As
			end
		end,
		case mnesia:transaction(F2) of
			{atomic, As1} ->
				As1;
			{aboarted, Reason} ->
				Reason
		end
	end,
	FilterState = fun(IsAspState, Asps) ->
			F = fun(#m3ua_asp{state = AspState}) when AspState == IsAspState ->
					true;
				(_) ->
					false
			end,
			lists:filter(F, Asps)
	end,
	{ok, _RoutingContext1} = rpc:call(AsNode, m3ua, register, [ClientEP1, Assoc1, NA, Keys, Mode]),
	{ok, _RoutingContext2} = rpc:call(AsNode, m3ua, register, [ClientEP2, Assoc2, NA, Keys, Mode]),
	{ok, _RoutingContext3} = rpc:call(AsNode, m3ua, register, [ClientEP3, Assoc3, NA, Keys, Mode]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	#m3ua_as{state = active, asp = Asps1} = F1(),
	3 = length(FilterState(active, Asps1)),
	ok = rpc:call(AsNode, m3ua, asp_inactive, [ClientEP1, Assoc1]),
	#m3ua_as{state = inactive, asp = Asps2} = F1(),
	2 = length(FilterState(active, Asps2)).

as_side_state_changes_1() ->
	[{userdata, [{doc, "AS and ASP state changes with Traffic
			maintenance messages and Notification messages"}]}].

as_side_state_changes_1(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(10),
	DPC = rand:uniform(255),
	SIs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	OPCs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RK = {NA, Keys, Mode},
	Port = rand:uniform(64511) + 1024,
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(demo_sg)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "sg" ++ integer_to_list(erlang:unique_integer([positive])),
	{ok, SgNode} = slave:start_link(Host, Node, ErlFlags),
	{ok, _} = rpc:call(SgNode, m3ua_app, install, [[SgNode]]),
	ok = rpc:call(SgNode, application, start, [m3ua]),
	{ok, _ServerEP} = rpc:call(SgNode, m3ua, open, [Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]]),
	{ok, _AS} = rpc:call(SgNode, m3ua, as_add, [undefined, NA, Keys, Mode, MinAsps, MaxAsps]),
	{ok, ClientEP1} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, ClientEP2} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, ClientEP3} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc1} = m3ua:sctp_establish(ClientEP1, {127,0,0,1}, Port, []),
	{ok, Assoc2} = m3ua:sctp_establish(ClientEP2, {127,0,0,1}, Port, []),
	{ok, Assoc3} = m3ua:sctp_establish(ClientEP3, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP1, Assoc1),
	ok = m3ua:asp_up(ClientEP2, Assoc2),
	ok = m3ua:asp_up(ClientEP3, Assoc3),
	F1  = fun() ->
		F2 = fun() ->
			case mnesia:read(m3ua_as, RK, read)  of
				[] ->
					not_found;
				[#m3ua_as{} = As] ->
					As
			end
		end,
		case mnesia:transaction(F2) of
			{atomic, As1} ->
				As1;
			{aboarted, Reason} ->
				Reason
		end
	end,
	FilterState = fun(IsAspState, Asps) ->
			F = fun(#m3ua_asp{state = AspState}) when AspState == IsAspState ->
					true;
				(_) ->
					false
			end,
			lists:filter(F, Asps)
	end,
	{ok, _RoutingContext1} = m3ua:register(ClientEP1, Assoc1, NA, Keys, Mode),
	{ok, _RoutingContext2} = m3ua:register(ClientEP2, Assoc2, NA, Keys, Mode),
	{ok, _RoutingContext3} = m3ua:register(ClientEP3, Assoc3, NA, Keys, Mode),
	ok = m3ua:asp_active(ClientEP1, Assoc1),
	ok = m3ua:asp_active(ClientEP2, Assoc2),
	ok = m3ua:asp_active(ClientEP3, Assoc3),
	receive after 250 -> ok end,
	#m3ua_as{state = active, asp = Asps1} = F1(),
	3 = length(FilterState(active, Asps1)),
	ok = m3ua:asp_inactive(ClientEP1, Assoc1),
	receive after 250 -> ok end,
	#m3ua_as{state = inactive, asp = Asps2} = F1(),
	2 = length(FilterState(active, Asps2)),
	ok = m3ua:asp_active(ClientEP1, Assoc1),
	receive after 250 -> ok end,
	#m3ua_as{state = active, asp = Asps3} = F1(),
	3 = length(FilterState(active, Asps3)).

as_side_state_changes_2() ->
	[{userdata, [{doc, "AS and ASP state changes with State
			Maintenance messages and Notification messages"}]}].

as_side_state_changes_2(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(10),
	DPC = rand:uniform(255),
	SIs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	OPCs = [rand:uniform(255) || _  <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RK = {NA, Keys, Mode},
	Port = rand:uniform(64511) + 1024,
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(demo_sg)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "sg" ++ integer_to_list(erlang:unique_integer([positive])),
	{ok, SgNode} = slave:start_link(Host, Node, ErlFlags),
	{ok, _} = rpc:call(SgNode, m3ua_app, install, [[SgNode]]),
	ok = rpc:call(SgNode, application, start, [m3ua]),
	{ok, _ServerEP} = rpc:call(SgNode, m3ua, open, [Port,
		[{sctp_role, server}, {m3ua_role, sgp}, {callback, {demo_sg, self()}}]]),
	{ok, _AS} = rpc:call(SgNode, m3ua, as_add, [undefined, NA, Keys, Mode, MinAsps, MaxAsps]),
	{ok, ClientEP1} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, ClientEP2} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, ClientEP3} = m3ua:open(0, [{callback, {demo_as, self()}}]),
	{ok, Assoc1} = m3ua:sctp_establish(ClientEP1, {127,0,0,1}, Port, []),
	{ok, Assoc2} = m3ua:sctp_establish(ClientEP2, {127,0,0,1}, Port, []),
	{ok, Assoc3} = m3ua:sctp_establish(ClientEP3, {127,0,0,1}, Port, []),
	ok = m3ua:asp_up(ClientEP1, Assoc1),
	ok = m3ua:asp_up(ClientEP2, Assoc2),
	ok = m3ua:asp_up(ClientEP3, Assoc3),
	F1  = fun() ->
		F2 = fun() ->
			case mnesia:read(m3ua_as, RK, read)  of
				[] ->
					not_found;
				[#m3ua_as{} = As] ->
					As
			end
		end,
		case mnesia:transaction(F2) of
			{atomic, As1} ->
				As1;
			{aboarted, Reason} ->
				Reason
		end
	end,
	FilterState = fun(IsAspState, Asps) ->
			F = fun(#m3ua_asp{state = AspState}) when AspState == IsAspState ->
					true;
				(_) ->
					false
			end,
			lists:filter(F, Asps)
	end,
	{ok, _RoutingContext1} = m3ua:register(ClientEP1, Assoc1, NA, Keys, Mode),
	{ok, _RoutingContext2} = m3ua:register(ClientEP2, Assoc2, NA, Keys, Mode),
	{ok, _RoutingContext3} = m3ua:register(ClientEP3, Assoc3, NA, Keys, Mode),
	ok = m3ua:asp_active(ClientEP1, Assoc1),
	ok = m3ua:asp_active(ClientEP2, Assoc2),
	ok = m3ua:asp_active(ClientEP3, Assoc3),
	receive after 500 -> ok end,
	ok = m3ua:asp_down(ClientEP1, Assoc1),
	receive after 500 -> ok end,
	#m3ua_as{state = inactive, asp = Asps1} = F1(),
	2 = length(FilterState(active, Asps1)),
	1 = length(FilterState(inactive, Asps1)),
	ok = m3ua:asp_down(ClientEP2, Assoc2),
	#m3ua_as{state = inactive, asp = Asps2} = F1(),
	1 = length(FilterState(active, Asps2)),
	2 = length(FilterState(inactive, Asps2)),
	ok = m3ua:asp_up(ClientEP2, Assoc2),
	#m3ua_as{state = inactive, asp = Asps3} = F1(),
	1 = length(FilterState(active, Asps3)),
	2 = length(FilterState(inactive, Asps3)),
	ok = m3ua:asp_active(ClientEP2, Assoc2),
	#m3ua_as{state = inactive, asp = Asps4} = F1(),
	2 = length(FilterState(active, Asps4)),
	1 = length(FilterState(inactive, Asps4)),
	ok = m3ua:asp_up(ClientEP1, Assoc1),
	#m3ua_as{state = inactive, asp = Asps5} = F1(),
	2 = length(FilterState(active, Asps5)),
	1 = length(FilterState(inactive, Asps5)),
	ok = m3ua:asp_active(ClientEP1, Assoc1),
	#m3ua_as{state = inactive, asp = Asps6} = F1(),
	3 = length(FilterState(active, Asps6)),
	0 = length(FilterState(inactive, Asps6)).

%%---------------------------------------------------------------------
%%  Internal functions
%%---------------------------------------------------------------------


