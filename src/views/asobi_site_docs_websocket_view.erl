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
<blockquote>
<p><strong>You probably do not call this directly.</strong> This page is the raw wire reference.
Every official SDK (Defold, Godot, Unity, Unreal, Dart/Flame, JavaScript, LÖVE)
wraps this protocol: each message you <em>send</em> is a function, each message the
server <em>pushes</em> is a callback you register. Reach for this page only to write a
client from scratch or to debug what is on the wire. For the calls in your
language, see the realtime section of your <a href="https://asobi.dev/docs">SDK quickstart</a>.</p>
</blockquote>
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
<h2 id="custom-events" tabindex="-1">Custom events</h2>
<p>The events listed on this page are the ones asobi itself emits. They are not
the whole <code>type</code> space: a game script owns the leaf name under <code>match.</code> and
<code>world.</code>, so a client must never switch exhaustively on the list below.</p>
<p><code>game.broadcast</code> from a match script:</p>
<pre><code class="language-lua">game.broadcast(&quot;round_start&quot;, { phase = &quot;combat&quot; })
</code></pre>
<p>reaches every player in that match as:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.round_start&quot;, &quot;payload&quot;: {&quot;phase&quot;: &quot;combat&quot;}}
</code></pre>
<p>The same call from a world script produces <code>world.round_start</code> and reaches
every player in the world. There is no <code>cid</code> - these are pushes, never
replies.</p>
<p>The runtime validates the leaf name before it goes on the wire:</p>
<ul>
<li>1 to 64 bytes.</li>
<li><code>A-Z</code>, <code>a-z</code>, <code>0-9</code>, <code>_</code> and <code>-</code> only. <code>.</code> is excluded, so a script cannot
mint a deeper <code>world.foo.bar</code> sub-namespace.</li>
<li>Not one of asobi's own leaf names, otherwise a script could forge a frame
byte-identical to an authoritative event such as <code>world.tick</code> or
<code>match.finished</code>. The reserved set is
<code>asobi_ws_handler:reserved_event_names/0</code>:</li>
</ul>
<p>&lt;!-- BEGIN reserved-event-names (verified against asobi_ws_handler:reserved_event_names/0 by asobi_protocol_coverage_tests) --&gt;</p>
<pre><code>ack                 finished            joined              left
list                matched             matchmaker_expired  matchmaker_failed
phase_changed       state               terrain             tick
vote_result         vote_start          vote_tally          vote_vetoed
</code></pre>
<p>&lt;!-- END reserved-event-names --&gt;</p>
<p>The payload is also capped at 64 KiB encoded, the same bound as an inbound
frame, because it fans out to every player. A payload that cannot be encoded
as JSON at all is rejected on the same path.</p>
<p>A broadcast that fails any of these is dropped and logged server-side. The
client is told nothing, so do not wait for an error frame that will not come.</p>
<p>Client SDKs handle this open namespace with a generic fallback: any
<code>match.*</code>/<code>world.*</code> type with no dedicated callback has its prefix stripped
and is handed to a catch-all match/world event handler. Every official SDK
has one; a client written from scratch needs one too.</p>
<h2 id="connection" tabindex="-1">Connection</h2>
<h3 id="sessionconnect" tabindex="-1"><code>session.connect</code></h3>
<p>Authenticate the WebSocket connection. Must be the first message sent. The
token is the <code>access_token</code> from any auth route.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;session.connect&quot;, &quot;payload&quot;: {&quot;token&quot;: &quot;&lt;access_token&gt;&quot;}}
</code></pre>
<p>Response:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;session.connected&quot;, &quot;payload&quot;: {&quot;player_id&quot;: &quot;...&quot;}}
</code></pre>
<p>A bad or expired token answers <code>error</code> with reason <code>invalid_token</code> and code
<code>unauthenticated</code>, and the socket stays open so the client can retry with a
refreshed token.</p>
<h3 id="sessionheartbeat" tabindex="-1"><code>session.heartbeat</code></h3>
<p>Keep-alive ping. Send periodically to prevent timeout.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;session.heartbeat&quot;, &quot;payload&quot;: {}}
</code></pre>
<p>Reply, carrying the server's clock in Unix milliseconds:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;session.heartbeat&quot;, &quot;cid&quot;: &quot;h-1&quot;, &quot;payload&quot;: {&quot;ts&quot;: 1785312000000}}
</code></pre>
<p>The reply is the same type as the request. A client that switches on <code>type</code>
alone must tolerate that; a <code>cid</code> distinguishes the reply from a push.</p>
<h3 id="limits" tabindex="-1">Limits</h3>
<p>Every bound below is enforced by the socket itself, and a client that
reconnects or backs off needs all of them.</p>
<table>
<thead>
<tr>
<th>Bound</th>
<th>What happens</th>
</tr>
</thead>
<tbody>
<tr>
<td>60 messages per second per connection</td>
<td>Further frames in that second are answered with <code>error</code>, reason <code>rate_limited</code>. The connection stays open.</td>
</tr>
<tr>
<td>64 KiB per inbound frame</td>
<td>Answered with <code>error</code>, reason <code>payload_too_large</code>. Measured on the raw frame, before JSON parsing.</td>
</tr>
<tr>
<td>10s to send <code>session.connect</code></td>
<td>The socket is closed with code 1008 and the reason <code>idle_auth_timeout</code>. Override with <code>asobi.ws_idle_auth_timeout_ms</code>.</td>
</tr>
<tr>
<td>60 connects per second per IP</td>
<td>The upgrade is closed with 1008 <code>rate_limited</code> before anything else runs. Tune under <code>asobi.rate_limits</code>, group <code>ws_connect</code>.</td>
</tr>
<tr>
<td>Origin allowlist</td>
<td>A browser <code>Origin</code> outside <code>asobi.ws_allowed_origins</code> is closed with 1008 <code>origin_rejected</code>. With no allowlist configured every Origin passes, and a request with no <code>Origin</code> header always passes, because a native client sends none.</td>
</tr>
</tbody>
</table>
<p>The message-rate window is a fixed 1000ms bucket, not a sliding one: a burst
that straddles the boundary can put 120 frames through in two adjacent
windows. Size a client's send rate against the limit, not against the burst.</p>
<p>Joining is bounded separately, per player rather than per connection: 10
world or match joins per 60 seconds, including <code>world.create</code> and
<code>world.find_or_create</code>. The 11th is <code>error</code> with reason <code>join_rate_limited</code>
and code <code>join_rate_limited</code>.</p>
<p>The first two bounds are per connection. The connect-flood and join buckets
are per node, so across a cluster the real ceiling is the figure above times
the node count. See <a href="/docs/clustering">Clustering</a>.</p>
<h2 id="matches" tabindex="-1">Matches</h2>
<blockquote>
<p>The <code>match.input</code> (client -&gt; server) and <code>match.state</code> (server -&gt; all clients)
pair below is the core real-time loop. In an SDK these are one send function and
one receive callback - see the realtime section of your <a href="https://asobi.dev/docs">SDK quickstart</a>.</p>
</blockquote>
<h3 id="matchlist" tabindex="-1"><code>match.list</code></h3>
<p>Browse live, joinable matches. Filters are optional.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.list&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;arena&quot;, &quot;has_capacity&quot;: true, &quot;joinable&quot;: true}}
</code></pre>
<p>Reply payload is <code>{&quot;matches&quot;: [...]}</code>, each entry carrying <code>match_id</code>,
<code>mode</code>, <code>status</code>, <code>player_count</code>, <code>max_players</code> and <code>joinable</code>. The roster is
not included; see <a href="/docs/world-server">World Server</a> for why discovery and
membership are separate surfaces.</p>
<p><code>has_capacity</code> and <code>joinable</code> are separate questions and a client looking for
somewhere to play should ask both: a match with room may have closed itself to
new players, and a full one has not closed - it may free a slot on the next
leave. <code>joinable</code> accepts <code>false</code> too, for a browser that wants to show
in-progress matches it cannot enter. A filter of the wrong type is rejected
with <code>invalid_joinable_filter</code>.</p>
<p><strong>Matches are unlisted by default.</strong> A matchmaker-spawned match is already
assigned to its players, so it has no reason to appear in a browser. A mode
opts in with <code>listed = true</code> (a Lua global, or <code>listed =&gt; true</code> in the
operator's <code>game_modes</code> config). This is the inverse of worlds, which default
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
<p>A <code>running</code> match takes joins exactly as a <code>waiting</code> one does, so this is also
how a player backfills into a game already in progress. There is no separate
backfill call.</p>
<h4 id="matchjoined-reply" tabindex="-1"><code>match.joined</code> (reply)</h4>
<p>The full match info, including the roster:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.joined&quot;, &quot;cid&quot;: &quot;j-1&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;, &quot;mode&quot;: &quot;arena&quot;, &quot;status&quot;: &quot;waiting&quot;, &quot;player_count&quot;: 1, &quot;max_players&quot;: 4, &quot;players&quot;: [&quot;...&quot;], &quot;listed&quot;: false, &quot;joinable&quot;: true}}
</code></pre>
<table>
<thead>
<tr>
<th>Reason</th>
<th>Code</th>
<th>Means</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>match_not_found</code></td>
<td><code>match.not_found</code></td>
<td>No live match with that id</td>
</tr>
<tr>
<td><code>join_rate_limited</code></td>
<td><code>join_rate_limited</code></td>
<td>Over 10 joins per 60 seconds</td>
</tr>
<tr>
<td><code>match_full</code></td>
<td><code>match.full</code></td>
<td>No room. May free a slot on the next leave</td>
</tr>
<tr>
<td><code>match_locked</code></td>
<td><code>match.locked</code></td>
<td>The game closed the match to new players</td>
</tr>
<tr>
<td><code>join_refused</code></td>
<td><code>match.join_refused</code></td>
<td>The game turned this player away</td>
</tr>
</tbody>
</table>
<p><code>join_refused</code> carries the game's own reason string in
<code>error.details.refused_reason</code> when the script gave one. It is game
vocabulary, never an asobi code - see
<a href="/docs/lua/api#refusing-a-join">Refusing a join</a>.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;error&quot;, &quot;cid&quot;: &quot;j-1&quot;, &quot;payload&quot;: {&quot;reason&quot;: &quot;join_refused&quot;, &quot;error&quot;: {&quot;code&quot;: &quot;match.join_refused&quot;, &quot;message&quot;: &quot;The game refused this join. See `details.refused_reason`.&quot;, &quot;details&quot;: {&quot;refused_reason&quot;: &quot;wrong_code&quot;}}}}
</code></pre>
<h4 id="join-context" tabindex="-1">Join context</h4>
<p>Both <code>match.join</code> and <code>world.join</code> accept an optional <code>ctx</code>, passed through
to your game module untouched:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.join&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;, &quot;ctx&quot;: {&quot;code&quot;: &quot;AB12&quot;}}}
</code></pre>
<p>Asobi never interprets, echoes, or logs it. It reaches your game's join
callback, which decides whether to accept.</p>
<p>In Lua, declare a third parameter:</p>
<pre><code class="language-lua">function join(player_id, state, ctx)
	if ctx.code ~= state.room_code then
		return state              -- refuse: player is not added
	end
	state.players[player_id] = true
	return state
end
</code></pre>
<p>In Erlang, export <code>join/3</code> (<code>join(PlayerId, Ctx, GameState)</code>) alongside or
instead of <code>join/2</code>.</p>
<p>Either way a game that takes only <code>(player_id, state)</code> is unaffected and a
supplied <code>ctx</code> is ignored.</p>
<p>This is how you build join codes, invites, passwords and party checks:
without it there is no channel from a client to your game before
membership exists, so <code>join/2</code> can implement an allowlist but never a code.</p>
<p>Bounded at the server: a flat object, at most 8 keys, keys up to 64 bytes,
string values up to 256 bytes, plus integers and booleans. No nesting.
Violations are rejected with <code>invalid_join_ctx</code>, <code>invalid_join_ctx_key</code>,
<code>join_ctx_too_many_keys</code>, <code>join_ctx_key_too_long</code>, <code>join_ctx_value_too_long</code>,
or <code>invalid_join_ctx_value</code>. None of the six has a code of its own, so each
arrives as <code>ws.request_failed</code> with the reason in <code>details</code> - see
<a href="#error-server-push">error</a>.</p>
<p><strong>A join context does not make a world private.</strong> Only a game that
implements <code>join/3</code> and rejects unauthorised joins restricts entry; a game
that ignores it stays open to anyone holding a <code>world_id</code>.</p>
<h3 id="matchinput" tabindex="-1"><code>match.input</code></h3>
<p>Send game input to the match server.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.input&quot;, &quot;payload&quot;: {&quot;action&quot;: &quot;move&quot;, &quot;x&quot;: 10, &quot;y&quot;: 5}}
</code></pre>
<p>As with <a href="#worldinput"><code>world.input</code></a>, the <code>payload</code> IS the input map. Two
<strong>deprecated</strong> compatibility shapes survive here and will go at the next
protocol break: a payload whose only key is <code>data</code> mapped to an object is
unwrapped to that object, and one whose only key is <code>data</code> mapped to a JSON
<em>string</em> is decoded and unwrapped. A malformed string, a decoded value that is
not an object, or a <code>payload</code> that is not an object at all is answered with
<code>error</code>, reason <code>invalid_payload</code>.</p>
<p>When the connection is in a world rather than a match, <code>match.input</code> is routed
to your zone, so the two frames reach the same <code>handle_input/3</code>.</p>
<p>Input sent while not in a match or world is dropped. The first drop (at
most one per 5 seconds per connection) is answered with an error event so
the client can tell input is going nowhere:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;error&quot;, &quot;payload&quot;: {&quot;type&quot;: &quot;match.input&quot;, &quot;reason&quot;: &quot;not_in_match&quot;, &quot;error&quot;: {&quot;code&quot;: &quot;match.not_in_match&quot;, &quot;message&quot;: &quot;This connection is not joined to a match.&quot;, &quot;details&quot;: {}}}}
</code></pre>
<h3 id="error-server-push" tabindex="-1"><code>error</code> (server push)</h3>
<p>Every failure on this socket is an <code>error</code> frame, carrying the <code>cid</code> of the
request that caused it when there was one:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;error&quot;, &quot;cid&quot;: &quot;c-17&quot;, &quot;payload&quot;: {&quot;reason&quot;: &quot;world_not_found&quot;, &quot;error&quot;: {&quot;code&quot;: &quot;world.not_found&quot;, &quot;message&quot;: &quot;No live world exists with this id.&quot;, &quot;details&quot;: {}}}}
</code></pre>
<ul>
<li><code>error.code</code> is the contract - stable, machine-readable, and namespaced by
domain (<code>match.</code>, <code>world.</code>, <code>chat.</code>, <code>dm.</code>, <code>matchmaker.</code>, <code>rpc.</code>, <code>ws.</code>) or
bare when it is cross-cutting (<code>rate_limited</code>, <code>join_rate_limited</code>,
<code>unauthenticated</code>, <code>forbidden</code>, <code>payload_too_large</code>, <code>invalid_json</code>,
<code>invalid_message</code>, <code>invalid_payload</code>, <code>missing_field</code>, <code>unknown_type</code>,
<code>internal</code>). Branch on this. Codes come from the same closed set the
<a href="/docs/protocols/rest#errors">REST API</a> uses.</li>
<li>The two surfaces agree only where a failure has a first-class code. A
WebSocket reason that has one carries it, so <code>world_not_found</code> here and a
404 on <code>GET /api/v1/worlds/:id</code> are both <code>world.not_found</code>. Everything else
arrives as <code>ws.request_failed</code> with the reason in <code>details</code>, including
several common failures. On this page that covers the world capacity pair
(<code>world_capacity_reached</code>, <code>player_world_limit_reached</code>, which REST answers
as <code>world.capacity_reached</code> and <code>world.player_limit_reached</code>) and every
join-context rejection listed under <a href="#join-context">Join context</a>. Match a
reason string on <code>details.reason</code> for those, not a code.</li>
<li><code>error.message</code> is prose for a human reading a log. Do not parse it.</li>
<li><code>error.details</code> is <strong>always</strong> an object, <code>{}</code> when there is nothing to add.</li>
<li><code>reason</code> is the original, flatter dialect. It is unchanged and still sent, so
existing clients keep working, but it is not namespaced and two unrelated
failures can share a string. Prefer <code>error.code</code>.</li>
</ul>
<p>A reason with no code of its own yet - including anything a Lua game script
returns from a rejected join - arrives as <code>ws.request_failed</code> with the raw
string in <code>details</code>, so script-supplied text can never mint a code:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;error&quot;, &quot;payload&quot;: {&quot;reason&quot;: &quot;party_is_full&quot;, &quot;error&quot;: {&quot;code&quot;: &quot;ws.request_failed&quot;, &quot;message&quot;: &quot;The request failed. See `details.reason`.&quot;, &quot;details&quot;: {&quot;reason&quot;: &quot;party_is_full&quot;}}}}
</code></pre>
<h3 id="moduleerror-server-push" tabindex="-1"><code>module.error</code> (server push)</h3>
<p>An extension callback error, sent to the player whose input triggered it.
Only emitted when the extension runs with dev errors enabled (for asobi's
Lua runtime, <code>ASOBI_DEV_ERRORS=true</code> or <code>{asobi_lua, [{dev_errors, true}]}</code>);
production runtimes keep script errors server-side.</p>
<p><code>module</code> names the extension that produced the error. It is the only field
asobi owns; the rest of the payload is the extension's.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;module.error&quot;, &quot;payload&quot;: {&quot;module&quot;: &quot;lua&quot;, &quot;callback&quot;: &quot;handle_input&quot;, &quot;script&quot;: &quot;match.lua&quot;, &quot;message&quot;: &quot;bad arithmetic + on nil, 1&quot;}}
</code></pre>
<h3 id="modulemessage-server-push" tabindex="-1"><code>module.message</code> (server push)</h3>
<p>A message addressed to one player by an extension - in Lua,
<code>game.send(player_id, message)</code>. The message is wrapped rather than sent
raw, because it may be any scripting value (string, number, table).</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;module.message&quot;, &quot;payload&quot;: {&quot;module&quot;: &quot;lua&quot;, &quot;message&quot;: &quot;you are player 3&quot;}}
</code></pre>
<h3 id="moduleevent-server-push" tabindex="-1"><code>module.event</code> (server push)</h3>
<p>A named, routable event an extension pushes to a player from its own Erlang
code with <code>asobi_extensions:emit/4</code>. Unlike <code>module.message</code> (an unnamed dev
message) this frame carries a routing key clients dispatch on. It is emitted as
a single frame with no legacy alias.</p>
<p><code>module</code> is the emitter's registered short name. <code>event</code> is <code>&lt;domain&gt;.&lt;name&gt;</code>,
where <code>domain</code> is an RPC prefix the extension owns. <code>data</code> is always an object.</p>
<p><code>module</code> may legitimately differ from the <code>event</code> domain, because an extension
can own an RPC prefix that is not its own name - so a consumer should key off
whichever of the two it actually means, deliberately.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;module.event&quot;, &quot;payload&quot;: {&quot;module&quot;: &quot;quests&quot;, &quot;event&quot;: &quot;quests.completed&quot;, &quot;data&quot;: {&quot;quest_id&quot;: &quot;01j8x000000000000000000042&quot;, &quot;reward&quot;: 250}}}
</code></pre>
<h3 id="gameerror-gamemessage-server-push-deprecated" tabindex="-1"><code>game.error</code> / <code>game.message</code> (server push, deprecated)</h3>
<p>The pre-rename names for the two frames above. Deprecated. <strong>New SDK code
dispatches on <code>module.error</code> and <code>module.message</code>.</strong> The pair is removed
at the 1.0 wire break and will not be replaced.</p>
<p>They are still emitted, byte-identical payload and same reply as their
<code>module.*</code> twin, so every SDK built before the rename keeps working with
no change. Each message therefore produces two frames today: the legacy
frame first, then the <code>module.*</code> frame.</p>
<p>Do not dispatch on both - a client that handles <code>game.message</code> and
<code>module.message</code> processes every message twice.</p>
<p>Neither name was ever Lua-specific: both frames are produced by
extensions in general, which is why the producer travels in the payload's
<code>module</code> key. Clients that care which extension spoke read
<code>payload.module</code> and treat a missing value as <code>&quot;lua&quot;</code>. <code>game.*</code> put one
extension in the wire type, where no second extension could reuse it -
that is what the rename fixes.</p>
<p><strong>Wire history.</strong> <code>module.*</code> did not exist on the wire in any release
before this change: not in v0.54.0, and not in v0.53.0, where commit
<code>a6bc2eb</code> says otherwise. That commit's message describes a dual-emit
that its own follow-up commit in the same pull request removed, because
Nova could not send two frames from one reply at the time
(novaframework/nova#400). Every release up to v0.54.0 emits <code>game.error</code>
and <code>game.message</code> only.</p>
<p><strong>Turning the legacy pair off.</strong> Set <code>asobi.ws_legacy_game_frames</code> to
<code>false</code> to emit only <code>module.*</code>. <code>game.message</code> is <code>game.send/2</code>, which a
script may call per player per tick, so on a chatty game the compat frame
doubles asobi's hottest extension-produced egress. Any client still
dispatching on <code>game.*</code> goes silent when you do this, so flip it only
once every client on the deployment reads <code>module.*</code>. It defaults to
<code>true</code> and becomes a no-op at 1.0.</p>
<h3 id="matchstate-server-push" tabindex="-1"><code>match.state</code> (server push)</h3>
<p>Server broadcasts game state updates to all players in the match.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.state&quot;, &quot;payload&quot;: {&quot;players&quot;: {...}, &quot;tick&quot;: 42}}
</code></pre>
<p>There is no &quot;match started&quot; frame. The match server notifies its players on
<code>finished</code> and on nothing else, so a client learns the match began from
<code>match.matched</code> (matchmaker) or <code>match.joined</code> (its own join reply), and
then from the first <code>match.state</code>.</p>
<h3 id="matchfinished-server-push" tabindex="-1"><code>match.finished</code> (server push)</h3>
<p>Notification that a match has ended with results.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.finished&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;, &quot;result&quot;: {...}}}
</code></pre>
<p><code>result</code> is whatever your game returned with <code>{finished, Result, State}</code>;
asobi does not interpret it, with one exception. It reads <code>winners</code> (a list
of player ids) or <code>winner</code> (one id), and <code>losers</code> / <code>loser</code>, to move the
<code>wins</code> and <code>losses</code> columns in <code>player_stats</code>. <code>games_played</code> moves for
every player in the match either way. Declare winners without losers and
every other player in the match takes the loss; declare <code>losers: []</code> to
score a co-op run where nobody loses. <code>rating</code> and <code>rating_deviation</code> are
not maintained by asobi.</p>
<h3 id="matchleave" tabindex="-1"><code>match.leave</code></h3>
<p>Leave the current match.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.leave&quot;, &quot;payload&quot;: {}}
</code></pre>
<h4 id="matchleft-reply" tabindex="-1"><code>match.left</code> (reply)</h4>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.left&quot;, &quot;cid&quot;: &quot;l-1&quot;, &quot;payload&quot;: {&quot;success&quot;: true}}
</code></pre>
<p>Sent whether or not the connection was in a match, so leaving is safe to
call unconditionally on teardown.</p>
<h2 id="matchmaking" tabindex="-1">Matchmaking</h2>
<p>The queue is per node. A ticket lives in the matchmaker process on the node
that accepted it, there is no ticket table, and the matcher only ever sees
that node's tickets. Two players who queue for the same mode against
different nodes therefore never match each other, and a ticket id is
meaningless on any other node. A cluster needs every matchmaker call from
one player pinned to one node, and matchmaking only works at all if the
whole population lands on one node or the fleet is deliberately partitioned
by mode.</p>
<p>World and match discovery and join are <strong>not</strong> subject to this. They resolve
through a cluster-wide process registry rather than the matchmaker's own
state, so <code>world.list</code>, <code>match.list</code>, <code>world.join</code> and <code>match.join</code> reach a
world or match on any node. See <a href="/docs/clustering">Clustering</a>.</p>
<h3 id="matchmakeradd" tabindex="-1"><code>matchmaker.add</code></h3>
<p>Submit a matchmaking ticket.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;matchmaker.add&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;arena&quot;, &quot;properties&quot;: {&quot;skill&quot;: 1200}}}
</code></pre>
<h4 id="matchmakerqueued-reply" tabindex="-1"><code>matchmaker.queued</code> (reply)</h4>
<pre><code class="language-json">{&quot;type&quot;: &quot;matchmaker.queued&quot;, &quot;cid&quot;: &quot;q-1&quot;, &quot;payload&quot;: {&quot;ticket_id&quot;: &quot;...&quot;, &quot;status&quot;: &quot;pending&quot;, &quot;players_needed&quot;: 4, &quot;already_queued&quot;: false}}
</code></pre>
<p><code>players_needed</code> is the mode's configured <code>match_size</code>, or <code>null</code> when the
mode declares none. How many others are already waiting is deliberately not
reported.</p>
<p>A mode that resolves to no game module is <code>unknown_mode</code>
(<code>matchmaker.unknown_mode</code>); a full queue is <code>queue_full</code>
(<code>matchmaker.queue_full</code>). Re-adding for a mode you already have an open
ticket for returns that same ticket rather than a second one, and sets
<code>already_queued</code> to <code>true</code>.</p>
<p><code>already_queued</code> exists so a reconnecting client can tell &quot;my resubmit was
absorbed, my original wait still stands&quot; from &quot;freshly queued&quot;. Keep the
elapsed timer running on <code>true</code> - <code>max_wait_seconds</code> counts from the ticket's
original submission, not from the resubmit.</p>
<h3 id="matchmakerremove" tabindex="-1"><code>matchmaker.remove</code></h3>
<p>Cancel a matchmaking ticket.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;matchmaker.remove&quot;, &quot;payload&quot;: {&quot;ticket_id&quot;: &quot;...&quot;}}
</code></pre>
<h4 id="matchmakerremoved-reply" tabindex="-1"><code>matchmaker.removed</code> (reply)</h4>
<pre><code class="language-json">{&quot;type&quot;: &quot;matchmaker.removed&quot;, &quot;cid&quot;: &quot;r-1&quot;, &quot;payload&quot;: {&quot;success&quot;: true}}
</code></pre>
<p>Another player's ticket is <code>not_owner</code> (<code>forbidden</code>). An unknown ticket is
<code>not_found</code>, which has no code of its own and arrives as <code>ws.request_failed</code>.
A ticket issued by another node reads as unknown here.</p>
<h3 id="matchmatched-server-push" tabindex="-1"><code>match.matched</code> (server push)</h3>
<p>Notification that the matchmaker paired you into a match. The join is
already done: the matchmaker joins every paired player before sending this,
so no <code>match.join</code> follows.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.matched&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;, &quot;players&quot;: [&quot;...&quot;, &quot;...&quot;]}}
</code></pre>
<p>A mode whose matches are backed by a <strong>world</strong> rather than a match server
sends a different payload on the same frame: <code>match_id</code> holds the world id,
<code>mode</code> is present, and the roster is under <code>player_ids</code> rather than
<code>players</code>. Read both keys if your game has any world-backed mode.</p>
<p>Distinct from <code>match.joined</code>, which is the reply to a client-initiated
<code>match.join</code>. Both mean &quot;you are in a match and <code>match.state</code> will follow&quot;,
but only <code>match.matched</code> arrives unprompted and without a <code>cid</code>.</p>
<h3 id="matchmatchmaker_expired-server-push" tabindex="-1"><code>match.matchmaker_expired</code> (server push)</h3>
<p>Your ticket waited longer than <code>matchmaker.max_wait_seconds</code> (default 60)
without being matched. It is gone; submit a new one to keep queuing.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.matchmaker_expired&quot;, &quot;payload&quot;: {&quot;ticket_id&quot;: &quot;...&quot;}}
</code></pre>
<h3 id="matchmatchmaker_failed-server-push" tabindex="-1"><code>match.matchmaker_failed</code> (server push)</h3>
<p>A group formed but the match could not be started, so everyone in it is back
out of the queue. <code>reason</code> is <code>match_start_failed</code> or <code>no_game_module</code>.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.matchmaker_failed&quot;, &quot;payload&quot;: {&quot;reason&quot;: &quot;match_start_failed&quot;}}
</code></pre>
<h2 id="worlds" tabindex="-1">Worlds</h2>
<p>The world server runs persistent shared spaces with zoned interest
management. See <a href="/docs/world-server">World server</a> for the model and
<a href="https://hexdocs.pm/asobi/large-worlds.html">Large worlds</a> for tuning.</p>
<h3 id="worldlist" tabindex="-1"><code>world.list</code></h3>
<p>List running worlds. Optional filters: <code>mode</code> (string, up to 64 bytes) and
<code>has_capacity</code> (bool - only worlds that are not full). A filter of the wrong
type is rejected with <code>invalid_mode_filter</code> or <code>invalid_has_capacity_filter</code>
rather than silently dropped.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.list&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;walkers&quot;, &quot;has_capacity&quot;: true}}
</code></pre>
<p>Response:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.list&quot;, &quot;payload&quot;: {&quot;worlds&quot;: [{&quot;world_id&quot;: &quot;...&quot;, &quot;mode&quot;: &quot;walkers&quot;, &quot;player_count&quot;: 1, &quot;max_players&quot;: 8}]}}
</code></pre>
<h3 id="worldcreate" tabindex="-1"><code>world.create</code></h3>
<p>Create a new world for the given mode. Refuses with
<code>world_capacity_reached</code> (global cap hit) or <code>player_world_limit_reached</code>
(per-player cap hit). Neither reason has a code of its own on this socket:
both arrive as <code>ws.request_failed</code> with the reason in <code>details</code>, unlike
<code>POST /api/v1/worlds</code>, which answers <code>world.capacity_reached</code> (503) and
<code>world.player_limit_reached</code> (429). On success the caller is auto-joined and
the reply is <code>world.joined</code>.</p>
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
<p>Send game input to your zone. The <code>payload</code> IS the input map; the server
forwards it verbatim to your <code>handle_input/3</code> callback and field names are
entirely up to your game.</p>
<p>One <strong>deprecated</strong> compatibility shape survives: a payload whose <em>only</em> key is
<code>data</code>, mapped to an object, is unwrapped to that object. It exists for clients
that predate this rule and will be removed at the next protocol break; do not
send it. A <code>data</code> key alongside any other key is not special, and neither is a
<code>data</code> whose value is not an object - both reach <code>handle_input/3</code> untouched,
with the rest of the payload intact.</p>
<p>A <code>payload</code> that is not an object at all is rejected with an <code>error</code> frame,
reason <code>invalid_payload</code>. It is not silently treated as empty input.</p>
<p>For client-side prediction, add an optional <code>seq</code> <em>alongside</em> <code>payload</code> (a
sibling, so &quot;the payload IS the input map&quot; stays true). The server echoes the
highest consumed <code>seq</code> back as a <a href="#worldack-server-push"><code>world.ack</code></a>; see
<a href="#client-side-prediction">Client-side prediction</a>. A <code>seq</code> that is not a
non-negative integer below 2^53 is ignored.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.input&quot;, &quot;seq&quot;: 412, &quot;payload&quot;: {&quot;kind&quot;: &quot;move&quot;, &quot;x&quot;: 600, &quot;y&quot;: 480}}
</code></pre>
<p>The server routes the message to whichever zone owns your player
entity - clients do not specify zone coordinates. Input sent while not in a
zone is dropped with no reply at all.</p>
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
the <strong>initial snapshot</strong> for every entity in the zone - register your
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
<td>Added, full state</td>
<td>id + every field on the entity</td>
</tr>
<tr>
<td><code>&quot;u&quot;</code></td>
<td>Updated, diff</td>
<td>id + only changed fields</td>
</tr>
<tr>
<td><code>&quot;r&quot;</code></td>
<td>Removed</td>
<td>id only</td>
</tr>
</tbody>
</table>
<h3 id="client-side-prediction" tabindex="-1">Client-side prediction</h3>
<p>asobi is server-authoritative, and server-side rollback, replay and lag
compensation are out of scope (TCP transport - see
<a href="https://hexdocs.pm/asobi/migrate-from-hathora.html">migrate-from-hathora</a>). The server half that
<em>client-side</em> prediction needs - an ack telling a client which of its inputs the
authoritative state already includes - is a first-class primitive:</p>
<ol>
<li>The client stamps each <code>world.input</code> with its own increasing <code>seq</code> (a sibling
of <code>payload</code>) and applies the input locally right away (the prediction).</li>
<li>The server records the highest <code>seq</code> it consumed for that player - a rejected
input still counts, so a dropped input never strands the client - and sends it
back on the next broadcast as a <a href="#worldack-server-push"><code>world.ack</code></a>
addressed to that connection alone.</li>
<li>The client discards every predicted input up to that <code>seq</code> and replays the
rest on top of the authoritative <code>world.tick</code> state (the reconciliation).</li>
</ol>
<p>Set <a href="/docs/world-server"><code>broadcast_interval</code></a> to 1 so the ack returns every tick.</p>
<p>The ack is addressed to one connection: it is sent only to clients that opted in
by stamping a <code>seq</code>, and never rides the shared <code>world.tick</code>, so one player's
input stream is never broadcast to the rest of the zone.</p>
<p><strong><code>seq</code> never goes backwards on a connection.</strong> The high-water mark is recorded
per zone, and a player is subscribed to their whole interest ring, so during a
crossing more than one zone can hold a mark for them. The connection drops any
ack that does not advance the highest <code>seq</code> it has already sent you, so you can
prune against the value you receive without tracking a maximum yourself.</p>
<p><strong>If your SDK does not yet surface <code>world.ack</code></strong>, the same reconciliation works
in userland: write the <code>seq</code> onto the player's entity in <code>handle_input/3</code>
(<code>entity.last_seq = input.seq</code>) and read it back off the <code>world.tick</code> delta. The
tradeoff is that <code>last_seq</code> then sits on the shared entity delta, so it reaches
every subscriber in the zone - its bandwidth scales with zone population, which
is exactly what the <code>world.ack</code> frame avoids.</p>
<h3 id="worldack-server-push" tabindex="-1"><code>world.ack</code> (server push)</h3>
<p>Acknowledgement of the highest <code>world.input</code> <code>seq</code> the server has consumed for
you as of <code>tick</code>, and monotonic for the life of the connection. Addressed to your
connection alone, and sent only to clients that stamped a <code>seq</code> on their input;
use it to reconcile prediction (above).</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.ack&quot;, &quot;payload&quot;: {&quot;tick&quot;: 42, &quot;seq&quot;: 412}}
</code></pre>
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
<p>Phase state for a world whose mode declares phases. Only worlds emit this;
there is no match equivalent, so a client that wants phases in a match reads
them out of <code>match.state</code> or has the script broadcast its own event.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.phase_changed&quot;, &quot;payload&quot;: {&quot;world_id&quot;: &quot;...&quot;, &quot;status&quot;: &quot;active&quot;, &quot;phase&quot;: &quot;combat&quot;, &quot;remaining_ms&quot;: 42000, &quot;config&quot;: {}, &quot;timers&quot;: {}}}
</code></pre>
<p><code>status</code> is <code>waiting</code>, <code>active</code> or <code>complete</code>, and it decides which other
fields are present:</p>
<table>
<thead>
<tr>
<th><code>status</code></th>
<th>Fields beside <code>phase</code></th>
</tr>
</thead>
<tbody>
<tr>
<td><code>waiting</code></td>
<td><code>start_condition</code> - what the phase is waiting for.</td>
</tr>
<tr>
<td><code>active</code></td>
<td><code>remaining_ms</code>, <code>config</code> (the phase's own config object) and <code>timers</code> (the phase's live timers, keyed by id).</td>
</tr>
<tr>
<td><code>complete</code></td>
<td>None. <code>phase</code> is <code>null</code>.</td>
</tr>
</tbody>
</table>
<p>The frame is sent on every transition, and again periodically while a phase
runs, so a client must treat it as state rather than as an edge. <code>world_id</code>
is present on the transition frame and absent from the periodic one; do not
key off it.</p>
<h2 id="chat" tabindex="-1">Chat</h2>
<p>Channel ids are namespaced: every id must start with one of these prefixes, and
a <code>chat.join</code> whose channel id is missing or unprefixed is rejected with
<code>invalid_channel_id</code> (<code>chat.invalid_channel_id</code>). The prefix lets the runtime
route the message and enforce membership without a per-frame registry lookup.</p>
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
<td>The two named participants only.</td>
</tr>
<tr>
<td><code>global:</code></td>
<td>Game-wide chat, spans every world</td>
<td>Any signed-in player, for a name the operator declared.</td>
</tr>
<tr>
<td><code>world:</code></td>
<td>World-wide chat</td>
<td>Players currently joined to the world.</td>
</tr>
<tr>
<td><code>zone:</code></td>
<td>A specific zone within a world</td>
<td>Players currently joined to the world.</td>
</tr>
<tr>
<td><code>prox:</code></td>
<td>Proximity chat (radius around a position)</td>
<td>Players currently joined to the world.</td>
</tr>
<tr>
<td><code>room:</code></td>
<td>App-defined group chat</td>
<td>Members of the group whose id is the part of the channel id after <code>room:</code>. Not open-join.</td>
</tr>
</tbody>
</table>
<p><code>global:&lt;name&gt;</code> is the only scheme that outlives a single world, so it is the
one to use for &quot;everyone in the game&quot;. A client cannot mint one: the name must
appear in the <code>chat =&gt; #{global =&gt; [...]}</code> of a configured game mode, otherwise
the join is rejected like any other unauthorised channel. Names are up to 64
bytes of <code>a-z A-Z 0-9 _ - .</code>. Players in a world whose mode declares a global
channel are joined to it automatically on <code>world.join</code> and left on
<code>world.leave</code>, exactly as with <code>world:</code> - see the
<a href="/docs/world-server#chat-channels">World Server</a> guide.</p>
<p>There is no open-join room policy and no <code>match:</code> scheme. <code>room:</code> is authorised
as a group membership check: the runtime strips the <code>room:</code> prefix and looks up
the remainder as a group id, so <code>room:&lt;group_id&gt;</code> authorises exactly the members
of <code>&lt;group_id&gt;</code>, not members of a group literally named <code>&quot;room:&lt;group_id&gt;&quot;</code>. For
pre-game lobby chat, gate on world membership with <code>world:&lt;world_id&gt;</code>, or use
<code>game.broadcast</code>; see the <a href="https://hexdocs.pm/asobi/lobbies.html">Lobbies</a> guide.</p>
<p>For a group created with <code>open=true</code>, anyone can join without an invite
(<code>POST /api/v1/groups/:id/join</code> never rejects with <code>group_closed</code>). Membership
is still required to read <code>room:&lt;group_id&gt;</code> - joining is what's unrestricted,
not reading. Once joined, a member sees the group's full retained history (up
to the last 200 messages, per the <code>history</code> limit below), including messages
sent before they joined. This is intentional and matches how public channels
work in Slack/Discord: it is not a bug or a cutoff to add later.</p>
<p>The worked examples below use a <code>world:</code> channel, which authorises on world
membership you already hold after <code>world.join</code>.</p>
<p>A single connection may join at most <strong>32 channels</strong> at once; a 33rd is rejected
with <code>too_many_channels</code> (<code>chat.too_many_channels</code>). Idle channels with no
members stop after 60s; rejoining is cheap.</p>
<p><code>chat.send</code> never answers with a size error. Content over 2000 bytes, and
content that is not a string, is dropped with no reply at all, and empty
content is accepted and broadcast. A client that needs either rejected has to
check before sending. The only failure <code>chat.send</code> reports is <code>not_authorized</code>
(<code>forbidden</code>), for a malformed channel id or a channel this player may not
write to. <code>content_empty</code> and <code>content_too_large</code> are direct-message codes -
see <a href="#direct-messages">Direct messages</a>.</p>
<p>History (<code>GET /api/v1/chat/:channel_id/history</code>) requires membership; <code>?limit</code>
defaults to 50 and clamps to 1-200, and a non-member gets <code>403</code>.</p>
<h3 id="chatjoin" tabindex="-1"><code>chat.join</code></h3>
<p>Join a chat channel. The channel id must be namespaced.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;chat.join&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;world:w_ancient_ruins&quot;}}
</code></pre>
<h4 id="chatjoined-reply" tabindex="-1"><code>chat.joined</code> (reply)</h4>
<pre><code class="language-json">{&quot;type&quot;: &quot;chat.joined&quot;, &quot;cid&quot;: &quot;c-1&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;world:w_ancient_ruins&quot;}}
</code></pre>
<p>A malformed id is <code>invalid_channel_id</code> (<code>chat.invalid_channel_id</code>); a channel
this player is not authorised for is <code>not_authorized</code> (<code>forbidden</code>).</p>
<p>Joining does not replay history. Fetch it from
<code>GET /api/v1/chat/:channel_id/history</code>.</p>
<h3 id="chatsend" tabindex="-1"><code>chat.send</code></h3>
<p>Send a message to a channel.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;chat.send&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;world:w_ancient_ruins&quot;, &quot;content&quot;: &quot;Hello!&quot;}}
</code></pre>
<h3 id="chatmessage-server-push" tabindex="-1"><code>chat.message</code> (server push)</h3>
<p>A new message in a joined channel.</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;chat.message&quot;,
  &quot;payload&quot;: {
    &quot;channel_id&quot;: &quot;world:w_ancient_ruins&quot;,
    &quot;sender_id&quot;: &quot;...&quot;,
    &quot;content&quot;: &quot;Hello!&quot;,
    &quot;sent_at&quot;: 1785312000000
  }
}
</code></pre>
<p><code>sent_at</code> is Unix milliseconds, not an ISO string. The same field on the
persisted history read is a timestamp column, so the two differ.</p>
<h3 id="chatleave" tabindex="-1"><code>chat.leave</code></h3>
<p>Leave a chat channel.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;chat.leave&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;world:w_ancient_ruins&quot;}}
</code></pre>
<h4 id="chatleft-reply" tabindex="-1"><code>chat.left</code> (reply)</h4>
<pre><code class="language-json">{&quot;type&quot;: &quot;chat.left&quot;, &quot;cid&quot;: &quot;c-2&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;world:w_ancient_ruins&quot;}}
</code></pre>
<p>Sent whether or not the connection had joined that channel.</p>
<h2 id="direct-messages" tabindex="-1">Direct messages</h2>
<p>A DM is a chat message on a <code>dm:</code> channel whose id is both player ids sorted
and joined with colons, so both sides always name the same channel. The
sender gets a reply carrying that id; the recipient gets a <code>dm.message</code>
push. Both sides read history from <code>GET /api/v1/dm/:player_id/history</code>.</p>
<h3 id="dmsend" tabindex="-1"><code>dm.send</code></h3>
<pre><code class="language-json">{&quot;type&quot;: &quot;dm.send&quot;, &quot;cid&quot;: &quot;d-1&quot;, &quot;payload&quot;: {&quot;recipient_id&quot;: &quot;...&quot;, &quot;content&quot;: &quot;Hello!&quot;}}
</code></pre>
<h4 id="dmsent-reply" tabindex="-1"><code>dm.sent</code> (reply)</h4>
<pre><code class="language-json">{&quot;type&quot;: &quot;dm.sent&quot;, &quot;cid&quot;: &quot;d-1&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;dm:0197...:0198...&quot;}}
</code></pre>
<table>
<thead>
<tr>
<th>Reason</th>
<th>Code</th>
<th>Cause</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>content_empty</code></td>
<td><code>dm.content_empty</code></td>
<td><code>content</code> was the empty string.</td>
</tr>
<tr>
<td><code>content_too_large</code></td>
<td><code>dm.content_too_large</code></td>
<td><code>content</code> was over 2000 bytes.</td>
</tr>
<tr>
<td><code>blocked</code></td>
<td><code>dm.blocked</code></td>
<td>The recipient has blocked the sender.</td>
</tr>
<tr>
<td><code>invalid_input</code></td>
<td><code>ws.request_failed</code></td>
<td><code>recipient_id</code> or <code>content</code> was not a string.</td>
</tr>
</tbody>
</table>
<p>Unlike <code>chat.send</code>, these are real error frames: a DM that is too long or
empty is refused rather than dropped.</p>
<h3 id="dmmessage-server-push" tabindex="-1"><code>dm.message</code> (server push)</h3>
<p>Addressed to the recipient's session, not to the channel. The sender's own
confirmation is the <code>dm.sent</code> reply.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;dm.message&quot;, &quot;payload&quot;: {&quot;channel_id&quot;: &quot;dm:0197...:0198...&quot;, &quot;sender_id&quot;: &quot;...&quot;, &quot;content&quot;: &quot;Hello!&quot;, &quot;sent_at&quot;: 1785312000000}}
</code></pre>
<p>A recipient who is offline gets no push; the message is persisted either way
and appears in history when they return.</p>
<p>A connection that has also <code>chat.join</code>ed the <code>dm:</code> channel additionally
receives the message as a <code>chat.message</code> on that channel. Handle one or the
other, or a client that does both shows every DM twice.</p>
<h2 id="voting" tabindex="-1">Voting</h2>
<h3 id="votecast" tabindex="-1"><code>vote.cast</code></h3>
<p>Cast a vote in an active match vote.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.cast&quot;, &quot;cid&quot;: &quot;v1&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;, &quot;option_id&quot;: &quot;jungle&quot;}}
</code></pre>
<p>For approval voting, <code>option_id</code> is a list:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.cast&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;, &quot;option_id&quot;: [&quot;jungle&quot;, &quot;caves&quot;]}}
</code></pre>
<h4 id="votecast_ok-reply" tabindex="-1"><code>vote.cast_ok</code> (reply)</h4>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.cast_ok&quot;, &quot;cid&quot;: &quot;v1&quot;, &quot;payload&quot;: {&quot;success&quot;: true}}
</code></pre>
<p>Casting while not in a match is <code>not_in_match</code> (<code>match.not_in_match</code>), and
changing your vote more times than the vote's <code>max_revotes</code> allows (3 by
default) is <code>rate_limited</code>. The refusals that come from the vote itself -
<code>vote_not_found</code>, <code>vote_closed</code>, <code>not_eligible</code>, <code>invalid_option</code> - have no
code of their own and arrive as <code>ws.request_failed</code> with the reason in
<code>details</code>. A vote in a world that has not finished loading is
<code>world_not_ready</code>, carried the same way.</p>
<h3 id="voteveto" tabindex="-1"><code>vote.veto</code></h3>
<p>Use a veto token to cancel the current vote. Requires <code>veto_tokens_per_player &gt; 0</code>
in match config and <code>veto_enabled</code> on the vote.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.veto&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;}}
</code></pre>
<h4 id="voteveto_ok-reply" tabindex="-1"><code>vote.veto_ok</code> (reply)</h4>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.veto_ok&quot;, &quot;cid&quot;: &quot;v2&quot;, &quot;payload&quot;: {&quot;success&quot;: true}}
</code></pre>
<p>An unknown vote is <code>vote_not_found</code>, a player out of tokens is
<code>no_veto_tokens</code>, and a vote that did not enable vetoes is <code>veto_disabled</code>.
None of the three has a code of its own either. A veto in a world that has not
finished loading is <code>world_not_ready</code>, carried the same way.</p>
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
<p>Set your own status string. <code>status</code> is the only field read; anything else in
the payload is discarded. Omitting it sets <code>&quot;online&quot;</code>.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;presence.update&quot;, &quot;cid&quot;: &quot;p-1&quot;, &quot;payload&quot;: {&quot;status&quot;: &quot;in_game&quot;}}
</code></pre>
<h4 id="presenceupdated-reply" tabindex="-1"><code>presence.updated</code> (reply)</h4>
<pre><code class="language-json">{&quot;type&quot;: &quot;presence.updated&quot;, &quot;cid&quot;: &quot;p-1&quot;, &quot;payload&quot;: {&quot;status&quot;: &quot;in_game&quot;}}
</code></pre>
<p>The status is not validated against a list, and it is not persisted: it lives
for the length of the session. There is no push telling a client that another
player's presence changed - a client that needs a friends list with live
status polls for it.</p>
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
<h2 id="extension-rpc" tabindex="-1">Extension RPC</h2>
<p>One frame type reaches every method any installed
<a href="https://hexdocs.pm/asobi/extensions.html">extension</a> declares, so an extension needs no per-extension
SDK work to be callable from a client.</p>
<h3 id="rpccall" tabindex="-1"><code>rpc.call</code></h3>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;rpc.call&quot;,
  &quot;cid&quot;: &quot;c-1&quot;,
  &quot;payload&quot;: {&quot;protocol&quot;: 1, &quot;method&quot;: &quot;quests.claim&quot;, &quot;params&quot;: {&quot;quest_id&quot;: &quot;q-1&quot;}}
}
</code></pre>
<ul>
<li><code>cid</code> is <strong>required</strong> here and validated by the server: 1 to 64 printable
ASCII bytes. Elsewhere on this socket it is an optional echo; an RPC reply
is useless without it, because it is the only way to pair a reply with its
call. A rejected <code>cid</code> is not echoed back, so that one reply carries none.</li>
<li><code>protocol</code> is the RPC payload version, currently <code>1</code>. Version the payload
rather than the frame type, so a server that does not speak your version
says so instead of answering <code>unknown_type</code>.</li>
<li><code>params</code> is <strong>always</strong> an object, <code>{}</code> when the method takes nothing.</li>
<li><code>method</code> is <code>&lt;extension&gt;.&lt;name&gt;</code>. The socket must already be authenticated:
every declared method is player-scoped, and the player is the one that sent
<code>session.connect</code>.</li>
</ul>
<h3 id="rpcok-reply" tabindex="-1"><code>rpc.ok</code> (reply)</h3>
<pre><code class="language-json">{&quot;type&quot;: &quot;rpc.ok&quot;, &quot;cid&quot;: &quot;c-1&quot;, &quot;payload&quot;: {&quot;result&quot;: {&quot;reward&quot;: 100}}}
</code></pre>
<p><code>result</code> is <strong>always</strong> an object, so a method can grow a field without
breaking a shipped client.</p>
<h3 id="rpcerror-reply" tabindex="-1"><code>rpc.error</code> (reply)</h3>
<pre><code class="language-json">{&quot;type&quot;: &quot;rpc.error&quot;, &quot;cid&quot;: &quot;c-1&quot;, &quot;payload&quot;: {&quot;error&quot;: {&quot;code&quot;: &quot;quests.already_claimed&quot;, &quot;message&quot;: &quot;This quest was already claimed.&quot;, &quot;details&quot;: {}}}}
</code></pre>
<p>The same error object the rest of this socket and the
<a href="/docs/protocols/rest#errors">REST API</a> carry, and only that object - the flatter
<code>reason</code> dialect is not repeated on a frame nothing has shipped against.</p>
<p>An extension mints codes in its own domain, so a failure arrives as
<code>quests.already_claimed</code> rather than <code>internal</code>. The set stays closed: a code
no installed extension declared is answered as <code>internal</code> instead of being
reflected back. Codes core itself adds for this surface:</p>
<table>
<thead>
<tr>
<th>Code</th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>rpc.unknown_method</code></td>
<td>No installed extension serves that method</td>
</tr>
<tr>
<td><code>rpc.invalid_cid</code></td>
<td><code>cid</code> was missing, not a string, empty, over 64 bytes, or not printable ASCII</td>
</tr>
<tr>
<td><code>rpc.unsupported_protocol</code></td>
<td><code>details.supported</code> lists the versions this server speaks</td>
</tr>
<tr>
<td><code>rpc.invalid_params</code></td>
<td><code>params</code> was not an object</td>
</tr>
<tr>
<td><code>invalid_payload</code></td>
<td><code>payload</code> itself was not an object</td>
</tr>
<tr>
<td><code>unauthenticated</code></td>
<td>The socket has not completed <code>session.connect</code></td>
</tr>
<tr>
<td><code>not_ready</code></td>
<td>The node is still running migrations. Retry</td>
</tr>
</tbody>
</table>
<h3 id="http-transport" tabindex="-1">HTTP transport</h3>
<p>The same RPC also answers over HTTP, for a client with no open socket:</p>
<pre><code>POST /api/v1/rpc/quests.claim
</code></pre>
<ul>
<li>The method is the last path segment, so <code>quests.claim</code> here is the method the
socket names in its payload. The body carries only <code>params</code>:</li>
</ul>
<pre><code class="language-json">{&quot;params&quot;: {&quot;quest_id&quot;: &quot;q-1&quot;}}
</code></pre>
<ul>
<li><code>protocol</code> is injected server-side, so an HTTP client never sends it, and
<code>rpc.unsupported_protocol</code> cannot fire here; the version lives in the
<code>/api/v1/</code> path instead.</li>
<li>There is no <code>cid</code>. An HTTP reply is self-correlating - it is the response to
this one request and nothing else.</li>
</ul>
<p>The reply is the <strong>same envelope</strong> the socket sends,
<code>{&quot;type&quot;: ..., &quot;payload&quot;: ...}</code>, carrying the same <code>rpc.ok</code> or <code>rpc.error</code>
below it, plus an HTTP status: <code>200</code> for <code>rpc.ok</code>, and the error object's own
status otherwise (the status the <a href="/docs/protocols/rest#errors">REST API</a> gives that
code).</p>
<pre><code class="language-json">200 OK
{&quot;type&quot;: &quot;rpc.ok&quot;, &quot;payload&quot;: {&quot;result&quot;: {&quot;reward&quot;: 100}}}
</code></pre>
<pre><code class="language-json">404 Not Found
{&quot;type&quot;: &quot;rpc.error&quot;, &quot;payload&quot;: {&quot;error&quot;: {&quot;code&quot;: &quot;rpc.unknown_method&quot;, &quot;message&quot;: &quot;No installed extension serves this RPC method.&quot;, &quot;details&quot;: {}}}}
</code></pre>
<p>Both transports share one envelope below the transport, so a single SDK decoder
reads a reply whether it arrived on the socket or from this endpoint.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/rest">REST API</a> - the request/response surface alongside this socket protocol.</li>
<li><a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a> - declaring the methods <code>rpc.call</code> reaches.</li>
<li><a href="/docs/authentication">Authentication</a> - obtaining the token the socket authenticates with.</li>
<li><a href="/docs/voting">Voting</a> - the vote flow whose <code>match.vote_*</code> pushes appear above.</li>
</ul>
"""}
    ]}.
