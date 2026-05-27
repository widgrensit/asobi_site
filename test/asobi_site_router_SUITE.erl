%% The shared Arizona WebSocket endpoint is provided by arizona_nova_router
%% at /arizona/ws (via nova_apps). The site router must not redefine a bare
%% /ws route: the client never connects there, so it only shadows the real
%% endpoint and invites drift.
-module(asobi_site_router_SUITE).
-compile([export_all, nowarn_export_all]).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

all() ->
    [no_bare_ws_route, has_core_routes].

%%====================================================================

paths() ->
    [#{routes := Routes}] = asobi_site_router:routes(prod),
    [element(1, R) || R <- Routes].

no_bare_ws_route(_Config) ->
    ?assertNot(lists:member(~"/ws", paths())).

has_core_routes(_Config) ->
    Paths = paths(),
    [?assert(lists:member(P, Paths)) || P <- [~"/", ~"/heartbeat", ~"/docs"]].
