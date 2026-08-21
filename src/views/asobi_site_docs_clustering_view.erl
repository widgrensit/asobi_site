%% GENERATED from asobi guides/clustering.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_clustering_view).

-export([mount/1, render/1, markdown/0]).

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
and the cookie. <code>config/vm.args.src</code> renders
<code>-name ${ASOBI_NODE_NAME}@${ASOBI_NODE_HOST}</code> and <code>-setcookie ${ERLANG_COOKIE}</code>,
so every node shares one base name and one cookie:</p>
<pre><code>ASOBI_NODE_HOST=10.0.0.1
ERLANG_COOKIE=&lt;shared-secret&gt;
</code></pre>
<p><strong>Leave <code>ASOBI_NODE_NAME</code> alone in a cluster.</strong> It defaults to <code>asobi</code>, and
<code>asobi_cluster</code> builds every peer name by reusing the <em>current</em> node's base name</p>
<ul>
<li>so a per-host value makes discovery find nothing, silently and with no error
anywhere. The one deployment that changes it is the datagram gateway, which is
not a cluster member: it shares a network namespace with its engine and needs a
name that does not collide in the shared EPMD.</li>
</ul>
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

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Clustering

asobi is one Erlang/OTP node holding the game backend, the Lua runtime and the
operator console. Several of those nodes can form a cluster over the BEAM's
distribution protocol and process groups (`pg`), for connection capacity and
for failover.

Read the per-node list below before you put a second node behind a load
balancer. Several subsystems are node-local, and most of them fail by getting
quietly worse rather than by returning an error.

## The scaling unit is a world, not a node

A world lives entirely on the node that created it. So does a match. Neither
migrates. Horizontal scale therefore means *more* worlds and matches, never a
bigger one: if a single world is the thing that is full, the answer is to shard
it in your game design (regions, instances, shards), not to add a node.

If the owning node dies, its live matches and worlds die with it. Match results
already written to Postgres survive; play does not resume elsewhere.

## Forming a cluster

The image is driven by environment variables, and that includes the node name
and the cookie. `config/vm.args.src` renders
`-name ${ASOBI_NODE_NAME}@${ASOBI_NODE_HOST}` and `-setcookie ${ERLANG_COOKIE}`,
so every node shares one base name and one cookie:

```
ASOBI_NODE_HOST=10.0.0.1
ERLANG_COOKIE=<shared-secret>
```

**Leave `ASOBI_NODE_NAME` alone in a cluster.** It defaults to `asobi`, and
`asobi_cluster` builds every peer name by reusing the *current* node's base name
- so a per-host value makes discovery find nothing, silently and with no error
anywhere. The one deployment that changes it is the datagram gateway, which is
not a cluster member: it shares a network namespace with its engine and needs a
name that does not collide in the shared EPMD.

`ghcr.io/widgrensit/asobi` also reads `ASOBI_PORT`, `ASOBI_DB_HOST`,
`ASOBI_DB_NAME`, `ASOBI_DB_USER`, `ASOBI_DB_PASSWORD`, `ASOBI_DB_SOCKET_OPTS`
and `ASOBI_CORS_ORIGINS`, and the operator console reads five more - see
[Operator console](https://hexdocs.pm/asobi/console.html).

> #### Change the cookie
>
> The image ships `ERLANG_COOKIE` defaulting to the literal `asobi`, so that
> `bin/asobi remote` works out of the box in a single container. Anyone who can
> reach the distribution port of a node still running that default has a shell
> on your VM. Set your own before you expose distribution.

`asobi_cluster` is a `gen_server` that periodically resolves its peers and
connects to any it is not already connected to. It never disconnects a node;
failover is left to the BEAM and to the load balancer.

## Service discovery

Clustering is opt-in: with no `cluster` key set, `asobi_cluster` does not start
and the node runs standalone. Configure the discovery strategy under the
`asobi` app's `cluster` key to enable it. Two strategies are supported.

**DNS (Kubernetes headless service)**
```erlang
{asobi, [
    {cluster, #{
        strategy => dns,
        dns_name => ~"asobi-headless.default.svc.cluster.local",
        poll_interval => 10000
    }}
]}
```
**EPMD (static host list)**
```erlang
{asobi, [
    {cluster, #{
        strategy => epmd,
        hosts => ['host-a', 'host-b'],
        poll_interval => 10000
    }}
]}
```

DNS resolves the peer addresses of the headless service; EPMD walks the fixed
`hosts` list. Either way asobi derives each peer's node name by reusing the
current node's base name (the part before `@`) and connects. `poll_interval` is
the rediscovery period in milliseconds, default 10000.

> #### Secure the distribution port
>
> EPMD binds `0.0.0.0:4369` and the distribution port range is unbounded by
> default; the cookie is the only protection. For anything beyond a trusted
> private network, constrain the port range and enable TLS for distribution.
> See the [Threat model](https://asobi.dev/docs/security/threat-model#erlang-distribution).

Add to `vm.args`:

```
-kernel inet_dist_listen_min 9100 inet_dist_listen_max 9105
-proto_dist inet_tls
-ssl_dist_optfile /etc/asobi/ssl_dist.config
```

## What is cluster-wide

- **`pg` process groups.** Presence, chat delivery, leaderboard liveness and
  world/match `whereis` lookups all resolve across nodes.
- **Player sessions.** A session on node A can send to a match on node B; the
  send is proxied through a `pg` lookup of the owning process.
- **Chat message delivery.** A message is fanned out to every joined pid in the
  `pg` group, wherever it lives.
- **Postgres.** Everything persistent is one database and is consistent across
  nodes: players, matches, economy, tournaments, notifications, leaderboard
  entries and chat messages.
- **`online_players`.** Presence counts pg members across the whole cluster.

## What is per-node

This is the complete list. Other guides state the one item their own subject
needs and link here.

- **The matchmaker queue and its tickets.** One `gen_server` per node, tickets
  in that process's own map. There is no ticket schema and nothing is shared or
  persisted. Two players who queue for the same mode against different nodes
  never match each other, and each node forms matches only from its own queue.
  Effective queue depth is your real depth divided by node count, which shows
  up as longer waits and weaker matches, not as an error. Either route all
  matchmaking for a mode to one node, or size for the division.
- **The console session store and the secret its CSRF token is derived from.**
  Both are per node, and the secret is regenerated on every boot. A console
  login is valid only on the node that issued it, so behind a round-robin
  balancer roughly `(N-1)/N` of console requests answer 403 and drop the
  operator back to the sign-in screen. Give `/console` and `/api/v1/ops` a
  sticky route, or point the console at one node.
- **Rate-limit buckets.** Counted per node, so the 5/s bucket in front of
  `/console/session` is really `5 x N` across the cluster, and so is every
  other limit.
- **The auth cache.** Access-token lookups are cached in a node-local ETS table
  for 60s by default (`asobi.auth_cache_ttl_ms`). Revocation invalidates the
  entry on the node that performed it; another node can keep honouring the
  token until its own entry expires.
- **The chat-channel registry.** Each node keeps its own registry of channel
  processes, so the same channel id can have a process on several nodes at
  once. Delivery is still cluster-wide; what is local is the process and what
  it holds.
- **The DM history buffer.** `GET /api/v1/dm/:player_id/history` answers from
  the last 100 messages held in the channel process on the node that answered,
  so two nodes give two different answers. `GET /api/v1/chat/:channel_id/history`
  reads Postgres and does not have this problem.
- **The player-to-world table.** `asobi_player_worlds` is a node-local ETS
  table, and `session.connect` consults only the local one to restore a
  player's world. A player who reconnects to a different node is not rejoined
  to their world and gets **no error**: the connect succeeds, the world is
  simply gone from their session. Pin a player's socket to one node.
- **Zone entity snapshots and every other ETS cache**, including the 500ms
  lobby listing cache below. Hot paths assume local access.
- **Luerl VMs.** Per process and per node; there is no shared script state.

## Ops reads across a cluster

`/api/v1/ops/features`, `/api/v1/ops/matchmaker` and
`/api/v1/ops/chat/channels` read node-local state and describe only the node
that answered. Every other ops route reads Postgres and is cluster-consistent.

`/api/v1/ops/stats` is per node - process count, run queue, memory, uptime -
with one exception: `online_players` is fleet-wide. Summing `/stats` across N
nodes multiplies the player count by N. That is why the payload carries `node`.

Every node needs the same ops secret. The secret is compared against the
answering node's own `ops_secret`, so if the values differ, whether an operator
can sign in at all depends on which node the balancer picked.

## Lobby listing cost scales with fleet size

Browsing worlds or matches enumerates the `pg` groups and issues one
synchronous `get_info` call per live world or match, across every node. A 500ms
per-node cache sits in front of it, which caps the fan-out at two refreshes per
second per node, but the cost of each refresh grows with the number of worlds
in the whole cluster, not on one node.

## Routing players to nodes

Put a load balancer in front of the cluster with a sticky WebSocket cookie, or
hash on `player_id`. Sticky routing is not an optimisation here: it is what
makes reconnect-into-a-world, console sessions and matchmaking queue depth
behave. Cross-node calls then happen only for a match or world the player
joined on another node.

## Draining and restarts

asobi has no drain facility. There is no way to tell a node to stop accepting
new matches while finishing the ones it has.

What you can do:

1. Take the node out of rotation at the load balancer. `GET /ready` is the
   probe to point it at.
2. Wait long enough for players to reconnect elsewhere. You are choosing this
   number, not asobi.
3. Stop the node. On shutdown, `/ready` flips to 503 and the node waits
   `shutdown_delay` (5s in the shipped production config) before tearing down
   the database pool. That is a load-balancer drain window, not a
   match-length one.

Matches and worlds still running on the node die with it, however long you
wait. Plan rolling restarts for a quiet window, or keep modes short enough that
waiting actually empties the node.

## Observability

asobi emits telemetry events under `[asobi, match, _]`, `[asobi, world, _]`,
`[asobi, zone, _]`, `[asobi, matchmaker, _]`, `[asobi, ws, _]` and others, all
from `asobi_telemetry`. Wire them to Prometheus via
`telemetry_metrics_prometheus`, or ship them to any OpenTelemetry collector.
Attach per node and label the series by node name: nothing here is aggregated
for you.

## Next steps

- [Configuration](https://asobi.dev/docs/configuration) - the full `cluster` config key.
- [Performance tuning](https://asobi.dev/docs/performance) - per-node tick and broadcast costs.
- [Operator console](https://hexdocs.pm/asobi/console.html) - the console behind a load balancer.
- [Threat model](https://asobi.dev/docs/security/threat-model) - the distribution trust boundary.
""".
