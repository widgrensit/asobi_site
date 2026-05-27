%% The site is plain server-rendered Nova (no Arizona, no live WebSocket).
%% Guard that no WebSocket route reappears and that the core pages route.
-module(asobi_site_router_SUITE).
-compile([export_all, nowarn_export_all]).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

all() ->
    [no_ws_route, has_core_routes].

%%====================================================================

paths() ->
    [#{routes := Routes}] = asobi_site_router:routes(prod),
    [element(1, R) || R <- Routes].

no_ws_route(_Config) ->
    Paths = paths(),
    ?assertNot(lists:member(~"/ws", Paths)),
    ?assertNot(lists:member(~"/arizona/ws", Paths)).

has_core_routes(_Config) ->
    Paths = paths(),
    [?assert(lists:member(P, Paths)) || P <- [~"/", ~"/heartbeat", ~"/docs"]].
