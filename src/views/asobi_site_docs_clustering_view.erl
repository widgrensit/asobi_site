%% GENERATED from asobi guides/clustering.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_clustering_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-clustering", title => ~"Clustering — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Clustering"
        ]},
        {h1, [], [~"Clustering"]},
        {raw,
            ~"""
<p>asobi is one Erlang/OTP node holding the game backend, the Lua runtime and the
operator console. Several of those nodes can form a cluster over the BEAM's
distribution protocol and process groups (<code>pg</code>), for connection capacity and
for failover.</p>
<p>Read the per-node list below before you put a second node behind a load
balancer. Several subsystems are node-local, and most of them fail by getting
quietly worse rather than by returning an error.</p>
<h2 id="the-scaling-unit-is-a-world-not-a-node" tabindex="-1">The scaling unit is a world, not a node</h2>
<p>A world lives entirely on the node that created it. So does a match. Neither
migrates. Horizontal scale therefore means <em>more</em> worlds and matches, never a
bigger one: if a single world is the thing that is full, the answer is to shard
it in your game design (regions, instances, shards), not to add a node.</p>
<p>If the owning node dies, its live matches and worlds die with it. Match results
already written to Postgres survive; play does not resume elsewhere.</p>
<h2 id="forming-a-cluster" tabindex="-1">Forming a cluster</h2>
<p>The image is driven by environment variables, and that includes the node name
and the cookie. <code>config/vm.args.src</code> renders <code>-name asobi@${ASOBI_NODE_HOST}</code>
and <code>-setcookie ${ERLANG_COOKIE}</code>, so every node shares the base name <code>asobi</code>
and one cookie:</p>
<pre><code>ASOBI_NODE_HOST=10.0.0.1
ERLANG_COOKIE=&lt;shared-secret&gt;
</code></pre>
<p><code>ghcr.io/widgrensit/asobi</code> also reads <code>ASOBI_PORT</code>, <code>ASOBI_DB_HOST</code>,
<code>ASOBI_DB_NAME</code>, <code>ASOBI_DB_USER</code>, <code>ASOBI_DB_PASSWORD</code>, <code>ASOBI_DB_SOCKET_OPTS</code>
and <code>ASOBI_CORS_ORIGINS</code>, and the operator console reads five more - see
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<div class="docs-callout docs-callout-warning"><p class="docs-callout-title">Change the cookie</p><p>The image ships <code>ERLANG_COOKIE</code> defaulting to the literal <code>asobi</code>, so that
<code>bin/asobi remote</code> works out of the box in a single container. Anyone who can
reach the distribution port of a node still running that default has a shell
on your VM. Set your own before you expose distribution.</p>
</div>
<p><code>asobi_cluster</code> is a <code>gen_server</code> that periodically resolves its peers and
connects to any it is not already connected to. It never disconnects a node;
failover is left to the BEAM and to the load balancer.</p>
<h2 id="service-discovery" tabindex="-1">Service discovery</h2>
<p>Clustering is opt-in: with no <code>cluster</code> key set, <code>asobi_cluster</code> does not start
and the node runs standalone. Configure the discovery strategy under the
<code>asobi</code> app's <code>cluster</code> key to enable it. Two strategies are supported.</p>
<div class="tabbed-code"><input type="radio" name="cluster-tab0" id="cluster-tab0-1" checked><input type="radio" name="cluster-tab0" id="cluster-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="cluster-tab0-1">DNS (Kubernetes headless service)</label><label for="cluster-tab0-2">EPMD (static host list)</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-erlang">{asobi, [
    {cluster, #{
        strategy =&gt; dns,
        dns_name =&gt; ~"asobi-headless.default.svc.cluster.local",
        poll_interval =&gt; 10000
    }}
]}</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">{asobi, [
    {cluster, #{
        strategy =&gt; epmd,
        hosts =&gt; ['host-a', 'host-b'],
        poll_interval =&gt; 10000
    }}
]}</code></pre></div></div>
<p>DNS resolves the peer addresses of the headless service; EPMD walks the fixed
<code>hosts</code> list. Either way asobi derives each peer's node name by reusing the
current node's base name (the part before <code>@</code>) and connects. <code>poll_interval</code> is
the rediscovery period in milliseconds, default 10000.</p>
<div class="docs-callout docs-callout-warning"><p class="docs-callout-title">Secure the distribution port</p><p>EPMD binds <code>0.0.0.0:4369</code> and the distribution port range is unbounded by
default; the cookie is the only protection. For anything beyond a trusted
private network, constrain the port range and enable TLS for distribution.
See the <a href="/docs/security/threat-model#erlang-distribution">Threat model</a>.</p>
</div>
<p>Add to <code>vm.args</code>:</p>
<pre><code>-kernel inet_dist_listen_min 9100 inet_dist_listen_max 9105
-proto_dist inet_tls
-ssl_dist_optfile /etc/asobi/ssl_dist.config
</code></pre>
<h2 id="what-is-cluster-wide" tabindex="-1">What is cluster-wide</h2>
<ul>
<li><strong><code>pg</code> process groups.</strong> Presence, chat delivery, leaderboard liveness and
world/match <code>whereis</code> lookups all resolve across nodes.</li>
<li><strong>Player sessions.</strong> A session on node A can send to a match on node B; the
send is proxied through a <code>pg</code> lookup of the owning process.</li>
<li><strong>Chat message delivery.</strong> A message is fanned out to every joined pid in the
<code>pg</code> group, wherever it lives.</li>
<li><strong>Postgres.</strong> Everything persistent is one database and is consistent across
nodes: players, matches, economy, tournaments, notifications, leaderboard
entries and chat messages.</li>
<li><strong><code>online_players</code>.</strong> Presence counts pg members across the whole cluster.</li>
</ul>
<h2 id="what-is-per-node" tabindex="-1">What is per-node</h2>
<p>This is the complete list. Other guides state the one item their own subject
needs and link here.</p>
<ul>
<li><strong>The matchmaker queue and its tickets.</strong> One <code>gen_server</code> per node, tickets
in that process's own map. There is no ticket schema and nothing is shared or
persisted. Two players who queue for the same mode against different nodes
never match each other, and each node forms matches only from its own queue.
Effective queue depth is your real depth divided by node count, which shows
up as longer waits and weaker matches, not as an error. Either route all
matchmaking for a mode to one node, or size for the division.</li>
<li><strong>The console session store and the secret its CSRF token is derived from.</strong>
Both are per node, and the secret is regenerated on every boot. A console
login is valid only on the node that issued it, so behind a round-robin
balancer roughly <code>(N-1)/N</code> of console requests answer 403 and drop the
operator back to the sign-in screen. Give <code>/console</code> and <code>/api/v1/ops</code> a
sticky route, or point the console at one node.</li>
<li><strong>Rate-limit buckets.</strong> Counted per node, so the 5/s bucket in front of
<code>/console/session</code> is really <code>5 x N</code> across the cluster, and so is every
other limit.</li>
<li><strong>The auth cache.</strong> Access-token lookups are cached in a node-local ETS table
for 60s by default (<code>asobi.auth_cache_ttl_ms</code>). Revocation invalidates the
entry on the node that performed it; another node can keep honouring the
token until its own entry expires.</li>
<li><strong>The chat-channel registry.</strong> Each node keeps its own registry of channel
processes, so the same channel id can have a process on several nodes at
once. Delivery is still cluster-wide; what is local is the process and what
it holds.</li>
<li><strong>The DM history buffer.</strong> <code>GET /api/v1/dm/:player_id/history</code> answers from
the last 100 messages held in the channel process on the node that answered,
so two nodes give two different answers. <code>GET /api/v1/chat/:channel_id/history</code>
reads Postgres and does not have this problem.</li>
<li><strong>The player-to-world table.</strong> <code>asobi_player_worlds</code> is a node-local ETS
table, and <code>session.connect</code> consults only the local one to restore a
player's world. A player who reconnects to a different node is not rejoined
to their world and gets <strong>no error</strong>: the connect succeeds, the world is
simply gone from their session. Pin a player's socket to one node.</li>
<li><strong>Zone entity snapshots and every other ETS cache</strong>, including the 500ms
lobby listing cache below. Hot paths assume local access.</li>
<li><strong>Luerl VMs.</strong> Per process and per node; there is no shared script state.</li>
</ul>
<h2 id="ops-reads-across-a-cluster" tabindex="-1">Ops reads across a cluster</h2>
<p><code>/api/v1/ops/features</code>, <code>/api/v1/ops/matchmaker</code> and
<code>/api/v1/ops/chat/channels</code> read node-local state and describe only the node
that answered. Every other ops route reads Postgres and is cluster-consistent.</p>
<p><code>/api/v1/ops/stats</code> is per node - process count, run queue, memory, uptime -
with one exception: <code>online_players</code> is fleet-wide. Summing <code>/stats</code> across N
nodes multiplies the player count by N. That is why the payload carries <code>node</code>.</p>
<p>Every node needs the same ops secret. The secret is compared against the
answering node's own <code>ops_secret</code>, so if the values differ, whether an operator
can sign in at all depends on which node the balancer picked.</p>
<h2 id="lobby-listing-cost-scales-with-fleet-size" tabindex="-1">Lobby listing cost scales with fleet size</h2>
<p>Browsing worlds or matches enumerates the <code>pg</code> groups and issues one
synchronous <code>get_info</code> call per live world or match, across every node. A 500ms
per-node cache sits in front of it, which caps the fan-out at two refreshes per
second per node, but the cost of each refresh grows with the number of worlds
in the whole cluster, not on one node.</p>
<h2 id="routing-players-to-nodes" tabindex="-1">Routing players to nodes</h2>
<p>Put a load balancer in front of the cluster with a sticky WebSocket cookie, or
hash on <code>player_id</code>. Sticky routing is not an optimisation here: it is what
makes reconnect-into-a-world, console sessions and matchmaking queue depth
behave. Cross-node calls then happen only for a match or world the player
joined on another node.</p>
<h2 id="draining-and-restarts" tabindex="-1">Draining and restarts</h2>
<p>asobi has no drain facility. There is no way to tell a node to stop accepting
new matches while finishing the ones it has.</p>
<p>What you can do:</p>
<ol>
<li>Take the node out of rotation at the load balancer. <code>GET /ready</code> is the
probe to point it at.</li>
<li>Wait long enough for players to reconnect elsewhere. You are choosing this
number, not asobi.</li>
<li>Stop the node. On shutdown, <code>/ready</code> flips to 503 and the node waits
<code>shutdown_delay</code> (5s in the shipped production config) before tearing down
the database pool. That is a load-balancer drain window, not a
match-length one.</li>
</ol>
<p>Matches and worlds still running on the node die with it, however long you
wait. Plan rolling restarts for a quiet window, or keep modes short enough that
waiting actually empties the node.</p>
<h2 id="observability" tabindex="-1">Observability</h2>
<p>asobi emits telemetry events under <code>[asobi, match, _]</code>, <code>[asobi, world, _]</code>,
<code>[asobi, zone, _]</code>, <code>[asobi, matchmaker, _]</code>, <code>[asobi, ws, _]</code> and others, all
from <code>asobi_telemetry</code>. Wire them to Prometheus via
<code>telemetry_metrics_prometheus</code>, or ship them to any OpenTelemetry collector.
Attach per node and label the series by node name: nothing here is aggregated
for you.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/configuration">Configuration</a> - the full <code>cluster</code> config key.</li>
<li><a href="/docs/performance">Performance tuning</a> - per-node tick and broadcast costs.</li>
<li><a href="https://hexdocs.pm/asobi/console.html">Operator console</a> - the console behind a load balancer.</li>
<li><a href="/docs/security/threat-model">Threat model</a> - the distribution trust boundary.</li>
</ul>
"""}
    ]}.
