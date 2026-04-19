-module(asobi_site_docs_world_server_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-world-server", title => ~"World server — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
                ~" / World server"
            ]},
            {h1, [], [~"World server"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Spatial partitioning for large-session multiplayer. 1\x{2013}500+ players in a shared continuous space, split into zone processes for parallel tick simulation and interest-based broadcasting. ",
                ~"Use this over the match server when players move through a shared space (co-op dungeons, open worlds, survival)."
            ]},

            {h2, [], [~"How it works"]},
            {p, [], [
                ~"The world is a grid of ",
                {strong, [], [~"zones"]},
                ~". Each zone is a separate Erlang process owning entities in its region. Players subscribe to nearby zones (interest management) and receive updates only from those. Zones tick in parallel across CPU cores."
            ]},
            code(
                ~"text",
                ~"""
World (2000x2000 units, 10x10 grid)
┌─────┬─────┬─────┬─────┐
│ z0,0│ z1,0│ z2,0│ ... │   P1 subscribes to 9 zones around z1,0
│     │  P1 │     │     │   P2 subscribes to 9 zones around z2,1
├─────┼─────┼─────┼─────┤   Most traffic is independent.
│ z0,1│ z1,1│ z2,1│ ... │
│     │     │ P2  │     │
└─────┴─────┴─────┴─────┘
"""
            ),

            {h2, [], [~"Tick cycle (default 20 Hz)"]},
            {ol, [], [
                {li, [], [
                    ~"Ticker sends ", {code, [], [~"tick(N)"]}, ~" to all zones in parallel."
                ]},
                {li, [], [
                    ~"Each zone: applies queued inputs, runs ",
                    {code, [], [~"zone_tick/2"]},
                    ~", computes deltas, broadcasts to subscribers."
                ]},
                {li, [], [~"Zones ack to the ticker."]},
                {li, [], [
                    ~"When all ack, ticker calls ",
                    {code, [], [~"post_tick/2"]},
                    ~" on the world server for global events (boss phases, vote requests, quest triggers)."
                ]}
            ]},

            {h2, [], [~"Delta compression"]},
            {p, [], [~"Zones broadcast only what changed since the last tick:"]},
            code(
                ~"json",
                ~"""
{"type": "world.tick",
 "payload": {
   "tick": 1042,
   "updates": [
     {"op": "u", "id": "p_abc", "x": 451, "y": 312, "hp": 80},
     {"op": "a", "id": "npc_7", "x": 400, "y": 300, "type": "goblin"},
     {"op": "r", "id": "item_3"}
   ]
 }}
"""
            ),
            {ul, [], [
                {li, [], [{code, [], [~"u"]}, ~" \x{2014} updated (changed fields only)"]},
                {li, [], [{code, [], [~"a"]}, ~" \x{2014} added (full entity state)"]},
                {li, [], [{code, [], [~"r"]}, ~" \x{2014} removed"]}
            ]},

            {h2, [], [~"Implementing the behaviour"]},
            {p, [], [~"Implement ", {code, [], [~"asobi_world"]}, ~" \x{2014} six callbacks."]},
            code(
                ~"erlang",
                ~"""
-module(my_dungeon).
-behaviour(asobi_world).

-export([init/1, join/2, leave/2, spawn_position/2,
         zone_tick/2, handle_input/3, post_tick/2]).

init(_Config) ->
    {ok, #{dungeon_level => 1, boss_hp => 10000}}.

spawn_position(_PlayerId, _State) ->
    {ok, {50.0 + rand:uniform(100), 50.0 + rand:uniform(100)}}.

zone_tick(Entities, ZoneState) ->
    Entities1 = maps:map(fun(_Id, E) ->
        case maps:get(type, E, <<"player">>) of
            <<"goblin">> -> ai_wander(E);
            _ -> E
        end
    end, Entities),
    {Entities1, ZoneState}.

handle_input(PlayerId, #{<<"action">> := <<"move">>, <<"x">> := X, <<"y">> := Y}, Entities) ->
    case Entities of
        #{PlayerId := E} -> {ok, Entities#{PlayerId => E#{x => X, y => Y}}};
        _                -> {error, not_found}
    end.

post_tick(_TickN, #{boss_hp := HP} = State) when HP =< 0 ->
    {vote, #{
        template  => <<"boon_pick">>,
        options   => [#{id => <<"shield">>}, #{id => <<"speed">>}, #{id => <<"damage">>}],
        window_ms => 15000
    }, State#{boss_hp => 10000, dungeon_level => maps:get(dungeon_level, State) + 1}};
post_tick(TickN, State) when TickN >= 36000 ->    %% 30 min @ 20 Hz
    {finished, #{reason => <<"time_up">>}, State};
post_tick(_TickN, State) ->
    {ok, State}.
"""
            ),

            {h2, [], [~"Lua equivalent"]},
            code(
                ~"lua",
                ~"""
local game = {}

function game.init(_cfg)
    return { dungeon_level = 1, boss_hp = 10000 }
end

function game.spawn_position(_player_id, _state)
    return { x = 50 + math.random() * 100, y = 50 + math.random() * 100 }
end

function game.zone_tick(entities, zone_state)
    for id, e in pairs(entities) do
        if e.type == "goblin" then ai_wander(e) end
    end
    return entities, zone_state
end

function game.handle_input(player_id, input, entities)
    if input.action == "move" then
        entities[player_id].x = input.x
        entities[player_id].y = input.y
    end
    return entities
end

function game.post_tick(tick_n, state)
    -- Signal vote/finish by setting reserved keys on state and returning it.
    if state.boss_hp <= 0 then
        state._vote = {
            template  = "boon_pick",
            window_ms = 15000,
            options   = { "shield", "speed", "damage" }
        }
        state.boss_hp       = 10000
        state.dungeon_level = state.dungeon_level + 1
    elseif tick_n >= 36000 then
        state._finished = true
        state._result   = { reason = "time_up" }
    end
    return state
end
"""
            ),

            {h2, [], [~"Large worlds"]},
            {p, [], [
                ~"For 10K+ zones (128K\x{00D7}128K tile maps, persistent planets), zones lazy-spawn on first access and reap when empty. ",
                ~"Terrain chunks are served on zone entry and cached. Benchmarked at 500 real WebSocket players on a 128K\x{00D7}128K tile map at 208MB RAM."
            ]},

            {h3, [], [~"Lazy zones"]},
            {p, [], [
                {code, [], [~"asobi_zone_manager"]},
                ~" keeps an ETS table of active zones. When a player enters an unloaded zone, it spawns one via ",
                {code, [], [~"asobi_zone_sup:start_zone/2"]},
                ~". When the last subscriber leaves, a ",
                {code, [], [~"release_zone/2"]},
                ~" cast triggers reaping after an idle timeout."
            ]},

            {h3, [], [~"Terrain"]},
            {p, [], [
                ~"Terrain chunks are bytes (compressed tile arrays) served via ",
                {code, [], [~"asobi_terrain_store"]},
                ~". Providers load from disk, procedural generation, or a tile DB. Clients receive chunk blobs on zone entry; servers can fetch via ",
                {code, [], [~"asobi_terrain_store:get_chunk/2"]},
                ~" when they need to reason about terrain."
            ]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {world, #{
        zone_size       => 256,      %% units per side
        lazy_zones      => true,
        zone_idle_ms    => 60000,
        terrain_provider => my_terrain_module
    }}
]}
"""
            ),

            {h2, [], [~"Subscriptions"]},
            {p, [], [
                ~"By default a player subscribes to their 3\x{00D7}3 zone neighborhood. When they move, the world recomputes membership, sends enter/leave events to new/old zones, and streams snapshots for newly-visible entities."
            ]},

            {h2, [], [~"Snapshots"]},
            {p, [], [
                {code, [], [~"asobi_zone_snapshotter"]},
                ~" periodically saves the state of each active zone (entities + zone state). On restart, zones restore from snapshot before accepting new subscribers. Tune via ",
                {code, [], [~"snapshot_interval_ms"]},
                ~" in world config."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/erlang/api"}], [
                        ~"Erlang API: asobi_zone, asobi_world_server, asobi_spatial"
                    ]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/performance"}], [~"Performance tuning"]},
                    ~" \x{2014} tick budgets, zone sizing."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/clustering"}], [~"Clustering"]},
                    ~" \x{2014} what's cross-node safe."
                ]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/world-server", Content).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
