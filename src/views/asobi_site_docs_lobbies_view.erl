%% GENERATED from asobi guides/lobbies.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_lobbies_view).

-export([mount/1, render/1, markdown/0]).

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
<p><strong><code>match.find_or_create</code> is the client-facing route into a live match.</strong> Send a
mode; the server returns the first listed match of that mode with room that is
still accepting players, and spawns one if there is none. The reply is
<code>match.joined</code>, the same frame <code>match.join</code> answers with.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.find_or_create&quot;, &quot;cid&quot;: &quot;1&quot;, &quot;payload&quot;: {&quot;mode&quot;: &quot;arena&quot;}}
</code></pre>
<p>Opt in with <code>quick_play = true</code>. It defaults to <code>false</code> for match modes, so a
ranked mode the matchmaker owns is refused with <code>quick_play_disabled</code> until you
say otherwise - and a mode written before this frame existed is safe on upgrade
without touching it.</p>
<p><code>quick_play</code> and <code>listed</code> are independent: <code>listed</code> decides whether a match
appears in <code>match.list</code>, <code>quick_play</code> decides whether a player may be dropped
into an existing one. Hidden but auto-filled is a legitimate combination.</p>
<p>Prefer it over <code>match.list</code> then <code>match.join</code>. Browsing and then joining is two
round trips with a race in the middle: two clients that both read an empty list
both create, and you get two half-empty matches that may each fail to reach
<code>min_players</code>. <code>find_or_create</code> resolves server-side, serialized, so
simultaneous callers land in the same match.</p>
<p>There is still no bare <code>match.create</code>, and no <code>POST /api/v1/matches</code>. Creating a
match without reusing one is what the matchmaker is for.</p>
<p>But the waiting state is reachable from mode config. Declare a <code>min_players</code>
higher than <code>match_size</code> and the matchmaker spawns on the group it formed while
the match sits in <code>waiting</code> until backfill brings it up to the threshold:</p>
<pre><code class="language-lua">match_size  = 2   -- the matchmaker forms and spawns on two
min_players = 4   -- the loop does not start until four are in
max_players = 8
quick_play  = true   -- so match.find_or_create can bring the other two in
listed      = true   -- so match.list can find it too
</code></pre>
<p>It gives up at <code>?WAITING_TIMEOUT</code> (60s) if the fourth never arrives.</p>
<p>Before asobi v0.85.0 the matchmaker overwrote <code>min_players</code> with <code>match_size</code>,
so declaring it was silently ignored and a waiting lobby needed an Erlang module
in your release calling <code>asobi_match_sup:start_match/1</code>. That function still
exists for an operator shipping their own module, but nothing about a lobby
needs it any more.</p>
<p><strong>A match is a client-creatable session too.</strong> That was not true before
<code>match.find_or_create</code>, and this page used to send Lua readers to a world for
that reason. A world is still the better hub when you want somewhere persistent
that survives empty - see <a href="#persistent-world-as-a-hub">Persistent world as a hub</a></p>
<ul>
<li>but it is a choice now, not the only option.</li>
</ul>
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
<a href="/docs/lua/api#join-player_id-state-or-join-player_id-state-ctx"><code>join</code></a> instead.</p>
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
<a href="/docs/configuration#instance-capacity">World capacity</a>.</p>
<h3 id="private-lobbies" tabindex="-1">Private lobbies</h3>
<p>A code-gated private lobby can be a match as well as a world: <code>match.find_or_create</code>
forwards the join context, so a <code>join</code> callback can refuse on a bad code. Share a code out of band and check it on the way in. The join context
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
<a href="/docs/protocols/websocket#match-join">Join context</a>.</p>
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

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Lobbies

How to gather players before a game starts.

asobi has no `Lobby` object. A lobby is a state, not a type, and asobi already
has two things that hold players before a game begins. This guide is about
picking one and wiring it up.

## Which one

| | Waiting match | Persistent world |
|---|---|---|
| Use for | gather N players, play, done | a hub people return to between games |
| Who can create one | an Erlang caller in the release, or the matchmaker | any client, over `world.create` or `POST /api/v1/worlds` |
| Processes | 1 | 6 (instance sup, zone sup, zone manager, one zone, ticker, world server) |
| Ticks while idle | none | yes, at `tick_rate` |
| Presence | you broadcast it | free, from the tick loop |
| Lifetime | starts at `min_players`, gives up after 60s | survives empty if `persistent` |

A waiting match is the cheaper shape, but the row above that decides it is
"who can create one". Read the next section before choosing it.

## Waiting match

A match starts in the `waiting` state and transitions to `running` when
`min_players` is reached. That waiting period is the lobby.

**`match.find_or_create` is the client-facing route into a live match.** Send a
mode; the server returns the first listed match of that mode with room that is
still accepting players, and spawns one if there is none. The reply is
`match.joined`, the same frame `match.join` answers with.

```json
{"type": "match.find_or_create", "cid": "1", "payload": {"mode": "arena"}}
```

Opt in with `quick_play = true`. It defaults to `false` for match modes, so a
ranked mode the matchmaker owns is refused with `quick_play_disabled` until you
say otherwise - and a mode written before this frame existed is safe on upgrade
without touching it.

`quick_play` and `listed` are independent: `listed` decides whether a match
appears in `match.list`, `quick_play` decides whether a player may be dropped
into an existing one. Hidden but auto-filled is a legitimate combination.

Prefer it over `match.list` then `match.join`. Browsing and then joining is two
round trips with a race in the middle: two clients that both read an empty list
both create, and you get two half-empty matches that may each fail to reach
`min_players`. `find_or_create` resolves server-side, serialized, so
simultaneous callers land in the same match.

There is still no bare `match.create`, and no `POST /api/v1/matches`. Creating a
match without reusing one is what the matchmaker is for.

But the waiting state is reachable from mode config. Declare a `min_players`
higher than `match_size` and the matchmaker spawns on the group it formed while
the match sits in `waiting` until backfill brings it up to the threshold:

```lua
match_size  = 2   -- the matchmaker forms and spawns on two
min_players = 4   -- the loop does not start until four are in
max_players = 8
quick_play  = true   -- so match.find_or_create can bring the other two in
listed      = true   -- so match.list can find it too
```

It gives up at `?WAITING_TIMEOUT` (60s) if the fourth never arrives.

Before asobi v0.85.0 the matchmaker overwrote `min_players` with `match_size`,
so declaring it was silently ignored and a waiting lobby needed an Erlang module
in your release calling `asobi_match_sup:start_match/1`. That function still
exists for an operator shipping their own module, but nothing about a lobby
needs it any more.

**A match is a client-creatable session too.** That was not true before
`match.find_or_create`, and this page used to send Lua readers to a world for
that reason. A world is still the better hub when you want somewhere persistent
that survives empty - see [Persistent world as a hub](#persistent-world-as-a-hub)
- but it is a choice now, not the only option.

### Letting players find it

```
GET /api/v1/matches/live        REST
match.list                      WebSocket
```

Both filter on `mode`, `has_capacity` and `joinable`. Matches are unlisted by
default - a matchmaker-spawned match is already assigned to its players and has
no reason to be browsable - so a mode opts in with `listed = true`.

Do not use `GET /api/v1/matches` for this. It reads the match record table:
finished matches, an audit trail, nothing joinable. See
[REST API](https://asobi.dev/docs/protocols/rest).

### Joining a match already in progress

A `running` match accepts joins exactly as a `waiting` one does, so backfill is
`match.list` then `match.join` with the `match_id` - there is no separate call
and no backfill mode to turn on. Your `join` callback runs mid-match, so it has
to cope with a player arriving into a live game state.

Ask for both filters when you are looking for somewhere to play:

```json
{"type": "match.join", "payload": {"match_id": "..."}}
```

```
match.list  { "has_capacity": true, "joinable": true }
```

They are different questions. A match with three free slots may have closed
itself to new players; a full one has not closed, and may free a slot on the
next leave. Every listing carries `joinable`, so a browser can show both and
grey one out.

To close a match to backfill, call
[`game.match.set_joinable(false)`](https://hexdocs.pm/asobi/lua-api.html#match) from the script - at the
end of round one, once the objective spawns, whenever the game says so. A
closed match answers `match.locked`; a full one answers `match.full`. To turn
away one specific player rather than everybody, return `nil` from
[`join`](https://asobi.dev/docs/lua/api#join-player_id-state-or-join-player_id-state-ctx) instead.

### The 60-second timeout

A match that does not reach `min_players` within 60 seconds stops itself. That
value is fixed (`?WAITING_TIMEOUT` in `asobi_match_server`) and is not exposed
per mode. Fine for quick play; too short if you want players assembling at their
own pace.

## Persistent world as a hub

For a town square people return to between games, use a world. This is the path
a client can drive on its own.

```lua
-- hub.lua
game_type   = "world"
persistent  = true    -- stays alive when empty; without this it dies on the last leave
grid_size   = 1       -- one zone: no spatial partitioning needed to stand around
tick_rate   = 200     -- 5 Hz is plenty; the 50ms default is for action games
match_size  = 1
```

`listed` and `quick_play` are Lua globals, both defaulting to true for a world -
which is what a hub wants: it is browsable and `world.find_or_create` drops
everyone into the same one. Set either to `false` in the script to change it.
An operator `game_modes` entry still wins, and it replaces the script's mode
config rather than merging into it - so if you add one, declare
`module => {lua, "hub.lua"}` and the rest of the shape in it too.

`persistent` is the flag that makes it a hub rather than a session. Without it a
world finishes the moment the last player leaves, so the next player gets a
fresh empty one.

Presence is free here: worlds tick and broadcast zone state, so players see each
other without you broadcasting anything. `world:<WorldId>` chat works and is
gated on world membership.

Nothing creates the hub at boot. The first `world.find_or_create` instantiates
it and it stays up from then on; after a restart the first player recreates it.

Worlds are subject to `world_max_per_player` (5) and `world_max` (1000) - see
[World capacity](https://asobi.dev/docs/configuration#instance-capacity).

### Private lobbies

A code-gated private lobby can be a match as well as a world: `match.find_or_create`
forwards the join context, so a `join` callback can refuse on a bad code. Share a code out of band and check it on the way in. The join context
is whatever the client put in the join payload; asobi never reads it.

```lua
function join(player_id, state, ctx)
	if ctx.code ~= state.room_code then
		return state                    -- refuse: player is not added
	end
	state.players[player_id] = true
	game.broadcast("lobby_update", { players = state.players })
	return state
end
```

Hide it from the browser with `listed = false` in the script. That is discovery
only - it never gates joining, so the join callback above is still the whole
gate. `listed` and `quick_play` are properties of the mode, not of one
instance, so every world of that mode is equally hidden. See
[Join context](https://asobi.dev/docs/protocols/websocket#match-join).

### Telling the room someone arrived

Core does not push a join notification to the players already waiting. That is
deliberate: what a lobby shows differs per game - a bare count, a full roster,
nothing until it fills.

`game.broadcast` from your join callback is the whole of it, as above. It
reaches every player currently in the session, and the example above arrives
client-side as `{"type": "world.lobby_update", "payload": {"players": ...}}` -
`match.lobby_update` from a match script. Naming rules and the SDK-side handler
are in [Custom events](https://asobi.dev/docs/protocols/websocket#custom-events).

### Chat in a lobby

There is no `match:` channel scheme. `world:<WorldId>`, `zone:<WorldId>:<X>,<Y>`
and `prox:<WorldId>:<X>,<Y>` exist and are gated on world membership; matches
have no equivalent, so a match lobby uses `game.broadcast` with your own message
shape.

The `room:` scheme is not open-join - `room:<GroupId>` resolves to a membership
check against that group.

## Seeing what players see

The console's Matches screen is the **finished-match record**, not the live
list: core writes one row when a match ends, so a waiting lobby never appears
there. To see what a player browsing sees, call `GET /api/v1/matches/live`.
There is no worlds screen either; use `GET /api/v1/worlds`. See
[Operator console](https://hexdocs.pm/asobi/console.html).

## Not included

- **Ready-up.** No first-class ready state. Track it in your own game state and
  broadcast it; the join context and `game.broadcast` are enough. A game that
  wants a shared one can ship it as an extension method and call it over the
  `rpc.call` frame - see [Extensions](https://hexdocs.pm/asobi/extensions.html).
- **Party.** You cannot queue as a group through the matchmaker. Play with
  specific people by sharing a world id or a join code, or add party grouping as
  an extension.
- **Rich filters.** Discovery filters on `mode`, `has_capacity` and `joinable`
  only. Anything richer belongs in your strategy module, or in an extension
  method that returns the filtered list.
- **Backfill matchmaking.** The matchmaker builds matches out of the queue; it
  never routes a queued player into a match that is already running. Backfill
  is a client browsing and joining, not a strategy the matchmaker runs.
- **Member roster API.** The joiner receives the roster on `match.joined` /
  `world.joined`; there is no separate "who is here" call. Keep the list in your
  game state, or expose it as an extension method.
""".
