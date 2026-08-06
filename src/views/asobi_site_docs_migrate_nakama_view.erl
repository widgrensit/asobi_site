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
<p>You run Nakama self-hosted on your own infrastructure. It works. Migrate only
if one of these applies:</p>
<ul>
<li>You want hot-reload of Lua that does not drop sessions on deploy. Editing a
Nakama runtime module means restarting the server.</li>
<li>You are hitting spatial or large-world use cases. asobi has zones, terrain
chunks and adaptive tick rates as first-class primitives; Nakama's match
handler is room-centric.</li>
<li>You prefer the BEAM's supervision model over recovering from panics in a
stateful realtime server.</li>
<li>You want a single Apache-2.0 codebase with no commercial-only companions.</li>
</ul>
<p>If none of those apply, stay on Nakama. Nakama and asobi are structurally the
closest cousins in this space, which makes the port straightforward and also
makes it pointless without a reason.</p>
<p>Nobody has migrated a shipped Nakama title to asobi yet. The asobi-side
endpoints and events below are verified against this repository; the
Nakama-side names come from Nakama's public documentation. Pair with us in the
<a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code> channel if you hit a
gap.</p>
<h2 id="what-asobi-is" tabindex="-1">What asobi is</h2>
<p>One Erlang/OTP node containing the game backend, the Lua runtime and the
operator console. Two ways in: run <code>ghcr.io/widgrensit/asobi</code> and write Lua, or
depend on the Hex package and write Erlang. Same node either way.</p>
<h2 id="concept-map" tabindex="-1">Concept map</h2>
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
<td>Match (authoritative)</td>
<td>Match</td>
<td>A process owning state, one per match.</td>
</tr>
<tr>
<td>Match handler</td>
<td><code>match.lua</code>, or the <code>asobi_match</code> behaviour</td>
<td>Callbacks: <code>init</code>, <code>join</code>, <code>leave</code>, <code>handle_input</code>, <code>tick</code>, <code>get_state</code>.</td>
</tr>
<tr>
<td>Match handler loop tick</td>
<td><code>tick(state)</code></td>
<td>Matches tick every 100ms and that is fixed. <code>tick_rate</code> is a world-mode global; worlds default to 50ms.</td>
</tr>
<tr>
<td>Parties</td>
<td>Not supported</td>
<td>No matchmaker party grouping. Share a match or world id, or a join code, and join directly; gate entry in <code>join(player_id, state, ctx)</code>.</td>
</tr>
<tr>
<td>MatchmakerAdd</td>
<td><code>POST /api/v1/matchmaker</code></td>
<td>Body <code>{&quot;mode&quot;: &quot;...&quot;, &quot;properties&quot;: {}}</code>. Returns <code>{&quot;ticket_id&quot;: &quot;...&quot;, &quot;status&quot;: &quot;pending&quot;}</code>.</td>
</tr>
<tr>
<td>Storage engine</td>
<td><code>GET/PUT/DELETE /api/v1/storage/:collection/:key</code></td>
<td>Collection, key and owner, same model. Permissions are <code>read_perm</code> and <code>write_perm</code>, each <code>public</code> or <code>owner</code>. There is no <code>none</code>.</td>
</tr>
<tr>
<td>Storage, shared/global rows</td>
<td>Lua <code>game.storage.get/set</code></td>
<td>The HTTP routes only ever touch per-player rows. The global namespace (no owner) is reachable from Lua only.</td>
</tr>
<tr>
<td>Leaderboards</td>
<td><code>/api/v1/leaderboards/:id</code></td>
<td>Submit, top, around.</td>
</tr>
<tr>
<td>Tournaments</td>
<td><code>/api/v1/tournaments</code></td>
<td>Scheduled, entry fees, rewards.</td>
</tr>
<tr>
<td>Friends</td>
<td><code>/api/v1/friends</code></td>
<td>Request, approve, block.</td>
</tr>
<tr>
<td>Groups</td>
<td><code>/api/v1/groups</code></td>
<td>Roles, join, leave, kick.</td>
</tr>
<tr>
<td>Chat channels</td>
<td>Chat channels plus WS <code>chat.send</code> / <code>chat.join</code></td>
<td>Per-channel history.</td>
</tr>
<tr>
<td>Notifications</td>
<td><code>/api/v1/notifications</code></td>
<td>Plus the <code>notification.new</code> WebSocket push.</td>
</tr>
<tr>
<td>Wallets</td>
<td>Economy wallets (<code>/api/v1/wallets</code>)</td>
<td>Multi-currency ledgers.</td>
</tr>
<tr>
<td>Purchases</td>
<td>Economy store (<code>/api/v1/store/purchase</code>)</td>
<td>Spends an in-game wallet balance.</td>
</tr>
<tr>
<td>IAP receipts</td>
<td><code>POST /api/v1/iap/apple</code>, <code>/api/v1/iap/google</code></td>
<td>Verifies the receipt and records it once per transaction. It grants nothing: turning a verified receipt into currency or items is your game's job, via the economy or inventory API.</td>
</tr>
<tr>
<td>Authentication (device / custom)</td>
<td><code>POST /api/v1/auth/guest</code></td>
<td>Create-or-resume from a device-held secret; claim later with <code>/api/v1/auth/guest/upgrade</code>. Opt-in - see the note below the table.</td>
</tr>
<tr>
<td>Authentication (email)</td>
<td><code>POST /api/v1/auth/register</code> and <code>/login</code></td>
<td>Username plus password.</td>
</tr>
<tr>
<td>Authentication (Google / Apple / Steam)</td>
<td><code>POST /api/v1/auth/oauth</code></td>
<td>OAuth/OIDC.</td>
</tr>
<tr>
<td>RPC endpoints</td>
<td>Extension RPC over the WebSocket</td>
<td>Frame <code>rpc.call</code> with <code>{protocol: 1, method, params}</code>; replies <code>rpc.ok</code> <code>{result}</code> or <code>rpc.error</code> <code>{error: {code, message, details}}</code>, correlated by <code>cid</code>. All seven client SDKs support it. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</td>
</tr>
<tr>
<td>Hooks (<code>before_authenticate</code>, <code>after_friendAdd</code>)</td>
<td>Nova plugins and match lifecycle callbacks</td>
<td>Pre- and post-request middleware in Nova.</td>
</tr>
<tr>
<td>Runtime Lua / TS / Go</td>
<td>Lua for game logic, Erlang/OTP for the engine</td>
<td>One scripting language.</td>
</tr>
<tr>
<td>Nakama Console</td>
<td>Built-in operator console at <code>/console</code></td>
<td>Off by default, and reads plus player erasure/export. See the note below the table.</td>
</tr>
<tr>
<td>Session token</td>
<td><code>access_token</code> plus <code>refresh_token</code></td>
<td>Register and login return <code>player_id</code>, <code>access_token</code>, <code>refresh_token</code> and <code>username</code>. There is no <code>session_token</code> field.</td>
</tr>
<tr>
<td>WebSocket</td>
<td><code>/ws</code>, <code>session.connect</code> first frame</td>
<td>See the Hathora guide's <a href="https://hexdocs.pm/asobi/migrate-from-hathora.html#websocket-handshake">WebSocket handshake</a>.</td>
</tr>
</tbody>
</table>
<p>Guest auth is off until two things are true: the game declares <code>guest_auth</code> in
its Lua config, and the operator supplies a pepper of at least 32 bytes. Either
one missing and <code>POST /api/v1/auth/guest</code> answers <code>guest.disabled</code>. See
<a href="/docs/authentication">Authentication</a>.</p>
<p>A stock node serves neither the console nor the ops API; you turn them on - see
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>. When you do, the plane is reads plus player
erasure and export, apart from actions an extension declares. If you run Nakama Console to ban and kick, budget
for building that yourself.</p>
<h2 id="migration-path" tabindex="-1">Migration path</h2>
<h3 id="phase-1---stand-up-asobi-alongside-nakama-05-days" tabindex="-1">Phase 1 - stand up asobi alongside Nakama (0.5 days)</h3>
<pre><code class="language-yaml">services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: my_game
    healthcheck:
      test: [&quot;CMD-SHELL&quot;, &quot;pg_isready -U postgres&quot;]
      interval: 5s

  asobi:
    image: ghcr.io/widgrensit/asobi:latest
    depends_on:
      postgres: { condition: service_healthy }
    ports: [&quot;8084:8084&quot;]
    volumes: [&quot;./lua:/app/game:ro&quot;]
    environment:
      ASOBI_DB_HOST: postgres
      ASOBI_DB_NAME: my_game
      ASOBI_CORS_ORIGINS: &quot;http://localhost:5173&quot;
      ASOBI_CONSOLE: &quot;true&quot;
      ASOBI_OPS_SECRET_FILE: /run/secrets/ops_secret
    secrets: [ops_secret]

secrets:
  ops_secret:
    file: ./ops_secret.txt
</code></pre>
<p><code>./lua</code> must contain a <code>match.lua</code> before the matchmaker has anything to match
on - see Phase 2 below, or <a href="https://hexdocs.pm/asobi/getting-started.html">Getting started</a> for a complete
one. Without it, <code>POST /api/v1/matchmaker</code> answers <code>matchmaker.unknown_mode</code>.</p>
<p><code>ASOBI_CORS_ORIGINS</code> is not optional for a browser client: unset, the node
sends an empty <code>Access-Control-Allow-Origin</code> and every fetch from a page is
blocked.</p>
<p>Requirements and the production compose are in
<a href="https://hexdocs.pm/asobi/self-hosting.html">Self-hosting</a>.</p>
<h3 id="phase-2---port-the-runtime-1-3-days" tabindex="-1">Phase 2 - port the runtime (1-3 days)</h3>
<p>Nakama's Lua API is RPC-first:</p>
<pre><code class="language-lua">local nk = require(&quot;nakama&quot;)
local function foo(context, payload)
  nk.logger_info(&quot;hello&quot;)
  local users = nk.storage_read({...})
  return nk.json_encode({ok = true})
end
nk.register_rpc(foo, &quot;my_rpc&quot;)
</code></pre>
<p>asobi's is match-first. The match is the unit; the file is <code>match.lua</code>:</p>
<pre><code class="language-lua">match_size = 2

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
<p>Cross-match logic has three homes:</p>
<ul>
<li><code>game.leaderboard.submit</code>, <code>game.economy.*</code>, <code>game.storage.*</code> and
<code>game.notify</code> are callable from any match script. See the
<a href="https://hexdocs.pm/asobi/lua-api.html">Lua API</a>.</li>
<li>Anything a client must call by name, that is not tied to a match, becomes an
extension RPC method. That is the direct replacement for
<code>nk.register_rpc</code>, and it reaches the client as <code>rpc.call</code> on the same
WebSocket. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</li>
<li>Scheduled work runs as a Shigoto job in Erlang.</li>
</ul>
<p>If most of your Nakama logic is RPC-shaped rather than per-match, budget closer
to a week and expect to write an extension.</p>
<h3 id="phase-3---migrate-the-storage-schema-1-2-days" tabindex="-1">Phase 3 - migrate the storage schema (1-2 days)</h3>
<p>asobi's table is <code>storage</code>, not <code>asobi_storage</code>. Permissions are two columns,
<code>read_perm</code> and <code>write_perm</code>, each <code>public</code> or <code>owner</code>. <code>id</code> and <code>updated_at</code>
have no database default, so the insert must supply them.</p>
<pre><code class="language-bash">pg_dump -U nakama -t storage -d nakama &gt; storage-export.sql
</code></pre>
<p>Load that dump into a staging table, then:</p>
<pre><code class="language-sql">INSERT INTO storage (id, collection, key, player_id, value, version, read_perm, write_perm, updated_at)
SELECT gen_random_uuid(), collection, key, user_id::uuid, value::jsonb, 1, 'owner', 'owner', now()
FROM nakama_storage_import;
</code></pre>
<p>asobi mints UUIDv7 for rows it creates; <code>gen_random_uuid()</code> gives v4, which is
fine for imported rows because nothing reads ordering off a storage id.</p>
<p>The same one-off-script pattern applies to leaderboards, friends, groups and
wallets. Column names differ; the schemas are in <code>src/</code> alongside each domain.</p>
<h3 id="phase-4---port-the-client-2-5-days" tabindex="-1">Phase 4 - port the client (2-5 days)</h3>
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
<tr>
<td>(none)</td>
<td><a href="https://github.com/widgrensit/asobi-love2d">asobi-love2d</a></td>
</tr>
<tr>
<td>(none)</td>
<td><a href="https://github.com/widgrensit/asobi-dart">asobi-dart</a></td>
</tr>
<tr>
<td>(none)</td>
<td><a href="https://github.com/widgrensit/flame_asobi">flame_asobi</a></td>
</tr>
</tbody>
</table>
<p><code>AuthenticateCustom</code> and <code>AuthenticateDevice</code> both become guest auth. On the
wire that is one POST and one WebSocket frame:</p>
<pre><code class="language-bash">curl -s localhost:8084/api/v1/auth/guest \
  -H 'content-type: application/json' \
  -d '{&quot;device_id&quot;:&quot;&lt;stable device id&gt;&quot;,&quot;device_secret&quot;:&quot;&lt;base64 of &gt;= 32 random bytes&gt;&quot;}'
# { &quot;player_id&quot;: &quot;019de3...&quot;, &quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;,
#   &quot;username&quot;: &quot;...&quot;, &quot;guest&quot;: true, &quot;created&quot;: true }
</code></pre>
<pre><code class="language-json">{&quot;type&quot;:&quot;session.connect&quot;,&quot;payload&quot;:{&quot;token&quot;:&quot;&lt;access_token&gt;&quot;}}
</code></pre>
<p>Your SDK wraps both. Each SDK's own README carries the call names; this guide
does not restate them because they differ per language.</p>
<h3 id="phase-5---cut-over-1-day" tabindex="-1">Phase 5 - cut over (1 day)</h3>
<p>Flip the client's base URL behind a feature flag. Monitor for 24h. Shut the
Nakama server down.</p>
<h2 id="what-nakama-has-that-asobi-does-not" tabindex="-1">What Nakama has that asobi does not</h2>
<ul>
<li>Satori. asobi's LiveOps story is rougher.</li>
<li>Hiro. asobi has tournaments and phases, and seasons ship as the
<a href="https://github.com/widgrensit/asobi_seasons"><code>asobi_seasons</code></a> extension, but
nothing as opinionated.</li>
<li>Go and TypeScript runtimes. asobi is Lua or Erlang.</li>
<li>A mutating operator console. asobi's ops plane erases and exports a player
and nothing else, so moderation is a database write, a Lua handler or an
extension action.</li>
<li>Published case studies from large studios. asobi is newer.</li>
</ul>
<h2 id="what-asobi-has-that-nakama-does-not" tabindex="-1">What asobi has that Nakama does not</h2>
<ul>
<li>Live Lua reload without dropping players.</li>
<li>Spatial zones and terrain, purpose-built for large-world games.</li>
<li>Built-in voting (plurality, ranked, approval, weighted).</li>
<li>Phases as a first-class primitive.</li>
<li>Per-match process isolation under OTP supervision: a crash in one match does
not leak into another, and there is no shared stop-the-world GC.</li>
</ul>
<h2 id="cost" tabindex="-1">Cost</h2>
<p>Self-hosted Nakama and self-hosted asobi have similar infrastructure costs.
Both run on PostgreSQL. The operational differences that show up in a bill are
node count and how you deploy game-logic changes.</p>
<p>Node count is where asobi's clustering behaviour matters: the matchmaker queue
is per node, so players queuing against different nodes never match each other,
and rate limits are per node. Adding nodes is not free of design consequences.
<a href="/docs/clustering">Clustering</a> has the full list.</p>
<h2 id="do-this-today" tabindex="-1">Do this today</h2>
<ul>
<li>Run the Phase 1 compose locally and register a test player.</li>
<li>Port one Nakama match handler to <code>match.lua</code>. Compare the feel.</li>
<li>Join the <a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code> channel and
tell us what your runtime modules do.</li>
</ul>
<h2 id="getting-help" tabindex="-1">Getting help</h2>
<ul>
<li>Discord: <a href="https://discord.gg/vYSfYYyXpu">#migrations</a></li>
<li>Email: hello@asobi.dev</li>
<li>GitHub Discussions:
<a href="https://github.com/widgrensit/asobi/discussions">widgrensit/asobi/discussions</a></li>
</ul>
<h2 id="see-also" tabindex="-1">See also</h2>
<ul>
<li><a href="https://hexdocs.pm/asobi/migrate-from-hathora.html">Migrating from Hathora</a></li>
<li><a href="https://hexdocs.pm/asobi/migrate-from-playfab.html">Migrating from PlayFab</a></li>
<li><a href="https://hexdocs.pm/asobi/exit.html">Exit guarantee</a></li>
<li><a href="https://hexdocs.pm/asobi/comparison.html">Comparison</a></li>
</ul>
"""}
    ]}.
