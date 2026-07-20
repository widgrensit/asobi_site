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
 &quot;username&quot;: &quot;guest_019f615cbc4a&quot;, &quot;created&quot;: true, &quot;guest&quot;: true}
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
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/websocket">WebSocket protocol</a> - the push side of the API.</li>
<li><a href="/docs/authentication">Authentication</a> - obtaining and refreshing the bearer token.</li>
<li><a href="/docs/economy">Economy &amp; IAP</a> - wallets, the store, and receipt validation.</li>
</ul>
"""}
    ]}.
