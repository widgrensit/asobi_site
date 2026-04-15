-module(asobi_site_docs_concepts_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-concepts", title => ~"Core concepts — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> term().
render(_Bindings) ->
    Content = ?html({'div', [], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}], [~"Docs"]},
            ~" / Core concepts"
        ]},
        {h1, [], [~"Core concepts"]},
        {p, [{class, ~"docs-lede"}], [
            ~"The primitives Asobi gives you to build multiplayer games."
        ]},

        {h2, [], [~"Games and modes"]},
        {p, [], [
            ~"A ",
            {strong, [], [~"game"]},
            ~" is a container: a name, a set of Lua modules, a database schema. ",
            ~"You register ",
            {strong, [], [~"game modes"]},
            ~" within a game \x{2014} each mode is one Lua module implementing the game behaviour. ",
            ~"A single game can have many modes (",
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
            ~" is one running session of a mode. 2-500 players, bounded lifetime, authoritative state. ",
            ~"Each match is an Erlang process \x{2014} if it crashes, other matches keep running. ",
            ~"Matches are the default primitive for arena-style games: FPS, auto-chess, card games, co-op dungeons."
        ]},
        {p, [], [
            ~"Each match runs a tick loop (default 10 Hz for matches, configurable). Your Lua ",
            {code, [], [~"tick"]},
            ~" callback advances state; ",
            {code, [], [~"handle_input"]},
            ~" processes player actions; ",
            {code, [], [~"get_state"]},
            ~" serialises per-player views."
        ]},

        {h2, [], [~"Worlds and zones"]},
        {p, [], [
            ~"For games with shared persistent space \x{2014} MMOs, open-world survival, sandbox \x{2014} use the ",
            {strong, [], [~"world server"]},
            ~". A world is divided into a grid of ",
            {strong, [], [~"zones"]},
            ~"; each zone is its own Erlang process managing entities within its region. ",
            ~"Players subscribe to nearby zones (interest management) and only receive updates from those."
        ]},
        {p, [], [
            ~"Zones can be ",
            {strong, [], [~"lazy-loaded"]},
            ~" (spawned on first access, reaped when empty) and paired with terrain chunks served on zone entry. ",
            ~"Asobi has been benchmarked at 500 real WebSocket players on a 128K\x{00D7}128K tile map at 208MB RAM."
        ]},

        {h2, [], [~"Matchmaking"]},
        {p, [], [
            ~"Players enter a queue (",
            {code, [], [~"matchmaker.add"]},
            ~") with skill/region/mode properties. A pluggable strategy module groups compatible players and spawns a match for them. ",
            ~"Built-in strategies: ",
            {strong, [], [~"fill"]},
            ~" (first-come-first-matched) and ",
            {strong, [], [~"skill-based"]},
            ~" (MMR-bucketed, widens window over time)."
        ]},

        {h2, [], [~"Voting"]},
        {p, [], [
            ~"Real-time voting during a match \x{2014} for boon picks, path choices, map votes. Five methods: ",
            ~"plurality, approval, weighted, ranked-choice, and spectator-weighted. ",
            ~"Supports veto tokens, quorum early-resolution, and frustration bonuses for repeatedly losing voters."
        ]},

        {h2, [], [~"Phases, timers, seasons"]},
        {p, [], [
            ~"Phases split a match into stages (lobby, active, results), each with duration and start conditions. ",
            ~"Timers let you schedule one-shot or repeating events. ",
            ~"Seasons wrap longer lifecycles (weekly competitive, monthly events)."
        ]},

        {h2, [], [~"Chat, presence, DMs"]},
        {p, [], [
            ~"Chat channels (world, zone, DM) are server-side and scoped per match/world. ",
            ~"Presence tracks who's online via ",
            {code, [], [~"pg"]},
            ~" \x{2014} cross-node out of the box in a cluster. ",
            ~"Direct messages have their own lifecycle and persistence."
        ]},

        {h2, [], [~"Economy and leaderboards"]},
        {p, [], [
            ~"First-class wallet, store listings, IAP, inventory, and transactional ledger. ",
            ~"Leaderboards support multiple scoring modes and time windows. Tournaments tie leaderboards to seasonal resets."
        ]},

        {h2, [], [~"Reconnection"]},
        {p, [], [
            ~"When a player disconnects, Asobi enters a ",
            {strong, [], [~"grace period"]},
            ~" configured per game mode. During grace their entity can remain idle, become AI-controlled, or be marked invulnerable. ",
            ~"If they reconnect in time, they resume seamlessly. If they don't, your game module decides (remove, forfeit, AI-takeover)."
        ]},

        {h2, [], [~"Hot reload"]},
        {p, [], [
            ~"Deploy new Lua code and it hot-swaps without disconnecting players. In-flight matches finish on the old code; new matches use the new code. ",
            ~"This is the BEAM's killer feature and Asobi's biggest differentiator."
        ]},

        {h2, [], [~"Where next?"]},
        {ul, [], [
            {li, [], [{a, [{href, ~"/docs/quickstart"}], [~"Quick start"]}, ~" \x{2014} run the engine and deploy a first game."]},
            {li, [], [{a, [{href, ~"/docs/tutorials/tic-tac-toe"}], [~"Tic-tac-toe tutorial"]}, ~" \x{2014} all of the above, applied."]},
            {li, [], [{a, [{href, ~"/docs/lua/api"}], [~"Lua API reference"]}, ~" \x{2014} what you can call from Lua."]}
        ]}
    ]}),
    asobi_site_docs_shell:render(~"/docs/concepts", Content).
