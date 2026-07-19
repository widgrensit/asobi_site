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
<p><strong>Hathora's game-hosting service shuts down on 2026-05-05.</strong> If you're reading
this with a running game on <code>hathora.dev</code> or <code>hathora.cloud</code>, this guide walks
you from &quot;we need a new backend by May&quot; to &quot;we're running on asobi and we
never have to do this again.&quot;</p>
<h2 id="today-in-15-minutes" tabindex="-1">Today, in 15 minutes</h2>
<p>Before you read the rest of this guide, do these five things in this order.
They get you unblocked even if the full port takes a week:</p>
<ol>
<li><strong>Stand up a local asobi backend.</strong> Drop this <code>docker-compose.yml</code> into an
empty directory:<pre><code class="language-yaml">services:
  postgres:
    image: postgres:17
    environment: { POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres, POSTGRES_DB: my_game }
    healthcheck: { test: [&quot;CMD-SHELL&quot;, &quot;pg_isready -U postgres&quot;], interval: 5s }
  asobi:
    image: ghcr.io/widgrensit/asobi_lua:latest
    depends_on: { postgres: { condition: service_healthy } }
    ports: [&quot;8084:8084&quot;]
    environment: { ASOBI_DB_HOST: postgres, ASOBI_DB_NAME: my_game }
</code></pre>
Then <code>docker compose up -d</code>. HTTP is on <code>:8084</code>, WebSocket is on <code>/ws</code>.</li>
<li><strong>Register one player</strong> — the asobi equivalent of <code>HathoraClient.loginAnonymous</code>:<pre><code class="language-bash">curl -s localhost:8084/api/v1/auth/register \
  -H 'content-type: application/json' \
  -d '{&quot;username&quot;:&quot;test&quot;,&quot;password&quot;:&quot;test1234&quot;}'
# → { &quot;username&quot;: &quot;test&quot;, &quot;player_id&quot;: &quot;019de3...&quot;, &quot;session_token&quot;: &quot;wRqvop92/...&quot; }
</code></pre>
That <code>session_token</code> is what your client passes in <code>Authorization: Bearer …</code>
from here on, in place of any Hathora auth token.</li>
<li><strong>Queue for matchmaking</strong> to confirm the matchmaker works end-to-end:<pre><code class="language-bash">curl -s localhost:8084/api/v1/matchmaker \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer wRqvop92/...' \
  -d '{&quot;mode&quot;:&quot;default&quot;,&quot;properties&quot;:{},&quot;party&quot;:[&quot;019de3...&quot;]}'
# → { &quot;status&quot;: &quot;pending&quot;, &quot;ticket_id&quot;: &quot;019de3...&quot; }
</code></pre>
</li>
<li><strong>Join the Discord</strong> <a href="https://discord.gg/vYSfYYyXpu"><code>#migrations</code> channel</a>.
Drop your Hathora setup (engine, language, lobby vs matchmaker,
server-authoritative vs P2P) — we will tell you which sections of this
guide actually apply to you and which to skip.</li>
<li><strong>Open a tracking issue</strong> at
<a href="https://github.com/widgrensit/asobi/issues">github.com/widgrensit/asobi/issues</a>
so we know you exist. We are prioritising migration help over feature work
until 2026-05-05.</li>
</ol>
<p>That is the panic checklist. You are no longer locked out as of step 1.
Everything below is the full port.</p>
<blockquote>
<p><strong>Draft notice.</strong> This guide is a starting point, not a battle-tested
playbook — nobody has yet migrated a Hathora game to asobi end-to-end.
The asobi-side endpoint and event names below are <strong>verified against the
current code</strong>. The Hathora-side method names come from our memory of the
pre-shutdown SDK and may have drifted. <strong>The fastest path to a working
migration is pairing with us in the
<a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code> channel</strong> — we'll
walk through your specific setup rather than you fighting this doc in the
dark.</p>
</blockquote>
<blockquote>
<p>This guide targets studios on Hathora's <em>managed</em> service. If you're a
self-hosted <code>hathora-core</code> user your situation is different — skip to
<a href="#self-hosted-hathora-users">§ Self-hosted Hathora users</a>.</p>
</blockquote>
<h2 id="tldr" tabindex="-1">TL;DR</h2>
<ol>
<li>Your game-server logic (C#, Go, Node, whatever it is today) <strong>keeps
running in its own process</strong> while you migrate.</li>
<li>You bring up an asobi_lua container. Your game-server talks to it over
WebSocket like it would any other auth/matchmaker/leaderboard service.</li>
<li>You port the Hathora-specific calls — <code>createLobby</code>, <code>getRoomInfo</code>,
<code>listActivePublicLobbies</code>, <code>HathoraClient.loginAnonymous</code>, etc. — to the
asobi equivalents in the table below.</li>
<li>Once asobi is doing auth/matchmaking/lobbies, you drop Hathora entirely
and either (a) keep running your existing server code in a plain
container on Hetzner / Fly / Scaleway or (b) fold your game logic into an
asobi Lua script and let asobi host that too.</li>
</ol>
<p>Option (b) is more work up front, but it means no game-server container at
all. For most Hathora games the game-server is a few hundred lines of
state-mutation code — well within the scope of a <code>match.lua</code> file.</p>
<h2 id="why-asobi-specifically" tabindex="-1">Why asobi specifically</h2>
<p>The reason you're reading this is that Hathora pivoted to AI. We don't want
that to be you again.</p>
<ul>
<li><strong>Apache-2.0, open-source, self-hostable.</strong> The engine is at
<a href="https://github.com/widgrensit/asobi">github.com/widgrensit/asobi</a> and the
Docker runtime is at
<a href="https://github.com/widgrensit/asobi_lua">github.com/widgrensit/asobi_lua</a>.
Fork it. Mirror it. Run it on your own hardware. Our <a href="https://hexdocs.pm/asobi/exit.html">exit
guide</a> is a 1-page runbook for keeping your game alive if we
vanish tomorrow.</li>
<li><strong>No CCU billing.</strong> Managed asobi cloud (opening later in 2026) is flat
per-container. Self-host is free.</li>
<li><strong>Hot-reload Lua.</strong> Edit your match logic, save, connected matches pick it
up — no rebuild, no redeploy, no kicked players.</li>
<li><strong>One container, one Postgres.</strong> No CockroachDB. No Redis. No Kubernetes.</li>
<li><strong>Matchmaking, lobbies, rooms, leaderboards, economy, chat, friends,
tournaments, voting, phases, seasons, reconnection</strong> are all already there
— see the <a href="../README.md#features">feature list</a>.</li>
<li><strong>Godot and Defold SDKs are first-class</strong>, alongside Unity/Unreal/JS/Flutter.</li>
<li><strong>EU-hosted, GDPR-ready, NIS2-aware</strong> if that matters to you.</li>
</ul>
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
<td>One container per environment (dev/live).</td>
</tr>
<tr>
<td>Room</td>
<td>Match</td>
<td>An OTP process per match, state kept in the process heap with ETS backup.</td>
</tr>
<tr>
<td>Process</td>
<td><em>(no equivalent)</em></td>
<td>asobi doesn't spin a container per match. One container hosts thousands of matches as BEAM processes. Simpler ops.</td>
</tr>
<tr>
<td>Lobby</td>
<td>Matchmaker ticket + Match in &quot;waiting&quot; phase</td>
<td>Players hit <code>/matchmaker/tickets</code>; when <code>match_size</code> is reached the match transitions to &quot;running&quot;.</td>
</tr>
<tr>
<td>Region</td>
<td>Deployment location</td>
<td>Deploy one container per region. No region abstraction baked in — you pick where to run the container.</td>
</tr>
<tr>
<td>Matchmaker (2.0)</td>
<td><code>asobi_matchmaker</code></td>
<td>Pluggable strategies (<code>fill</code>, <code>skill_based</code>); custom via <code>asobi_matchmaker_strategy</code> behaviour.</td>
</tr>
<tr>
<td><code>HathoraClient.loginAnonymous</code></td>
<td><code>POST /api/v1/auth/register</code> with <code>username</code> + <code>password</code></td>
<td><strong>No anonymous flag today.</strong> You generate a random username/password in the client and persist it locally (or use OAuth). Response fields: <code>player_id</code>, <code>session_token</code>, <code>username</code>.</td>
</tr>
<tr>
<td><code>HathoraClient.loginGoogle</code></td>
<td><code>POST /api/v1/auth/oauth</code></td>
<td>OAuth/OIDC flow.</td>
</tr>
<tr>
<td><code>createLobby</code> / <code>createRoom</code> / queue</td>
<td><code>POST /api/v1/matchmaker</code> body <code>{&quot;mode&quot;:&quot;default&quot;,&quot;properties&quot;:{},&quot;party&quot;:[playerId]}</code></td>
<td>Response: <code>{&quot;ticket_id&quot;:&quot;...&quot;,&quot;status&quot;:&quot;pending&quot;}</code>.</td>
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
<td><code>GET /api/v1/matches</code></td>
<td>Query params filter results.</td>
</tr>
<tr>
<td><code>getConnectionInfo(roomId)</code></td>
<td>WebSocket upgrade on <code>GET /ws</code></td>
<td>See <a href="#websocket-handshake">§ WebSocket handshake</a> — first frame must authenticate.</td>
</tr>
<tr>
<td><code>ping</code> region API</td>
<td><em>(none)</em></td>
<td>If you need client-side region selection, probe each deployment endpoint yourself.</td>
</tr>
<tr>
<td>Hathora SDK</td>
<td>asobi SDKs</td>
<td><a href="https://github.com/widgrensit/asobi-unity">asobi-unity</a>, <a href="https://github.com/widgrensit/asobi-unreal">asobi-unreal</a>, <a href="https://github.com/widgrensit/asobi-js">asobi-js</a>, <a href="https://github.com/widgrensit/asobi-godot">asobi-godot</a>, <a href="https://github.com/widgrensit/asobi-defold">asobi-defold</a>, <a href="https://github.com/widgrensit/asobi-dart">asobi-dart</a>, <a href="https://github.com/widgrensit/flame_asobi">flame_asobi</a>.</td>
</tr>
<tr>
<td>Hathora Console</td>
<td><a href="https://github.com/widgrensit/asobi_admin">asobi-admin</a></td>
<td>Tenants, games, API keys, match inspection. Pre-1.0.</td>
</tr>
<tr>
<td><code>hathora.yml</code></td>
<td><code>docker-compose.yml</code></td>
<td>Plain Compose, no proprietary spec.</td>
</tr>
<tr>
<td>Process-hour billing</td>
<td>Flat per-container</td>
<td>No surprise invoices.</td>
</tr>
</tbody>
</table>
<h2 id="migration-path" tabindex="-1">Migration path</h2>
<h3 id="phase-1-stand-up-asobi-alongside-hathora-1-day" tabindex="-1">Phase 1 — stand up asobi alongside Hathora (1 day)</h3>
<p>Run asobi on the same cloud (or locally) without touching the Hathora
deployment. Goal: verify auth, a lobby, and a match work end-to-end from
your client.</p>
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
<p>Put a minimal <code>lua/match.lua</code> in place (see the <a href="https://github.com/widgrensit/asobi_lua#quick-start">asobi_lua
README</a>) and bring it
up:</p>
<pre><code class="language-bash">docker compose up -d
curl localhost:8084/api/v1/auth/register \
  -H 'content-type: application/json' \
  -d '{&quot;username&quot;:&quot;test&quot;,&quot;password&quot;:&quot;test1234&quot;}'
# → { &quot;player_id&quot;: &quot;01HX...&quot;, &quot;session_token&quot;: &quot;...&quot;, &quot;username&quot;: &quot;test&quot; }
</code></pre>
<h3 id="phase-2-port-the-client-sdk-calls-25-days" tabindex="-1">Phase 2 — port the client SDK calls (2–5 days)</h3>
<p>In your Unity / Unreal / JS / Godot client, replace the Hathora SDK with the
asobi one for the same engine. The call shape is close but not identical:</p>
<p><strong>Unity — before (Hathora):</strong></p>
<pre><code class="language-csharp">var client = new HathoraClient(&quot;my-app-id&quot;);
await client.LoginAnonymousAsync();
var lobby = await client.CreateLobbyAsync(Visibility.Public, …);
var info = await client.GetConnectionInfoAsync(lobby.RoomId);
// then open a websocket to info.ExposedPort.Host:Port
</code></pre>
<p><strong>Unity — after (asobi):</strong></p>
<pre><code class="language-csharp">var client = new AsobiClient(&quot;https://api.my-game.com&quot;);
await client.Auth.RegisterAsync(&quot;alice&quot;, &quot;hunter2&quot;);     // or LoginAsync
await client.WebSocket.ConnectAsync();                    // /ws
client.WebSocket.SendSessionConnect(sessionToken);        // first frame
client.WebSocket.On(&quot;match.matched&quot;, OnMatched);          // payload: { match_id, players }
await client.Matchmaker.QueueAsync(mode: &quot;default&quot;);      // POST /api/v1/matchmaker
</code></pre>
<p>Matchmaker tickets resolve asynchronously over the WebSocket via the
<code>match.matched</code> event (payload <code>{match_id, players}</code>). You can poll
<code>GET /api/v1/matchmaker/:ticket_id</code> if you prefer.</p>
<p>Do this one feature at a time: <strong>auth first, then WebSocket handshake, then
matchmaking, then the game-session messages</strong>. Hathora and asobi can
coexist in the client during this phase (different base URLs).</p>
<h3 id="websocket-handshake" tabindex="-1">WebSocket handshake</h3>
<p>Asobi expects every WebSocket client to authenticate with a <code>session.connect</code>
frame <em>before</em> it can use any other WS message type. The payload field is
<strong><code>token</code></strong> (the value of the <code>session_token</code> you got from register/login):</p>
<pre><code class="language-json">{&quot;type&quot;:&quot;session.connect&quot;,&quot;payload&quot;:{&quot;token&quot;:&quot;eyJ...&quot;}}
</code></pre>
<p>The server replies <code>{&quot;type&quot;:&quot;session.connected&quot;,&quot;payload&quot;:{&quot;player_id&quot;:&quot;...&quot;}}</code>
when the token is accepted, or <code>{&quot;type&quot;:&quot;error&quot;,&quot;payload&quot;:{&quot;reason&quot;:&quot;invalid_payload&quot;}}</code>
if the field name is wrong. After successful auth the server routes
match/matchmaker/chat/world events to this player. Other message types the server handles: <code>matchmaker.add</code>,
<code>matchmaker.remove</code>, <code>match.input</code>, <code>match.join</code>, <code>match.leave</code>, <code>chat.send</code>,
<code>chat.join</code>, <code>chat.leave</code>, <code>dm.send</code>, <code>presence.update</code>, <code>vote.cast</code>,
<code>vote.veto</code>, <code>world.list</code>, <code>world.create</code>, <code>world.find_or_create</code>,
<code>world.join</code>, <code>world.leave</code>, <code>session.heartbeat</code>.</p>
<p>Server-pushed event types follow the pattern <code>{domain}.{event}</code> — notably:
<code>match.matched</code> (matched into a game), <code>match.state</code> (full state push),
<code>match.finished</code>, <code>world.tick</code>, <code>world.terrain</code>, <code>chat.message</code>,
<code>dm.message</code>, <code>error</code>.</p>
<h3 id="phase-3-port-the-game-logic-2-days-2-weeks" tabindex="-1">Phase 3 — port the game logic (2 days – 2 weeks)</h3>
<p>You have two choices here.</p>
<p><strong>Option A — keep your existing game server.</strong> If you've got a lot of C#/Go
server code you'd rather not rewrite, keep running it in its own container
on Hetzner / Fly / Scaleway. Use asobi for auth, matchmaking, lobbies,
leaderboards, and persistence. When the matchmaker fires <code>match.matched</code>,
the client has a <code>session_token</code> from asobi — pass it (plus <code>player_id</code> and
<code>match_id</code>) to your game server over your own connection, and have your
game server validate the token with asobi before accepting input.</p>
<blockquote>
<p><strong>Reality check:</strong> the public asobi library does not ship a built-in
&quot;server-to-server token validation&quot; endpoint today — token verification
on your own server means calling <code>POST /api/v1/auth/refresh</code> with the
token, or adding a small validation route yourself. If this is a blocker
for you, ping us in Discord — it's a natural library addition and we'll
prioritise it.</p>
</blockquote>
<p><strong>Option B — fold the game logic into Lua.</strong> Rewrite your tick / input /
state logic as a <code>match.lua</code> file. The callbacks are:</p>
<pre><code class="language-lua">function init(config)         -- once per match
function join(player_id, state)
function leave(player_id, state)
function handle_input(player_id, input, state)
function tick(state)           -- default 10Hz, configurable
function get_state(player_id, state)   -- per-player view
</code></pre>
<p>For most Hathora games this is a few hundred lines of Lua. You get hot
reload for free (edit + save + live matches update) and you delete a
container.</p>
<h3 id="phase-4-cut-over-1-day" tabindex="-1">Phase 4 — cut over (1 day)</h3>
<p>Flip a feature flag in the client to point at the asobi endpoint. Monitor
for 24h. Shut Hathora down.</p>
<h2 id="deploy-story" tabindex="-1">Deploy story</h2>
<p>You can run asobi anywhere Docker runs. Common choices:</p>
<table>
<thead>
<tr>
<th>Host</th>
<th>Fit</th>
<th>Rough cost</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Hetzner Cloud</strong> (CX22–CX42)</td>
<td>Best price/perf. EU-only if that matters.</td>
<td>€4–15 / month</td>
</tr>
<tr>
<td><strong>Scaleway Serverless</strong></td>
<td>Auto-scale for dev / low traffic</td>
<td>Free tier → pay per req</td>
</tr>
<tr>
<td><strong>Fly.io</strong></td>
<td>Multi-region one-liner</td>
<td>$5+/month/region</td>
</tr>
<tr>
<td><strong>Clever Cloud</strong></td>
<td>git-push deploy, EU</td>
<td>€10+/month</td>
</tr>
<tr>
<td><strong>Your laptop</strong></td>
<td>Development / LAN party</td>
<td>—</td>
</tr>
</tbody>
</table>
<p>Typical Hathora cost for a small-indie game was <strong>$200–800 / month</strong> on
process-hours. The same game on asobi at Hetzner is <strong>€5–20 / month</strong>,
often 10–40× cheaper.</p>
<h2 id="pricing-comparison" tabindex="-1">Pricing comparison</h2>
<table>
<thead>
<tr>
<th></th>
<th>Hathora (pre-shutdown)</th>
<th>asobi self-host</th>
<th>asobi managed (soon)</th>
</tr>
</thead>
<tbody>
<tr>
<td>Pricing model</td>
<td>Process-hours ($0.03–0.15/hr) + bandwidth</td>
<td>Flat infra cost you choose</td>
<td>Flat per-container</td>
</tr>
<tr>
<td>Free tier</td>
<td>Small credit</td>
<td>Unlimited</td>
<td>TBD</td>
</tr>
<tr>
<td>100 CCU</td>
<td>~$50–150/mo</td>
<td>€5–15/mo infra</td>
<td>~€9/mo</td>
</tr>
<tr>
<td>1,000 CCU</td>
<td>~$300–800/mo</td>
<td>€15–50/mo infra</td>
<td>~€29/mo</td>
</tr>
<tr>
<td>Bandwidth surcharges</td>
<td>Yes</td>
<td>No (infra cost)</td>
<td>No</td>
</tr>
<tr>
<td>Multi-region</td>
<td>First-class, auto</td>
<td>DIY (one container per region)</td>
<td>Per-region tier</td>
</tr>
</tbody>
</table>
<h2 id="self-hosted-hathora-users" tabindex="-1">Self-hosted Hathora users</h2>
<p>If you run <code>hathora-core</code> on your own infra, your situation is better: you
still own the stack. You can keep running it as long as it works. But the
same migration strategy applies when you decide to move — asobi's single
container + Postgres is operationally simpler than Hathora's Go monolith +
Redis + Cockroach.</p>
<h2 id="things-asobi-does-not-do-yet" tabindex="-1">Things asobi does NOT do (yet)</h2>
<p>Be honest with yourself before committing:</p>
<ul>
<li><strong>No UDP transport.</strong> WebSocket/TCP only. If you're a twitch FPS /
fighting game / racing game that needs sub-3ms physics, pair asobi with a
UDP relay (Photon, ENet server, custom). Use asobi for auth / matchmaker
/ economy / leaderboard / social.</li>
<li><strong>No anonymous-login shortcut.</strong> Auth is <code>username+password</code> or OAuth.
If your Hathora game used <code>loginAnonymous</code>, you'll generate a random
username/password in the client and persist it locally, or wire OAuth.</li>
<li><strong>No server-to-server token validation endpoint</strong> in the public library
(see Option A note above).</li>
<li><strong>No auto multi-region.</strong> Deploy one container per region yourself.</li>
<li><strong>No client-side prediction / rollback netcode primitives.</strong> On the
roadmap.</li>
<li><strong>Pre-1.0 API.</strong> Minor breaking changes possible until 1.0.</li>
<li><strong>Managed cloud opens later in 2026</strong> — today, self-host.</li>
</ul>
<h2 id="do-this-today" tabindex="-1">Do this today</h2>
<ul>
<li>[ ] <code>git clone</code> <a href="https://github.com/widgrensit/asobi_lua">asobi_lua</a> and
bring up <code>docker compose up</code> locally. Register a player. Confirm it works.</li>
<li>[ ] Pick a single SDK call in your client to port first (usually
<code>loginAnonymous</code>). Get it compiling against asobi.</li>
<li>[ ] Join the <a href="https://discord.gg/vYSfYYyXpu">Discord</a>. We'll help you debug.</li>
<li>[ ] Decide Option A (keep game server) vs Option B (Lua rewrite). Open
a thread in <a href="https://github.com/widgrensit/asobi_lua/discussions">Discussions</a>
and we'll sanity-check.</li>
<li>[ ] Set a cutover date before 2026-05-05.</li>
</ul>
<h2 id="getting-help" tabindex="-1">Getting help</h2>
<ul>
<li><strong>Discord</strong>: <a href="https://discord.gg/vYSfYYyXpu">#migrations</a> channel</li>
<li><strong>Email</strong>: hello@asobi.dev</li>
<li><strong>GitHub Discussions</strong>: <a href="https://github.com/widgrensit/asobi_lua/discussions">widgrensit/asobi_lua/discussions</a></li>
</ul>
<p>We'll prioritise Hathora-migration support through May 2026.</p>
<h2 id="see-also" tabindex="-1">See also</h2>
<ul>
<li><a href="https://hexdocs.pm/asobi/migrate-from-playfab.html">Migrating from PlayFab</a></li>
<li><a href="https://hexdocs.pm/asobi/migrate-from-nakama.html">Migrating from Nakama self-host</a></li>
<li><a href="https://hexdocs.pm/asobi/exit.html">Exit guarantee</a> — if asobi disappears tomorrow</li>
<li><a href="https://hexdocs.pm/asobi/comparison.html">Comparison vs Nakama, Colyseus, SpacetimeDB</a></li>
</ul>
"""}
    ]}.
