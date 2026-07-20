%% GENERATED from asobi guides/lobbies.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_lobbies_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-lobbies", title => ~"Lobbies — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Lobbies"
        ]},
        {h1, [], [~"Lobbies"]},
        {raw,
            ~"""
<p>How to gather players before a game starts.</p>
<p>Asobi has no <code>Lobby</code> object. That is a deliberate choice, not a gap - a
lobby is a <em>state</em>, not a type, and asobi already has two things that hold
players before a game begins. This guide is about picking one and wiring it
up, because the pieces are documented separately and the flow is not
obvious from any one of them.</p>
<h2 id="which-one" tabindex="-1">Which one</h2>
<table>
<thead>
<tr>
<th></th>
<th>Waiting match</th>
<th>Persistent world</th>
</tr>
</thead>
<tbody>
<tr>
<td>Use for</td>
<td>gather N players, play, done</td>
<td>a hub people return to between games</td>
</tr>
<tr>
<td>Processes</td>
<td>1</td>
<td>~6 (instance sup, zone sup, zone, ticker, server)</td>
</tr>
<tr>
<td>Ticks while idle</td>
<td>none</td>
<td>yes, at <code>tick_rate</code></td>
</tr>
<tr>
<td>Presence</td>
<td>you broadcast it</td>
<td>free, from the tick loop</td>
</tr>
<tr>
<td>Lifetime</td>
<td>starts at <code>min_players</code>, times out after 60s</td>
<td>survives empty if <code>persistent</code></td>
</tr>
</tbody>
</table>
<p>For &quot;gather four players and start&quot;, use a <strong>waiting match</strong>. A world is a
spatial simulation; running one so people can stand still is the expensive
way round.</p>
<h2 id="waiting-match" tabindex="-1">Waiting match</h2>
<p>A match starts in the <code>waiting</code> state and only transitions to <code>running</code>
when <code>min_players</code> is reached. That waiting period is the lobby.</p>
<pre><code class="language-lua">-- arena.lua
match_size  = 4      -- min_players: the match starts when the 4th player joins
max_players = 4
listed      = true   -- so match.list can find it
</code></pre>
<p>A waiting match holds one process and one 60-second timer. It does not tick
until it starts, so idle lobbies cost close to nothing.</p>
<h3 id="letting-players-find-it" tabindex="-1">Letting players find it</h3>
<pre><code>GET /api/v1/matches/live        REST
match.list                      WebSocket
</code></pre>
<p>Both filter on <code>mode</code> and <code>has_capacity</code>. Matches are <strong>unlisted by
default</strong> - a matchmaker-spawned match is already assigned to its players
and has no reason to be browsable - so a mode opts in with <code>listed = true</code>.</p>
<p>Do not use <code>GET /api/v1/matches</code> for this. It reads the match record table:
finished matches, an audit trail, nothing joinable. See
<a href="/docs/protocols/rest">REST API</a>.</p>
<h3 id="private-lobbies" tabindex="-1">Private lobbies</h3>
<p>Share a code out of band and check it on the way in. The join context is
whatever the client put in the join payload; asobi never reads it.</p>
<pre><code class="language-lua">function join(player_id, state, ctx)
	if ctx.code ~= state.room_code then
		return state                    -- refuse: player is not added
	end
	state.players[player_id] = true
	game.broadcast(&quot;lobby_update&quot;, { players = state.players })
	return state
end
</code></pre>
<p>Combine with <code>listed = false</code> for a lobby that is reachable only by code.
See <a href="/docs/protocols/websocket#join-context">Join context</a>.</p>
<h3 id="telling-the-room-someone-arrived" tabindex="-1">Telling the room someone arrived</h3>
<p>Core does not push a join notification to the players already waiting. That
is deliberate: <code>match.left</code> is a reply to the leaver rather than a
broadcast, so co-member notification is the game's decision throughout, and
what a lobby shows differs per game - a bare count, a full roster, nothing
until it fills.</p>
<p><code>game.broadcast</code> from your join callback is the whole of it, as above. It
reaches every player currently in the match.</p>
<h3 id="chat-in-a-lobby" tabindex="-1">Chat in a lobby</h3>
<p>There is no <code>match:</code> chat channel scheme. <code>world:&lt;WorldId&gt;</code> exists and is
gated on world membership; matches have no equivalent. Use <code>game.broadcast</code>
with your own message shape.</p>
<p>The <code>room:</code> scheme is documented as open-join but is not - it resolves to a
group membership check. See
<a href="https://github.com/widgrensit/asobi/issues/209">asobi#209</a>.</p>
<h3 id="the-60-second-timeout" tabindex="-1">The 60-second timeout</h3>
<p>A match that does not reach <code>min_players</code> within 60 seconds stops itself.
That value is currently fixed (<code>?WAITING_TIMEOUT</code> in <code>asobi_match_server</code>)
and is not exposed per mode. Fine for quick play; too short if you want
players assembling at their own pace.</p>
<h2 id="persistent-world-as-a-hub" tabindex="-1">Persistent world as a hub</h2>
<p>For a town square people return to between games, use a world.</p>
<pre><code class="language-lua">-- hub.lua
game_type   = &quot;world&quot;
persistent  = true    -- stays alive when empty; without this it dies on the last leave
grid_size   = 1       -- one zone: no spatial partitioning needed to stand around
tick_rate   = 200     -- 5 Hz is plenty; the 50ms default is for action games
listed      = true
quick_play  = true    -- world.find_or_create drops everyone into the same one
match_size  = 1
</code></pre>
<p><code>persistent</code> is the flag that makes it a hub rather than a session. Without
it a world finishes the moment the last player leaves, so the next player
gets a fresh empty one.</p>
<p>Presence is free here: worlds tick and broadcast zone state, so players see
each other without you broadcasting anything. <code>world:&lt;WorldId&gt;</code> chat works
and is gated on world membership.</p>
<p>Nothing creates the hub at boot. The first <code>world.find_or_create</code>
instantiates it and it stays up from then on; after a restart the first
player recreates it, restoring snapshots if <code>persistent</code>.</p>
<p>Worlds are subject to <code>world_max_per_player</code> (5) and <code>world_max</code> (1000) -
see <a href="/docs/configuration#world-capacity">World capacity</a>.</p>
<h2 id="not-included" tabindex="-1">Not included</h2>
<ul>
<li><strong>Ready-up.</strong> No first-class ready state. Track it in your own game state
and broadcast it; the join context and <code>game.broadcast</code> are enough.</li>
<li><strong>Party.</strong> You cannot queue as a group through the matchmaker. Play with
specific people by sharing a match id or a join code.</li>
<li><strong>Rich filters.</strong> Discovery filters on <code>mode</code> and <code>has_capacity</code> only.
Anything richer belongs in your strategy module.</li>
<li><strong>Member roster API.</strong> The joiner receives the roster on <code>match.joined</code>;
there is no separate &quot;who is here&quot; call. Keep the list in your game state.</li>
</ul>
"""}
    ]}.
