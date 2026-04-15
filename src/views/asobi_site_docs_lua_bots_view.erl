-module(asobi_site_docs_lua_bots_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-lua-bots", title => ~"Lua bots — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(_Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
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
                ~"A bot is a Lua file exporting a ",
                {code, [], [~"think"]},
                ~" function. Asobi calls it each bot tick (default 5 Hz)."
            ]},
            code(
                ~"lua",
                ~"""
-- bots/random_player.lua
local bot = {}

function bot.on_join(state, view)
    -- Called once when the bot joins the match.
    return { targeting = nil }
end

function bot.think(state, view)
    -- view is what get_state(bot_id, match_state) returned.
    -- Return an input table to submit, or nil to skip this tick.
    if view.phase ~= "active" then return nil end

    local enemies = enemies_in_sight(view)
    if #enemies == 0 then
        return { action = "move", x = math.random(-5, 5), y = math.random(-5, 5) }
    end

    local target = enemies[1]
    state.targeting = target.id
    return { action = "attack", target = target.id }
end

function bot.on_leave(_state, _view) end

return bot
"""
            ),

            {h2, [], [~"Spawning a bot into a match"]},
            pair(
                ~"""
-- Lua (from your game module)
function game.init(config)
    -- Add 3 bots to fill the arena
    for i = 1, 3 do
        game.bots.add("random_player", {
            display_name = "Bot " .. i,
            skill = 1000,
        })
    end
    return { ... }
end
""",
                ~"""
%% Erlang API
{ok, _BotId} = asobi_bot:add(MatchPid, #{
    script       => <<"random_player">>,
    display_name => <<"Bot Alpha">>,
    skill        => 1000
}).
"""
            ),

            {h2, [], [~"Bot callbacks"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"on_join(state, view)"]},
                    ~" \x{2014} called once; returns the bot's private state."
                ]},
                {li, [], [
                    {code, [], [~"think(state, view)"]},
                    ~" \x{2014} called per bot tick. Return an input table or ",
                    {code, [], [~"nil"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"on_message(state, view, msg)"]},
                    ~" \x{2014} optional; receives messages ",
                    {code, [], [~"game.send"]},
                    ~" would have sent to a human."
                ]},
                {li, [], [{code, [], [~"on_leave(state, view)"]}, ~" \x{2014} optional; cleanup."]}
            ]},

            {h2, [], [~"Configuration"]},
            code(
                ~"erlang",
                ~"""
{asobi_lua, [
    {bot_dir,      <<"./bots">>},
    {bot_tick_ms,  200},                 %% 5 Hz default
    {max_bots_per_match, 8}
]}
"""
            ),

            {h2, [], [~"Difficulty knobs"]},
            {p, [], [
                ~"Common pattern: add a reaction-time delay based on \x{201C}skill\x{201D} metadata."
            ]},
            code(
                ~"lua",
                ~"""
function bot.think(state, view)
    state.reaction_countdown = (state.reaction_countdown or 0) - 1
    if state.reaction_countdown > 0 then return nil end

    -- simulate decision-making delay (higher skill = faster reactions)
    state.reaction_countdown = math.max(1, math.floor(30 / state.skill * 10))

    return pick_action(view)
end
"""
            ),

            {h2, [], [~"Load testing with bots"]},
            {p, [], [
                ~"To pressure-test a match, spawn N bots that do trivial actions and let the tick loop run. Because bots skip the WebSocket, you can saturate CPU with a few lines of config."
            ]},
            code(
                ~"erlang",
                ~"""
[ asobi_bot:add(MatchPid, #{script => <<"noop_bot">>}) || _ <- lists:seq(1, 100) ].
"""
            ),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/docs/lua/api"}], [~"Lua API reference"]}]},
                {li, [], [{a, [{href, ~"/docs/lua/callbacks"}], [~"Game module callbacks"]}]},
                {li, [], [{a, [{href, ~"/docs/performance"}], [~"Performance & benchmarks"]}]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(~"/docs/lua/bots", Content).

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
