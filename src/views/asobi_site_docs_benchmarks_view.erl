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
<p>Single-node performance measurements. Client and server run on the same
machine, so a real deployment with the load generator elsewhere will see higher
server throughput than the tables below.</p>
<p>Measured on 2026-04-02 at commit <code>8069c02</code>. Re-run them yourself before you
size anything: the numbers below are one machine on one day, not a promise.</p>
<h2 id="test-environment" tabindex="-1">Test environment</h2>
<ul>
<li>8 cores, client and server sharing them</li>
<li>Erlang/OTP 28 and PostgreSQL 17, what the image was built on at that commit.
asobi builds on OTP 29 today - see <a href="https://hexdocs.pm/asobi/self-hosting.html">Self-hosting</a></li>
<li>PostgreSQL in Docker with <code>max_connections=500</code>, <code>shared_buffers=256MB</code></li>
<li>Database pool: 200 connections (the <code>dev_sys.config.src</code> default the CT
profile runs with)</li>
<li>One Erlang node, no clustering</li>
</ul>
<h2 id="websocket-throughput" tabindex="-1">WebSocket throughput</h2>
<p>Heartbeat round-trip: the client sends <code>session.heartbeat</code>, the server replies
with a timestamp. This measures the whole WebSocket pipeline including JSON
encode and decode.</p>
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
<p>Peak sustained: ~83,000 messages/sec at 3,500 concurrent connections.</p>
<p>At 7,000 connections per-message throughput drops because the benchmark client
is competing with the server for CPU on the same machine.</p>
<h3 id="blast-mode" tabindex="-1">Blast mode</h3>
<p>Fire-and-forget: all messages sent before waiting for any reply. Measures raw
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
<p>All messages delivered, none lost.</p>
<h2 id="http-rest-api" tabindex="-1">HTTP REST API</h2>
<p>100 concurrent players, each running register, login, then API reads.</p>
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
<td><code>POST /api/v1/auth/register</code></td>
<td>1,463ms</td>
<td>1,464ms</td>
<td>1,464ms</td>
</tr>
<tr>
<td><code>POST /api/v1/auth/login</code></td>
<td>724ms</td>
<td>1,278ms</td>
<td>1,308ms</td>
</tr>
<tr>
<td><code>GET /api/v1/matches</code></td>
<td>8ms</td>
<td>45ms</td>
<td>64ms</td>
</tr>
<tr>
<td><code>GET /api/v1/friends</code></td>
<td>7ms</td>
<td>99ms</td>
<td>133ms</td>
</tr>
<tr>
<td><code>GET /api/v1/wallets</code></td>
<td>11ms</td>
<td>272ms</td>
<td>280ms</td>
</tr>
<tr>
<td><code>GET /api/v1/players/:id</code></td>
<td>14ms</td>
<td>191ms</td>
<td>194ms</td>
</tr>
</tbody>
</table>
<p>Register and login are slow on purpose: pbkdf2 at 100,000 iterations is meant
to cost CPU. Everything else is sub-15ms at p50.</p>
<h2 id="game-type-suitability" tabindex="-1">Game type suitability</h2>
<h3 id="mobile-and-casual-turn-based-party-puzzle" tabindex="-1">Mobile and casual (turn-based, party, puzzle)</h3>
<p>Good fit. Sub-10ms WebSocket RTT, thousands of concurrent connections per node.
Most mobile games send well under 100 messages/sec per player.</p>
<h3 id="persistent-worlds" tabindex="-1">Persistent worlds</h3>
<p>Viable per world. 3,000-7,000 concurrent connections per node with acceptable
latency.</p>
<p>One world lives entirely on one node and does not migrate, so a node is not a
slice of a shared world - it is a set of separate worlds. Reaching 20,000 CCU
across 5-10 nodes therefore means running 5-10 sets of worlds, with players
sharded across them by your own routing. If your design needs one world larger
than a single node can hold, adding nodes does not help. See
<a href="/docs/clustering#the-scaling-unit-is-a-world-not-a-node">Clustering</a>.</p>
<h3 id="competitive-real-time-fps-fighting-racing" tabindex="-1">Competitive real-time (FPS, fighting, racing)</h3>
<p>Not the target. WebSocket over TCP has a 5-25ms RTT floor and these genres want
UDP under 3ms. Run a UDP transport for game state alongside asobi and use asobi
for everything else: auth, matchmaking, economy, social, leaderboards.</p>
<h2 id="bottlenecks-and-tuning" tabindex="-1">Bottlenecks and tuning</h2>
<h3 id="authentication-under-load" tabindex="-1">Authentication under load</h3>
<p>pbkdf2 saturates CPU during login storms. Mitigations:</p>
<ul>
<li>Rate-limit <code>/api/v1/auth/*</code> at the reverse proxy. asobi's own limiter is
per node, so it is <code>N x</code> looser across a cluster - see
<a href="/docs/clustering#what-is-per-node">Clustering</a>.</li>
<li>More nodes behind a load balancer, to spread the pbkdf2 work.</li>
</ul>
<h3 id="database-pool" tabindex="-1">Database pool</h3>
<p>The pool is <code>pool_size</code> under the <code>kura</code> application in <code>sys.config</code>. What
ships:</p>
<table>
<thead>
<tr>
<th>Config</th>
<th><code>pool_size</code></th>
</tr>
</thead>
<tbody>
<tr>
<td><code>config/prod_sys.config.src</code> (the image)</td>
<td>20</td>
</tr>
<tr>
<td><code>config/dev_sys.config.src</code> (dev and CT)</td>
<td>200</td>
</tr>
</tbody>
</table>
<p>The production default of 20 is deliberately conservative, because every node
opens its own pool and PostgreSQL's <code>max_connections</code> is a fleet-wide budget:
<code>nodes x pool_size</code> has to fit inside it with room for your own tooling. Raise
it when you see queueing on database-bound endpoints, and raise
<code>max_connections</code> to match.</p>
<h3 id="memory" tabindex="-1">Memory</h3>
<p>WebSocket connections cost ~13-20KB each, so at the concurrency measured above
memory is not the constraint. CPU spent on message processing is.</p>
<h2 id="running-the-benchmarks" tabindex="-1">Running the benchmarks</h2>
<pre><code class="language-bash"># HTTP load test (default 100 players)
ASOBI_LOAD_N=500 rebar3 ct --suite=asobi_load_bench

# WebSocket benchmark. Phase 1 registers players (cached after the first run),
# phase 2 connects and blasts heartbeats.
ASOBI_BENCH_PLAYERS=5000 \
ASOBI_WS_N=5000 \
ASOBI_WS_MSGS=2000 \
ASOBI_WS_WAVE=200 \
rebar3 ct --suite=asobi_ws_bench
</code></pre>
<table>
<thead>
<tr>
<th>Variable</th>
<th>Default</th>
<th>Meaning</th>
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
<p>Both suites need a running PostgreSQL 17 - see
<a href="https://hexdocs.pm/asobi/self-hosting.html">Self-hosting</a>.</p>
"""}
    ]}.
