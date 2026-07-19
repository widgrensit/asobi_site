%% GENERATED from asobi guides/migrate-from-nakama.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_migrate_nakama_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-migrate-nakama", title => ~"Migrate from Nakama — Asobi docs"}, Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Migrate / Nakama"
        ]},
        {h1, [], [~"Migrating from Nakama self-host to asobi"]},
        {raw,
            ~"""
<p>You're running Nakama self-hosted on your own infra. It works. But maybe:</p>
<ul>
<li>You're tired of Nakama requiring <strong>CockroachDB</strong> (vs plain PostgreSQL
everywhere else in your stack)</li>
<li>You want <strong>hot-reload of Lua</strong> that doesn't drop sessions on deploy
(Nakama issue <a href="https://github.com/heroiclabs/nakama/issues/192">#192</a> has
been open since 2018)</li>
<li>You're bumping into <strong>spatial / MMO</strong> use cases Nakama wasn't designed
for</li>
<li>You prefer <strong>BEAM's fault-tolerance</strong> over Go's recovery-from-panic
model for a stateful realtime server</li>
<li>You want <strong>Apache-2</strong> without the BSL-adjacent ambiguity in some
Heroic Cloud components</li>
</ul>
<p>This guide walks you from a working Nakama deployment to an equivalent
asobi deployment. It's the most straightforward of the three migration
guides — Nakama and asobi are structurally the closest cousins in the
OSS backend space.</p>
<blockquote>
<p><strong>Draft notice.</strong> This guide is a starting point, not a playbook —
nobody has yet migrated a shipped Nakama title to asobi. The asobi-side
endpoints and events below are verified against the current code.
Nakama-side method names come from Nakama's public docs. <strong>Pair with us
in the <a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code> channel
if you hit an API gap.</strong></p>
</blockquote>
<h2 id="why-migrate-at-all" tabindex="-1">Why migrate at all</h2>
<p>Nakama is a fine product. We respect Heroic Labs. You should only migrate
if one of these reasons applies to you:</p>
<ul>
<li><strong>You need hot-reload.</strong> Editing a Lua runtime module in Nakama requires
a full server restart, which drops connections. asobi does it live via
Luerl module swap.</li>
<li><strong>Your infra is Postgres-only.</strong> Moving CockroachDB off your ops plate
is worth real money.</li>
<li><strong>You're building an MMO / large-world game.</strong> asobi has spatial zones,
lazy-zone loading, terrain chunks, and adaptive tick rates as first-class
primitives. Nakama's match handler is room-centric.</li>
<li><strong>You want truly-free OSS.</strong> Nakama is Apache-2 at the core but Heroic
Cloud has commercial-only components (Satori, Hiro) that ease adoption.
If you're committed to OSS-only, asobi is structurally simpler.</li>
</ul>
<p>If none of those apply, stay on Nakama. Honestly.</p>
<h2 id="concept-map" tabindex="-1">Concept map</h2>
<p>Nakama and asobi agree on most of the vocabulary:</p>
<table>
<thead>
<tr>
<th>Nakama</th>
<th>asobi</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Match</strong> (authoritative)</td>
<td>Match</td>
<td>Same: a BEAM/goroutine process owning state.</td>
</tr>
<tr>
<td><strong>Match handler</strong> (Lua / TS / Go)</td>
<td><code>asobi_match</code> behaviour / <code>match.lua</code></td>
<td>Callbacks: init, join, leave, handle_input, tick, get_state.</td>
</tr>
<tr>
<td><strong>Match Handler's LoopTick</strong></td>
<td><code>tick(state)</code></td>
<td>Same cadence (configurable).</td>
</tr>
<tr>
<td><strong>Parties</strong></td>
<td>Matchmaker tickets with <code>party</code> field</td>
<td>Send a list of player_ids in the ticket body.</td>
</tr>
<tr>
<td><strong>MatchmakerAdd</strong></td>
<td><code>POST /api/v1/matchmaker</code></td>
<td>Body: <code>{mode, properties, party}</code>.</td>
</tr>
<tr>
<td><strong>Storage Engine</strong></td>
<td><code>/api/v1/storage/:collection/:key</code></td>
<td>Collection+key+owner model is the same. Public/Owner/None permissions.</td>
</tr>
<tr>
<td><strong>Leaderboards</strong></td>
<td>Leaderboards (<code>/api/v1/leaderboards/:id</code>)</td>
<td>Submit/top/around queries.</td>
</tr>
<tr>
<td><strong>Tournaments</strong></td>
<td>Tournaments (<code>/api/v1/tournaments</code>)</td>
<td>Scheduled, entry fees, rewards.</td>
</tr>
<tr>
<td><strong>Friends</strong></td>
<td>Friends (<code>/api/v1/friends</code>)</td>
<td>Request/approve/block.</td>
</tr>
<tr>
<td><strong>Groups</strong></td>
<td>Groups (<code>/api/v1/groups</code>)</td>
<td>Roles, join/leave/kick.</td>
</tr>
<tr>
<td><strong>Chat channels</strong></td>
<td>Chat channels + WS <code>chat.send</code> / <code>chat.join</code></td>
<td>Per-channel history.</td>
</tr>
<tr>
<td><strong>Notifications</strong></td>
<td>Notifications (<code>/api/v1/notifications</code>)</td>
<td>Plus WS push.</td>
</tr>
<tr>
<td><strong>Wallets</strong></td>
<td>Economy wallets (<code>/api/v1/wallets</code>)</td>
<td>Multi-currency ledgers.</td>
</tr>
<tr>
<td><strong>Purchases</strong></td>
<td>Economy store (<code>/api/v1/store/purchase</code>)</td>
<td>Integrates with IAP verification.</td>
</tr>
<tr>
<td><strong>Authentication (Device / Custom)</strong></td>
<td><code>/api/v1/auth/guest</code></td>
<td>Create-or-resume anonymous accounts from a device-held secret; upgrade later with <code>/auth/guest/upgrade</code>. Maps directly to <code>AuthenticateDevice</code>/<code>AuthenticateCustom</code>.</td>
</tr>
<tr>
<td><strong>Authentication (Email)</strong></td>
<td><code>/api/v1/auth/register</code> + <code>/login</code></td>
<td>Username + password.</td>
</tr>
<tr>
<td><strong>Authentication (Google / Apple / Steam / ...)</strong></td>
<td><code>/api/v1/auth/oauth</code></td>
<td>OAuth/OIDC.</td>
</tr>
<tr>
<td><strong>RPC endpoints</strong></td>
<td>Nova controllers (Erlang) or Lua callbacks</td>
<td>For per-match logic, use Lua in <code>match.lua</code>. For cross-match workflows, write a Nova controller.</td>
</tr>
<tr>
<td><strong>Hooks (<code>before_authenticate</code>, <code>after_friendAdd</code>)</strong></td>
<td>Nova plugins + match lifecycle callbacks</td>
<td>Pre- and post-request middleware in Nova.</td>
</tr>
<tr>
<td><strong>Runtime Lua / TS / Go</strong></td>
<td>Luerl Lua (for match logic), Erlang/OTP (for the engine)</td>
<td>One scripting language (Lua); the engine is all OTP.</td>
</tr>
<tr>
<td><strong>Nakama Console</strong></td>
<td><a href="https://github.com/widgrensit/asobi_admin">asobi_admin</a></td>
<td>Pre-1.0 admin surface.</td>
</tr>
<tr>
<td><strong><code>sessiontoken</code></strong></td>
<td><code>session_token</code></td>
<td>Same concept, returned from <code>/register</code> or <code>/login</code>.</td>
</tr>
<tr>
<td><strong>WebSocket</strong></td>
<td><code>/ws</code> with <code>session.connect</code> first frame</td>
<td>See the Hathora guide's <a href="https://hexdocs.pm/asobi/migrate-from-hathora.html#websocket-handshake">WebSocket handshake</a> section for the protocol.</td>
</tr>
</tbody>
</table>
<h2 id="migration-path" tabindex="-1">Migration path</h2>
<h3 id="phase-1-stand-up-asobi-alongside-nakama-05-days" tabindex="-1">Phase 1 — stand up asobi alongside Nakama (0.5 days)</h3>
<pre><code class="language-yaml"># docker-compose.yml
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: my_game

  asobi:
    image: ghcr.io/widgrensit/asobi_lua:latest
    depends_on: [postgres]
    ports: [&quot;8084:8084&quot;]
    volumes: [&quot;./lua:/app/game:ro&quot;]
    environment:
      ASOBI_DB_HOST: postgres
      ASOBI_DB_NAME: my_game
</code></pre>
<p>Note: plain PostgreSQL, no CockroachDB. If you currently run Nakama
against Postgres-compatible Cockroach, you already have a backup strategy
that works here.</p>
<h3 id="phase-2-port-the-lua-runtime-1-3-days" tabindex="-1">Phase 2 — port the Lua runtime (1-3 days)</h3>
<p>Nakama's Lua API:</p>
<pre><code class="language-lua">local nk = require(&quot;nakama&quot;)
local function foo(context, payload)
  nk.logger_info(&quot;hello&quot;)
  local users = nk.storage_read({...})
  return nk.json_encode({ok = true})
end
nk.register_rpc(foo, &quot;my_rpc&quot;)
</code></pre>
<p>asobi's Lua API differs in key ways — the match is the first-class unit,
not an RPC:</p>
<pre><code class="language-lua">-- match.lua
match_size = 2

function init(_config)
  return { players = {} }
end

function join(player_id, state)
  state.players[player_id] = { score = 0 }
  return state
end

function handle_input(player_id, input, state)
  if input.type == &quot;score&quot; then
    local p = state.players[player_id]
    p.score = p.score + 1
    game.broadcast(&quot;score&quot;, { player = player_id, score = p.score })
  end
  return state
end
</code></pre>
<p>For cross-match logic (leaderboards, global state, scheduled jobs):</p>
<ul>
<li><code>game.leaderboard.submit(&quot;global&quot;, player_id, score)</code> in Lua</li>
<li>Shigoto background jobs in Erlang for scheduled cross-match workflows</li>
<li>Nova controllers in Erlang for custom REST endpoints (equivalent to
Nakama RPCs)</li>
</ul>
<p>If you have a lot of RPC-shaped logic (not per-match), budget Phase 2 for
closer to a week.</p>
<h3 id="phase-3-migrate-the-storage-schema-1-2-days" tabindex="-1">Phase 3 — migrate the storage schema (1-2 days)</h3>
<pre><code class="language-bash"># Export from Nakama's Postgres (or CockroachDB):
pg_dump -U nakama -t storage -d nakama &gt; storage-export.sql

# Transform storage rows to asobi's asobi_storage schema
psql -U postgres -d my_game -c &quot;
  INSERT INTO asobi_storage (player_id, collection, key, value, permissions)
  SELECT user_id::uuid, collection, key, value::jsonb, 'owner'
  FROM old_nakama_storage;
&quot;
</code></pre>
<p>The same pattern applies to leaderboards, friends, groups, and wallets.
Column names differ slightly (see the <a href="https://hexdocs.pm/asobi">Kura schemas</a>
for the target shape) but the data is 1:1 translatable.</p>
<h3 id="phase-4-port-the-client-2-5-days" tabindex="-1">Phase 4 — port the client (2-5 days)</h3>
<p>Nakama client SDKs and asobi client SDKs map cleanly:</p>
<table>
<thead>
<tr>
<th>Nakama SDK</th>
<th>asobi SDK</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>nakama-unity</code></td>
<td><a href="https://github.com/widgrensit/asobi-unity">asobi-unity</a></td>
</tr>
<tr>
<td><code>nakama-godot</code></td>
<td><a href="https://github.com/widgrensit/asobi-godot">asobi-godot</a></td>
</tr>
<tr>
<td><code>nakama-defold</code></td>
<td><a href="https://github.com/widgrensit/asobi-defold">asobi-defold</a></td>
</tr>
<tr>
<td><code>nakama-unreal</code></td>
<td><a href="https://github.com/widgrensit/asobi-unreal">asobi-unreal</a></td>
</tr>
<tr>
<td><code>nakama-js</code></td>
<td><a href="https://github.com/widgrensit/asobi-js">asobi-js</a></td>
</tr>
</tbody>
</table>
<p>The Unity example:</p>
<pre><code class="language-csharp">// Before (Nakama)
var client = new Client(&quot;defaultkey&quot;, &quot;127.0.0.1&quot;, 7350, false);
var session = await client.AuthenticateCustomAsync(deviceId);
var socket = client.NewSocket();
await socket.ConnectAsync(session);

// After (asobi) - guest auth is the direct AuthenticateCustom/Device equivalent
var client = new AsobiClient(&quot;https://api.my-game.com&quot;);
await client.Auth.GuestAsync(deviceId, deviceSecret);   // POST /auth/guest, create-or-resume
await client.WebSocket.ConnectAsync();
client.WebSocket.SendSessionConnect(client.Session.Token);
</code></pre>
<h3 id="phase-5-cut-over-1-day" tabindex="-1">Phase 5 — cut over (1 day)</h3>
<p>Flip the client's base URL via a feature flag. Monitor for 24h. Shut
down the Nakama server.</p>
<h2 id="things-nakama-has-that-asobi-doesnt-yet" tabindex="-1">Things Nakama has that asobi doesn't (yet)</h2>
<ul>
<li><strong>Satori</strong> (LiveOps platform). asobi's LiveOps story is rougher.</li>
<li><strong>Hiro</strong> (progression system). asobi has tournaments, seasons, and
phases but nothing as opinionated as Hiro.</li>
<li><strong>Go and TypeScript runtimes</strong> as alternatives to Lua. asobi is Lua or
Erlang — no JS/TS runtime.</li>
<li><strong>Nakama Console</strong> is further along than asobi_admin today.</li>
<li><strong>Published case studies from AAA studios.</strong> asobi is newer.</li>
</ul>
<p>If you're deeply reliant on Satori, you'll need to build the equivalent
in asobi or accept the feature loss.</p>
<h2 id="things-asobi-has-that-nakama-doesnt" tabindex="-1">Things asobi has that Nakama doesn't</h2>
<ul>
<li><strong>Hot-reload Lua</strong> — the <a href="https://github.com/heroiclabs/nakama/issues/192">Nakama issue #192</a>
that's been open since 2018</li>
<li><strong>Plain PostgreSQL</strong> — no CockroachDB requirement</li>
<li><strong>Spatial zones / terrain</strong> — purpose-built for large-world games</li>
<li><strong>Built-in voting</strong> (plurality / ranked / approval / weighted)</li>
<li><strong>Phases and seasons</strong> as first-class primitives</li>
<li><strong>Per-match process isolation</strong> via OTP supervision — crashes never
leak between matches, no shared GC pauses</li>
</ul>
<h2 id="cost-comparison" tabindex="-1">Cost comparison</h2>
<p>Self-hosted Nakama and self-hosted asobi have similar infrastructure
costs at the low end. The main operational difference:</p>
<table>
<thead>
<tr>
<th></th>
<th>Nakama self-host</th>
<th>asobi self-host</th>
</tr>
</thead>
<tbody>
<tr>
<td>Database</td>
<td>CockroachDB (3-node recommended)</td>
<td>PostgreSQL (1 node is fine)</td>
</tr>
<tr>
<td>Hot ops</td>
<td>Restart on deploy</td>
<td>Live module swap</td>
</tr>
<tr>
<td>Clustering</td>
<td>Nakama's cluster mode + Consul</td>
<td>OTP <code>pg</code> / distributed Erlang</td>
</tr>
<tr>
<td>Typical idle cost</td>
<td>€30-60/mo (Cockroach is memory-hungry)</td>
<td>€5-15/mo</td>
</tr>
</tbody>
</table>
<p>If you're already running Postgres for other services, consolidating onto
one DB flavour is a meaningful win.</p>
<h2 id="do-this-today" tabindex="-1">Do this today</h2>
<ul>
<li>[ ] <code>git clone</code> <a href="https://github.com/widgrensit/asobi_lua">asobi_lua</a>,
<code>docker compose up</code>, register a test player.</li>
<li>[ ] Port one Nakama RPC or match handler to <code>match.lua</code>. Compare the
feel.</li>
<li>[ ] Join the <a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code>
channel — tell us what your Lua runtime does and we'll sketch the port.</li>
</ul>
<h2 id="getting-help" tabindex="-1">Getting help</h2>
<ul>
<li><strong>Discord</strong>: <a href="https://discord.gg/vYSfYYyXpu">#migrations</a> channel</li>
<li><strong>Email</strong>: hello@asobi.dev</li>
<li><strong>GitHub Discussions</strong>: <a href="https://github.com/widgrensit/asobi_lua/discussions">widgrensit/asobi_lua/discussions</a></li>
</ul>
<h2 id="see-also" tabindex="-1">See also</h2>
<ul>
<li><a href="https://hexdocs.pm/asobi/migrate-from-hathora.html">Migrating from Hathora</a></li>
<li><a href="https://hexdocs.pm/asobi/migrate-from-playfab.html">Migrating from PlayFab</a></li>
<li><a href="https://hexdocs.pm/asobi/exit.html">Exit guarantee</a></li>
<li><a href="https://hexdocs.pm/asobi/comparison.html">Comparison vs Nakama, Colyseus, SpacetimeDB</a></li>
</ul>
"""}
    ]}.
