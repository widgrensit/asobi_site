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
        {h1, [], [~"Large Worlds"]},
        {raw,
            ~"""
<p>Scale the world server to handle massive tile-based maps with lazy zone
loading, terrain data serving, and configurable zone lifecycle management.</p>
<p>Everything here is game logic and config. It is written once and runs the same
whether you deploy to managed Cloud (<code>asobi deploy</code>, console.asobi.dev) or
self-host your own release of asobi + asobi_lua. The one exception - shipping a
custom terrain generator - is called out under <a href="#terrain-data">Terrain Data</a>.</p>
<h2 id="lazy-zone-loading" tabindex="-1">Lazy Zone Loading</h2>
<p>By default, all zones in a world are spawned at startup. For large worlds
(thousands of zones), enable lazy loading so zones are created on demand when a
player enters. The config keys are globals at the top of your world script.</p>
<div class="tabbed-code"><input type="radio" name="worlds-tab0" id="worlds-tab0-1" checked><input type="radio" name="worlds-tab0" id="worlds-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="worlds-tab0-1">Lua</label><label for="worlds-tab0-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">-- world.lua
game_type         = "world"
grid_size         = 2000
zone_size         = 64
lazy_zones        = true
zone_idle_timeout = 30000
max_active_zones  = 10000</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">Config = #{
    game_module =&gt; my_world,
    grid_size =&gt; 2000,
    zone_size =&gt; 64,
    lazy_zones =&gt; true,
    zone_idle_timeout =&gt; 30000,
    max_active_zones =&gt; 10000
}.</code></pre></div></div>
<p>With <code>lazy_zones</code> on:</p>
<ul>
<li>Zones are created when a player joins or moves into them.</li>
<li>Interest zones (adjacent to the player) only subscribe if already loaded.</li>
<li>Idle zones are snapshotted to the database and terminated after <code>zone_idle_timeout</code>.</li>
<li><code>max_active_zones</code> caps concurrent zone processes and prevents runaway memory.</li>
</ul>
<p><code>lazy_zones</code> auto-enables when <code>grid_size &gt; 100</code>. For small worlds
(<code>grid_size &lt;= 100</code>) all zones are pre-warmed at startup regardless of the
setting.</p>
<h2 id="zone-lifecycle" tabindex="-1">Zone Lifecycle</h2>
<p>Each zone follows this lifecycle:</p>
<pre><code>[not loaded] --ensure_zone--&gt; [active] --no subscribers--&gt; [idle]
     ^                                                        |
     |                    idle_timeout expires                 |
     +---&lt;---snapshot + terminate---&lt;---reap---&lt;--------------+
</code></pre>
<p>A zone with subscribers resets its idle timer each tick. When subscribers drop
to zero and the zone has no tickable entities, it enters BEAM hibernation to
reduce memory, then is snapshotted and reaped once <code>zone_idle_timeout</code> expires.</p>
<h2 id="terrain-data" tabindex="-1">Terrain Data</h2>
<p>Terrain is separate from entities. Tile chunks are served as compressed binary
blobs when a player subscribes to a zone, not through the tick/delta loop.</p>
<p>Asobi does not define what terrain is. A provider returns the bytes of the chunk
at a <code>{X, Y}</code> coordinate; Asobi caches that blob in the terrain store and ships
it to clients verbatim. The payload is whatever your provider produces. A
complete, runnable provider lives in
<a href="https://github.com/widgrensit/asobi/tree/main/examples/world-terrain"><code>examples/world-terrain</code></a>.</p>
<p>The split is: Lua selects a provider, Erlang implements one.</p>
<h3 id="selecting-a-provider" tabindex="-1">Selecting a Provider</h3>
<p>Your world script names its provider from <code>terrain_provider</code>, returning the
module name and its args as a keyed table.</p>
<div class="tabbed-code"><input type="radio" name="worlds-tab1" id="worlds-tab1-1" checked><input type="radio" name="worlds-tab1" id="worlds-tab1-2"><div class="tabbed-code-labels" role="tablist"><label for="worlds-tab1-1">Lua</label><label for="worlds-tab1-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">-- world.lua
function terrain_provider(config)
    return { module = "asobi_terrain_perlin", args = { seed = 42 } }
end</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">terrain_provider(Config) -&gt;
    {asobi_terrain_perlin, #{seed =&gt; maps:get(seed, Config, 42)}}.</code></pre></div></div>
<p>Return <code>nil</code> (Lua) or <code>none</code> (Erlang) for a world with no terrain.</p>
<p>Two providers ship built in: <code>asobi_terrain_flat</code> and <code>asobi_terrain_perlin</code>.
The name is checked against an allowlist rather than resolved as an arbitrary
module, so a script cannot name <code>gen_server</code> or any other loaded module. A name
that is not on the list is rejected with <code>terrain_provider_not_allowed</code>.</p>
<p><strong>Cloud:</strong> the two built-in providers are available with no configuration.</p>
<p><strong>Self-hosted:</strong> extend the allowlist to admit your own provider. This is an
<code>asobi_lua</code> key, set in sys.config - see
<a href="/docs/configuration#terrain-provider-allowlist">Terrain provider allowlist</a>:</p>
<pre><code class="language-erlang">{asobi_lua, [
    {terrain_providers, [asobi_terrain_flat, asobi_terrain_perlin, my_terrain]}
]}
</code></pre>
<p>A custom provider is a compiled Erlang module, so shipping one means running
your own release: it is a self-hosted feature. On managed Cloud, stick to the
built-ins.</p>
<h3 id="terrain-provider-behaviour-erlang" tabindex="-1">Terrain Provider Behaviour (Erlang)</h3>
<p>Implement <code>asobi_terrain_provider</code> to supply terrain data. This is Erlang only,
the same split as matchmaker strategies.</p>
<pre><code class="language-erlang">-module(my_terrain).
-behaviour(asobi_terrain_provider).
-export([init/1, load_chunk/2, generate_chunk/3]).

init(Config) -&gt;
    {ok, Config}.

load_chunk({X, Y}, State) -&gt;
    {error, not_found}.

generate_chunk({X, Y}, Seed, State) -&gt;
    Tiles = generate_tiles(X, Y, Seed),
    Bin = asobi_terrain:compress_chunk(asobi_terrain:encode_chunk(Tiles)),
    {ok, Bin, State}.
</code></pre>
<p><code>load_chunk/2</code> loads from file or database; returning <code>{error, not_found}</code> falls
back to <code>generate_chunk/3</code> for procedural generation.</p>
<p>When a player subscribes to a zone, they receive a <code>world.terrain</code> message with
the compressed chunk data (base64-encoded in JSON).</p>
<h3 id="terrain-encoding" tabindex="-1">Terrain Encoding</h3>
<p><code>asobi_terrain</code> encodes tiles as compact binaries:</p>
<ul>
<li>Default format: 4 bytes per tile (2B tile_id, 1B flags, 1B elevation).</li>
<li>64x64 chunk = 16KB raw, typically 2-4KB compressed.</li>
<li>Custom formats via the <code>format</code> parameter.</li>
</ul>
<pre><code class="language-erlang">Tiles = [{0, 0, 1, 0, 10}, {3, 5, 200, 15, 255}],
Bin = asobi_terrain:encode_chunk(Tiles),
Compressed = asobi_terrain:compress_chunk(Bin).
</code></pre>
<h3 id="terrain-store" tabindex="-1">Terrain Store</h3>
<p>The terrain store is an ETS-backed cache that lazy-loads chunks from the
provider. It starts automatically when the game returns a terrain provider.
Chunks are cached after first load.</p>
<h2 id="zone-lifecycle-callbacks" tabindex="-1">Zone Lifecycle Callbacks</h2>
<p>A world script can react to zones loading and unloading. Both callbacks are
optional.</p>
<div class="tabbed-code"><input type="radio" name="worlds-tab2" id="worlds-tab2-1" checked><input type="radio" name="worlds-tab2" id="worlds-tab2-2"><div class="tabbed-code-labels" role="tablist"><label for="worlds-tab2-1">Lua</label><label for="worlds-tab2-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">-- world.lua
function on_zone_loaded(cx, cy, state)
    local zone_state = { biome = "plains" }
    return zone_state, state
end

function on_zone_unloaded(cx, cy, state)
    return state
end</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">-callback terrain_provider(Config :: map()) -&gt;
    {Module :: module(), ProviderArgs :: map()} | none.

-callback on_zone_loaded(Coords :: {integer(), integer()}, GameState :: term()) -&gt;
    {ok, ZoneState :: map(), GameState1 :: term()}.

-callback on_zone_unloaded(Coords :: {integer(), integer()}, GameState :: term()) -&gt;
    {ok, GameState1 :: term()}.</code></pre></div></div>
<h2 id="configuration-reference" tabindex="-1">Configuration Reference</h2>
<table>
<thead>
<tr>
<th>Key</th>
<th>Default</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>grid_size</code></td>
<td><code>10</code></td>
<td>Zones per dimension</td>
</tr>
<tr>
<td><code>zone_size</code></td>
<td><code>200</code></td>
<td>World units per zone</td>
</tr>
<tr>
<td><code>lazy_zones</code></td>
<td><code>grid_size &gt; 100</code></td>
<td>Enable on-demand zone loading</td>
</tr>
<tr>
<td><code>zone_idle_timeout</code></td>
<td><code>30000</code></td>
<td>Milliseconds before idle zones are reaped</td>
</tr>
<tr>
<td><code>max_active_zones</code></td>
<td><code>10000</code></td>
<td>Maximum concurrent zone processes</td>
</tr>
</tbody>
</table>
<h2 id="scaling-guidelines" tabindex="-1">Scaling Guidelines</h2>
<p>Asobi is single-node by design. These figures are per node.</p>
<table>
<thead>
<tr>
<th>Map Size</th>
<th>Zones</th>
<th>Recommended Config</th>
</tr>
</thead>
<tbody>
<tr>
<td>Small (1K x 1K)</td>
<td>100</td>
<td>Default (eager loading)</td>
</tr>
<tr>
<td>Medium (10K x 10K)</td>
<td>10,000</td>
<td><code>lazy_zones = true</code></td>
</tr>
<tr>
<td>Large (128K x 128K)</td>
<td>4,000,000</td>
<td>Lazy + terrain provider + tuned idle timeout</td>
</tr>
</tbody>
</table>
<p>For large worlds, expect 200-500 concurrent zone processes per node with typical
player clustering. The BEAM handles this efficiently; the bottleneck is
serialisation and network I/O, not process count.</p>
<h2 id="checkpoint" tabindex="-1">Checkpoint</h2>
<ol>
<li>
<p>Set <code>game_type = &quot;world&quot;</code>, <code>grid_size = 2000</code> and <code>lazy_zones = true</code> in
<code>world.lua</code>, then start your world (Cloud: <code>asobi deploy</code>; self-hosted: your
release).</p>
</li>
<li>
<p>Connect a client and move into a zone. On the server, confirm only a handful
of zones are active, not four million:</p>
<pre><code>Active zones climb as players spread out, and idle zones vanish after
zone_idle_timeout - not all grid_size^2 zones at once.
</code></pre>
</li>
<li>
<p>If you named a <code>terrain_provider</code>, the subscribing client receives a
<code>world.terrain</code> message with a non-empty base64 chunk. An empty chunk or a
<code>terrain_provider_not_allowed</code> log means the name is not on the allowlist.</p>
</li>
</ol>
<h2 id="next" tabindex="-1">Next</h2>
<p><a href="/docs/performance">Performance Tuning</a> - spatial-grid indexing, adaptive
tick rates, and shared-state broadcast for busy zones.</p>
"""}
    ]}.
