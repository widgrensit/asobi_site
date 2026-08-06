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
        {h1, [], [~"World server"]},
        {raw,
            ~"""
<p>Large-session multiplayer with spatial partitioning. The world server holds
players in a shared continuous space and splits that space into zone processes
for parallelised tick simulation and interest-based state broadcasting.</p>
<p>Use it when players move through a shared space: co-op dungeons, open worlds,
large-scale survival. For arena-style games with smaller player counts, use the
<a href="/docs/matchmaking">match server</a>.</p>
<p>For massive tile-based worlds, see <a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a> for lazy zone
loading, terrain data and scaling configuration.</p>
<h2 id="how-it-works" tabindex="-1">How it works</h2>
<p>A world is divided into a grid of <strong>zones</strong>, each a separate Erlang process
owning the entities in its region. A player receives updates only from the
zones they can see (interest management), and each zone runs its tick in
parallel across CPU cores.</p>
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
<h3 id="supervision-tree" tabindex="-1">Supervision tree</h3>
<p>Each world instance is its own supervisor:</p>
<pre><code>asobi_world_sup (one_for_one)
├── asobi_zone_snapshotter       - batched snapshot writer, one per node
├── asobi_world_registry         - tracks active worlds on this node
└── asobi_world_instance_sup     - dynamic, one child per world
    └── asobi_world_instance     - one_for_all per world
        ├── asobi_zone_sup       - dynamic, one child per live zone cell
        │   └── asobi_zone       - gen_server per grid cell
        ├── asobi_zone_manager   - owns which cells are live and reaps idle ones
        ├── asobi_world_ticker   - coordinates ticks across zones
        └── asobi_world_server   - gen_statem, world lifecycle
</code></pre>
<p>The top three are node-wide singletons. Everything under
<code>asobi_world_instance</code> is per world, which is why a world costs six processes
before a single zone beyond the first.</p>
<h3 id="tick-cycle" tabindex="-1">Tick cycle</h3>
<p>Every tick (default 20 Hz, 50ms):</p>
<ol>
<li>The ticker sends <code>tick(N)</code> to every zone in parallel.</li>
<li>Each zone applies queued player inputs, runs <code>zone_tick/2</code>, computes deltas
from the previous state and broadcasts them to its subscribers.</li>
<li>Each zone acks back to the ticker.</li>
<li>When every zone has acked, the ticker calls <code>post_tick/2</code> on the world
server for global events: boss phases, quest triggers, vote requests.</li>
</ol>
<h3 id="delta-compression" tabindex="-1">Delta compression</h3>
<p>Zones send only what changed since the last tick:</p>
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
<li><code>u</code> - updated, only the changed fields</li>
<li><code>a</code> - added, full entity state</li>
<li><code>r</code> - removed</li>
</ul>
<h2 id="in-lua" tabindex="-1">In Lua</h2>
<p>Run <code>ghcr.io/widgrensit/asobi</code> and write a world script. The
<a href="#in-erlang">Erlang behaviour</a> below is the same model on the other surface of
the same node, for a release that depends on the Hex package.</p>
<p>World scripts follow the same pattern as match scripts, with zone-specific
callbacks. Set <code>game_type = &quot;world&quot;</code> in your mode globals.</p>
<p>The global is <code>game_type</code>, not <code>type</code>. The Erlang <code>sys.config</code> form uses the
key <code>type</code>, but the Lua loader reads <code>game_type</code>. A Lua script setting
<code>type = &quot;world&quot;</code> is silently ignored: it registers as a match mode, so
<code>world.find_or_create</code> hands the match bridge to the world server, which then
crashes on the world callbacks that bridge does not export (<code>spawn_position/2</code>,
<code>zone_tick/2</code>, <code>post_tick/2</code>). There is no clean error for this - check
<code>game_type</code> first.</p>
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

    -- Boss defeated: next level, and tell every client
    if state.boss_hp &lt;= 0 then
        state.boss_hp = 10000
        state.dungeon_level = state.dungeon_level + 1
        game.broadcast(&quot;level_up&quot;, { level = state.dungeon_level })
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
<h3 id="lua-callbacks" tabindex="-1">Lua callbacks</h3>
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
<td>Return the initial global game state</td>
</tr>
<tr>
<td><code>join(player_id, state)</code></td>
<td>yes</td>
<td>Player joined; return state</td>
</tr>
<tr>
<td><code>join(player_id, state, ctx)</code></td>
<td>no</td>
<td>Same, plus the client's join context. Declare the third parameter and it is used instead - see <a href="/docs/protocols/websocket#join-context">Join context</a></td>
</tr>
<tr>
<td><code>leave(player_id, state)</code></td>
<td>yes</td>
<td>Player left; return state</td>
</tr>
<tr>
<td><code>spawn_position(player_id, state)</code></td>
<td>yes</td>
<td>Return a <code>{x=N, y=N}</code> table</td>
</tr>
<tr>
<td><code>post_tick(tick, state)</code></td>
<td>yes</td>
<td>Global tick logic. Set <code>_finished</code> and <code>_result</code> on state to end the world</td>
</tr>
<tr>
<td><code>zone_tick(entities, zone_state)</code></td>
<td>no</td>
<td>Per-zone simulation; return both</td>
</tr>
<tr>
<td><code>handle_input(player_id, input, entities)</code></td>
<td>no</td>
<td>Apply one player's input to that zone's entities</td>
</tr>
<tr>
<td><code>generate_world(seed, config)</code></td>
<td>no</td>
<td>Return a table keyed by <code>&quot;x,y&quot;</code> strings</td>
</tr>
<tr>
<td><code>get_state(player_id, state)</code></td>
<td>no</td>
<td>Player-visible state</td>
</tr>
<tr>
<td><code>spawn_templates(config)</code></td>
<td>no</td>
<td>See <a href="#spawn-templates">Spawn templates</a></td>
</tr>
<tr>
<td><code>phases(config)</code></td>
<td>no</td>
<td>See <a href="/docs/phases">Phases</a></td>
</tr>
<tr>
<td><code>on_phase_started(name, state)</code> / <code>on_phase_ended(name, state)</code></td>
<td>no</td>
<td>Phase transitions</td>
</tr>
<tr>
<td><code>on_zone_loaded(cx, cy, state)</code> / <code>on_zone_unloaded(cx, cy, state)</code></td>
<td>no</td>
<td>See <a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a></td>
</tr>
<tr>
<td><code>terrain_provider(config)</code></td>
<td>no</td>
<td>See <a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a></td>
</tr>
<tr>
<td><code>on_world_recovered(snapshot, state)</code></td>
<td>no</td>
<td>The world process restarted and a snapshot was recovered</td>
</tr>
</tbody>
</table>
<p><code>vote_resolved</code> is not on this list on purpose. The world bridge does not
export it, so a Lua world script defining <code>vote_resolved</code> is never called. See
<a href="/docs/voting">Voting</a> for what does and does not reach a Lua world today.</p>
<h3 id="finishing-a-world" tabindex="-1">Finishing a world</h3>
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
<h3 id="triggering-votes" tabindex="-1">Triggering votes</h3>
<p>Setting <code>state._vote</code> in <code>post_tick</code> is the world's vote trigger, and the
server does read it every tick. It does not start a vote today: the decoded
table reaches the vote server with the wrong key type and the failure is
swallowed. <a href="/docs/voting">Voting</a> has the detail and the Erlang route that works.</p>
<h2 id="in-erlang" tabindex="-1">In Erlang</h2>
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
    %% Boss defeated - trigger an upgrade vote
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
<td>Initialise global game state</td>
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
<td>Handle vote result. Not declared on the <code>asobi_world</code> behaviour: the world server looks for it with <code>erlang:function_exported/3</code>, so exporting it works but the compiler will not tell you if the arity is wrong</td>
</tr>
</tbody>
</table>
<h3 id="entity-keys" tabindex="-1">Entity keys</h3>
<p>Entity maps are yours: asobi stores whatever a callback returns and only
reads <code>x</code>, <code>y</code>, <code>type</code> and <code>persistent</code> from them, for zone crossings,
spatial queries, hibernation and snapshots. Those four are read under either
an atom key (<code>x</code>) or a binary one (<code>~&quot;x&quot;</code>), so a scripting bridge that hands
entities back binary-keyed works the same as a native Erlang module. Mixing
shapes within one entity is not supported - keep an entity's keys consistent.</p>
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
<td><code>module</code></td>
<td>required</td>
<td>The game module, or <code>{lua, &quot;path.lua&quot;}</code></td>
</tr>
<tr>
<td><code>grid_size</code></td>
<td>10</td>
<td>Zones per axis; total zones = <code>grid_size^2</code></td>
</tr>
<tr>
<td><code>zone_size</code></td>
<td>200</td>
<td>Units per zone side; world size = <code>grid_size * zone_size</code></td>
</tr>
<tr>
<td><code>tick_rate</code></td>
<td>50</td>
<td>Milliseconds between ticks (50 = 20 Hz)</td>
</tr>
<tr>
<td><code>view_radius</code></td>
<td>1</td>
<td>Zones visible in each direction from the player's zone</td>
</tr>
<tr>
<td><code>max_players</code></td>
<td>500</td>
<td>Concurrent players per world</td>
</tr>
<tr>
<td><code>persistent</code></td>
<td><code>false</code></td>
<td>Keep the world alive with no players in it</td>
</tr>
<tr>
<td><code>empty_grace_ms</code></td>
<td>0</td>
<td>Milliseconds an empty world lingers before finishing. 0 finishes immediately</td>
</tr>
<tr>
<td><code>player_ttl_ms</code></td>
<td>0</td>
<td>Milliseconds a disconnected player's entity is held for reconnection</td>
</tr>
<tr>
<td><code>listed</code></td>
<td><code>true</code></td>
<td>Whether worlds of this mode appear in <code>world.list</code> and <code>GET /api/v1/worlds</code></td>
</tr>
<tr>
<td><code>quick_play</code></td>
<td><code>true</code></td>
<td>Whether <code>world.find_or_create</code> may place a player into an existing world of this mode</td>
</tr>
<tr>
<td><code>chat</code></td>
<td><code>#{}</code></td>
<td>See <a href="#chat-channels">Chat channels</a></td>
</tr>
</tbody>
</table>
<p>Using a world as a persistent hub is covered in <a href="https://hexdocs.pm/asobi/lobbies.html">Lobbies</a>.</p>
<h3 id="four-values-you-cannot-set" tabindex="-1">Four values you cannot set</h3>
<p>These four look like mode options and are not: the mode config never reaches
the process that would read them, so every world runs on the built-in value.
Plan around them as facts of the deployment, not knobs.</p>
<table>
<thead>
<tr>
<th>Value</th>
<th>What every world gets</th>
</tr>
</thead>
<tbody>
<tr>
<td>Active zones per world</td>
<td>10,000. See <a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a> for what happens at that ceiling</td>
</tr>
<tr>
<td>Zone idle timeout</td>
<td>30 seconds before an empty zone is released</td>
</tr>
<tr>
<td>Rehome margin</td>
<td>0.15 of <code>zone_size</code> (described below)</td>
</tr>
<tr>
<td>Zone snapshot interval</td>
<td>600 ticks, and moot - see <a href="#snapshots">Snapshots</a></td>
</tr>
</tbody>
</table>
<p>An entity, player or NPC, must clear its zone's edge by the rehome margin (a
fraction of <code>zone_size</code>) before re-homing to the neighbouring zone, so an
entity parked on or jittering across a boundary does not re-home every tick.
An entity's tracked zone can therefore lag its true position by up to that
margin near a boundary: an entity in a zone's entity map is not necessarily
strictly inside that zone's rectangle.</p>
<p>The zone-based <code>game.spatial.query_radius(x, y, radius)</code> and
<code>game.spatial.query_rect(x1, y1, x2, y2)</code> search only the calling zone's own
entity map, so this lag has a direction that matters: an area geometrically
inside zone A's rectangle can be occupied by an entity zone B still owns,
because it has not cleared the margin yet. A query issued from zone A over that
area misses it entirely, and the gap persists - an NPC parked just past its
zone's edge stays invisible to the neighbour's queries indefinitely, not only
for the tick it takes to cross. Account for that if your NPC AI queries by
position near zone edges.</p>
<p>The margin bounds this slack only for positions inside the world rectangle. An
entity outside it entirely is clamped into the edge zone by <code>pos_to_zone</code> and
stays owned by that zone at any distance past the edge, so validate positions
in your movement handler if your game trusts the zone rectangle as a hard
bound. A band-parked NPC also stays visible to a neighbouring zone's
<em>subscribers</em> only while <code>view_radius &gt;= 1</code> keeps that neighbour touched every
tick; at <code>view_radius = 0</code> the owning zone can idle out under coordinates a
player standing metres away never loads.</p>
<p>See <a href="/docs/configuration">Configuration</a> for the <code>rehome</code> rate limit on how often
a player may re-home at all. NPCs re-home directly without going through that
limiter, since <code>asobi_zone</code> owns them outright.</p>
<h2 id="visibility" tabindex="-1">Visibility</h2>
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
<h3 id="procedural-generation" tabindex="-1">Procedural generation</h3>
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
<li><code>type</code> - the entity type applied to every spawned instance.</li>
<li><code>base_state</code> - a map merged into every entity spawned from the template.</li>
<li><code>respawn</code> - optional respawn policy: <code>strategy</code> (currently <code>timer</code>),
<code>delay</code> (milliseconds), <code>jitter</code> (milliseconds of random spread added to
the delay), and <code>max_respawns</code> (cap, or <code>infinity</code>).</li>
<li><code>persistent</code> - whether a spawned entity would survive a zone snapshot and
restore (see <a href="#snapshots">Snapshots</a> for why none is taken today).
Lua entities default to <code>true</code>.</li>
</ul>
<p>At runtime, Lua scripts spawn from a template with
<code>game.zone.spawn(&quot;goblin&quot;, x, y, {overrides})</code>, where the optional table
overrides fields from the template's <code>base_state</code>.</p>
<p>If <code>template_id</code> doesn't match a key returned by <code>spawn_templates</code>, nothing
spawns: <code>game.zone.spawn</code> has no return value to report the failure. The zone
logs a <code>zone_spawn_failed</code> warning with the <code>world_id</code> and <code>coords</code>, and
emits <code>[asobi, error]</code> with <code>kind =&gt; unknown_spawn_template</code>.</p>
<h3 id="updating-templates-in-an-already-running-zone" tabindex="-1">Updating templates in an already-running zone</h3>
<p><code>spawn_templates/1</code> is only ever called once, at zone creation - a template
added later (e.g. via a script hot-reload) never reaches a zone that's
already running; it stays invisible to that zone until the zone is recreated.</p>
<p>The optional <code>spawn_templates_hint/1</code> Erlang callback closes this: it runs
every tick, and returning <code>{changed, NewTemplates}</code> pushes an updated
template set into the live zone immediately. Return <code>unchanged</code> in the
common case - this runs on the hot path, so a game module implementing it
owns the cost of deciding whether anything actually changed (e.g. only doing
real work right after its own hot-reload check fires), not this callback
being a place to unconditionally re-derive templates every tick.</p>
<p><code>NewTemplates</code> <strong>replaces</strong> the zone's whole template set, the same as
<code>spawn_templates/1</code>'s result does at creation - it is not a delta. Include
every template that should still be spawnable, not only the ones that
changed, or the rest silently stop being spawnable.</p>
<pre><code class="language-erlang">spawn_templates_hint(ZoneState) -&gt;
    case just_reloaded(ZoneState) of
        false -&gt; unchanged;
        true -&gt; {changed, current_templates(ZoneState)}
    end.
</code></pre>
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
<p><code>asobi_zone_snapshotter</code> is a batched writer that persists a zone's entities,
zone state, entity timers and spawner state to the <code>zone_snapshots</code> table, and
loads them back when a zone starts blank.</p>
<p><strong>No world writes one today.</strong> The zone reads a <code>persistence</code> flag, and the
mode config that would set it emits <code>persistent</code> instead, so the flag is always
false and both the periodic write and the restore-on-start are skipped. Setting
<code>persistent = true</code> in a mode keeps a world alive when it empties; it does not
survive a node restart.</p>
<p>What does still work is a per-zone ETS backup written every 20 ticks. It is
crash recovery for a zone process inside a running node, not durability across
a restart.</p>
<p>Do not build on cross-restart world state until this is fixed. A world's
entities are in memory only.</p>
<h2 id="subscriptions" tabindex="-1">Subscriptions</h2>
<p>A player subscribes to the 3x3 neighbourhood of zones around their entity.
Membership is recomputed as the player moves: entering a zone streams a
snapshot of that zone's currently visible entities, and leaving a zone stops
its updates.</p>
<h2 id="websocket-protocol" tabindex="-1">WebSocket protocol</h2>
<p>World messages use the <code>world.*</code> namespace. See
<a href="/docs/protocols/websocket">WebSocket protocol</a> for the envelope.</p>
<h3 id="client-to-server" tabindex="-1">Client to server</h3>
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
<td><code>world.create</code></td>
<td><code>{&quot;mode&quot;: &quot;...&quot;}</code></td>
<td>Create a world of this mode and join it</td>
</tr>
<tr>
<td><code>world.find_or_create</code></td>
<td><code>{&quot;mode&quot;: &quot;...&quot;}</code></td>
<td>Join an existing world of this mode, or create one</td>
</tr>
<tr>
<td><code>world.join</code></td>
<td><code>{&quot;world_id&quot;: &quot;...&quot;}</code></td>
<td>Join a specific world</td>
</tr>
<tr>
<td><code>world.list</code></td>
<td><code>{&quot;mode&quot;: &quot;...&quot;, &quot;has_capacity&quot;: true}</code></td>
<td>Browse listed worlds</td>
</tr>
<tr>
<td><code>world.leave</code></td>
<td><code>{}</code></td>
<td>Leave the current world</td>
</tr>
<tr>
<td><code>world.input</code></td>
<td><code>{&quot;action&quot;: &quot;move&quot;, &quot;x&quot;: 100, &quot;y&quot;: 200}</code></td>
<td>Send input to your zone</td>
</tr>
</tbody>
</table>
<h3 id="server-to-client" tabindex="-1">Server to client</h3>
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
<td><code>{world_id, status, player_count, grid_size, ...}</code></td>
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
<td><code>world.phase_changed</code></td>
<td>the phase info block</td>
<td>See <a href="/docs/phases">Phases</a></td>
</tr>
<tr>
<td><code>world.terrain</code></td>
<td><code>{coords, data}</code></td>
<td>See <a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a></td>
</tr>
<tr>
<td><code>world.finished</code></td>
<td><code>{world_id, result}</code></td>
<td>World ended</td>
</tr>
</tbody>
</table>
<p>A player already in a world who sends <code>world.join</code> for a different one is
refused with <code>world.already_joined</code>; leave first.</p>
<h3 id="input-routing" tabindex="-1">Input routing</h3>
<p><code>world.input</code> is routed to the zone process that currently owns your player
entity. You do not name a zone: the server tracks your position and routes
automatically.</p>
<h2 id="chat-channels" tabindex="-1">Chat channels</h2>
<p>World chat is configuration-driven. Enable the channel types you need per
game mode:</p>
<pre><code class="language-erlang">{asobi, [
    {game_modes, #{
        ~&quot;galaxy&quot; =&gt; #{
            type =&gt; world,
            module =&gt; my_game,
            chat =&gt; #{
                global =&gt; [~&quot;general&quot;, ~&quot;trade&quot;], %% game-wide, spans every world
                world =&gt; true,       %% one channel for everyone in this world
                zone =&gt; true,        %% auto-join/leave as players move between zones
                proximity =&gt; 2       %% chat with players within N zones of you
            }
        }
    }}
]}
</code></pre>
<p>There is no Lua equivalent: the loader reads no chat globals, so a script
cannot turn a channel on. Chat is an operator <code>game_modes</code> entry, and that
entry replaces the script's mode config for that name rather than merging into
it - so a Lua world with chat needs the whole mode declared in <code>sys.config</code>,
<code>module =&gt; {lua, &quot;world.lua&quot;}</code> included.</p>
<h3 id="channel-types" tabindex="-1">Channel types</h3>
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
<td>Global</td>
<td>Every player in the game, across all worlds</td>
<td>Join on world join, leave on world leave</td>
</tr>
<tr>
<td>World</td>
<td>All players in the world instance</td>
<td>Join on world join, leave on world leave</td>
</tr>
<tr>
<td>Zone</td>
<td>Players in the same zone cell</td>
<td>Auto-swap when crossing zone boundaries</td>
</tr>
<tr>
<td>Proximity</td>
<td>Players within N zones</td>
<td>Follows your interest radius, updates on zone change</td>
</tr>
</tbody>
</table>
<h3 id="how-it-works-1" tabindex="-1">How it works</h3>
<p>Chat channels use the <code>asobi_chat_channel</code> system. The world server manages
subscriptions:</p>
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
<li>Global: <code>global:{name}</code></li>
<li>World: <code>world:{world_id}</code></li>
<li>Zone: <code>zone:{world_id}:{x},{y}</code></li>
<li>Proximity: <code>prox:{world_id}:{x},{y}</code></li>
</ul>
<p>A global channel carries no world id on purpose: every world of every mode
that declares the same name resolves the same channel process, so one message
is one broadcast and one row of history, not one per world. Only names
declared in a mode's <code>chat.global</code> are authorised, so a client cannot mint
new ones; names are up to 64 bytes of <code>a-z A-Z 0-9 _ - .</code> and anything else
is dropped with a warning at join time.</p>
<h3 id="no-chat-config" tabindex="-1">No chat config</h3>
<p>Omit the <code>chat</code> key and no channels are created. The world server then runs
with no chat overhead. Add channels later by updating your mode config.</p>
<h2 id="clustering" tabindex="-1">Clustering</h2>
<p>A world lives entirely on the node that created it. Its zones are local
processes under that world's instance supervisor; nothing distributes them
across nodes and there is no zone placement to configure. <code>pg</code> carries the
registrations - world server pids by world id, zone pids by coordinates, player
sessions, and the per-player and global world caps - but it registers
processes, it never moves them.</p>
<p>Horizontal scale therefore means more worlds, never a bigger one. If a single
world is the thing that is full, shard it in your game design - regions,
instances, shards. See <a href="/docs/clustering">Clustering</a>.</p>
<h2 id="inspecting-a-world" tabindex="-1">Inspecting a world</h2>
<p>The console has no worlds screen. Three things stand in for one:</p>
<pre><code class="language-bash"># Every listed world, with player counts and phase blocks. Player-facing, so
# it needs a player token, and unlisted modes never appear.
curl http://localhost:8084/api/v1/worlds -H 'Authorization: Bearer &lt;token&gt;'

# One world by id, including unlisted ones.
curl http://localhost:8084/api/v1/worlds/&lt;world_id&gt; -H 'Authorization: Bearer &lt;token&gt;'

# Node pressure: process count against the limit, run queue, memory, uptime.
curl -H 'Authorization: Bearer &lt;ops-secret&gt;' \
  http://localhost:8084/api/v1/ops/stats
</code></pre>
<p><code>/ops/stats</code> is the one to watch when zones are the concern: every zone is a
process, so a world grid and its idle-zone churn show up in <code>process_count</code> and
<code>run_queue</code> before they show up anywhere else. A stock node serves neither the
console nor the ops API - see <a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a> - lazy zones, terrain, and the zone ceiling.</li>
<li><a href="/docs/lua/api">Lua scripting</a> - the match-side scripting model.</li>
<li><a href="/docs/voting">Voting</a> - in-session voting.</li>
<li><a href="/docs/phases">Phases</a> - the phase clock and <code>world.phase_changed</code>.</li>
<li><a href="/docs/clustering">Clustering</a> - multi-node deployment.</li>
</ul>
"""}
    ]}.
