%% GENERATED from asobi guides/websocket-protocol.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_websocket_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-ws", title => ~"WebSocket protocol — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Protocols / WebSocket"
        ]},
        {h1, [], [~"WebSocket Protocol"]},
        {raw,
            ~"""
<p>Asobi uses a single WebSocket connection per client at <code>/ws</code>. All messages
are JSON with a common envelope format.</p>
<h2 id="message-format" tabindex="-1">Message Format</h2>
<h3 id="client-to-server" tabindex="-1">Client to Server</h3>
<pre><code class="language-json">{
  &quot;cid&quot;: &quot;optional-correlation-id&quot;,
  &quot;type&quot;: &quot;message.type&quot;,
  &quot;payload&quot;: {}
}
</code></pre>
<h3 id="server-to-client" tabindex="-1">Server to Client</h3>
<pre><code class="language-json">{
  &quot;cid&quot;: &quot;correlation-id-if-request&quot;,
  &quot;type&quot;: &quot;message.type&quot;,
  &quot;payload&quot;: {}
}
</code></pre>
<p>The <code>cid</code> field is optional. When provided, the server echoes it back in
the response so the client can correlate request/response pairs.</p>
<h2 id="connection" tabindex="-1">Connection</h2>
<h3 id="sessionconnect" tabindex="-1"><code>session.connect</code></h3>
<p>Authenticate the WebSocket connection. Must be the first message sent.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;session.connect&quot;, &quot;payload&quot;: {&quot;token&quot;: &quot;session_token_here&quot;}}
</code></pre>
<p>Response:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;session.connected&quot;, &quot;payload&quot;: {&quot;player_id&quot;: &quot;...&quot;}}
</code></pre>
<h3 id="sessionheartbeat" tabindex="-1"><code>session.heartbeat</code></h3>
<p>Keep-alive ping. Send periodically to prevent timeout.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;session.heartbeat&quot;, &quot;payload&quot;: {}}
</code></pre>
<h2 id="matches" tabindex="-1">Matches</h2>
<h3 id="matchlist" tabindex="-1"><code>match.list</code></h3>
<p>Browse live, joinable matches. Filters are optional.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.list&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;arena&quot;, &quot;has_capacity&quot;: true}}
</code></pre>
<p>Reply payload is <code>{&quot;matches&quot;: [...]}</code>, each entry carrying <code>match_id</code>,
<code>mode</code>, <code>status</code>, <code>player_count</code> and <code>max_players</code>. The roster is not
included; see <a href="/docs/world-server">World Server</a> for why discovery and
membership are separate surfaces.</p>
<p><strong>Matches are unlisted by default.</strong> A matchmaker-spawned match is already
assigned to its players, so it has no reason to appear in a browser. A mode
opts in with <code>listed =&gt; true</code>. This is the inverse of worlds, which default
to listed.</p>
<p>Distinct from <code>GET /api/v1/matches</code>, which reads the match <em>record</em> table
(finished matches, an audit trail). <code>GET /api/v1/matches/live</code> is the REST
equivalent of this message.</p>
<h3 id="matchjoin" tabindex="-1"><code>match.join</code></h3>
<p>Join a match (after being matched via matchmaker, discovered via
<code>match.list</code>, or a direct invite).</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.join&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;}}
</code></pre>
<p>Joining is WebSocket-only by design: the join binds the match to your
session so subsequent <code>match.input</code> is routed. There is no REST join, the
same as for worlds.</p>
<h4 id="join-context" tabindex="-1">Join context</h4>
<p>Both <code>match.join</code> and <code>world.join</code> accept an optional <code>ctx</code>, passed through
to your game module untouched:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.join&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;, &quot;ctx&quot;: {&quot;code&quot;: &quot;AB12&quot;}}}
</code></pre>
<p>Asobi never interprets, echoes, or logs it. It reaches your game's
<code>join/3</code> callback, which decides whether to accept. Games that implement
only <code>join/2</code> are unaffected and a supplied <code>ctx</code> is ignored.</p>
<p>This is how you build join codes, invites, passwords and party checks:
without it there is no channel from a client to your game before
membership exists, so <code>join/2</code> can implement an allowlist but never a code.</p>
<p>Bounded at the server: a flat object, at most 8 keys, keys up to 64 bytes,
string values up to 256 bytes, plus integers and booleans. No nesting.
Violations are rejected with <code>invalid_join_ctx</code>, <code>join_ctx_too_many_keys</code>,
<code>join_ctx_key_too_long</code>, <code>join_ctx_value_too_long</code>, or
<code>invalid_join_ctx_value</code>.</p>
<p><strong>A join context does not make a world private.</strong> Only a game that
implements <code>join/3</code> and rejects unauthorised joins restricts entry; a game
that ignores it stays open to anyone holding a <code>world_id</code>.</p>
<h3 id="matchinput" tabindex="-1"><code>match.input</code></h3>
<p>Send game input to the match server.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.input&quot;, &quot;payload&quot;: {&quot;action&quot;: &quot;move&quot;, &quot;x&quot;: 10, &quot;y&quot;: 5}}
</code></pre>
<h3 id="matchstate-server-push" tabindex="-1"><code>match.state</code> (server push)</h3>
<p>Server broadcasts game state updates to all players in the match.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.state&quot;, &quot;payload&quot;: {&quot;players&quot;: {...}, &quot;tick&quot;: 42}}
</code></pre>
<h3 id="matchstarted-server-push" tabindex="-1"><code>match.started</code> (server push)</h3>
<p>Notification that a match has begun.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.started&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;, &quot;players&quot;: [...]}}
</code></pre>
<h3 id="matchfinished-server-push" tabindex="-1"><code>match.finished</code> (server push)</h3>
<p>Notification that a match has ended with results.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.finished&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;, &quot;result&quot;: {...}}}
</code></pre>
<h3 id="matchleave" tabindex="-1"><code>match.leave</code></h3>
<p>Leave the current match.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.leave&quot;, &quot;payload&quot;: {}}
</code></pre>
<h2 id="matchmaking" tabindex="-1">Matchmaking</h2>
<h3 id="matchmakeradd" tabindex="-1"><code>matchmaker.add</code></h3>
<p>Submit a matchmaking ticket.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;matchmaker.add&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;arena&quot;, &quot;properties&quot;: {&quot;skill&quot;: 1200}}}
</code></pre>
<h3 id="matchmakerremove" tabindex="-1"><code>matchmaker.remove</code></h3>
<p>Cancel a matchmaking ticket.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;matchmaker.remove&quot;, &quot;payload&quot;: {&quot;ticket_id&quot;: &quot;...&quot;}}
</code></pre>
<h3 id="matchmatched-server-push" tabindex="-1"><code>match.matched</code> (server push)</h3>
<p>Notification that the matchmaker paired you into a match.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.matched&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;, &quot;players&quot;: [...]}}
</code></pre>
<blockquote>
<p>Note: distinct from <code>match.joined</code>, which is the server's reply to a
client-initiated <code>match.join</code> message. Both signal &quot;you're in a match
and <code>match.state</code> will follow,&quot; but only <code>match.matched</code> is fired
spontaneously by the matchmaker.</p>
</blockquote>
<h2 id="worlds" tabindex="-1">Worlds</h2>
<p>The world server runs persistent shared spaces with zoned interest
management. See <a href="/docs/world-server">World server</a> for the model and
<a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a> for tuning.</p>
<h3 id="worldlist" tabindex="-1"><code>world.list</code></h3>
<p>List running worlds. Optional filters: <code>mode</code> (string), <code>has_capacity</code>
(bool — only worlds that aren't full).</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.list&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;walkers&quot;, &quot;has_capacity&quot;: true}}
</code></pre>
<p>Response:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.list&quot;, &quot;payload&quot;: {&quot;worlds&quot;: [{&quot;world_id&quot;: &quot;...&quot;, &quot;mode&quot;: &quot;walkers&quot;, &quot;player_count&quot;: 1, &quot;max_players&quot;: 8}]}}
</code></pre>
<h3 id="worldcreate" tabindex="-1"><code>world.create</code></h3>
<p>Create a new world for the given mode. Refuses with
<code>world_capacity_reached</code> (global cap hit) or <code>player_world_limit_reached</code>
(per-player cap hit). On success the caller is auto-joined.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.create&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;walkers&quot;}}
</code></pre>
<h3 id="worldfind_or_create" tabindex="-1"><code>world.find_or_create</code></h3>
<p>Atomic find-or-create: returns the first non-full world for the mode,
or creates one if none exists. The caller is auto-joined. <strong>This is the
right call for &quot;drop me into a shared room&quot; flows.</strong></p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.find_or_create&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;walkers&quot;}}
</code></pre>
<h3 id="worldjoin" tabindex="-1"><code>world.join</code></h3>
<p>Join a specific world by id (e.g. one returned from <code>world.list</code>).</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.join&quot;, &quot;payload&quot;: {&quot;world_id&quot;: &quot;...&quot;}}
</code></pre>
<h3 id="worldinput" tabindex="-1"><code>world.input</code></h3>
<p>Send game input to your zone. The <code>payload</code> IS the input map — there is
no inner <code>data</code> wrapper. Field names are entirely up to your game; the
server only forwards the map verbatim to your <code>handle_input/3</code> callback.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.input&quot;, &quot;payload&quot;: {&quot;kind&quot;: &quot;move&quot;, &quot;x&quot;: 600, &quot;y&quot;: 480}}
</code></pre>
<p>The server routes the message to whichever zone owns your player
entity — clients don't specify zone coordinates.</p>
<h3 id="worldleave" tabindex="-1"><code>world.leave</code></h3>
<p>Leave the current world.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.leave&quot;, &quot;payload&quot;: {}}
</code></pre>
<h3 id="worldjoined-server-push" tabindex="-1"><code>world.joined</code> (server push)</h3>
<p>Sent in response to a successful <code>world.create</code>, <code>world.find_or_create</code>,
or <code>world.join</code>. The <code>payload</code> is the full world info (mode, world_id,
player_count, grid_size, max_players, …).</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.joined&quot;, &quot;payload&quot;: {&quot;world_id&quot;: &quot;...&quot;, &quot;mode&quot;: &quot;walkers&quot;, &quot;grid_size&quot;: 1, &quot;max_players&quot;: 8, &quot;player_count&quot;: 1, &quot;status&quot;: &quot;running&quot;}}
</code></pre>
<h3 id="worldtick-server-push" tabindex="-1"><code>world.tick</code> (server push)</h3>
<p>Per-zone delta broadcast. The first <code>world.tick</code> after <code>world.joined</code> is
the <strong>initial snapshot</strong> for every entity in the zone — register your
handler before sending the join message or you miss it.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.tick&quot;, &quot;payload&quot;: {&quot;tick&quot;: 42, &quot;updates&quot;: [{&quot;op&quot;: &quot;a&quot;, &quot;id&quot;: &quot;01HX...&quot;, &quot;x&quot;: 600, &quot;y&quot;: 480, &quot;type&quot;: &quot;player&quot;}]}}
</code></pre>
<p><code>updates</code> is a list of entity deltas. <code>op</code> values:</p>
<table>
<thead>
<tr>
<th><code>op</code></th>
<th>Meaning</th>
<th>Fields</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>&quot;a&quot;</code></td>
<td>Added — full state</td>
<td>id + every field on the entity</td>
</tr>
<tr>
<td><code>&quot;u&quot;</code></td>
<td>Updated — diff</td>
<td>id + only changed fields</td>
</tr>
<tr>
<td><code>&quot;r&quot;</code></td>
<td>Removed</td>
<td>id only</td>
</tr>
</tbody>
</table>
<h3 id="worldterrain-server-push" tabindex="-1"><code>world.terrain</code> (server push)</h3>
<p>Sent on zone subscription when the world has a terrain provider. The
chunk data is base64-encoded compressed binary; see
<a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a> for the encoding.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.terrain&quot;, &quot;payload&quot;: {&quot;coords&quot;: [3, 5], &quot;data&quot;: &quot;eJw...&quot;}}
</code></pre>
<h3 id="worldleft-server-push" tabindex="-1"><code>world.left</code> (server push)</h3>
<p>Confirmation that the leave completed (or that the client was already
out of any world).</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.left&quot;, &quot;payload&quot;: {&quot;success&quot;: true}}
</code></pre>
<h3 id="worldfinished-server-push" tabindex="-1"><code>world.finished</code> (server push)</h3>
<p>The world ended (e.g. last player left and the empty grace expired, or
the game module returned <code>{finished, Result, State}</code> from <code>post_tick</code>).</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.finished&quot;, &quot;payload&quot;: {&quot;world_id&quot;: &quot;...&quot;, &quot;result&quot;: {}}}
</code></pre>
<h3 id="worldphase_changed-server-push" tabindex="-1"><code>world.phase_changed</code> (server push)</h3>
<p>Phase transition for worlds that declare phases. Payload mirrors the
match <code>match.phase_changed</code> event.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.phase_changed&quot;, &quot;payload&quot;: {&quot;phase&quot;: &quot;combat&quot;, &quot;duration_ms&quot;: 60000}}
</code></pre>
<h2 id="chat" tabindex="-1">Chat</h2>
<p>Channel ids are namespaced: every id must start with one of these prefixes, and
a frame whose channel id is missing or unprefixed is rejected with
<code>channel_id_invalid</code>. The prefix lets the runtime route the message and enforce
membership without a per-frame registry lookup.</p>
<table>
<thead>
<tr>
<th>Prefix</th>
<th>Used for</th>
<th>Membership rule</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>dm:</code></td>
<td>Direct messages</td>
<td>Both participants only.</td>
</tr>
<tr>
<td><code>world:</code></td>
<td>World-wide chat</td>
<td>Players currently joined to the world.</td>
</tr>
<tr>
<td><code>zone:</code></td>
<td>A specific zone within a world</td>
<td>Players currently inside that zone.</td>
</tr>
<tr>
<td><code>prox:</code></td>
<td>Proximity chat (radius around a position)</td>
<td>Players within the configured radius.</td>
</tr>
<tr>
<td><code>room:</code></td>
<td>Group / lobby / custom rooms</td>
<td>Group members, or open join per room policy.</td>
</tr>
</tbody>
</table>
<p>A single connection may join at most <strong>32 channels</strong> at once; a 33rd is rejected
with <code>too_many_channels</code>. Idle channels with no members stop after 60s; rejoining
is cheap. Message <code>content</code> is capped at 2000 bytes and empty or non-binary
content is rejected with <code>content_empty</code> / <code>content_too_large</code>.</p>
<p>History (<code>GET /api/v1/chat/:channel_id/history</code>) requires membership and clamps
<code>?limit</code> to 200; non-members get <code>403</code>.</p>
<h3 id="chatjoin" tabindex="-1"><code>chat.join</code></h3>
<p>Join a chat channel. The channel id must be namespaced.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;chat.join&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;room:lobby&quot;}}
</code></pre>
<h3 id="chatsend" tabindex="-1"><code>chat.send</code></h3>
<p>Send a message to a channel.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;chat.send&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;room:lobby&quot;, &quot;content&quot;: &quot;Hello!&quot;}}
</code></pre>
<h3 id="chatmessage-server-push" tabindex="-1"><code>chat.message</code> (server push)</h3>
<p>A new message in a joined channel.</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;chat.message&quot;,
  &quot;payload&quot;: {
    &quot;channel_id&quot;: &quot;room:lobby&quot;,
    &quot;sender_id&quot;: &quot;...&quot;,
    &quot;content&quot;: &quot;Hello!&quot;,
    &quot;sent_at&quot;: &quot;2025-01-15T10:30:00Z&quot;
  }
}
</code></pre>
<h3 id="chatleave" tabindex="-1"><code>chat.leave</code></h3>
<p>Leave a chat channel.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;chat.leave&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;room:lobby&quot;}}
</code></pre>
<h2 id="voting" tabindex="-1">Voting</h2>
<h3 id="votecast" tabindex="-1"><code>vote.cast</code></h3>
<p>Cast a vote in an active match vote.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.cast&quot;, &quot;cid&quot;: &quot;v1&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;, &quot;option_id&quot;: &quot;jungle&quot;}}
</code></pre>
<p>For approval voting, <code>option_id</code> is a list:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.cast&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;, &quot;option_id&quot;: [&quot;jungle&quot;, &quot;caves&quot;]}}
</code></pre>
<h3 id="voteveto" tabindex="-1"><code>vote.veto</code></h3>
<p>Use a veto token to cancel the current vote. Requires <code>veto_tokens_per_player &gt; 0</code>
in match config and <code>veto_enabled</code> on the vote.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.veto&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;}}
</code></pre>
<h3 id="matchvote_start-server-push" tabindex="-1"><code>match.vote_start</code> (server push)</h3>
<p>A new vote has started.</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;match.vote_start&quot;,
  &quot;payload&quot;: {
    &quot;vote_id&quot;: &quot;...&quot;,
    &quot;options&quot;: [{&quot;id&quot;: &quot;jungle&quot;, &quot;label&quot;: &quot;Jungle Path&quot;}, {&quot;id&quot;: &quot;volcano&quot;, &quot;label&quot;: &quot;Volcano Path&quot;}],
    &quot;window_ms&quot;: 15000,
    &quot;method&quot;: &quot;plurality&quot;
  }
}
</code></pre>
<h3 id="matchvote_tally-server-push" tabindex="-1"><code>match.vote_tally</code> (server push)</h3>
<p>Running tally update (only with <code>&quot;live&quot;</code> visibility).</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;match.vote_tally&quot;,
  &quot;payload&quot;: {
    &quot;vote_id&quot;: &quot;...&quot;,
    &quot;tallies&quot;: {&quot;jungle&quot;: 2, &quot;volcano&quot;: 1},
    &quot;time_remaining_ms&quot;: 8432,
    &quot;total_votes&quot;: 3
  }
}
</code></pre>
<h3 id="matchvote_result-server-push" tabindex="-1"><code>match.vote_result</code> (server push)</h3>
<p>Vote closed, winner determined.</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;match.vote_result&quot;,
  &quot;payload&quot;: {
    &quot;vote_id&quot;: &quot;...&quot;,
    &quot;winner&quot;: &quot;jungle&quot;,
    &quot;counts&quot;: {&quot;jungle&quot;: 2, &quot;volcano&quot;: 1},
    &quot;distribution&quot;: {&quot;jungle&quot;: 0.666, &quot;volcano&quot;: 0.333},
    &quot;total_votes&quot;: 3,
    &quot;turnout&quot;: 1.0
  }
}
</code></pre>
<h3 id="matchvote_vetoed-server-push" tabindex="-1"><code>match.vote_vetoed</code> (server push)</h3>
<p>A player vetoed the vote.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.vote_vetoed&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;, &quot;vetoed_by&quot;: &quot;player_id&quot;}}
</code></pre>
<h2 id="presence" tabindex="-1">Presence</h2>
<h3 id="presenceupdate" tabindex="-1"><code>presence.update</code></h3>
<p>Update your online status.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;presence.update&quot;, &quot;payload&quot;: {&quot;status&quot;: &quot;in_game&quot;, &quot;metadata&quot;: {&quot;match_id&quot;: &quot;...&quot;}}}
</code></pre>
<h3 id="presencechanged-server-push" tabindex="-1"><code>presence.changed</code> (server push)</h3>
<p>A friend's presence changed.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;presence.changed&quot;, &quot;payload&quot;: {&quot;player_id&quot;: &quot;...&quot;, &quot;status&quot;: &quot;online&quot;}}
</code></pre>
<h2 id="notifications" tabindex="-1">Notifications</h2>
<h3 id="notificationnew-server-push" tabindex="-1"><code>notification.new</code> (server push)</h3>
<p>A new notification for the player.</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;notification.new&quot;,
  &quot;payload&quot;: {
    &quot;id&quot;: &quot;...&quot;,
    &quot;type&quot;: &quot;friend_request&quot;,
    &quot;subject&quot;: &quot;New friend request&quot;,
    &quot;content&quot;: {&quot;from_player_id&quot;: &quot;...&quot;}
  }
}
</code></pre>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/rest">REST API</a> - the request/response surface alongside this socket protocol.</li>
<li><a href="/docs/authentication">Authentication</a> - obtaining the token the socket authenticates with.</li>
<li><a href="/docs/voting">Voting</a> - the vote flow whose <code>match.vote_*</code> pushes appear above.</li>
</ul>
"""}
    ]}.
