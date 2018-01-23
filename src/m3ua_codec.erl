%%% m3ua.erl
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
%%% @doc This library module implements encoding and decoding (CODEC)
%%% 	functions for the M3UA protocol in the
%%% 	{@link //m3ua. m3ua} application.
%%%
-module(m3ua_codec).

-export([m3ua/1]).
-export([parameters/1]).

-export([add_parameter/3, store_parameter/3,
		find_parameter/2, fetch_parameter/2,
		get_all_parameter/2]).

-include("m3ua.hrl").

-spec add_parameter(Tag, Value, Params) -> Params
	when
		Tag :: integer(),
		Value :: term(),
		Params :: [tuple()].
%% @doc Add a parameter to M3UA parameter list
add_parameter(Tag, Value, Params) ->
	[{Tag, Value} | Params].

-spec store_parameter(Tag, Value, Params) -> Params
	when
		Tag :: integer(),
		Value :: term(),
		Params :: [tuple()].
%% @doc Add new parameter to M3UA parameter list
store_parameter(Tag, Value, Params) ->
	lists:keystore(Tag, 1, Params, {Tag, Value}).

-spec find_parameter(Tag, Params) -> Result
	when
		Tag :: integer(),
		Params :: [tuple()],
		Result :: {ok, term()} | {error, not_found}.
%% @doc Search for a parameter in M3UA parameter list
find_parameter(Tag, Params) ->
	case lists:keyfind(Tag, 1, Params) of
		{_, Value} ->
			{ok, Value};
		false ->
			{error, not_found}
	end.

-spec fetch_parameter(Tag, Params) -> Parameter
	when
		Tag :: integer(),
		Params :: [tuple()],
		Parameter :: term().
%% @doc Return the value for an parameter in M3UA parameter list
fetch_parameter(Tag, Params) ->
	case lists:keyfind(Tag, 1, Params) of
		{_, Value} ->
			Value;
		false ->
			exit(not_found)
	end.

-spec get_all_parameter(Tag, Params) -> Params
	when
		Tag :: integer(),
		Params :: [tuple()].
%% @doc Return all value for a parameter which may occur
%% more than once in	the M3UA parameter list.
get_all_parameter(Tag, Params) ->
	F = fun({T, V}) when T == Tag ->
			{true, V};
		(_) ->
			false
	end,
	lists:filtermap(F, Params).

-spec m3ua(CMH) -> CMH
	when
		CMH :: binary() | #m3ua{}.
%% @doc codec for M3UA Common Message Header
%% RFC4666, Section-1.3.1
%%
m3ua(<<_V, _Reserved, Class, Type, _Len:32, Data/binary>>) ->
	#m3ua{class = Class, type = Type, params = Data};
m3ua(#m3ua{class = Class, type = Type, params = Data}) ->
	Len = size(Data) + 8,
	<<1, 0, Class, Type, Len:32, Data/binary>>.

-spec parameters(Message) -> Message
	when
		Message :: binary() | [tuple()].
%% @doc codec for m3ua message
%% RFC4666, Section-3.2
%%
parameters(Message) when is_binary(Message) ->
	parameters(Message, []);
parameters(Message) when is_list(Message) ->
	parameters(Message, <<>>).
%% @hidden
parameters(<<Tag:16, Len:16, Chunk/binary>>, Acc) ->
	DataLen = Len - 4,
	<<Data:DataLen/binary, Rest/binary>> = Chunk,
	parameters(Rest, parameter(Tag, Data, Acc));
parameters([{?InfoString, InfoString} | T], Acc) ->
	IS = list_to_binary(InfoString),
	Len = size(IS) + 4,
	parameters(T, <<Acc/binary, ?InfoString:16, Len:16, IS/binary>>);
parameters([{?RoutingContext, RoutingContext} | T], Acc) ->
	RCs = list_to_binary([<<RC:32>> || RC <- RoutingContext]),
	Len = size(RCs) + 4,
	parameters(T,<<Acc/binary, ?RoutingContext:16, Len:16, RCs/binary>>);
parameters([{?DiagnosticInformation, DiagnosticInfo} | T], Acc) ->
	Len = size(DiagnosticInfo) + 4,
	parameters(T, <<Acc/binary, ?DiagnosticInformation:16,
			Len:16, DiagnosticInfo/binary>>);
parameters([{?HeartbeatData, HeartbeatData} | T], Acc) ->
	Len = size(HeartbeatData) + 4,
	parameters(T, <<Acc/binary, ?HeartbeatData:16,
			Len:16, HeartbeatData/binary>>);
parameters([{?TrafficModeType, override} | T], Acc) ->
	parameters(T, <<Acc/binary, ?TrafficModeType:16, 8:16, 1:32>>);
parameters([{?TrafficModeType, loadshare} | T], Acc) ->
	parameters(T, <<Acc/binary, ?TrafficModeType:16, 8:16, 2:32>>);
parameters([{?TrafficModeType, broadcast} | T], Acc) ->
	parameters(T, <<Acc/binary, ?TrafficModeType:16, 8:16, 3:32>>);
parameters([{?ErrorCode, ErrorCode} | T], Acc) ->
	EC = error_code(ErrorCode),
	parameters(T, <<Acc/binary, ?ErrorCode:16, 8:16, EC/binary>>);
parameters([{?Status, {assc, inactive}} | T], Acc) ->
	parameters(T, <<Acc/binary, ?Status:16, 8:16, 1:16, 2:16>>);
parameters([{?Status, {assc, active}} | T], Acc) ->
	parameters(T, <<Acc/binary, ?Status:16, 8:16, 1:16, 3:16>>);
parameters([{?Status, {assc, pending}} | T], Acc) ->
	parameters(T, <<Acc/binary, ?Status:16, 8:16, 1:16, 4:16>>);
parameters([{?Status, {other, insufficient_asp_resource_active}} | T], Acc) ->
	parameters(T, <<Acc/binary, ?Status:16, 8:16, 2:16, 1:16>>);
parameters([{?Status, {other, alternate_asp_active}} | T], Acc) ->
	parameters(T, <<Acc/binary, ?Status:16, 8:16, 2:16, 2:16>>);
parameters([{?Status, {other, asp_failure}} | T], Acc) ->
	parameters(T, <<Acc/binary, ?Status:16, 8:16, 2:16, 3:16>>);
parameters([{?ASPIdentifier, ASPI} | T], Acc) ->
	parameters(T, <<Acc/binary, ?ASPIdentifier:16, 8:16, ASPI:32>>);
parameters([{?AffectedPointCode, APC} | T], Acc) ->
	APCs = list_to_binary([affected_pc(A) || A <- APC]),
	Len = size(APCs) + 4,
	parameters(T, <<Acc/binary, ?AffectedPointCode:16, Len:16, APCs/binary>>);
parameters([{?CorrelationID, CorrelationID} | T], Acc) ->
erlang:display({?MODULE, ?LINE, Acc, CorrelationID}),
	parameters(T, <<Acc/binary, ?CorrelationID:16, 8:16, CorrelationID:32>>);
parameters([{?NetworkAppearance, NA} | T], Acc) ->
	parameters(T, <<Acc/binary, ?NetworkAppearance:16, 8:16, NA:32>>);
parameters([{?UserCause, UserCause} | T], Acc) ->
	UC = mtp3_user_cause(UserCause),
	parameters(T, <<Acc/binary, ?UserCause:16, 8:18, UC/binary>>);
parameters([{?CongestionIndications, CL} | T], Acc) ->
	CL1 = <<0:24, CL>>,
	parameters(T, <<Acc/binary, ?ConcernedDestination:16, 8:16, CL1/binary>>);
parameters([{?ConcernedDestination, ConcernedDestination} | T], Acc) ->
	CD = <<0, ConcernedDestination/binary>>,
	parameters(T, <<Acc/binary, ?ConcernedDestination:16, 8:16, CD/binary>>);
parameters([{?RoutingKey, RoutingKeys} | T], Acc) ->
	RK = parameters(RoutingKeys),
	Len = size(RK) + 4,
	parameters(T, <<Acc/binary, ?RoutingKey:16, Len:16, RK/binary>>);
parameters([{?RegistrationResult, _} | T], Acc) ->
	parameters(T, Acc);
parameters([{?LocalRoutingKeyIdentifier, LRI} | T], Acc) ->
	parameters(T, <<Acc/binary, ?LocalRoutingKeyIdentifier:16, 8:16, LRI:32>>);
parameters([{?DestinationPointCode, DPC} | T], Acc) ->
	parameters(T, <<Acc/binary, ?DestinationPointCode:16, 8:16, 0, DPC:24>>);
parameters([{?ServiceIndicators, ServiceIndicators} | T], Acc) ->
	SIs = <<SI | SI <- ServiceIndicators>>
	Len = size(SI) + 4,
	parameters(T, <<Acc/binary, ?ServiceIndicators:16, Len:16, SIs/binary);
parameters([{?OriginatingPointCodeList, OPCs} | T], Acc) ->
	OPCL = << <<0, OPC:24>> || OPC <- OPcs>>
	Len = size(OPCL) + 4,
	parameters(T, <<Acc/binary, ?OriginatingPointCodeList:16, Len:16, OPCL/binary);
parameters([{?ProtocolData, #protocol_data{} = ProtocolData} | T], Acc) ->
	PD = protocol_data(ProtocolData),
	Len = size(PD) + 4,
	parameters(T, <<Acc/binary, ?ProtocolData:16, Len:16, PD/binary>>);
parameters([{?RegistrationStatus, _} | T], Acc) ->
	parameters(T, Acc);
parameters([{?DeregistrationStatus, _} | T], Acc) ->
	parameters(T, Acc);
parameters(<<>>, Acc) ->
	lists:reverse(Acc);
parameters([], Acc) when (size(Acc) rem 4) /= 0 ->
	Pad = (size(Acc) rem 4) * 8,
	<<Acc/binary, 0:Pad>>;
parameters(Pad, Acc) when (size(Pad) rem 4) /= 0 ->
	lists:reverse(Acc);
parameters([], Acc) ->
	Acc.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------
%% @hidden
parameter(?InfoString, InfoString, Acc) ->
	[{?InfoString, binary_to_list(InfoString)} | Acc];
parameter(?RoutingContext, RoutingContext, Acc) ->
	RCs = [RC || <<RC:32>> <= RoutingContext],
	[{?RoutingContext, RCs} | Acc];
parameter(?DiagnosticInformation, DiagnositcInfo, Acc) ->
	[{?DiagnosticInformation, DiagnositcInfo} | Acc];
parameter(?HeartbeatData, HartbeatData, Acc) ->
	[{?HeartbeatData, HartbeatData} | Acc];
parameter(?TrafficModeType, <<1:32>>, Acc) ->
	[{?TrafficModeType, override} | Acc];
parameter(?TrafficModeType, <<2:32>>, Acc) ->
	[{?TrafficModeType, loadshare} | Acc];
parameter(?TrafficModeType, <<3:32>>, Acc) ->
	[{?TrafficModeType, broadcast} | Acc];
parameter(?ErrorCode, EC, Acc) ->
	[{?ErrorCode, error_code(EC)} | Acc];
parameter(?Status, <<1:16, 2:16>>, Acc) ->
	[{?Status, {assc, inactive}} | Acc];
parameter(?Status, <<1:16, 3:16>>, Acc) ->
	[{?Status, {assc, active}} | Acc];
parameter(?Status, <<1:16, 4:16>>, Acc) ->
	[{?Status, {assc, pending}} | Acc];
parameter(?Status, <<2:16, 1:16>>, Acc) ->
	[{?Status, {other, insufficient_asp_resource_active}} | Acc];
parameter(?Status, <<2:16, 2:16>>, Acc) ->
	[{?Status, {other, alternate_asp_active}} | Acc];
parameter(?Status, <<2:16, 3:16>>, Acc) ->
	[{?Status, {other, asp_failure}} | Acc];
parameter(?ASPIdentifier, <<ASPIdentifier:32>>, Acc) ->
	[{?ASPIdentifier, ASPIdentifier} | Acc];
parameter(?AffectedPointCode, APC, Acc) ->
	APCs = [affected_pc(A) || <<A:4/binary>> <= APC],
	[{?AffectedPointCode, APCs} | Acc];
parameter(?CorrelationID, CorrelationID, Acc) ->
	CId = binary:decode_unsigned(CorrelationID),
	[{?CorrelationID, CId} | Acc];
parameter(?NetworkAppearance, NetworkAppearance, Acc) ->
	NA = binary:decode_unsigned(NetworkAppearance),
	[{?NetworkAppearance, NA} | Acc];
parameter(?UserCause, UserCause, Acc) ->
	[{?UserCause, mtp3_user_cause(UserCause)} | Acc];
parameter(?CongestionIndications, <<_:24, CL>>, Acc) ->
	[{?CongestionIndications, CL} | Acc];
parameter(?ConcernedDestination, <<_, ConcernedDestination/binary>>, Acc) ->
	[{?ConcernedDestination, ConcernedDestination} | Acc];
parameter(?RoutingKey, RoutingKey, Acc) ->
	[{?RoutingKey, parameters(RoutingKey)} | Acc];
parameter(?RegistrationResult, _, Acc) ->
	Acc;
parameter(?LocalRoutingKeyIdentifier, <<LRI:32>>, Acc) ->
	[{?LocalRoutingKeyIdentifier, LRI} | Acc];
parameter(?DestinationPointCode, <<_Mask, DPC:24>>, Acc) ->
	[{?DestinationPointCode, DPC} | Acc];
parameter(?ServiceIndicators, ServiceIndicators, Acc) ->
	SIs = [SI || SI <= ServiceIndicators],
	[{?ServiceIndicators, SIs} | Acc];
parameter(?OriginatingPointCodeList, OPCs, Acc) ->
	OPCL = [OPC || <<0, OPC:24>> <= OPCs],
	[{?OriginatingPointCodeList, OPCL} | Acc];
parameter(?ProtocolData, PD, Acc) ->
	[{?ProtocolData, protocol_data(PD)} | Acc];
parameter(?RegistrationStatus, _, Acc) ->
	Acc;
parameter(?DeregistrationStatus, _, Acc) ->
	Acc;
parameter(_, _, Acc) ->
	Acc.

-type mtp3_user() :: sccp | tup | isup | broadband_isup
						| satellite_isup | aal2signalling | gcp.

-type mtp3_cause() :: unknown | unequipped_remote_user
							| inaccessible_remote_user.

-spec mtp3_user_cause(UserCause) -> UserCause
	when
		UserCause :: binary() | {User, Cause},
		User :: mtp3_user(),
		Cause :: mtp3_cause().
%% @doc Unavailability Cause and MTP3-User
%%  Identity fields, associated with the Affected
%%  PC in the Affected Point Code parameter
%% @hidden
%%
mtp3_user_cause(<<User:16, Case:16>>) ->
	{mtp3_user(User), mtp3_cause(Case)};
mtp3_user_cause({User, Case}) ->
	U = mtp3_user(User),
	C = mtp3_cause(Case),
	<<U:16, C:16>>.

-spec mtp3_user(User) -> User
	when
		User :: integer() | mtp3_user().
%% @doc MTP3-User Identity field
%% @hidden
%%
mtp3_user(3) -> sccp;
mtp3_user(4) -> tup;
mtp3_user(5) -> isup;
mtp3_user(9) -> broadband_isup;
mtp3_user(10) -> satellite_isup;
mtp3_user(13) -> aal2signalling;
mtp3_user(14) -> gcp; %% Gateway Control Protocol
mtp3_user(sccp) -> 3;
mtp3_user(tup) -> 4;
mtp3_user(isup) -> 5;
mtp3_user(broadband_isup) -> 9;
mtp3_user(satellite_isup) -> 10;
mtp3_user(aal2signalling) -> 13;
mtp3_user(gcp) -> 14.

-spec mtp3_cause(Cause) -> Cause
	when
		Cause :: integer() | mtp3_cause().
%% @doc MTP3 Unavailability Cause
%% @hidden
%%
mtp3_cause(0) -> unknown;
mtp3_cause(1) -> unequipped_remote_user;
mtp3_cause(2) -> inaccessible_remote_user;
mtp3_cause(unknown) -> 0;
mtp3_cause(unequipped_remote_user) -> 1;
mtp3_cause(inaccessible_remote_user) -> 2.

-spec affected_pc(APF) -> APF
	when
		APF :: binary()
				| {itu_pc, Mask, Zone, Region, SP}
				| {ansi_pc, Mask, Network, Cluster, Member},
		Mask :: term(),
		Zone :: term(),
		Region :: term(),
		SP :: term(),
		Network :: term(),
		Cluster :: term(),
		Member :: term().
%% @doc Codec for Affected Point Codes.
%% RFC4666, Section-3.4.1
%% @hidden
%%
affected_pc(<<Mask, 0:10, Zone:3, Region:8, SP:3>>) ->
	{itu_pc, Mask, Zone, Region, SP};
affected_pc(<<Mask, Network, Cluster, Member>>) ->
	{ansi_pc, Mask, Network, Cluster, Member};
affected_pc({itu_pc, Mask, Zone, Region, SP}) ->
	<<Mask, 0:10, Zone:3, Region:8, SP:3>>;
affected_pc({ansi_pc, Mask, Network, Cluster, Member}) ->
	<<Mask, Network, Cluster, Member>>.

-spec error_code(ErrorCode) -> ErrorCode
	when
		ErrorCode :: binary() | atom().
%% @doc codec for error codes
%% RFC4666 - Section 3.8.1
%% @hidden
%%
error_code(<<1:32>>) -> invalid_version;
error_code(<<3:32>>) -> unsupported_message_class;
error_code(<<4:32>>) -> unsupported_message_type;
error_code(<<5:32>>) -> unsupported_traffic_mod_type;
error_code(<<6:32>>) -> unexpected_message;
error_code(<<7:32>>) -> protocol_error;
error_code(<<9:32>>) -> invalid_stream_identifier;
error_code(<<13:32>>) -> refused_management_blocking;
error_code(<<14:32>>) -> asp_identifier_required;
error_code(<<15:32>>) -> invalid_asp_identifier;
error_code(<<33:32>>) -> invalid_parameter_value;
error_code(<<34:32>>) -> parameter_field_error;
error_code(<<35:32>>) -> unexpected_parameter;
error_code(<<36:32>>) -> missing_parameter;
error_code(<<37:32>>) -> destination_status_unknown;
error_code(<<38:32>>) -> invalid_network_appearance;
error_code(<<41:32>>) -> invalid_routing_context;
error_code(<<42:32>>) -> no_configure_AS_for_ASP;
error_code(invalid_version) -> <<1:32>>;
error_code(unsupported_message_class) -> <<3:32>>;
error_code(unsupported_message_type) -> <<4:32>>;
error_code(unsupported_traffic_mod_type) -> <<5:32>>;
error_code(unexpected_message) -> <<6:32>>;
error_code(protocol_error) -> <<7:32>>;
error_code(invalid_stream_identifier) -> <<9:32>>;
error_code(refused_management_blocking) -> <<13:32>>;
error_code(asp_identifier_required) -> <<14:32>>;
error_code(invalid_asp_identifier) -> <<15:32>>;
error_code(invalid_parameter_value) -> <<33:32>>;
error_code(parameter_field_error) -> <<34:32>>;
error_code(unexpected_parameter) -> <<35:32>>;
error_code(missing_parameter) -> <<36:32>>;
error_code(destination_status_unknown) -> <<37:32>>;
error_code(invalid_network_appearance) -> <<38:32>>;
error_code(invalid_routing_context) -> <<41:32>>;
error_code(no_configure_AS_for_ASP) -> <<42:32>>.

-spec protocol_data(ProtocolData) -> ProtocolData
	when
		ProtocolData :: binary() | #protocol_data{}.
%% @doc code for protocol data
%% RFC4666, Section-3.3.1
%% @hidden
%%
protocol_data(<<OPC:32, DPC:32, SI, NI, MP, SLS, UPD/binary>>) ->
	#protocol_data{opc = OPC, dpc = DPC,
			si = SI, ni = NI, mp = MP, sls = SLS, data = UPD};
protocol_data(#protocol_data{opc = OPC, dpc = DPC,
		si = SI, ni = NI, mp = MP, sls = SLS, data = UPD}) ->
	<<OPC:32, DPC:32, SI, NI, MP, SLS, UPD/binary>>.

