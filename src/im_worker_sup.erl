-module(im_worker_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    PropLists = application:get_env(im_worker, workers,[]),
    PoolSpecs = lists:map(fun plist_to_pool_spec/1,PropLists),
    {ok, { {one_for_one, 5, 10}, PoolSpecs} }.


plist_to_pool_spec(PropList) ->
    Name = proplists:get_value(worker, PropList, undefined),
    PoolArgs = [{ name, {local, Name} },
                { worker_module, im_worker_server },
                { size , proplists:get_value(pool_size, PropList, 10)},
                { max_overflow , proplists:get_value(max_overflow, PropList, 20)}
               ],
    poolboy:child_spec(Name, PoolArgs, PropList).
