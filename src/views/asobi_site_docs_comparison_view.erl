%% GENERATED from asobi guides/comparison.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_comparison_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-comparison", title => ~"How Asobi compares — Asobi docs"}, Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Comparison"
        ]},
        {h1, [], [~"Comparison"]},
        {raw,
            ~"""
<p>How Asobi compares to other open-source game backend platforms.</p>
<h2 id="feature-matrix" tabindex="-1">Feature Matrix</h2>
<table>
<thead>
<tr>
<th>Feature</th>
<th style="text-align:center">Asobi</th>
<th style="text-align:center">Nakama</th>
<th style="text-align:center">Colyseus</th>
<th style="text-align:center">PlayFab</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Runtime</strong></td>
<td style="text-align:center">BEAM (Erlang/OTP)</td>
<td style="text-align:center">Go</td>
<td style="text-align:center">Node.js</td>
<td style="text-align:center">Cloud</td>
</tr>
<tr>
<td><strong>Authentication</strong></td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Plugin</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td><strong>Anonymous / Guest Auth</strong></td>
<td style="text-align:center">Built-in (upgradeable)</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td><strong>Player Management</strong></td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td><strong>Real-Time Multiplayer</strong></td>
<td style="text-align:center">WebSocket</td>
<td style="text-align:center">WebSocket</td>
<td style="text-align:center">WebSocket</td>
<td style="text-align:center">WebSocket</td>
</tr>
<tr>
<td><strong>Server-Authoritative Game Loop</strong></td>
<td style="text-align:center">Built-in (tick-based)</td>
<td style="text-align:center">Lua scripting</td>
<td style="text-align:center">Room-based</td>
<td style="text-align:center">CloudScript</td>
</tr>
<tr>
<td><strong>Matchmaking</strong></td>
<td style="text-align:center">Query-based</td>
<td style="text-align:center">Query-based</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td><strong>Leaderboards</strong></td>
<td style="text-align:center">ETS + PostgreSQL</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td><strong>Virtual Economy</strong></td>
<td style="text-align:center">Wallets, store, inventory</td>
<td style="text-align:center">IAP validation</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td><strong>Friends / Groups</strong></td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td><strong>Chat</strong></td>
<td style="text-align:center">Built-in (channels)</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Manual</td>
</tr>
<tr>
<td><strong>Tournaments</strong></td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Manual</td>
</tr>
<tr>
<td><strong>Cloud Saves</strong></td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Storage API</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td><strong>Notifications</strong></td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td><strong>Background Jobs</strong></td>
<td style="text-align:center">Shigoto (built-in)</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Scheduled tasks</td>
</tr>
<tr>
<td><strong>Admin Dashboard</strong></td>
<td style="text-align:center">Arizona LiveView</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Monitor</td>
<td style="text-align:center">Portal</td>
</tr>
<tr>
<td><strong>Database</strong></td>
<td style="text-align:center">PostgreSQL (Kura ORM)</td>
<td style="text-align:center">CockroachDB</td>
<td style="text-align:center">MongoDB / custom</td>
<td style="text-align:center">Managed</td>
</tr>
<tr>
<td><strong>Self-Hosted</strong></td>
<td style="text-align:center">Yes</td>
<td style="text-align:center">Yes</td>
<td style="text-align:center">Yes</td>
<td style="text-align:center">No</td>
</tr>
</tbody>
</table>
<h2 id="runtime-characteristics" tabindex="-1">Runtime Characteristics</h2>
<table>
<thead>
<tr>
<th>Concern</th>
<th>Asobi (BEAM)</th>
<th>Nakama (Go)</th>
<th>Colyseus (Node.js)</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Garbage Collection</strong></td>
<td>Per-process -- isolated per match</td>
<td>Stop-the-world -- affects all matches</td>
<td>Stop-the-world -- affects all rooms</td>
</tr>
<tr>
<td><strong>Fault Tolerance</strong></td>
<td>OTP supervision -- crashed matches restart</td>
<td>Panic recovery -- manual</td>
<td>Process crash -- manual</td>
</tr>
<tr>
<td><strong>Hot Code Upgrade</strong></td>
<td>Native -- zero-downtime deploys</td>
<td>Restart required</td>
<td>Restart required</td>
</tr>
<tr>
<td><strong>Pub/Sub</strong></td>
<td><code>pg</code> module -- cluster-native</td>
<td>Built-in + optional Redis</td>
<td>Built-in (single node)</td>
</tr>
<tr>
<td><strong>In-Memory State</strong></td>
<td>ETS -- zero serialization</td>
<td>In-process maps</td>
<td>In-process objects</td>
</tr>
<tr>
<td><strong>Clustering</strong></td>
<td>Distributed Erlang -- built in</td>
<td>etcd / Consul</td>
<td>Redis (presence only)</td>
</tr>
<tr>
<td><strong>Scheduling</strong></td>
<td>Preemptive -- fair across all processes</td>
<td>Cooperative goroutines</td>
<td>Single-threaded event loop</td>
</tr>
<tr>
<td><strong>Connection Density</strong></td>
<td>~500K+ per node</td>
<td>~100K per node</td>
<td>~10K per node</td>
</tr>
</tbody>
</table>
<h2 id="when-to-choose-asobi" tabindex="-1">When to Choose Asobi</h2>
<ul>
<li>You want a <strong>single deployable</strong> with auth, matchmaking, economy, social, and real-time multiplayer</li>
<li>You need <strong>fault-tolerant game sessions</strong> that survive crashes without losing state</li>
<li>You want <strong>hot-reloadable Lua</strong> so bug-fixes ship without kicking players</li>
<li>You want <strong>zero-downtime deploys</strong> for game logic updates</li>
<li>You're building for <strong>high concurrency</strong> (many simultaneous matches/rooms)</li>
<li>You prefer <strong>self-hosted Apache-2</strong> over closed managed clouds, with a real exit guarantee (see <a href="https://hexdocs.pm/asobi/exit.html">exit.md</a>)</li>
<li>You want a <strong>PostgreSQL-backed</strong> system with a proper ORM</li>
</ul>
<h2 id="dont-know-erlang" tabindex="-1">Don't know Erlang?</h2>
<p>You don't need to. Use <a href="https://github.com/widgrensit/asobi_lua"><strong>asobi_lua</strong></a> — the
same engine packaged as a Docker image with Lua scripting. Write your match
logic in a <code>.lua</code> file, <code>docker compose up</code>, you're running. The Erlang is
underneath but you never touch it.</p>
<p>The Erlang-library path (depending on <code>asobi</code> directly via rebar.config) is
for teams that already write OTP and want to compose asobi with the rest of
their release.</p>
<h2 id="when-to-choose-something-else" tabindex="-1">When to Choose Something Else</h2>
<ul>
<li>You need <strong>sub-3ms UDP latency</strong> for a twitch FPS / fighting game / racer. Pair asobi with a UDP relay, or use Photon Fusion / Quantum for the physics.</li>
<li>You need <strong>deep LiveOps tooling</strong> (A/B testing, segmentation, push campaigns) today. PlayFab still leads here, though it's an operational/trust trade-off post-v2 migration.</li>
<li>You need a <strong>fully managed cloud</strong> and are willing to pay cloud-scale prices. Our managed tier opens later in 2026; until then, self-host.</li>
<li>You're building a <strong>single-player</strong> game that only needs analytics and IAP. Firebase Analytics + a simple store validator is cheaper than any backend here.</li>
</ul>
<h2 id="client-sdks" tabindex="-1">Client SDKs</h2>
<p>First-class SDKs for <strong>Godot, Defold, Unity, Unreal, JavaScript/TypeScript, Dart/Flutter, Flame</strong>
— see the <a href="https://github.com/widgrensit/asobi_lua#client-sdks">asobi_lua README</a> for the table.</p>
<h2 id="migrating-from-another-backend" tabindex="-1">Migrating from another backend?</h2>
<ul>
<li><a href="https://hexdocs.pm/asobi/migrate-from-hathora.html"><strong>from Hathora</strong></a> — shutdown 2026-05-05</li>
<li><a href="https://hexdocs.pm/asobi/migrate-from-playfab.html"><strong>from PlayFab</strong></a></li>
<li><a href="https://hexdocs.pm/asobi/migrate-from-nakama.html"><strong>from Nakama self-host</strong></a></li>
</ul>
"""}
    ]}.
