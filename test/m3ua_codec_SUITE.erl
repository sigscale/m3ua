%%% m3ua_codec_SUITE.erl
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
%%%  Test suite for the m3ua codec.
%%%
-module(m3ua_codec_SUITE).
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
	[asp_up, asp_up_ack, asp_down, asp_down_ack].

%%---------------------------------------------------------------------
%%  Test cases
%%---------------------------------------------------------------------
asp_up() ->
	[{userdata, [{doc, "ASP UP Message encoding and decoding"}]}].
	
asp_up(_Config) ->
	AspIdentifier = [{?ASPIdentifier, rand:uniform(100)}],
	RecAspUp = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP,
			params = AspIdentifier},
	BinAspUp = m3ua_codec:m3ua(RecAspUp),
	0 = size(BinAspUp) rem 4,
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP,
			params = Params} = m3ua_codec:m3ua(BinAspUp),
	0 = size(Params) rem 4,
	AspIdentifier = m3ua_codec:parameters(Params).

asp_up_ack() ->
	[{userdata, [{doc, "ASP UP Ack Message encoding and decoding"}]}].

asp_up_ack(_Config) ->
	AspIdentifier = [{?ASPIdentifier, rand:uniform(100)}],
	RecAspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK,
			params = AspIdentifier},
	BinAspUpAck = m3ua_codec:m3ua(RecAspUpAck),
	0 = size(BinAspUpAck) rem 4,
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK,
			params = Params} = m3ua_codec:m3ua(BinAspUpAck),
	0 = size(Params) rem 4,
	AspIdentifier = m3ua_codec:parameters(Params).

asp_down(_Config) ->
	[{userdata, [{doc, "ASP Down Message encoding and decoding"}]}].

asp_down(_Config) ->
	RecAspDown = #m3ua{class = ?ASPSMMessage,
			type = ?ASPSMASPDN, params = <<>>},
	BinAspDown = m3ua_codec:m3ua(RecAspDown),
	0 = size(BinAspDown) rem 4,
	RecAspDown = m3ua_codec:m3ua(BinAspDown).

asp_down_ack() ->
	[{userdata, [{doc, "ASP Down Ack Message encoding and decoding"}]}].

asp_down_ack(_Config) ->
	RecAspDownAck = #m3ua{class = ?ASPSMMessage,
			type = ?ASPSMASPDNACK, params = <<>>},
	BinAspDownAck = m3ua_codec:m3ua(RecAspDownAck),
	0 = size(BinAspDownAck) rem 4,
	RecAspDownAck = m3ua_codec:m3ua(BinAspDownAck).

%%---------------------------------------------------------------------
%%  Internal functions
%%---------------------------------------------------------------------

