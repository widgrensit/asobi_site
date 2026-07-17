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
<p>Run multiple asobi nodes as one cluster for horizontal scale of connections and
matches, plus automatic failover. Presence, chat, and cross-match messaging are
cluster-safe out of the box via the BEAM's process groups (<code>pg</code>).</p>
<div class="docs-callout docs-callout-info"><p class="docs-callout-title">asobi is single-node by design for gameplay</p><p>A match lives on one node; the world server's zones for a given world live on
one node. Clustering is for connection termination, cross-node messaging, and
failover - not for live cross-node zone migration. Shard heavy load at the app
level (for example, route players to a region's cluster).</p>
</div>
<h2 id="whats-cluster-safe" tabindex="-1">What's cluster-safe</h2>
<ul>
<li><strong><code>pg</code>-scoped process groups</strong> - presence, chat channels, and world/match
<code>whereis</code> lookups resolve across nodes.</li>
<li><strong>Player sessions</strong> - a session on node A can send to a match on node B; the
send is proxied via a <code>pg</code> lookup of the match's owning process.</li>
<li><strong>Storage</strong> - Postgres is shared, so everything persistent is consistent
across nodes.</li>
<li><strong>Matchmaker</strong> - replicated: one <code>gen_server</code> per node, with tickets held in
Postgres, so any node can form a match.</li>
</ul>
<h2 id="what-isnt" tabindex="-1">What isn't</h2>
<ul>
<li><strong>Matches and worlds do not migrate between nodes.</strong> If the owning node dies,
its active matches are lost (their state persists in Postgres for post-mortem,
but play does not resume elsewhere).</li>
<li><strong>ETS caches</strong> (zone entity snapshots, rate-limit counters) are per-node. Hot
paths assume local access.</li>
<li><strong>Luerl VMs</strong> are per-process and per-node - there is no shared script state
across nodes.</li>
</ul>
<h2 id="forming-a-cluster" tabindex="-1">Forming a cluster</h2>
<p>asobi uses the BEAM's distribution protocol. Give each node a long name, share a
cookie, and let the <code>asobi_cluster</code> discovery loop connect them. The image reads
only <code>ASOBI_PORT</code>, <code>ASOBI_DB_*</code>, and <code>ASOBI_CORS_ORIGINS</code> from the environment;
set the node name and cookie with the standard VM flags:</p>
<pre><code>-name asobi@10.0.0.1 -setcookie &lt;shared-secret&gt;
</code></pre>
<p><code>asobi_cluster</code> is a <code>gen_server</code> that periodically resolves its peers and
connects to any it isn't already connected to. It never disconnects a node;
failover is left to the BEAM and the load balancer.</p>
<h2 id="service-discovery" tabindex="-1">Service discovery</h2>
<p>Clustering is opt-in: with no <code>cluster</code> key set, <code>asobi_cluster</code> does not start
and the node runs standalone. Configure the discovery strategy under the <code>asobi</code>
app's <code>cluster</code> key to enable it. Two strategies are supported.</p>
<div class="tabbed-code"><input type="radio" name="cluster-tab0" id="cluster-tab0-1" checked><input type="radio" name="cluster-tab0" id="cluster-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="cluster-tab0-1">DNS (Kubernetes headless service)</label><label for="cluster-tab0-2">EPMD (static host list)</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-erlang">{asobi, [
    {cluster, #{
        strategy =&gt; dns,
        dns_name =&gt; &lt;&lt;"asobi-headless.default.svc.cluster.local"&gt;&gt;,
        poll_interval =&gt; 10000
    }}
]}</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">{asobi, [
    {cluster, #{
        strategy =&gt; epmd,
        hosts =&gt; ['host-a', 'host-b'],
        poll_interval =&gt; 10000
    }}
]}</code></pre></div></div>
<p>DNS resolves the peer addresses of the headless service; EPMD walks a fixed
<code>hosts</code> list. Either way asobi derives each peer's node name by reusing the
current node's base name (the part before <code>@</code>) and connects. <code>poll_interval</code> is
the rediscovery period in milliseconds (default 10000).</p>
<div class="docs-callout docs-callout-warning"><p class="docs-callout-title">Secure the distribution port</p><p>EPMD binds <code>0.0.0.0:4369</code> and the distribution port range is unbounded by
default; the cookie is the only protection. For anything beyond a trusted
private network, constrain the port range and enable TLS for distribution in
<code>vm.args</code> (<code>inet_dist_listen_min</code>/<code>max</code>, <code>-proto_dist inet_tls</code>). See the
<a href="/docs/security/threat-model#single-node-beam-distribution">Threat model</a>.</p>
</div>
<h2 id="routing-players-to-nodes" tabindex="-1">Routing players to nodes</h2>
<p>Put a load balancer in front of the cluster with a sticky WebSocket cookie, or
hash on <code>player_id</code>. This keeps a player's session pinned to one node;
cross-node calls happen only for matches or worlds the player joins on a
different node.</p>
<h2 id="deployment" tabindex="-1">Deployment</h2>
<p>Rolling restarts are safe: drain a node (stop accepting new matches, let
existing ones finish), upgrade it, and let it rejoin. Sessions on the drained
node reconnect to another node when the load balancer re-routes them.</p>
<h2 id="observability" tabindex="-1">Observability</h2>
<p><code>asobi</code> emits telemetry events (<code>[asobi, match, *]</code>, <code>[asobi, world, *]</code>,
<code>[asobi, matchmaker, *]</code>). Wire them to Prometheus via
<code>telemetry_metrics_prometheus</code>, or ship them to any OpenTelemetry collector.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/configuration">Configuration</a> - the full <code>cluster</code> config key.</li>
<li><a href="/docs/performance">Performance tuning</a> - per-node tick and BEAM knobs.</li>
<li><a href="/docs/security/threat-model">Threat model</a> - the distribution trust boundary.</li>
</ul>
"""}
    ]}.
