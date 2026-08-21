%% GENERATED from asobi guides/websocket-protocol.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_websocket_view).

-export([mount/1, render/1, markdown/0]).

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
<pre><code class="language-json">{&quot;type&quot;: &quot;session.connected&quot;, &quot;payload&quot;: {&quot;player_id&quot;: &quot;...&quot;, &quot;wire&quot;: &quot;json&quot;}}
</code></pre>
<p>A bad or expired token answers <code>error</code> with reason <code>invalid_token</code> and code
<code>unauthenticated</code>, and the socket stays open so the client can retry with a
refreshed token.</p>
<h4 id="choosing-a-wire" tabindex="-1">Choosing a wire</h4>
<p><code>session.connect</code> may ask for the binary <code>world.tick</code> encoding:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;session.connect&quot;, &quot;payload&quot;: {&quot;token&quot;: &quot;...&quot;, &quot;wire&quot;: &quot;binary&quot;}}
</code></pre>
<p>The reply always states the wire you actually got, which is not always the one
you asked for: a server with <code>asobi.binary_wire</code> off answers <code>&quot;json&quot;</code>. Read it
rather than assuming, and never infer the answer from the opcode of the first
frame that happens to arrive.</p>
<p>Asking for binary changes <code>world.tick</code> and nothing else. <code>world.ack</code>,
<code>world.terrain</code>, <code>match.*</code>, <code>module.*</code> and every <code>error</code> stay JSON text on both
wires, so a binary client is one that handles both frame types, not one that
stops handling text. A frame the server cannot encode as binary also arrives as
text: an entity field holding a list or a nested map, or a frame needing more
than the 32 field names the dictionary can index.</p>
<p>The uplink is text-only on both wires. A binary frame sent to the server answers
<code>error</code> with reason <code>binary_uplink_unsupported</code>.</p>
<p>See <a href="#binary-world-tick">Binary <code>world.tick</code></a> for the encoding.</p>
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
<h3 id="matchfind_or_create" tabindex="-1"><code>match.find_or_create</code></h3>
<p>Get into a live match of a mode, spawning one if there is none.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.find_or_create&quot;, &quot;cid&quot;: &quot;1&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;arena&quot;}}
</code></pre>
<p>Replies with <code>match.joined</code>, exactly as <code>match.join</code> does. The payload takes
<code>mode</code> only - every other match parameter comes from mode config, so a client
cannot choose <code>max_players</code> or the tick rate.</p>
<p>Eligibility is <code>quick_play</code>, not <code>listed</code> - they are independent axes. A match
mode <strong>defaults to <code>quick_play = false</code></strong>, so a mode is reachable through the
matchmaker alone until you opt it in. A mode that is not eligible answers
<code>quick_play_disabled</code>, the same reason <code>world.find_or_create</code> uses.</p>
<p>That default is deliberate: every match mode written before this frame existed
declares no <code>quick_play</code>, and defaulting it open would expose a ranked mode to a
client that had never been rated or queued.</p>
<p>Prefer this to <code>match.list</code> followed by <code>match.join</code>: the two-step version
races, and two clients reading the same empty listing will each create a match.
This resolves server-side and is serialized, so simultaneous callers converge on
one match.</p>
<p>Subject to the same join rate limit as <code>match.join</code> and <code>world.join</code>, and to a
node-wide cap on live matches (<code>asobi.match_max</code>, default 1000), which answers
<code>match_capacity_reached</code>. A world mode is refused with <code>wrong_mode_type</code>.</p>
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
<a href="/docs/lua/api#join-player_id-state-or-join-player_id-state-ctx">Refusing a join</a>.</p>
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
<p>As with <a href="#world-input"><code>world.input</code></a>, the <code>payload</code> IS the input map. Two
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
join-context rejection listed under <a href="#match-join">Join context</a>. Match a
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
highest consumed <code>seq</code> back as a <a href="#world-ack-server-push"><code>world.ack</code></a>; see
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
<pre><code class="language-json">{&quot;type&quot;: &quot;world.tick&quot;, &quot;payload&quot;: {&quot;zone&quot;: [3, 5], &quot;frame_seq&quot;: 118, &quot;kf&quot;: false, &quot;tick&quot;: 42, &quot;updates&quot;: [{&quot;op&quot;: &quot;a&quot;, &quot;id&quot;: &quot;01HX...&quot;, &quot;x&quot;: 600, &quot;y&quot;: 480, &quot;type&quot;: &quot;player&quot;}]}}
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
<h4 id="apply-per-zone-and-check-the-sequence" tabindex="-1">Apply per zone, and check the sequence</h4>
<table>
<thead>
<tr>
<th>Field</th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>zone</code></td>
<td>The zone these updates belong to, as <code>[x, y]</code>.</td>
</tr>
<tr>
<td><code>frame_seq</code></td>
<td>Contiguous per zone, advancing only on a frame actually sent.</td>
</tr>
<tr>
<td><code>kf</code></td>
<td><code>true</code> on a keyframe: a complete baseline for that zone, all <code>op: &quot;a&quot;</code>.</td>
</tr>
</tbody>
</table>
<p><strong>Keep one entity table per zone, keyed by <code>zone</code>, never one flat table.</strong> You
are subscribed to an interest ring of several zones at once, each an independent
process, and messages are ordered per sender only. Crossing a boundary emits an
<code>op: &quot;r&quot;</code> from the zone you left and an <code>op: &quot;a&quot;</code> from the zone you entered, from
two different senders, so they can reach you in either order. Applied into one
flat table, the removal can land last and delete an entity you will never hear
about again. Per-zone tables make that unreachable.</p>
<p><strong><code>frame_seq</code> is how you detect loss.</strong> It has no gaps by construction, so a
frame whose sequence is more than one past the last you applied for that zone
means you missed something; a frame at or below it is stale and should be
dropped. <code>tick</code> cannot do this job - it skips on <code>broadcast_interval</code> and is
suppressed on a quiet tick, so a gap in it is ambiguous.</p>
<p>Two frames are applied <strong>ungated</strong>, without the sequence check:</p>
<ul>
<li><code>kf: true</code>, which resets your high-water mark to the value it carries. That is
what makes a zone restart recoverable.</li>
<li>A frame with no <code>frame_seq</code> at all, which is the removal list you get for the
zone you are leaving. Gating it would leave you holding ghosts forever.</li>
</ul>
<p>On a gap, send <a href="#world-resync"><code>world.resync</code></a> for that zone and you get a fresh
keyframe.</p>
<h3 id="binary-worldtick" tabindex="-1">Binary <code>world.tick</code></h3>
<p>A client that negotiated <code>&quot;wire&quot;: &quot;binary&quot;</code> at
<a href="#session-connect"><code>session.connect</code></a> receives <code>world.tick</code> as a <strong>WebSocket
binary frame</strong> carrying the same information in about a quarter of the bytes, and
materially cheaper to decode: measured against native JSON, 2.4x faster in
Godot's GDScript and 33x faster than the pure-Lua parser Defold and LOVE ship.
Every other message type still arrives as JSON text.</p>
<p>All multi-byte integers and floats are <strong>little-endian</strong>. That is not the usual
choice for a wire format, and it is deliberate: Godot's
<code>PackedByteArray.decode_*</code> reads little-endian and has no big-endian counterpart,
so network byte order would force a hand-rolled byte loop in interpreted
GDScript - and those native calls are exactly why the codec beats JSON there
rather than losing to it. Every other target reads either order for the same
price, so the runtime with no room to spare picks.</p>
<pre><code>frame    Kind:8, ZX:32/signed, ZY:32/signed, FrameSeq:64, Kf:8, Tick:64,
         DictLen:8, Dict, RecCount:16, Records

dict     for each name: Len:8, Name/binary            (at most 32 names)
record   Op:8, Slot:16, [IdLen:8, Id/binary]?, FieldCount:8, Fields
field    Type:3, Idx:5, Value                         (one header byte)
</code></pre>
<p><code>Kind</code> is <code>1</code> for a frame holding a position in the zone's sequence and <code>2</code> for
one that does not - the binary equivalent of the text wire omitting <code>frame_seq</code>.
A <code>2</code> frame is the leave-removal list, and it is applied ungated.</p>
<p><code>Op</code> is <code>0</code> add, <code>1</code> update, <code>2</code> remove. <code>Type</code> selects the value encoding:</p>
<table>
<thead>
<tr>
<th><code>Type</code></th>
<th>Value</th>
</tr>
</thead>
<tbody>
<tr>
<td>0</td>
<td><code>float32</code></td>
</tr>
<tr>
<td>1</td>
<td><code>int32</code>, signed</td>
</tr>
<tr>
<td>2</td>
<td><code>true</code>, no bytes follow</td>
</tr>
<tr>
<td>3</td>
<td><code>false</code>, no bytes follow</td>
</tr>
<tr>
<td>4</td>
<td><code>Len:16, UTF-8 bytes</code></td>
</tr>
<tr>
<td>5</td>
<td><code>null</code>, no bytes follow</td>
</tr>
</tbody>
</table>
<p><code>Idx</code> indexes the frame's own dictionary, so forty records all carrying
<code>x, y, vx, vy</code> pay for four names rather than a hundred and sixty. The frame is
self-describing: nothing is negotiated up front and nothing survives a
reconnect.</p>
<p><strong>Five bits of index means a frame carries at most 32 distinct field names</strong>, and
this is a budget worth knowing before you hit it. It is counted across the whole
frame, not per entity, but one entity is what usually spends it: a delta names
only the fields that changed, while the <code>add</code> that introduces an entity names all
of them. An entity with 33 fields therefore cannot ride this wire at all.</p>
<p>A frame past the budget is sent as text instead. That is safe for the frame and
not safe on its own for what follows: <strong>a text add carries no slot</strong>, so the
entities it introduced are not in your table, and the next binary frame names
them in <code>op:&quot;u&quot;</code> records you have to drop - with a contiguous <code>frame_seq</code> that
gives you no reason to resync.</p>
<p>So the server repairs it rather than leaving it to you. The frame after a refused
one is a <strong>keyframe</strong> - <code>kf: true</code>, all adds - which re-establishes every binding.
Nothing is required of a client that already applies keyframes the way this guide
describes. If that keyframe is refused too, the cause is the shape of the game's
entities rather than one frame, and the zone gives the binary wire up: every
client on it falls back to text, which carries everything, and the datagram
plane switches off with it. The zone asks again later on a doubling backoff -
a minute, then two, up to an hour - so an entity that was briefly unencodable
costs a pause rather than the rest of the zone's life. A successful retry is
itself a keyframe, so every client is rebound by it.</p>
<p>Both outcomes are visible server-side, and neither is silent on the client's
behalf. If a game seems to be missing the datagram plane, count the fields on its
widest entity and look for <code>binary world.tick frame refused</code> or
<code>binary wire disabled for this zone</code> in the server log; both name the zone, the
distinct-name count and the widest entity.</p>
<p><strong>Entities are 2-byte slots, and the slot is scoped to the zone.</strong> A record
carries the full entity id on an <strong>add only</strong>, which is where the binding is
established; update and remove carry the slot and generation alone.</p>
<p><code>Gen</code> advances every time a slot is rebound to a different entity. On this wire it
is redundant, because the stream is ordered and reliable and <code>frame_seq</code> already
bounds the reuse hazard, and it is carried anyway so that a client also running
the datagram plane can keep one slot table for both carriers rather than two that
can disagree. If you are only on the WebSocket you can ignore it. Keep a slot-to-id table per
zone - slot 5 in one zone has nothing to do with slot 5 in another - and let an
add REPLACE any binding already there, because a freed slot is eventually
reused. There is no mapping message and none is needed: a keyframe is all-adds,
so <code>world.resync</code> re-establishes every binding for you.</p>
<p>The binary wire is also what the <a href="https://hexdocs.pm/asobi/datagram-plane.html">datagram plane</a> builds on:
its <code>pose</code> frames carry slots, and the bindings come from the <code>add</code> records here.</p>
<p>A committed fixture corpus lives in <code>priv/wire_fixtures/</code> - one <code>.bin</code> per case
plus a <code>manifest.json</code> saying what each decodes to. Test your decoder against
it; the server's own CI asserts those bytes are still what it produces.</p>
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
back on the next broadcast as a <a href="#world-ack-server-push"><code>world.ack</code></a>
addressed to that connection alone.</li>
<li>The client discards every predicted input up to that <code>seq</code> and replays the
rest on top of the authoritative <code>world.tick</code> state (the reconciliation).</li>
</ol>
<p>Set <a href="/docs/world-server"><code>broadcast_interval</code></a> to 1 so the ack returns every tick.</p>
<p>The ack is addressed to one connection and never rides the shared <code>world.tick</code>,
so one player's input stream is never broadcast to the rest of the zone. It is
sent to clients that opted in by stamping a <code>seq</code>, and to clients whose game
module reports a consumed seq for them - see
<a href="#client-side-prediction">Batched input and the ack</a>, where numbering the
steps inside the payload replaces stamping the frame.</p>
<p><strong><code>seq</code> never goes backwards on a connection.</strong> The high-water mark is recorded
per zone, and a player is subscribed to their whole interest ring, so during a
crossing more than one zone can hold a mark for them. The connection drops any
ack that does not advance the highest <code>seq</code> it has already sent you, so you can
prune against the value you receive without tracking a maximum yourself.</p>
<h4 id="batched-input-and-the-ack" tabindex="-1">Batched input and the ack</h4>
<p>Step 2 says &quot;the highest <code>seq</code> it consumed&quot;, and by default that is the <code>seq</code>
stamped on the frame: one input frame, one input, nothing to disagree about.</p>
<p>A client predicting faster than the zone ticks changes that. At 60 Hz against a
12.5 Hz zone there are roughly five simulation steps per tick, so a frame
carries a <em>batch</em> of steps rather than one, and a zone that caps how many steps
it runs per tick parks the rest for the next one. The frame stamp then no longer
describes what ran:</p>
<ul>
<li>Stamp the frame with the <strong>last</strong> seq in the batch and the ack overclaims
whenever steps are parked. The client discards predicted steps the server has
not applied yet, cannot replay them, and drifts until something resyncs it.</li>
<li>Stamp it with the <strong>first</strong> seq and the ack underclaims. The client replays
steps the server already applied and overshoots on every reconciliation.</li>
</ul>
<p>Return the seq you actually consumed and the ack carries that instead:</p>
<pre><code class="language-erlang">handle_input(PlayerId, #{~&quot;steps&quot; := Steps}, Entities) -&gt;
    {Entities1, Watermark} = apply_steps(PlayerId, Steps, Entities),
    {ok, Entities1, Watermark}.
</code></pre>
<pre><code class="language-lua">function handle_input(player_id, input, entities)
  local watermark = apply_steps(input.steps, entities)
  return entities, watermark
end
</code></pre>
<p>The number is in your client's own sequence space - the same numbering the steps
inside the payload carry - and must be a non-negative integer no larger than
2^53-1, the same bound the client-stamped <code>seq</code> is held to. Anything else is
refused with a warning and the frame stamp is used instead: the value is echoed
to your client on every broadcast tick, so a wider one would be an encode
amplifier and unreadable to any SDK holding it in an int64. The rules that come
with it:</p>
<ul>
<li><strong>Report on every input or on none.</strong> Within a tick a report always beats a
frame stamp, whatever order they arrive in. Across ticks it does not: a tick
in which you reported nothing records the frame stamp instead, and the ack
keeps the highest value it has recorded, so one unreported tick pins the ack
above your watermark for good.</li>
<li><strong>Reporting acks a client that never stamped a <code>seq</code>.</strong> If your client numbers
its steps inside the payload it never needs to stamp the frame at all. SDK
authors: this means <code>world.ack</code> can arrive unsolicited, so a client that never
opted in must drop it silently rather than log or raise per frame.</li>
<li><strong>Draining parked steps in <code>zone_tick</code> has no report channel.</strong> The watermark
rides out on the next input you handle, which a client re-sending
unacknowledged steps produces every tick - so it costs a tick, except for a
player at rest, whose final drain stays unacked until they move.</li>
<li><strong><code>{error, Reason}</code> still acks the frame stamp</strong>, because a client must never
wait forever on an input the server chose to drop - unless a report already
landed this tick, which outranks it. Refusing one input does not unrun the
steps another already consumed. A game that parks should model refusal as
<code>{ok, Entities, Watermark}</code> instead.</li>
<li><strong>Deduplicate by the same watermark.</strong> A client that re-sends unacknowledged
steps for redundancy (what makes an unreliable carrier safe) will hand you
steps you have already run; skip them, and report the watermark either way.</li>
</ul>
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
<h3 id="worldresync" tabindex="-1"><code>world.resync</code></h3>
<p>Ask one zone to re-send its baseline, after a <code>frame_seq</code> gap tells you a frame
went missing.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;world.resync&quot;, &quot;payload&quot;: {&quot;zone&quot;: [3, 5]}}
</code></pre>
<p>There is no reply of its own. The answer is a <code>world.tick</code> with <code>kf: true</code> for
that zone, holding every entity as an <code>op: &quot;a&quot;</code> - so on the binary wire it also
re-establishes every slot binding.</p>
<p>A request naming a zone you are not subscribed to is dropped in silence rather
than answered. There is nothing to repair, and answering would turn resync into
a way to read any zone in the world.</p>
<p>Rate limited on two buckets, per player first and then fleet-wide: <strong>2 per 10s
per player</strong> and <strong>20 per second across the server</strong>. A client that needs more
than that is not recovering from loss, it is looping. Tune under
<code>asobi.rate_limits</code>, groups <code>resync</code> and <code>resync_global</code>.</p>
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

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# WebSocket Protocol

Asobi uses a single WebSocket connection per client at `/ws`. All messages
are JSON with a common envelope format.

> **You probably do not call this directly.** This page is the raw wire reference.
> Every official SDK (Defold, Godot, Unity, Unreal, Dart/Flame, JavaScript, LÖVE)
> wraps this protocol: each message you *send* is a function, each message the
> server *pushes* is a callback you register. Reach for this page only to write a
> client from scratch or to debug what is on the wire. For the calls in your
> language, see the realtime section of your [SDK quickstart](https://asobi.dev/docs).

## Message Format

### Client to Server

```json
{
  "cid": "optional-correlation-id",
  "type": "message.type",
  "payload": {}
}
```

### Server to Client

```json
{
  "cid": "correlation-id-if-request",
  "type": "message.type",
  "payload": {}
}
```

The `cid` field is optional. When provided, the server echoes it back in
the response so the client can correlate request/response pairs.

## Custom events

The events listed on this page are the ones asobi itself emits. They are not
the whole `type` space: a game script owns the leaf name under `match.` and
`world.`, so a client must never switch exhaustively on the list below.

`game.broadcast` from a match script:

```lua
game.broadcast("round_start", { phase = "combat" })
```

reaches every player in that match as:

```json
{"type": "match.round_start", "payload": {"phase": "combat"}}
```

The same call from a world script produces `world.round_start` and reaches
every player in the world. There is no `cid` - these are pushes, never
replies.

The runtime validates the leaf name before it goes on the wire:

- 1 to 64 bytes.
- `A-Z`, `a-z`, `0-9`, `_` and `-` only. `.` is excluded, so a script cannot
  mint a deeper `world.foo.bar` sub-namespace.
- Not one of asobi's own leaf names, otherwise a script could forge a frame
  byte-identical to an authoritative event such as `world.tick` or
  `match.finished`. The reserved set is
  `asobi_ws_handler:reserved_event_names/0`:

<!-- BEGIN reserved-event-names (verified against asobi_ws_handler:reserved_event_names/0 by asobi_protocol_coverage_tests) -->
```
ack                 finished            joined              left
list                matched             matchmaker_expired  matchmaker_failed
phase_changed       state               terrain             tick
vote_result         vote_start          vote_tally          vote_vetoed
```
<!-- END reserved-event-names -->

The payload is also capped at 64 KiB encoded, the same bound as an inbound
frame, because it fans out to every player. A payload that cannot be encoded
as JSON at all is rejected on the same path.

A broadcast that fails any of these is dropped and logged server-side. The
client is told nothing, so do not wait for an error frame that will not come.

Client SDKs handle this open namespace with a generic fallback: any
`match.*`/`world.*` type with no dedicated callback has its prefix stripped
and is handed to a catch-all match/world event handler. Every official SDK
has one; a client written from scratch needs one too.

## Connection

### `session.connect`

Authenticate the WebSocket connection. Must be the first message sent. The
token is the `access_token` from any auth route.

```json
{"type": "session.connect", "payload": {"token": "<access_token>"}}
```

Response:

```json
{"type": "session.connected", "payload": {"player_id": "...", "wire": "json"}}
```

A bad or expired token answers `error` with reason `invalid_token` and code
`unauthenticated`, and the socket stays open so the client can retry with a
refreshed token.

#### Choosing a wire

`session.connect` may ask for the binary `world.tick` encoding:

```json
{"type": "session.connect", "payload": {"token": "...", "wire": "binary"}}
```

The reply always states the wire you actually got, which is not always the one
you asked for: a server with `asobi.binary_wire` off answers `"json"`. Read it
rather than assuming, and never infer the answer from the opcode of the first
frame that happens to arrive.

Asking for binary changes `world.tick` and nothing else. `world.ack`,
`world.terrain`, `match.*`, `module.*` and every `error` stay JSON text on both
wires, so a binary client is one that handles both frame types, not one that
stops handling text. A frame the server cannot encode as binary also arrives as
text: an entity field holding a list or a nested map, or a frame needing more
than the 32 field names the dictionary can index.

The uplink is text-only on both wires. A binary frame sent to the server answers
`error` with reason `binary_uplink_unsupported`.

See [Binary `world.tick`](#binary-world-tick) for the encoding.

### `session.heartbeat`

Keep-alive ping. Send periodically to prevent timeout.

```json
{"type": "session.heartbeat", "payload": {}}
```

Reply, carrying the server's clock in Unix milliseconds:

```json
{"type": "session.heartbeat", "cid": "h-1", "payload": {"ts": 1785312000000}}
```

The reply is the same type as the request. A client that switches on `type`
alone must tolerate that; a `cid` distinguishes the reply from a push.

### Limits

Every bound below is enforced by the socket itself, and a client that
reconnects or backs off needs all of them.

| Bound | What happens |
| --- | --- |
| 60 messages per second per connection | Further frames in that second are answered with `error`, reason `rate_limited`. The connection stays open. |
| 64 KiB per inbound frame | Answered with `error`, reason `payload_too_large`. Measured on the raw frame, before JSON parsing. |
| 10s to send `session.connect` | The socket is closed with code 1008 and the reason `idle_auth_timeout`. Override with `asobi.ws_idle_auth_timeout_ms`. |
| 60 connects per second per IP | The upgrade is closed with 1008 `rate_limited` before anything else runs. Tune under `asobi.rate_limits`, group `ws_connect`. |
| Origin allowlist | A browser `Origin` outside `asobi.ws_allowed_origins` is closed with 1008 `origin_rejected`. With no allowlist configured every Origin passes, and a request with no `Origin` header always passes, because a native client sends none. |

The message-rate window is a fixed 1000ms bucket, not a sliding one: a burst
that straddles the boundary can put 120 frames through in two adjacent
windows. Size a client's send rate against the limit, not against the burst.

Joining is bounded separately, per player rather than per connection: 10
world or match joins per 60 seconds, including `world.create` and
`world.find_or_create`. The 11th is `error` with reason `join_rate_limited`
and code `join_rate_limited`.

The first two bounds are per connection. The connect-flood and join buckets
are per node, so across a cluster the real ceiling is the figure above times
the node count. See [Clustering](https://asobi.dev/docs/clustering).

## Matches

> The `match.input` (client -> server) and `match.state` (server -> all clients)
> pair below is the core real-time loop. In an SDK these are one send function and
> one receive callback - see the realtime section of your [SDK quickstart](https://asobi.dev/docs).

### `match.list`

Browse live, joinable matches. Filters are optional.

```json
{"type": "match.list", "payload": {"mode": "arena", "has_capacity": true, "joinable": true}}
```

Reply payload is `{"matches": [...]}`, each entry carrying `match_id`,
`mode`, `status`, `player_count`, `max_players` and `joinable`. The roster is
not included; see [World Server](https://asobi.dev/docs/world-server) for why discovery and
membership are separate surfaces.

`has_capacity` and `joinable` are separate questions and a client looking for
somewhere to play should ask both: a match with room may have closed itself to
new players, and a full one has not closed - it may free a slot on the next
leave. `joinable` accepts `false` too, for a browser that wants to show
in-progress matches it cannot enter. A filter of the wrong type is rejected
with `invalid_joinable_filter`.

**Matches are unlisted by default.** A matchmaker-spawned match is already
assigned to its players, so it has no reason to appear in a browser. A mode
opts in with `listed = true` (a Lua global, or `listed => true` in the
operator's `game_modes` config). This is the inverse of worlds, which default
to listed.

Distinct from `GET /api/v1/matches`, which reads the match *record* table
(finished matches, an audit trail). `GET /api/v1/matches/live` is the REST
equivalent of this message.

### `match.find_or_create`

Get into a live match of a mode, spawning one if there is none.

```json
{"type": "match.find_or_create", "cid": "1", "payload": {"mode": "arena"}}
```

Replies with `match.joined`, exactly as `match.join` does. The payload takes
`mode` only - every other match parameter comes from mode config, so a client
cannot choose `max_players` or the tick rate.

Eligibility is `quick_play`, not `listed` - they are independent axes. A match
mode **defaults to `quick_play = false`**, so a mode is reachable through the
matchmaker alone until you opt it in. A mode that is not eligible answers
`quick_play_disabled`, the same reason `world.find_or_create` uses.

That default is deliberate: every match mode written before this frame existed
declares no `quick_play`, and defaulting it open would expose a ranked mode to a
client that had never been rated or queued.

Prefer this to `match.list` followed by `match.join`: the two-step version
races, and two clients reading the same empty listing will each create a match.
This resolves server-side and is serialized, so simultaneous callers converge on
one match.

Subject to the same join rate limit as `match.join` and `world.join`, and to a
node-wide cap on live matches (`asobi.match_max`, default 1000), which answers
`match_capacity_reached`. A world mode is refused with `wrong_mode_type`.

### `match.join`

Join a match (after being matched via matchmaker, discovered via
`match.list`, or a direct invite).

```json
{"type": "match.join", "payload": {"match_id": "..."}}
```

Joining is WebSocket-only by design: the join binds the match to your
session so subsequent `match.input` is routed. There is no REST join, the
same as for worlds.

A `running` match takes joins exactly as a `waiting` one does, so this is also
how a player backfills into a game already in progress. There is no separate
backfill call.

#### `match.joined` (reply)

The full match info, including the roster:

```json
{"type": "match.joined", "cid": "j-1", "payload": {"match_id": "...", "mode": "arena", "status": "waiting", "player_count": 1, "max_players": 4, "players": ["..."], "listed": false, "joinable": true}}
```

| Reason | Code | Means |
|---|---|---|
| `match_not_found` | `match.not_found` | No live match with that id |
| `join_rate_limited` | `join_rate_limited` | Over 10 joins per 60 seconds |
| `match_full` | `match.full` | No room. May free a slot on the next leave |
| `match_locked` | `match.locked` | The game closed the match to new players |
| `join_refused` | `match.join_refused` | The game turned this player away |

`join_refused` carries the game's own reason string in
`error.details.refused_reason` when the script gave one. It is game
vocabulary, never an asobi code - see
[Refusing a join](https://asobi.dev/docs/lua/api#join-player_id-state-or-join-player_id-state-ctx).

```json
{"type": "error", "cid": "j-1", "payload": {"reason": "join_refused", "error": {"code": "match.join_refused", "message": "The game refused this join. See `details.refused_reason`.", "details": {"refused_reason": "wrong_code"}}}}
```

#### Join context

Both `match.join` and `world.join` accept an optional `ctx`, passed through
to your game module untouched:

```json
{"type": "match.join", "payload": {"match_id": "...", "ctx": {"code": "AB12"}}}
```

Asobi never interprets, echoes, or logs it. It reaches your game's join
callback, which decides whether to accept.

In Lua, declare a third parameter:

```lua
function join(player_id, state, ctx)
	if ctx.code ~= state.room_code then
		return state              -- refuse: player is not added
	end
	state.players[player_id] = true
	return state
end
```

In Erlang, export `join/3` (`join(PlayerId, Ctx, GameState)`) alongside or
instead of `join/2`.

Either way a game that takes only `(player_id, state)` is unaffected and a
supplied `ctx` is ignored.

This is how you build join codes, invites, passwords and party checks:
without it there is no channel from a client to your game before
membership exists, so `join/2` can implement an allowlist but never a code.

Bounded at the server: a flat object, at most 8 keys, keys up to 64 bytes,
string values up to 256 bytes, plus integers and booleans. No nesting.
Violations are rejected with `invalid_join_ctx`, `invalid_join_ctx_key`,
`join_ctx_too_many_keys`, `join_ctx_key_too_long`, `join_ctx_value_too_long`,
or `invalid_join_ctx_value`. None of the six has a code of its own, so each
arrives as `ws.request_failed` with the reason in `details` - see
[error](#error-server-push).

**A join context does not make a world private.** Only a game that
implements `join/3` and rejects unauthorised joins restricts entry; a game
that ignores it stays open to anyone holding a `world_id`.

### `match.input`

Send game input to the match server.

```json
{"type": "match.input", "payload": {"action": "move", "x": 10, "y": 5}}
```

As with [`world.input`](#world-input), the `payload` IS the input map. Two
**deprecated** compatibility shapes survive here and will go at the next
protocol break: a payload whose only key is `data` mapped to an object is
unwrapped to that object, and one whose only key is `data` mapped to a JSON
*string* is decoded and unwrapped. A malformed string, a decoded value that is
not an object, or a `payload` that is not an object at all is answered with
`error`, reason `invalid_payload`.

When the connection is in a world rather than a match, `match.input` is routed
to your zone, so the two frames reach the same `handle_input/3`.

Input sent while not in a match or world is dropped. The first drop (at
most one per 5 seconds per connection) is answered with an error event so
the client can tell input is going nowhere:

```json
{"type": "error", "payload": {"type": "match.input", "reason": "not_in_match", "error": {"code": "match.not_in_match", "message": "This connection is not joined to a match.", "details": {}}}}
```

### `error` (server push)

Every failure on this socket is an `error` frame, carrying the `cid` of the
request that caused it when there was one:

```json
{"type": "error", "cid": "c-17", "payload": {"reason": "world_not_found", "error": {"code": "world.not_found", "message": "No live world exists with this id.", "details": {}}}}
```

- `error.code` is the contract - stable, machine-readable, and namespaced by
  domain (`match.`, `world.`, `chat.`, `dm.`, `matchmaker.`, `rpc.`, `ws.`) or
  bare when it is cross-cutting (`rate_limited`, `join_rate_limited`,
  `unauthenticated`, `forbidden`, `payload_too_large`, `invalid_json`,
  `invalid_message`, `invalid_payload`, `missing_field`, `unknown_type`,
  `internal`). Branch on this. Codes come from the same closed set the
  [REST API](https://asobi.dev/docs/protocols/rest#errors) uses.
- The two surfaces agree only where a failure has a first-class code. A
  WebSocket reason that has one carries it, so `world_not_found` here and a
  404 on `GET /api/v1/worlds/:id` are both `world.not_found`. Everything else
  arrives as `ws.request_failed` with the reason in `details`, including
  several common failures. On this page that covers the world capacity pair
  (`world_capacity_reached`, `player_world_limit_reached`, which REST answers
  as `world.capacity_reached` and `world.player_limit_reached`) and every
  join-context rejection listed under [Join context](#match-join). Match a
  reason string on `details.reason` for those, not a code.
- `error.message` is prose for a human reading a log. Do not parse it.
- `error.details` is **always** an object, `{}` when there is nothing to add.
- `reason` is the original, flatter dialect. It is unchanged and still sent, so
  existing clients keep working, but it is not namespaced and two unrelated
  failures can share a string. Prefer `error.code`.

A reason with no code of its own yet - including anything a Lua game script
returns from a rejected join - arrives as `ws.request_failed` with the raw
string in `details`, so script-supplied text can never mint a code:

```json
{"type": "error", "payload": {"reason": "party_is_full", "error": {"code": "ws.request_failed", "message": "The request failed. See `details.reason`.", "details": {"reason": "party_is_full"}}}}
```

### `module.error` (server push)

An extension callback error, sent to the player whose input triggered it.
Only emitted when the extension runs with dev errors enabled (for asobi's
Lua runtime, `ASOBI_DEV_ERRORS=true` or `{asobi_lua, [{dev_errors, true}]}`);
production runtimes keep script errors server-side.

`module` names the extension that produced the error. It is the only field
asobi owns; the rest of the payload is the extension's.

```json
{"type": "module.error", "payload": {"module": "lua", "callback": "handle_input", "script": "match.lua", "message": "bad arithmetic + on nil, 1"}}
```

### `module.message` (server push)

A message addressed to one player by an extension - in Lua,
`game.send(player_id, message)`. The message is wrapped rather than sent
raw, because it may be any scripting value (string, number, table).

```json
{"type": "module.message", "payload": {"module": "lua", "message": "you are player 3"}}
```

### `module.event` (server push)

A named, routable event an extension pushes to a player from its own Erlang
code with `asobi_extensions:emit/4`. Unlike `module.message` (an unnamed dev
message) this frame carries a routing key clients dispatch on. It is emitted as
a single frame with no legacy alias.

`module` is the emitter's registered short name. `event` is `<domain>.<name>`,
where `domain` is an RPC prefix the extension owns. `data` is always an object.

`module` may legitimately differ from the `event` domain, because an extension
can own an RPC prefix that is not its own name - so a consumer should key off
whichever of the two it actually means, deliberately.

```json
{"type": "module.event", "payload": {"module": "quests", "event": "quests.completed", "data": {"quest_id": "01j8x000000000000000000042", "reward": 250}}}
```

### `game.error` / `game.message` (server push, deprecated)

The pre-rename names for the two frames above. Deprecated. **New SDK code
dispatches on `module.error` and `module.message`.** The pair is removed
at the 1.0 wire break and will not be replaced.

They are still emitted, byte-identical payload and same reply as their
`module.*` twin, so every SDK built before the rename keeps working with
no change. Each message therefore produces two frames today: the legacy
frame first, then the `module.*` frame.

Do not dispatch on both - a client that handles `game.message` and
`module.message` processes every message twice.

Neither name was ever Lua-specific: both frames are produced by
extensions in general, which is why the producer travels in the payload's
`module` key. Clients that care which extension spoke read
`payload.module` and treat a missing value as `"lua"`. `game.*` put one
extension in the wire type, where no second extension could reuse it -
that is what the rename fixes.

**Wire history.** `module.*` did not exist on the wire in any release
before this change: not in v0.54.0, and not in v0.53.0, where commit
`a6bc2eb` says otherwise. That commit's message describes a dual-emit
that its own follow-up commit in the same pull request removed, because
Nova could not send two frames from one reply at the time
(novaframework/nova#400). Every release up to v0.54.0 emits `game.error`
and `game.message` only.

**Turning the legacy pair off.** Set `asobi.ws_legacy_game_frames` to
`false` to emit only `module.*`. `game.message` is `game.send/2`, which a
script may call per player per tick, so on a chatty game the compat frame
doubles asobi's hottest extension-produced egress. Any client still
dispatching on `game.*` goes silent when you do this, so flip it only
once every client on the deployment reads `module.*`. It defaults to
`true` and becomes a no-op at 1.0.

### `match.state` (server push)

Server broadcasts game state updates to all players in the match.

```json
{"type": "match.state", "payload": {"players": {...}, "tick": 42}}
```

There is no "match started" frame. The match server notifies its players on
`finished` and on nothing else, so a client learns the match began from
`match.matched` (matchmaker) or `match.joined` (its own join reply), and
then from the first `match.state`.

### `match.finished` (server push)

Notification that a match has ended with results.

```json
{"type": "match.finished", "payload": {"match_id": "...", "result": {...}}}
```

`result` is whatever your game returned with `{finished, Result, State}`;
asobi does not interpret it, with one exception. It reads `winners` (a list
of player ids) or `winner` (one id), and `losers` / `loser`, to move the
`wins` and `losses` columns in `player_stats`. `games_played` moves for
every player in the match either way. Declare winners without losers and
every other player in the match takes the loss; declare `losers: []` to
score a co-op run where nobody loses. `rating` and `rating_deviation` are
not maintained by asobi.

### `match.leave`

Leave the current match.

```json
{"type": "match.leave", "payload": {}}
```

#### `match.left` (reply)

```json
{"type": "match.left", "cid": "l-1", "payload": {"success": true}}
```

Sent whether or not the connection was in a match, so leaving is safe to
call unconditionally on teardown.

## Matchmaking

The queue is per node. A ticket lives in the matchmaker process on the node
that accepted it, there is no ticket table, and the matcher only ever sees
that node's tickets. Two players who queue for the same mode against
different nodes therefore never match each other, and a ticket id is
meaningless on any other node. A cluster needs every matchmaker call from
one player pinned to one node, and matchmaking only works at all if the
whole population lands on one node or the fleet is deliberately partitioned
by mode.

World and match discovery and join are **not** subject to this. They resolve
through a cluster-wide process registry rather than the matchmaker's own
state, so `world.list`, `match.list`, `world.join` and `match.join` reach a
world or match on any node. See [Clustering](https://asobi.dev/docs/clustering).

### `matchmaker.add`

Submit a matchmaking ticket.

```json
{"type": "matchmaker.add", "payload": {"mode": "arena", "properties": {"skill": 1200}}}
```

#### `matchmaker.queued` (reply)

```json
{"type": "matchmaker.queued", "cid": "q-1", "payload": {"ticket_id": "...", "status": "pending", "players_needed": 4, "already_queued": false}}
```

`players_needed` is the mode's configured `match_size`, or `null` when the
mode declares none. How many others are already waiting is deliberately not
reported.

A mode that resolves to no game module is `unknown_mode`
(`matchmaker.unknown_mode`); a full queue is `queue_full`
(`matchmaker.queue_full`). Re-adding for a mode you already have an open
ticket for returns that same ticket rather than a second one, and sets
`already_queued` to `true`.

`already_queued` exists so a reconnecting client can tell "my resubmit was
absorbed, my original wait still stands" from "freshly queued". Keep the
elapsed timer running on `true` - `max_wait_seconds` counts from the ticket's
original submission, not from the resubmit.

### `matchmaker.remove`

Cancel a matchmaking ticket.

```json
{"type": "matchmaker.remove", "payload": {"ticket_id": "..."}}
```

#### `matchmaker.removed` (reply)

```json
{"type": "matchmaker.removed", "cid": "r-1", "payload": {"success": true}}
```

Another player's ticket is `not_owner` (`forbidden`). An unknown ticket is
`not_found`, which has no code of its own and arrives as `ws.request_failed`.
A ticket issued by another node reads as unknown here.

### `match.matched` (server push)

Notification that the matchmaker paired you into a match. The join is
already done: the matchmaker joins every paired player before sending this,
so no `match.join` follows.

```json
{"type": "match.matched", "payload": {"match_id": "...", "players": ["...", "..."]}}
```

A mode whose matches are backed by a **world** rather than a match server
sends a different payload on the same frame: `match_id` holds the world id,
`mode` is present, and the roster is under `player_ids` rather than
`players`. Read both keys if your game has any world-backed mode.

Distinct from `match.joined`, which is the reply to a client-initiated
`match.join`. Both mean "you are in a match and `match.state` will follow",
but only `match.matched` arrives unprompted and without a `cid`.

### `match.matchmaker_expired` (server push)

Your ticket waited longer than `matchmaker.max_wait_seconds` (default 60)
without being matched. It is gone; submit a new one to keep queuing.

```json
{"type": "match.matchmaker_expired", "payload": {"ticket_id": "..."}}
```

### `match.matchmaker_failed` (server push)

A group formed but the match could not be started, so everyone in it is back
out of the queue. `reason` is `match_start_failed` or `no_game_module`.

```json
{"type": "match.matchmaker_failed", "payload": {"reason": "match_start_failed"}}
```

## Worlds

The world server runs persistent shared spaces with zoned interest
management. See [World server](https://asobi.dev/docs/world-server) for the model and
[Large worlds](https://hexdocs.pm/asobi/large-worlds.html) for tuning.

### `world.list`

List running worlds. Optional filters: `mode` (string, up to 64 bytes) and
`has_capacity` (bool - only worlds that are not full). A filter of the wrong
type is rejected with `invalid_mode_filter` or `invalid_has_capacity_filter`
rather than silently dropped.

```json
{"type": "world.list", "payload": {"mode": "walkers", "has_capacity": true}}
```

Response:

```json
{"type": "world.list", "payload": {"worlds": [{"world_id": "...", "mode": "walkers", "player_count": 1, "max_players": 8}]}}
```

### `world.create`

Create a new world for the given mode. Refuses with
`world_capacity_reached` (global cap hit) or `player_world_limit_reached`
(per-player cap hit). Neither reason has a code of its own on this socket:
both arrive as `ws.request_failed` with the reason in `details`, unlike
`POST /api/v1/worlds`, which answers `world.capacity_reached` (503) and
`world.player_limit_reached` (429). On success the caller is auto-joined and
the reply is `world.joined`.

```json
{"type": "world.create", "payload": {"mode": "walkers"}}
```

### `world.find_or_create`

Atomic find-or-create: returns the first non-full world for the mode,
or creates one if none exists. The caller is auto-joined. **This is the
right call for "drop me into a shared room" flows.**

```json
{"type": "world.find_or_create", "payload": {"mode": "walkers"}}
```

### `world.join`

Join a specific world by id (e.g. one returned from `world.list`).

```json
{"type": "world.join", "payload": {"world_id": "..."}}
```

### `world.input`

Send game input to your zone. The `payload` IS the input map; the server
forwards it verbatim to your `handle_input/3` callback and field names are
entirely up to your game.

One **deprecated** compatibility shape survives: a payload whose *only* key is
`data`, mapped to an object, is unwrapped to that object. It exists for clients
that predate this rule and will be removed at the next protocol break; do not
send it. A `data` key alongside any other key is not special, and neither is a
`data` whose value is not an object - both reach `handle_input/3` untouched,
with the rest of the payload intact.

A `payload` that is not an object at all is rejected with an `error` frame,
reason `invalid_payload`. It is not silently treated as empty input.

For client-side prediction, add an optional `seq` *alongside* `payload` (a
sibling, so "the payload IS the input map" stays true). The server echoes the
highest consumed `seq` back as a [`world.ack`](#world-ack-server-push); see
[Client-side prediction](#client-side-prediction). A `seq` that is not a
non-negative integer below 2^53 is ignored.

```json
{"type": "world.input", "seq": 412, "payload": {"kind": "move", "x": 600, "y": 480}}
```

The server routes the message to whichever zone owns your player
entity - clients do not specify zone coordinates. Input sent while not in a
zone is dropped with no reply at all.

### `world.leave`

Leave the current world.

```json
{"type": "world.leave", "payload": {}}
```

### `world.joined` (server push)

Sent in response to a successful `world.create`, `world.find_or_create`,
or `world.join`. The `payload` is the full world info (mode, world_id,
player_count, grid_size, max_players, …).

```json
{"type": "world.joined", "payload": {"world_id": "...", "mode": "walkers", "grid_size": 1, "max_players": 8, "player_count": 1, "status": "running"}}
```

### `world.tick` (server push)

Per-zone delta broadcast. The first `world.tick` after `world.joined` is
the **initial snapshot** for every entity in the zone - register your
handler before sending the join message or you miss it.

```json
{"type": "world.tick", "payload": {"zone": [3, 5], "frame_seq": 118, "kf": false, "tick": 42, "updates": [{"op": "a", "id": "01HX...", "x": 600, "y": 480, "type": "player"}]}}
```

`updates` is a list of entity deltas. `op` values:

| `op` | Meaning | Fields |
|------|---------|--------|
| `"a"` | Added, full state | id + every field on the entity |
| `"u"` | Updated, diff | id + only changed fields |
| `"r"` | Removed | id only |

#### Apply per zone, and check the sequence

| Field | Meaning |
|-------|---------|
| `zone` | The zone these updates belong to, as `[x, y]`. |
| `frame_seq` | Contiguous per zone, advancing only on a frame actually sent. |
| `kf` | `true` on a keyframe: a complete baseline for that zone, all `op: "a"`. |

**Keep one entity table per zone, keyed by `zone`, never one flat table.** You
are subscribed to an interest ring of several zones at once, each an independent
process, and messages are ordered per sender only. Crossing a boundary emits an
`op: "r"` from the zone you left and an `op: "a"` from the zone you entered, from
two different senders, so they can reach you in either order. Applied into one
flat table, the removal can land last and delete an entity you will never hear
about again. Per-zone tables make that unreachable.

**`frame_seq` is how you detect loss.** It has no gaps by construction, so a
frame whose sequence is more than one past the last you applied for that zone
means you missed something; a frame at or below it is stale and should be
dropped. `tick` cannot do this job - it skips on `broadcast_interval` and is
suppressed on a quiet tick, so a gap in it is ambiguous.

Two frames are applied **ungated**, without the sequence check:

- `kf: true`, which resets your high-water mark to the value it carries. That is
  what makes a zone restart recoverable.
- A frame with no `frame_seq` at all, which is the removal list you get for the
  zone you are leaving. Gating it would leave you holding ghosts forever.

On a gap, send [`world.resync`](#world-resync) for that zone and you get a fresh
keyframe.

### Binary `world.tick`

A client that negotiated `"wire": "binary"` at
[`session.connect`](#session-connect) receives `world.tick` as a **WebSocket
binary frame** carrying the same information in about a quarter of the bytes, and
materially cheaper to decode: measured against native JSON, 2.4x faster in
Godot's GDScript and 33x faster than the pure-Lua parser Defold and LOVE ship.
Every other message type still arrives as JSON text.

All multi-byte integers and floats are **little-endian**. That is not the usual
choice for a wire format, and it is deliberate: Godot's
`PackedByteArray.decode_*` reads little-endian and has no big-endian counterpart,
so network byte order would force a hand-rolled byte loop in interpreted
GDScript - and those native calls are exactly why the codec beats JSON there
rather than losing to it. Every other target reads either order for the same
price, so the runtime with no room to spare picks.

```
frame    Kind:8, ZX:32/signed, ZY:32/signed, FrameSeq:64, Kf:8, Tick:64,
         DictLen:8, Dict, RecCount:16, Records

dict     for each name: Len:8, Name/binary            (at most 32 names)
record   Op:8, Slot:16, [IdLen:8, Id/binary]?, FieldCount:8, Fields
field    Type:3, Idx:5, Value                         (one header byte)
```

`Kind` is `1` for a frame holding a position in the zone's sequence and `2` for
one that does not - the binary equivalent of the text wire omitting `frame_seq`.
A `2` frame is the leave-removal list, and it is applied ungated.

`Op` is `0` add, `1` update, `2` remove. `Type` selects the value encoding:

| `Type` | Value |
|--------|-------|
| 0 | `float32` |
| 1 | `int32`, signed |
| 2 | `true`, no bytes follow |
| 3 | `false`, no bytes follow |
| 4 | `Len:16, UTF-8 bytes` |
| 5 | `null`, no bytes follow |

`Idx` indexes the frame's own dictionary, so forty records all carrying
`x, y, vx, vy` pay for four names rather than a hundred and sixty. The frame is
self-describing: nothing is negotiated up front and nothing survives a
reconnect.

**Five bits of index means a frame carries at most 32 distinct field names**, and
this is a budget worth knowing before you hit it. It is counted across the whole
frame, not per entity, but one entity is what usually spends it: a delta names
only the fields that changed, while the `add` that introduces an entity names all
of them. An entity with 33 fields therefore cannot ride this wire at all.

A frame past the budget is sent as text instead. That is safe for the frame and
not safe on its own for what follows: **a text add carries no slot**, so the
entities it introduced are not in your table, and the next binary frame names
them in `op:"u"` records you have to drop - with a contiguous `frame_seq` that
gives you no reason to resync.

So the server repairs it rather than leaving it to you. The frame after a refused
one is a **keyframe** - `kf: true`, all adds - which re-establishes every binding.
Nothing is required of a client that already applies keyframes the way this guide
describes. If that keyframe is refused too, the cause is the shape of the game's
entities rather than one frame, and the zone gives the binary wire up: every
client on it falls back to text, which carries everything, and the datagram
plane switches off with it. The zone asks again later on a doubling backoff -
a minute, then two, up to an hour - so an entity that was briefly unencodable
costs a pause rather than the rest of the zone's life. A successful retry is
itself a keyframe, so every client is rebound by it.

Both outcomes are visible server-side, and neither is silent on the client's
behalf. If a game seems to be missing the datagram plane, count the fields on its
widest entity and look for `binary world.tick frame refused` or
`binary wire disabled for this zone` in the server log; both name the zone, the
distinct-name count and the widest entity.

**Entities are 2-byte slots, and the slot is scoped to the zone.** A record
carries the full entity id on an **add only**, which is where the binding is
established; update and remove carry the slot and generation alone.

`Gen` advances every time a slot is rebound to a different entity. On this wire it
is redundant, because the stream is ordered and reliable and `frame_seq` already
bounds the reuse hazard, and it is carried anyway so that a client also running
the datagram plane can keep one slot table for both carriers rather than two that
can disagree. If you are only on the WebSocket you can ignore it. Keep a slot-to-id table per
zone - slot 5 in one zone has nothing to do with slot 5 in another - and let an
add REPLACE any binding already there, because a freed slot is eventually
reused. There is no mapping message and none is needed: a keyframe is all-adds,
so `world.resync` re-establishes every binding for you.

The binary wire is also what the [datagram plane](https://hexdocs.pm/asobi/datagram-plane.html) builds on:
its `pose` frames carry slots, and the bindings come from the `add` records here.

A committed fixture corpus lives in `priv/wire_fixtures/` - one `.bin` per case
plus a `manifest.json` saying what each decodes to. Test your decoder against
it; the server's own CI asserts those bytes are still what it produces.

### Client-side prediction

asobi is server-authoritative, and server-side rollback, replay and lag
compensation are out of scope (TCP transport - see
[migrate-from-hathora](https://hexdocs.pm/asobi/migrate-from-hathora.html)). The server half that
*client-side* prediction needs - an ack telling a client which of its inputs the
authoritative state already includes - is a first-class primitive:

1. The client stamps each `world.input` with its own increasing `seq` (a sibling
   of `payload`) and applies the input locally right away (the prediction).
2. The server records the highest `seq` it consumed for that player - a rejected
   input still counts, so a dropped input never strands the client - and sends it
   back on the next broadcast as a [`world.ack`](#world-ack-server-push)
   addressed to that connection alone.
3. The client discards every predicted input up to that `seq` and replays the
   rest on top of the authoritative `world.tick` state (the reconciliation).

Set [`broadcast_interval`](https://asobi.dev/docs/world-server) to 1 so the ack returns every tick.

The ack is addressed to one connection and never rides the shared `world.tick`,
so one player's input stream is never broadcast to the rest of the zone. It is
sent to clients that opted in by stamping a `seq`, and to clients whose game
module reports a consumed seq for them - see
[Batched input and the ack](#client-side-prediction), where numbering the
steps inside the payload replaces stamping the frame.

**`seq` never goes backwards on a connection.** The high-water mark is recorded
per zone, and a player is subscribed to their whole interest ring, so during a
crossing more than one zone can hold a mark for them. The connection drops any
ack that does not advance the highest `seq` it has already sent you, so you can
prune against the value you receive without tracking a maximum yourself.

#### Batched input and the ack

Step 2 says "the highest `seq` it consumed", and by default that is the `seq`
stamped on the frame: one input frame, one input, nothing to disagree about.

A client predicting faster than the zone ticks changes that. At 60 Hz against a
12.5 Hz zone there are roughly five simulation steps per tick, so a frame
carries a *batch* of steps rather than one, and a zone that caps how many steps
it runs per tick parks the rest for the next one. The frame stamp then no longer
describes what ran:

- Stamp the frame with the **last** seq in the batch and the ack overclaims
  whenever steps are parked. The client discards predicted steps the server has
  not applied yet, cannot replay them, and drifts until something resyncs it.
- Stamp it with the **first** seq and the ack underclaims. The client replays
  steps the server already applied and overshoots on every reconciliation.

Return the seq you actually consumed and the ack carries that instead:

```erlang
handle_input(PlayerId, #{~"steps" := Steps}, Entities) ->
    {Entities1, Watermark} = apply_steps(PlayerId, Steps, Entities),
    {ok, Entities1, Watermark}.
```

```lua
function handle_input(player_id, input, entities)
  local watermark = apply_steps(input.steps, entities)
  return entities, watermark
end
```

The number is in your client's own sequence space - the same numbering the steps
inside the payload carry - and must be a non-negative integer no larger than
2^53-1, the same bound the client-stamped `seq` is held to. Anything else is
refused with a warning and the frame stamp is used instead: the value is echoed
to your client on every broadcast tick, so a wider one would be an encode
amplifier and unreadable to any SDK holding it in an int64. The rules that come
with it:

- **Report on every input or on none.** Within a tick a report always beats a
  frame stamp, whatever order they arrive in. Across ticks it does not: a tick
  in which you reported nothing records the frame stamp instead, and the ack
  keeps the highest value it has recorded, so one unreported tick pins the ack
  above your watermark for good.
- **Reporting acks a client that never stamped a `seq`.** If your client numbers
  its steps inside the payload it never needs to stamp the frame at all. SDK
  authors: this means `world.ack` can arrive unsolicited, so a client that never
  opted in must drop it silently rather than log or raise per frame.
- **Draining parked steps in `zone_tick` has no report channel.** The watermark
  rides out on the next input you handle, which a client re-sending
  unacknowledged steps produces every tick - so it costs a tick, except for a
  player at rest, whose final drain stays unacked until they move.
- **`{error, Reason}` still acks the frame stamp**, because a client must never
  wait forever on an input the server chose to drop - unless a report already
  landed this tick, which outranks it. Refusing one input does not unrun the
  steps another already consumed. A game that parks should model refusal as
  `{ok, Entities, Watermark}` instead.
- **Deduplicate by the same watermark.** A client that re-sends unacknowledged
  steps for redundancy (what makes an unreliable carrier safe) will hand you
  steps you have already run; skip them, and report the watermark either way.

**If your SDK does not yet surface `world.ack`**, the same reconciliation works
in userland: write the `seq` onto the player's entity in `handle_input/3`
(`entity.last_seq = input.seq`) and read it back off the `world.tick` delta. The
tradeoff is that `last_seq` then sits on the shared entity delta, so it reaches
every subscriber in the zone - its bandwidth scales with zone population, which
is exactly what the `world.ack` frame avoids.

### `world.ack` (server push)

Acknowledgement of the highest `world.input` `seq` the server has consumed for
you as of `tick`, and monotonic for the life of the connection. Addressed to your
connection alone, and sent only to clients that stamped a `seq` on their input;
use it to reconcile prediction (above).

```json
{"type": "world.ack", "payload": {"tick": 42, "seq": 412}}
```

### `world.resync`

Ask one zone to re-send its baseline, after a `frame_seq` gap tells you a frame
went missing.

```json
{"type": "world.resync", "payload": {"zone": [3, 5]}}
```

There is no reply of its own. The answer is a `world.tick` with `kf: true` for
that zone, holding every entity as an `op: "a"` - so on the binary wire it also
re-establishes every slot binding.

A request naming a zone you are not subscribed to is dropped in silence rather
than answered. There is nothing to repair, and answering would turn resync into
a way to read any zone in the world.

Rate limited on two buckets, per player first and then fleet-wide: **2 per 10s
per player** and **20 per second across the server**. A client that needs more
than that is not recovering from loss, it is looping. Tune under
`asobi.rate_limits`, groups `resync` and `resync_global`.

### `world.terrain` (server push)

Sent on zone subscription when the world has a terrain provider. The
chunk data is base64-encoded compressed binary; see
[Large worlds](https://hexdocs.pm/asobi/large-worlds.html) for the encoding.

```json
{"type": "world.terrain", "payload": {"coords": [3, 5], "data": "eJw..."}}
```

### `world.left` (server push)

Confirmation that the leave completed (or that the client was already
out of any world).

```json
{"type": "world.left", "payload": {"success": true}}
```

### `world.finished` (server push)

The world ended (e.g. last player left and the empty grace expired, or
the game module returned `{finished, Result, State}` from `post_tick`).

```json
{"type": "world.finished", "payload": {"world_id": "...", "result": {}}}
```

### `world.phase_changed` (server push)

Phase state for a world whose mode declares phases. Only worlds emit this;
there is no match equivalent, so a client that wants phases in a match reads
them out of `match.state` or has the script broadcast its own event.

```json
{"type": "world.phase_changed", "payload": {"world_id": "...", "status": "active", "phase": "combat", "remaining_ms": 42000, "config": {}, "timers": {}}}
```

`status` is `waiting`, `active` or `complete`, and it decides which other
fields are present:

| `status` | Fields beside `phase` |
| --- | --- |
| `waiting` | `start_condition` - what the phase is waiting for. |
| `active` | `remaining_ms`, `config` (the phase's own config object) and `timers` (the phase's live timers, keyed by id). |
| `complete` | None. `phase` is `null`. |

The frame is sent on every transition, and again periodically while a phase
runs, so a client must treat it as state rather than as an edge. `world_id`
is present on the transition frame and absent from the periodic one; do not
key off it.

## Chat

Channel ids are namespaced: every id must start with one of these prefixes, and
a `chat.join` whose channel id is missing or unprefixed is rejected with
`invalid_channel_id` (`chat.invalid_channel_id`). The prefix lets the runtime
route the message and enforce membership without a per-frame registry lookup.

| Prefix   | Used for                                  | Membership rule |
|----------|-------------------------------------------|-----------------|
| `dm:`    | Direct messages                           | The two named participants only. |
| `global:`| Game-wide chat, spans every world         | Any signed-in player, for a name the operator declared. |
| `world:` | World-wide chat                           | Players currently joined to the world. |
| `zone:`  | A specific zone within a world            | Players currently joined to the world. |
| `prox:`  | Proximity chat (radius around a position) | Players currently joined to the world. |
| `room:`  | App-defined group chat                    | Members of the group whose id is the part of the channel id after `room:`. Not open-join. |

`global:<name>` is the only scheme that outlives a single world, so it is the
one to use for "everyone in the game". A client cannot mint one: the name must
appear in the `chat => #{global => [...]}` of a configured game mode, otherwise
the join is rejected like any other unauthorised channel. Names are up to 64
bytes of `a-z A-Z 0-9 _ - .`. Players in a world whose mode declares a global
channel are joined to it automatically on `world.join` and left on
`world.leave`, exactly as with `world:` - see the
[World Server](https://asobi.dev/docs/world-server#chat-channels) guide.

There is no open-join room policy and no `match:` scheme. `room:` is authorised
as a group membership check: the runtime strips the `room:` prefix and looks up
the remainder as a group id, so `room:<group_id>` authorises exactly the members
of `<group_id>`, not members of a group literally named `"room:<group_id>"`. For
pre-game lobby chat, gate on world membership with `world:<world_id>`, or use
`game.broadcast`; see the [Lobbies](https://hexdocs.pm/asobi/lobbies.html) guide.

For a group created with `open=true`, anyone can join without an invite
(`POST /api/v1/groups/:id/join` never rejects with `group_closed`). Membership
is still required to read `room:<group_id>` - joining is what's unrestricted,
not reading. Once joined, a member sees the group's full retained history (up
to the last 200 messages, per the `history` limit below), including messages
sent before they joined. This is intentional and matches how public channels
work in Slack/Discord: it is not a bug or a cutoff to add later.

The worked examples below use a `world:` channel, which authorises on world
membership you already hold after `world.join`.

A single connection may join at most **32 channels** at once; a 33rd is rejected
with `too_many_channels` (`chat.too_many_channels`). Idle channels with no
members stop after 60s; rejoining is cheap.

`chat.send` never answers with a size error. Content over 2000 bytes, and
content that is not a string, is dropped with no reply at all, and empty
content is accepted and broadcast. A client that needs either rejected has to
check before sending. The only failure `chat.send` reports is `not_authorized`
(`forbidden`), for a malformed channel id or a channel this player may not
write to. `content_empty` and `content_too_large` are direct-message codes -
see [Direct messages](#direct-messages).

History (`GET /api/v1/chat/:channel_id/history`) requires membership; `?limit`
defaults to 50 and clamps to 1-200, and a non-member gets `403`.

### `chat.join`

Join a chat channel. The channel id must be namespaced.

```json
{"type": "chat.join", "payload": {"channel_id": "world:w_ancient_ruins"}}
```

#### `chat.joined` (reply)

```json
{"type": "chat.joined", "cid": "c-1", "payload": {"channel_id": "world:w_ancient_ruins"}}
```

A malformed id is `invalid_channel_id` (`chat.invalid_channel_id`); a channel
this player is not authorised for is `not_authorized` (`forbidden`).

Joining does not replay history. Fetch it from
`GET /api/v1/chat/:channel_id/history`.

### `chat.send`

Send a message to a channel.

```json
{"type": "chat.send", "payload": {"channel_id": "world:w_ancient_ruins", "content": "Hello!"}}
```

### `chat.message` (server push)

A new message in a joined channel.

```json
{
  "type": "chat.message",
  "payload": {
    "channel_id": "world:w_ancient_ruins",
    "sender_id": "...",
    "content": "Hello!",
    "sent_at": 1785312000000
  }
}
```

`sent_at` is Unix milliseconds, not an ISO string. The same field on the
persisted history read is a timestamp column, so the two differ.

### `chat.leave`

Leave a chat channel.

```json
{"type": "chat.leave", "payload": {"channel_id": "world:w_ancient_ruins"}}
```

#### `chat.left` (reply)

```json
{"type": "chat.left", "cid": "c-2", "payload": {"channel_id": "world:w_ancient_ruins"}}
```

Sent whether or not the connection had joined that channel.

## Direct messages

A DM is a chat message on a `dm:` channel whose id is both player ids sorted
and joined with colons, so both sides always name the same channel. The
sender gets a reply carrying that id; the recipient gets a `dm.message`
push. Both sides read history from `GET /api/v1/dm/:player_id/history`.

### `dm.send`

```json
{"type": "dm.send", "cid": "d-1", "payload": {"recipient_id": "...", "content": "Hello!"}}
```

#### `dm.sent` (reply)

```json
{"type": "dm.sent", "cid": "d-1", "payload": {"channel_id": "dm:0197...:0198..."}}
```

| Reason | Code | Cause |
| --- | --- | --- |
| `content_empty` | `dm.content_empty` | `content` was the empty string. |
| `content_too_large` | `dm.content_too_large` | `content` was over 2000 bytes. |
| `blocked` | `dm.blocked` | The recipient has blocked the sender. |
| `invalid_input` | `ws.request_failed` | `recipient_id` or `content` was not a string. |

Unlike `chat.send`, these are real error frames: a DM that is too long or
empty is refused rather than dropped.

### `dm.message` (server push)

Addressed to the recipient's session, not to the channel. The sender's own
confirmation is the `dm.sent` reply.

```json
{"type": "dm.message", "payload": {"channel_id": "dm:0197...:0198...", "sender_id": "...", "content": "Hello!", "sent_at": 1785312000000}}
```

A recipient who is offline gets no push; the message is persisted either way
and appears in history when they return.

A connection that has also `chat.join`ed the `dm:` channel additionally
receives the message as a `chat.message` on that channel. Handle one or the
other, or a client that does both shows every DM twice.

## Voting

### `vote.cast`

Cast a vote in an active match vote.

```json
{"type": "vote.cast", "cid": "v1", "payload": {"vote_id": "...", "option_id": "jungle"}}
```

For approval voting, `option_id` is a list:

```json
{"type": "vote.cast", "payload": {"vote_id": "...", "option_id": ["jungle", "caves"]}}
```

#### `vote.cast_ok` (reply)

```json
{"type": "vote.cast_ok", "cid": "v1", "payload": {"success": true}}
```

Casting while not in a match is `not_in_match` (`match.not_in_match`), and
changing your vote more times than the vote's `max_revotes` allows (3 by
default) is `rate_limited`. The refusals that come from the vote itself -
`vote_not_found`, `vote_closed`, `not_eligible`, `invalid_option` - have no
code of their own and arrive as `ws.request_failed` with the reason in
`details`. A vote in a world that has not finished loading is
`world_not_ready`, carried the same way.

### `vote.veto`

Use a veto token to cancel the current vote. Requires `veto_tokens_per_player > 0`
in match config and `veto_enabled` on the vote.

```json
{"type": "vote.veto", "payload": {"vote_id": "..."}}
```

#### `vote.veto_ok` (reply)

```json
{"type": "vote.veto_ok", "cid": "v2", "payload": {"success": true}}
```

An unknown vote is `vote_not_found`, a player out of tokens is
`no_veto_tokens`, and a vote that did not enable vetoes is `veto_disabled`.
None of the three has a code of its own either. A veto in a world that has not
finished loading is `world_not_ready`, carried the same way.

### `match.vote_start` (server push)

A new vote has started.

```json
{
  "type": "match.vote_start",
  "payload": {
    "vote_id": "...",
    "options": [{"id": "jungle", "label": "Jungle Path"}, {"id": "volcano", "label": "Volcano Path"}],
    "window_ms": 15000,
    "method": "plurality"
  }
}
```

### `match.vote_tally` (server push)

Running tally update (only with `"live"` visibility).

```json
{
  "type": "match.vote_tally",
  "payload": {
    "vote_id": "...",
    "tallies": {"jungle": 2, "volcano": 1},
    "time_remaining_ms": 8432,
    "total_votes": 3
  }
}
```

### `match.vote_result` (server push)

Vote closed, winner determined.

```json
{
  "type": "match.vote_result",
  "payload": {
    "vote_id": "...",
    "winner": "jungle",
    "counts": {"jungle": 2, "volcano": 1},
    "distribution": {"jungle": 0.666, "volcano": 0.333},
    "total_votes": 3,
    "turnout": 1.0
  }
}
```

### `match.vote_vetoed` (server push)

A player vetoed the vote.

```json
{"type": "match.vote_vetoed", "payload": {"vote_id": "...", "vetoed_by": "player_id"}}
```

## Presence

### `presence.update`

Set your own status string. `status` is the only field read; anything else in
the payload is discarded. Omitting it sets `"online"`.

```json
{"type": "presence.update", "cid": "p-1", "payload": {"status": "in_game"}}
```

#### `presence.updated` (reply)

```json
{"type": "presence.updated", "cid": "p-1", "payload": {"status": "in_game"}}
```

The status is not validated against a list, and it is not persisted: it lives
for the length of the session. There is no push telling a client that another
player's presence changed - a client that needs a friends list with live
status polls for it.

## Notifications

### `notification.new` (server push)

A new notification for the player.

```json
{
  "type": "notification.new",
  "payload": {
    "id": "...",
    "type": "friend_request",
    "subject": "New friend request",
    "content": {"from_player_id": "..."}
  }
}
```

## Extension RPC

One frame type reaches every method any installed
[extension](https://hexdocs.pm/asobi/extensions.html) declares, so an extension needs no per-extension
SDK work to be callable from a client.

### `rpc.call`

```json
{
  "type": "rpc.call",
  "cid": "c-1",
  "payload": {"protocol": 1, "method": "quests.claim", "params": {"quest_id": "q-1"}}
}
```

- `cid` is **required** here and validated by the server: 1 to 64 printable
  ASCII bytes. Elsewhere on this socket it is an optional echo; an RPC reply
  is useless without it, because it is the only way to pair a reply with its
  call. A rejected `cid` is not echoed back, so that one reply carries none.
- `protocol` is the RPC payload version, currently `1`. Version the payload
  rather than the frame type, so a server that does not speak your version
  says so instead of answering `unknown_type`.
- `params` is **always** an object, `{}` when the method takes nothing.
- `method` is `<extension>.<name>`. The socket must already be authenticated:
  every declared method is player-scoped, and the player is the one that sent
  `session.connect`.

### `rpc.ok` (reply)

```json
{"type": "rpc.ok", "cid": "c-1", "payload": {"result": {"reward": 100}}}
```

`result` is **always** an object, so a method can grow a field without
breaking a shipped client.

### `rpc.error` (reply)

```json
{"type": "rpc.error", "cid": "c-1", "payload": {"error": {"code": "quests.already_claimed", "message": "This quest was already claimed.", "details": {}}}}
```

The same error object the rest of this socket and the
[REST API](https://asobi.dev/docs/protocols/rest#errors) carry, and only that object - the flatter
`reason` dialect is not repeated on a frame nothing has shipped against.

An extension mints codes in its own domain, so a failure arrives as
`quests.already_claimed` rather than `internal`. The set stays closed: a code
no installed extension declared is answered as `internal` instead of being
reflected back. Codes core itself adds for this surface:

| Code | Meaning |
|---|---|
| `rpc.unknown_method` | No installed extension serves that method |
| `rpc.invalid_cid` | `cid` was missing, not a string, empty, over 64 bytes, or not printable ASCII |
| `rpc.unsupported_protocol` | `details.supported` lists the versions this server speaks |
| `rpc.invalid_params` | `params` was not an object |
| `invalid_payload` | `payload` itself was not an object |
| `unauthenticated` | The socket has not completed `session.connect` |
| `not_ready` | The node is still running migrations. Retry |

### HTTP transport

The same RPC also answers over HTTP, for a client with no open socket:

```
POST /api/v1/rpc/quests.claim
```

- The method is the last path segment, so `quests.claim` here is the method the
  socket names in its payload. The body carries only `params`:

```json
{"params": {"quest_id": "q-1"}}
```

- `protocol` is injected server-side, so an HTTP client never sends it, and
  `rpc.unsupported_protocol` cannot fire here; the version lives in the
  `/api/v1/` path instead.
- There is no `cid`. An HTTP reply is self-correlating - it is the response to
  this one request and nothing else.

The reply is the **same envelope** the socket sends,
`{"type": ..., "payload": ...}`, carrying the same `rpc.ok` or `rpc.error`
below it, plus an HTTP status: `200` for `rpc.ok`, and the error object's own
status otherwise (the status the [REST API](https://asobi.dev/docs/protocols/rest#errors) gives that
code).

```json
200 OK
{"type": "rpc.ok", "payload": {"result": {"reward": 100}}}
```

```json
404 Not Found
{"type": "rpc.error", "payload": {"error": {"code": "rpc.unknown_method", "message": "No installed extension serves this RPC method.", "details": {}}}}
```

Both transports share one envelope below the transport, so a single SDK decoder
reads a reply whether it arrived on the socket or from this endpoint.

## Next steps

- [REST API](https://asobi.dev/docs/protocols/rest) - the request/response surface alongside this socket protocol.
- [Extensions](https://hexdocs.pm/asobi/extensions.html) - declaring the methods `rpc.call` reaches.
- [Authentication](https://asobi.dev/docs/authentication) - obtaining the token the socket authenticates with.
- [Voting](https://asobi.dev/docs/voting) - the vote flow whose `match.vote_*` pushes appear above.
""".
