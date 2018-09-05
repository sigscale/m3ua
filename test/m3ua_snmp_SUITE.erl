%%% m3ua_snmp_SUITE.erl
%%% vim: ts=3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2018 SigScale Global Inc.
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
%%%  @doc Test suite for SNMP agent of the {@link //m3ua. m3ua} application.
%%%
-module(m3ua_snmp_SUITE).
-copyright('Copyright (c) 2018 SigScale Global Inc.').

%% common_test required callbacks
-export([suite/0, sequences/0, all/0]).
-export([init_per_suite/1, end_per_suite/1]).
-export([init_per_testcase/2, end_per_testcase/2]).

%% Note: This directive should only be used in test suites.
-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include("m3ua.hrl").

%%---------------------------------------------------------------------
%%  Test server callback functions
%%---------------------------------------------------------------------

-spec suite() -> DefaultData :: [tuple()].
%% Require variables and set default values for the suite.
%%
suite() ->
	Port = rand:uniform(32767) + 32768,
	[{userdata, [{doc, "Test suite for SNMP agent in SigScale M3UA"}]},
	{require, snmp_mgr_agent, snmp},
	{default_config, snmp,
			[{start_agent, true},
			{agent_udp, Port},
			{agent_engine_id, sigscale_snmp_lib:engine_id()},
			{users,
					[{m3ua_mibs_test, [snmpm_user_default, []]}]},
			{managed_agents,
					[{m3ua_mibs_test, [m3ua_mibs_test, {127,0,0,1}, Port, []]}]}]},
	{require, snmp_app},
	{default_config, snmp_app,
			[{manager,
					[{config, [{verbosity, silence}]},
					{server, [{verbosity, silence}]},
					{net_if, [{verbosity, silence}]}]},
			{agent,
					[{config, [{verbosity, silence}]},
					{agent_verbosity, silence},
					{net_if, [{verbosity, silence}]}]}]},
	{timetrap, {minutes, 1}}].

-spec init_per_suite(Config :: [tuple()]) -> Config :: [tuple()].
%% Initialization before the whole suite.
%%
init_per_suite(Config) ->
	PrivDir = ?config(priv_dir, Config),
	application:load(mnesia),
	ok = application:set_env(mnesia, dir, PrivDir),
	{ok, [m3ua_asp, m3ua_as]} = m3ua_app:install(),
	ok = application:start(m3ua),
	ok = ct_snmp:start(Config, snmp_mgr_agent, snmp_app),
	ok = application:start(sigscale_mibs),
	ok = sigscale_mib:load(),
	DataDir = filename:absname(?config(data_dir, Config)),
	TestDir = filename:dirname(DataDir),
	BuildDir = filename:dirname(TestDir),
	MibDir =  BuildDir ++ "/priv/mibs/",
	Mibs = [MibDir ++ "SIGSCALE-M3UA-MIB"],
	ok = ct_snmp:load_mibs(Mibs),
	Config.

-spec end_per_suite(Config :: [tuple()]) -> any().
%% Cleanup after the whole suite.
%%
end_per_suite(Config) ->
	ok = application:stop(m3ua),
	ok = m3ua_mib:unload(),
	ok = sigscale_mib:unload(),
	ok = application:stop(sigscale_mibs),
	ok = ct_snmp:stop(Config).

-spec init_per_testcase(TestCase :: atom(), Config :: [tuple()]) -> Config :: [tuple()].
%% Initialization before each test case.
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
	[get_ep, get_next_ep, get_as, get_next_as, get_asp_sgp, get_next_asp_sgp,
			get_asp_stat, get_next_asp_stat].

%%---------------------------------------------------------------------
%%  Test cases
%%---------------------------------------------------------------------

get_ep() ->
	[{userdata, [{doc, "Get an endpoint (EP) table entry"}]}].

get_ep(_Config) ->
	{ok, _EP} = m3ua:start(#m3ua_fsm_cb{}),
	{value, EpTypeOID} = snmpa:name_to_oid(m3uaEpType),
	EpTypeOID1 = EpTypeOID ++ [1],
	{noError, _, Varbinds} = ct_snmp:get_values(m3ua_mibs_test,
			[EpTypeOID1], snmp_mgr_agent),
	[{varbind, EpTypeOID1, 'INTEGER', 1, _}] = Varbinds.

get_next_ep() ->
	[{userdata, [{doc, "Get next on endpoint (EP) table"}]}].

get_next_ep(_Config) ->
	Port = rand:uniform(64511) + 1024,
	{ok, _EP1} = m3ua:start(#m3ua_fsm_cb{}),
	{ok, _EP2} = m3ua:start(#m3ua_fsm_cb{}, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	{ok, _EP3} = m3ua:start(#m3ua_fsm_cb{}, 0,
			[{role, sgp}, {connect, {172,16,120,123}, Port, []}]),
	{ok, _EP4} = m3ua:start(#m3ua_fsm_cb{}),
	{value, EpTableOID} = snmpa:name_to_oid(m3uaEndPointTable),
	{noError, _, Varbinds} = ct_snmp:get_next_values(m3ua_mibs_test,
			[EpTableOID], snmp_mgr_agent),
	{value, EpTypeOID} = snmpa:name_to_oid(m3uaEpType),
	EpTypeOID1 = EpTypeOID ++ [1],
	[{varbind, EpTypeOID1, 'INTEGER', 1, _}] = Varbinds.

get_as() ->
	[{userdata, [{doc, "Get an application server (AS) table entry"}]}].

get_as(_Config) ->
	Name = "as_" ++ integer_to_list(rand:uniform(255)),
	Keys = [{rand:uniform(16383), [], []}],
	RC = rand:uniform(4294967295),
	{ok, _AS} = m3ua:as_add(Name, RC, undefined, Keys, loadshare, 1, 4),
	{value, AsStateOID} = snmpa:name_to_oid(m3uaSgpIpspAsState),
	AsStateOID1 = AsStateOID ++ [1],
	{noError, _, Varbinds} = ct_snmp:get_values(m3ua_mibs_test,
			[AsStateOID1], snmp_mgr_agent),
	[{varbind, AsStateOID1, 'INTEGER', _, _}] = Varbinds.

get_next_as() ->
	[{userdata, [{doc, "Get next on application server (AS) table"}]}].

get_next_as(_Config) ->
	Name1 = "as_" ++ integer_to_list(rand:uniform(255)),
	Keys1 = [{rand:uniform(16383), [], []}],
	Name2 = "as_" ++ integer_to_list(rand:uniform(255)),
	Keys2 = [{rand:uniform(16383), [], []}],
	Name3 = "as_" ++ integer_to_list(rand:uniform(255)),
	Keys3 = [{rand:uniform(16383), [], []}],
	RC1 = rand:uniform(4294967295),
	RC2 = rand:uniform(4294967295),
	RC3 = rand:uniform(4294967295),
	{ok, _AS1} = m3ua:as_add(Name1, RC1, undefined, Keys1, loadshare, 1, 4),
	{ok, _AS2} = m3ua:as_add(Name2, RC2, 1, Keys2, override, 1, 2),
	{ok, _AS3} = m3ua:as_add(Name3, RC3, 1, Keys3, broadcast, 1, 2),
	{value, AsTableOID} = snmpa:name_to_oid(m3uaSgpIpspAsTable),
	{noError, _, Varbinds} = ct_snmp:get_next_values(m3ua_mibs_test,
			[AsTableOID], snmp_mgr_agent),
	{value, AsStateOID} = snmpa:name_to_oid(m3uaSgpIpspAsState),
	AsStateOID1 = AsStateOID ++ [1],
	[{varbind, AsStateOID1, 'INTEGER', _, _}] = Varbinds.

get_asp_sgp() ->
	[{userdata, [{doc, "Get an ASP/SGP table entry"}]}].

get_asp_sgp(_Config) ->
	Name = "as_" ++ integer_to_list(rand:uniform(255)),
	Keys = [{rand:uniform(16383), [], []}],
	RC = rand:uniform(4294967295),
	{ok, _AS} = m3ua:as_add(Name, RC, undefined, Keys, loadshare, 1, 4),
	{value, AspStateOID} = snmpa:name_to_oid(m3uaAspSgpState),
	AspStateOID1 = AspStateOID ++ [1, 1],
	{noError, _, Varbinds} = ct_snmp:get_values(m3ua_mibs_test,
			[AspStateOID1], snmp_mgr_agent),
	[{varbind, AspStateOID1, 'NULL', noSuchInstance, _}] = Varbinds.

get_next_asp_sgp() ->
	[{userdata, [{doc, "Get next on ASP/SGP table"}]}].

get_next_asp_sgp(_Config) ->
	{value, AspSgpTableOID} = snmpa:name_to_oid(m3uaAspSgpTable),
	{noError, _, Varbinds} = ct_snmp:get_next_values(m3ua_mibs_test,
			[AspSgpTableOID], snmp_mgr_agent),
	% ASP/SGP table is empty, next is AS table
	{value, SgpIpspAsStateOID} = snmpa:name_to_oid(m3uaSgpIpspAsState),
	SgpIpspAsStateOID1 = SgpIpspAsStateOID ++ [1],
	[{varbind, SgpIpspAsStateOID1, 'INTEGER', _, _}] = Varbinds.

get_asp_stat() ->
	[{userdata, [{doc, "Get ASP statistics table entry"}]}].

get_asp_stat(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	RefC = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, [{role, sgp}]),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	{_, Assoc} = lists:keyfind(ClientEP, 1, m3ua:get_assoc()),
	{value, AspupOut} = snmpa:name_to_oid(m3uaAspStatAspupOut),
	AspupOutOID = AspupOut ++ [Assoc],
	{noError, _, Varbinds} = ct_snmp:get_values(m3ua_mibs_test,
			[AspupOutOID], snmp_mgr_agent),
	[{varbind, AspupOutOID, 'Counter32', _, _}] = Varbinds,
	ok = m3ua:stop(ServerEP),
	ok = m3ua:stop(ClientEP).

get_next_asp_stat() ->
	[{userdata, [{doc, "Get next on ASP statistics table"}]}].

get_next_asp_stat(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	RefC = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, [{role, sgp}]),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	{value, AspStatTableOID} = snmpa:name_to_oid(m3uaAspStatTable),
	{noError, _, Varbinds} = ct_snmp:get_next_values(m3ua_mibs_test,
			[AspStatTableOID], snmp_mgr_agent),
	[{varbind, _OID, 'Counter32', _, _}] = Varbinds,
	ok = m3ua:stop(ServerEP),
	ok = m3ua:stop(ClientEP).

%%---------------------------------------------------------------------
%%  Internal functions
%%---------------------------------------------------------------------

callback(Ref) ->
	Finit = fun(_Module, _Asp, _EP, _EpName, _Assoc, Pid) ->
				Pid ! Ref,
				{ok, once, []}
	end,
	#m3ua_fsm_cb{init = Finit, extra = [self()]}.

wait(Ref) ->
	receive
		Ref ->
			ok
	end.
