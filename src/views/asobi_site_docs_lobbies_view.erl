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
<p>asobi has no <code>Lobby</code> object. A lobby is a state, not a type, and asobi already
has two things that hold players before a game begins. This guide is about
picking one and wiring it up.</p>
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
<td>Who can create one</td>
<td>an Erlang caller in the release, or the matchmaker</td>
<td>any client, over <code>world.create</code> or <code>POST /api/v1/worlds</code></td>
</tr>
<tr>
<td>Processes</td>
<td>1</td>
<td>6 (instance sup, zone sup, zone manager, one zone, ticker, world server)</td>
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
<td>starts at <code>min_players</code>, gives up after 60s</td>
<td>survives empty if <code>persistent</code></td>
</tr>
</tbody>
</table>
<p>A waiting match is the cheaper shape, but the row above that decides it is
&quot;who can create one&quot;. Read the next section before choosing it.</p>
<h2 id="waiting-match" tabindex="-1">Waiting match</h2>
<p>A match starts in the <code>waiting</code> state and transitions to <code>running</code> when
<code>min_players</code> is reached. That waiting period is the lobby.</p>
<p><strong>No client-facing call brings a waiting match into existence.</strong>
<code>asobi_match_sup:start_match/1</code> is the only thing that creates a match, and its
only caller in the release is the matchmaker - which spawns a match with
<code>min_players</code> already equal to the group it just formed, so the waiting state
lasts as long as the join fan-out and no longer. There is no <code>match.create</code>
frame and no <code>POST /api/v1/matches</code>.</p>
<p>So the waiting-match lobby is an <strong>Erlang-only</strong> route: it needs a module in
your release that calls <code>asobi_match_sup:start_match/1</code> with a <code>min_players</code>
higher than the number of players it seeds, and <code>listed =&gt; true</code> so clients can
find it.</p>
<pre><code class="language-erlang">{ok, Pid} = asobi_match_sup:start_match(#{
    mode         =&gt; ~&quot;arena&quot;,
    game_module  =&gt; my_arena,
    game_config  =&gt; #{},
    min_players  =&gt; 4,
    max_players  =&gt; 4,
    listed       =&gt; true
}).
</code></pre>
<p><strong>If you are writing Lua, use a world instead.</strong> A world is the only session a
client can create, so it is the only lobby a Lua-only game can build. Skip to
<a href="#persistent-world-as-a-hub">Persistent world as a hub</a>.</p>
<h3 id="letting-players-find-it" tabindex="-1">Letting players find it</h3>
<pre><code>GET /api/v1/matches/live        REST
match.list                      WebSocket
</code></pre>
<p>Both filter on <code>mode</code>, <code>has_capacity</code> and <code>joinable</code>. Matches are unlisted by
default - a matchmaker-spawned match is already assigned to its players and has
no reason to be browsable - so a mode opts in with <code>listed = true</code>.</p>
<p>Do not use <code>GET /api/v1/matches</code> for this. It reads the match record table:
finished matches, an audit trail, nothing joinable. See
<a href="/docs/protocols/rest">REST API</a>.</p>
<h3 id="joining-a-match-already-in-progress" tabindex="-1">Joining a match already in progress</h3>
<p>A <code>running</code> match accepts joins exactly as a <code>waiting</code> one does, so backfill is
<code>match.list</code> then <code>match.join</code> with the <code>match_id</code> - there is no separate call
and no backfill mode to turn on. Your <code>join</code> callback runs mid-match, so it has
to cope with a player arriving into a live game state.</p>
<p>Ask for both filters when you are looking for somewhere to play:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.join&quot;, &quot;payload&quot;: {&quot;match_id&quot;: &quot;...&quot;}}
</code></pre>
<pre><code>match.list  { &quot;has_capacity&quot;: true, &quot;joinable&quot;: true }
</code></pre>
<p>They are different questions. A match with three free slots may have closed
itself to new players; a full one has not closed, and may free a slot on the
next leave. Every listing carries <code>joinable</code>, so a browser can show both and
grey one out.</p>
<p>To close a match to backfill, call
<a href="https://hexdocs.pm/asobi/lua-api.html#match"><code>game.match.set_joinable(false)</code></a> from the script - at the
end of round one, once the objective spawns, whenever the game says so. A
closed match answers <code>match.locked</code>; a full one answers <code>match.full</code>. To turn
away one specific player rather than everybody, return <code>nil</code> from
<a href="/docs/lua/api#refusing-a-join"><code>join</code></a> instead.</p>
<h3 id="the-60-second-timeout" tabindex="-1">The 60-second timeout</h3>
<p>A match that does not reach <code>min_players</code> within 60 seconds stops itself. That
value is fixed (<code>?WAITING_TIMEOUT</code> in <code>asobi_match_server</code>) and is not exposed
per mode. Fine for quick play; too short if you want players assembling at their
own pace.</p>
<h2 id="persistent-world-as-a-hub" tabindex="-1">Persistent world as a hub</h2>
<p>For a town square people return to between games, use a world. This is the path
a client can drive on its own.</p>
<pre><code class="language-lua">-- hub.lua
game_type   = &quot;world&quot;
persistent  = true    -- stays alive when empty; without this it dies on the last leave
grid_size   = 1       -- one zone: no spatial partitioning needed to stand around
tick_rate   = 200     -- 5 Hz is plenty; the 50ms default is for action games
match_size  = 1
</code></pre>
<p><code>listed</code> and <code>quick_play</code> are Lua globals, both defaulting to true for a world -
which is what a hub wants: it is browsable and <code>world.find_or_create</code> drops
everyone into the same one. Set either to <code>false</code> in the script to change it.
An operator <code>game_modes</code> entry still wins, and it replaces the script's mode
config rather than merging into it - so if you add one, declare
<code>module =&gt; {lua, &quot;hub.lua&quot;}</code> and the rest of the shape in it too.</p>
<p><code>persistent</code> is the flag that makes it a hub rather than a session. Without it a
world finishes the moment the last player leaves, so the next player gets a
fresh empty one.</p>
<p>Presence is free here: worlds tick and broadcast zone state, so players see each
other without you broadcasting anything. <code>world:&lt;WorldId&gt;</code> chat works and is
gated on world membership.</p>
<p>Nothing creates the hub at boot. The first <code>world.find_or_create</code> instantiates
it and it stays up from then on; after a restart the first player recreates it.</p>
<p>Worlds are subject to <code>world_max_per_player</code> (5) and <code>world_max</code> (1000) - see
<a href="/docs/configuration#world-capacity">World capacity</a>.</p>
<h3 id="private-lobbies" tabindex="-1">Private lobbies</h3>
<p>Because only a world can be created by a client, a code-gated private lobby is a
world too. Share a code out of band and check it on the way in. The join context
is whatever the client put in the join payload; asobi never reads it.</p>
<pre><code class="language-lua">function join(player_id, state, ctx)
	if ctx.code ~= state.room_code then
		return state                    -- refuse: player is not added
	end
	state.players[player_id] = true
	game.broadcast(&quot;lobby_update&quot;, { players = state.players })
	return state
end
</code></pre>
<p>Hide it from the browser with <code>listed = false</code> in the script. That is discovery
only - it never gates joining, so the join callback above is still the whole
gate. <code>listed</code> and <code>quick_play</code> are properties of the mode, not of one
instance, so every world of that mode is equally hidden. See
<a href="/docs/protocols/websocket#join-context">Join context</a>.</p>
<h3 id="telling-the-room-someone-arrived" tabindex="-1">Telling the room someone arrived</h3>
<p>Core does not push a join notification to the players already waiting. That is
deliberate: what a lobby shows differs per game - a bare count, a full roster,
nothing until it fills.</p>
<p><code>game.broadcast</code> from your join callback is the whole of it, as above. It
reaches every player currently in the session, and the example above arrives
client-side as <code>{&quot;type&quot;: &quot;world.lobby_update&quot;, &quot;payload&quot;: {&quot;players&quot;: ...}}</code> -
<code>match.lobby_update</code> from a match script. Naming rules and the SDK-side handler
are in <a href="/docs/protocols/websocket#custom-events">Custom events</a>.</p>
<h3 id="chat-in-a-lobby" tabindex="-1">Chat in a lobby</h3>
<p>There is no <code>match:</code> channel scheme. <code>world:&lt;WorldId&gt;</code>, <code>zone:&lt;WorldId&gt;:&lt;X&gt;,&lt;Y&gt;</code>
and <code>prox:&lt;WorldId&gt;:&lt;X&gt;,&lt;Y&gt;</code> exist and are gated on world membership; matches
have no equivalent, so a match lobby uses <code>game.broadcast</code> with your own message
shape.</p>
<p>The <code>room:</code> scheme is not open-join - <code>room:&lt;GroupId&gt;</code> resolves to a membership
check against that group.</p>
<h2 id="seeing-what-players-see" tabindex="-1">Seeing what players see</h2>
<p>The console's Matches screen is the <strong>finished-match record</strong>, not the live
list: core writes one row when a match ends, so a waiting lobby never appears
there. To see what a player browsing sees, call <code>GET /api/v1/matches/live</code>.
There is no worlds screen either; use <code>GET /api/v1/worlds</code>. See
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<h2 id="not-included" tabindex="-1">Not included</h2>
<ul>
<li><strong>Ready-up.</strong> No first-class ready state. Track it in your own game state and
broadcast it; the join context and <code>game.broadcast</code> are enough. A game that
wants a shared one can ship it as an extension method and call it over the
<code>rpc.call</code> frame - see <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</li>
<li><strong>Party.</strong> You cannot queue as a group through the matchmaker. Play with
specific people by sharing a world id or a join code, or add party grouping as
an extension.</li>
<li><strong>Rich filters.</strong> Discovery filters on <code>mode</code>, <code>has_capacity</code> and <code>joinable</code>
only. Anything richer belongs in your strategy module, or in an extension
method that returns the filtered list.</li>
<li><strong>Backfill matchmaking.</strong> The matchmaker builds matches out of the queue; it
never routes a queued player into a match that is already running. Backfill
is a client browsing and joining, not a strategy the matchmaker runs.</li>
<li><strong>Member roster API.</strong> The joiner receives the roster on <code>match.joined</code> /
<code>world.joined</code>; there is no separate &quot;who is here&quot; call. Keep the list in your
game state, or expose it as an extension method.</li>
</ul>
"""}
    ]}.
