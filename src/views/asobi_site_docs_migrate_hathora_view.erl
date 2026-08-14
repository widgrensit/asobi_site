%% GENERATED from asobi guides/migrate-from-hathora.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_migrate_hathora_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-migrate-hathora", title => ~"Migrate from Hathora — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Migrate / Hathora"
        ]},
        {h1, [], [~"Migrating from Hathora to asobi"]},
        {raw,
            ~"""
<p>Hathora's game-hosting service shut down on 2026-05-05. This guide takes you
from &quot;we need a new backend&quot; to a running asobi deployment.</p>
<p>Nobody has migrated a Hathora game to asobi end to end yet. The asobi-side
endpoints and events below are verified against this repository; the
Hathora-side method names are from memory of the pre-shutdown SDK and may have
drifted. The fastest route is pairing with us in the
<a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code> channel.</p>
<p>This guide targets studios on Hathora's managed service. Self-hosted
<code>hathora-core</code> users have a different problem - skip to
<a href="#self-hosted-hathora-users">Self-hosted Hathora users</a>.</p>
<h2 id="what-asobi-is" tabindex="-1">What asobi is</h2>
<p>One Erlang/OTP node containing the game backend, the Lua runtime and the
operator console. Two ways in: run <code>ghcr.io/widgrensit/asobi</code> and write Lua, or
depend on the Hex package and write Erlang. Same node either way.</p>
<h2 id="today-in-15-minutes" tabindex="-1">Today, in 15 minutes</h2>
<p>Four steps. They unblock you even if the full port takes a week.</p>
<p><strong>1. Write a minimal game.</strong> asobi loads Lua from <code>/app/game</code>, and without a
mode declared there the matchmaker has nothing to match on. In an empty
directory:</p>
<pre><code class="language-lua">-- lua/match.lua

match_size = 2

function init(_config)
    return { players = {} }
end

function join(player_id, state)
    state.players[player_id] = { score = 0 }
    return state
end

function leave(player_id, state)
    state.players[player_id] = nil
    return state
end

function handle_input(_player_id, _input, state)
    return state
end

function tick(state)
    return state
end

function get_state(_player_id, state)
    return { players = state.players }
end
</code></pre>
<p><strong>2. Stand the backend up.</strong> Next to <code>lua/</code>:</p>
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
<p><code>openssl rand -hex 32 &gt; ops_secret.txt</code>, then <code>docker compose up -d</code>. HTTP is on
<code>:8084</code>, the WebSocket is on <code>/ws</code>, the console is on <code>/console</code>.</p>
<p><code>ASOBI_CORS_ORIGINS</code> is not optional for a browser client: unset, the node
sends an empty <code>Access-Control-Allow-Origin</code> and every fetch from a page is
blocked.</p>
<p><strong>3. Register one player.</strong></p>
<pre><code class="language-bash">curl -s localhost:8084/api/v1/auth/register \
  -H 'content-type: application/json' \
  -d '{&quot;username&quot;:&quot;test&quot;,&quot;password&quot;:&quot;test1234&quot;}'
# { &quot;player_id&quot;: &quot;019de3...&quot;, &quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;, &quot;username&quot;: &quot;test&quot; }
</code></pre>
<p><code>access_token</code> is what the client passes as <code>Authorization: Bearer ...</code> from
here on. <code>refresh_token</code> buys a new pair from <code>POST /api/v1/auth/refresh</code>.
There is no <code>session_token</code> anywhere in asobi.</p>
<p><strong>4. Queue for matchmaking.</strong></p>
<pre><code class="language-bash">curl -s localhost:8084/api/v1/matchmaker \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer &lt;access_token&gt;' \
  -d '{&quot;mode&quot;:&quot;default&quot;,&quot;properties&quot;:{}}'
# { &quot;ticket_id&quot;: &quot;019de3...&quot;, &quot;status&quot;: &quot;pending&quot; }
</code></pre>
<p>A 400 with <code>matchmaker.unknown_mode</code> means the node found no mode called
<code>default</code>, which almost always means <code>lua/match.lua</code> is not mounted where step
2 puts it.</p>
<p>Then open a tracking issue at
<a href="https://github.com/widgrensit/asobi/issues">github.com/widgrensit/asobi/issues</a>
and say hello in the <a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code>
channel with your setup: engine, language, lobby versus matchmaker,
server-authoritative versus P2P. We will tell you which sections below apply to
you.</p>
<h2 id="the-full-port-in-outline" tabindex="-1">The full port, in outline</h2>
<ol>
<li>Your game-server logic keeps running in its own process while you migrate.</li>
<li>asobi comes up alongside it. Your game server talks to it over WebSocket
like any other auth, matchmaker or leaderboard service.</li>
<li>You port the Hathora-specific calls to the equivalents in the concept map.</li>
<li>Once asobi owns auth, matchmaking and lobbies, you drop Hathora and either
keep your game server in a plain container, or fold its logic into a
<code>match.lua</code> and delete the container.</li>
</ol>
<p>For most Hathora games the game server is a few hundred lines of state
mutation, which is well within the scope of one Lua file.</p>
<h2 id="concept-map" tabindex="-1">Concept map</h2>
<table>
<thead>
<tr>
<th>Hathora</th>
<th>asobi</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td>Application</td>
<td>asobi deployment</td>
<td>One container per environment.</td>
</tr>
<tr>
<td>Room</td>
<td>Match</td>
<td>One process per match; state lives in the process heap.</td>
</tr>
<tr>
<td>Process</td>
<td>No equivalent</td>
<td>asobi does not spin a container per match. One container hosts thousands of matches as BEAM processes.</td>
</tr>
<tr>
<td>Lobby</td>
<td>Matchmaker ticket plus a match in its waiting phase</td>
<td><code>POST /api/v1/matchmaker</code>; when <code>match_size</code> is reached the match starts.</td>
</tr>
<tr>
<td>Region</td>
<td>Deployment location</td>
<td>One container per region, chosen by you. There is no region abstraction.</td>
</tr>
<tr>
<td>Matchmaker 2.0</td>
<td><code>asobi_matchmaker</code></td>
<td>Strategies <code>fill</code> and <code>skill_based</code>, or your own via the <code>asobi_matchmaker_strategy</code> behaviour.</td>
</tr>
<tr>
<td><code>HathoraClient.loginAnonymous</code></td>
<td><code>POST /api/v1/auth/guest</code></td>
<td>Device-backed anonymous auth: <code>device_id</code> plus <code>device_secret</code>, and you get a real player back. Claim it later with <code>POST /api/v1/auth/guest/upgrade</code>. Opt-in - see the note below the table.</td>
</tr>
<tr>
<td><code>HathoraClient.loginGoogle</code></td>
<td><code>POST /api/v1/auth/oauth</code></td>
<td>OAuth/OIDC.</td>
</tr>
<tr>
<td><code>createLobby</code>, <code>createRoom</code>, queue</td>
<td><code>POST /api/v1/matchmaker</code></td>
<td>Body <code>{&quot;mode&quot;: &quot;...&quot;, &quot;properties&quot;: {}}</code>, response <code>{&quot;ticket_id&quot;: &quot;...&quot;, &quot;status&quot;: &quot;pending&quot;}</code>.</td>
</tr>
<tr>
<td>Ticket poll</td>
<td><code>GET /api/v1/matchmaker/:ticket_id</code></td>
<td></td>
</tr>
<tr>
<td>Cancel</td>
<td><code>DELETE /api/v1/matchmaker/:ticket_id</code></td>
<td></td>
</tr>
<tr>
<td><code>listActivePublicLobbies</code></td>
<td><code>GET /api/v1/matches/live</code></td>
<td>Live, joinable matches; filter with <code>mode</code> and <code>has_capacity</code>. Matches are unlisted by default and a mode opts in with <code>listed = true</code> (a Lua global, or <code>listed =&gt; true</code> in the operator's <code>game_modes</code> config). Not <code>GET /api/v1/matches</code>, which is the finished-match record table.</td>
</tr>
<tr>
<td><code>getConnectionInfo(roomId)</code></td>
<td>WebSocket upgrade on <code>GET /ws</code></td>
<td>See <a href="#websocket-handshake">WebSocket handshake</a>. The first frame must authenticate.</td>
</tr>
<tr>
<td>Custom room messages</td>
<td>Extension RPC</td>
<td>Frame <code>rpc.call</code> with <code>{protocol: 1, method, params}</code>; replies <code>rpc.ok</code> <code>{result}</code> or <code>rpc.error</code> <code>{error: {code, message, details}}</code>, correlated by <code>cid</code>. All seven client SDKs support it. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</td>
</tr>
<tr>
<td><code>ping</code> region API</td>
<td>None</td>
<td>Probe each deployment endpoint yourself if you need client-side region selection.</td>
</tr>
<tr>
<td>Hathora SDK</td>
<td>asobi SDKs</td>
<td><a href="https://github.com/widgrensit/asobi-unity">Unity</a>, <a href="https://github.com/widgrensit/asobi-unreal">Unreal</a>, <a href="https://github.com/widgrensit/asobi-js">JS/TS</a>, <a href="https://github.com/widgrensit/asobi-godot">Godot</a>, <a href="https://github.com/widgrensit/asobi-defold">Defold</a>, <a href="https://github.com/widgrensit/asobi-love2d">LÖVE</a>, <a href="https://github.com/widgrensit/asobi-dart">Dart</a>, <a href="https://github.com/widgrensit/flame_asobi">Flame</a>.</td>
</tr>
<tr>
<td>Hathora Console</td>
<td>Built-in operator console at <code>/console</code></td>
<td>Off by default, and reads plus player erasure/export. See the note below the table.</td>
</tr>
<tr>
<td><code>hathora.yml</code></td>
<td><code>docker-compose.yml</code></td>
<td>Plain Compose, no proprietary spec.</td>
</tr>
</tbody>
</table>
<p>Guest auth is off until two things are true: the game declares <code>guest_auth</code> in
its Lua config, and the operator supplies a pepper of at least 32 bytes. Either
one missing and <code>POST /api/v1/auth/guest</code> answers <code>guest.disabled</code>. See
<a href="/docs/authentication">Authentication</a>.</p>
<p>A stock node serves neither the console nor the ops API; you turn them on - see
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>. When you do, the plane is reads plus player
erasure and export, apart from actions an extension declares. Coming from the Hathora console you will look for
a restart-this-process button; there is not one, because there is no process per
match to restart.</p>
<h2 id="migration-path" tabindex="-1">Migration path</h2>
<h3 id="phase-1---stand-up-asobi-alongside-hathora-1-day" tabindex="-1">Phase 1 - stand up asobi alongside Hathora (1 day)</h3>
<p>Use the compose file from step 2 above, on the same cloud or locally, without
touching the Hathora deployment. Goal: auth, a lobby and a match working end to
end from your client. Requirements and the production compose are in
<a href="https://hexdocs.pm/asobi/self-hosting.html">Self-hosting</a>.</p>
<h3 id="phase-2---port-the-client-sdk-calls-2-to-5-days" tabindex="-1">Phase 2 - port the client SDK calls (2 to 5 days)</h3>
<p>Swap the Hathora SDK for the asobi SDK for the same engine. Do it one feature
at a time: auth first, then the WebSocket handshake, then matchmaking, then the
game-session messages. Hathora and asobi coexist in the client during this
phase behind different base URLs.</p>
<p>Matchmaker tickets resolve asynchronously over the WebSocket as <code>match.matched</code>
with payload <code>{match_id, players}</code>. Polling
<code>GET /api/v1/matchmaker/:ticket_id</code> works too.</p>
<p>Each SDK's README carries its own call names; this guide does not restate them
because they differ per language.</p>
<h3 id="websocket-handshake" tabindex="-1">WebSocket handshake</h3>
<p>asobi expects every WebSocket client to authenticate with a <code>session.connect</code>
frame before any other message type is accepted. The payload field is <code>token</code>,
carrying the <code>access_token</code> from register, login or guest:</p>
<pre><code class="language-json">{&quot;type&quot;:&quot;session.connect&quot;,&quot;payload&quot;:{&quot;token&quot;:&quot;&lt;access_token&gt;&quot;}}
</code></pre>
<p>The server replies:</p>
<pre><code class="language-json">{&quot;type&quot;:&quot;session.connected&quot;,&quot;payload&quot;:{&quot;player_id&quot;:&quot;019de3...&quot;}}
</code></pre>
<p>A missing or misspelled <code>token</code> field is not a shape error - it is treated as a
token that did not resolve, so the reply is an error frame carrying the wire
code <code>unauthenticated</code>:</p>
<pre><code class="language-json">{&quot;type&quot;:&quot;error&quot;,&quot;payload&quot;:{&quot;reason&quot;:&quot;invalid_token&quot;,&quot;error&quot;:{&quot;code&quot;:&quot;unauthenticated&quot;,&quot;message&quot;:&quot;The credentials are missing, expired, or invalid.&quot;,&quot;details&quot;:{}}}}
</code></pre>
<p>After a successful handshake the server routes match, matchmaker, chat and
world events to this player. The message types a client may send are:</p>
<p><code>session.connect</code>, <code>session.heartbeat</code>, <code>matchmaker.add</code>, <code>matchmaker.remove</code>,
<code>match.join</code>, <code>match.leave</code>, <code>match.input</code>, <code>match.list</code>, <code>world.create</code>,
<code>world.find_or_create</code>, <code>world.join</code>, <code>world.leave</code>, <code>world.input</code>,
<code>world.list</code>, <code>chat.send</code>, <code>chat.join</code>, <code>chat.leave</code>, <code>dm.send</code>,
<code>presence.update</code>, <code>vote.cast</code>, <code>vote.veto</code>, <code>rpc.call</code>.</p>
<p>Server-pushed types follow <code>{domain}.{event}</code>: <code>match.matched</code>, <code>match.state</code>,
<code>match.finished</code>, <code>world.tick</code>, <code>world.terrain</code>, <code>chat.message</code>, <code>dm.message</code>,
<code>notification.new</code>, <code>error</code>, plus any leaf name your script broadcasts under
<code>match.</code> or <code>world.</code>. The full reference is
<a href="/docs/protocols/websocket">WebSocket protocol</a>.</p>
<h3 id="phase-3---port-the-game-logic-2-days-to-2-weeks" tabindex="-1">Phase 3 - port the game logic (2 days to 2 weeks)</h3>
<p><strong>Option A - keep your existing game server.</strong> If you have a lot of C# or Go
server code you would rather not rewrite, keep running it in its own container.
Use asobi for auth, matchmaking, lobbies, leaderboards and persistence. When
the matchmaker fires <code>match.matched</code>, the client has an <code>access_token</code> from
asobi; pass it, plus <code>player_id</code> and <code>match_id</code>, to your game server over your
own connection, and have your game server check the token with asobi before
accepting input.</p>
<p>There is no dedicated server-to-server token-introspection route. Check a token
by calling any authenticated GET with it (<code>GET /api/v1/friends</code> is a cheap one)
and treating 200 as accepted, 401 as not. Two caveats before you build on it:
no core route reliably reports the caller's own <code>player_id</code> - a friends,
notifications or saves response carries it only on rows the player already has,
and is empty otherwise - so a 200 proves the token is valid, not whose it is.
And do not use <code>POST /api/v1/auth/refresh</code> for the check. That endpoint takes a
<code>refresh_token</code>, not an access token, so an access token simply fails there;
and a refresh token rotates the pair, with a second presentation of a rotated
token revoking the whole token family and logging the player out. If you
need real introspection, an extension can add it: an RPC handler receives the
caller's <code>player_id</code> in its context. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</p>
<p><strong>Option B - fold the game logic into Lua.</strong> Rewrite your tick, input and state
logic as a <code>match.lua</code>, using the six callbacks from step 1:</p>
<ul>
<li><code>init(config)</code> - once per match, returns the initial state</li>
<li><code>join(player_id, state)</code> and <code>leave(player_id, state)</code></li>
<li><code>handle_input(player_id, input, state)</code> - one client <code>match.input</code> frame</li>
<li><code>tick(state)</code> - every 100ms</li>
<li><code>get_state(player_id, state)</code> - the per-player view</li>
</ul>
<p>Matches tick every 100ms and that is fixed; <code>tick_rate</code> is a world-mode
setting. You get live reload for free - edit, save, and the next tick
re-evaluates the file against the running state - and you delete a container.
See <a href="/docs/lua/api">Lua scripting</a>.</p>
<h3 id="phase-4---cut-over-1-day" tabindex="-1">Phase 4 - cut over (1 day)</h3>
<p>Point the client at the asobi endpoint behind a feature flag. Monitor for 24h.
Shut Hathora down.</p>
<h2 id="deploy-story" tabindex="-1">Deploy story</h2>
<p>asobi runs anywhere Docker runs. The managed version is
<a href="https://asobi.dev/cloud">asobi.dev/cloud</a>, the same open-source core.</p>
<p>A single node holds 3,000-7,000 concurrent WebSocket connections in
measurement, at 4.4ms p50 round-trip with 3,500 of them - see
<a href="https://hexdocs.pm/asobi/benchmarks.html">Benchmarks</a>. Most games' first deployment is one small machine
plus a Postgres, which is where the saving against process-hour billing comes
from.</p>
<p>If you plan on more than one node, read <a href="/docs/clustering">Clustering</a> first: the
matchmaker queue is per node, so players queuing against different nodes never
match each other, rate limits are per node, and the console needs a sticky
route.</p>
<h2 id="self-hosted-hathora-users" tabindex="-1">Self-hosted Hathora users</h2>
<p>If you run <code>hathora-core</code> on your own infrastructure you still own the stack
and can keep running it as long as it works. The same migration strategy
applies when you decide to move.</p>
<h2 id="things-asobi-does-not-do" tabindex="-1">Things asobi does not do</h2>
<ul>
<li><strong>No UDP transport.</strong> WebSocket over TCP only. A twitch FPS, fighting game or
racer that needs sub-3ms physics should pair asobi with a UDP relay and use
asobi for auth, matchmaking, economy, leaderboards and social.</li>
<li><strong>Guest auth is opt-in and off by default.</strong> It exists and it is device-backed
rather than a throwaway username, but it stays off until the game declares
<code>guest_auth</code> and the operator supplies a pepper of at least 32 bytes.</li>
<li><strong>No server-to-server token introspection route.</strong> See Option A above.</li>
<li><strong>No automatic multi-region.</strong> One container per region, deployed by you.</li>
<li><strong>No rollback netcode or lag compensation.</strong> No server-side replay, no hitbox
rewind; over TCP (above) asobi is not for twitch shooters. But the server half
of <em>client-side prediction</em> is a first-class primitive: the client stamps each
<code>world.input</code> with an increasing <code>seq</code>, and the server returns the highest one
it has consumed as a <code>world.ack</code> on that connection for the client to
reconcile against. See
<a href="/docs/protocols/websocket#client-side-prediction">Client-side prediction</a>.</li>
<li><strong>Pre-1.0 API.</strong> Minor breaking changes are possible until 1.0.</li>
</ul>
<h2 id="do-this-today" tabindex="-1">Do this today</h2>
<ul>
<li>Run the compose from step 2 locally and register a player.</li>
<li>Pick one SDK call in your client to port first, usually <code>loginAnonymous</code>.</li>
<li>Join the <a href="https://discord.gg/vYSfYYyXpu">Discord</a>.</li>
<li>Decide Option A or Option B and open a thread in
<a href="https://github.com/widgrensit/asobi/discussions">Discussions</a>.</li>
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
<li><a href="https://hexdocs.pm/asobi/migrate-from-playfab.html">Migrating from PlayFab</a></li>
<li><a href="https://hexdocs.pm/asobi/migrate-from-nakama.html">Migrating from Nakama self-host</a></li>
<li><a href="https://hexdocs.pm/asobi/exit.html">Exit guarantee</a></li>
<li><a href="https://hexdocs.pm/asobi/comparison.html">Comparison</a></li>
</ul>
"""}
    ]}.
