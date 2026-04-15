-module(asobi_site_app).
-behaviour(application).

-export([start/2, stop/1]).

-spec start(term(), term()) -> {ok, pid()} | {error, term()}.
start(_StartType, _StartArgs) ->
    case asobi_site_sup:start_link() of
        {ok, _} = Ok -> Ok;
        {error, _} = Err -> Err;
        ignore -> {error, ignore}
    end.

-spec stop(term()) -> ok.
stop(_State) ->
    ok.
