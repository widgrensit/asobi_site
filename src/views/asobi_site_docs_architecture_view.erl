%% GENERATED from asobi guides/architecture.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_architecture_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-architecture", title => ~"Architecture — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Architecture"
        ]},
        {h1, [], [~"Architecture"]},
        {raw,
            ~"""
<h2 id="overview" tabindex="-1">Overview</h2>
<p>Asobi is an Erlang/OTP game backend built on Nova. This document covers the
runtime architecture, session lifecycle, how services communicate, and the
trade-offs for single-node, distributed Erlang, and cloud-native deployments.</p>
<h2 id="supervision-tree" tabindex="-1">Supervision Tree</h2>
<pre><code>asobi_sup (one_for_one)
├── asobi_rate_limit_server     — per-node ETS rate limiter
├── asobi_cluster               — node discovery (DNS/EPMD)
├── asobi_player_session_sup    — dynamic simple_one_for_one
│   └── asobi_player_session    — one per connected player
├── asobi_match_sup             — dynamic simple_one_for_one
│   └── asobi_match_server      — one per active match (gen_statem)
├── asobi_matchmaker            — matching algorithm, tick-based
├── asobi_leaderboard_sup       — one child per leaderboard
│   └── asobi_leaderboard_server — in-memory buffer, periodic DB flush
├── asobi_chat_sup              — chat channel processes
├── asobi_tournament_sup        — tournament processes
└── asobi_presence              — tracks online players via pg
</code></pre>
<h2 id="session-lifecycle" tabindex="-1">Session Lifecycle</h2>
<pre><code>Client                    WS Handler              Session              Presence (pg)
  │                          │                       │                      │
  │── WS connect ───────────►│                       │                      │
  │── session.connect ──────►│                       │                      │
  │                          │── authenticate(token) │                      │
  │                          │   (DB lookup)         │                      │
  │                          │── start_session ─────►│                      │
  │                          │                       │── track(id, self) ──►│
  │                          │                       │   pg:join(player,id) │
  │◄── session.connected ───│                       │                      │
  │                          │                       │                      │
  │   ... gameplay ...       │                       │                      │
  │                          │                       │                      │
  │── disconnect ───────────►│                       │                      │
  │                          │── stop(session) ─────►│                      │
  │                          │                       │── untrack(id) ──────►│
  │                          │                       │   pg:leave           │
</code></pre>
<p><strong>Key points:</strong></p>
<ul>
<li>Token is validated <strong>once</strong> at <code>session.connect</code> via DB lookup</li>
<li>After authentication, <code>player_id</code> lives in process state — no further DB checks</li>
<li>The session process monitors the WS process; if WS dies, session cleans up</li>
<li>WS terminate calls <code>session:stop/1</code> for the reverse direction</li>
</ul>
<h2 id="session-revocation" tabindex="-1">Session Revocation</h2>
<p>When a player is banned, deleted, or their token is revoked:</p>
<pre><code class="language-erlang">asobi_presence:revoke_session(PlayerId, ~&quot;banned&quot;).
</code></pre>
<p><strong>Flow:</strong></p>
<ol>
<li><code>revoke_session/2</code> enqueues a job on the <code>broadcast</code> fanout queue via Shigoto</li>
<li>All nodes poll the fanout queue and pick up the job</li>
<li>Each node calls <code>asobi_presence:disconnect/2</code> locally</li>
<li><code>disconnect/2</code> looks up session processes in the local <code>pg</code> group</li>
<li>Sends <code>{session_revoked, Reason}</code> to each session process</li>
<li>Session forwards to WS process, then stops</li>
<li>WS handler logs and returns <code>{stop, State}</code></li>
</ol>
<p>This uses Shigoto's fanout queue mode — every node processes every broadcast
job. Jobs are ephemeral (120s window, auto-pruned). Workers are idempotent.
The source of truth is always the database.</p>
<p><strong>Two-layer API:</strong></p>
<ul>
<li><code>asobi_presence:revoke_session/2</code> — public API, enqueues broadcast job (cross-node)</li>
<li><code>asobi_presence:disconnect/2</code> — local delivery mechanism, called by the broadcast worker</li>
</ul>
<h2 id="match-lifecycle" tabindex="-1">Match Lifecycle</h2>
<pre><code>Matchmaker              Match Sup            Match Server          Players (via pg)
  │                        │                      │                     │
  │── start_match(Config)─►│                      │                     │
  │                        │── start_link ────────►│ (waiting state)     │
  │                        │                      │                     │
  │── join(Pid, Player1) ─────────────────────────►│                     │
  │── join(Pid, Player2) ─────────────────────────►│ (min_players met)   │
  │                        │                      │── enter running ───►│
  │                        │                      │                     │
  │                        │                      │◄── {input, ...} ────│
  │                        │                      │── tick ──────────── │
  │                        │                      │── broadcast_state ─►│
  │                        │                      │   (10 Hz loop)      │
  │                        │                      │                     │
  │                        │                      │── enter finished    │
  │                        │                      │── persist_result ──►DB
  │                        │                      │── notify_players ──►│
  │                        │                      │── cleanup (5s) ────►stop
</code></pre>
<p><strong>Match states:</strong> <code>waiting → running → finished</code> (also <code>paused</code>)</p>
<p><strong>Server-authoritative:</strong> The match process owns all game state. Clients send
inputs, the server applies them each tick, and broadcasts the resulting state.
The game module (<code>asobi_match</code> behaviour) provides <code>init/1</code>, <code>join/2</code>,
<code>handle_input/3</code>, <code>tick/1</code>, and either <code>get_state/2</code> (per-player) or
<code>get_state/1</code> (shared, broadcast-once — see <a href="/docs/performance">Performance Tuning</a>).</p>
<h2 id="database-migrations" tabindex="-1">Database &amp; Migrations</h2>
<p>Each node runs its own PGO connection pool. Migrations run automatically at
application startup via <code>kura_migrator:migrate(asobi_repo)</code>.</p>
<p><strong>Migration rules:</strong></p>
<ul>
<li>The initial schema uses <code>create_table</code> operations</li>
<li>Kura topologically sorts tables by FK dependencies — order in the migration
file doesn't matter</li>
<li>All operations run in a single PostgreSQL transaction with an advisory lock</li>
<li><strong>Never delete or modify an applied migration</strong> — add new <code>alter_table</code>
migrations instead</li>
<li>If migration fails, the app logs the error and continues starting (by design,
to allow the app to serve health checks even with a stale schema)</li>
</ul>
<p><strong>Multi-node consideration:</strong> The advisory lock ensures only one node runs
migrations at a time. Other nodes wait. This is safe for rolling deploys.</p>
<h2 id="deployment-models" tabindex="-1">Deployment Models</h2>
<h3 id="single-node-current" tabindex="-1">Single Node (Current)</h3>
<p>Everything runs on one BEAM node. All process communication is local.
This is the simplest model and works for small-to-medium scale.</p>
<pre><code>┌─────────────────────────────────┐
│           BEAM Node             │
│  ┌──────────┐  ┌─────────────┐ │
│  │ WS/HTTP  │  │ Matchmaker  │ │
│  │ Handlers │  │ (local)     │ │
│  └──────────┘  └─────────────┘ │
│  ┌──────────┐  ┌─────────────┐ │
│  │ Sessions │  │ Matches     │ │
│  │ (local)  │  │ (local)     │ │
│  └──────────┘  └─────────────┘ │
│  ┌──────────────────────────┐  │
│  │ pg (presence, chat)      │  │
│  └──────────────────────────┘  │
└──────────────┬──────────────────┘
               │
         ┌─────▼─────┐
         │ PostgreSQL │
         └───────────┘
</code></pre>
<p><strong>Migrations:</strong> Always run at startup. One node, no contention.</p>
<p><strong>Scale limit:</strong> A single BEAM node can handle tens of thousands of concurrent
WebSocket connections and hundreds of active matches. The bottleneck is usually
the game tick loop CPU cost, not connection count.</p>
<h3 id="distributed-erlang-multi-node" tabindex="-1">Distributed Erlang (Multi-Node)</h3>
<p>Multiple BEAM nodes connected via distributed Erlang. The <code>pg</code> module
automatically replicates group membership across all connected nodes.</p>
<pre><code>┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    Node A     │    │    Node B     │    │    Node C     │
│  WS/HTTP     │    │  WS/HTTP     │    │  WS/HTTP     │
│  Sessions    │◄──►│  Sessions    │◄──►│  Sessions    │
│  Matches     │    │  Matches     │    │  Matches     │
│  Matchmaker  │    │  Matchmaker  │    │  Matchmaker  │
│  pg (shared) │    │  pg (shared) │    │  pg (shared) │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                     ┌─────▼─────┐
                     │ PostgreSQL │
                     └───────────┘
</code></pre>
<p><strong>What works across nodes today:</strong></p>
<ul>
<li><strong>Presence</strong> — <code>pg:get_members(nova_scope, {player, Id})</code> returns pids on all
nodes. Sending messages to those pids works transparently.</li>
<li><strong>Session revocation</strong> — <code>asobi_presence:disconnect/2</code> reaches sessions on any
node.</li>
<li><strong>Chat</strong> — <code>nova_pubsub</code> uses <code>pg</code> underneath, so chat messages cross nodes.</li>
<li><strong>Match state broadcasts</strong> — <code>broadcast_state</code> uses <code>asobi_presence:send/2</code>
which goes through <code>pg</code>, so a match process on Node A can send state to a
player session on Node B.</li>
</ul>
<p><strong>What does NOT work today:</strong></p>
<ul>
<li><strong>Matchmaker</strong> — Each node runs its own <code>asobi_matchmaker</code> (local registration).
A player on Node A and a player on Node B won't be matched together.</li>
<li><strong>Match lookup by ID</strong> — <code>global:whereis_name({asobi_match_server, MatchId})</code>
fails because matches don't register globally.</li>
<li><strong>Rate limiting</strong> — Per-node ETS, not shared.</li>
</ul>
<p><strong>Migrations:</strong> The Kura advisory lock ensures only one node migrates at a
time. Safe for rolling deploys, but you should NOT run migrations on every node
simultaneously — let the first node apply, others will see the version already
recorded and skip.</p>
<p><strong>When to use:</strong> Small clusters (2-5 nodes) on the same network. Full mesh
topology. Good for HA and moderate scale. Not suitable for large clusters or
multi-region.</p>
<h3 id="cloud-native-no-distributed-erlang" tabindex="-1">Cloud-Native (No Distributed Erlang)</h3>
<p>In Kubernetes, Fly.io, or similar platforms, distributed Erlang is often
impractical:</p>
<ul>
<li>Dynamic IPs and pod churn make node discovery fragile</li>
<li>Full mesh doesn't scale beyond ~50 nodes</li>
<li>The distribution protocol has a large security surface</li>
<li>Stateless horizontal scaling is the expected model</li>
</ul>
<p>In this model, each BEAM node is independent. Cross-node communication goes
through PostgreSQL (which you already have) and Shigoto (which you already have).
No Redis, no NATS, no additional infrastructure.</p>
<h4 id="the-shigoto-broadcast-pattern" tabindex="-1">The Shigoto Broadcast Pattern</h4>
<p>The core idea: <strong>every cross-node event is a Shigoto fanout job</strong>. All nodes
consume the fanout queue. When a node picks up a job, it broadcasts locally
via <code>pg</code> to the affected sessions, which push to clients via WebSocket.</p>
<pre><code>Producer Node                 PostgreSQL              All Consumer Nodes
     │                            │                         │
     │── shigoto:insert(...)────►│                         │
     │   (broadcast queue)        │                         │
     │                            │── fanout poll ─────────►│
     │                            │   (no locking,          │── local pg lookup
     │                            │    time-window)         │── broadcast to sessions
     │                            │                         │── WS push to clients
</code></pre>
<p>Fanout jobs are ephemeral — they live in the database for a configurable
window (default 120s), then are automatically pruned. Workers must be
idempotent. If a node misses a broadcast (e.g. during restart), the client
catches up from the database on reconnect. The database is always the
source of truth; fanout is best-effort push.</p>
<h4 id="architecture-diagram" tabindex="-1">Architecture Diagram</h4>
<pre><code>┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│      Pod A       │  │      Pod B       │  │      Pod C       │
│  WS/HTTP         │  │  WS/HTTP         │  │  WS/HTTP         │
│  Sessions (pg)   │  │  Sessions (pg)   │  │  Sessions (pg)   │
│  Matches (local) │  │  Matches (local) │  │  Matches (local) │
│  Shigoto worker  │  │  Shigoto worker  │  │  Shigoto worker  │
└────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
         │                     │                     │
         └─────────────────────┼─────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │     PostgreSQL      │
                    │  ┌───────────────┐  │
                    │  │ shigoto_jobs  │  │  ← shared job queue
                    │  │ asobi tables  │  │  ← application state
                    │  └───────────────┘  │
                    └─────────────────────┘
</code></pre>
<p>No Redis. No NATS. No distributed Erlang. Just PostgreSQL.</p>
<h4 id="what-goes-through-the-fanout-queue" tabindex="-1">What Goes Through the Fanout Queue</h4>
<table>
<thead>
<tr>
<th>Event</th>
<th>Producer</th>
<th>Consumer Behavior</th>
</tr>
</thead>
<tbody>
<tr>
<td>Session revocation (ban/delete)</td>
<td>Admin action</td>
<td>All nodes: <code>asobi_presence:disconnect/2</code> locally</td>
</tr>
<tr>
<td>Chat message (cross-pod)</td>
<td>Sender's pod</td>
<td>All nodes: deliver to local <code>pg</code> chat group members</td>
</tr>
<tr>
<td>Notification</td>
<td>Any service</td>
<td>All nodes: push to player's local session if connected</td>
</tr>
<tr>
<td>Presence update</td>
<td>Any pod</td>
<td>All nodes: update local presence state</td>
</tr>
<tr>
<td>Matchmaker ticket</td>
<td>Player's pod</td>
<td>One node (matchmaker leader): process ticket</td>
</tr>
</tbody>
</table>
<h4 id="what-does-not-go-through-the-fanout-queue" tabindex="-1">What Does NOT Go Through the Fanout Queue</h4>
<table>
<thead>
<tr>
<th>Event</th>
<th>Why</th>
<th>Mechanism</th>
</tr>
</thead>
<tbody>
<tr>
<td>Match state (10 Hz)</td>
<td>Too fast, must be local</td>
<td>Local <code>pg</code> on same pod (sticky placement)</td>
</tr>
<tr>
<td>Match input</td>
<td>Same pod as match</td>
<td>Direct <code>gen_statem:cast</code></td>
</tr>
<tr>
<td>Leaderboard flush</td>
<td>Already DB-backed</td>
<td>Local buffer → periodic <code>asobi_repo:insert</code></td>
</tr>
</tbody>
</table>
<h4 id="sticky-match-placement" tabindex="-1">Sticky Match Placement</h4>
<p>The matchmaker assigns a pod for each match. All matched players connect (or
get routed) to that pod. The match process, player sessions, and game tick
loop stay local — no cross-pod communication at 10 Hz.</p>
<p>The load balancer routes by match ID or a session cookie set during the
matchmaker flow.</p>
<h4 id="migrations" tabindex="-1">Migrations</h4>
<p>Run as a separate Kubernetes Job or init container before the deployment rolls
out. Do not race migrations across pods — use a single job with Kura's
advisory lock as a safety net.</p>
<h2 id="match-placement-same-node-vs-distributed" tabindex="-1">Match Placement: Same Node vs Distributed</h2>
<p><strong>Should all players in a match be on the same node?</strong></p>
<p>Yes, for real-time games. The match server ticks at 10 Hz and broadcasts state
to all players. If players are on different nodes:</p>
<ul>
<li><strong>Distributed Erlang:</strong> Works, but adds ~0.1-1ms per message hop. At 10 Hz
with 10 players on 3 nodes, that's 100 cross-node messages/second. Tolerable
for small clusters, but adds jitter.</li>
<li><strong>Cloud-native:</strong> Unacceptable without distributed Erlang. You'd need to
serialize state to Redis/NATS per tick, which adds latency and complexity.</li>
</ul>
<p><strong>Recommendation:</strong> Use sticky match placement. The matchmaker assigns a node,
all matched players connect (or get routed) to that node for the duration of the
match. This keeps the tight game loop local.</p>
<p><strong>For non-real-time features</strong> (leaderboards, chat, social, inventory): these
are request/response or low-frequency pub/sub. Cross-node or cross-pod
communication via the Shigoto fanout queue is fine.</p>
<h2 id="summary-which-model-when" tabindex="-1">Summary: Which Model When</h2>
<table>
<thead>
<tr>
<th>Scale</th>
<th>Model</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td>Dev / small prod</td>
<td>Single node</td>
<td>Simplest. Up to ~10K concurrent connections.</td>
</tr>
<tr>
<td>Medium (HA needed)</td>
<td>Distributed Erlang, 2-5 nodes</td>
<td>Add global matchmaker, global match registration. Sticky match placement.</td>
</tr>
<tr>
<td>Large / cloud-native</td>
<td>Independent pods + Shigoto/PG</td>
<td>Cross-pod events via Shigoto fanout queue. Sticky match placement. No Redis/NATS needed. Migration via job.</td>
</tr>
</tbody>
</table>
<p>The current codebase is designed for single-node. Moving to distributed Erlang
requires making the matchmaker cluster-aware (global registration or a shared
queue via <code>pg</code>). Moving to cloud-native requires only PostgreSQL — Shigoto
provides the durable fanout queue for cross-pod broadcast, and <code>pg</code> handles
local-node session routing. No additional infrastructure beyond what you
already have.</p>
"""}
    ]}.
