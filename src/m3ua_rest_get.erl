%%% m3ua_rest_get.erl
%%% vim: ts=3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2016 - 2025 SigScale Global Inc.
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
-module(m3ua_rest_get).
-copyright('Copyright (c) 2016 - 2025 SigScale Global Inc.').

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
		Body :: list() | nobody | {Fun, Arg},
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
%% @doc Callback handler for inets httpd.
do(#mod{method = Method, parsed_header = _Headers, request_uri = Uri,
		data = Data} = ModData) ->
	case Method of
		"GET" ->
			case proplists:get_value(status, Data) of
				{_StatusCode, _PhraseArgs, _Reason} ->
					{proceed, Data};
				undefined ->
					case proplists:get_value(response, Data) of
						undefined ->
							case lists:keyfind(resource, 1, Data) of
								false ->
									{proceed, Data};
								{_, Resource} ->
									Path = http_uri:decode(Uri),
									parse_query(Resource, ModData, httpd_util:split_path(Path))
							end;
						_Response ->
							{proceed,  Data}
					end
			end;
		_ ->
			{proceed, Data}
	end.

%% @hidden
parse_query(Resource, ModData, {Path, []}) ->
	do_get(Resource, ModData, string:tokens(Path, "/"), []);
%parse_query(Resource, ModData, {Path, "?" ++ Query}) ->
%	do_get(Resource, ModData, string:tokens(Path, "/"),
%		m3ua_rest:parse_query(Query));
parse_query(_, _, _) ->
	Response = "<h2>HTTP Error 404 - Not Found</h2>",
	{break, [{response, {404, Response}}]}.

%% @hidden
do_get(Resource, #mod{parsed_header = Headers} = ModData,
		["metrics"], Query) ->
	do_response(ModData, Resource:get_metrics(Query, Headers));
do_get(_, _, _, _) ->
	Response = "<h2>HTTP Error 404 - Not Found</h2>",
	{break, [{response, {404, Response}}]}.

%% @hidden
do_response(ModData, {ok, Headers, ResponseBody}) ->
	Size = integer_to_list(iolist_size(ResponseBody)),
	NewHeaders = Headers ++ [{content_length, Size}],
	send(ModData, 200, NewHeaders, ResponseBody),
	{proceed,[{response,{already_sent, 200, Size}}]};
do_response(_ModData, {error, 400}) ->
	Response = "<h2>HTTP Error 400 - Bad Request</h2>",
	{break, [{response, {400, Response}}]};
do_response(_ModData, {error, 404}) ->
	Response = "<h2>HTTP Error 404 - Not Found</h2>",
	{break, [{response, {404, Response}}]};
do_response(_ModData, {error, 412}) ->
	Response = "<h2>HTTP Error 412 - Precondition Failed</h2>",
	{break, [{response, {412, Response}}]};
do_response(_ModData, {error, 416}) ->
	Response = "<h2>HTTP Error 416 - Range Not Satisfiable</h2>",
	{break, [{response, {416, Response}}]};
do_response(_ModData, {error, 500}) ->
	Response = "<h2>HTTP Error 500 - Server Error</h2>",
	{break, [{response, {500, Response}}]}.


%% @hidden
send(#mod{socket = Socket, socket_type = SocketType} = ModData,
		StatusCode, Headers, ResponseBody) ->
	httpd_response:send_header(ModData, StatusCode, Headers),
	httpd_socket:deliver(SocketType, Socket, ResponseBody).

