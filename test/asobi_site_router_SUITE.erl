%% The site is plain server-rendered Nova (no Arizona, no live WebSocket).
%% Guard that no WebSocket route reappears, that the core pages route, and
%% that every route renders to valid iodata without crashing.
-module(asobi_site_router_SUITE).
-compile([export_all, nowarn_export_all]).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

all() ->
    [no_ws_route, has_core_routes, renders_all_routes, blog_post_runs_mount].

%%====================================================================

routes() ->
    [#{routes := Routes}] = asobi_site_router:routes(prod),
    Routes.

paths() ->
    [element(1, R) || R <- routes()].

no_ws_route(_Config) ->
    Paths = paths(),
    ?assertNot(lists:member(~"/ws", Paths)),
    ?assertNot(lists:member(~"/arizona/ws", Paths)).

has_core_routes(_Config) ->
    Paths = paths(),
    [?assert(lists:member(P, Paths)) || P <- [~"/", ~"/heartbeat", ~"/docs"]].

%% Every routed controller must return valid iodata - the missing-binding
%% crash that took the site down on /blog/:slug renders fine here.
renders_all_routes(_Config) ->
    Slug = maps:get(slug, hd(asobi_site_blog_posts:all())),
    Req = #{bindings => #{~"slug" => Slug}},
    [render_ok(R, Req) || R <- routes()].

render_ok(Route, Req) ->
    Fun = element(2, Route),
    case is_function(Fun, 1) of
        true ->
            case Fun(Req) of
                {status, _Code, _Headers, Body} -> _ = iolist_to_binary(Body);
                {status, _Code} -> ok
            end;
        false ->
            ok
    end.

%% Regression guard: render_view/2 must detect and run mount/1 even when the
%% view module has not been loaded yet (lazy code loading in the release was
%% why function_exported/3 returned false and mount/1 was skipped in prod).
blog_post_runs_mount(_Config) ->
    code:purge(asobi_site_blog_post_view),
    code:delete(asobi_site_blog_post_view),
    #{slug := Slug, title := Title} = hd(asobi_site_blog_posts:all()),
    Req = #{bindings => #{~"slug" => Slug}},
    {_Path, Fun, _Opts} = lists:keyfind(~"/blog/:slug", 1, routes()),
    {status, 200, _Headers, Body} = Fun(Req),
    Html = iolist_to_binary(Body),
    ?assertNotEqual(nomatch, binary:match(Html, Title)),
    ?assertEqual(nomatch, binary:match(Html, ~"Post not found")).
