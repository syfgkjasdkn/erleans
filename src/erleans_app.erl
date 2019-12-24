%%%--------------------------------------------------------------------
%%% Copyright Tristan Sloughter 2019. All Rights Reserved.
%%%
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
%%%
%% @doc
%% @end
%%%-------------------------------------------------------------------

-module(erleans_app).

-behaviour(application).

-export([start/2,
         stop/1]).

-include_lib("kernel/include/logger.hrl").

start(_StartType, _StartArgs) ->
    Config = application:get_all_env(erleans),
    {ok, Pid} = erleans_sup:start_link(Config),
    init_providers(),
    {ok, Pid}.

stop(_State) ->
    erleans_cluster:leave(),
    ok.

%% Internal functions

init_providers() ->
    Providers = erleans_config:get(providers, #{}),
    maps:map(fun(ProviderName, Config) ->
                     %% start provider as child of erleans_provider_sup
                     case erleans_provider_sup:start_child(ProviderName, Config) of
                         %% handle crash here so application stops with good error message?
                         {ok, _} ->
                             ok;
                         {error, Reason} ->
                             ?LOG_ERROR("failed to initialize provider ~s: reason=~p", [ProviderName, Reason]),
                             ok
                     end
             end, Providers).
