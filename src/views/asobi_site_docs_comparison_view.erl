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
<p>How asobi compares to other game backend platforms.</p>
<p>asobi is one Erlang/OTP node containing the game backend, the Lua runtime and
the operator console. There are two front doors into it: run the image
(<code>ghcr.io/widgrensit/asobi</code>) and write Lua, or depend on the Hex package and
write Erlang. Same node, same features, different surface.</p>
<p>The asobi column is checked against this repository. The other columns are
summarised from each vendor's own public documentation
(<a href="https://heroiclabs.com/docs/nakama/">Nakama</a>,
<a href="https://docs.colyseus.io/">Colyseus</a>,
<a href="https://learn.microsoft.com/en-us/gaming/playfab/">PlayFab</a>) and were last
read on 2026-08-06. Check them against the vendor before you make a decision
on one.</p>
<h2 id="feature-matrix" tabindex="-1">Feature matrix</h2>
<table>
<thead>
<tr>
<th>Feature</th>
<th style="text-align:center">asobi</th>
<th style="text-align:center">Nakama</th>
<th style="text-align:center">Colyseus</th>
<th style="text-align:center">PlayFab</th>
</tr>
</thead>
<tbody>
<tr>
<td>Runtime</td>
<td style="text-align:center">BEAM (Erlang/OTP)</td>
<td style="text-align:center">Go</td>
<td style="text-align:center">Node.js</td>
<td style="text-align:center">Cloud</td>
</tr>
<tr>
<td>Authentication</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Plugin</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td>Anonymous / guest auth</td>
<td style="text-align:center">Built-in, upgradeable, opt-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td>Player management</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td>Real-time multiplayer</td>
<td style="text-align:center">WebSocket</td>
<td style="text-align:center">WebSocket</td>
<td style="text-align:center">WebSocket</td>
<td style="text-align:center">WebSocket</td>
</tr>
<tr>
<td>Server-authoritative game loop</td>
<td style="text-align:center">Built-in, tick-based</td>
<td style="text-align:center">Lua / Go / TS runtime</td>
<td style="text-align:center">Room-based</td>
<td style="text-align:center">CloudScript</td>
</tr>
<tr>
<td>Matchmaking</td>
<td style="text-align:center">Modes plus pluggable strategies</td>
<td style="text-align:center">Query-based</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td>Leaderboards</td>
<td style="text-align:center">ETS reads, PostgreSQL persistence</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td>Virtual economy</td>
<td style="text-align:center">Wallets, store, inventory</td>
<td style="text-align:center">IAP validation</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td>Friends / groups</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td>Chat</td>
<td style="text-align:center">Built-in, channels plus DMs</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Manual</td>
</tr>
<tr>
<td>Tournaments</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Manual</td>
</tr>
<tr>
<td>Cloud saves</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Storage API</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td>Notifications</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Built-in</td>
</tr>
<tr>
<td>Background jobs</td>
<td style="text-align:center">Shigoto, built-in</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Manual</td>
<td style="text-align:center">Scheduled tasks</td>
</tr>
<tr>
<td>Custom server-side logic</td>
<td style="text-align:center">Lua callbacks plus extension RPC</td>
<td style="text-align:center">Runtime modules and RPCs</td>
<td style="text-align:center">Room handlers</td>
<td style="text-align:center">CloudScript</td>
</tr>
<tr>
<td>Operator console</td>
<td style="text-align:center">Built-in, read-only</td>
<td style="text-align:center">Nakama Console, mutating</td>
<td style="text-align:center">Monitor</td>
<td style="text-align:center">Game Manager</td>
</tr>
<tr>
<td>Database</td>
<td style="text-align:center">PostgreSQL, Kura ORM</td>
<td style="text-align:center">PostgreSQL or CockroachDB</td>
<td style="text-align:center">MongoDB / custom</td>
<td style="text-align:center">Managed</td>
</tr>
<tr>
<td>Self-hosted</td>
<td style="text-align:center">Yes</td>
<td style="text-align:center">Yes</td>
<td style="text-align:center">Yes</td>
<td style="text-align:center">No</td>
</tr>
</tbody>
</table>
<p>Two rows are worth reading twice.</p>
<p>The console is a React SPA served from <code>priv/console</code> by the same node that
serves the game. Core's ops routes are reads apart from erasing and exporting
one player; the third mutating route is <code>/api/v1/ops/ext/:extension/:action</code>,
whose behaviour comes from an installed extension. So there is no ban, kick,
grant, refund or match-end button. Nakama Console and PlayFab Game Manager both
mutate; if you are moving from one of those, that is a real gap. See
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<p>Custom server-side logic that is not per-match goes over the WebSocket as
<code>rpc.call</code> with <code>{protocol: 1, method, params}</code>, answered by <code>rpc.ok</code> or
<code>rpc.error</code> and correlated by <code>cid</code>. All seven client SDKs speak it. That is
the replacement for a Nakama RPC, a PlayFab CloudScript function and a Hathora
custom message. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</p>
<h2 id="runtime-characteristics" tabindex="-1">Runtime characteristics</h2>
<table>
<thead>
<tr>
<th>Concern</th>
<th>asobi (BEAM)</th>
<th>Nakama (Go)</th>
<th>Colyseus (Node.js)</th>
</tr>
</thead>
<tbody>
<tr>
<td>Garbage collection</td>
<td>Per-process, isolated per match</td>
<td>Stop-the-world</td>
<td>Stop-the-world</td>
</tr>
<tr>
<td>Fault tolerance</td>
<td>OTP supervision, crashed matches restart</td>
<td>Panic recovery, manual</td>
<td>Process crash, manual</td>
</tr>
<tr>
<td>Live game-logic reload</td>
<td>Lua re-evaluated in place on the next tick</td>
<td>Restart required</td>
<td>Restart required</td>
</tr>
<tr>
<td>Pub/sub</td>
<td><code>pg</code>, cluster-native</td>
<td>Built-in plus optional Redis</td>
<td>Built-in, single node</td>
</tr>
<tr>
<td>In-memory state</td>
<td>ETS and process heaps</td>
<td>In-process maps</td>
<td>In-process objects</td>
</tr>
<tr>
<td>Clustering</td>
<td>Distributed Erlang, built in</td>
<td>etcd / Consul</td>
<td>Redis, presence only</td>
</tr>
<tr>
<td>Scheduling</td>
<td>Pre-emptive, fair across all processes</td>
<td>Cooperative goroutines</td>
<td>Single-threaded event loop</td>
</tr>
</tbody>
</table>
<p>Live reload is a Lua mechanism, not an OTP release upgrade: the runtime stats
the script file each tick, and a changed mtime re-executes the script body
against the running Luerl state, re-declaring globals and functions while
in-flight game state survives. It needs the game directory to be a live mount.
asobi ships no <code>appup</code> or <code>relup</code>, so upgrading the node itself is a restart.</p>
<p>Connection density on a single node is <strong>3,000-7,000 concurrent WebSocket
connections</strong> measured on 8 cores, at 4.4ms p50 round-trip with 3,500
connections. Each connection costs ~13-20KB, so at that concurrency the ceiling
is CPU spent on message processing, not memory. Figures and method are in
<a href="https://hexdocs.pm/asobi/benchmarks.html">Benchmarks</a>.</p>
<h2 id="when-to-choose-asobi" tabindex="-1">When to choose asobi</h2>
<ul>
<li>You want a single deployable with auth, matchmaking, economy, social and
real-time multiplayer.</li>
<li>You need fault-tolerant game sessions that survive crashes without losing
state.</li>
<li>You want hot-reloadable Lua so bug fixes ship without kicking players.</li>
<li>You are building for many simultaneous matches or worlds.</li>
<li>You prefer self-hosted Apache-2.0 over a closed managed cloud, with a real
exit runbook (see <a href="https://hexdocs.pm/asobi/exit.html">Exit guarantee</a>).</li>
<li>You want a PostgreSQL-backed system with a proper ORM.</li>
</ul>
<h2 id="when-to-choose-something-else" tabindex="-1">When to choose something else</h2>
<ul>
<li>You need sub-3ms UDP latency for a twitch FPS, fighting game or racer. Pair
asobi with a UDP relay, or use a physics-first product for the simulation.</li>
<li>You need deep LiveOps tooling (A/B testing, segmentation, push campaigns)
today.</li>
<li>You need a fully managed cloud at hyperscaler breadth. asobi's managed
version is <a href="https://asobi.dev/cloud">asobi.dev/cloud</a>, which is the same
open-source core rather than a different product - invite-only today, and
narrower than self-hosting in ways <a href="https://hexdocs.pm/asobi/cloud.html">Cloud</a> lists.</li>
<li>You are building a single-player game that only needs analytics and IAP.
Analytics plus a store validator is cheaper than any backend here.</li>
</ul>
<h2 id="clustering" tabindex="-1">Clustering</h2>
<p>Multiple nodes share Postgres and <code>pg</code>-scoped presence, chat and process
lookups. Three things stay node-local and change how you deploy: the matchmaker
queue, the rate-limit buckets and the console session store, so the console
needs a sticky route and players queuing against different nodes never match
each other. <a href="/docs/clustering">Clustering</a> has the full list.</p>
<h2 id="client-sdks" tabindex="-1">Client SDKs</h2>
<p>Seven first-class SDKs: <a href="https://github.com/widgrensit/asobi-godot">Godot</a>,
<a href="https://github.com/widgrensit/asobi-defold">Defold</a>,
<a href="https://github.com/widgrensit/asobi-love2d">LÖVE</a>,
<a href="https://github.com/widgrensit/asobi-unity">Unity</a>,
<a href="https://github.com/widgrensit/asobi-unreal">Unreal</a>,
<a href="https://github.com/widgrensit/asobi-js">JavaScript/TypeScript</a> and
<a href="https://github.com/widgrensit/asobi-dart">Dart/Flutter</a>.
<a href="https://github.com/widgrensit/flame_asobi">flame_asobi</a> is a Flame bridge on
top of the Dart SDK rather than an eighth protocol implementation. The table
with guides and demos is in the <a href="../README.md#client-sdks">README</a>.</p>
<h2 id="migrating-from-another-backend" tabindex="-1">Migrating from another backend</h2>
<ul>
<li><a href="https://hexdocs.pm/asobi/migrate-from-hathora.html">From Hathora</a> - shutdown 2026-05-05</li>
<li><a href="https://hexdocs.pm/asobi/migrate-from-playfab.html">From PlayFab</a></li>
<li><a href="https://hexdocs.pm/asobi/migrate-from-nakama.html">From Nakama self-host</a></li>
</ul>
"""}
    ]}.
