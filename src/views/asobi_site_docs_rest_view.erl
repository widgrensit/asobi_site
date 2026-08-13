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
<p><strong>Windows / PowerShell.</strong> The examples below use <code>curl</code> (Linux, macOS, Git
Bash, WSL). In PowerShell, translate any block by hand once - the shape is the
same:</p>
<pre><code class="language-powershell">Invoke-RestMethod -Uri http://localhost:8084/api/v1/auth/register `
  -Method Post -ContentType application/json `
  -Body '{&quot;username&quot;: &quot;player1&quot;, &quot;password&quot;: &quot;secret123&quot;}'
</code></pre>
<p>Add auth with <code>-Headers @{ Authorization = &quot;Bearer $token&quot; }</code>.
<code>Invoke-RestMethod</code> parses the JSON response for you, so no <code>jq</code> is needed.</p>
<h2 id="auth" tabindex="-1">Auth</h2>
<pre><code>POST   /api/v1/auth/register        Register a new player
POST   /api/v1/auth/login           Sign in, returns an access + refresh pair
POST   /api/v1/auth/refresh         Exchange a refresh token for a new pair
POST   /api/v1/auth/logout          Revoke the current tokens
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
<h3 id="logout" tabindex="-1">Logout</h3>
<p>Unauthenticated, because it accepts a token that may already have expired.
Send the refresh token in the body to kill the whole refresh family; the
access token in the <code>Authorization</code> header is revoked too, so it cannot
outlive its cache TTL.</p>
<pre><code class="language-bash">curl -X POST /api/v1/auth/logout \
  -H 'Content-Type: application/json' \
  -H &quot;Authorization: Bearer $ACCESS_TOKEN&quot; \
  -d '{&quot;refresh_token&quot;: &quot;...&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;success&quot;: true}
</code></pre>
<p>Always <strong>200</strong>, including with no body and no header at all: logout is
idempotent and reports nothing about which token was valid.</p>
<h3 id="guest" tabindex="-1">Guest</h3>
<p>Anonymous device-based auth, opt-in via config. <code>POST /auth/guest</code> creates a
player on first call and resumes the same one on later calls; <code>/auth/guest/upgrade</code>
(authenticated) claims it with a username and password. To delete a guest, use
<a href="#erasing-your-own-account">the account-erasure route</a> - guest removal is not a
guest-specific endpoint. See the
<a href="/docs/authentication#guest-anonymous">Authentication guide</a> for the device-secret
contract, config, and error codes.</p>
<pre><code class="language-bash">curl -X POST /api/v1/auth/guest \
  -H 'Content-Type: application/json' \
  -d '{&quot;device_id&quot;: &quot;b64-device-id&quot;, &quot;device_secret&quot;: &quot;b64-32-random-bytes&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;player_id&quot;: &quot;...&quot;, &quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;,
 &quot;username&quot;: &quot;guest_9c41e0b7a2d5f318&quot;, &quot;created&quot;: true, &quot;guest&quot;: true}
</code></pre>
<p><code>created</code> is present only on the call that created the player. A resume
returns the same body without it, so treat a missing <code>created</code> as <code>false</code>
rather than expecting the key.</p>
<p>To delete a guest account, call
<a href="#erasing-your-own-account"><code>POST /players/me/erase</code></a> on its session. No
<code>password</code> is needed, because a guest has none.</p>
<h2 id="players" tabindex="-1">Players</h2>
<pre><code>GET /api/v1/players/:id        Get player profile
PUT /api/v1/players/:id        Update own profile
</code></pre>
<h3 id="erasing-your-own-account" tabindex="-1">Erasing your own account</h3>
<pre><code>POST /api/v1/players/me/erase
</code></pre>
<p>Erases the calling player and everything core holds about them. The subject is
always the caller - the id comes from the session and there is no id in the
path or body - so this route can never reach another account. An operator
erasing somebody else is a different route with a different credential:
<a href="#erasing-and-exporting-a-player"><code>/ops/players/:id/erase</code></a>.</p>
<p>An account with a password must echo it. One without - a guest, or a
provider-only account - has no credential the client can re-present, so its
session is the whole confirmation.</p>
<pre><code class="language-bash"># password account
curl -X POST /api/v1/players/me/erase \
  -H 'Authorization: Bearer &lt;access_token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;password&quot;: &quot;secret123&quot;}'

# guest or provider-only account
curl -X POST /api/v1/players/me/erase \
  -H 'Authorization: Bearer &lt;access_token&gt;' \
  -H 'Content-Type: application/json' -d '{}'
</code></pre>
<pre><code class="language-json">{&quot;deleted&quot;: true}
</code></pre>
<p>POST rather than DELETE because the confirmation travels in the body, and a
DELETE body has no defined semantics - the same shape the operator route uses.</p>
<p>Irreversible, and it takes the children with it: wallets, ledger, inventory,
storage, cloud saves, notifications, leaderboard entries, chat, group
memberships, friendships, stats, sessions and identities. Purchase receipts are
severed rather than deleted, for the reason described under
<a href="#erasing-and-exporting-a-player">the operator route</a>. Every erasure writes an
audit row whose actor is the player themselves.</p>
<p>A refused confirmation is <code>403</code>, not <code>401</code>, on purpose: the caller is
authenticated and failed a step-up check, so an SDK that treats <code>401</code> as
&quot;refresh the token pair and replay the request&quot; must not do either of those
things here.</p>
<p><strong>The session dies with the account.</strong> A retried call after a successful one
answers <code>401</code>, not <code>200</code> or <code>404</code>, because the token it presents was deleted
inside the same transaction. A client whose request timed out should read a
subsequent <code>401</code> as &quot;it worked&quot;, not as &quot;sign in again&quot;.</p>
<table>
<thead>
<tr>
<th>Status</th>
<th><code>error.code</code></th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>400</code></td>
<td><code>missing_field</code></td>
<td>The account has a password and the body carried none</td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>unauthenticated</code></td>
<td>No session, or the account is already gone</td>
</tr>
<tr>
<td><code>403</code></td>
<td><code>player.confirmation_failed</code></td>
<td>The password does not match. Nothing was deleted, and the session is still valid</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>player.credentials_changed</code></td>
<td>The password changed while the request was in flight. Nothing was deleted; retry</td>
</tr>
<tr>
<td><code>429</code></td>
<td><code>rate_limited</code></td>
<td>Erasure has its own tight bucket, because the wrong-password path runs the password KDF</td>
</tr>
<tr>
<td><code>500</code></td>
<td><code>player.erase_failed</code></td>
<td>The transaction rolled back. Nothing was deleted</td>
</tr>
</tbody>
</table>
<h2 id="worlds" tabindex="-1">Worlds</h2>
<pre><code>GET  /api/v1/worlds         Browse live worlds
GET  /api/v1/worlds/:id     Get one world
POST /api/v1/worlds         Create a world
</code></pre>
<p><code>GET /api/v1/worlds</code> accepts <code>mode</code> (ignored above 64 bytes) and
<code>has_capacity=true</code>. Only worlds whose mode sets <code>listed</code> (the default for a
world; set <code>listed = false</code> in the script to hide one) are returned. Results
are cached for 500ms.</p>
<p><code>POST /api/v1/worlds</code> returns <strong>201</strong> with the world info, <strong>429</strong>
<code>world.player_limit_reached</code> when the player is at their per-player cap, and
<strong>503</strong> <code>world.capacity_reached</code> when the global cap is reached. See
<a href="/docs/configuration#world-capacity">World capacity</a>. The equivalent
<code>world.create</code> failures over WebSocket carry no code of their own - see the
<a href="/docs/protocols/websocket">WebSocket protocol</a>.</p>
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
lobby browser wants. It accepts <code>mode</code>, <code>has_capacity=true</code> and
<code>joinable=true|false</code>. Matches are <strong>unlisted by default</strong> - a mode opts in
with <code>listed = true</code> (a Lua global, or <code>listed =&gt; true</code> in the operator's
<code>game_modes</code> config) - so an empty result usually means no mode has opted in
yet.</p>
<p>Every entry carries <code>joinable</code>, and a browser looking for somewhere to play
should filter on both it and <code>has_capacity</code>: a match with room may have closed
itself to new players, and a full one has not closed. <code>running</code> matches are
included, because a running match takes joins - that is how backfill works.</p>
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
GET  /api/v1/store                     List store catalogue
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
<p><code>GET /api/v1/leaderboards/:id</code> accepts <code>?limit</code>, default 100, clamped to
1-100. <code>GET .../around/:player_id</code> accepts <code>?range</code>, default 5, clamped to
1-50, and returns that many entries either side. A non-numeric value falls
back to the default rather than erroring.</p>
<p><code>POST /api/v1/leaderboards/:id</code> is <strong>off by default</strong> and answers <strong>403</strong>
<code>leaderboard.client_submit_disabled</code>. Scores are normally submitted from game
code, where the client cannot forge them. An operator opts a board in by
listing its id under the <code>leaderboard_client_submit</code> application env, or by
setting that to <code>all</code> - reasonable for a casual scoreboard where cheating
does not matter, wrong for anything competitive.</p>
<p>A board that is full answers <strong>503</strong> <code>leaderboard.capacity_reached</code>.</p>
<h2 id="matchmaking" tabindex="-1">Matchmaking</h2>
<pre><code>POST   /api/v1/matchmaker              Submit matchmaking ticket
GET    /api/v1/matchmaker/:ticket_id   Check ticket status
DELETE /api/v1/matchmaker/:ticket_id   Cancel ticket
</code></pre>
<p>A ticket is only valid on the node that issued it. The queue lives in one
process per node and there is no ticket table, so a status check or a cancel
that lands on a second node answers <strong>404</strong> <code>matchmaker.ticket_not_found</code> for
a ticket that is very much alive elsewhere. A cluster needs a sticky route
pinning all three calls for one player to one node. Another player's ticket is
<strong>403</strong> <code>forbidden</code>. See <a href="/docs/clustering">Clustering</a>.</p>
<p>Ticket outcomes are pushed over WebSocket, not polled here.</p>
<h2 id="tournaments" tabindex="-1">Tournaments</h2>
<pre><code>GET  /api/v1/tournaments               List active tournaments
GET  /api/v1/tournaments/:id           Get tournament details
POST /api/v1/tournaments/:id/join      Join tournament
</code></pre>
<h2 id="votes" tabindex="-1">Votes</h2>
<pre><code>GET /api/v1/matches/:id/votes    List votes for a match (newest first, max 50)
GET /api/v1/votes/:id            Get a single vote with full results
</code></pre>
<p>The match list is <strong>participant-only</strong>: a caller who is not on the match's
roster gets <strong>403</strong> <code>forbidden</code>, whether the match is live or finished. A
vote whose visibility is <code>hidden</code> and whose status is not yet <code>resolved</code> has
its <code>votes_cast</code> field withheld, so a participant cannot read who voted for
what while the vote is still open.</p>
<p>Voting itself happens over WebSocket. See the <a href="/docs/voting">Voting guide</a>.</p>
<h2 id="chat" tabindex="-1">Chat</h2>
<pre><code>GET /api/v1/chat/:channel_id/history   Message history
</code></pre>
<p>Requires membership of the channel: a non-member gets <strong>403</strong> <code>forbidden</code>, and
so does a malformed channel id. <code>?limit</code> defaults to 50 and is clamped to
1-200, oldest-first within the window.</p>
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
<p>The whole subsystem is on by default and switches off with <code>{storage, false}</code>;
off, all seven routes answer 404 - see
<a href="/docs/configuration#storage">Configuration</a>.</p>
<h2 id="ops" tabindex="-1">Ops</h2>
<pre><code>GET /api/v1/ops/stats                        Runtime health of this node
GET /api/v1/ops/players                      Paginated player list
GET /api/v1/ops/players/:id                  One player
GET /api/v1/ops/matches                      Paginated match-record list
GET /api/v1/ops/matches/:id                  One match record
GET /api/v1/ops/features                     Installed feature set
GET /api/v1/ops/leaderboards                 Paginated board list
GET /api/v1/ops/leaderboards/:id/entries     Paginated, ranked board entries
GET /api/v1/ops/matchmaker                   Matchmaking queue, by mode
GET /api/v1/ops/economy/items                Paginated item catalogue
GET /api/v1/ops/economy/items/:id            One item definition
GET /api/v1/ops/economy/listings             Paginated store listings
GET /api/v1/ops/economy/listings/:id         One store listing
GET /api/v1/ops/chat/channels                Live chat channels, by members
GET /api/v1/ops/chat/channels/:id/messages   Paginated channel history
GET /api/v1/ops/tournaments                  Paginated tournament list
GET /api/v1/ops/tournaments/:id              One tournament
GET /api/v1/ops/notifications                Paginated sent notifications

GET  /api/v1/ops/players/:id/export          Everything held about one player
POST /api/v1/ops/players/:id/erase           Delete one player. Irreversible.

GET|POST|PUT|DELETE
    /api/v1/ops/ext/:extension/:action       Dispatch to an installed extension
</code></pre>
<p>The game-operations plane, for a console rather than a game client. The lists
differ from the ones above in three ways: they report a total, they accept a
sort, and they page by offset.</p>
<p>Everything here is a read except two account-lifecycle routes - see
<a href="#erasing-and-exporting-a-player">Erasing and exporting a player</a> - and
<code>/api/v1/ops/ext/:extension/:action</code>, whose behaviour comes from an installed
extension.</p>
<p>These routes do <strong>not</strong> accept player tokens. They are their own auth plane -
see <a href="#ops-authentication">Ops authentication</a> below. For turning the console
on, the environment variables and the operator narrative, see
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<h3 id="what-is-node-local-and-what-is-not" tabindex="-1">What is node-local and what is not</h3>
<p>Four of these read live process state on the node that answers, so behind a
load balancer two consecutive reads can disagree and neither is wrong:</p>
<table>
<thead>
<tr>
<th>Route</th>
<th>What it reads</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>ops/stats</code></td>
<td>This node's VM. <code>online_players</code> is the exception: presence is a cluster-wide process group, so that one gauge is fleet-wide.</td>
</tr>
<tr>
<td><code>ops/features</code></td>
<td>This node's resolved extension set and configured capabilities.</td>
</tr>
<tr>
<td><code>ops/matchmaker</code></td>
<td>This node's queue. The whole matchmaker is per node.</td>
</tr>
<tr>
<td><code>ops/chat/channels</code></td>
<td>The chat channels running on this node.</td>
</tr>
</tbody>
</table>
<p>Every other ops route reads Postgres and is therefore consistent whichever
node answers. See <a href="/docs/clustering">Clustering</a>.</p>
<p>Every list returns the same envelope:</p>
<pre><code class="language-json">{
  &quot;data&quot;: [ ... ],
  &quot;page&quot;: { &quot;limit&quot;: 50, &quot;offset&quot;: 0, &quot;total&quot;: 137 }
}
</code></pre>
<p>Parameters shared by every ops list:</p>
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
<td><code>asc</code> (default) or <code>desc</code>, matched case-insensitively, so <code>DESC</code> works. Anything else is <strong>400</strong>.</td>
</tr>
<tr>
<td><code>q</code></td>
<td>Case-insensitive substring search. <code>%</code> and <code>_</code> are matched literally. Only on the lists with something to search: not the queue, a board's entries, or listings.</td>
</tr>
</tbody>
</table>
<p><code>page</code> has its own ceiling of 10000 on top of the offset clamp, so the
deepest reachable window is whichever of <code>page * limit</code> and 100000 is
smaller.</p>
<p>A malformed number is never an error: <code>?limit=abc</code> uses the default. A
malformed <em>sort</em> always is, because ordering the wrong rows silently is worse
than a 400.</p>
<p>A filter is dropped when its value is empty or too long: you get a superset,
and the rows show it. The exception is a filter on an <strong>id</strong> column
(<code>player_id</code>, <code>sender_id</code>, <code>item_def_id</code>): a value that is not a uuid is
<code>400 ops.invalid_filter</code>, because dropping it would answer a request scoped to
one player with everybody's rows and nothing in the response would say so.</p>
<p>Sorts always end on a unique column, so paging by offset cannot repeat or skip
a row when the sort key has duplicates. That column is <code>id</code> on most lists,
<code>board_id</code> for the board list, <code>player_id</code> within a board, <code>mode</code> for the
queue and <code>channel_id</code> for the channel list.</p>
<h3 id="lookup-by-id" tabindex="-1">Lookup by id</h3>
<p>Every list with a <code>:id</code> route beside it returns one row in the same envelope
minus the page:</p>
<pre><code class="language-json">{ &quot;data&quot;: { &quot;id&quot;: &quot;0197...&quot;, &quot;username&quot;: &quot;kaito&quot; } }
</code></pre>
<p>The row is passed through the list's own projection, so a lookup can never
return a field the list withheld. An id that is not a uuid is
<code>400 ops.invalid_id</code> and never reaches the database; a real miss is
<code>404 ops.not_found</code>.</p>
<h3 id="players-1" tabindex="-1">Players</h3>
<h3 id="erasing-your-own-account-1" tabindex="-1">Erasing your own account</h3>
<pre><code>POST /api/v1/players/me/erase
</code></pre>
<p>Erases the calling player and everything core holds about them. The subject is
always the caller - the id comes from the session and there is no id in the
path or body - so this route can never reach another account. An operator
erasing somebody else is a different route with a different credential:
<a href="#erasing-and-exporting-a-player"><code>/ops/players/:id/erase</code></a>.</p>
<p>An account with a password must echo it. One without - a guest, or a
provider-only account - has no credential the client can re-present, so its
session is the whole confirmation.</p>
<pre><code class="language-bash"># password account
curl -X POST /api/v1/players/me/erase \
  -H 'Authorization: Bearer &lt;access_token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;password&quot;: &quot;secret123&quot;}'

# guest or provider-only account
curl -X POST /api/v1/players/me/erase \
  -H 'Authorization: Bearer &lt;access_token&gt;' \
  -H 'Content-Type: application/json' -d '{}'
</code></pre>
<pre><code class="language-json">{&quot;deleted&quot;: true}
</code></pre>
<p>POST rather than DELETE because the confirmation travels in the body, and a
DELETE body has no defined semantics - the same shape the operator route uses.</p>
<p>Irreversible, and it takes the children with it: wallets, ledger, inventory,
storage, cloud saves, notifications, leaderboard entries, chat, group
memberships, friendships, stats, sessions and identities. Purchase receipts are
severed rather than deleted, for the reason described under
<a href="#erasing-and-exporting-a-player">the operator route</a>. Every erasure writes an
audit row whose actor is the player themselves.</p>
<p>A refused confirmation is <code>403</code>, not <code>401</code>, on purpose: the caller is
authenticated and failed a step-up check, so an SDK that treats <code>401</code> as
&quot;refresh the token pair and replay the request&quot; must not do either of those
things here.</p>
<p><strong>The session dies with the account.</strong> A retried call after a successful one
answers <code>401</code>, not <code>200</code> or <code>404</code>, because the token it presents was deleted
inside the same transaction. A client whose request timed out should read a
subsequent <code>401</code> as &quot;it worked&quot;, not as &quot;sign in again&quot;.</p>
<table>
<thead>
<tr>
<th>Status</th>
<th><code>error.code</code></th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>400</code></td>
<td><code>missing_field</code></td>
<td>The account has a password and the body carried none</td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>unauthenticated</code></td>
<td>No session, or the account is already gone</td>
</tr>
<tr>
<td><code>403</code></td>
<td><code>player.confirmation_failed</code></td>
<td>The password does not match. Nothing was deleted, and the session is still valid</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>player.credentials_changed</code></td>
<td>The password changed while the request was in flight. Nothing was deleted; retry</td>
</tr>
<tr>
<td><code>429</code></td>
<td><code>rate_limited</code></td>
<td>Erasure has its own tight bucket, because the wrong-password path runs the password KDF</td>
</tr>
<tr>
<td><code>500</code></td>
<td><code>player.erase_failed</code></td>
<td>The transaction rolled back. Nothing was deleted</td>
</tr>
</tbody>
</table>
<p><code>ops/players</code> sorts on <code>id</code>, <code>username</code>, <code>display_name</code>, <code>inserted_at</code>,
<code>updated_at</code>, and searches username and display name. <code>ops/matches</code> sorts on
<code>id</code>, <code>mode</code>, <code>status</code>, <code>started_at</code>, <code>finished_at</code>, <code>inserted_at</code>, filters on
<code>mode</code> and <code>status</code>, and searches mode. Both return the same fields as their
public counterparts - no roster, no credentials.</p>
<h3 id="economy-1" tabindex="-1">Economy</h3>
<p><code>GET /api/v1/ops/economy/items</code> is the item catalogue. Sorts on <code>id</code>, <code>slug</code>,
<code>name</code>, <code>category</code>, <code>rarity</code>, <code>inserted_at</code>, <code>updated_at</code>, filters on
<code>category</code> and <code>rarity</code>, and searches slug and name.</p>
<p><code>GET /api/v1/ops/economy/listings</code> is the store. Sorts on <code>id</code>, <code>item_def_id</code>,
<code>currency</code>, <code>price</code>, <code>active</code>, <code>valid_from</code>, <code>valid_until</code>, and filters on
<code>item_def_id</code>, <code>currency</code> and <code>active</code> (<code>true</code> or <code>false</code> - nothing else
filters).</p>
<pre><code class="language-json">{
  &quot;data&quot;: [
    { &quot;id&quot;: &quot;0198...&quot;, &quot;item_def_id&quot;: &quot;0197...&quot;, &quot;currency&quot;: &quot;gold&quot;,
      &quot;price&quot;: 250, &quot;active&quot;: true, &quot;valid_from&quot;: null, &quot;valid_until&quot;: null,
      &quot;metadata&quot;: {} }
  ],
  &quot;page&quot;: { &quot;limit&quot;: 50, &quot;offset&quot;: 0, &quot;total&quot;: 38 }
}
</code></pre>
<p>Listings carry no timestamp, so they default to <code>id</code> descending. Ids are
UUIDv7, so that is still newest-first. There is no <code>q</code> on listings: nothing on
a listing is prose. Search the catalogue and filter by the <code>item_def_id</code> it
gives you.</p>
<h3 id="chat-1" tabindex="-1">Chat</h3>
<p><code>GET /api/v1/ops/chat/channels</code> lists the channels running on this node with
their current member count. Sorts on <code>channel_id</code> and <code>members</code>, busiest
first, and searches the channel id. It is process state, so it is this node's
view and it changes between reads.</p>
<pre><code class="language-json">{
  &quot;data&quot;: [{ &quot;channel_id&quot;: &quot;room:lobby&quot;, &quot;members&quot;: 14 }],
  &quot;page&quot;: { &quot;limit&quot;: 50, &quot;offset&quot;: 0, &quot;total&quot;: 1 }
}
</code></pre>
<p><code>GET /api/v1/ops/chat/channels/:id/messages</code> pages one channel's persisted
history. Sorts on <code>id</code>, <code>channel_type</code>, <code>sender_id</code>, <code>sent_at</code>, newest first,
filters on <code>sender_id</code> and <code>channel_type</code>, and searches message content - the
read a moderator acting on a report needs. <code>metadata</code> does not leave.</p>
<p>A channel with history but no live process is still readable here; a live
channel that has not been written to yet has no rows.</p>
<h3 id="tournaments-1" tabindex="-1">Tournaments</h3>
<p><code>GET /api/v1/ops/tournaments</code> sorts on <code>id</code>, <code>name</code>, <code>leaderboard_id</code>,
<code>status</code>, <code>start_at</code>, <code>end_at</code>, <code>inserted_at</code>, filters on <code>status</code> and
<code>leaderboard_id</code>, and searches the name.</p>
<p>Every row carries <code>live</code>: whether a tournament process is actually running for
it. A row can say <code>&quot;status&quot;: &quot;active&quot;</code> with <code>&quot;live&quot;: false</code> after a node
restart, and no other read shows that. <code>metadata</code> does not leave; <code>entry_fee</code>
and <code>rewards</code> do.</p>
<h3 id="notifications-1" tabindex="-1">Notifications</h3>
<p><code>GET /api/v1/ops/notifications</code> is the send history. Sorts on <code>id</code>,
<code>player_id</code>, <code>type</code>, <code>subject</code>, <code>read</code>, <code>sent_at</code>, newest first, filters on
<code>player_id</code>, <code>type</code> and <code>read</code>, and searches the subject. It answers the
question a broadcast raises: who received it, and how many have opened it.</p>
<p>There is no broadcast route here. The broadcast is an in-process entry point
that writes an audit row - see <a href="#ops-audit">Ops audit</a>.</p>
<h3 id="leaderboards-1" tabindex="-1">Leaderboards</h3>
<p><code>GET /api/v1/ops/leaderboards</code> lists boards rather than scores. Sorts on
<code>board_id</code>, <code>entries</code>, <code>top_score</code>, <code>updated_at</code>, defaults to the largest
board first, and searches <code>board_id</code>.</p>
<pre><code class="language-json">{
  &quot;data&quot;: [
    { &quot;board_id&quot;: &quot;arena_eu&quot;, &quot;entries&quot;: 4120, &quot;top_score&quot;: 98210,
      &quot;updated_at&quot;: &quot;2026-08-03T12:00:00Z&quot;, &quot;live&quot;: true }
  ],
  &quot;page&quot;: { &quot;limit&quot;: 50, &quot;offset&quot;: 0, &quot;total&quot;: 1 }
}
</code></pre>
<p><code>live</code> says whether the board currently has a process. A board is live without
rows for its first 30 seconds - scores are flushed on an interval - and has
rows without being live when nothing has written to it since the node started.
Both cases are listed.</p>
<p><code>GET /api/v1/ops/leaderboards/:id/entries</code> pages one board. Sorts on <code>id</code>,
<code>player_id</code>, <code>score</code>, <code>sub_score</code>, <code>updated_at</code>, and defaults to <code>score</code>
descending, which is the board's own order.</p>
<pre><code class="language-json">{
  &quot;data&quot;: [
    { &quot;id&quot;: &quot;0198...&quot;, &quot;leaderboard_id&quot;: &quot;arena_eu&quot;, &quot;player_id&quot;: &quot;0197...&quot;,
      &quot;score&quot;: 98210, &quot;sub_score&quot;: 0, &quot;rank&quot;: 1,
      &quot;updated_at&quot;: &quot;2026-08-03T12:00:00Z&quot; }
  ],
  &quot;page&quot;: { &quot;limit&quot;: 50, &quot;offset&quot;: 0, &quot;total&quot;: 4120 }
}
</code></pre>
<p><code>rank</code> is the position on the whole board, not within the page: row 501 is
rank 501. It stays the board's rank whatever you sort the page by, and it is
computed over the same order the public <code>GET /api/v1/leaderboards/:id</code> uses,
so the two agree on any flushed score.</p>
<p>The read is of persisted scores. A score submitted seconds ago is on the
public top-N endpoint before it is here.</p>
<h3 id="matchmaker" tabindex="-1">Matchmaker</h3>
<p><code>GET /api/v1/ops/matchmaker</code> reports the queue, one row per mode. Sorts on
<code>mode</code>, <code>waiting</code>, <code>oldest_wait_ms</code>, <code>average_wait_ms</code>, deepest queue first.</p>
<pre><code class="language-json">{
  &quot;data&quot;: [
    { &quot;mode&quot;: &quot;ranked&quot;, &quot;waiting&quot;: 14, &quot;oldest_wait_ms&quot;: 21400, &quot;average_wait_ms&quot;: 8300 }
  ],
  &quot;page&quot;: { &quot;limit&quot;: 50, &quot;offset&quot;: 0, &quot;total&quot;: 1 },
  &quot;queue&quot;: { &quot;waiting&quot;: 14, &quot;modes&quot;: 1, &quot;sampled_at&quot;: 1785312000000, &quot;age_ms&quot;: 420 }
}
</code></pre>
<p>Counts come from a sample the matchmaker publishes on each tick, so they are
up to one tick old - 1s by default - and <code>age_ms</code> says how old. Waits are
measured from the reading, so they keep growing between ticks. The read never
touches the matchmaker process itself; it cannot slow matchmaking down however
often it is polled.</p>
<p>No ticket, player id or ticket property appears here. Who is queued is player
data and waits on the capability model.</p>
<h3 id="features" tabindex="-1">Features</h3>
<p><code>GET /api/v1/ops/features</code> reports what this deployment has installed:</p>
<pre><code class="language-json">{
  &quot;data&quot;: {
    &quot;core&quot;: {
      &quot;name&quot;: &quot;asobi&quot;,
      &quot;version&quot;: &quot;0.68.2&quot;,
      &quot;capabilities&quot;: [{ &quot;name&quot;: &quot;guest_auth&quot;, &quot;enabled&quot;: true }]
    },
    &quot;extensions&quot;: []
  }
}
</code></pre>
<p>Capabilities report what is <em>configured</em>, not what is compiled in, and carry a
boolean only - never the configured value. <code>lua</code> is the one exception: it is a
module check, and it is true in every stock release because the Lua runtime
ships in asobi.</p>
<p><code>extensions</code> is the resolved extension set, in dependency order and in the
same shape as <code>core</code>, so a client reads one row type:</p>
<pre><code class="language-json">{ &quot;name&quot;: &quot;quests&quot;, &quot;version&quot;: &quot;1.0.0&quot;,
  &quot;capabilities&quot;: [{ &quot;name&quot;: &quot;console&quot;, &quot;enabled&quot;: true },
                   { &quot;name&quot;: &quot;lua&quot;, &quot;enabled&quot;: true },
                   { &quot;name&quot;: &quot;ops&quot;, &quot;enabled&quot;: true },
                   { &quot;name&quot;: &quot;rpc&quot;, &quot;enabled&quot;: true },
                   { &quot;name&quot;: &quot;tables&quot;, &quot;enabled&quot;: true }] }
</code></pre>
<p>An extension's capabilities are the seams it declares something under, plus
<code>console</code> for one that ships operator screens - which is a file check rather
than a manifest key. They say what it contributes, never what it contains - no
method name, no action name, no table name. <code>[]</code> when nothing is installed.</p>
<p>This is what a console reads to decide which of its screens to render, and to
surface a version it was not built against.</p>
<h3 id="stats" tabindex="-1">Stats</h3>
<p><code>GET /api/v1/ops/stats</code> is the runtime health of <strong>one node</strong>. Everything in
it comes from the VM or from presence, so it stays answerable when Postgres
is the thing that is unwell.</p>
<pre><code class="language-json">{
  &quot;data&quot;: {
    &quot;node&quot;: &quot;asobi@10.0.1.7&quot;,
    &quot;online_players&quot;: 412,
    &quot;process_count&quot;: 8134,
    &quot;process_limit&quot;: 262144,
    &quot;memory_total&quot;: 184549376,
    &quot;memory_processes&quot;: 71303168,
    &quot;memory_ets&quot;: 12582912,
    &quot;memory_binary&quot;: 33554432,
    &quot;run_queue&quot;: 0,
    &quot;scheduler_count&quot;: 8,
    &quot;uptime_ms&quot;: 864000000
  }
}
</code></pre>
<p><code>node</code> is in the response because every node serves its own copy of this
endpoint and the numbers are per node. Behind a load balancer a reading
without a node name is a reading you cannot act on: poll every node and key
the results on this field.</p>
<p><code>online_players</code> is the one fleet-wide figure here, and it is <code>null</code> rather
than an error if presence is momentarily unavailable. Memory gauges are
bytes; <code>uptime_ms</code> is wall-clock milliseconds since this node booted.</p>
<p>There is no push variant. The console polls.</p>
<h3 id="extension-actions" tabindex="-1">Extension actions</h3>
<p><code>/api/v1/ops/ext/:extension/:action</code> is the one ops route core owns on behalf
of extensions, and the one route on the plane that can mutate. Everything
about it comes from the installed extension's manifest: which actions exist,
which HTTP method each answers, which capability class it needs, and what it
does.</p>
<p>An action nobody declared has no class, and an untagged route is denied, so
an unknown extension, an unknown action and a method the action does not
answer are all <strong>403</strong>, never 404. Enumerating which extensions are installed
is not something an unauthorised caller gets to do. <code>GET /api/v1/ops/features</code>
is where an authorised caller reads the installed set.</p>
<p>A <code>get</code> action receives the parsed query string; any other method receives the
decoded JSON body. Both arrive as a map with string keys. On success the
handler's own object is the response body verbatim, with no <code>data</code> envelope
around it, so this route does not share the shape the lists above use. A
failure is the shared error object, carrying a code the extension declared -
an undeclared code is refused and answered <code>internal</code>.</p>
<p>Every method other than <code>get</code> is wrapped in the audit path, so an extension
cannot write on this plane without core recording who asked. Declaring a
method other than <code>get</code> is what opts an action in; there is nothing to
configure.</p>
<p>A successful call is stored as outcome <code>ok</code> with a succeeded count of one. A
failure is stored as outcome <code>error</code> whether or not it carried details, and
the row's <code>details</code> holds the returned code; the details map itself is the
caller's diagnostic and is not stored. A handler that raises, or answers
something outside the reply contract, is answered <code>internal</code> and still
audited as an <code>error</code> outcome.</p>
<p>While the node is still running migrations the route answers <strong>503</strong>
<code>not_ready</code>, before the extension's handler runs.</p>
<h3 id="ops-authentication" tabindex="-1">Ops authentication</h3>
<p>Ops routes sit behind an operator credential, never a player token. Send the
configured operator secret as a bearer token:</p>
<pre><code>GET /api/v1/ops/players
Authorization: Bearer &lt;ops_secret&gt;
</code></pre>
<p>There is <strong>no default</strong> secret. A deployment that has not set one rejects
every ops request, so the plane is closed until an operator opens it. A player
or guest token is rejected the same way: the ops plane never consults the
player token store at all.</p>
<p>The <code>console</code> setting gates the <code>/console</code> routes, not this one. An ops secret
alone makes <code>/api/v1/ops/*</code> answerable without the console being on. For
setting both, see <a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<p>Every rejection is <strong>403</strong> with the same body every other failure on this API
returns:</p>
<pre><code class="language-json">{&quot;error&quot;: {&quot;code&quot;: &quot;forbidden&quot;, &quot;message&quot;: &quot;The caller may not perform this action.&quot;, &quot;details&quot;: {}}}
</code></pre>
<p>That is the body whatever the cause. An unconfigured deployment, a wrong
secret and a credential that lacks the route's capability class are
indistinguishable to the caller, deliberately.</p>
<p>A bearer token wins when both it and a console cookie are present.</p>
<p>Each route carries exactly one capability class - <code>read</code>, <code>player_data</code>,
<code>config</code> or <code>erasure</code> - and a request is admitted only if the credential holds
that class. Every core route is <code>read</code> except the two account-lifecycle ones;
an extension action's class comes from its manifest. Role names never appear
on the wire.</p>
<p><code>erasure</code> is separate from <code>player_data</code> for one reason, and it is not
sensitivity: it is the only class whose actions cannot be undone by a later
call. The operator secret sent as a bearer token holds all four. A console
session holds every class <strong>but</strong> <code>erasure</code> unless <code>console_erasure</code> is set to
<code>true</code> - same secret, different transport, different blast radius.</p>
<h3 id="erasing-and-exporting-a-player" tabindex="-1">Erasing and exporting a player</h3>
<pre><code>GET  /api/v1/ops/players/:id/export
POST /api/v1/ops/players/:id/erase
</code></pre>
<p><code>export</code> returns everything core holds about one player, keyed by table, each
row through a positive allowlist. Credentials are never in it: no
<code>hashed_password</code>, and a session is reported as having existed without its
bearer token. Class <code>player_data</code>, not <code>read</code> - a leaderboard view is one
thing, and the whole of one identified person's record is another.</p>
<p>The payload also names every installed extension under an <code>extensions</code> key:
the data its <code>export_player/1</code> returned, or a <code>skipped</code> marker when the
extension does not export one - a skipped extension is visible in the
artefact, never silently absent. An extension that fails to export fails the
whole request with <code>500 ops.export_incomplete</code>, and no partial artefact is
returned. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</p>
<p><code>erase</code> deletes the player and every row core holds for them, in one
transaction, and it cannot be undone. The body must echo the player's username
and the server checks it against the row:</p>
<pre><code class="language-bash">curl -X POST \
  -H &quot;Authorization: Bearer $ASOBI_OPS_SECRET&quot; \
  -H 'Content-Type: application/json' \
  -d '{&quot;username&quot;: &quot;kaito&quot;}' \
  https://game.example.com/api/v1/ops/players/019f.../erase
</code></pre>
<pre><code class="language-json">{&quot;data&quot;: {&quot;player_id&quot;: &quot;019f...&quot;, &quot;erased&quot;: true}}
</code></pre>
<p>A missing echo is <code>ops.confirmation_required</code> and a wrong one is
<code>ops.confirmation_mismatch</code>, both 400. Neither reaches the deletion.</p>
<p>Two tables survive with the player reference set to <code>NULL</code> rather than being
deleted: <code>iap_transactions</code>, because a refund or chargeback dispute needs the
real-money receipt, and <code>groups.creator_id</code>, because deleting the group would
destroy every other member's data. Everything else goes, including the wallet,
its ledger, saves, storage, chat messages, friendships and identities.</p>
<p>Three columns hold player ids with no foreign key, and they keep them:
<code>match_records.players</code>, <code>votes.votes_cast</code> and <code>zone_snapshots.entities</code>. The
ids no longer resolve to anybody - the schema stores bare uuids and nothing
else about the person, so deleting <code>players</code> and <code>player_identities</code> <em>is</em> the
anonymisation. <code>zone_snapshots.entities</code> is opaque game-defined state, so a
game that puts personal data in it owns erasing that itself; see
<a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</p>
<p>The erasure writes its own audit row inside the same transaction, so &quot;erased&quot;
and &quot;recorded as erased&quot; are one commit (ADR 0007). Installed extensions erase
first, in that transaction; one refusing aborts the whole deletion and the
player survives intact.</p>
<p>You do not need the ops plane for this. A self-hoster with a release and a
remote shell can call the same function, and it is the same code path:</p>
<pre><code class="language-erlang">1&gt; asobi_player_erase:run(~&quot;019f...&quot;).
{ok,#{player_id =&gt; &lt;&lt;&quot;019f...&quot;&gt;&gt;,erased =&gt; true}}
2&gt; asobi_player_export:run(~&quot;019f...&quot;).
{ok,#{player =&gt; #{...}, wallets =&gt; [...], ...}}
</code></pre>
<p>There is no player-facing self-delete. Whether players may erase themselves is
a support-load and abuse decision belonging to the game - it turns an account
takeover into an account destruction - so asobi gives the operator the
primitive and the game decides whether to expose it.</p>
<h3 id="console-session" tabindex="-1">Console session</h3>
<p>A browser has a second transport for the same credential. These three routes
are outside <code>/api/v1</code> and are not themselves behind the ops credential - the
login endpoint cannot require the credential it exists to accept.</p>
<pre><code>GET    /console/session   Who this browser is, if anyone
POST   /console/session   Exchange a credential for a session
DELETE /console/session   End the session
</code></pre>
<p><code>POST</code> takes <code>{&quot;secret&quot;: &quot;...&quot;}</code> and an optional <code>&quot;label&quot;</code>, the display name
the audit trail carries for this session. It defaults to <code>operator</code>, it is
self-asserted, and it is held to the same shape as the <code>x-asobi-operator</code>
header.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/console/session \
  -H 'Content-Type: application/json' \
  -d '{&quot;secret&quot;: &quot;'&quot;$ASOBI_OPS_SECRET&quot;'&quot;, &quot;label&quot;: &quot;kaito&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;data&quot;: {&quot;display&quot;: &quot;kaito&quot;, &quot;expires_at&quot;: 1785355200, &quot;csrf&quot;: &quot;...&quot;}}
</code></pre>
<p>Two cookies come back. <code>asobi_console</code> holds the session id and is <code>HttpOnly</code>,
so page script cannot read it. <code>asobi_console_csrf</code> holds the CSRF token and
is deliberately <strong>not</strong> <code>HttpOnly</code>, because the page has to send it back as an
<code>x-csrf-token</code> header and holding it only in memory would end the session on
every reload. Every later ops request carries the cookie plus that header
instead of the bearer token; a cookie without a matching header is refused, so
a cross-site request that arrives with the browser's cookies attached gets
403. <code>DELETE</code> is the exception and needs the cookie only, since it can only
ever destroy authority.</p>
<p>Both cookies are <code>SameSite=Lax</code>, path <code>/</code>, and <code>Secure</code> whenever the request
looks like TLS directly or through a proxy that says so. The <code>x-csrf-token</code>
header, not the cookie attribute, is what stops a cross-site write.</p>
<p><code>GET</code> returns the actor behind the session and requires both the cookie and
the header, like any other ops read.</p>
<pre><code class="language-json">{&quot;data&quot;: {&quot;display&quot;: &quot;kaito&quot;, &quot;source&quot;: &quot;local_user&quot;, &quot;caps&quot;: [&quot;read&quot;, &quot;player_data&quot;, &quot;config&quot;], &quot;attested&quot;: false}}
</code></pre>
<p>A session resolves only on the node that minted it: the store is an ETS table
owned by one process on that node, and the secret the CSRF token is derived
from is generated at boot. Restarting the node ends every session in flight,
and a round-robin load balancer 403s most console requests. Pin the console to
one node. Sessions expire absolutely, after 12 hours by default, and reading
one does not extend it.</p>
<p>Every route in this group answers <strong>404</strong> when the console is switched off,
which is the same 404 an unknown path gets. For the model, the environment
variables and the credentials, see <a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<p><strong>One secret means one privilege level.</strong> The static secret resolves to all
three classes, so anyone holding it holds <code>config</code>. A studio cannot hand a
community manager <code>player_data</code> without handing over everything else. Restrict
who reaches the console at all with a reverse proxy. Per-person capabilities
need the second credential shape the plane accepts: a minted token carrying an
explicit capability list and a short expiry, issued by a control plane rather
than configured on the node.</p>
<p>Optionally send <code>x-asobi-operator: &lt;name&gt;</code> to name the human behind a shared
secret. It is attribution only: it is read after the credential is accepted,
it never affects what a request may do, and it is recorded unattested. A
label that is empty, multi-valued, over 64 bytes, or not printable ASCII is
dropped rather than trusted.</p>
<h3 id="ops-audit" tabindex="-1">Ops audit</h3>
<p>Every ops-plane mutation is wrapped so it writes a row to <code>ops_audit_entries</code>,
carrying the acting operator (<code>actor_id</code>, <code>actor_display</code>, <code>actor_source</code>,
<code>actor_attested</code>), the action, its subject, and when it happened. Reads are
not audited.</p>
<p>Three things go through the audit path: player erasure, an extension action
reached over <code>/api/v1/ops/ext/:extension/:action</code>, and the in-process
notification broadcast entry point. The player export is a read and is not
audited.</p>
<p><code>actor_attested</code> is the important column. A name that came from
<code>x-asobi-operator</code> is self-declared, so it is stored <code>false</code>; only a verified
identity is stored <code>true</code>. Treat an unattested name as a hint, not evidence.</p>
<p><code>outcome</code> is <code>ok</code>, <code>partial</code> or <code>error</code>, with <code>succeeded_count</code> and
<code>failed_count</code> beside it, so a fan-out that reached some of its subjects is
never recorded as a success. Per-subject reasons sit in <code>details</code> and are
diagnostic only; the counts are what you query.</p>
<p>Rows are append-only and core never prunes them, so retention is yours to set.
No index leads on <code>occurred_at</code>: it is the second column of the
<code>(actor_id, occurred_at)</code> and <code>(action, occurred_at)</code> composites, and the only
other index is on <code>target_id</code>. A delete scoped to time alone therefore scans
the table. Prune in batches, off-peak, or add an index on <code>occurred_at</code> if you
intend to prune by time on a schedule.</p>
<p>Nothing cascades into the table, so erasing a player does not erase the record
of what was done to them - <code>actor_id</code> and <code>target_id</code> are plain strings with no
foreign key. That is what lets an erasure's own row outlive its subject.</p>
<p>Erasure is the one exception to &quot;the audit never fails the operation&quot;. Its row
is written <strong>inside</strong> the erasure transaction, so a failed audit insert rolls
the deletion back: the data is gone by definition, so the row is the only
surviving evidence the request was honoured. Every other mutation audits after
the fact and cannot be failed by it (ADR 0007).</p>
<p>A guest-retention sweep writes no rows. It is the machine's own housekeeping
over up to 500 accounts a pass, and it logs a count instead.</p>
<p>An audit write never fails the operation it describes. It runs after the
change has already happened, so refusing the response could only invite a
retry that applies the change twice. If the insert fails, the row is emitted
instead at error level with the same field names, so ship your logs.</p>
<h2 id="errors" tabindex="-1">Errors</h2>
<p>A failing request returns its HTTP status and one object:</p>
<pre><code class="language-json">{&quot;error&quot;: {&quot;code&quot;: &quot;storage.not_found&quot;, &quot;message&quot;: &quot;No object exists at this collection and key.&quot;, &quot;details&quot;: {}}}
</code></pre>
<ul>
<li><code>code</code> is the contract. It is stable, machine-readable, and namespaced by
domain (<code>storage.</code>, <code>save.</code>, <code>auth.</code>, <code>guest.</code>, <code>player.</code>, <code>match.</code>,
<code>world.</code>, <code>matchmaker.</code>, <code>leaderboard.</code>, <code>economy.</code>, <code>inventory.</code>, <code>iap.</code>,
<code>social.</code>, <code>chat.</code>, <code>dm.</code>, <code>tournament.</code>, <code>notification.</code>, <code>vote.</code>, <code>ops.</code>,
<code>rpc.</code>, <code>console.</code>, <code>ws.</code>) or bare when it is cross-cutting
(<code>internal</code>, <code>rate_limited</code>, <code>join_rate_limited</code>, <code>payload_too_large</code>,
<code>invalid_json</code>, <code>invalid_message</code>, <code>invalid_payload</code>, <code>missing_field</code>,
<code>unknown_type</code>, <code>unauthenticated</code>, <code>forbidden</code>, <code>validation_failed</code>,
<code>length_required</code>, <code>client_gate_denied</code>, <code>not_ready</code>). Branch on this. The
whole set is one list in <code>asobi_error</code>, and an extension may add codes only
in its own domain.</li>
<li><code>message</code> is prose for a human reading a log. It may be reworded at any
time. Do not parse it.</li>
<li><code>details</code> is <strong>always</strong> an object, <code>{}</code> when there is nothing to add, so no
client needs a null branch. A version conflict, for example, carries what
the client needs to retry:</li>
</ul>
<pre><code class="language-json">{&quot;error&quot;: {&quot;code&quot;: &quot;save.version_conflict&quot;, &quot;message&quot;: &quot;The slot was written by another client.&quot;, &quot;details&quot;: {&quot;current_version&quot;: 4}}}
</code></pre>
<p>Codes are a closed set. A string supplied by a client, by an identity
provider, by a store's receipt verifier, or by a Lua game script never becomes
a code; it arrives inside <code>details</code> instead. So a rejected sign-in reads:</p>
<pre><code class="language-json">{&quot;error&quot;: {&quot;code&quot;: &quot;auth.provider_rejected&quot;, &quot;message&quot;: &quot;The identity provider rejected the token.&quot;, &quot;details&quot;: {&quot;reason&quot;: &quot;publisher_banned&quot;}}}
</code></pre>
<p>Every route returns this shape, as does every WebSocket <code>error</code> frame. No
route is left on the older, flat body (<code>{&quot;error&quot;: &quot;some_string&quot;}</code>), and none
answers a failure with an empty body.</p>
<p>A route that already sent more than <code>error</code> still sends it, unchanged and in
the same place: <code>fields</code> and <code>errors</code> on a 422, <code>retry_after</code> on a 429,
<code>field</code> or <code>order</code> on an ops sort rejection, <code>reason</code> on a
<code>client_gate_denied</code> 403. Each is repeated inside <code>details</code>, so new code reads
one place. Statuses are unchanged; a route that answered 403 or 404 with no
body answers the same status with the object in it.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/websocket">WebSocket protocol</a> - the push side of the API.</li>
<li><a href="/docs/authentication">Authentication</a> - obtaining and refreshing the bearer token.</li>
<li><a href="/docs/economy">Economy &amp; IAP</a> - wallets, the store, and receipt validation.</li>
</ul>
"""}
    ]}.
