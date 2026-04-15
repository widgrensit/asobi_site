-module(asobi_site_docs_tictactoe_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-tictactoe", title => ~"Tic-tac-toe tutorial — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(_Bindings) ->
    asobi_site_docs_coming_soon_view:render_with(
        ~"/docs/tutorials/tic-tac-toe",
        ~"Tic-tac-toe tutorial",
        ~"A two-player turn-based game, built step by step in Lua (and Erlang). We'll cover match state, input validation, win detection, and broadcasting.",
        [
            ~"https://github.com/widgrensit/asobi/blob/main/guides/getting-started.md",
            ~"https://github.com/widgrensit/asobi/blob/main/guides/lua-scripting.md"
        ]
    ).
