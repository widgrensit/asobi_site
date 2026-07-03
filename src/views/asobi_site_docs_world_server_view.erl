-module(asobi_site_docs_world_server_view).
-include("asobi_site_view.hrl").

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

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / World server"
            ]},
            {h1, [], [~"World server"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Spatial partitioning for large-session multiplayer. 1-500+ players in a shared continuous space, split into zone processes for parallel tick simulation and interest-based broadcasting. ",
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
                {li, [], [{code, [], [~"u"]}, ~" - updated (changed fields only)"]},
                {li, [], [{code, [], [~"a"]}, ~" - added (full entity state)"]},
                {li, [], [{code, [], [~"r"]}, ~" - removed"]}
            ]},

            {h2, [], [~"Implementing the behaviour"]},
            {p, [], [~"Implement ", {code, [], [~"asobi_world"]}, ~" - six callbacks."]},
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
function init(_cfg)
    return { dungeon_level = 1, boss_hp = 10000 }
end

function spawn_position(_player_id, _state)
    return { x = 50 + math.random() * 100, y = 50 + math.random() * 100 }
end

function zone_tick(entities, zone_state)
    for id, e in pairs(entities) do
        if e.type == "goblin" then ai_wander(e) end
    end
    return entities, zone_state
end

function handle_input(player_id, input, entities)
    if input.action == "move" then
        entities[player_id].x = input.x
        entities[player_id].y = input.y
    end
    return entities
end

function post_tick(tick_n, state)
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

            {h2, [], [~"Defining spawn templates"]},
            {p, [], [
                ~"A zone spawns entities from named ",
                {strong, [], [~"templates"]},
                ~". Declare them with the optional ",
                {code, [], [~"spawn_templates/1"]},
                ~" callback, which returns a registry keyed by template id. Each template carries a ",
                {code, [], [~"type"]},
                ~", a ",
                {code, [], [~"base_state"]},
                ~" map copied onto every spawned entity, and an optional ",
                {code, [], [~"respawn"]},
                ~" rule."
            ]},
            code(
                ~"erlang",
                ~"""
spawn_templates(_Config) ->
    #{
        <<"goblin">> => #{
            template_id => <<"goblin">>,
            type        => <<"npc">>,
            base_state  => #{health => 100, ai => <<"patrol">>},
            respawn     => #{strategy => timer, delay => 5000, jitter => 1000}
        },
        <<"ore">> => #{
            template_id => <<"ore">>,
            type        => <<"resource">>,
            base_state  => #{quantity => 5},
            respawn     => #{strategy => timer, delay => 3000, max_respawns => 2}
        },
        <<"chest">> => #{
            template_id => <<"chest">>,
            type        => <<"object">>,
            base_state  => #{loot => <<"common">>}
        }
    }.
"""
            ),
            {p, [], [
                ~"In Lua the table key is the template id and ",
                {code, [], [~"strategy"]},
                ~" is always ",
                {code, [], [~"timer"]},
                ~", so you omit both:"
            ]},
            code(
                ~"lua",
                ~"""
function spawn_templates(config)
    return {
        goblin = { type = "npc",      base_state = { health = 100, ai = "patrol" }, respawn = { delay = 5000, jitter = 1000 } },
        ore    = { type = "resource", base_state = { quantity = 5 },                respawn = { delay = 3000, max_respawns = 2 } },
        chest  = { type = "object",   base_state = { loot = "common" } },
    }
end
"""
            ),
            {p, [], [
                ~"Spawn from any zone callback by template id. A fourth argument shallow-merges overrides onto ",
                {code, [], [~"base_state"]},
                ~":"
            ]},
            code(
                ~"lua",
                ~"""
function zone_tick(entities, zone_state)
    if not zone_state.seeded then
        game.zone.spawn("goblin", 500, 500)
        game.zone.spawn("ore", 700, 650)
        game.zone.spawn("chest", 620, 600, { loot = "rare" })
        zone_state.seeded = true
    end
    return entities, zone_state
end
"""
            ),
            {ul, [], [
                {li, [], [
                    {code, [], [~"type"]},
                    ~" - entity category string, echoed in delta ",
                    {code, [], [~"a"]},
                    ~" (added) updates."
                ]},
                {li, [], [
                    {code, [], [~"base_state"]},
                    ~" - fields copied onto each spawned entity."
                ]},
                {li, [], [
                    {code, [], [~"respawn"]},
                    ~" - omit for one-shot. With it, a removed entity respawns after ",
                    {code, [], [~"delay"]},
                    ~" ms (plus up to ",
                    {code, [], [~"jitter"]},
                    ~"), capped by ",
                    {code, [], [~"max_respawns"]},
                    ~" (default unlimited)."
                ]},
                {li, [], [
                    {code, [], [~"persistent"]},
                    ~" - Lua default ",
                    {code, [], [~"true"]},
                    ~"; set ",
                    {code, [], [~"false"]},
                    ~" to keep an entity out of zone snapshots."
                ]}
            ]},
            {p, [], [
                ~"A complete runnable world lives in ",
                {code, [], [~"examples/world-spawns"]},
                ~" in the asobi repo."
            ]},

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
                ~"Asobi does not define what terrain is. You implement a provider that returns the bytes of the chunk at an ",
                {code, [], [~"{X, Y}"]},
                ~" coordinate; ",
                {code, [], [~"asobi_terrain_store"]},
                ~" caches that blob and ships it to clients on zone entry, verbatim. The payload is whatever your provider produces - the data Asobi chunks is the data you hand back, and the client decodes it."
            ]},
            {p, [], [
                ~"A provider implements the ",
                {code, [], [~"asobi_terrain_provider"]},
                ~" behaviour:"
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"init(Args)"]},
                    ~" - once at startup; returns the provider state."
                ]},
                {li, [], [
                    {code, [], [~"load_chunk({X, Y}, State)"]},
                    ~" - a stored chunk, or ",
                    {code, [], [~"{error, not_found}"]},
                    ~" to fall back to generation."
                ]},
                {li, [], [
                    {code, [], [~"generate_chunk({X, Y}, Seed, State)"]},
                    ~" - optional; build the chunk procedurally."
                ]}
            ]},
            code(
                ~"erlang",
                ~"""
-module(my_terrain).
-behaviour(asobi_terrain_provider).
-export([init/1, load_chunk/2, generate_chunk/3]).

init(Config) -> {ok, Config}.

load_chunk(_Coords, _State) ->
    {error, not_found}.

generate_chunk({CX, CY}, Seed, State) ->
    Tiles = #{{0, 0} => {tile_id(CX, CY, Seed), 0, 0}},
    Bin = asobi_terrain:compress_chunk(asobi_terrain:encode_chunk(Tiles)),
    {ok, Bin, State}.
"""
            ),
            {p, [], [
                ~"The ",
                {code, [], [~"asobi_terrain"]},
                ~" helpers give you a compact tile format (each tile ",
                {code, [], [~"{TileId, Flags, Elevation}"]},
                ~", 4 bytes, zlib-compressed), but any binary your client can decode works. Wire the provider to a world by returning it from ",
                {code, [], [~"terrain_provider/1"]},
                ~":"
            ]},
            code(
                ~"erlang",
                ~"""
terrain_provider(_Config) ->
    {my_terrain, #{seed => 42}}.
"""
            ),
            {p, [], [
                ~"From Lua you can only name an ",
                {strong, [], [~"allowlisted"]},
                ~" Erlang provider module (terrain logic cannot be written in Lua):"
            ]},
            code(
                ~"lua",
                ~"""
function terrain_provider(config)
    return { module = "my_terrain", args = {} }
end
"""
            ),
            {p, [], [
                ~"A complete runnable provider lives in ",
                {a,
                    [
                        {href,
                            ~"https://github.com/widgrensit/asobi/tree/main/examples/world-terrain"}
                    ],
                    [
                        ~"examples/world-terrain"
                    ]},
                ~". Servers that need to reason about terrain can read it back via ",
                {code, [], [~"asobi_terrain_store:get_chunk/2"]},
                ~"."
            ]},
            {h2, [], [~"World config"]},
            {p, [], [
                ~"World options are not application env. In Lua they are top-level globals in your world script; in Erlang the same keys go in the ",
                {code, [], [~"Config"]},
                ~" map passed to ",
                {code, [], [~"asobi_world_lobby:create_world/1"]},
                ~". Terrain is wired through the ",
                {code, [], [~"terrain_provider/1"]},
                ~" game-module callback, not a static key."
            ]},
            code(
                ~"lua",
                ~"""
game_type         = "world"
zone_size         = 256      -- world units per zone (default 200)
grid_size         = 10       -- zones per dimension (default 10)
view_radius       = 1        -- zone radius a player subscribes to (default 1)
tick_rate         = 50       -- ms per tick (default 50 = 20 Hz)
zone_idle_timeout = 60000    -- ms before an idle zone is reaped (default 30000)
empty_grace_ms    = 60000    -- ms to keep an empty world alive (default 60000)
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
                    {a, [{href, ~"/docs/erlang/api"}, az_navigate], [
                        ~"Erlang API: asobi_zone, asobi_world_server, asobi_spatial"
                    ]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/performance"}, az_navigate], [~"Performance tuning"]},
                    ~" - tick budgets, zone sizing."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/clustering"}, az_navigate], [~"Clustering"]},
                    ~" - what's cross-node safe."
                ]}
            ]}
        ]}
    ).
code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
