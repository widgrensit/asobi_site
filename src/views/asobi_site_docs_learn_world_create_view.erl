-module(asobi_site_docs_learn_world_create_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-world-create", title => ~"Create a world - Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Learn / Create a world"
            ]},
            {h1, [], [~"Create a world (and when to pick one)"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Register a persistent arena, understand when a world beats a match, and prove one comes into being."
            ]},

            {p, [], [
                ~"So far the arena has lived inside a ",
                {strong, [], [~"match"]},
                ~". A match is an arena round: a bounded, ephemeral fight. A fixed roster joins, your fighter moves, the round finishes, and the state is gone. That is the right shape for a round of play with a clear start and end."
            ]},
            {p, [], [
                ~"A ",
                {strong, [], [~"world"]},
                ~" is the other shape: a persistent arena. It is an always-on, zoned, shared space that never ends. It exists independently of any one player. People wander in and out; the arena stays. Under the hood the world is split into zone processes so it can carry many more players than a match, each player only receiving updates from the zones they can see."
            ]},

            {h2, [], [~"Match or world?"]},
            {p, [], [~"Pick a ", {strong, [], [~"match"]}, ~" when:"]},
            {ul, [], [
                {li, [], [~"Play happens in bounded rounds with a start and a finish."]},
                {li, [], [~"The roster is small and fixed for the round."]},
                {li, [], [~"Nothing needs to survive after the last player leaves."]}
            ]},
            {p, [], [~"Pick a ", {strong, [], [~"world"]}, ~" when:"]},
            {ul, [], [
                {li, [], [~"The space is a shared room that outlives any single session."]},
                {li, [], [~"Players join and leave continuously rather than as one cohort."]},
                {li, [], [
                    ~"You expect more players than a single tick loop should simulate (a world fans out across zones; a match does not)."
                ]}
            ]},
            {p, [], [
                ~"For the arena: a match is fine for a two-player round. Reach for a world when the arena becomes a persistent space players drift through and it should still be there when they come back. Matches are bounded rounds; a world is a persistent arena. The rest of this part builds the persistent-arena version."
            ]},
            {p, [], [
                ~"See ",
                {a, [{href, ~"/docs/world-server"}, az_navigate], [~"World server"]},
                ~" for the zone model and supervision tree, and ",
                {a, [{href, ~"/docs/large-worlds"}, az_navigate], [~"Large worlds"]},
                ~" for tile-based worlds with lazy zone loading."
            ]},

            {h2, [], [~"Write ", {code, [], [~"world.lua"]}]},
            {p, [], [
                ~"A world script is a match script with world callbacks. The whole file is game logic, so it is ",
                {strong, [], [~"identical on Cloud and self-hosted"]},
                ~" - you write it once."
            ]},
            code(
                ~"lua",
                ~"""
                -- lua/world.lua
                game_type   = "world"
                match_size  = 1
                max_players = 500
                grid_size   = 5
                zone_size   = 400
                tick_rate   = 50
                view_radius = 1

                function init(config)
                    return { spawned = 0 }
                end

                function join(player_id, state)
                    state.spawned = state.spawned + 1
                    return state
                end

                function leave(player_id, state)
                    return state
                end

                function spawn_position(player_id, state)
                    return { x = 100 + math.random(200), y = 100 + math.random(200) }
                end

                function post_tick(tick, state)
                    return state
                end
                """
            ),
            {p, [], [
                ~"That is the minimum a world needs: ",
                {code, [], [~"init"]},
                ~", ",
                {code, [], [~"join"]},
                ~", ",
                {code, [], [~"leave"]},
                ~", ",
                {code, [], [~"spawn_position"]},
                ~", and ",
                {code, [], [~"post_tick"]},
                ~" are all required. ",
                {code, [], [~"spawn_position"]},
                ~" returns the ",
                {code, [], [~"{x, y}"]},
                ~" where a joining player's fighter appears. Moving your fighter and broadcasting deltas comes in the next two steps; here the world just has to exist and accept a spawn."
            ]},

            {'div', [{class, ~"docs-callout docs-callout-warning"}], [
                {p, [{class, ~"docs-callout-title"}], [~"Gotcha"]},
                {p, [], [
                    ~"the Lua global is ",
                    {code, [], [~"game_type"]},
                    ~", not ",
                    {code, [], [~"type"]},
                    ~". A script that sets ",
                    {code, [], [~"type = \"world\""]},
                    ~" is silently registered as a ",
                    {em, [], [~"match"]},
                    ~" mode, and ",
                    {code, [], [~"world.find_or_create"]},
                    ~" then answers ",
                    {code, [], [~"mode_not_found"]},
                    ~". (The Erlang ",
                    {code, [], [~"sys.config"]},
                    ~" key ",
                    {em, [], [~"is"]},
                    ~" ",
                    {code, [], [~"type"]},
                    ~"; only the Lua loader reads ",
                    {code, [], [~"game_type"]},
                    ~".)"
                ]}
            ]},

            {p, [], [
                {code, [], [~"match_size"]},
                ~" is required by the loader for every mode, worlds included. Use ",
                {code, [], [~"1"]},
                ~" for a world that should not gate on a minimum player count."
            ]},

            {h2, [], [~"Register the mode"]},
            {p, [], [
                ~"Map a mode name to the script in ",
                {code, [], [~"config.lua"]},
                ~". This manifest is game logic too, so it is ",
                {strong, [], [~"the same on Cloud and self-hosted"]},
                ~"."
            ]},
            code(
                ~"lua",
                ~"""
                -- lua/config.lua
                return {
                    hub = "world.lua"
                }
                """
            ),
            {p, [], [
                ~"When ",
                {code, [], [~"config.lua"]},
                ~" is present, Asobi reads it instead of looking for a top-level ",
                {code, [], [~"match.lua"]},
                ~". The mode is now named ",
                {code, [], [~"hub"]},
                ~", and clients create worlds of it by that name."
            ]},
            {p, [], [
                ~"Worlds are ",
                {code, [], [~"listed = true"]},
                ~" by default, so instances show up in ",
                {code, [], [~"world.list"]},
                ~"; ",
                {code, [], [~"quick_play"]},
                ~" defaults to ",
                {code, [], [~"true"]},
                ~", so ",
                {code, [], [~"world.find_or_create"]},
                ~" may place a caller into an existing ",
                {code, [], [~"hub"]},
                ~" world. Both are covered in ",
                {a, [{href, ~"/docs/world-server"}, az_navigate], [~"World server"]},
                ~" if you need to change them."
            ]},

            {h2, [], [~"How a world is created"]},
            {p, [], [
                ~"A world is not created at boot. It is created on demand by a client frame over the WebSocket, and the caller is auto-joined:"
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"world.create {mode}"]},
                    ~" - always make a new world."
                ]},
                {li, [], [
                    {code, [], [~"world.find_or_create {mode}"]},
                    ~" - return the first non-full world of that mode, or make one if none exists. This is the \"drop me into a shared arena\" call, and what you almost always want for the arena."
                ]}
            ]},
            {p, [], [
                ~"Both refuse with ",
                {code, [], [~"world_capacity_reached"]},
                ~" (global cap) or ",
                {code, [], [~"player_world_limit_reached"]},
                ~" (per-player cap). Those caps are the only Cloud/self-hosted difference in this step:"
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Cloud:"]},
                    ~" the platform supplies defaults; you tune nothing to get started."
                ]},
                {li, [], [
                    {strong, [], [~"Self-hosted:"]},
                    ~" set them in ",
                    {code, [], [~"sys.config"]},
                    ~" - ",
                    {code, [], [~"{world_max, 1000}"]},
                    ~" and ",
                    {code, [], [~"{world_max_per_player, 5}"]},
                    ~". See ",
                    {a, [{href, ~"/docs/configuration"}, az_navigate], [
                        ~"World capacity in Configuration"
                    ]},
                    ~"."
                ]}
            ]},
            {p, [], [
                ~"Everything else about creating a world - the frame you send and the ",
                {code, [], [~"world.joined"]},
                ~" reply you get back - is identical on both, and identical across every client SDK apart from the base server URL. The full SDK-by-SDK join flow is ",
                {a, [{href, ~"/docs/learn/world-join"}, az_navigate], [~"step 11"]},
                ~"; here we only need to see a world exist."
            ]},

            checkpoint([
                {p, [], [
                    ~"A world exists once a client creates one. Deploy the bundle, then, reusing the authenticated WebSocket you connected in ",
                    {a, [{href, ~"/docs/learn/connect"}, az_navigate], [~"step 3"]},
                    ~" and the guest identity from ",
                    {a, [{href, ~"/docs/learn/identity"}, az_navigate], [~"step 4"]},
                    ~", send one frame:"
                ]},
                code(
                    ~"json",
                    ~"""
                    {"type": "world.find_or_create", "payload": {"mode": "hub"}}
                    """
                ),
                {p, [], [
                    ~"You should receive a ",
                    {code, [], [~"world.joined"]},
                    ~" push carrying the new world's id:"
                ]},
                code(
                    ~"json",
                    ~"""
                    {"type": "world.joined", "payload": {"world_id": "...", "mode": "hub", "grid_size": 5, "max_players": 500, "player_count": 1, "status": "running"}}
                    """
                ),
                {p, [], [~"Confirm it independently by listing worlds of the mode:"]},
                code(
                    ~"json",
                    ~"""
                    {"type": "world.list", "payload": {"mode": "hub"}}
                    """
                ),
                code(
                    ~"json",
                    ~"""
                    {"type": "world.list", "payload": {"worlds": [{"world_id": "...", "mode": "hub", "player_count": 1, "max_players": 500}]}}
                    """
                ),
                {p, [], [
                    ~"One ",
                    {code, [], [~"hub"]},
                    ~" world in the list means the mode loaded correctly and a live world exists. If you instead get ",
                    {code, [], [~"mode_not_found"]},
                    ~", re-check ",
                    {code, [], [~"game_type = \"world\""]},
                    ~" in ",
                    {code, [], [~"world.lua"]},
                    ~"."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/world-join",
                ~"Step 11: Connect to a world",
                ~"Join across every client SDK and receive the initial snapshot."
            )
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).

checkpoint(Children) ->
    ?html(
        {'div', [{class, ~"docs-callout docs-callout-success"}], [
            {p, [], [{strong, [], [~"Checkpoint"]}]} | Children
        ]}
    ).

nextstep(Href, Label, Blurb) ->
    ?html(
        {'div', [{class, ~"docs-next"}], [
            {p, [], [
                {strong, [], [~"Next: "]},
                {a, [{href, Href}, az_navigate], [Label]}
            ]},
            {p, [], [Blurb]}
        ]}
    ).
