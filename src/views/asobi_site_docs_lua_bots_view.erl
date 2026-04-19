-module(asobi_site_docs_lua_bots_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-lua-bots", title => ~"Lua bots — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Lua / Bots"
            ]},
            {h1, [], [~"Lua bots"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Server-side AI players that fill empty slots, drive tutorials, or load-test your game. ",
                ~"Bots run inside the match alongside humans \x{2014} no network, no WebSocket \x{2014} and share the same ",
                {code, [], [~"game.*"]},
                ~" surface as your game logic."
            ]},

            {h2, [], [~"When to use bots"]},
            {ul, [], [
                {li, [], [~"Fill empty slots so matches start immediately."]},
                {li, [], [~"Tutorial / single-player sandbox with scripted opponents."]},
                {li, [], [~"Load test your tick loop without spawning real WebSocket sessions."]},
                {li, [], [~"Replay / record-and-replay testing."]}
            ]},

            {h2, [], [~"Writing a bot"]},
            {p, [], [
                ~"A bot script exports a top-level ",
                {code, [], [~"think(bot_id, state)"]},
                ~" function. Asobi calls it each bot tick (100ms) with the latest match state for that bot."
            ]},
            code(
                ~"lua",
                ~"""
-- bots/random_player.lua
-- Optional: advertise display names the platform reads back
names = {"Spark", "Blitz", "Volt", "Neon", "Pulse"}

function think(bot_id, state)
    -- state is the full match state as of the latest match.state broadcast.
    -- Return an input table to submit, or nil/{} to skip this tick.
    local players = state.players or {}
    local me = players[bot_id]
    if not me then return {} end

    -- wander randomly; real bots would pick targets, cast abilities, etc.
    return {
        right = math.random() < 0.5,
        left  = math.random() < 0.5,
        up    = math.random() < 0.5,
        down  = math.random() < 0.5,
    }
end
"""
            ),

            {h2, [], [~"Wiring bots into a mode"]},
            {p, [], [
                ~"Bots are configured per mode. In a Lua game, set ",
                {code, [], [~"bots"]},
                ~" as a top-level global in ",
                {code, [], [~"match.lua"]},
                ~". In ",
                {code, [], [~"sys.config"]},
                ~", use the ",
                {code, [], [~"bots"]},
                ~" key inside the mode:"
            ]},
            pair(
                ~"""
-- match.lua
match_size  = 4
max_players = 4
bots = {
    script = "bots/random_player.lua"
}
""",
                ~"""
{asobi, [
    {game_modes, #{
        ~"arena" => #{
            module     => my_arena,
            match_size => 4,
            bots       => #{
                enabled     => true,
                min_players => 4,
                script      => ~"bots/random_player.lua"
            }
        }
    }}
]}
"""
            ),
            {p, [], [
                ~"When ",
                {code, [], [~"enabled = true"]},
                ~" and the queue for that mode is under ",
                {code, [], [~"min_players"]},
                ~", ",
                {code, [], [~"asobi_bot_spawner"]},
                ~" fills the shortfall with bots that are added to the matchmaker like regular players."
            ]},

            {h2, [], [~"Bot callbacks"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"think(bot_id, state)"]},
                    ~" \x{2014} required. Called each bot tick. Return an input map or ",
                    {code, [], [~"{}"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"names"]},
                    ~" \x{2014} optional top-level table of display-name strings the spawner picks from."
                ]}
            ]},
            {p, [], [
                ~"There is no ",
                {code, [], [~"on_join"]},
                ~"/",
                {code, [], [~"on_leave"]},
                ~"/",
                {code, [], [~"on_message"]},
                ~" surface: a bot is a plain input source, nothing more. Keep per-bot state by keying off ",
                {code, [], [~"bot_id"]},
                ~"."
            ]},

            {h2, [], [~"Difficulty knobs"]},
            {p, [], [
                ~"Common pattern: key private state off ",
                {code, [], [~"bot_id"]},
                ~" in a module-level table and add a reaction-time delay."
            ]},
            code(
                ~"lua",
                ~"""
local mem = {}

function think(bot_id, state)
    local m = mem[bot_id] or { reaction = 0, skill = 1000 }
    m.reaction = m.reaction - 1
    if m.reaction > 0 then mem[bot_id] = m; return {} end

    m.reaction = math.max(1, math.floor(3000 / m.skill))
    mem[bot_id] = m
    return pick_action(bot_id, state)
end
"""
            ),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua API reference"]}]},
                {li, [], [{a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"Game module callbacks"]}]},
                {li, [], [{a, [{href, ~"/docs/performance"}, az_navigate], [~"Performance & benchmarks"]}]}
            ]}
        ]}
    ).
pair(LuaBody, ErlBody) ->
    ?html(
        {'div', [{class, ~"docs-lang-pair"}], [
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Lua"]},
                code(~"lua", LuaBody)
            ]},
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Erlang"]},
                code(~"erlang", ErlBody)
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
