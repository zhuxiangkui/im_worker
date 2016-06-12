-module(im_worker).
-author('wcy123@gmail.com').
-export([do_work/4, do_work_async/4]).
-compile([{parse_transform, lager_transform}]).


do_work_async(WorkerName, M,F,A) ->
    spawn(?MODULE, do_work, [WorkerName, M, F, A]).

do_work(WorkerName, M, F, A) ->
    WorkerPid = poolboy:checkout(WorkerName, is_block(), timeout()),
    try
        im_worker_server:evaluate(WorkerPid, M, F, A)
    catch
        Class:Error ->
            lager:error("im worker error ~p:~p M = ~p, F = ~p, A = ~p, Stack=~p~n",
                        [Class, Error, M, F, A, erlang:get_stacktrace()]),
            {error, {Class, Error}}
    after
        poolboy:checkin(WorkerName, WorkerPid)
    end.

is_block() -> true.
timeout() -> infinity.
