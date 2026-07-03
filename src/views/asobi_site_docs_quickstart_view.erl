-module(asobi_site_docs_quickstart_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-quickstart", title => ~"Quick start - Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Quick start"
            ]},
            {h1, [], [~"Quick start"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Write a tiny game in Lua, run the Asobi server, and connect a client. ",
                ~"About 10 minutes. You host the server yourself, or run it on managed Asobi ",
                ~"(cloud) - the game and the client code are identical either way."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Asobi games are written in Lua. "]},
                    ~"The engine is an Erlang/OTP application underneath. If you would rather ",
                    ~"embed it directly in your own OTP app instead of writing Lua, see the ",
                    {a, [{href, ~"/docs/erlang/api"}, az_navigate], [~"Erlang API reference"]},
                    ~" - the rest of this page is the Lua path."
                ]}
            ]},
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Prerequisites: "]},
                    ~"Docker and a terminal. Nothing else - you do not need Erlang or rebar3 to write and run a Lua game."
                ]}
            ]},

            {h2, [], [~"1. Write the game"]},
            {p, [], [
                ~"Your game is Lua that the server loads from a directory. Create ",
                {code, [], [~"game/match.lua"]},
                ~". We will build a ",
                {em, [], [~"click counter"]},
                ~": every player who sends a ",
                {code, [], [~"click"]},
                ~" input increments a shared counter, broadcast to everyone."
            ]},
            code(
                ~"lua",
                ~"""
-- game/match.lua
match_size = 1
max_players = 1
strategy = "fill"

function init(config)
    return { hits = 0 }
end

function join(player_id, state)
    game.send(player_id, { kind = "welcome", msg = "hi " .. player_id })
    return state
end

function leave(_player_id, state) return state end

function handle_input(_player_id, input, state)
    if input.action == "click" then
        state.hits = state.hits + 1
        game.broadcast("update", { hits = state.hits })
    end
    return state
end

function tick(state) return state end
function get_state(_player_id, state) return { hits = state.hits } end
"""
            ),
            {p, [], [
                ~"The ",
                {code, [], [~"match_size"]},
                ~" / ",
                {code, [], [~"max_players"]},
                ~" / ",
                {code, [], [~"strategy"]},
                ~" globals configure matchmaking; the functions are the match lifecycle. Every ",
                {code, [], [~"game.*"]},
                ~" call is documented in the ",
                {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua API reference"]},
                ~"."
            ]},

            {h2, [], [~"2. Run the server"]},
            {p, [], [
                ~"The server is the ",
                {code, [], [~"asobi_lua"]},
                ~" runtime image plus Postgres. It loads your Lua from ",
                {code, [], [~"/app/game"]},
                ~", so mount the ",
                {code, [], [~"game/"]},
                ~" directory you just created there. Save this as ",
                {code, [], [~"docker-compose.yml"]},
                ~" next to ",
                {code, [], [~"game/"]},
                ~":"
            ]},
            code(
                ~"yaml",
                ~"""
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: asobi
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5

  asobi:
    image: ghcr.io/widgrensit/asobi_lua:latest
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "8084:8084"
    volumes:
      - ./game:/app/game:ro
    environment:
      ASOBI_PORT: "8084"
      ASOBI_NODE_HOST: "127.0.0.1"
      ERLANG_COOKIE: dev_cookie
      ASOBI_DB_HOST: postgres
      ASOBI_DB_NAME: asobi
      ASOBI_DB_USER: postgres
      ASOBI_DB_PASSWORD: postgres
"""
            ),
            code(
                ~"bash",
                ~"""
docker compose up -d
"""
            ),
            {p, [], [
                ~"The server is now on ",
                {code, [], [~"http://localhost:8084"]},
                ~" - the HTTP API and the WebSocket endpoint (",
                {code, [], [~"/ws"]},
                ~") share the port. Prefer a ready-made server to copy from? The ",
                {a, [{href, ~"https://github.com/widgrensit/sdk_demo_backend"}], [
                    ~"sdk_demo_backend"
                ]},
                ~" repo is exactly this compose with a sample game already in ",
                {code, [], [~"./lua"]},
                ~"."
            ]},

            {h2, [], [~"3. Connect a client"]},
            {p, [], [
                ~"Players authenticate with a username and password; the server returns an ",
                {code, [], [~"access"]},
                ~" / ",
                {code, [], [~"refresh"]},
                ~" token pair. There is no API key on the client. Register one over REST:"
            ]},
            code(
                ~"bash",
                ~"""
curl -sX POST http://localhost:8084/api/v1/auth/register \
  -H 'content-type: application/json' \
  -d '{"username":"player1","password":"secret123"}'
# => {"player_id":"...","access_token":"...","refresh_token":"..."}
"""
            ),
            {p, [], [
                ~"An SDK does this for you and attaches the token to every REST and WebSocket call, refreshing it automatically. For a raw test, connect with the ",
                {code, [], [~"access_token"]},
                ~" using ",
                {code, [], [~"wscat"]},
                ~":"
            ]},
            code(
                ~"bash",
                ~"""
npm install -g wscat
wscat -c ws://localhost:8084/ws
> {"type":"session.connect","payload":{"token":"<access_token>"}}
> {"type":"matchmaker.add","payload":{"mode":"default"}}
# server replies with match.matched { match_id: "<id>" }
> {"type":"match.join","payload":{"match_id":"<id>"}}
> {"type":"match.input","payload":{"action":"click"}}
"""
            ),
            {p, [], [
                ~"You will see ",
                {code, [], [~"{\"type\":\"match.state\",\"payload\":{\"hits\":1}}"]},
                ~" - every click increments the counter. For a real client, use an SDK: ",
                {a, [{href, ~"/defold"}, az_navigate], [~"Defold"]},
                ~", ",
                {a, [{href, ~"/unity"}, az_navigate], [~"Unity"]},
                ~", ",
                {a, [{href, ~"/godot"}, az_navigate], [~"Godot"]},
                ~", ",
                {a, [{href, ~"/dart"}, az_navigate], [~"Dart/Flutter"]},
                ~"."
            ]},

            {h2, [], [~"4. Deploy changes"]},
            {p, [], [
                ~"Deploying is shipping new Lua to the server. How you do it is the one thing that differs between hosting your own server and running on managed Asobi."
            ]},

            {h3, [], [~"Self-hosted"]},
            {p, [], [
                ~"Your game is the Lua in ",
                {code, [], [~"./game"]},
                ~", mounted at ",
                {code, [], [~"/app/game"]},
                ~". Edit a file and restart the container to load it:"
            ]},
            code(
                ~"bash",
                ~"""
docker compose restart asobi
"""
            ),
            {p, [], [
                ~"For production, bake the game into your own image instead of mounting it, and run that:"
            ]},
            code(
                ~"docker",
                ~"""
FROM ghcr.io/widgrensit/asobi_lua:latest
COPY game/ /app/game
"""
            ),
            {p, [], [
                ~"No API key is involved anywhere: a self-hosted server authenticates players directly (step 3), and there is nothing to register with. You own the database, the TLS, and the restart."
            ]},

            {h3, [], [~"Cloud (managed Asobi)"]},
            {p, [], [
                ~"On ",
                {a, [{href, ~"https://console.asobi.dev"}], [~"console.asobi.dev"]},
                ~" you get a hosted environment with an endpoint URL and hot-reload deploys through the CLI - new Lua loads with no dropped connections."
            ]},
            code(
                ~"bash",
                ~"""
curl -fsSL https://raw.githubusercontent.com/widgrensit/asobi-cli/main/install.sh | sh
asobi login
asobi use <your-game>
asobi deploy prod lua
"""
            ),
            {p, [], [
                {code, [], [~"asobi login"]},
                ~" approves the CLI over a browser device-code flow; ",
                {code, [], [~"asobi use"]},
                ~" selects your game; ",
                {code, [], [~"asobi deploy"]},
                ~" ships and hot-loads your Lua. The CLI signs in for you - you never handle a key. Point your client SDK at the environment's endpoint URL instead of ",
                {code, [], [~"localhost:8084"]},
                ~"."
            ]},

            {'div', [{class, ~"docs-callout docs-callout-success"}], [
                {p, [], [
                    {strong, [], [~"That's it. "]},
                    ~"You have a live Asobi server running a Lua game, with a client talking to it."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/concepts"}, az_navigate], [~"Core concepts"]},
                    ~" - matches, worlds, zones, voting, phases."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua API reference"]},
                    ~" - every ",
                    {code, [], [~"game.*"]},
                    ~" function."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-host"]},
                    ~" - run Asobi on your own infrastructure for real."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/cloud"}, az_navigate], [~"Cloud"]},
                    ~" - environments, deploys, and billing on managed Asobi."
                ]}
            ]}
        ]}
    ).
code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
