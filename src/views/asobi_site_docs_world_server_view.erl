%% GENERATED from asobi guides/world-server.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_world_server_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-world-server", title => ~"World server — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / World server"
        ]},
        {h1, [], [~"World Server"]},
        {raw,
            ~"""
<p>Build large-session multiplayer games with spatial partitioning. The world
server handles 1--500+ players in a shared continuous space, automatically
splitting the world into zone processes for parallelized tick simulation
and interest-based state broadcasting.</p>
<p>Use the world server when your game has players moving through a shared
space (co-op dungeons, open worlds, large-scale survival). For arena-style
games with smaller player counts, use the standard <a href="/docs/matchmaking">match server</a>.</p>
<p>For massive tile-based worlds (10K+ zones), see <a href="https://hexdocs.pm/asobi/large-worlds.html">Large Worlds</a>
for lazy zone loading, terrain data, and scaling configuration.</p>
<h2 id="how-it-works" tabindex="-1">How It Works</h2>
<p>A world is divided into a grid of <strong>zones</strong> -- each zone is a separate
Erlang process that owns the entities in its region. Players only receive
updates from zones they can see (interest management), and each zone runs
its tick in parallel across CPU cores.</p>
<pre><code>World (2000x2000 units, 10x10 grid)
┌─────┬─────┬─────┬─────┬ ...
│ z0,0│ z1,0│ z2,0│ z3,0│
│     │  P1 │     │     │
├─────┼─────┼─────┼─────┼ ...
│ z0,1│ z1,1│ z2,1│ z3,1│
│     │     │ P2  │     │
├─────┼─────┼─────┼─────┼ ...
│ z0,2│ z1,2│ z2,2│ z3,2│
│     │     │     │     │
</code></pre>
<p>P1 subscribes to the 9 zones around z1,0. P2 subscribes to the 9 zones
around z2,1. They only overlap on 2 zones, so most of their traffic is
independent.</p>
<h3 id="supervision-tree" tabindex="-1">Supervision Tree</h3>
<p>Each world instance is its own supervisor:</p>
<pre><code>asobi_world_sup (one_for_one)
├── asobi_world_registry         — tracks active worlds
└── asobi_world_instance_sup     — dynamic, one per world
    └── asobi_world_instance     — one_for_all per world
        ├── asobi_zone_sup       — dynamic, one per zone cell
        │   └── asobi_zone       — gen_server per grid cell
        ├── asobi_world_ticker   — coordinates ticks across zones
        └── asobi_world_server   — gen_statem: world lifecycle
</code></pre>
<h3 id="tick-cycle" tabindex="-1">Tick Cycle</h3>
<p>Every tick (default 20 Hz / 50ms):</p>
<ol>
<li>Ticker sends <code>tick(N)</code> to all zones in parallel</li>
<li>Each zone: applies queued player inputs, runs <code>zone_tick/2</code>, computes
deltas from previous state, broadcasts deltas to subscribers</li>
<li>Each zone acks back to the ticker</li>
<li>When all zones ack, ticker calls <code>post_tick/2</code> on the world server
for global game events (boss phases, quest triggers, vote requests)</li>
</ol>
<h3 id="delta-compression" tabindex="-1">Delta Compression</h3>
<p>Zones only send what changed since the last tick:</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;world.tick&quot;,
  &quot;payload&quot;: {
    &quot;tick&quot;: 1042,
    &quot;updates&quot;: [
      {&quot;op&quot;: &quot;u&quot;, &quot;id&quot;: &quot;p_abc&quot;, &quot;x&quot;: 451, &quot;y&quot;: 312, &quot;hp&quot;: 80},
      {&quot;op&quot;: &quot;a&quot;, &quot;id&quot;: &quot;npc_7&quot;, &quot;x&quot;: 400, &quot;y&quot;: 300, &quot;type&quot;: &quot;goblin&quot;},
      {&quot;op&quot;: &quot;r&quot;, &quot;id&quot;: &quot;item_3&quot;}
    ]
  }
}
</code></pre>
<ul>
<li><code>u</code> -- updated (only changed fields)</li>
<li><code>a</code> -- added (full entity state)</li>
<li><code>r</code> -- removed</li>
</ul>
<h2 id="lua-implementation" tabindex="-1">Lua Implementation</h2>
<p>Most games write world logic in Lua and run the asobi_lua Docker image - no
Erlang needed. The <a href="#erlang-implementation">Erlang behaviour</a> below is the same
model for teams embedding asobi as a library.</p>
<p>World scripts follow the same pattern as match scripts but with
zone-specific callbacks. Set <code>game_type = &quot;world&quot;</code> in your mode globals.</p>
<blockquote>
<p><strong>Gotcha</strong>: the global is <strong><code>game_type</code></strong>, not <code>type</code>. The Erlang
<code>sys.config</code> form uses the key <code>type</code>, but the Lua loader
reads <code>game_type</code>. A Lua script that sets <code>type = &quot;world&quot;</code> is
silently ignored — the script registers as a <em>match</em> mode and
<code>world.find_or_create</code> returns <code>mode_not_found</code>.</p>
</blockquote>
<pre><code class="language-lua">-- lua/world.lua

-- World mode config
game_type   = &quot;world&quot;
match_size  = 10            -- required by the loader for every mode,
                            -- including worlds. Use 1 for worlds that
                            -- don't gate on a minimum player count.
max_players = 500
grid_size   = 5
zone_size   = 400
tick_rate   = 50
view_radius = 1
strategy    = &quot;fill&quot;

function init(config)
    return {
        dungeon_level = 1,
        boss_hp = 10000,
        tick_count = 0
    }
end

function join(player_id, state)
    return state
end

function leave(player_id, state)
    return state
end

function spawn_position(player_id, state)
    return {
        x = 100 + math.random(200),
        y = 100 + math.random(200)
    }
end

function post_tick(tick, state)
    state.tick_count = tick

    -- Boss defeated: trigger a vote
    if state.boss_hp &lt;= 0 then
        state.boss_hp = 10000
        state.dungeon_level = state.dungeon_level + 1
        state._vote = {
            template = &quot;boon_pick&quot;,
            options = {
                { id = &quot;shield&quot;, label = &quot;Shield Boost&quot; },
                { id = &quot;speed&quot;,  label = &quot;Speed Boost&quot; },
                { id = &quot;damage&quot;, label = &quot;Damage Boost&quot; }
            },
            method = &quot;plurality&quot;,
            window_ms = 15000
        }
    end

    -- Time limit: 30 minutes at 20 Hz
    if tick &gt;= 36000 then
        state._finished = true
        state._result = { reason = &quot;time_up&quot; }
    end

    return state
end

-- Optional: procedural generation
function generate_world(seed, config)
    local zones = {}
    for x = 0, 4 do
        for y = 0, 4 do
            local key = x .. &quot;,&quot; .. y
            zones[key] = {
                biome = pick_biome(x, y, seed),
                spawners = {}
            }
        end
    end
    return zones
end

function get_state(player_id, state)
    return {
        dungeon_level = state.dungeon_level,
        boss_hp = state.boss_hp
    }
end
</code></pre>
<h3 id="lua-callbacks" tabindex="-1">Lua Callbacks</h3>
<table>
<thead>
<tr>
<th>Function</th>
<th>Required</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>init(config)</code></td>
<td>yes</td>
<td>Return initial global game state</td>
</tr>
<tr>
<td><code>join(player_id, state)</code></td>
<td>yes</td>
<td>Handle player join, return state</td>
</tr>
<tr>
<td><code>leave(player_id, state)</code></td>
<td>yes</td>
<td>Handle player leave, return state</td>
</tr>
<tr>
<td><code>spawn_position(player_id, state)</code></td>
<td>yes</td>
<td>Return <code>{x=N, y=N}</code> table</td>
</tr>
<tr>
<td><code>post_tick(tick, state)</code></td>
<td>yes</td>
<td>Global tick logic. Set <code>_finished</code>/<code>_result</code> or <code>_vote</code> on state</td>
</tr>
<tr>
<td><code>generate_world(seed, config)</code></td>
<td>no</td>
<td>Return table keyed by <code>&quot;x,y&quot;</code> strings</td>
</tr>
<tr>
<td><code>get_state(player_id, state)</code></td>
<td>no</td>
<td>Player-visible state</td>
</tr>
<tr>
<td><code>vote_resolved(template, result, state)</code></td>
<td>no</td>
<td>Handle vote result</td>
</tr>
</tbody>
</table>
<h3 id="finishing-a-world" tabindex="-1">Finishing a World</h3>
<p>Set <code>_finished</code> and <code>_result</code> on your state in <code>post_tick()</code>:</p>
<pre><code class="language-lua">function post_tick(tick, state)
    if all_quests_complete(state) then
        state._finished = true
        state._result = {
            status = &quot;completed&quot;,
            dungeon_level = state.dungeon_level,
            survivors = count_alive(state)
        }
    end
    return state
end
</code></pre>
<h3 id="triggering-votes" tabindex="-1">Triggering Votes</h3>
<p>Set <code>_vote</code> on your state in <code>post_tick()</code>:</p>
<pre><code class="language-lua">function post_tick(tick, state)
    if state.boss_hp &lt;= 0 then
        state._vote = {
            template = &quot;choose_path&quot;,
            options = {
                { id = &quot;cave&quot;, label = &quot;Dark Cave&quot; },
                { id = &quot;forest&quot;, label = &quot;Enchanted Forest&quot; }
            },
            method = &quot;plurality&quot;,
            window_ms = 20000
        }
        state.boss_hp = nil  -- clear so vote doesn't re-trigger
    end
    return state
end
</code></pre>
<h2 id="erlang-implementation" tabindex="-1">Erlang Implementation</h2>
<p>Implement the <code>asobi_world</code> behaviour:</p>
<pre><code class="language-erlang">-module(my_dungeon).
-behaviour(asobi_world).

-export([init/1, join/2, leave/2, spawn_position/2]).
-export([zone_tick/2, handle_input/3, post_tick/2]).

init(_Config) -&gt;
    {ok, #{dungeon_level =&gt; 1, boss_hp =&gt; 10000}}.

join(PlayerId, State) -&gt;
    {ok, State}.

leave(PlayerId, State) -&gt;
    {ok, State}.

spawn_position(_PlayerId, _State) -&gt;
    %% Random position in the first zone
    {ok, {50.0 + rand:uniform(100), 50.0 + rand:uniform(100)}}.

zone_tick(Entities, ZoneState) -&gt;
    %% Run NPC AI, move projectiles, apply effects
    Entities1 = maps:map(fun(Id, E) -&gt;
        case maps:get(type, E, ~&quot;player&quot;) of
            ~&quot;goblin&quot; -&gt; ai_wander(E);
            _ -&gt; E
        end
    end, Entities),
    {Entities1, ZoneState}.

handle_input(PlayerId, #{~&quot;action&quot; := ~&quot;move&quot;, ~&quot;x&quot; := X, ~&quot;y&quot; := Y}, Entities) -&gt;
    case Entities of
        #{PlayerId := Entity} -&gt;
            {ok, Entities#{PlayerId =&gt; Entity#{x =&gt; X, y =&gt; Y}}};
        _ -&gt;
            {error, not_found}
    end;
handle_input(_PlayerId, _Input, Entities) -&gt;
    {ok, Entities}.

post_tick(TickN, #{boss_hp := HP} = State) when HP =&lt; 0 -&gt;
    %% Boss defeated -- trigger an upgrade vote
    {vote, #{
        template =&gt; ~&quot;boon_pick&quot;,
        options =&gt; [
            #{id =&gt; ~&quot;shield&quot;, label =&gt; ~&quot;Shield Boost&quot;},
            #{id =&gt; ~&quot;speed&quot;, label =&gt; ~&quot;Speed Boost&quot;},
            #{id =&gt; ~&quot;damage&quot;, label =&gt; ~&quot;Damage Boost&quot;}
        ],
        method =&gt; ~&quot;plurality&quot;,
        window_ms =&gt; 15000
    }, State#{boss_hp =&gt; 10000, dungeon_level =&gt; maps:get(dungeon_level, State) + 1}};
post_tick(TickN, State) when TickN &gt;= 36000 -&gt;
    %% 30 minutes at 20 Hz
    {finished, #{reason =&gt; ~&quot;time_up&quot;}, State};
post_tick(_TickN, State) -&gt;
    {ok, State}.
</code></pre>
<h3 id="callbacks" tabindex="-1">Callbacks</h3>
<table>
<thead>
<tr>
<th>Callback</th>
<th>Required</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>init/1</code></td>
<td>yes</td>
<td>Initialize global game state</td>
</tr>
<tr>
<td><code>join/2</code></td>
<td>yes</td>
<td>Player joined the world</td>
</tr>
<tr>
<td><code>leave/2</code></td>
<td>yes</td>
<td>Player left the world</td>
</tr>
<tr>
<td><code>spawn_position/2</code></td>
<td>yes</td>
<td>Return <code>{ok, {X, Y}}</code> for new player placement</td>
</tr>
<tr>
<td><code>zone_tick/2</code></td>
<td>yes</td>
<td>Per-zone simulation: <code>(Entities, ZoneState) -&gt; {Entities, ZoneState}</code></td>
</tr>
<tr>
<td><code>handle_input/3</code></td>
<td>yes</td>
<td>Process player input within a zone's entities</td>
</tr>
<tr>
<td><code>post_tick/2</code></td>
<td>yes</td>
<td>Global post-tick: return <code>{ok, State}</code>, <code>{vote, Config, State}</code>, or <code>{finished, Result, State}</code></td>
</tr>
<tr>
<td><code>generate_world/2</code></td>
<td>no</td>
<td>Procedural generation: <code>(Seed, Config) -&gt; {ok, #{Coords =&gt; ZoneState}}</code></td>
</tr>
<tr>
<td><code>get_state/2</code></td>
<td>no</td>
<td>Per-player state view</td>
</tr>
<tr>
<td><code>vote_resolved/3</code></td>
<td>no</td>
<td>Handle vote result (inherited from match voting)</td>
</tr>
</tbody>
</table>
<h3 id="configuration" tabindex="-1">Configuration</h3>
<p>Register your world mode in <code>sys.config</code>:</p>
<pre><code class="language-erlang">{asobi, [
    {game_modes, #{
        ~&quot;dungeon&quot; =&gt; #{
            type =&gt; world,
            module =&gt; my_dungeon,
            match_size =&gt; 10,
            max_players =&gt; 500,
            grid_size =&gt; 10,        %% 10x10 = 100 zones
            zone_size =&gt; 200,       %% each zone covers 200x200 units
            tick_rate =&gt; 50,        %% 50ms = 20 Hz
            view_radius =&gt; 1,       %% subscribe to 1 zone in each direction (3x3 = 9 zones)
            strategy =&gt; fill
        }
    }}
]}
</code></pre>
<table>
<thead>
<tr>
<th>Option</th>
<th>Default</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>type</code></td>
<td><code>match</code></td>
<td>Must be <code>world</code> for world server mode</td>
</tr>
<tr>
<td><code>grid_size</code></td>
<td>10</td>
<td>Number of zones per axis (total = grid_size^2)</td>
</tr>
<tr>
<td><code>zone_size</code></td>
<td>200</td>
<td>Units per zone side (world size = grid_size * zone_size)</td>
</tr>
<tr>
<td><code>tick_rate</code></td>
<td>50</td>
<td>Milliseconds between ticks (50 = 20 Hz)</td>
</tr>
<tr>
<td><code>view_radius</code></td>
<td>1</td>
<td>Zones visible in each direction from player's zone</td>
</tr>
<tr>
<td><code>max_players</code></td>
<td>500</td>
<td>Maximum concurrent players per world</td>
</tr>
<tr>
<td><code>zone_idle_timeout</code></td>
<td>30000</td>
<td>Milliseconds an empty zone lingers before it is released</td>
</tr>
<tr>
<td><code>empty_grace_ms</code></td>
<td>0</td>
<td>Milliseconds a world with no players lingers before it finishes (0 = finish immediately)</td>
</tr>
<tr>
<td><code>snapshot_interval</code></td>
<td>600</td>
<td>Ticks between zone snapshots (see <a href="#snapshots">Snapshots</a>)</td>
</tr>
<tr>
<td><code>listed</code></td>
<td><code>true</code></td>
<td>Whether worlds of this mode appear in <code>world.list</code> / <code>GET /api/v1/worlds</code></td>
</tr>
<tr>
<td><code>quick_play</code></td>
<td><code>true</code></td>
<td>Whether <code>world.find_or_create</code> may place a player into an existing world of this mode</td>
</tr>
</tbody>
</table>
<h3 id="visibility" tabindex="-1">Visibility</h3>
<p><code>listed</code> and <code>quick_play</code> are independent axes, so a mode can be browsable
but out of quick-play rotation, or reachable by quick-play while hidden from
the browser.</p>
<pre><code class="language-erlang">~&quot;tutorial&quot; =&gt; #{
    type =&gt; world,
    module =&gt; my_tutorial,
    listed =&gt; false,      %% never shows up in the browser
    quick_play =&gt; false   %% and never absorbs a quick-play request
}
</code></pre>
<p>Neither flag gates joining. A client that already knows a <code>world_id</code> can
still <code>world.join</code> it. Both flags control discovery only.</p>
<p>Both are properties of the <strong>mode</strong>, not of a world instance, so a player
cannot host a private world at runtime. A mode is either discoverable or it
is not, for every world it spawns. Player-hosted private games need join
authorisation, which does not exist yet.</p>
<p>With <code>quick_play =&gt; false</code>, <code>world.find_or_create</code> returns
<code>quick_play_disabled</code> rather than creating a world, since it could never
find the one it just made.</p>
<h3 id="procedural-generation" tabindex="-1">Procedural Generation</h3>
<p>Implement <code>generate_world/2</code> to provide initial state for each zone:</p>
<pre><code class="language-erlang">generate_world(Seed, _Config) -&gt;
    rand:seed(exsss, {Seed, Seed, Seed}),
    ZoneStates = maps:from_list([
        {{X, Y}, #{
            biome =&gt; pick_biome(X, Y),
            npcs =&gt; generate_npcs(X, Y),
            loot =&gt; generate_loot(X, Y)
        }}
     || X &lt;- lists:seq(0, 9), Y &lt;- lists:seq(0, 9)
    ]),
    {ok, ZoneStates}.
</code></pre>
<p>Each zone receives its state via the <code>zone_state</code> field in <code>zone_tick/2</code>.</p>
<h2 id="spawn-templates" tabindex="-1">Spawn templates</h2>
<p>Worlds seed non-player entities (NPCs, resources, objects) from <strong>spawn
templates</strong>. Implement the optional <code>spawn_templates/1</code> callback to return a
map of template id to template definition.</p>
<p>A template has:</p>
<ul>
<li><code>type</code> -- the entity type applied to every spawned instance.</li>
<li><code>base_state</code> -- a map merged into every entity spawned from the template.</li>
<li><code>respawn</code> -- optional respawn policy: <code>strategy</code> (currently <code>timer</code>),
<code>delay</code> (milliseconds), <code>jitter</code> (milliseconds of random spread added to
the delay), and <code>max_respawns</code> (cap, or <code>infinity</code>).</li>
<li><code>persistent</code> -- whether a spawned entity survives a zone snapshot/restore.
Lua entities default to <code>true</code>.</li>
</ul>
<p>At runtime, Lua scripts spawn from a template with
<code>game.zone.spawn(&quot;goblin&quot;, x, y, {overrides})</code>, where the optional table
overrides fields from the template's <code>base_state</code>.</p>
<pre><code class="language-lua">function spawn_templates(config)
    return {
        goblin = {
            type       = &quot;npc&quot;,
            base_state = { health = 100, ai = &quot;patrol&quot; },
            respawn    = { delay = 5000, jitter = 1000, max_respawns = 3 }
        },
        chest = {
            type       = &quot;object&quot;,
            base_state = { loot = &quot;common&quot; }
        }
    }
end

function zone_tick(entities, zone_state)
    game.zone.spawn(&quot;goblin&quot;, 500, 500)
    game.zone.spawn(&quot;chest&quot;, 620, 600, { loot = &quot;rare&quot; })
    return entities, zone_state
end
</code></pre>
<p>See the <code>examples/world-spawns</code> demo for a complete world script.</p>
<h2 id="snapshots" tabindex="-1">Snapshots</h2>
<p><code>asobi_zone_snapshotter</code> periodically persists each zone's entities and
restores them on restart, before the zone accepts new subscribers. Tune the
cadence with the <code>snapshot_interval</code> config key (default 600, measured in
<strong>ticks</strong>, not milliseconds).</p>
<h2 id="subscriptions" tabindex="-1">Subscriptions</h2>
<p>A player subscribes to the 3x3 neighbourhood of zones around their entity.
Membership is recomputed as the player moves: entering a zone streams a
snapshot of that zone's currently-visible entities, and leaving a zone stops
its updates.</p>
<h2 id="websocket-protocol" tabindex="-1">WebSocket Protocol</h2>
<p>World messages use the <code>world.*</code> namespace. See the full
<a href="/docs/protocols/websocket">WebSocket Protocol</a> for envelope format.</p>
<h3 id="client-to-server" tabindex="-1">Client to Server</h3>
<table>
<thead>
<tr>
<th>Type</th>
<th>Payload</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>world.join</code></td>
<td><code>{&quot;world_id&quot;: &quot;...&quot;}</code></td>
<td>Join a specific world</td>
</tr>
<tr>
<td><code>world.leave</code></td>
<td><code>{}</code></td>
<td>Leave current world</td>
</tr>
<tr>
<td><code>world.input</code></td>
<td><code>{&quot;action&quot;: &quot;move&quot;, &quot;x&quot;: 100, &quot;y&quot;: 200}</code></td>
<td>Send input to your zone</td>
</tr>
</tbody>
</table>
<h3 id="server-to-client" tabindex="-1">Server to Client</h3>
<table>
<thead>
<tr>
<th>Type</th>
<th>Payload</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>world.joined</code></td>
<td><code>{world_id, status, player_count, grid_size}</code></td>
<td>Join confirmed</td>
</tr>
<tr>
<td><code>world.left</code></td>
<td><code>{success: true}</code></td>
<td>Leave confirmed</td>
</tr>
<tr>
<td><code>world.tick</code></td>
<td><code>{tick, updates: [{op, id, ...}]}</code></td>
<td>Zone delta broadcast</td>
</tr>
<tr>
<td><code>world.finished</code></td>
<td><code>{world_id, result}</code></td>
<td>World ended</td>
</tr>
</tbody>
</table>
<h3 id="input-routing" tabindex="-1">Input Routing</h3>
<p>When you send <code>world.input</code>, the message is routed to the zone process
that currently owns your player entity. You don't need to specify which
zone -- the server tracks your position and routes automatically.</p>
<h2 id="chat-channels" tabindex="-1">Chat Channels</h2>
<p>World chat is configuration-driven. Enable the channel types you need per
game mode:</p>
<pre><code class="language-erlang">{asobi, [
    {game_modes, #{
        ~&quot;galaxy&quot; =&gt; #{
            type =&gt; world,
            module =&gt; my_game,
            chat =&gt; #{
                world =&gt; true,       %% global channel for everyone in the world
                zone =&gt; true,        %% auto-join/leave as players move between zones
                proximity =&gt; 2       %% chat with players within N zones of you
            }
        }
    }}
]}
</code></pre>
<p>Lua equivalent:</p>
<pre><code class="language-lua">-- In your world script globals
chat_world     = true
chat_zone      = true
chat_proximity = 2
</code></pre>
<h3 id="channel-types" tabindex="-1">Channel Types</h3>
<table>
<thead>
<tr>
<th>Type</th>
<th>Scope</th>
<th>Lifecycle</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>World</strong></td>
<td>All players in the world instance</td>
<td>Join on world join, leave on world leave</td>
</tr>
<tr>
<td><strong>Zone</strong></td>
<td>Players in the same zone cell</td>
<td>Auto-swap when crossing zone boundaries</td>
</tr>
<tr>
<td><strong>Proximity</strong></td>
<td>Players within N zones</td>
<td>Follows your interest radius, updates on zone change</td>
</tr>
<tr>
<td><strong>Federation</strong></td>
<td>Federation members only</td>
<td>Managed by the social system (works automatically)</td>
</tr>
</tbody>
</table>
<h3 id="how-it-works-1" tabindex="-1">How It Works</h3>
<p>Chat channels use the existing <code>asobi_chat_channel</code> system. The world
server automatically manages subscriptions:</p>
<ul>
<li><strong>On join</strong>: player is added to world chat and their spawn zone's chat</li>
<li><strong>On zone change</strong>: old zone chat is left, new zone chat is joined.
Proximity channels diff the old and new interest areas so only the
delta is updated</li>
<li><strong>On leave</strong>: all world/zone/proximity channels are cleaned up</li>
</ul>
<p>No extra client code needed. Chat messages arrive via the same WebSocket
as <code>chat.message</code> events. Clients just need to know the channel IDs,
which follow a predictable format:</p>
<ul>
<li>World: <code>world:{world_id}</code></li>
<li>Zone: <code>zone:{world_id}:{x},{y}</code></li>
<li>Proximity: <code>prox:{world_id}:{x},{y}</code></li>
</ul>
<h3 id="no-chat-config" tabindex="-1">No Chat Config</h3>
<p>If you omit the <code>chat</code> key entirely, no chat channels are created. The
world server runs without any chat overhead. Add channels later by
updating your mode config.</p>
<h2 id="clustering" tabindex="-1">Clustering</h2>
<p>Zones are regular Erlang processes. In a multi-node cluster, they
distribute across nodes automatically via <code>pg</code>. A player on Node A can
be subscribed to a zone on Node B -- Erlang distribution handles the
message routing transparently.</p>
<p>For large worlds, zones are distributed round-robin across cluster nodes:</p>
<pre><code>Node A: zones {0,0}..{4,4}  (25 zones)
Node B: zones {5,0}..{9,4}  (25 zones)
Node C: zones {0,5}..{4,9}  (25 zones)
Node D: zones {5,5}..{9,9}  (25 zones)
</code></pre>
<h2 id="next-steps" tabindex="-1">Next Steps</h2>
<ul>
<li><a href="https://hexdocs.pm/asobi/lua-scripting.html">Lua Scripting</a> -- match-based Lua scripting</li>
<li><a href="/docs/voting">Voting</a> -- in-game voting system</li>
<li><a href="/docs/matchmaking">Matchmaking</a> -- how players enter worlds</li>
<li><a href="/docs/clustering">Clustering</a> -- multi-node deployment</li>
</ul>
"""}
    ]}.
