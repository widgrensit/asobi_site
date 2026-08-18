%% The site is plain server-rendered Nova (no Arizona, no live WebSocket).
%% Guard that no WebSocket route reappears, that the core pages route, and
%% that every route renders to valid iodata without crashing.
-module(asobi_site_router_SUITE).
%% Explicit rather than export_all: export_all makes every helper look like a
%% test case to elp, which then reports the helpers as unreachable tests and
%% needs a module-level warning suppression to quieten. Listing what CT has to
%% reach says the same thing without either.
-export([
    all/0,
    no_ws_route/1,
    has_core_routes/1,
    renders_all_routes/1,
    blog_post_runs_mount/1,
    erlang_getting_started_redirects/1,
    llms_txt_indexes_every_route/1,
    llms_txt_entries_are_well_formed/1,
    llms_txt_is_plain_text/1,
    robots_txt_points_at_the_sitemap/1,
    sitemap_covers_every_page/1
]).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

all() ->
    [
        no_ws_route,
        has_core_routes,
        renders_all_routes,
        blog_post_runs_mount,
        erlang_getting_started_redirects,
        llms_txt_indexes_every_route,
        llms_txt_entries_are_well_formed,
        llms_txt_is_plain_text,
        robots_txt_points_at_the_sitemap,
        sitemap_covers_every_page
    ].

%%====================================================================

routes() -> asobi_site_pages:routes().

paths() -> asobi_site_pages:paths().

no_ws_route(_Config) ->
    Paths = paths(),
    ?assertNot(lists:member(~"/ws", Paths)),
    ?assertNot(lists:member(~"/arizona/ws", Paths)).

has_core_routes(_Config) ->
    Paths = paths(),
    [
        ?assert(lists:member(P, Paths))
     || P <- [~"/", ~"/heartbeat", ~"/docs", ~"/llms.txt", ~"/robots.txt", ~"/sitemap.xml"]
    ].

llms_entries() ->
    [E || {_Heading, Entries} <- asobi_site_llms:sections(), E <- Entries].

%% The failure mode this exists to prevent: a page is added, nobody touches
%% llms.txt, and the index quietly becomes a lie. That is worse than having
%% no index, because an agent reads it as a complete map and stops looking.
%% Every routed path must be indexed or explicitly excluded, and nothing may
%% be indexed that is no longer routed.
llms_txt_indexes_every_route(_Config) ->
    Indexed = [P || {P, _T, _D} <- llms_entries()],
    Known = Indexed ++ asobi_site_llms:exclusions(),
    Routed = [P || P <- paths(), is_binary(P), not asobi_site_pages:is_md(P)],
    ?assertEqual([], [P || P <- Routed, not lists:member(P, Known)]),
    ?assertEqual([], [P || P <- Indexed, not lists:member(P, Routed)]),
    ?assertEqual([], [P || P <- asobi_site_llms:exclusions(), not lists:member(P, Routed)]),
    %% llms.txt links the .md variant of every entry, so each must resolve.
    ?assertEqual(
        [], [P || P <- Indexed, not lists:member(<<P/binary, ".md">>, paths())]
    ).

%% Titles are what an agent scans to decide whether to fetch, so duplicates
%% are unroutable - Anthropic's own file ships four "Overview" entries.
%% A missing description is a link that costs a fetch to evaluate.
llms_txt_entries_are_well_formed(_Config) ->
    Entries = llms_entries(),
    Titles = [T || {_P, T, _D} <- Entries],
    ?assertEqual(lists:usort(Titles), lists:sort(Titles)),
    ?assertEqual([], [P || {P, _T, D} <- Entries, D =:= ~""]),
    ?assertEqual([], [P || {P, T, _D} <- Entries, T =:= ~""]),
    [?assertMatch(<<"/", _/binary>>, P) || {P, _T, _D} <- Entries].

%% Three sites in the peer corpus answer /llms.txt with HTTP 200 and an HTML
%% body. A soft 404 passes every status-only audit while feeding an agent a
%% page of markup, so assert on the content type and on the body being
%% markdown rather than markup.
llms_txt_is_plain_text(_Config) ->
    Text = asobi_site_pages:body(~"/llms.txt", ~"text/plain; charset=utf-8"),
    ?assertMatch(<<"# asobi\n\n> ", _/binary>>, Text),
    ?assertEqual(nomatch, binary:match(Text, ~"<")),
    %% Links must be absolute: fetched out of band, a relative path is
    %% unresolvable, which is the commonest defect in the peer corpus.
    ?assertEqual(nomatch, binary:match(Text, ~"](/")),
    ?assertNotEqual(nomatch, binary:match(Text, ~"](https://asobi.dev/docs/quickstart.md)")).

robots_txt_points_at_the_sitemap(_Config) ->
    Text = asobi_site_pages:body(~"/robots.txt", ~"text/plain; charset=utf-8"),
    ?assertNotEqual(nomatch, binary:match(Text, ~"Sitemap: https://asobi.dev/sitemap.xml")).

%% The sitemap is derived from the router, so this asserts the derivation
%% rather than a list: every routed page appears exactly once with an
%% absolute URL, every blog post is expanded, and no non-page leaks in.
sitemap_covers_every_page(_Config) ->
    Xml = asobi_site_pages:body(~"/sitemap.xml", ~"application/xml; charset=utf-8"),
    {match, Matches} = re:run(Xml, ~"<loc>(.*?)</loc>", [global, {capture, all_but_first, binary}]),
    Locs = [L || [L] <- Matches],
    [?assertMatch(<<"https://asobi.dev/", _/binary>>, L) || L <- Locs],
    ?assertEqual(lists:usort(Locs), lists:sort(Locs)),
    [
        ?assert(lists:member(<<"https://asobi.dev", P/binary>>, Locs))
     || P <- [~"/", ~"/docs", ~"/docs/quickstart", ~"/cloud", ~"/privacy"]
    ],
    [
        ?assertNot(lists:member(<<"https://asobi.dev", P/binary>>, Locs))
     || P <- [~"/heartbeat", ~"/blog/:slug", ~"/sitemap.xml", ~"/docs/erlang/getting-started"]
    ],
    Slug = maps:get(slug, hd(asobi_site_blog_posts:all())),
    ?assert(lists:member(<<"https://asobi.dev/blog/", Slug/binary>>, Locs)).

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

%% The Erlang getting-started page is retired, not deleted (asobi ADR 0008):
%% asobi's examples/erlang-match README links it by name, so the URL has to
%% keep resolving rather than 404.
erlang_getting_started_redirects(_Config) ->
    {_Path, Fun, _Opts} = lists:keyfind(~"/docs/erlang/getting-started", 1, routes()),
    ?assertEqual({status, 301, #{~"location" => ~"/docs/erlang/api"}, ~""}, Fun(#{})).

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
