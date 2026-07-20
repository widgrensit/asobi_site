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
<h2 id="lazy-zone-loading" tabindex="-1">Lazy Zone Loading</h2>
<p>By default, all zones in a world are spawned at startup. For large worlds
(thousands of zones), enable lazy loading so zones are created on demand
when a player enters.</p>
<div class="tabbed-code"><input type="radio" name="worlds-tab0" id="worlds-tab0-1" checked><input type="radio" name="worlds-tab0" id="worlds-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="worlds-tab0-1">Lua</label><label for="worlds-tab0-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">-- world.lua
game_type         = "world"
grid_size         = 2000       -- 2000x2000 zone grid
zone_size         = 64         -- 64 tiles per zone
lazy_zones        = true       -- auto-true when grid_size &gt; 100
zone_idle_timeout = 30000      -- reap idle zones after 30s
max_active_zones  = 10000      -- cap concurrent zone processes</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">Config = #{
    game_module =&gt; my_world,
    grid_size =&gt; 2000,          %% 2000x2000 zone grid
    zone_size =&gt; 64,            %% 64 tiles per zone
    lazy_zones =&gt; true,         %% auto-true when grid_size &gt; 100
    zone_idle_timeout =&gt; 30000, %% reap idle zones after 30s
    max_active_zones =&gt; 10000   %% cap concurrent zone processes
}.</code></pre></div></div>
<p>With <code>lazy_zones =&gt; true</code>:</p>
<ul>
<li>Zones are created when a player joins or moves into them</li>
<li>Interest zones (adjacent to the player) only subscribe if already loaded</li>
<li>Idle zones are snapshotted to the database and terminated after <code>zone_idle_timeout</code></li>
<li>The <code>max_active_zones</code> cap prevents runaway memory usage</li>
</ul>
<p>For small worlds (<code>grid_size =&lt; 100</code>), all zones are pre-warmed at startup
regardless of the <code>lazy_zones</code> setting.</p>
<h2 id="zone-lifecycle" tabindex="-1">Zone Lifecycle</h2>
<p>Each zone follows this lifecycle:</p>
<pre><code>[not loaded] --ensure_zone--&gt; [active] --no subscribers--&gt; [idle]
     ^                                                        |
     |                    idle_timeout expires                 |
     +---&lt;---snapshot + terminate---&lt;---reap---&lt;--------------+
</code></pre>
<p>Active zones call <code>touch_zone</code> each tick when they have subscribers,
resetting the idle timer. When subscribers drop to zero and the zone has
no tickable entities, it enters Erlang hibernation to reduce memory.</p>
<h2 id="terrain-data" tabindex="-1">Terrain Data</h2>
<p>Terrain is separate from entities. Tile chunks are served as compressed
binary blobs when a player subscribes to a zone -- not through the
tick/delta loop.</p>
<p>Asobi does not define what terrain is. You implement a provider that returns
the bytes of the chunk at a <code>{X, Y}</code> coordinate; Asobi caches that blob in
the terrain store and ships it to clients verbatim. The payload is whatever
your provider produces -- &quot;the data Asobi chunks&quot; is the data you hand back.
The <code>asobi_terrain</code> helpers below give you a compact tile format, but any
binary your client can decode works. A complete, runnable provider lives in
<a href="https://github.com/widgrensit/asobi/tree/main/examples/world-terrain"><code>examples/world-terrain</code></a>.</p>
<h3 id="selecting-a-provider-lua" tabindex="-1">Selecting a Provider (Lua)</h3>
<p>A Lua world names its provider from <code>terrain_provider</code>, returning the module
and its args:</p>
<pre><code class="language-lua">-- world.lua
function terrain_provider(config)
	return {&quot;asobi_terrain_perlin&quot;, {seed = 42}}
end
</code></pre>
<p>Two providers ship built in: <code>asobi_terrain_flat</code> and
<code>asobi_terrain_perlin</code>. The name is checked against an allowlist rather than
resolved as an arbitrary module, so a script cannot name <code>gen_server</code> or any
other loaded module. Operators extend the allowlist via env.</p>
<p><strong>Writing a new provider is Erlang only</strong> - the same split as matchmaker
strategies. Lua selects; Erlang implements.</p>
<h3 id="terrain-provider-behaviour-erlang" tabindex="-1">Terrain Provider Behaviour (Erlang)</h3>
<p>Implement <code>asobi_terrain_provider</code> to supply terrain data:</p>
<pre><code class="language-erlang">-module(my_terrain).
-behaviour(asobi_terrain_provider).
-export([init/1, load_chunk/2, generate_chunk/3]).

init(Config) -&gt;
    {ok, Config}.

load_chunk({X, Y}, State) -&gt;
    %% Load from file, database, etc.
    {error, not_found}.  %% Falls back to generate_chunk/3

generate_chunk({X, Y}, Seed, State) -&gt;
    %% Procedural generation
    Tiles = generate_tiles(X, Y, Seed),
    Bin = asobi_terrain:compress_chunk(
        asobi_terrain:encode_chunk(Tiles)
    ),
    {ok, Bin, State}.
</code></pre>
<h3 id="connecting-to-the-world" tabindex="-1">Connecting to the World</h3>
<p>Add <code>terrain_provider/1</code> to your world game module:</p>
<pre><code class="language-erlang">-module(my_world).
-behaviour(asobi_world).

terrain_provider(Config) -&gt;
    {my_terrain, #{seed =&gt; maps:get(seed, Config, 42)}}.
</code></pre>
<p>When a player subscribes to a zone, they receive a <code>world.terrain</code> message
with the compressed chunk data (base64-encoded in JSON).</p>
<h3 id="terrain-encoding" tabindex="-1">Terrain Encoding</h3>
<p><code>asobi_terrain</code> encodes tiles as compact binaries:</p>
<ul>
<li>Default format: 4 bytes per tile (2B tile_id, 1B flags, 1B elevation)</li>
<li>64x64 chunk = 16KB raw, typically 2-4KB compressed</li>
<li>Custom formats via the <code>format</code> parameter</li>
</ul>
<pre><code class="language-erlang">Tiles = [{0, 0, 1, 0, 10}, {3, 5, 200, 15, 255}],
Bin = asobi_terrain:encode_chunk(Tiles),
Compressed = asobi_terrain:compress_chunk(Bin),
%% Compressed is typically 75-85% smaller
</code></pre>
<h3 id="terrain-store" tabindex="-1">Terrain Store</h3>
<p>The terrain store is an ETS-backed cache that lazy-loads chunks from the
provider. It is started automatically when the game module returns a
terrain provider. Chunks are cached after first load.</p>
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
</tbody>
</table>
<h2 id="new-behaviour-callbacks" tabindex="-1">New Behaviour Callbacks</h2>
<p>These optional callbacks are available on <code>asobi_world</code>:</p>
<pre><code class="language-erlang">-callback terrain_provider(Config :: map()) -&gt;
    {Module :: module(), ProviderArgs :: map()} | none.

-callback on_zone_loaded(Coords :: {integer(), integer()}, GameState :: term()) -&gt;
    {ok, ZoneState :: map(), GameState1 :: term()}.

-callback on_zone_unloaded(Coords :: {integer(), integer()}, GameState :: term()) -&gt;
    {ok, GameState1 :: term()}.
</code></pre>
<h2 id="scaling-guidelines" tabindex="-1">Scaling Guidelines</h2>
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
<td><code>lazy_zones =&gt; true</code></td>
</tr>
<tr>
<td>Large (128K x 128K)</td>
<td>4,000,000</td>
<td>Lazy + terrain provider + tuned idle timeout</td>
</tr>
</tbody>
</table>
<p>For large worlds, expect 200-500 concurrent zone processes per node with
typical player clustering. The BEAM handles this efficiently -- the
bottleneck is serialisation and network I/O, not process count.</p>
"""}
    ]}.
