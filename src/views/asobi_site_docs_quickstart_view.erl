-module(asobi_site_docs_quickstart_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-quickstart", title => ~"Quick start — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(_Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
                ~" / Quick start"
            ]},
            {h1, [], [~"Quick start"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Install Asobi, run the engine, deploy a tiny Lua game, and connect a test client. ",
                ~"About 15 minutes."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Prerequisites: "]},
                    ~"Erlang/OTP 28+, rebar3, Docker (for Postgres), and a terminal."
                ]}
            ]},

            {h2, [], [~"1. Run the engine"]},
            {p, [], [
                ~"The fastest way to run Asobi is the pre-built Docker image. It starts a local Postgres and the engine in one command:"
            ]},
            code(
                ~"bash",
                ~"""
docker run -d --name asobi-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 postgres:17

docker run --rm -it --name asobi \
  -p 8080:8080 \
  -e ASOBI_DB_HOST=host.docker.internal \
  -e ERLANG_COOKIE=$(openssl rand -hex 32) \
  ghcr.io/widgrensit/asobi_lua:latest
"""
            ),
            {p, [], [
                ~"You should see the engine come up with a ",
                {code, [], [~"Nova application started"]},
                ~" log line. Port 8080 is the WebSocket endpoint for clients; the HTTP API lives on the same port."
            ]},

            {h2, [], [~"2. Write a Lua game"]},
            {p, [], [
                ~"Asobi games are Lua modules that implement a small set of callbacks. ",
                ~"Create ",
                {code, [], [~"game/hello.lua"]},
                ~":"
            ]},
            code(
                ~"lua",
                ~"""
-- game/hello.lua
local game = {}

function game.init(config)
    return { hits = 0 }
end

function game.join(player_id, state)
    game.send(player_id, { kind = "welcome", msg = "hi " .. player_id })
    return state
end

function game.leave(_player_id, state) return state end

function game.handle_input(_player_id, input, state)
    if input.action == "click" then
        state.hits = state.hits + 1
        game.broadcast("update", { hits = state.hits })
    end
    return state
end

function game.tick(state) return state end
function game.get_state(_player_id, state) return { hits = state.hits } end

return game
"""
            ),
            {p, [], [
                ~"Every public Lua function corresponds to a callback Asobi calls. ",
                ~"The ",
                {code, [], [~"game"]},
                ~" global gives you the runtime API: ",
                {code, [], [~"game.broadcast"]},
                ~", ",
                {code, [], [~"game.send"]},
                ~", and much more \x{2014} see the ",
                {a, [{href, ~"/docs/lua/api"}], [~"Lua API reference"]},
                ~"."
            ]},

            {h2, [], [~"3. Deploy the game"]},
            {p, [], [
                ~"Install the ",
                {code, [], [~"asobi"]},
                ~" CLI and deploy your Lua bundle:"
            ]},
            code(
                ~"bash",
                ~"""
# Install the CLI (one-time)
go install github.com/widgrensit/asobi-cli/cmd/asobi@latest

# Deploy the bundle to the local engine
asobi config set url http://localhost:8080
asobi config set api_key dev
asobi deploy ./game
"""
            ),
            {p, [], [
                ~"The CLI uploads your Lua files; the engine hot-loads them. ",
                ~"No restart, no dropped connections. You'll see ",
                {code, [], [~"\"Deployed 1 script successfully\""]},
                ~" when it's done."
            ]},

            {h2, [], [~"4. Connect from a client"]},
            {p, [], [
                ~"You can use any WebSocket client. Here's a quick test with ",
                {code, [], [~"wscat"]},
                ~":"
            ]},
            code(
                ~"bash",
                ~"""
npm install -g wscat
wscat -c ws://localhost:8080/ws
> {"type":"session.connect","payload":{"token":"dev-token"}}
> {"type":"match.create","payload":{"mode":"hello"}}
> {"type":"match.input","payload":{"action":"click"}}
"""
            ),
            {p, [], [
                ~"You should see the engine respond with match state \x{2014} ",
                {code, [], [~"{\"type\":\"match.state\",\"payload\":{\"hits\":1}}"]},
                ~". Every ",
                {code, [], [~"click"]},
                ~" increments the counter."
            ]},
            {p, [], [
                ~"For a real client, grab one of the SDKs: ",
                {a, [{href, ~"/defold"}], [~"Defold"]},
                ~", ",
                {a, [{href, ~"/unity"}], [~"Unity"]},
                ~", ",
                {a, [{href, ~"/godot"}], [~"Godot"]},
                ~", ",
                {a, [{href, ~"/dart"}], [~"Dart/Flutter"]},
                ~"."
            ]},

            {h2, [], [~"5. Iterate with hot reload"]},
            {p, [], [
                ~"Change ",
                {code, [], [~"game/hello.lua"]},
                ~" (e.g. log the player ID on click) and re-run ",
                {code, [], [~"asobi deploy ./game"]},
                ~". The engine swaps the Lua module atomically \x{2014} any in-flight match finishes with the old code; new matches get the new code. Players stay connected."
            ]},

            {'div', [{class, ~"docs-callout docs-callout-success"}], [
                {p, [], [
                    {strong, [], [~"That's it. "]},
                    ~"You have a live Asobi server running a Lua game with hot-reload deploys."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/tutorials/tic-tac-toe"}], [~"Tic-tac-toe tutorial"]},
                    ~" \x{2014} build a real two-player game from scratch."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/concepts"}], [~"Core concepts"]},
                    ~" \x{2014} matches, worlds, zones, voting, phases."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}], [~"game.* API reference"]},
                    ~" \x{2014} every Lua function Asobi exposes."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/self-host"}], [~"Self-host"]},
                    ~" \x{2014} deploy Asobi to your own infrastructure."
                ]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(~"/docs/quickstart", Content).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
