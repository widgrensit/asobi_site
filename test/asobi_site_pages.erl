%% Route and view helpers shared by the test suites.
%%
%% These live outside a _SUITE module on purpose: elp reads an exported /1 in a
%% suite that is absent from all/0 as an unreachable test case, so helpers of
%% that arity have to live somewhere that is not a suite.
-module(asobi_site_pages).

-export([
    routes/0,
    paths/0,
    route/1,
    body/2,
    is_md/1,
    md_path/1,
    md_routes/0,
    not_a_page/0,
    views/0,
    tree/1
]).

-spec routes() -> [tuple()].
routes() ->
    [#{routes := Routes}] = asobi_site_router:routes(prod),
    Routes.

-spec paths() -> [binary() | string()].
paths() ->
    [element(1, R) || R <- routes()].

-spec route(binary()) -> tuple().
route(Path) ->
    lists:keyfind(Path, 1, routes()).

%% Render a route and assert its content type, returning the body.
-spec body(binary(), binary()) -> binary().
body(Path, ContentType) ->
    {_P, Fun, _Opts} = route(Path),
    {status, 200, Headers, Body} = Fun(#{}),
    ContentType = maps:get(~"content-type", Headers),
    iolist_to_binary(Body).

-spec is_md(binary() | string()) -> boolean().
is_md(Path) when is_binary(Path) -> binary:longest_common_suffix([Path, ~".md"]) =:= 3;
is_md(_Path) -> false.

-spec md_path(binary()) -> binary().
md_path(~"/") -> ~"/index.md";
md_path(Path) -> <<Path/binary, ".md">>.

-spec md_routes() -> [tuple()].
md_routes() ->
    [R || R <- routes(), is_md(element(1, R))].

%% Routed, but not a page: probes, feeds, the dynamic blog template, a 301,
%% and the machine-readable files themselves.
-spec not_a_page() -> [binary()].
not_a_page() ->
    [
        ~"/heartbeat",
        ~"/blog/rss.xml",
        ~"/blog/:slug",
        ~"/docs/erlang/getting-started",
        ~"/llms.txt",
        ~"/robots.txt",
        ~"/sitemap.xml"
    ].

%% Every view module, from the .app (rebar3 populates {modules, []} from src/).
%% The blog post view is excluded: its mount/1 needs a slug binding, and its
%% route carries a cowboy binding so it has no .md twin.
-spec views() -> [module()].
views() ->
    _ = application:load(asobi_site),
    {ok, Mods} = application:get_key(asobi_site, modules),
    lists:usort([
        Mod
     || Mod <- Mods,
        nomatch =/= binary:match(atom_to_binary(Mod), ~"_view"),
        Mod =/= asobi_site_blog_post_view
    ]).

-spec tree(module()) -> asobi_site_html:html().
tree(View) ->
    asobi_site_html:render_view(View, #{id => ~"page"}).
