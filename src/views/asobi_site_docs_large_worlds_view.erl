%% GENERATED from asobi guides/large-worlds.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_large_worlds_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-large-worlds", title => ~"Large worlds — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Large worlds"
        ]},
        {h1, [], [~"Large worlds"]},
        {raw,
            ~"""
<p>Running the world server over a big tile map: how zones come and go, and how
terrain is served.</p>
<p>Everything here is game logic and config. It is the same whether you run the
image and write Lua or depend on the Hex package and write Erlang. The one
exception, shipping a custom terrain generator, is called out under
<a href="#terrain-data">Terrain data</a>.</p>
<h2 id="zones-are-created-on-demand-above-grid_size-100" tabindex="-1">Zones are created on demand above grid_size 100</h2>
<p>A world with <code>grid_size &gt; 100</code> creates zones lazily, when a player joins or
moves into one. At or below 100 it pre-warms every zone at startup. That
threshold is the deployment's behaviour and there is no configuration key that
changes it.</p>
<p>Two more numbers are fixed the same way:</p>
<ul>
<li><strong>Zone idle: 30s.</strong> A zone becomes reap-eligible 30s after its last touch, or
immediately when its last occupant leaves. The sweep that acts on that runs
every 10s.</li>
<li><strong>Active zones: 10,000 per world.</strong> This is a hard ceiling, not a
recommendation. A world that needs more concurrent zones than that needs
bigger zones (<code>zone_size</code>) or a smaller grid.</li>
</ul>
<p>A mode script declares the map itself:</p>
<pre><code class="language-lua">-- lua/world.lua
game_type   = &quot;world&quot;
match_size  = 1
max_players = 200
grid_size   = 2000
zone_size   = 64
view_radius = 1
</code></pre>
<p><code>match_size</code> is required in every mode script, world modes included; the loader
rejects a script without it. A file named <code>world.lua</code> is only loaded when a
<code>config.lua</code> maps a mode name to it:</p>
<pre><code class="language-lua">-- lua/config.lua
return {
    frontier = &quot;world.lua&quot;,
}
</code></pre>
<p>A complete, runnable pair lives in
<a href="https://github.com/widgrensit/asobi/tree/main/examples/world-walkers"><code>examples/world-walkers</code></a>.</p>
<p>In Erlang the same keys are mode config, and the mode declares <code>module</code>:</p>
<pre><code class="language-erlang">{asobi, [
    {game_modes, #{
        ~&quot;frontier&quot; =&gt; #{
            type =&gt; world,
            module =&gt; my_world,
            grid_size =&gt; 2000,
            zone_size =&gt; 64
        }
    }}
]}.
</code></pre>
<p><code>game_module</code> is an internal key of the world server, derived from <code>module</code>.
Setting it in mode config does nothing.</p>
<h2 id="zone-lifecycle" tabindex="-1">Zone lifecycle</h2>
<pre><code>[not loaded] --ensure_zone--&gt; [active] --last occupant leaves--&gt; [idle]
     ^                                                             |
     |                    reap sweep (every 10s)                   |
     +---&lt;-------------- stop, if empty ------------&lt;--------------+
</code></pre>
<p>A zone with subscribers resets its idle timer each tick. When subscribers drop
to zero and the zone holds no NPCs, it hibernates to shrink its heap.</p>
<p>A reap is a proposal, not an order. A zone that still holds entities declines
it and re-touches its own timer; only an empty zone stops. A join or crossing
that finds its zone reaped between resolving the pid and placing the player
transparently starts a replacement zone and places them there.</p>
<p>Zone state is <strong>not</strong> snapshotted on the way out. Zone persistence exists in
the zone process but no configuration path reaches it, so entities in a
reaped zone are gone. Do not design a world that depends on a zone's contents
surviving the players leaving it - write anything durable to your own tables
from a callback.</p>
<p><code>persistent = true</code> in a mode's config does one reachable thing today: it keeps
an emptied world alive instead of finishing it.</p>
<h2 id="terrain-data" tabindex="-1">Terrain data</h2>
<p>Terrain is separate from entities. Tile chunks are served when a player
subscribes to a zone, not through the tick and delta loop.</p>
<p>asobi does not define what terrain is. A provider returns the bytes of the
chunk at a <code>{X, Y}</code> coordinate; asobi caches that blob in the terrain store and
ships it to clients verbatim, base64-encoded inside a JSON <code>world.terrain</code>
frame. The payload is whatever your provider produces. A complete, runnable
provider lives in
<a href="https://github.com/widgrensit/asobi/tree/main/examples/world-terrain"><code>examples/world-terrain</code></a>.</p>
<p>The split is: Lua selects a provider, Erlang implements one.</p>
<h3 id="selecting-a-provider" tabindex="-1">Selecting a provider</h3>
<p>Your world script names its provider from <code>terrain_provider</code>, returning the
module name and its arguments as a keyed table.</p>
<pre><code class="language-lua">function terrain_provider(config)
    return { module = &quot;asobi_terrain_perlin&quot;, args = { seed = 42 } }
end
</code></pre>
<p>In Erlang:</p>
<pre><code class="language-erlang">terrain_provider(Config) -&gt;
    {asobi_terrain_perlin, #{seed =&gt; maps:get(seed, Config, 42)}}.
</code></pre>
<p>Return <code>nil</code> (Lua) or <code>none</code> (Erlang) for a world with no terrain.</p>
<p>Two providers ship built in: <code>asobi_terrain_flat</code> and <code>asobi_terrain_perlin</code>.
The name is checked against an allowlist rather than resolved as an arbitrary
module, so a script cannot name <code>gen_server</code> or anything else that happens to
be loaded. A name that is not on the list logs a <code>terrain_provider_not_allowed</code>
warning and the world starts with <strong>no terrain store at all</strong> - clients receive
no <code>world.terrain</code> message, rather than an empty one.</p>
<p>To admit your own provider, extend the allowlist in <code>sys.config</code>:</p>
<pre><code class="language-erlang">{asobi, [
    {terrain_providers, [asobi_terrain_flat, asobi_terrain_perlin, my_terrain]}
]}
</code></pre>
<p>See <a href="/docs/configuration#terrain-provider-allowlist">Terrain provider allowlist</a>,
and <a href="/docs/configuration#which-application-key">Which application key</a> if you still
have an <code>{asobi_lua, [...]}</code> block.</p>
<p>A custom provider is a compiled Erlang module, so shipping one means building
your own release.</p>
<h3 id="terrain-provider-behaviour-erlang" tabindex="-1">Terrain provider behaviour (Erlang)</h3>
<p>Implement <code>asobi_terrain_provider</code>. There is no Lua path for this, the same
split as matchmaker strategies.</p>
<pre><code class="language-erlang">-module(my_terrain).
-behaviour(asobi_terrain_provider).
-export([init/1, load_chunk/2, generate_chunk/3]).

init(Config) -&gt;
    {ok, Config}.

load_chunk({_X, _Y}, _State) -&gt;
    {error, not_found}.

generate_chunk({X, Y}, Seed, State) -&gt;
    Tiles = generate_tiles(X, Y, Seed),
    Bin = asobi_terrain:compress_chunk(asobi_terrain:encode_chunk(Tiles)),
    {ok, Bin, State}.
</code></pre>
<p><code>load_chunk/2</code> loads from file or database; returning <code>{error, not_found}</code>
falls back to <code>generate_chunk/3</code> for procedural generation.</p>
<h3 id="terrain-encoding" tabindex="-1">Terrain encoding</h3>
<p><code>asobi_terrain</code> encodes tiles as compact binaries:</p>
<ul>
<li>Default format: 4 bytes per tile (2B tile_id, 1B flags, 1B elevation), 64x64
tiles per chunk.</li>
<li>A 64x64 chunk is 16KB raw, typically 2-4KB compressed.</li>
<li>Other tile sizes and chunk dimensions via <code>encode_chunk/2</code>.</li>
</ul>
<p>A tile is <code>{X, Y, TileId, Flags, Elevation}</code>:</p>
<pre><code class="language-erlang">Tiles = [{0, 0, 1, 0, 10}, {3, 5, 200, 15, 255}],
Bin = asobi_terrain:encode_chunk(Tiles),
Compressed = asobi_terrain:compress_chunk(Bin).
</code></pre>
<h3 id="terrain-store" tabindex="-1">Terrain store</h3>
<p>The terrain store is an ETS-backed cache that lazy-loads chunks from the
provider. It starts automatically when the game returns a terrain provider, and
caches each chunk after first load. It is per node, like every other cache -
see <a href="/docs/clustering#what-is-per-node">Clustering</a>.</p>
<h2 id="zone-lifecycle-callbacks" tabindex="-1">Zone lifecycle callbacks</h2>
<p>A world script can react to zones loading and unloading. Both callbacks are
optional.</p>
<pre><code class="language-lua">function on_zone_loaded(cx, cy, state)
    local zone_state = { biome = &quot;plains&quot; }
    return zone_state, state
end

function on_zone_unloaded(cx, cy, state)
    return state
end
</code></pre>
<p>In Erlang:</p>
<pre><code class="language-erlang">-callback terrain_provider(Config :: map()) -&gt;
    {Module :: module(), ProviderArgs :: map()} | none.

-callback on_zone_loaded(Coords :: {integer(), integer()}, GameState :: term()) -&gt;
    {ok, ZoneState :: map(), GameState1 :: term()}.

-callback on_zone_unloaded(Coords :: {integer(), integer()}, GameState :: term()) -&gt;
    {ok, GameState1 :: term()}.
</code></pre>
<h2 id="configuration-reference" tabindex="-1">Configuration reference</h2>
<table>
<thead>
<tr>
<th>Key</th>
<th>Default</th>
<th>What it does</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>grid_size</code></td>
<td><code>10</code></td>
<td>Zones per dimension. Above 100, zones load on demand.</td>
</tr>
<tr>
<td><code>zone_size</code></td>
<td><code>200</code></td>
<td>World units per zone.</td>
</tr>
<tr>
<td><code>view_radius</code></td>
<td><code>1</code></td>
<td>Zone radius a player subscribes to. 0 means own zone only.</td>
</tr>
<tr>
<td><code>tick_rate</code></td>
<td><code>50</code></td>
<td>Milliseconds per world tick.</td>
</tr>
<tr>
<td><code>max_players</code></td>
<td><code>500</code>, but <code>match_size</code> in a Lua script</td>
<td>Players per world.</td>
</tr>
<tr>
<td><code>persistent</code></td>
<td><code>false</code></td>
<td>Keep an emptied world alive instead of finishing it.</td>
</tr>
</tbody>
</table>
<h2 id="scaling-guidelines" tabindex="-1">Scaling guidelines</h2>
<p>One world lives entirely on one node, so these are per world and per node. More
nodes means more worlds, not a bigger world - see
<a href="/docs/clustering#the-scaling-unit-is-a-world-not-a-node">Clustering</a>.</p>
<p>A world can hold at most 10,000 active zones at once. Grids above roughly
100x100 only work because most of the map is unloaded most of the time: with
typical player clustering, expect a few hundred live zone processes. If your
players do not cluster, the ceiling is what you will hit, and the fix is a
larger <code>zone_size</code>.</p>
<p>The bottleneck at that scale is serialisation and network I/O, not process
count. The BEAM is comfortable with thousands of zone processes; the tick that
encodes deltas for all of them is what runs out of time first.</p>
<h2 id="checkpoint" tabindex="-1">Checkpoint</h2>
<ol>
<li>Put a <code>config.lua</code> mapping a mode to <code>world.lua</code>, with <code>game_type = &quot;world&quot;</code>,
<code>match_size = 1</code> and <code>grid_size = 2000</code>, then start your world.</li>
<li>Connect a client and move into a zone. Only a handful of zones should be
active, not four million: active zones climb as players spread out and fall
again as they leave, and no zone is created until somebody enters it.</li>
<li>If you named a <code>terrain_provider</code>, the subscribing client receives a
<code>world.terrain</code> message with a non-empty base64 chunk. No <code>world.terrain</code>
message at all, plus a <code>terrain_provider_not_allowed</code> warning in the log,
means the name is not on the allowlist.</li>
</ol>
<h2 id="next" tabindex="-1">Next</h2>
<p><a href="/docs/performance">Performance tuning</a> - spatial queries, shared-state
broadcast, and what the zone tick costs.</p>
"""}
    ]}.
