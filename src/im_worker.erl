-module(im_worker).
-author('wcy123@gmail.com').
-export([do_work/5, do_work_async/4]).
-compile([{parse_transform, lager_transform}]).


do_work_async(WorkerName, M,F,A) ->
    Self = self(),
    spawn(?MODULE, do_work, [Self, WorkerName, M, F, A]),
    receive
        Self ->
            ok
    end.

do_work(Pid, WorkerName, M, F, A) ->
    WorkerPid = poolboy:checkout(WorkerName, is_block(), timeout()),
    Pid ! Pid,
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
