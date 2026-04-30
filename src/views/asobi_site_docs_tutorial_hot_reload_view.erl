-module(asobi_site_docs_tutorial_hot_reload_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-tutorial-hr", title => ~"Live-edit your game — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Tutorials / Live-edit your game"
            ]},
            {h1, [], [~"Live-edit your game (hot reload)"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi can swap your ",
                {code, [], [~"match.lua"]},
                ~" while a match is running. Players stay connected, scores stay intact, the next tick uses the new code. ",
                ~"This tutorial walks through editing a behaviour mid-match and watching it take effect without reconnecting."
            ]},

            {h2, [], [~"What you need"]},
            {ul, [], [
                {li, [], [
                    ~"A running Asobi server. The simplest path is the ",
                    {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                    ~" \x{2014} Docker Compose, ~2 minutes."
                ]},
                {li, [], [
                    ~"A terminal with ", {code, [], [~"wscat"]}, ~" or any WebSocket client."
                ]},
                {li, [], [~"A text editor pointed at the mounted game directory."]}
            ]},

            {h2, [], [~"1. Start with a minimal match"]},
            {p, [], [
                ~"Create ",
                {code, [], [~"game/match.lua"]},
                ~" with one tick callback that just stamps a counter into state:"
            ]},
            code(
                ~"lua",
                ~"""
function init(state)
    state.counter = 0
    state.message = "hello"
    return state
end

function tick(state)
    state.counter = state.counter + 1
    return state
end

function get_state(state, player_id)
    return { counter = state.counter, message = state.message }
end
"""
            ),
            {p, [], [
                ~"Restart Asobi (Compose: ",
                {code, [], [~"docker compose restart asobi"]},
                ~"). This is the only restart you need; everything from here on is hot."
            ]},

            {h2, [], [~"2. Connect a client"]},
            {p, [], [~"Open a WebSocket and join a match:"]},
            code(
                ~"bash",
                ~"""
wscat -c ws://localhost:8080/ws

> {"type":"session.connect","payload":{"token":"<token>"}}
> {"type":"matchmaker.add","payload":{"mode":"hello"}}
> # ... matchmaker.matched arrives, then match.state every tick
"""
            ),
            {p, [], [
                ~"You should see ",
                {code, [], [~"match.state"]},
                ~" frames where ",
                {code, [], [~"counter"]},
                ~" climbs each tick and ",
                {code, [], [~"message"]},
                ~" stays at ",
                {code, [], [~"\"hello\""]},
                ~"."
            ]},

            {h2, [], [~"3. Edit the script with the match still running"]},
            {p, [], [
                ~"Without touching the WebSocket, edit ",
                {code, [], [~"game/match.lua"]},
                ~" so ",
                {code, [], [~"tick"]},
                ~" updates the message:"
            ]},
            code(
                ~"lua",
                ~"""
function tick(state)
    state.counter = state.counter + 1
    state.message = "tick " .. tostring(state.counter)
    return state
end
"""
            ),
            {p, [], [
                ~"Save the file. Asobi's loader picks up the change on the next reload poll. Within a second or two your ",
                {code, [], [~"wscat"]},
                ~" stream's ",
                {code, [], [~"message"]},
                ~" field starts rising with the counter \x{2014} no reconnect, no lost players, no lost score."
            ]},

            {h2, [], [~"What just happened"]},
            {p, [], [
                ~"Asobi's Lua loader ",
                {code, [], [~"asobi_lua_loader"]},
                ~" caches each script's bytecode in a per-match Luerl state. When the file mtime advances, the next callback re-compiles into a fresh state, copies the existing ",
                {code, [], [~"state"]},
                ~" table across, and continues. The previous code keeps running for any in-flight callback to avoid mid-tick swaps."
            ]},
            {p, [], [
                ~"This means ",
                {strong, [], [~"data structures must round-trip through the bridge"]},
                ~". Adding a new field to the state map is fine; introducing a Luerl userdata that the new code can't decode is not. Treat hot reload as a code-only path: schema changes still want a deploy."
            ]},

            {h2, [], [~"Caveats"]},
            {ul, [], [
                {li, [], [
                    ~"A syntax error in the new file is rejected; the match keeps running with the old code. The error appears in the structured log with a ",
                    {code, [], [~"reload_failed"]},
                    ~" event."
                ]},
                {li, [], [
                    ~"The compiler error list is truncated to three entries to avoid blowing up the log pipeline if you accidentally save a binary file under the game dir."
                ]},
                {li, [], [
                    ~"Mid-callback rollback after a ",
                    {code, [], [~"game.economy.debit"]},
                    ~" is best-effort \x{2014} see ",
                    {a, [{href, ~"/docs/security/lua-known-limitations"}, az_navigate], [
                        ~"Lua known limitations"
                    ]},
                    ~" for the rationale."
                ]},
                {li, [], [
                    ~"Hot reload picks up changes per-script; a ",
                    {code, [], [~"require"]},
                    ~"'d module that changes is reloaded on next ",
                    {code, [], [~"require"]},
                    ~", not retroactively for existing matches. Force the reload by clearing ",
                    {code, [], [~"_ASOBI_LOADED"]},
                    ~" or restarting the match."
                ]}
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* API reference"]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"Lua callbacks"]},
                    ~" \x{2014} all the entry points you can hot-reload."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/security/lua-sandbox"}, az_navigate], [~"Lua sandbox"]}
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
