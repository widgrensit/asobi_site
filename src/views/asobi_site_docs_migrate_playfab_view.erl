%% GENERATED from asobi guides/migrate-from-playfab.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_migrate_playfab_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1, markdown/0]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-migrate-playfab", title => ~"Migrate from PlayFab — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Migrate / PlayFab"
        ]},
        {h1, [], [~"Migrating from PlayFab to asobi"]},
        {raw,
            ~"""
<p>For studios who have been through the PlayFab v2 migration, watched features
get removed, or watched the Azure bill climb while the product got thinner. The
<a href="https://medium.com/@imperium42/the-silent-death-of-playfab-29614f5b9f15">Imperium42 write-up</a>
catalogues the situation.</p>
<p>Nobody has migrated a shipped PlayFab title to asobi end to end yet. The
asobi-side endpoints and events below are verified against this repository;
PlayFab-side names come from Microsoft's public documentation. Pair with us in
the <a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code> channel.</p>
<h2 id="what-asobi-is" tabindex="-1">What asobi is</h2>
<p>One Erlang/OTP node containing the game backend, the Lua runtime and the
operator console. Two ways in: run <code>ghcr.io/widgrensit/asobi</code> and write Lua, or
depend on the Hex package and write Erlang. Same node either way. Apache-2.0,
self-hostable, and the <a href="https://hexdocs.pm/asobi/exit.html">exit guide</a> is the runbook for keeping your
game alive if we disappear.</p>
<h2 id="the-shape-of-the-move" tabindex="-1">The shape of the move</h2>
<ol>
<li>Your Unity, Unreal or JS game keeps shipping. You do not touch the client on
day one.</li>
<li>Stand up asobi in parallel.</li>
<li>Port one PlayFab API domain at a time.</li>
<li>When every domain is ported, flip a feature flag and retire the PlayFab
Title.</li>
</ol>
<h2 id="concept-map" tabindex="-1">Concept map</h2>
<table>
<thead>
<tr>
<th>PlayFab</th>
<th>asobi</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td>Title</td>
<td>Deployment</td>
<td>One container per environment.</td>
</tr>
<tr>
<td>TitleId plus SDK config</td>
<td>Base URL of your deployment</td>
<td>No opaque ID; you point the SDK at a URL.</td>
</tr>
<tr>
<td>Entity (<code>master_player_account</code>)</td>
<td>Player</td>
<td>Durable ID plus profile.</td>
</tr>
<tr>
<td>Virtual currency</td>
<td>Economy</td>
<td><code>game.economy.grant</code>, <code>debit</code>, <code>balance</code>, <code>purchase</code> in Lua; <code>/api/v1/wallets</code> over REST. Multiple named currencies, per-player ledgers.</td>
</tr>
<tr>
<td>Catalog</td>
<td>Store plus item definitions</td>
<td><code>GET /api/v1/store</code>, <code>POST /api/v1/store/purchase</code>.</td>
</tr>
<tr>
<td>Inventory</td>
<td>Inventory</td>
<td><code>GET /api/v1/inventory</code> and <code>POST /api/v1/inventory/consume</code>, or Kura queries against the <code>asobi_player_item</code> schema (table <code>player_items</code>). There is no Lua binding for inventory.</td>
</tr>
<tr>
<td>CloudScript (JS functions)</td>
<td>Lua callbacks, or an extension RPC method</td>
<td>Per-match logic goes in <code>match.lua</code>. Anything a client calls by name goes over the WebSocket as <code>rpc.call</code> - see below the table. No separate Functions runtime, no cold starts.</td>
</tr>
<tr>
<td>Matchmaking (queue)</td>
<td><code>POST /api/v1/matchmaker</code></td>
<td>Modes plus pluggable strategies (<code>fill</code>, <code>skill_based</code>, or your own via the <code>asobi_matchmaker_strategy</code> behaviour).</td>
</tr>
<tr>
<td>Multiplayer Server (build)</td>
<td>Match process</td>
<td>No container per match. One container hosts thousands of matches as BEAM processes.</td>
</tr>
<tr>
<td>Data, player key-value</td>
<td><code>/api/v1/storage/:collection/:key</code></td>
<td>Per-player rows. Permissions are <code>read_perm</code> and <code>write_perm</code>, each <code>public</code> or <code>owner</code>. There is no <code>none</code>.</td>
</tr>
<tr>
<td>Data, Title Data</td>
<td>Lua <code>game.storage.get/set</code></td>
<td>The HTTP storage routes are scoped to per-player rows, so writing to a collection called <code>global</code> gives every player their own copy. The shared, owner-less namespace is reachable from Lua only.</td>
</tr>
<tr>
<td>Data, Title Internal Data</td>
<td>Erlang <code>sys.config</code> or a Kura schema</td>
<td>Sensitive config stays off the player-facing API.</td>
</tr>
<tr>
<td>Leaderboards and statistics</td>
<td><code>/api/v1/leaderboards/:id</code></td>
<td>ETS for reads, PostgreSQL for persistence.</td>
</tr>
<tr>
<td>Friends list</td>
<td><code>/api/v1/friends</code></td>
<td>Request, approve, block, update status.</td>
</tr>
<tr>
<td>Player groups</td>
<td><code>/api/v1/groups</code></td>
<td>Roles, member management, a chat channel per group.</td>
</tr>
<tr>
<td>Push notifications</td>
<td>Notifications plus a WebSocket push</td>
<td><code>GET /api/v1/notifications</code>, or the <code>notification.new</code> frame on the socket. This is in-game delivery, not APNs or FCM.</td>
</tr>
<tr>
<td>PlayFab Party (voice and chat)</td>
<td>Chat channels plus DMs</td>
<td>Text only. For voice, pair asobi with a voice service.</td>
</tr>
<tr>
<td>Receipt validation (IAP)</td>
<td><code>POST /api/v1/iap/apple</code>, <code>/api/v1/iap/google</code></td>
<td>Verifies an Apple or Google receipt and records it once per transaction.</td>
</tr>
<tr>
<td>Granting from a receipt</td>
<td>Your game's job</td>
<td>Nothing is granted by the IAP endpoints. Turn a verified receipt into currency or items yourself through the economy or inventory API.</td>
</tr>
<tr>
<td>Automation rules and webhooks</td>
<td>Shigoto jobs</td>
<td>Written as an Erlang callback.</td>
</tr>
<tr>
<td>Insights and analytics</td>
<td><code>asobi_telemetry</code> plus your own pipeline</td>
<td>Telemetry is emitted; there is no hosted analytics.</td>
</tr>
<tr>
<td>Game Manager (web console)</td>
<td>Built-in operator console at <code>/console</code></td>
<td>Off by default, and reads plus player erasure/export. See the note below the table.</td>
</tr>
</tbody>
</table>
<p>Custom server-side logic that is not tied to a match goes over the WebSocket:
frame type <code>rpc.call</code> with <code>{protocol: 1, method, params}</code>, answered by
<code>rpc.ok</code> <code>{result}</code> or <code>rpc.error</code> <code>{error: {code, message, details}}</code>,
correlated by <code>cid</code>. All seven client SDKs support it. That is the CloudScript
replacement. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</p>
<p>A stock node serves neither the console nor the ops API; you turn them on - see
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>. When you do, the plane is reads plus player
erasure and export, apart from actions an extension declares. If you use Game Manager to ban a player, refund a
purchase or edit a catalogue item, budget for building that yourself.</p>
<h2 id="migration-path" tabindex="-1">Migration path</h2>
<h3 id="phase-1---stand-up-asobi-alongside-playfab-1-day" tabindex="-1">Phase 1 - stand up asobi alongside PlayFab (1 day)</h3>
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
      ASOBI_CORS_ORIGINS: &quot;https://play.my-game.com&quot;
      ASOBI_CONSOLE: &quot;true&quot;
      ASOBI_OPS_SECRET_FILE: /run/secrets/ops_secret
    secrets: [ops_secret]

secrets:
  ops_secret:
    file: ./ops_secret.txt
</code></pre>
<p><code>./lua</code> must contain a <code>match.lua</code> before the matchmaker has anything to match
on - <a href="https://hexdocs.pm/asobi/getting-started.html">Getting started</a> has a complete one. Without it,
<code>POST /api/v1/matchmaker</code> answers <code>matchmaker.unknown_mode</code>.</p>
<p><code>ASOBI_CORS_ORIGINS</code> is not optional for a browser build: unset, the node sends
an empty <code>Access-Control-Allow-Origin</code> and every fetch from a page is blocked.</p>
<pre><code class="language-bash">docker compose up -d
curl -s localhost:8084/api/v1/auth/register \
  -H 'content-type: application/json' \
  -d '{&quot;username&quot;:&quot;alice&quot;,&quot;password&quot;:&quot;hunter2&quot;}'
# { &quot;player_id&quot;: &quot;019de3...&quot;, &quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;, &quot;username&quot;: &quot;alice&quot; }
</code></pre>
<p>There is no <code>session_token</code>. <code>access_token</code> is the Bearer credential;
<code>refresh_token</code> buys a new pair from <code>POST /api/v1/auth/refresh</code>. Requirements
and the production compose are in <a href="https://hexdocs.pm/asobi/self-hosting.html">Self-hosting</a>.</p>
<h3 id="phase-2---port-auth-2-5-days" tabindex="-1">Phase 2 - port auth (2-5 days)</h3>
<p><code>LoginWithCustomID</code> maps to guest auth. The client generates a random
<code>device_secret</code> of at least 32 bytes on first launch and posts it with a stable
<code>device_id</code>; the server creates the player, or resumes it on later launches:</p>
<pre><code class="language-bash">curl -s localhost:8084/api/v1/auth/guest \
  -H 'content-type: application/json' \
  -d '{&quot;device_id&quot;:&quot;&lt;stable device id&gt;&quot;,&quot;device_secret&quot;:&quot;&lt;base64 of &gt;= 32 random bytes&gt;&quot;}'
</code></pre>
<p>Treat <code>device_secret</code> as that account's password and keep it in secure device
storage; every SDK does this for you. Claim the account later with
<code>POST /api/v1/auth/guest/upgrade</code>.</p>
<p>Guest auth is opt-in and off until two things are true: the game declares
<code>guest_auth</code> in its Lua config, and the operator supplies a pepper of at least
32 bytes. Either one missing and the endpoint answers <code>guest.disabled</code>. See
<a href="/docs/authentication">Authentication</a>.</p>
<p>OAuth providers go through <code>POST /api/v1/auth/oauth</code>, replacing
<code>LoginWithGoogleAccount</code> and friends.</p>
<h3 id="phase-3---port-the-data-domains-one-at-a-time-1-2-weeks" tabindex="-1">Phase 3 - port the data domains one at a time (1-2 weeks)</h3>
<p>Run PlayFab and asobi in parallel. Per domain:</p>
<ul>
<li>Migrate the PlayFab snapshot into asobi's Postgres schema with a one-off
script.</li>
<li>Dual-write: the client hits both for the same action.</li>
<li>Read from asobi, diff against PlayFab for a day.</li>
<li>Switch reads to asobi, keep the PlayFab write for rollback.</li>
<li>After a week of clean reads, stop writing to PlayFab.</li>
</ul>
<p>Order: leaderboards, inventory, virtual currency, storage, friends, groups,
matchmaking. Matchmaking last, because it is the most stateful handoff.</p>
<h3 id="phase-4---port-cloudscript-2-days-to-2-weeks" tabindex="-1">Phase 4 - port CloudScript (2 days to 2 weeks)</h3>
<p>Each CloudScript function becomes one of three things:</p>
<ul>
<li>A Lua callback in <code>match.lua</code>, for per-match logic.</li>
<li>An extension RPC method, for anything a client calls by name. This is the
closest equivalent and the one most CloudScript functions map onto. See
<a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</li>
<li>A Shigoto job, for scheduled work such as a daily reset.</li>
</ul>
<p>The upside is that live Lua reload replaces the CloudScript deploy loop.</p>
<h3 id="phase-5---cut-over-1-day" tabindex="-1">Phase 5 - cut over (1 day)</h3>
<p>Flip the SDK base URL behind a feature flag. Monitor for 24h. Retire the
PlayFab Title.</p>
<h2 id="what-asobi-does-not-do" tabindex="-1">What asobi does not do</h2>
<ul>
<li>No hosted analytics dashboard. Telemetry is emitted; you pipe it somewhere.
This is the biggest gap against PlayFab Insights.</li>
<li>No A/B testing or segmentation framework.</li>
<li>No push notification service. Use APNs, FCM or a third party directly; the
built-in notifications are in-game only.</li>
<li>No hosted voice.</li>
<li>Little player-support tooling. The console erases and exports a player;
refunds, bans and grants are your own code.</li>
<li>No Entity model. <code>player_id</code> is the primary key and you are not required to
model everything as an entity with objects.</li>
</ul>
<h2 id="what-asobi-does-that-playfab-does-not" tabindex="-1">What asobi does that PlayFab does not</h2>
<ul>
<li>Live Lua reload without dropping players.</li>
<li>Open source: read it, fork it, run it.</li>
<li>Linux servers throughout.</li>
<li>One matchmaker rather than several overlapping services.</li>
<li>Friends, groups, chat, votes, tournaments and phases as first-class
primitives; seasons ship as the
<a href="https://github.com/widgrensit/asobi_seasons"><code>asobi_seasons</code></a> extension.</li>
<li>Built-in voting: plurality, ranked, approval, weighted.</li>
<li>First-class Godot, Defold and LÖVE SDKs alongside Unity, Unreal, JS and
Dart, plus a Flame bridge on top of the Dart one.</li>
</ul>
<h2 id="cost" tabindex="-1">Cost</h2>
<p>PlayFab bills tiers, metered analytics and VM-minute multiplayer servers. asobi
is a container whose cost you choose, plus a Postgres. A single node holds
3,000-7,000 concurrent WebSocket connections in measurement - see
<a href="https://hexdocs.pm/asobi/benchmarks.html">Benchmarks</a> - so most studios' first deployment is one small
machine.</p>
<p>If you plan to run more than one node, read <a href="/docs/clustering">Clustering</a> first:
the matchmaker queue is per node, so players queuing against different nodes
never match each other, rate limits are per node, and the console needs a
sticky route.</p>
<h2 id="do-this-today" tabindex="-1">Do this today</h2>
<ul>
<li>Run the Phase 1 compose locally and register a player.</li>
<li>Pick the smallest PlayFab API your game calls, usually leaderboards or one
CloudScript function, and port it behind a feature flag.</li>
<li>Join the <a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code> channel.</li>
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
<li><a href="https://hexdocs.pm/asobi/migrate-from-nakama.html">Migrating from Nakama self-host</a></li>
<li><a href="https://hexdocs.pm/asobi/exit.html">Exit guarantee</a></li>
<li><a href="https://hexdocs.pm/asobi/comparison.html">Comparison</a></li>
</ul>
"""}
    ]}.

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Migrating from PlayFab to asobi

For studios who have been through the PlayFab v2 migration, watched features
get removed, or watched the Azure bill climb while the product got thinner. The
[Imperium42 write-up](https://medium.com/@imperium42/the-silent-death-of-playfab-29614f5b9f15)
catalogues the situation.

Nobody has migrated a shipped PlayFab title to asobi end to end yet. The
asobi-side endpoints and events below are verified against this repository;
PlayFab-side names come from Microsoft's public documentation. Pair with us in
the [Discord](https://discord.gg/vYSfYYyXpu) `#migrations` channel.

## What asobi is

One Erlang/OTP node containing the game backend, the Lua runtime and the
operator console. Two ways in: run `ghcr.io/widgrensit/asobi` and write Lua, or
depend on the Hex package and write Erlang. Same node either way. Apache-2.0,
self-hostable, and the [exit guide](https://hexdocs.pm/asobi/exit.html) is the runbook for keeping your
game alive if we disappear.

## The shape of the move

1. Your Unity, Unreal or JS game keeps shipping. You do not touch the client on
   day one.
2. Stand up asobi in parallel.
3. Port one PlayFab API domain at a time.
4. When every domain is ported, flip a feature flag and retire the PlayFab
   Title.

## Concept map

| PlayFab | asobi | Notes |
|---|---|---|
| Title | Deployment | One container per environment. |
| TitleId plus SDK config | Base URL of your deployment | No opaque ID; you point the SDK at a URL. |
| Entity (`master_player_account`) | Player | Durable ID plus profile. |
| Virtual currency | Economy | `game.economy.grant`, `debit`, `balance`, `purchase` in Lua; `/api/v1/wallets` over REST. Multiple named currencies, per-player ledgers. |
| Catalog | Store plus item definitions | `GET /api/v1/store`, `POST /api/v1/store/purchase`. |
| Inventory | Inventory | `GET /api/v1/inventory` and `POST /api/v1/inventory/consume`, or Kura queries against the `asobi_player_item` schema (table `player_items`). There is no Lua binding for inventory. |
| CloudScript (JS functions) | Lua callbacks, or an extension RPC method | Per-match logic goes in `match.lua`. Anything a client calls by name goes over the WebSocket as `rpc.call` - see below the table. No separate Functions runtime, no cold starts. |
| Matchmaking (queue) | `POST /api/v1/matchmaker` | Modes plus pluggable strategies (`fill`, `skill_based`, or your own via the `asobi_matchmaker_strategy` behaviour). |
| Multiplayer Server (build) | Match process | No container per match. One container hosts thousands of matches as BEAM processes. |
| Data, player key-value | `/api/v1/storage/:collection/:key` | Per-player rows. Permissions are `read_perm` and `write_perm`, each `public` or `owner`. There is no `none`. |
| Data, Title Data | Lua `game.storage.get/set` | The HTTP storage routes are scoped to per-player rows, so writing to a collection called `global` gives every player their own copy. The shared, owner-less namespace is reachable from Lua only. |
| Data, Title Internal Data | Erlang `sys.config` or a Kura schema | Sensitive config stays off the player-facing API. |
| Leaderboards and statistics | `/api/v1/leaderboards/:id` | ETS for reads, PostgreSQL for persistence. |
| Friends list | `/api/v1/friends` | Request, approve, block, update status. |
| Player groups | `/api/v1/groups` | Roles, member management, a chat channel per group. |
| Push notifications | Notifications plus a WebSocket push | `GET /api/v1/notifications`, or the `notification.new` frame on the socket. This is in-game delivery, not APNs or FCM. |
| PlayFab Party (voice and chat) | Chat channels plus DMs | Text only. For voice, pair asobi with a voice service. |
| Receipt validation (IAP) | `POST /api/v1/iap/apple`, `/api/v1/iap/google` | Verifies an Apple or Google receipt and records it once per transaction. |
| Granting from a receipt | Your game's job | Nothing is granted by the IAP endpoints. Turn a verified receipt into currency or items yourself through the economy or inventory API. |
| Automation rules and webhooks | Shigoto jobs | Written as an Erlang callback. |
| Insights and analytics | `asobi_telemetry` plus your own pipeline | Telemetry is emitted; there is no hosted analytics. |
| Game Manager (web console) | Built-in operator console at `/console` | Off by default, and reads plus player erasure/export. See the note below the table. |

Custom server-side logic that is not tied to a match goes over the WebSocket:
frame type `rpc.call` with `{protocol: 1, method, params}`, answered by
`rpc.ok` `{result}` or `rpc.error` `{error: {code, message, details}}`,
correlated by `cid`. All seven client SDKs support it. That is the CloudScript
replacement. See [Extensions](https://hexdocs.pm/asobi/extensions.html).

A stock node serves neither the console nor the ops API; you turn them on - see
[Operator console](https://hexdocs.pm/asobi/console.html). When you do, the plane is reads plus player
erasure and export, apart from actions an extension declares. If you use Game Manager to ban a player, refund a
purchase or edit a catalogue item, budget for building that yourself.

## Migration path

### Phase 1 - stand up asobi alongside PlayFab (1 day)

```yaml
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: my_game
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s

  asobi:
    image: ghcr.io/widgrensit/asobi:latest
    depends_on:
      postgres: { condition: service_healthy }
    ports: ["8084:8084"]
    volumes: ["./lua:/app/game:ro"]
    environment:
      ASOBI_DB_HOST: postgres
      ASOBI_DB_NAME: my_game
      ASOBI_CORS_ORIGINS: "https://play.my-game.com"
      ASOBI_CONSOLE: "true"
      ASOBI_OPS_SECRET_FILE: /run/secrets/ops_secret
    secrets: [ops_secret]

secrets:
  ops_secret:
    file: ./ops_secret.txt
```

`./lua` must contain a `match.lua` before the matchmaker has anything to match
on - [Getting started](https://hexdocs.pm/asobi/getting-started.html) has a complete one. Without it,
`POST /api/v1/matchmaker` answers `matchmaker.unknown_mode`.

`ASOBI_CORS_ORIGINS` is not optional for a browser build: unset, the node sends
an empty `Access-Control-Allow-Origin` and every fetch from a page is blocked.

```bash
docker compose up -d
curl -s localhost:8084/api/v1/auth/register \
  -H 'content-type: application/json' \
  -d '{"username":"alice","password":"hunter2"}'
# { "player_id": "019de3...", "access_token": "...", "refresh_token": "...", "username": "alice" }
```

There is no `session_token`. `access_token` is the Bearer credential;
`refresh_token` buys a new pair from `POST /api/v1/auth/refresh`. Requirements
and the production compose are in [Self-hosting](https://hexdocs.pm/asobi/self-hosting.html).

### Phase 2 - port auth (2-5 days)

`LoginWithCustomID` maps to guest auth. The client generates a random
`device_secret` of at least 32 bytes on first launch and posts it with a stable
`device_id`; the server creates the player, or resumes it on later launches:

```bash
curl -s localhost:8084/api/v1/auth/guest \
  -H 'content-type: application/json' \
  -d '{"device_id":"<stable device id>","device_secret":"<base64 of >= 32 random bytes>"}'
```

Treat `device_secret` as that account's password and keep it in secure device
storage; every SDK does this for you. Claim the account later with
`POST /api/v1/auth/guest/upgrade`.

Guest auth is opt-in and off until two things are true: the game declares
`guest_auth` in its Lua config, and the operator supplies a pepper of at least
32 bytes. Either one missing and the endpoint answers `guest.disabled`. See
[Authentication](https://asobi.dev/docs/authentication).

OAuth providers go through `POST /api/v1/auth/oauth`, replacing
`LoginWithGoogleAccount` and friends.

### Phase 3 - port the data domains one at a time (1-2 weeks)

Run PlayFab and asobi in parallel. Per domain:

- Migrate the PlayFab snapshot into asobi's Postgres schema with a one-off
  script.
- Dual-write: the client hits both for the same action.
- Read from asobi, diff against PlayFab for a day.
- Switch reads to asobi, keep the PlayFab write for rollback.
- After a week of clean reads, stop writing to PlayFab.

Order: leaderboards, inventory, virtual currency, storage, friends, groups,
matchmaking. Matchmaking last, because it is the most stateful handoff.

### Phase 4 - port CloudScript (2 days to 2 weeks)

Each CloudScript function becomes one of three things:

- A Lua callback in `match.lua`, for per-match logic.
- An extension RPC method, for anything a client calls by name. This is the
  closest equivalent and the one most CloudScript functions map onto. See
  [Extensions](https://hexdocs.pm/asobi/extensions.html).
- A Shigoto job, for scheduled work such as a daily reset.

The upside is that live Lua reload replaces the CloudScript deploy loop.

### Phase 5 - cut over (1 day)

Flip the SDK base URL behind a feature flag. Monitor for 24h. Retire the
PlayFab Title.

## What asobi does not do

- No hosted analytics dashboard. Telemetry is emitted; you pipe it somewhere.
  This is the biggest gap against PlayFab Insights.
- No A/B testing or segmentation framework.
- No push notification service. Use APNs, FCM or a third party directly; the
  built-in notifications are in-game only.
- No hosted voice.
- Little player-support tooling. The console erases and exports a player;
  refunds, bans and grants are your own code.
- No Entity model. `player_id` is the primary key and you are not required to
  model everything as an entity with objects.

## What asobi does that PlayFab does not

- Live Lua reload without dropping players.
- Open source: read it, fork it, run it.
- Linux servers throughout.
- One matchmaker rather than several overlapping services.
- Friends, groups, chat, votes, tournaments and phases as first-class
  primitives; seasons ship as the
  [`asobi_seasons`](https://github.com/widgrensit/asobi_seasons) extension.
- Built-in voting: plurality, ranked, approval, weighted.
- First-class Godot, Defold and LÖVE SDKs alongside Unity, Unreal, JS and
  Dart, plus a Flame bridge on top of the Dart one.

## Cost

PlayFab bills tiers, metered analytics and VM-minute multiplayer servers. asobi
is a container whose cost you choose, plus a Postgres. A single node holds
3,000-7,000 concurrent WebSocket connections in measurement - see
[Benchmarks](https://hexdocs.pm/asobi/benchmarks.html) - so most studios' first deployment is one small
machine.

If you plan to run more than one node, read [Clustering](https://asobi.dev/docs/clustering) first:
the matchmaker queue is per node, so players queuing against different nodes
never match each other, rate limits are per node, and the console needs a
sticky route.

## Do this today

- Run the Phase 1 compose locally and register a player.
- Pick the smallest PlayFab API your game calls, usually leaderboards or one
  CloudScript function, and port it behind a feature flag.
- Join the [Discord](https://discord.gg/vYSfYYyXpu) `#migrations` channel.

## Getting help

- Discord: [#migrations](https://discord.gg/vYSfYYyXpu)
- Email: hello@asobi.dev
- GitHub Discussions:
  [widgrensit/asobi/discussions](https://github.com/widgrensit/asobi/discussions)

## See also

- [Migrating from Hathora](https://hexdocs.pm/asobi/migrate-from-hathora.html)
- [Migrating from Nakama self-host](https://hexdocs.pm/asobi/migrate-from-nakama.html)
- [Exit guarantee](https://hexdocs.pm/asobi/exit.html)
- [Comparison](https://hexdocs.pm/asobi/comparison.html)
""".
