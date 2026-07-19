%% GENERATED from asobi guides/migrate-from-playfab.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_migrate_playfab_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

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
<p>If you're reading this, you've probably been through the PlayFab v2
migration, watched features quietly get removed, or watched your Azure
bill climb while the product got thinner. You're not alone — the
<a href="https://medium.com/@imperium42/the-silent-death-of-playfab-29614f5b9f15">Imperium42 write-up</a>
catalogues the situation far better than we can.</p>
<p>This guide walks you from &quot;my PlayFab stack is working but brittle&quot; to
&quot;I run my game on a Docker container I own.&quot;</p>
<blockquote>
<p><strong>Draft notice.</strong> This guide is a starting point, not a playbook — nobody
has yet migrated a shipped PlayFab title to asobi end-to-end. The
asobi-side endpoints and events below are verified against the current
code. PlayFab-side SDK names come from the public PlayFab documentation
and may have drifted. <strong>The fastest path is pairing with us in the
<a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code> channel.</strong></p>
</blockquote>
<h2 id="tldr" tabindex="-1">TL;DR</h2>
<ol>
<li>Your Unity/Unreal/JS game keeps shipping. You don't touch the client.</li>
<li>Stand up asobi in parallel on Hetzner / Fly / your laptop.</li>
<li>Port one PlayFab API domain at a time — usually <strong>Auth → Player
Inventory → Virtual Currency → Leaderboards → Matchmaking</strong>, in that
order.</li>
<li>When all domains are ported, flip a feature flag to point at asobi and
retire the PlayFab Title.</li>
</ol>
<h2 id="why-asobi-specifically" tabindex="-1">Why asobi specifically</h2>
<ul>
<li><strong>Apache-2.0, open-source, self-hostable.</strong> Not a Microsoft product, not
a SaaS. The repos are <a href="https://github.com/widgrensit/asobi">widgrensit/asobi</a>
and <a href="https://github.com/widgrensit/asobi_lua">widgrensit/asobi_lua</a>. See
the <a href="https://hexdocs.pm/asobi/exit.html">exit guide</a> if you want to know what happens if <em>we</em>
disappear.</li>
<li><strong>Flat infra cost.</strong> PlayFab Essentials starts free but scales steeply
through compute-based tiers, Data Explorer add-ons, and dedicated
multiplayer server VMs. asobi is a single container whose cost you
control — a small Hetzner box (€5-15/mo) comfortably holds thousands of
players.</li>
<li><strong>Linux dedicated servers work.</strong> Unlike PlayFab's Unreal OSS SDK which
historically forced Windows hosts (and their licensing costs), asobi
just runs in any Linux container.</li>
<li><strong>Hot-reload Lua.</strong> Ship a fix at 11pm. Connected players stay connected.</li>
<li><strong>One matchmaking service.</strong> Not three (Client::Matchmaker, Multiplayer
Matchmaking 2.0, OSS SDK) with no canonical guidance — just
<code>asobi_matchmaker</code> with pluggable strategies.</li>
<li><strong>Friends work.</strong> Request, approve, block — all in the library.</li>
<li><strong>Lobbies hold state.</strong> Our matchmaker tickets + match &quot;waiting&quot; phase
replace the v1 Lobby. Not the stateless read-only v2 Lobby that broke
half the games on PlayFab.</li>
</ul>
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
<td><strong>Title</strong></td>
<td>Tenant / deployment</td>
<td>One Docker container per environment (dev/live).</td>
</tr>
<tr>
<td><strong>TitleId</strong> + SDK config</td>
<td>Base URL of your asobi deployment</td>
<td>No opaque ID — you point the SDK at a URL.</td>
</tr>
<tr>
<td><strong>Entity (<code>master_player_account</code>)</strong></td>
<td>Player</td>
<td>Same concept: durable ID + profile.</td>
</tr>
<tr>
<td><strong>Virtual Currency</strong></td>
<td>Economy</td>
<td><code>game.economy.grant</code>, <code>debit</code>, <code>balance</code>, <code>purchase</code>. Multiple named currencies; per-player ledgers.</td>
</tr>
<tr>
<td><strong>Catalog</strong></td>
<td>Store + inventory</td>
<td><code>asobi_store_listing</code> + <code>asobi_item_def</code> tables; <code>/api/v1/store</code>.</td>
</tr>
<tr>
<td><strong>Inventory</strong></td>
<td>Inventory</td>
<td><code>game.player_items</code> in Lua / <code>/api/v1/inventory</code> REST.</td>
</tr>
<tr>
<td><strong>CloudScript (JS functions)</strong></td>
<td>Lua in <code>match.lua</code> + REST controllers</td>
<td>Your server logic runs as part of the match process — no separate Functions runtime, no cold starts.</td>
</tr>
<tr>
<td><strong>Matchmaking (Queue)</strong></td>
<td><code>asobi_matchmaker</code></td>
<td>Strategies: <code>fill</code>, <code>skill_based</code>, or bring your own via <code>asobi_matchmaker_strategy</code>.</td>
</tr>
<tr>
<td><strong>Multiplayer Server (Build)</strong></td>
<td>Match process</td>
<td>No container-per-match. One Docker container hosts thousands of matches as BEAM processes. Simpler ops, cheaper.</td>
</tr>
<tr>
<td><strong>Data → Player → KeyValue</strong></td>
<td><code>/api/v1/storage/:collection/:key</code></td>
<td>Per-player and shared collections with public/owner/none permissions.</td>
</tr>
<tr>
<td><strong>Data → Title Data</strong></td>
<td><code>/api/v1/storage/global/:key</code></td>
<td>Use a well-known collection.</td>
</tr>
<tr>
<td><strong>Data → Title Internal Data</strong></td>
<td>Erlang <code>sys.config</code> or Kura schema</td>
<td>Sensitive config stays out of the API.</td>
</tr>
<tr>
<td><strong>Leaderboards + Statistics</strong></td>
<td>Leaderboards (<code>/api/v1/leaderboards/:id</code>)</td>
<td>ETS for microsecond reads, Postgres for persistence.</td>
</tr>
<tr>
<td><strong>Friends list</strong></td>
<td>Friends (<code>/api/v1/friends</code>)</td>
<td>Request / approve / block / update status all work.</td>
</tr>
<tr>
<td><strong>Player Groups</strong></td>
<td>Groups (<code>/api/v1/groups</code>)</td>
<td>Roles, member management, chat channel per group.</td>
</tr>
<tr>
<td><strong>Push Notifications</strong></td>
<td>Notifications table + WS push</td>
<td><code>match.notification</code> event or polled via <code>/api/v1/notifications</code>.</td>
</tr>
<tr>
<td><strong>PlayFab Party (voice/chat)</strong></td>
<td>Chat channels + DM</td>
<td>Text only. For voice, pair asobi with Vivox / Dissonance / a WebRTC service.</td>
</tr>
<tr>
<td><strong>Receipt validation (IAP)</strong></td>
<td><code>/api/v1/iap/apple</code>, <code>/api/v1/iap/google</code></td>
<td>Verifies Apple App Store and Google Play receipts.</td>
</tr>
<tr>
<td><strong>Automation rules / webhooks</strong></td>
<td>Shigoto jobs</td>
<td>Write the rule as an Erlang callback or Lua handler.</td>
</tr>
<tr>
<td><strong>Insights / Analytics</strong></td>
<td><code>asobi_telemetry</code> + your pipeline</td>
<td>We emit telemetry; pipe to Prometheus / Grafana / ClickHouse. No hosted analytics yet.</td>
</tr>
<tr>
<td><strong>Game Manager (web console)</strong></td>
<td><a href="https://github.com/widgrensit/asobi_admin">asobi_admin</a></td>
<td>Players, leaderboards, economy, chat. Pre-1.0.</td>
</tr>
</tbody>
</table>
<h2 id="migration-path" tabindex="-1">Migration path</h2>
<h3 id="phase-1-stand-up-asobi-alongside-playfab-1-day" tabindex="-1">Phase 1 — stand up asobi alongside PlayFab (1 day)</h3>
<p>Bring up asobi on a spare machine:</p>
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
<pre><code class="language-bash">docker compose up -d
curl localhost:8084/api/v1/auth/register \
  -H 'content-type: application/json' \
  -d '{&quot;username&quot;:&quot;alice&quot;,&quot;password&quot;:&quot;hunter2&quot;}'
# → { &quot;player_id&quot;: &quot;...&quot;, &quot;session_token&quot;: &quot;...&quot;, &quot;username&quot;: &quot;alice&quot; }
</code></pre>
<h3 id="phase-2-port-auth-2-5-days" tabindex="-1">Phase 2 — port Auth (2-5 days)</h3>
<p>PlayFab auth paths map 1:1:</p>
<p><code>LoginWithCustomID</code> maps directly to guest auth - Asobi handles create-or-resume
server-side, so there is no client-generated password to persist:</p>
<pre><code class="language-csharp">// Before (PlayFab)
PlayFabClientAPI.LoginWithCustomID(new LoginWithCustomIDRequest {
  CustomId = deviceId, CreateAccount = true
}, OnSuccess, OnError);

// After (asobi) — anonymous guest, create-or-resume from a device-held secret
var client = new AsobiClient(&quot;https://api.my-game.com&quot;);
await client.Auth.GuestAsync(deviceId, deviceSecret);   // POST /auth/guest
// later, when the player signs up for real:
// await client.Auth.UpgradeGuestAsync(username, password);
</code></pre>
<p>Store <code>deviceSecret</code> (&gt;= 32 random bytes) in secure device storage; see the
<a href="/docs/authentication#guest-anonymous">Authentication guide</a>.</p>
<p>OAuth providers (Google, Apple, Steam) go through
<code>POST /api/v1/auth/oauth</code> — same as PlayFab's <code>LoginWithGoogleAccount</code> etc.</p>
<h3 id="phase-3-port-the-data-domains-one-at-a-time-1-2-weeks" tabindex="-1">Phase 3 — port the data domains one at a time (1-2 weeks)</h3>
<p>Run PlayFab and asobi in parallel. For each domain:</p>
<ul>
<li>Migrate the PlayFab data snapshot to asobi's Postgres schema (one-off
script per domain)</li>
<li>Dual-write: the client hits PlayFab AND asobi for the same action</li>
<li>Read from asobi; diff vs PlayFab for a day</li>
<li>Switch reads to asobi; keep PlayFab dual-write for rollback</li>
<li>After a week of clean asobi reads, stop writing to PlayFab</li>
</ul>
<p>Order: <strong>Leaderboards → Inventory → Virtual Currency → Storage → Friends →
Groups → Matchmaking</strong>. Leave matchmaking last because it's the most
stateful handoff.</p>
<h3 id="phase-4-port-cloudscript-2-days-2-weeks" tabindex="-1">Phase 4 — port CloudScript (2 days – 2 weeks)</h3>
<p>Rewrite each CloudScript function either as:</p>
<ul>
<li>A <strong>Lua callback</strong> in <code>match.lua</code> (for per-match logic — e.g.
<code>handle_input</code>, <code>tick</code>)</li>
<li>An <strong>asobi REST controller</strong> in Erlang (for domain logic — economy
rules, tournament brackets, daily quest resets)</li>
</ul>
<p>If your PlayFab workload is CloudScript-heavy, budget more time for this
phase. The upside: hot-reload replaces the CloudScript deploy loop.</p>
<h3 id="phase-5-cut-over-1-day" tabindex="-1">Phase 5 — cut over (1 day)</h3>
<p>Flip the SDK base URL from PlayFab to your asobi endpoint via a feature
flag. Monitor for 24h. Retire the PlayFab Title.</p>
<h2 id="deploy-story" tabindex="-1">Deploy story</h2>
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
<td>Best price/perf. EU-only.</td>
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
<td><strong>On-prem (your datacentre)</strong></td>
<td>Regulated / sovereign workloads</td>
<td>Your hardware cost</td>
</tr>
</tbody>
</table>
<p>A studio running PlayFab Multiplayer Servers at, say, $300/month in VM
credits typically fits on a €15/month Hetzner CX32 box with asobi.</p>
<h2 id="things-asobi-does-not-do-compared-to-playfab" tabindex="-1">Things asobi does NOT do (compared to PlayFab)</h2>
<ul>
<li><strong>No hosted analytics dashboard.</strong> We emit telemetry; you pipe it
somewhere. PlayFab Insights is the biggest DX gap.</li>
<li><strong>No built-in A/B testing / segmentation framework.</strong> Coming in 2026. For
now, roll it in your match logic.</li>
<li><strong>No push notification service.</strong> Use OneSignal, Firebase Cloud
Messaging, or APNs directly.</li>
<li><strong>No hosted voice.</strong> Pair with Vivox / Dissonance / Agora.</li>
<li><strong>No Title-as-a-product support tools</strong> (refunds portal, player support
console). On the admin dashboard roadmap.</li>
<li><strong>No mandated Entity model.</strong> asobi is pragmatic: player_id is the
primary key; you don't have to model everything as Entity-With-Objects.</li>
</ul>
<h2 id="things-asobi-does-that-playfab-doesnt" tabindex="-1">Things asobi does that PlayFab doesn't</h2>
<ul>
<li>Hot-reload game logic without dropping players</li>
<li>Open-source — read the code, fork it, own it</li>
<li>Linux servers are first-class</li>
<li>One unified matchmaker, not three competing services</li>
<li>Friends / groups / chat / votes / tournaments / seasons / phases as
first-class primitives, not bolt-ons</li>
<li>Built-in voting system (plurality, ranked, approval, weighted)</li>
<li>Godot and Defold SDKs at engine-parity with Unity</li>
</ul>
<h2 id="cost-comparison" tabindex="-1">Cost comparison</h2>
<table>
<thead>
<tr>
<th></th>
<th>PlayFab Essentials</th>
<th>PlayFab paid</th>
<th>asobi self-host</th>
<th>asobi managed (soon)</th>
</tr>
</thead>
<tbody>
<tr>
<td>Base</td>
<td>Free tier</td>
<td>$99+/mo</td>
<td>€5–20/mo infra</td>
<td>~€9–29/mo</td>
</tr>
<tr>
<td>Multiplayer servers</td>
<td>N/A</td>
<td>VM-minute billing</td>
<td>Same container</td>
<td>Included</td>
</tr>
<tr>
<td>Analytics add-ons</td>
<td>Limited</td>
<td>Data Explorer metered</td>
<td>Bring your own stack</td>
<td>Bring your own</td>
</tr>
<tr>
<td>Egress</td>
<td>N/A</td>
<td>Azure rates</td>
<td>Your host's rates</td>
<td>Flat</td>
</tr>
<tr>
<td>Vendor lock-in</td>
<td>High (Azure)</td>
<td>High</td>
<td>None (Apache-2)</td>
<td>Exit runbook</td>
</tr>
</tbody>
</table>
<h2 id="do-this-today" tabindex="-1">Do this today</h2>
<ul>
<li>[ ] <code>git clone</code> <a href="https://github.com/widgrensit/asobi_lua">asobi_lua</a> and
<code>docker compose up</code>. Register a player. Confirm it works.</li>
<li>[ ] Pick the smallest PlayFab API your game calls (often leaderboards
or a single CloudScript function). Port it to asobi in a feature flag.</li>
<li>[ ] Join the <a href="https://discord.gg/vYSfYYyXpu">Discord</a> <code>#migrations</code>
channel. We'll sanity-check your staging order.</li>
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
<li><a href="https://hexdocs.pm/asobi/migrate-from-nakama.html">Migrating from Nakama self-host</a></li>
<li><a href="https://hexdocs.pm/asobi/exit.html">Exit guarantee</a></li>
<li><a href="https://hexdocs.pm/asobi/comparison.html">Comparison vs Nakama, Colyseus, SpacetimeDB</a></li>
</ul>
"""}
    ]}.
