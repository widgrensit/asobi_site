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
<h2 id="what-a-node-is" tabindex="-1">What a node is</h2>
<p>An asobi node is a single Erlang/OTP release holding the game backend, the Lua
runtime and the operator console. There is no separate scripting service and no
separate admin service. The image is <code>ghcr.io/widgrensit/asobi</code> and the release
binary inside it is <code>bin/asobi</code> (<code>Dockerfile:75</code>).</p>
<p>Two front doors onto the same node:</p>
<ul>
<li>Run the image and write Lua. <code>match.lua</code> or a <code>config.lua</code> manifest is loaded
at boot and drives matches, worlds and bots.</li>
<li>Depend on the Hex package and write Erlang. Implement the <code>asobi_match</code>
behaviour and register the module under <code>game_modes</code>.</li>
</ul>
<p>Both reach the same processes, the same database and the same console.</p>
<h2 id="supervision-tree" tabindex="-1">Supervision tree</h2>
<p><code>asobi_sup</code> is <code>one_for_one</code>, 10 restarts in 60 seconds
(<code>src/asobi_sup.erl:16-20</code>). Nineteen children, in this order
(<code>src/asobi_sup.erl:21-41</code>):</p>
<pre><code>asobi_sup (one_for_one)
├── asobi_rate_limits             temporary; registers the seki limiter buckets
├── asobi_oidc_providers          temporary; starts OIDC workers only if providers are configured
├── asobi_auth_cache              per-node bearer-token cache
├── asobi_cluster                 node discovery; returns `ignore` unless `cluster` is set
├── asobi_player_session_sup      simple_one_for_one
│   └── asobi_player_session      one per connected socket
├── asobi_match_sup               simple_one_for_one; owns the asobi_match_state table
│   └── asobi_match_server        one per match (gen_statem)
├── asobi_world_sup               owns asobi_world_state and asobi_player_worlds
│   ├── asobi_zone_snapshotter
│   ├── asobi_world_registry
│   └── asobi_world_instance_sup  simple_one_for_one
│       └── asobi_world_instance  one_for_all: zone sup, zone manager, ticker, world server
├── asobi_world_lobby_server      serialises asobi_world_lobby:find_or_create/1
├── asobi_vote_sup                simple_one_for_one
│   └── asobi_vote_server         one per open vote
├── asobi_matchmaker              the queue; ticks itself
├── asobi_leaderboard_sup         simple_one_for_one
│   └── asobi_leaderboard_server  one per board
├── asobi_chat_sup                simple_one_for_one; owns the channel registry table
│   └── asobi_chat_channel        one per live channel
├── asobi_tournament_sup          simple_one_for_one
│   └── asobi_tournament_server   registered under `global`
├── asobi_presence                online set and delivery targets, over pg
├── asobi_guest_reaper            opt-in sweep of unclaimed guest accounts
├── asobi_console_session         console session table; started whether or not the console is on
├── asobi_lua_config              temporary; loads the game config
├── asobi_lua_sup
│   ├── asobi_lua_rate_limits     temporary; `game.log` budgets
│   ├── asobi_bot_sup
│   ├── asobi_bot_spawner
│   └── asobi_lua_config_watcher
└── asobi_extension_sup           one child group per installed extension
</code></pre>
<p>The last three entries are ordered deliberately and the order is load-bearing:
core children, then the Lua config load, then the Lua children, then extensions
(<code>src/asobi_sup.erl:44-52</code>). The Lua runtime used to be its own OTP
application, which started after <code>asobi</code> and therefore loaded the game config
after every <code>asobi_sup</code> child was already up. Moving the load earlier changes
what a core child that reads configuration at <code>start_link/0</code> sees at boot, so
it stays here and the old order is preserved exactly.</p>
<p>A game config that fails to load aborts the boot. <code>load_lua_game_config/0</code>
raises, which arrives as a supervisor <code>failed_to_start_child</code> and takes the
already-started core children down with it (<code>src/asobi_sup.erl:60-72</code>). A node
with an unloadable game config has nothing useful to serve.</p>
<p><code>asobi_extension_sup</code> is last so an extension's processes start after every
core service they might call. With no extensions installed it is one idle
supervisor with no children (<code>src/asobi_sup.erl:81-89</code>).</p>
<p><code>asobi_rate_limits</code> is a temporary registration child, not a server: it calls
<code>seki:new_limiter/2</code> once per bucket and returns <code>ignore</code>
(<code>src/asobi_sup.erl:217-305</code>). The buckets themselves live in seki, in memory,
per node - ten of them, covering auth, register, iap, api, ws_connect, join,
guest_global, script_log, rehome and rehome_global.</p>
<h2 id="session-lifecycle" tabindex="-1">Session lifecycle</h2>
<p>One <code>asobi_player_session</code> process per connection, started when the socket
sends <code>session.connect</code> and stopped when the socket closes
(<code>src/ws/asobi_ws_handler.erl:356-370</code>). A session does not survive the
connection. A client that reconnects presents the same token and gets a new
session process.</p>
<pre><code>Client              WS handler           Session              pg
  │                     │                   │                  │
  │─ WS connect ───────►│                   │                  │
  │─ session.connect ──►│                   │                  │
  │                     │ resolve_token     │                  │
  │                     │─ start_session ──►│                  │
  │                     │                   │─ join {player,Id}►│
  │◄ session.connected ─│                   │                  │
  │     ... play ...    │                   │                  │
  │─ disconnect ───────►│                   │                  │
  │                     │─ stop ───────────►│                  │
  │                     │                   │─ leave ─────────►│
</code></pre>
<p>The token is resolved once, at <code>session.connect</code>. After that the <code>player_id</code>
lives in process state and no further lookup happens on the hot path. The
session monitors the WebSocket process, and <code>terminate/3</code> calls
<code>asobi_player_session:stop/1</code> for the other direction.</p>
<h3 id="the-auth-cache" tabindex="-1">The auth cache</h3>
<p>Bearer tokens are opaque 32 random bytes issued by <code>nova_auth</code> and stored in
<code>player_tokens</code> (<code>src/asobi_auth.erl:6-18</code>,
<code>src/migrations/m20260329095708_update_schema.erl:185</code>). They are not JWTs, so
resolving one is a database read, and both the HTTP plugin and the WebSocket
handler go through a per-node ETS cache to avoid doing it per request
(<code>src/plugins/asobi_auth_plugin.erl:11</code>, <code>src/ws/asobi_ws_handler.erl:914</code>).</p>
<p>Entries expire after <code>auth_cache_ttl_ms</code>, default 60000 ms; negative results
expire after <code>auth_cache_negative_ttl_ms</code>, default 5000 ms
(<code>src/auth/asobi_auth_cache.erl:94-95</code>). That TTL is the bound on revocation
latency: a token revoked through <code>asobi_auth_tokens</code> or
<code>asobi_auth_cache:revoke_player/1</code> is invalidated immediately on the node that
did it, and everywhere else within the TTL. Access tokens are valid for 60
minutes and refresh tokens for 30 days, both <code>nova_auth</code> defaults
(<code>src/asobi_auth.erl:15</code>).</p>
<p>The cache is per node. Nothing replicates it.</p>
<h2 id="session-revocation" tabindex="-1">Session revocation</h2>
<pre><code class="language-erlang">asobi_presence:revoke_session(PlayerId, ~&quot;banned&quot;).
</code></pre>
<p><code>revoke_session/2</code> enqueues a job on the <code>broadcast</code> fanout queue
(<code>src/social/asobi_presence.erl:121-123</code>). Every node consumes the fanout
queue, and <code>asobi_broadcast_worker:perform/1</code> calls
<code>asobi_presence:disconnect/2</code> locally, which looks the player up in the local
<code>pg</code> group and sends <code>{session_revoked, Reason}</code> to each session process
(<code>src/workers/asobi_broadcast_worker.erl:24-25</code>).</p>
<p><code>asobi_broadcast_worker</code> is the only worker asobi ships, and it handles exactly
three job types: <code>session_revoked</code>, <code>notification</code> and <code>chat</code>. Anything else
logs <code>unknown_broadcast_type</code> and returns ok.</p>
<p>Fanout jobs are ephemeral - a 120 second window in the dev config
(<code>config/dev_sys.config.src</code>), auto-pruned. The database is the source of
truth; the fanout is a best-effort push.</p>
<h2 id="match-lifecycle" tabindex="-1">Match lifecycle</h2>
<p><code>asobi_match_server</code> is a <code>gen_statem</code> under <code>asobi_match_sup</code>
(<code>src/matches/asobi_match_server.erl:60-62</code>,
<code>src/matches/asobi_match_sup.erl:22-33</code>). States are <code>waiting</code>, <code>running</code>,
<code>paused</code> and <code>finished</code>; a cancellation is a transition to <code>finished</code> with a
<code>cancelled</code> result, not a state of its own.</p>
<pre><code>Matchmaker           Match sup         Match server        Players (pg)
  │                     │                   │                   │
  │─ start_match(Cfg)──►│                   │                   │
  │                     │─ start_link ─────►│ waiting           │
  │─ join(Pid, P1) ────────────────────────►│                   │
  │─ join(Pid, P2) ────────────────────────►│ running           │
  │                     │                   │◄─ {input, ...} ───│
  │                     │                   │── tick ───────────│
  │                     │                   │── broadcast ─────►│
  │                     │                   │ finished          │
  │                     │                   │── persist ───────►DB
</code></pre>
<p>Server-authoritative: the match process owns all game state, clients send
inputs, the server applies them on the tick and broadcasts the result. The tick
is a <code>state_timeout</code>, default 100 ms
(<code>src/matches/asobi_match_server.erl:47,200</code>).</p>
<p>The game module implements the <code>asobi_match</code> behaviour. Only <code>init/1</code> and
exactly one of <code>get_state/2</code> (per player) or <code>get_state/1</code> (shared,
broadcast-once) are required; everything else is optional, including
<code>join/2</code>, <code>join/3</code>, <code>leave/2</code>, <code>handle_input/3</code>, <code>tick/1</code>, <code>vote_requested/1</code>,
<code>vote_resolved/3</code>, <code>phases/1</code>, <code>on_phase_started/2</code> and <code>on_phase_ended/2</code>
(<code>src/matches/asobi_match.erl:30-128</code>). See
<a href="/docs/performance">Performance tuning</a> for when the shared form pays.</p>
<h3 id="finding-a-match" tabindex="-1">Finding a match</h3>
<p>A match joins the <code>pg</code> group <code>{asobi_match_server, MatchId}</code> in <code>nova_scope</code>
when it starts, and <code>asobi_match_server:whereis/1</code> resolves through that group
(<code>src/matches/asobi_match_server.erl:152-156,167</code>). Because <code>pg</code> replicates
within a scope across connected nodes, a match pid is resolvable from any node
in the cluster. The process itself does not move, and its 10 Hz broadcast stays
where it is. Nothing registers matches under <code>global</code>. Tournament
servers do: <code>asobi_tournament_server</code> starts as
<code>{global, {asobi_tournament_server, TournamentId}}</code>
(<code>src/tournaments/asobi_tournament_server.erl:10</code>).</p>
<p><code>asobi_match_state</code> is a separate thing and is often misread as the registry.
It is a node-local public ETS table owned by <code>asobi_match_sup</code>
(<code>src/matches/asobi_match_sup.erl:12</code>) into which a match writes a
pid-stripped snapshot of its state, so a crashed match restarted by its
supervisor on the same node resumes rather than starting empty
(<code>src/matches/asobi_match_server.erl:948-968</code>). It is a crash-recovery buffer,
it is per node, and it does not survive the node.</p>
<h2 id="matchmaker" tabindex="-1">Matchmaker</h2>
<p>One <code>asobi_matchmaker</code> gen_server per node. It ticks itself with
<code>erlang:send_after/3</code> - once in <code>init/1</code> and once at the end of every tick
handler (<code>src/matches/asobi_matchmaker.erl:217,342</code>). The default interval is
1000 ms and the default wait before a ticket expires is 60 seconds, both under
the <code>matchmaker</code> key as <code>tick_interval</code> and <code>max_wait_seconds</code>.</p>
<p>Tickets are a plain map in the gen_server's own state
(<code>src/matches/asobi_matchmaker.erl:229,236-270</code>). There is no ticket table, no
ticket schema and nothing persisted: the queue dies with the node, and a
player queued against one node can never be matched with a player queued
against another. Plan for that before you run more than one node - see
<a href="/docs/clustering">Clustering</a>.</p>
<p>One live ticket per player <em>per mode</em>. Re-adding while already queued for the
same mode returns the existing ticket rather than minting a second, so a
double-tapped &quot;find match&quot; cannot fill one player into a self-match
(<code>src/matches/asobi_matchmaker.erl:246-252</code>). A player may hold tickets in two
different modes at once.</p>
<p>Grouping is a strategy module - <code>fill</code> (first-come, first-served) and
<code>skill_based</code> (expanding window) ship. There is no query language and no region
concept; filtering beyond <code>mode</code> happens inside your strategy against the
ticket's <code>properties</code> map. When a group fills, the matchmaker starts the match
through <code>asobi_match_sup</code> on its own node.</p>
<h2 id="lua-subsystem" tabindex="-1">Lua subsystem</h2>
<p>The Lua runtime is fifteen modules under <code>src/lua/</code> plus the bot modules. It is
not a wrapper around asobi; it is part of it.</p>
<p><strong>Registration.</strong> <code>asobi_app:start/2</code> calls
<code>asobi_lua_sup:register_game_modes/0</code> before the supervision tree comes up,
which registers <code>asobi_lua_match</code>, <code>asobi_lua_match_shared</code> and
<code>asobi_lua_world</code> as the providers for the three Lua mode kinds
(<code>src/asobi_app.erl:14,41-42</code>, <code>src/lua/asobi_lua_sup.erl:16-20</code>). Without that
registration every <code>{lua, Script}</code> mode resolves to
<code>{error, lua_runtime_unavailable}</code> (<code>src/asobi_game_modes.erl:92-100</code>). This is
what makes a Lua mode resolvable at all, and it happens ahead of every
<code>asobi_sup</code> child including the matchmaker.</p>
<p><strong>Config load.</strong> <code>asobi_lua_config:maybe_load_game_config/0</code> reads either a
single <code>match.lua</code> or a <code>config.lua</code> manifest mapping mode names to script
paths (<code>src/lua/asobi_lua_config.erl:5-20</code>). If neither file exists it is a
no-op, so an Erlang project that configures modes in <code>sys.config</code> is
unaffected. If a file exists and is broken, the boot fails - fail-closed, as
described under the supervision tree above.</p>
<p><strong>Loader and sandbox.</strong> <code>asobi_lua_loader</code> builds the Luerl state and clears
every dangerous standard-library entry point: <code>os.execute</code>, <code>os.exit</code>,
<code>os.getenv</code>, <code>os.remove</code>, <code>os.rename</code>, <code>os.tmpname</code>, the whole of <code>io</code>,
<code>dofile</code>, <code>loadfile</code>, <code>load</code>, <code>loadstring</code>, and the whole of <code>package</code>
(<code>src/lua/asobi_lua_loader.erl:1-31</code>). <code>package</code> is replaced by a controlled
<code>require/1</code> that resolves names relative to the loaded script's directory and
rejects parent traversal and absolute paths. <code>init_sandboxed/0</code> gives a
hardened state with no script attached, used for evaluating a <code>config.lua</code>
manifest; <code>new/1</code> loads a script and pins its base directory. The API surface a
script sees is <code>asobi_lua_api</code> and <code>asobi_lua_surface</code>; see
<a href="https://hexdocs.pm/asobi/lua-api.html">Lua API</a>.</p>
<p><strong>Configuration keys.</strong> The runtime's own keys go through
<code>asobi_lua_env:get_env/2</code> (<code>src/lua/asobi_lua_env.erl:22-32</code>), which reads
<code>asobi_lua</code> before <code>asobi</code> so a <code>sys.config</code> written against the old separate
application did not become dead config at the merge. See
<a href="/docs/configuration#which-application-key">Which application key</a>.</p>
<h2 id="world-and-zone-subsystem" tabindex="-1">World and zone subsystem</h2>
<p>Twenty-two modules under <code>src/world/</code>. A world is long-lived, partitioned into
zones on a grid, and ticked by its own process.</p>
<p><code>asobi_world_instance</code> is a <code>one_for_all</code> supervisor per world holding a zone
supervisor, a zone manager, a ticker and the world server, started in that
order because the world server discovers the others through the supervisor
(<code>src/world/asobi_world_instance.erl:30-78</code>). One world therefore lives entirely
on one node: its server, its ticker and every one of its zone processes are
children of one supervisor tree on one BEAM. Worlds do not migrate.</p>
<p>The world server joins the <code>pg</code> group <code>{asobi_world_server, WorldId}</code> so a
world is discoverable from any connected node
(<code>src/world/asobi_world_server.erl:174,187</code>). Two node-local public ETS tables
back it: <code>asobi_world_state</code>, holding zone entity snapshots, and
<code>asobi_player_worlds</code>, mapping a player to the world they are in
(<code>src/world/asobi_world_sup.erl:26-36</code>). Both are node-local, and both are
<code>public</code>, which is an explicit trust boundary - anything running in the same
BEAM can read and write them, and a sandboxed runtime layered on top must keep
its sandbox out of them.</p>
<p>See <a href="/docs/world-server">World server</a> and <a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a>.</p>
<h2 id="leaderboards" tabindex="-1">Leaderboards</h2>
<p>One <code>asobi_leaderboard_server</code> per board, hydrating its ETS tables from
<code>leaderboard_entries</code> before it accepts reads
(<code>src/leaderboards/asobi_leaderboard_server.erl:120-122</code>).</p>
<p>The ETS table is an <code>ordered_set</code> keyed on <code>{-Score, PlayerId}</code>, so iteration
order is rank order (<code>src/leaderboards/asobi_leaderboard_server.erl:138-168</code>).
<code>sub_score</code> is written to the database as 0 and takes no part in ordering
(<code>src/leaderboards/asobi_leaderboard_server.erl:362</code>); it exists as a column,
not as a tiebreak.</p>
<p>A 30 second timer inside the board process flushes dirty players to Postgres
(<code>src/leaderboards/asobi_leaderboard_server.erl:123,177,180</code>). Each flush
upserts only the players that changed since the last one; a player whose write
fails stays pending and is retried. <code>terminate/2</code> flushes, so a clean restart
does not lose scores.</p>
<p>The exported API is <code>submit/3</code>, <code>top/2</code>, <code>rank/2</code>, <code>around/3</code> and
<code>live_boards/0</code> (<code>src/leaderboards/asobi_leaderboard_server.erl:6</code>). There is
no <code>reset/0</code>, no archive table and no scheduled reset. Time-scoped boards are
something you build with separate board ids.</p>
<h2 id="chat" tabindex="-1">Chat</h2>
<p>One <code>asobi_chat_channel</code> process per live channel, members tracked in the <code>pg</code>
group <code>{chat, ChannelId}</code>. A send fans out to the group's members and then
inserts the row inline, in the same <code>handle_cast</code>
(<code>src/social/asobi_chat_channel.erl:131-137,204-219</code>). There is no batching job
and no async persist queue. Channel types and who may reach them are in
<code>asobi_chat_acl</code>.</p>
<h2 id="presence" tabindex="-1">Presence</h2>
<p><code>asobi_presence</code> records two separate things: the delivery target for a player
and membership of the online set. <code>track/2</code> records both; <code>track_bot/2</code> records
only the delivery target, so bots receive broadcasts without counting toward
<code>online_count/0</code> (<code>src/social/asobi_presence.erl:15</code>). Status changes go out
over <code>nova_pubsub</code>, not the fanout queue.</p>
<p>Everything <code>asobi_presence:send/2</code> delivers is one of the shapes in
<code>t:asobi_presence:message/0</code>.</p>
<h2 id="extensions-and-the-rpc-seam" tabindex="-1">Extensions and the RPC seam</h2>
<p>An extension is an OTP application listed in the release that declares a
manifest. <code>asobi_extension_sup</code> starts one child group per installed extension,
last in the tree. Extensions contribute no routes.</p>
<p>Clients reach an extension over the WebSocket, through one frame type:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;rpc.call&quot;, &quot;cid&quot;: &quot;c-1&quot;,
 &quot;payload&quot;: {&quot;protocol&quot;: 1, &quot;method&quot;: &quot;shop.buy&quot;, &quot;params&quot;: {&quot;sku&quot;: &quot;hat&quot;}}}
</code></pre>
<p>The reply is <code>rpc.ok</code> with a <code>result</code>, or <code>rpc.error</code> with the standard error
object:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;rpc.ok&quot;,    &quot;cid&quot;: &quot;c-1&quot;, &quot;payload&quot;: {&quot;result&quot;: {&quot;reward&quot;: 100}}}
{&quot;type&quot;: &quot;rpc.error&quot;, &quot;cid&quot;: &quot;c-1&quot;, &quot;payload&quot;: {&quot;error&quot;: {&quot;code&quot;: &quot;...&quot;, &quot;message&quot;: &quot;...&quot;, &quot;details&quot;: {}}}}
</code></pre>
<p><code>cid</code> is required on <code>rpc.call</code> and validated, unlike the rest of the socket
where it is optional - it is the only way a client pairs a reply with the call
it made, and it is bounded and checked rather than reflected unchanged. A
rejected <code>cid</code> is not echoed back (<code>src/extensions/asobi_rpc.erl:12-25,118-128</code>).
Every client SDK speaks this. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</p>
<h2 id="ops-plane-and-console" tabindex="-1">Ops plane and console</h2>
<p>The node serves an operator console at <code>/console</code> and an ops HTTP API at
<code>/api/v1/ops/*</code>, on the same listener as the game
(<code>src/asobi_router.erl:25-26,214,282</code>).</p>
<p>The two are gated separately. <code>/console</code> needs <code>console</code> to be true; the ops
routes are always mounted and reject everything until an <code>ops_secret</code> is
configured, so a stock node serves neither. <a href="https://hexdocs.pm/asobi/console.html">Operator console</a> owns
the detail.</p>
<p>Every ops route carries a capability class - <code>read</code>, <code>player_data</code>, <code>config</code>
or <code>erasure</code> (<code>src/ops/asobi_ops_caps.erl</code>) - and the class is the only thing
that authorises the call. Core's routes are reads apart from two:
<code>GET /api/v1/ops/players/:id/export</code> (<code>player_data</code>) and
<code>POST /api/v1/ops/players/:id/erase</code> (<code>erasure</code>). The third mutating route is
<code>/api/v1/ops/ext/:extension/:action</code>, whose behaviour comes from an installed
extension.</p>
<p><code>erasure</code> is its own class because it is the only irreversible one, and a
console session is granted every class but that one by default
(<code>src/console/asobi_console_session.erl</code>).</p>
<p>The console holds no privileged path into the database. It reads the ops plane
over HTTP like any other client. It was previously a separate project,
<code>asobi_admin</code>, which read the same database directly; that is archived, because
a second deployment to secure and keep in step was the wrong shape for
something an operator opens during an incident.</p>
<h2 id="database-and-migrations" tabindex="-1">Database and migrations</h2>
<p>Each node runs its own pgo pool through Kura. Migrations are Erlang modules in
<code>src/migrations/</code> and run at application start, before the supervision tree,
via <code>kura_migrator:migrate(asobi_repo)</code> (<code>src/asobi_app.erl:16-22</code>).</p>
<ul>
<li>All operations in one migration run in a single PostgreSQL transaction under
an advisory lock, so only one node migrates at a time and the rest wait. Safe
for a rolling deploy.</li>
<li>Kura topologically sorts <code>create_table</code> operations by foreign-key dependency,
so ordering within a migration file does not matter.</li>
<li>Never edit or delete an applied migration. Add an <code>alter_table</code> migration.</li>
<li>A failed migration logs <code>migration_failed</code> and the node carries on starting,
but <code>asobi_readiness:mark_ready/0</code> is not called - the node comes up and
reports itself unready rather than dying.</li>
</ul>
<h2 id="running-more-than-one-node" tabindex="-1">Running more than one node</h2>
<p>Everything above describes one node, which is the shape asobi is designed
around: a match lives on one node, a world lives on one node, and neither
migrates.</p>
<p><a href="/docs/clustering">Clustering</a> is the single source of truth for what is and is
not cluster-safe, and holds the complete list of per-node state. Do not infer
it from this page. Before you go further, four facts about a node that shape
every clustering decision:</p>
<ul>
<li>The matchmaker queue and its tickets are in one gen_server's state, per node,
never persisted.</li>
<li>The console session store and its CSRF secret are per node and per boot.</li>
<li>Rate-limit buckets and the auth cache are per node.</li>
<li>Matches and worlds are pinned to the node that started them.</li>
</ul>
<p>Postgres is shared, so everything persistent is consistent across nodes.
<code>pg</code>-scoped lookups - presence, chat, match and world <code>whereis</code> - resolve
across connected nodes.</p>
<p>Sticky routing, where you need it, is a load-balancer configuration you own.
asobi does not implement placement, does not assign nodes, and sets no cookie
for it; the only cookies in the codebase are the console's
(<code>src/console/asobi_console_session.erl</code>).</p>
"""}
    ]}.
