-module(asobi_site_docs_quickstart_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-quickstart", title => ~"Quick start — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
                ~" / Quick start"
            ]},
            {h1, [], [~"Quick start"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Install Asobi, run the engine, ship a tiny game, and connect a test client. ",
                ~"About 15 minutes. Each step is shown in ",
                {strong, [], [~"both Lua and Erlang"]},
                ~" \x{2014} pick whichever your team writes."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Which should I use? "]},
                    ~"Lua is the fastest path to shipping (hot reload, no rebar3, smaller mental model). ",
                    ~"Erlang gives you full behaviour-level control and better performance on CPU-heavy loops. ",
                    ~"You can mix: a mostly-Lua game can drop into Erlang for one hot module."
                ]}
            ]},
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Prerequisites: "]},
                    ~"Erlang/OTP 28+, rebar3, Docker (for Postgres), and a terminal."
                ]}
            ]},

            {h2, [], [~"1. Run the engine"]},
            {p, [], [
                ~"Start Postgres, then the Asobi engine. Same one-liner regardless of which language you write your game in \x{2014} the engine loads both."
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
                ~"You should see a ",
                {code, [], [~"Nova application started"]},
                ~" log line. Port 8080 is the WebSocket endpoint for clients; the HTTP API lives on the same port."
            ]},

            {h2, [], [~"2. Write the game"]},
            {p, [], [
                ~"We'll build a ",
                {em, [], [~"click counter"]},
                ~": every player who sends a ",
                {code, [], [~"click"]},
                ~" input increments a shared counter, broadcast to everyone."
            ]},

            {h3, [], [~"Option A \x{2014} Lua"]},
            {p, [], [
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

            {h3, [], [~"Option B \x{2014} Erlang"]},
            {p, [], [
                ~"Create ",
                {code, [], [~"src/hello_game.erl"]},
                ~" in a rebar3 project that depends on ",
                {code, [], [~"asobi"]},
                ~":"
            ]},
            code(
                ~"erlang",
                ~"""
-module(hello_game).
-behaviour(asobi_match).

-export([init/1, join/2, leave/2, handle_input/3, tick/1, get_state/2]).

init(_Config) ->
    {ok, #{hits => 0}}.

join(_PlayerId, State) ->
    %% Per-player messages have no Erlang helper; project the welcome
    %% into get_state/2 instead, or use Lua's game.send from a Lua match.
    {ok, State}.

leave(_PlayerId, State) ->
    {ok, State}.

handle_input(_PlayerId, #{action := <<"click">>}, #{hits := H} = State) ->
    NewState = State#{hits := H + 1},
    asobi_match_server:broadcast_event(self(), <<"update">>, #{hits => H + 1}),
    {ok, NewState};
handle_input(_PlayerId, _Input, State) ->
    {ok, State}.

tick(State) -> {ok, State}.

get_state(_PlayerId, #{hits := H}) -> #{hits => H}.
"""
            ),
            {p, [], [
                ~"Both versions implement the same ",
                {code, [], [~"asobi_match"]},
                ~" contract. The Lua runtime translates each callback into the Erlang equivalent at the edge \x{2014} there's no semantic difference."
            ]},

            {h2, [], [~"3. Deploy the game"]},

            {h3, [], [~"Option A \x{2014} Lua"]},
            {p, [], [
                ~"Install the ",
                {code, [], [~"asobi"]},
                ~" CLI once, then push the bundle to the engine:"
            ]},
            code(
                ~"bash",
                ~"""
go install github.com/widgrensit/asobi-cli/cmd/asobi@latest

asobi config set url http://localhost:8080
asobi config set api_key dev
asobi deploy ./game
"""
            ),
            {p, [], [
                ~"The engine hot-loads your Lua. No restart, no dropped connections. You'll see ",
                {code, [], [~"\"Deployed 1 script successfully\""]},
                ~"."
            ]},

            {h3, [], [~"Option B \x{2014} Erlang"]},
            {p, [], [
                ~"Erlang game modules rebuild and hot-load from ",
                {code, [], [~"rebar3 shell"]},
                ~" during development; for releases, rebuild and restart. From your project root:"
            ]},
            code(
                ~"bash",
                ~"""
rebar3 compile
# from a running rebar3 shell: r3:compile() (or l(hello_game) to reload)
"""
            ),
            {p, [], [
                ~"In-flight matches keep running on the old module version; new matches pick up the new one. Same guarantee as the Lua path."
            ]},

            {h2, [], [~"4. Connect a client"]},
            {p, [], [
                ~"Any WebSocket client works. Quick test with ",
                {code, [], [~"wscat"]},
                ~":"
            ]},
            code(
                ~"bash",
                ~"""
npm install -g wscat
wscat -c ws://localhost:8080/ws
> {"type":"session.connect","payload":{"token":"dev-token"}}
> {"type":"matchmaker.add","payload":{"mode":"hello"}}
# server replies with matchmaker.matched { match_id: "<id>" }
> {"type":"match.join","payload":{"match_id":"<id>"}}
> {"type":"match.input","payload":{"action":"click"}}
"""
            ),
            {p, [], [
                ~"You'll see ",
                {code, [], [~"{\"type\":\"match.state\",\"payload\":{\"hits\":1}}"]},
                ~" \x{2014} every click increments the counter."
            ]},
            {p, [], [
                ~"For a real client, use an SDK: ",
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
                ~"Edit the game file, re-deploy, watch changes take effect without disconnecting anyone. ",
                ~"This is the BEAM's killer feature and Asobi's biggest differentiator \x{2014} any non-BEAM backend will drop connections on deploy."
            ]},

            {'div', [{class, ~"docs-callout docs-callout-success"}], [
                {p, [], [
                    {strong, [], [~"That's it. "]},
                    ~"You have a live Asobi server running a bilingual-capable game with hot-reload deploys."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/concepts"}], [~"Core concepts"]},
                    ~" \x{2014} matches, worlds, zones, voting, phases \x{2014} each with Lua + Erlang snippets."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}], [~"Lua API reference"]},
                    ~" \x{2014} every ",
                    {code, [], [~"game.*"]},
                    ~" function."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/erlang/api"}], [~"Erlang API reference"]},
                    ~" \x{2014} the behaviours and modules that power it all."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/self-host"}], [~"Self-host"]},
                    ~" \x{2014} deploy Asobi to your own infrastructure."
                ]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/quickstart", Content).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
