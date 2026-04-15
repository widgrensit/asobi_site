-module(asobi_site_docs_lua_cookbook_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-lua-cookbook", title => ~"Lua cookbook — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(_Bindings) ->
    asobi_site_docs_coming_soon_view:render_with(
        ~"/docs/lua/cookbook",
        ~"Lua cookbook",
        ~"Copy-pasteable Lua patterns for common gameplay tasks: ticking AI, spatial queries, economy grants, reconnection flows, phased matches, voting.",
        [
            ~"https://github.com/widgrensit/asobi/blob/main/guides/lua-scripting.md",
            ~"https://github.com/widgrensit/asobi/blob/main/guides/lua-bots.md"
        ]
    ).
