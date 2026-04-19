-module(asobi_site_docs_concepts_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-concepts", title => ~"Core concepts — Asobi docs"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Core concepts"
            ]},
            {h1, [], [~"Core concepts"]},
            {p, [{class, ~"docs-lede"}], [
                ~"The primitives Asobi gives you to build multiplayer games. Each concept shows the Lua API side by side with the Erlang equivalent \x{2014} they're the same thing, just different surfaces on the same behaviour."
            ]},

            {h2, [], [~"Games and modes"]},
            {p, [], [
                ~"A ",
                {strong, [], [~"game"]},
                ~" is a container: a name, a set of modules, a database schema. ",
                ~"You register ",
                {strong, [], [~"game modes"]},
                ~" within a game \x{2014} each mode is one module implementing the ",
                {code, [], [~"asobi_match"]},
                ~" behaviour. A single game can have many modes (",
                {code, [], [~"deathmatch"]},
                ~", ",
                {code, [], [~"tutorial"]},
                ~", ",
                {code, [], [~"ranked"]},
                ~")."
            ]},

            {h2, [], [~"Matches"]},
            {p, [], [
                ~"A ",
                {strong, [], [~"match"]},
                ~" is one running session of a mode. 2\x{2013}500 players, bounded lifetime, authoritative state. ",
                ~"Each match is an Erlang process \x{2014} if it crashes, other matches keep running."
            ]},
            {p, [], [
                ~"Each match runs a tick loop (default 10 Hz). Your ",
                {code, [], [~"tick"]},
                ~" callback advances state; ",
                {code, [], [~"handle_input"]},
                ~" processes player actions; ",
                {code, [], [~"get_state"]},
                ~" serialises per-player views. The minimal game is a few dozen lines:"
            ]},
            pair(
                ~"""
function game.tick(state)
    state.elapsed = state.elapsed + 0.1
    if state.elapsed >= 60 then
        state._finished = true
        state._result   = { winner = leader(state) }
    end
    return state
end
""",
                ~"""
tick(#{elapsed := E} = State) when E >= 60 ->
    {finished, #{winner => leader(State)}, State};
tick(#{elapsed := E} = State) ->
    {ok, State#{elapsed := E + 0.1}}.
"""
            ),

            {h2, [], [~"Worlds and zones"]},
            {p, [], [
                ~"For games with shared persistent space \x{2014} MMOs, open-world survival, sandbox \x{2014} use the ",
                {strong, [], [~"world server"]},
                ~". A world is divided into a grid of ",
                {strong, [], [~"zones"]},
                ~"; each zone is its own process managing entities within its region. ",
                ~"Players subscribe to nearby zones (interest management) and only receive updates from those."
            ]},
            {p, [], [
                ~"Zones can be ",
                {strong, [], [~"lazy-loaded"]},
                ~" (spawned on first access, reaped when empty) and paired with terrain chunks served on zone entry. ",
                ~"Benchmarked at 500 real WebSocket players on a 128K\x{00D7}128K tile map at 208MB RAM."
            ]},
            pair(
                ~"""
-- spawn a goblin and find nearby players
local g = game.zone.spawn("goblin_warrior", 100, 200, { hp = 150 })
local nearby = game.spatial.query_radius(g.x, g.y, 50)
""",
                ~"""
%% same, Erlang
{ok, G} = asobi_world_server:spawn_at(World,
    <<"goblin_warrior">>, {100, 200}, #{hp => 150}),
{ok, Nearby} = asobi_zone:query_radius(Zone, {100, 200}, 50).
"""
            ),

            {h2, [], [~"Matchmaking"]},
            {p, [], [
                ~"Players enter a queue with skill/region/mode properties. A pluggable strategy module groups compatible players and spawns a match. ",
                ~"Built-in strategies: ",
                {strong, [], [~"fill"]},
                ~" (first-come-first-matched) and ",
                {strong, [], [~"skill-based"]},
                ~" (MMR-bucketed, widens window over time)."
            ]},
            {p, [], [
                ~"Matchmaking is driven by the client over WebSocket (",
                {code, [], [~"matchmaker.add"]},
                ~" → server replies with ",
                {code, [], [~"matchmaker.matched"]},
                ~"). Server-side, you can also enqueue from Erlang:"
            ]},
            code(
                ~"erlang",
                ~"""
{ok, TicketId} = asobi_matchmaker:add(PlayerId, #{
    mode       => <<"ranked">>,
    properties => #{skill => 1250, region => <<"eu_west">>}
}).
"""
            ),

            {h2, [], [~"Voting"]},
            {p, [], [
                ~"Real-time voting during a match \x{2014} for boon picks, path choices, map votes. Five methods: ",
                ~"plurality, approval, weighted, ranked-choice, and spectator-weighted. ",
                ~"Supports veto tokens, quorum early-resolution, and frustration bonuses for repeatedly losing voters."
            ]},
            {p, [], [
                ~"From Lua, votes are opened by implementing the ",
                {code, [], [~"vote_requested(state)"]},
                ~" callback \x{2014} return a vote config and the match server starts the vote. From Erlang, you can open one directly:"
            ]},
            code(
                ~"erlang",
                ~"""
{ok, _} = asobi_match_server:start_vote(MatchPid, #{
    template  => <<"boon_pick">>,
    method    => plurality,
    options   => [<<"fireball">>, <<"shield">>, <<"speed">>],
    window_ms => 30000
}).
"""
            ),

            {h2, [], [~"Phases, timers, seasons"]},
            {p, [], [
                ~"Phases split a match into stages (lobby, active, results), each with duration and start conditions. ",
                ~"Timers let you schedule one-shot or repeating events. ",
                ~"Seasons wrap longer lifecycles (weekly competitive, monthly events)."
            ]},
            {p, [], [
                {em, [], [
                    ~"Phases fire for Erlang match games and for Lua world games. Lua match games should model phases inside "
                ]},
                {code, [], [~"tick"]},
                {em, [], [~" with an explicit state field."]}
            ]},
            pair(
                ~"""
-- Lua: world mode only
function game.phases(_config)
    return {
        { name = "lobby",   duration = 30000 },
        { name = "active",  duration = 300000 },
        { name = "results", duration = 15000 },
    }
end
""",
                ~"""
phases(_Config) ->
    [
        #{name => <<"lobby">>,   duration => 30000},
        #{name => <<"active">>,  duration => 300000},
        #{name => <<"results">>, duration => 15000}
    ].
"""
            ),

            {h2, [], [~"Chat, presence, DMs"]},
            {p, [], [
                ~"Chat channels (world, zone, DM) are server-side and scoped per match/world. ",
                ~"Presence tracks who's online via ",
                {code, [], [~"pg"]},
                ~" \x{2014} cross-node out of the box in a cluster. ",
                ~"Direct messages have their own lifecycle and persistence."
            ]},
            pair(
                ~"""
game.chat.send("world:main", player_id, "gg")
""",
                ~"""
asobi_chat_channel:send_message(<<"world:main">>, PlayerId, <<"gg">>).
"""
            ),

            {h2, [], [~"Economy and leaderboards"]},
            {p, [], [
                ~"First-class wallet, store listings, IAP, inventory, and transactional ledger. ",
                ~"Leaderboards support multiple scoring modes and time windows. Tournaments tie leaderboards to seasonal resets."
            ]},
            pair(
                ~"""
game.economy.grant(winner_id, "gold", 50, "match_win")
game.leaderboard.submit("arena:weekly", winner_id, kills)
""",
                ~"""
asobi_economy:grant(WinnerId, <<"gold">>, 50, #{reason => <<"match_win">>}),
asobi_leaderboard_server:submit(<<"arena:weekly">>, WinnerId, Kills).
"""
            ),

            {h2, [], [~"Reconnection"]},
            {p, [], [
                ~"When a player disconnects, Asobi enters a ",
                {strong, [], [~"grace period"]},
                ~" configured per game mode. During grace their entity can remain idle, become AI-controlled, or be marked invulnerable. ",
                ~"If they reconnect in time, they resume seamlessly. If they don't, your game module decides (remove, forfeit, AI-takeover)."
            ]},

            {h2, [], [~"Hot reload"]},
            {p, [], [
                ~"Deploy new code and it hot-swaps without disconnecting players. In-flight matches finish on the old code; new matches use the new code. ",
                ~"Works the same way for Lua bundles and Erlang beam files \x{2014} the BEAM's module system handles both."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"Quick start"]},
                    ~" \x{2014} run the engine and ship a first game (Lua or Erlang)."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua API reference"]},
                    ~" \x{2014} the ",
                    {code, [], [~"game.*"]},
                    ~" surface in full."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/erlang/api"}, az_navigate], [~"Erlang API reference"]},
                    ~" \x{2014} behaviours, modules, and specs."
                ]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/concepts", Content).

pair(LuaBody, ErlangBody) ->
    ?html(
        {'div', [{class, ~"docs-lang-pair"}], [
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Lua"]},
                code(~"lua", LuaBody)
            ]},
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Erlang"]},
                code(~"erlang", ErlangBody)
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
