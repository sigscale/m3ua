%%% m3ua.hrl
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
%%%
%% M3UA Message Classes
-define(MGMTMessage,       0).
-define(TransferMessage,   1).
-define(SSNMMessage,       2).
-define(ASPSMMessage,      3).
-define(ASPTMMessage,      4).
-define(RKMMessage,        9).

%% M3UA MGMT Message types
-define(MGMTError,         0).
-define(MGMTNotify,        1).

%% M3UA Transfer Message types
-define(TransferMessageReserved,       0).
-define(TransferMessageData,           1).

%% M3UA SSNM Message types
-define(SSNMReserved,       0).
-define(SSNMDUNA,           1).
-define(SSNMDAVA,           2).
-define(SSNMDAUD,           3).
-define(SSNMSCON,           4).
-define(SSNMDUPU,           5).
-define(SSNMDRST,           6).

%% M3UA ASPSM Message types
-define(ASPSMReserved,      0).
-define(ASPSMASPUP,         1).
-define(ASPSMASPDN,         2).
-define(ASPSMBEAT,          3).
-define(ASPSMASPUPACK,      4).
-define(ASPSMASPDNACK,      5).
-define(ASPSMBEATACK,       6).

%% M3UA ASPTM Message types
-define(ASPTMReserved,      0).
-define(ASPTMASPAC,         1).
-define(ASPTMASPIA,         2).
-define(ASPTMASPACACK,      3).
-define(ASPTMASPIAACK,      4).

%% M3UA RKM Message types
-define(RKMReserved,        0).
-define(RKMREGREQ,          1).
-define(RKMREGRSP,          2).
-define(RKMDEREGREQ,        3).
-define(RKMDEREGRSP,        4).

%% M3UA Common Parameters
-define(InfoString,                 4).
-define(RoutingContext,             6).
-define(DiagnosticInformation,      7).
-define(HeartbeatData,              9).
-define(TrafficModeType,            11).
-define(ErrorCode,                  12).
-define(Status,                     13).
-define(ASPIdentifier,              17).
-define(AffectedPointCode,          18).
-define(CorrelationID,              19).

%% M3UA Spefici Parameters
-define(NetworkAppearance,          512).
-define(UserCause,                  516).
-define(CongestionIndications,      517).
-define(ConcernedDestination,       518).
-define(RoutingKey,                 519).
-define(RegistrationResult,         520).
-define(DeregistrationResult,       521).
-define(LocalRoutingKeyIdentifier,  522).
-define(DestinationPointCode,       523).
-define(ServiceIndicators,          524).
-define(OriginatingPointCodeList,   526).
-define(ProtocolData,               528).
-define(RegistrationStatus,         530).
-define(DeregistrationStatus,       531).

-type tmt() :: override | loadshare | broadcast.
-type key() :: {DPC :: pos_integer(), [SI :: pos_integer()], [OPC :: pos_integer()]}.
-type routing_key() :: {NA :: pos_integer(), Keys :: [key()], TMT :: tmt()}.

%% M3UA Common Header -- RFC4666, Section-1.3.1
-record(m3ua,
		{version :: byte(),
		class :: byte(),
		type :: byte(),
		params = <<>> :: binary() | [tuple()]}).

-record(protocol_data,
		{opc :: integer(),
		dpc :: integer(),
		si :: integer(),
		ni :: integer(),
		mp :: integer(),
		sls :: integer(),
		data :: binary()}).

-record(m3ua_routing_key,
		{rc :: pos_integer(),
		na :: pos_integer(),
		tmt :: tmt(),
		status :: atom(),
		as :: term,
		lrk_id :: pos_integer(),
		key :: [key()]}).

-record(registration_result,
		{lrk_id :: pos_integer(),
		status :: atom(),
		rc :: integer()}).

-record(m3ua_asp,
		{id :: pos_integer(),
		sgp :: pid(),
		state :: down | inactive | active,
		info :: string()}).

-record(m3ua_as,
		{routing_key :: routing_key(),
		name :: term(),
		min_asp :: pos_integer(),
		max_asp :: pos_integer(),
		state :: down | inactive | active | pending,
		asp :: [#m3ua_asp{}]}).


