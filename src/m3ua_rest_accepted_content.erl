%%% m3ua_rest_accepted_content.erl
%%% vim: ts=3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2016 - 2024 SigScale Global Inc.
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
-module(m3ua_rest_accepted_content).
-copyright('Copyright (c) 2016 - 2024 SigScale Global Inc.').

-export([do/1]).

-include_lib("inets/include/httpd.hrl").

-spec do(ModData) -> Result
	when
		ModData :: #mod{},
		Result :: {proceed, OldData} | {proceed, NewData} | {break, NewData} | done,
		OldData :: list(),
		NewData :: [{response,{StatusCode,Body}}] | [{response,{response,Head,Body}}]
				| [{response,{already_sent,StatusCode,Size}}],
		StatusCode :: integer(),
		Body :: iolist() | nobody | {Fun, Arg},
		Head :: [HeaderOption],
		HeaderOption :: {Option, Value} | {code, StatusCode},
		Option :: accept_ranges | allow
				| cache_control | content_MD5
				| content_encoding | content_language
				| content_length | content_location
				| content_range | content_type | date
				| etag | expires | last_modified
				| location | pragma | retry_after
				| server | trailer | transfer_encoding,
		Value :: string(),
		Size :: term(),
		Fun :: fun((Arg) -> sent| close | Body),
		Arg :: [term()].
% % @doc Callback handler for inets httpd.
do(#mod{method = Method, parsed_header = Headers, request_uri = Uri,
		data = Data} = _ModData) ->
	case proplists:get_value(status, Data) of
		{_StatusCode, _PhraseArgs, _Reason} ->
			{proceed, Data};
		undefined ->
			case proplists:get_value(response, Data) of
				undefined ->
					Path = http_uri:decode(Uri),
					case string:tokens(Path, "/?") of
						["metrics"] ->
							check_content_type_header(Headers, Method, m3ua_rest_prometheus, Data);
						_ ->
							{proceed, Data}
					end;
				_ ->
					{proceed,  Data}
			end
	end.

%% @hidden
check_content_type_header(Headers, Method, Module, Data) ->
	case lists:keyfind("content-type", 1, Headers) of
		false when Method == "DELETE"; Method == "GET" ->
			check_accept_header(Headers, Module, [{resource, Module} | Data]);
		{_, []} when Method == "DELETE"; Method == "GET" ->
			check_accept_header(Headers, Module, [{resource, Module} | Data]);
		{_, ProvidedType1} ->
			[ProvidedType2 | _] = string:tokens(ProvidedType1, [$;]),
			AcceptedTypes = Module:content_types_accepted(),
			case lists:member(ProvidedType2, AcceptedTypes) of
				true ->
					check_accept_header(Headers, Module, [{resource, Module},
							{content_type,  ProvidedType2} | Data]);
				false ->
					Response = "<h2>HTTP Error 415 - Unsupported Media Type</h2>",
					{break, [{response, {415, Response}}]}
			end;
		false ->
			Response = "<h2>HTTP Error 400 - Bad Request</h2>",
			{break, [{response, {400, Response}}]}
	end.

%% @hidden
check_accept_header(Headers, Module, Data) ->
	case lists:keyfind("accept", 1, Headers) of
		{_, AcceptType1} ->
			[AcceptType2 | _] = string:tokens(AcceptType1, [$;]),
			Representations = Module:content_types_provided(),
			case lists:member(AcceptType2, Representations) of
				true ->
					{proceed, [{accept, AcceptType2} | Data]};
				false ->
					Response = "<h2>HTTP Error 415 - Unsupported Media Type</h2>",
					{break, [{response, {415, Response}}]}
			end;
		false ->
			{proceed, Data}
	end.

