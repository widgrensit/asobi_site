-module(asobi_site_docs_lua_callbacks_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-lua-callbacks", title => ~"Game module callbacks — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(_Bindings) ->
    asobi_site_docs_coming_soon_view:render_with(
        ~"/docs/lua/callbacks",
        ~"Game module callbacks",
        ~"The set of functions your Lua game module can implement: init, join, leave, handle_input, tick, get_state, phases, and the vote hooks.",
        [
            ~"https://github.com/widgrensit/asobi/blob/main/guides/lua-scripting.md",
            ~"https://github.com/widgrensit/asobi/blob/main/src/matches/asobi_match.erl"
        ]
    ).
