%% GENERATED from asobi guides/rest-api.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_rest_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-rest", title => ~"REST API — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Protocols / REST"
        ]},
        {h1, [], [~"REST API"]},
        {raw,
            ~"""
<p>All endpoints are under <code>/api/v1</code>. Requests and responses use JSON.</p>
<p>Authenticated endpoints require the <code>Authorization: Bearer &lt;access_token&gt;</code> header.</p>
<div class="docs-callout docs-callout-info"><p class="docs-callout-title">Real-time flows go over WebSocket</p><p>Use REST for request/response. Matchmaking notifications, chat, votes,
presence, and live game state are pushed over the <a href="/docs/protocols/websocket">WebSocket
protocol</a>, not polled here.</p>
</div>
<blockquote>
<p><strong>Windows / PowerShell</strong>: examples below use <code>curl</code> (Linux, macOS, Git Bash,
WSL). In PowerShell, translate any block by hand once - the shape is the same:</p>
<pre><code class="language-powershell">Invoke-RestMethod -Uri http://localhost:8084/api/v1/auth/register `
  -Method Post -ContentType application/json `
  -Body '{&quot;username&quot;: &quot;player1&quot;, &quot;password&quot;: &quot;secret123&quot;}'
</code></pre>
<p>Add auth with <code>-Headers @{ Authorization = &quot;Bearer $token&quot; }</code>.
<code>Invoke-RestMethod</code> parses the JSON response for you, so no <code>jq</code> is needed.</p>
</blockquote>
<h2 id="auth" tabindex="-1">Auth</h2>
<pre><code>POST   /api/v1/auth/register        Register a new player
POST   /api/v1/auth/login           Login, returns session token
POST   /api/v1/auth/refresh         Refresh session token
POST   /api/v1/auth/oauth           OAuth / Steam token validation
POST   /api/v1/auth/guest           Create or resume an anonymous guest
POST   /api/v1/auth/guest/upgrade   Claim a guest account (username + password)
POST   /api/v1/auth/link            Link a provider to the current account
DELETE /api/v1/auth/unlink          Unlink a provider
</code></pre>
<h3 id="register" tabindex="-1">Register</h3>
<pre><code class="language-bash">curl -X POST /api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{&quot;username&quot;: &quot;player1&quot;, &quot;password&quot;: &quot;secret123&quot;, &quot;display_name&quot;: &quot;Player One&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;player_id&quot;: &quot;...&quot;, &quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;, &quot;username&quot;: &quot;player1&quot;}
</code></pre>
<h3 id="login" tabindex="-1">Login</h3>
<pre><code class="language-bash">curl -X POST /api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{&quot;username&quot;: &quot;player1&quot;, &quot;password&quot;: &quot;secret123&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;player_id&quot;: &quot;...&quot;, &quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;, &quot;username&quot;: &quot;player1&quot;}
</code></pre>
<h3 id="guest" tabindex="-1">Guest</h3>
<p>Anonymous device-based auth, opt-in via config. <code>POST /auth/guest</code> creates a
player on first call and resumes the same one on later calls; <code>/auth/guest/upgrade</code>
(authenticated) claims it with a username and password. See the
<a href="/docs/authentication#guest-anonymous">Authentication guide</a> for the device-secret
contract, config, and error codes.</p>
<pre><code class="language-bash">curl -X POST /api/v1/auth/guest \
  -H 'Content-Type: application/json' \
  -d '{&quot;device_id&quot;: &quot;b64-device-id&quot;, &quot;device_secret&quot;: &quot;b64-32-random-bytes&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;player_id&quot;: &quot;...&quot;, &quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;,
 &quot;username&quot;: &quot;guest_9c41e0b7a2d5f318&quot;, &quot;created&quot;: true, &quot;guest&quot;: true}
</code></pre>
<h2 id="players" tabindex="-1">Players</h2>
<pre><code>GET /api/v1/players/:id        Get player profile
PUT /api/v1/players/:id        Update own profile
</code></pre>
<h2 id="worlds" tabindex="-1">Worlds</h2>
<pre><code>GET  /api/v1/worlds         Browse live worlds
GET  /api/v1/worlds/:id     Get one world
POST /api/v1/worlds         Create a world
</code></pre>
<p><code>GET /api/v1/worlds</code> accepts <code>mode</code> (ignored above 64 bytes) and
<code>has_capacity=true</code>. Only worlds whose mode sets <code>listed</code> (the default) are
returned. Results are cached for 500ms.</p>
<p><code>POST /api/v1/worlds</code> returns <strong>201</strong> with the world info, <strong>429</strong> when the
player is at their per-player cap (<code>player_world_limit_reached</code>), and <strong>503</strong>
when the global cap is reached (<code>world_capacity_reached</code>). See
<a href="/docs/configuration#world-capacity">World capacity</a>.</p>
<p><code>GET /api/v1/worlds/:id</code> returns <strong>404</strong> for an unknown id.</p>
<p>None of these return the player roster - see <a href="/docs/world-server">World Server</a>.
There is no REST join: joining binds the world to your WebSocket session, so
it is <code>world.join</code> over WS.</p>
<h2 id="matches" tabindex="-1">Matches</h2>
<pre><code>GET /api/v1/matches         Match history (finished matches)
GET /api/v1/matches/live    Live, joinable matches
GET /api/v1/matches/:id     Get one match record
</code></pre>
<p><strong>These read different data sources, and it is the most confusing thing in
this API.</strong> <code>GET /api/v1/matches</code> queries the match <em>record</em> table: finished
matches, an audit trail, nothing you can join. It accepts <code>mode</code>, <code>status</code>
and <code>limit</code> (1-200, default 50), newest first.</p>
<p><code>GET /api/v1/matches/live</code> enumerates running match processes and is what a
lobby browser wants. It accepts <code>mode</code> and <code>has_capacity=true</code>. Matches are
<strong>unlisted by default</strong> - a mode opts in with <code>listed =&gt; true</code> - so an empty
result usually means no mode has opted in yet.</p>
<p>Neither returns the player roster. As with worlds, joining is <code>match.join</code>
over WS.</p>
<h2 id="social" tabindex="-1">Social</h2>
<pre><code>GET    /api/v1/friends                               List friends
POST   /api/v1/friends                               Send friend request
PUT    /api/v1/friends/:friend_id                    Accept/reject/block
DELETE /api/v1/friends/:friend_id                    Remove friend

POST   /api/v1/groups                                Create group
GET    /api/v1/groups/:id                            Get group
PUT    /api/v1/groups/:id                            Update group
POST   /api/v1/groups/:id/join                       Join group
POST   /api/v1/groups/:id/leave                      Leave group
GET    /api/v1/groups/:id/members                    List group members
PUT    /api/v1/groups/:id/members/:player_id/role    Update member role
DELETE /api/v1/groups/:id/members/:player_id         Kick member
</code></pre>
<h2 id="economy" tabindex="-1">Economy</h2>
<pre><code>GET  /api/v1/wallets                   List player wallets
GET  /api/v1/wallets/:currency/history Transaction history
GET  /api/v1/store                     List store catalog
POST /api/v1/store/purchase            Purchase item
GET  /api/v1/inventory                 List player items
POST /api/v1/inventory/consume         Consume item

POST /api/v1/iap/apple                 Validate an Apple receipt
POST /api/v1/iap/google                Validate a Google Play receipt
</code></pre>
<h2 id="leaderboards" tabindex="-1">Leaderboards</h2>
<pre><code>GET  /api/v1/leaderboards/:id                  Top N entries
GET  /api/v1/leaderboards/:id/around/:player_id Around player
POST /api/v1/leaderboards/:id                  Submit score
</code></pre>
<h2 id="matchmaking" tabindex="-1">Matchmaking</h2>
<pre><code>POST   /api/v1/matchmaker              Submit matchmaking ticket
GET    /api/v1/matchmaker/:ticket_id   Check ticket status
DELETE /api/v1/matchmaker/:ticket_id   Cancel ticket
</code></pre>
<h2 id="tournaments" tabindex="-1">Tournaments</h2>
<pre><code>GET  /api/v1/tournaments               List active tournaments
GET  /api/v1/tournaments/:id           Get tournament details
POST /api/v1/tournaments/:id/join      Join tournament
</code></pre>
<h2 id="votes" tabindex="-1">Votes</h2>
<pre><code>GET /api/v1/matches/:match_id/votes    List votes for a match (newest first, max 50)
GET /api/v1/votes/:id                  Get a single vote with full results
</code></pre>
<p>Voting itself happens over WebSocket. See the <a href="/docs/voting">Voting guide</a>.</p>
<h2 id="chat" tabindex="-1">Chat</h2>
<pre><code>GET /api/v1/chat/:channel_id/history   Message history (paginated)
</code></pre>
<p>Real-time chat messages are sent and received over WebSocket.</p>
<h2 id="notifications" tabindex="-1">Notifications</h2>
<pre><code>GET    /api/v1/notifications           List notifications (paginated)
PUT    /api/v1/notifications/:id/read  Mark as read
DELETE /api/v1/notifications/:id       Delete notification
</code></pre>
<h2 id="direct-messages" tabindex="-1">Direct messages</h2>
<pre><code>POST /api/v1/dm                        Send a direct message
GET  /api/v1/dm/:player_id/history     DM history with a player
</code></pre>
<h2 id="storage" tabindex="-1">Storage</h2>
<pre><code>GET    /api/v1/saves                   List save slots
GET    /api/v1/saves/:slot             Get save data
PUT    /api/v1/saves/:slot             Write save (with version for OCC)

GET    /api/v1/storage/:collection             List objects
GET    /api/v1/storage/:collection/:key        Read object
PUT    /api/v1/storage/:collection/:key        Write object
DELETE /api/v1/storage/:collection/:key        Delete object
</code></pre>
<p>These routes return the <a href="#errors">error object</a> below on failure.</p>
<h2 id="ops" tabindex="-1">Ops</h2>
<pre><code>GET /api/v1/ops/players     Paginated player list
GET /api/v1/ops/matches     Paginated match-record list
GET /api/v1/ops/features    Installed feature set
</code></pre>
<p>The game-operations read plane, for a console rather than a game client. The
lists differ from the ones above in three ways: they report a total, they
accept a sort, and they page by offset.</p>
<p>Every list returns the same envelope:</p>
<pre><code class="language-json">{
  &quot;data&quot;: [ ... ],
  &quot;page&quot;: { &quot;limit&quot;: 50, &quot;offset&quot;: 0, &quot;total&quot;: 137 }
}
</code></pre>
<p>Parameters shared by <code>ops/players</code> and <code>ops/matches</code>:</p>
<table>
<thead>
<tr>
<th>Parameter</th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>limit</code></td>
<td>Rows per page. Default 50, clamped to 1-200.</td>
</tr>
<tr>
<td><code>page</code></td>
<td>1-based page number. Wins over <code>offset</code> when both are given.</td>
</tr>
<tr>
<td><code>offset</code></td>
<td>Rows to skip. Clamped to 0-100000 and snapped down to a multiple of <code>limit</code>, so the <code>offset</code> in the response is the one the query ran with.</td>
</tr>
<tr>
<td><code>sort</code></td>
<td>Field to sort by. Must be one of the fields listed below - anything else is <strong>400</strong>, never a silent fallback.</td>
</tr>
<tr>
<td><code>order</code></td>
<td><code>asc</code> (default) or <code>desc</code>. Anything else is <strong>400</strong>.</td>
</tr>
<tr>
<td><code>q</code></td>
<td>Case-insensitive substring search. <code>%</code> and <code>_</code> are matched literally.</td>
</tr>
</tbody>
</table>
<p>A malformed number is never an error: <code>?limit=abc</code> uses the default. A
malformed <em>sort</em> always is, because ordering the wrong rows silently is worse
than a 400.</p>
<p>Sorts always end on <code>id</code>, so paging by offset cannot repeat or skip a row when
the sort key has duplicates.</p>
<p><code>ops/players</code> sorts on <code>id</code>, <code>username</code>, <code>display_name</code>, <code>inserted_at</code>,
<code>updated_at</code>, and searches username and display name. <code>ops/matches</code> sorts on
<code>id</code>, <code>mode</code>, <code>status</code>, <code>started_at</code>, <code>finished_at</code>, <code>inserted_at</code>, filters on
<code>mode</code> and <code>status</code>, and searches mode. Both return the same fields as their
public counterparts - no roster, no credentials.</p>
<p><code>GET /api/v1/ops/features</code> reports what this deployment has installed:</p>
<pre><code class="language-json">{
  &quot;data&quot;: {
    &quot;core&quot;: {
      &quot;name&quot;: &quot;asobi&quot;,
      &quot;version&quot;: &quot;0.46.0&quot;,
      &quot;capabilities&quot;: [{ &quot;name&quot;: &quot;guest_auth&quot;, &quot;enabled&quot;: true }]
    },
    &quot;extensions&quot;: []
  }
}
</code></pre>
<p>Capabilities report what is <em>configured</em>, not what is compiled in, and carry a
boolean only - never the configured value. <code>extensions</code> is empty until an
extension registry exists; entries will have the same shape as <code>core</code>.</p>
<div class="docs-callout docs-callout-warning"><p class="docs-callout-title">Ops routes use player auth today</p><p>These routes sit behind the same bearer check as the rest of <code>/api/v1</code>, so
any authenticated player can read them, and their fields are held to exactly
what the public endpoints already expose. An operator capability model is
the follow-up.</p>
</div>
<h2 id="errors" tabindex="-1">Errors</h2>
<p>A failing request returns its HTTP status and one object:</p>
<pre><code class="language-json">{&quot;error&quot;: {&quot;code&quot;: &quot;storage.not_found&quot;, &quot;message&quot;: &quot;No object exists at this collection and key.&quot;, &quot;details&quot;: {}}}
</code></pre>
<ul>
<li><code>code</code> is the contract. It is stable, machine-readable, and namespaced by
domain (<code>storage.</code>, <code>save.</code>, <code>match.</code>, <code>world.</code>, <code>chat.</code>, <code>matchmaker.</code>) or
bare when it is cross-cutting (<code>rate_limited</code>, <code>internal</code>). Branch on this.</li>
<li><code>message</code> is prose for a human reading a log. It may be reworded at any
time. Do not parse it.</li>
<li><code>details</code> is <strong>always</strong> an object, <code>{}</code> when there is nothing to add, so no
client needs a null branch. A version conflict, for example, carries what
the client needs to retry:</li>
</ul>
<pre><code class="language-json">{&quot;error&quot;: {&quot;code&quot;: &quot;save.version_conflict&quot;, &quot;message&quot;: &quot;The slot was written by another client.&quot;, &quot;details&quot;: {&quot;current_version&quot;: 4}}}
</code></pre>
<p>Codes are a closed set. A string supplied by a client or by a Lua game script
never becomes a code; it arrives inside <code>details</code> instead.</p>
<div class="docs-callout docs-callout-info"><p class="docs-callout-title">Rollout</p><p>The storage and cloud-save routes above return this shape today. Every other
route still returns its older, flat body (<code>{&quot;error&quot;: &quot;some_string&quot;}</code>) or an
empty body with only a status. Those are converted in a follow-up; until
then, branch on the HTTP status outside <code>/saves</code> and <code>/storage</code>.</p>
</div>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/websocket">WebSocket protocol</a> - the push side of the API.</li>
<li><a href="/docs/authentication">Authentication</a> - obtaining and refreshing the bearer token.</li>
<li><a href="/docs/economy">Economy &amp; IAP</a> - wallets, the store, and receipt validation.</li>
</ul>
"""}
    ]}.
