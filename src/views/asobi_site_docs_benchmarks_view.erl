%% GENERATED from asobi guides/benchmarks.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_benchmarks_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-benchmarks", title => ~"Benchmarks — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Benchmarks"
        ]},
        {h1, [], [~"Benchmarks"]},
        {raw,
            ~"""
<p>Performance measurements for Asobi on a single node. All tests run client and
server on the same machine (8 cores, shared schedulers), so real-world
deployments with separate client machines will see higher server throughput.</p>
<h2 id="test-environment" tabindex="-1">Test environment</h2>
<ul>
<li><strong>CPU</strong>: 8 cores</li>
<li><strong>OTP</strong>: 28</li>
<li><strong>PostgreSQL</strong>: 17 (Docker, max_connections=500, shared_buffers=256MB)</li>
<li><strong>DB pool</strong>: 200 connections</li>
<li><strong>Single Erlang node</strong>, no clustering</li>
</ul>
<h2 id="websocket-throughput" tabindex="-1">WebSocket throughput</h2>
<p>Heartbeat round-trip: client sends <code>session.heartbeat</code>, server replies with
timestamp. Measures the full WebSocket pipeline including JSON encode/decode.</p>
<table>
<thead>
<tr>
<th>Connections</th>
<th>Messages</th>
<th>Throughput</th>
<th>RTT p50</th>
<th>RTT p99</th>
<th>Memory/conn</th>
</tr>
</thead>
<tbody>
<tr>
<td>100</td>
<td>10,000</td>
<td>35,000 msg/sec</td>
<td>1.4ms</td>
<td>5.1ms</td>
<td>~20KB</td>
</tr>
<tr>
<td>3,500</td>
<td>7,000,000</td>
<td>83,000 msg/sec</td>
<td>4.4ms</td>
<td>6.5ms</td>
<td>~15KB</td>
</tr>
<tr>
<td>7,000</td>
<td>695,800</td>
<td>39,000 msg/sec</td>
<td>5.8ms</td>
<td>19.9ms</td>
<td>~13KB</td>
</tr>
</tbody>
</table>
<p><strong>Peak sustained</strong>: ~83,000 messages/sec with 3,500 concurrent connections.</p>
<p>At 7,000 connections the per-message throughput drops because the benchmark
client competes with the server for CPU on the same machine.</p>
<h3 id="blast-mode" tabindex="-1">Blast mode</h3>
<p>Fire-and-forget: all messages sent before waiting for replies. Measures raw
server processing capacity.</p>
<table>
<thead>
<tr>
<th>Connections</th>
<th>Messages each</th>
<th>Total delivered</th>
<th>Throughput</th>
</tr>
</thead>
<tbody>
<tr>
<td>3,500</td>
<td>2,000</td>
<td>7,044,000</td>
<td>83,000 msg/sec</td>
</tr>
</tbody>
</table>
<p>All messages delivered with zero loss.</p>
<h2 id="http-rest-api" tabindex="-1">HTTP REST API</h2>
<p>100 concurrent players, each running the full lifecycle: register, login, then
API reads.</p>
<table>
<thead>
<tr>
<th>Endpoint</th>
<th>p50</th>
<th>p95</th>
<th>p99</th>
</tr>
</thead>
<tbody>
<tr>
<td>POST /auth/register</td>
<td>1,463ms</td>
<td>1,464ms</td>
<td>1,464ms</td>
</tr>
<tr>
<td>POST /auth/login</td>
<td>724ms</td>
<td>1,278ms</td>
<td>1,308ms</td>
</tr>
<tr>
<td>GET /matches</td>
<td>8ms</td>
<td>45ms</td>
<td>64ms</td>
</tr>
<tr>
<td>GET /friends</td>
<td>7ms</td>
<td>99ms</td>
<td>133ms</td>
</tr>
<tr>
<td>GET /wallets</td>
<td>11ms</td>
<td>272ms</td>
<td>280ms</td>
</tr>
<tr>
<td>GET /players/:id</td>
<td>14ms</td>
<td>191ms</td>
<td>194ms</td>
</tr>
</tbody>
</table>
<p>Registration and login are slow by design: pbkdf2 with 100,000 iterations is
CPU-intensive but correct for password security. API reads are sub-15ms p50.</p>
<h2 id="game-type-suitability" tabindex="-1">Game type suitability</h2>
<h3 id="mobile-casual-turn-based-party-puzzle" tabindex="-1">Mobile / casual (turn-based, party, puzzle)</h3>
<p>Excellent fit. Sub-10ms WebSocket RTT, 3,000+ CCU per node. Most mobile games
need &lt;100 messages/sec per player, so a single node handles thousands of
concurrent players comfortably.</p>
<h3 id="mmo-persistent-world" tabindex="-1">MMO (persistent world)</h3>
<p>Viable for zone servers. 3,000-7,000 concurrent connections per node with good
latency. A 20,000 CCU MMO would need 5-10 nodes. Erlang's <code>pg</code>-based clustering
is designed for this.</p>
<h3 id="competitive-real-time-fps-fighting-racing" tabindex="-1">Competitive real-time (FPS, fighting, racing)</h3>
<p>Not the target. WebSocket (TCP) has a 5-25ms RTT floor. These genres need UDP
transport with &lt;3ms latency. Consider Photon or a custom UDP relay alongside
Asobi for the game state, using Asobi for everything else (auth, matchmaking,
economy, social, leaderboards).</p>
<h2 id="bottlenecks-and-tuning" tabindex="-1">Bottlenecks and tuning</h2>
<h3 id="authentication-under-load" tabindex="-1">Authentication under load</h3>
<p>pbkdf2 saturates CPU during login storms (1,000+ simultaneous registrations).
Mitigations:</p>
<ul>
<li><strong>Reverse proxy rate limiting</strong> on <code>/auth/*</code> endpoints</li>
<li><strong>Auth result caching</strong> for repeated token validations</li>
<li><strong>Multiple nodes</strong> behind a load balancer to spread pbkdf2 work</li>
</ul>
<h3 id="database-pool" tabindex="-1">Database pool</h3>
<p>The default pool size matters. With 10 connections, 100+ concurrent DB
operations queue up. Recommended:</p>
<table>
<thead>
<tr>
<th>Deployment</th>
<th>pool_size</th>
<th>PG max_connections</th>
</tr>
</thead>
<tbody>
<tr>
<td>Development</td>
<td>50</td>
<td>100</td>
</tr>
<tr>
<td>Production (single node)</td>
<td>200</td>
<td>500</td>
</tr>
<tr>
<td>Production (cluster)</td>
<td>100 per node</td>
<td>500-1000</td>
</tr>
</tbody>
</table>
<h3 id="memory" tabindex="-1">Memory</h3>
<p>WebSocket connections use ~13-20KB each. A node with 8GB RAM can sustain
~100,000 connections from memory alone. The practical limit is CPU (message
processing) not memory.</p>
<h2 id="running-benchmarks" tabindex="-1">Running benchmarks</h2>
<pre><code class="language-bash"># HTTP load test (default 100 players)
ASOBI_LOAD_N=500 rebar3 ct --suite=asobi_load_bench

# WebSocket benchmark
# Phase 1: Register players (cached after first run)
# Phase 2: Connect and blast heartbeats
ASOBI_BENCH_PLAYERS=5000 \
ASOBI_WS_N=5000 \
ASOBI_WS_MSGS=2000 \
ASOBI_WS_WAVE=200 \
rebar3 ct --suite=asobi_ws_bench
</code></pre>
<p>Environment variables:</p>
<table>
<thead>
<tr>
<th>Variable</th>
<th>Default</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>ASOBI_LOAD_N</code></td>
<td>100</td>
<td>HTTP benchmark: concurrent players</td>
</tr>
<tr>
<td><code>ASOBI_BENCH_PLAYERS</code></td>
<td>1000</td>
<td>WS benchmark: players to register</td>
</tr>
<tr>
<td><code>ASOBI_BENCH_BATCH</code></td>
<td>50</td>
<td>WS benchmark: registration batch size</td>
</tr>
<tr>
<td><code>ASOBI_WS_N</code></td>
<td>500</td>
<td>WS benchmark: concurrent connections</td>
</tr>
<tr>
<td><code>ASOBI_WS_MSGS</code></td>
<td>200</td>
<td>WS benchmark: messages per connection</td>
</tr>
<tr>
<td><code>ASOBI_WS_WAVE</code></td>
<td>200</td>
<td>WS benchmark: connections per wave</td>
</tr>
</tbody>
</table>
"""}
    ]}.
