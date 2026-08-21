%% GENERATED from asobi guides/phases.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_phases_view).

-export([mount/1, render/1, markdown/0]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-phases", title => ~"Phases and seasons — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Phases and seasons"
        ]},
        {h1, [], [~"Phases"]},
        {raw,
            ~"""
<p>A <strong>phase</strong> is a stage in one session's lifecycle - lobby, then play, then
results - inside a single match or world. It starts and ends with that
session and is authored in the game script.</p>
<p>The other clock, a <strong>season</strong>, is a wall-clock window across the whole
deployment - a fortnight of ranked play, a themed event. Seasons are not part
of core: they ship as the <a href="https://github.com/widgrensit/asobi_seasons"><code>asobi_seasons</code></a> extension. The two do not
interact.</p>
<h2 id="phases" tabindex="-1">Phases</h2>
<h3 id="declare-them-in-your-game-script" tabindex="-1">Declare them in your game script</h3>
<p>Phases are a list. The engine walks it in order: the first phase starts,
runs for its <code>duration</code>, ends, and the next begins.</p>
<pre><code class="language-lua">-- king_of_the_hill.lua
function phases(config)
  return {
    { name = &quot;warmup&quot;,  duration = 10000 },
    { name = &quot;combat&quot;,  duration = 120000 },
    { name = &quot;results&quot;, duration = 8000 },
  }
end
</code></pre>
<p><code>duration</code> is milliseconds. When the last phase ends the session's phase
state is complete; a match reports <code>phases_complete</code> and finishes.</p>
<p>This is game logic. It runs identically whether you deploy to the managed
cloud or self-host - nothing here touches deployment, secrets, or the
database. Every phase example below is written once and is the same on both.</p>
<h3 id="start-conditions" tabindex="-1">Start conditions</h3>
<p>By default each phase starts when the previous one ends (<code>prev_ended</code>). A
phase can instead wait for a condition:</p>
<pre><code class="language-lua">function phases(config)
  return {
    { name = &quot;lobby&quot;,  start = { players = 4 } },
    { name = &quot;combat&quot;, duration = 120000 },
    { name = &quot;results&quot;, duration = 8000 },
  }
end
</code></pre>
<p>Start conditions you can declare from Lua:</p>
<table>
<thead>
<tr>
<th><code>start</code> value</th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>&quot;prev_ended&quot;</code></td>
<td>when the previous phase ends (default)</td>
</tr>
<tr>
<td><code>{ players = N }</code></td>
<td>when the Nth player has joined</td>
</tr>
<tr>
<td><code>{ timer = Ms }</code></td>
<td>after Ms of waiting, whatever else</td>
</tr>
<tr>
<td><code>Ms</code> (a bare number)</td>
<td>shorthand for <code>{ timer = Ms }</code></td>
</tr>
<tr>
<td><code>&quot;all_ready&quot;</code></td>
<td>when the game signals every player ready</td>
</tr>
</tbody>
</table>
<p>A waiting phase has no duration clock; it holds until its condition fires.</p>
<h3 id="react-to-transitions" tabindex="-1">React to transitions</h3>
<p>Two optional callbacks fire as phases begin and end. Use them to reset
scores, open a gate, freeze input. The client sends intent; the server
decides the phase; the server broadcasts the result.</p>
<pre><code class="language-lua">function on_phase_started(phase_name, state)
  if phase_name == &quot;combat&quot; then
    state.scores = {}
    game.broadcast(&quot;round_start&quot;, { phase = phase_name })
  end
  return state
end

function on_phase_ended(phase_name, state)
  if phase_name == &quot;combat&quot; then
    game.broadcast(&quot;round_over&quot;, { winner = leader(state) })
  end
  return state
end
</code></pre>
<p><code>game.broadcast</code> is how the phase reaches your own clients with your own
shape. The two calls above arrive as <code>{&quot;type&quot;: &quot;match.round_start&quot;}</code> and
<code>{&quot;type&quot;: &quot;match.round_over&quot;}</code> (<code>world.*</code> from a world script); see
<a href="/docs/protocols/websocket#custom-events">Custom events</a> for the naming rules.
See the callback reference for the full callback list.</p>
<h3 id="what-the-client-sees-on-the-wire" tabindex="-1">What the client sees on the wire</h3>
<p>A <strong>world</strong> pushes <code>world.phase_changed</code> on every transition:</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;world.phase_changed&quot;,
  &quot;payload&quot;: {
    &quot;status&quot;: &quot;active&quot;,
    &quot;phase&quot;: &quot;combat&quot;,
    &quot;remaining_ms&quot;: 118400,
    &quot;config&quot;: {},
    &quot;timers&quot;: {},
    &quot;world_id&quot;: &quot;...&quot;
  }
}
</code></pre>
<p>It also re-sends the phase info periodically, and what a client actually
receives is a <strong>burst of identical frames</strong>, not one frame every three seconds.
The gate is a wall-clock check evaluated inside the tick loop, so it passes on
every tick that falls in a qualifying second: at the default 20 Hz that is
roughly twenty copies, once every three seconds. A slower <code>tick_rate</code> sends
fewer, a faster one more.</p>
<p>Dedupe on the client. Keep the last <code>(phase, status)</code> you rendered and ignore a
frame that repeats it; use <code>remaining_ms</code> for the countdown rather than
counting frames.</p>
<p>Two other differences in the periodic frames worth handling: they carry no
<code>world_id</code> (only the transition frame merges it in), and a world whose phases
have all completed sends <code>{&quot;status&quot;: &quot;complete&quot;, &quot;phase&quot;: &quot;undefined&quot;}</code> on
repeat - the string, not <code>null</code>.</p>
<p>A <strong>match</strong> does not push a phase event at all. The match server runs the phase
clock and your callbacks, but the client learns the phase by reading the <code>phase</code>
block on the listing and join reply - <code>status</code>, <code>phase</code>, <code>remaining_ms</code> and the
pending <code>start_condition</code>. Broadcast anything richer yourself from
<code>on_phase_started</code>.</p>
<p>See <a href="/docs/protocols/websocket#world-phase_changed-server-push">WebSocket protocol</a>
for the frame envelope and <a href="https://hexdocs.pm/asobi/lobbies.html">Lobbies</a> for <code>game.broadcast</code>.</p>
<h3 id="erlang-games" tabindex="-1">Erlang games</h3>
<p>An Erlang match or world module implements the same three callbacks and has
the full phase feature set, including per-phase <code>timers</code>, an <code>end_condition</code>
predicate, and the <code>players_ratio</code> and <code>event</code> start conditions that the Lua
decoder does not expose.</p>
<pre><code class="language-erlang">phases(_Config) -&gt;
    [
        #{name =&gt; ~&quot;warmup&quot;, duration =&gt; 10000},
        #{name =&gt; ~&quot;combat&quot;, duration =&gt; 120000,
          timers =&gt; [#{id =&gt; ~&quot;suddendeath&quot;, type =&gt; countdown, duration =&gt; 100000}]},
        #{name =&gt; ~&quot;results&quot;, duration =&gt; 8000}
    ].

on_phase_started(~&quot;combat&quot;, GameState) -&gt;
    {ok, GameState#{scores =&gt; #{}}};
on_phase_started(_Name, GameState) -&gt;
    {ok, GameState}.
</code></pre>
<h3 id="limits-when-authoring-in-lua" tabindex="-1">Limits when authoring in Lua</h3>
<p>The Lua <code>phases()</code> decoder reads <code>name</code>, <code>duration</code>, <code>start</code> and <code>config</code>
only. From Lua you cannot declare per-phase <code>timers</code>, an <code>end_condition</code>
function, or the <code>players_ratio</code> and <code>event</code> start conditions - those need
an Erlang game module. If a phase needs a timer, drive it from your own tick
logic and <code>game.broadcast</code>, or move that game to Erlang.</p>
<h3 id="three-ways-a-phase-list-fails-quietly" tabindex="-1">Three ways a phase list fails quietly</h3>
<p>The decoder is forgiving, and three mistakes cost you a warning you will never
see:</p>
<ul>
<li><strong>A non-numeric <code>duration</code> becomes 0.</strong> <code>duration = &quot;10000&quot;</code> is a string, so
the phase starts and ends in the same tick. Only a Lua number works.</li>
<li><strong>An unrecognised <code>start</code> falls back to <code>prev_ended</code>.</strong> <code>start = &quot;all-ready&quot;</code>
or <code>start = &quot;players&quot;</code> is not rejected; the phase simply begins when the
previous one ends. The accepted values are exactly the table above.</li>
<li><strong>A phase table with no <code>name</code> is dropped from the list.</strong> The rest of the
list still runs, so a three-phase game silently becomes a two-phase one.</li>
</ul>
<p>Only a non-list return from <code>phases()</code> logs anything. Check the phase names on
the wire (<code>world.phase_changed</code>) or in the <code>phase</code> block on a listing before
concluding a phase never fired.</p>
<h2 id="seasons" tabindex="-1">Seasons</h2>
<p>Seasons live in <a href="https://github.com/widgrensit/asobi_seasons"><code>asobi_seasons</code></a>, an extension. asobi still creates
the <code>seasons</code> table - the extraction moved the code, not the migration history</p>
<ul>
<li>but the schema, the query API and the background manager that flips
<code>upcoming -&gt; active -&gt; ended</code> are all in that package now.</li>
</ul>
<p>Add it to your release and read <a href="https://github.com/widgrensit/asobi_seasons/blob/main/guides/seasons.md">its guide</a>.</p>
<h2 id="checkpoint" tabindex="-1">Checkpoint</h2>
<p>Phases, with a Lua world game running locally:</p>
<ol>
<li>Add a <code>phases()</code> returning <code>warmup</code> (5000) then <code>active</code> (10000) to your
world script.</li>
<li>Join the world over the WebSocket and watch the frames. Within a few
seconds you see <code>world.phase_changed</code> with <code>&quot;phase&quot;: &quot;warmup&quot;</code>, then
after five seconds another with <code>&quot;phase&quot;: &quot;active&quot;</code>. Expect repeats of the
same frame in between; that is the periodic re-send, not a second
transition.</li>
<li>Call <code>world.list</code>; the entry carries a <code>phase</code> block with the live
<code>phase</code> and <code>remaining_ms</code>.</li>
</ol>
<p>If the phase frames never arrive, confirm the game is a <strong>world</strong> (matches run
phases but do not push them) and that <code>phases()</code> returns a list. A non-list
logs a warning and is ignored. If some phases arrive and others do not, check
the <a href="#three-ways-a-phase-list-fails-quietly">three silent decoder failures</a>.</p>
<h2 id="next" tabindex="-1">Next</h2>
<p><a href="/docs/voting">Voting</a> - run a vote inside a phase to let players pick what
happens in the next one.</p>
"""}
    ]}.

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Phases

A **phase** is a stage in one session's lifecycle - lobby, then play, then
results - inside a single match or world. It starts and ends with that
session and is authored in the game script.

The other clock, a **season**, is a wall-clock window across the whole
deployment - a fortnight of ranked play, a themed event. Seasons are not part
of core: they ship as the [`asobi_seasons`][seasons] extension. The two do not
interact.

[seasons]: https://github.com/widgrensit/asobi_seasons

## Phases

### Declare them in your game script

Phases are a list. The engine walks it in order: the first phase starts,
runs for its `duration`, ends, and the next begins.

```lua
-- king_of_the_hill.lua
function phases(config)
  return {
    { name = "warmup",  duration = 10000 },
    { name = "combat",  duration = 120000 },
    { name = "results", duration = 8000 },
  }
end
```

`duration` is milliseconds. When the last phase ends the session's phase
state is complete; a match reports `phases_complete` and finishes.

This is game logic. It runs identically whether you deploy to the managed
cloud or self-host - nothing here touches deployment, secrets, or the
database. Every phase example below is written once and is the same on both.

### Start conditions

By default each phase starts when the previous one ends (`prev_ended`). A
phase can instead wait for a condition:

```lua
function phases(config)
  return {
    { name = "lobby",  start = { players = 4 } },
    { name = "combat", duration = 120000 },
    { name = "results", duration = 8000 },
  }
end
```

Start conditions you can declare from Lua:

| `start` value        | Meaning                                  |
|----------------------|------------------------------------------|
| `"prev_ended"`       | when the previous phase ends (default)   |
| `{ players = N }`    | when the Nth player has joined           |
| `{ timer = Ms }`     | after Ms of waiting, whatever else       |
| `Ms` (a bare number) | shorthand for `{ timer = Ms }`           |
| `"all_ready"`        | when the game signals every player ready |

A waiting phase has no duration clock; it holds until its condition fires.

### React to transitions

Two optional callbacks fire as phases begin and end. Use them to reset
scores, open a gate, freeze input. The client sends intent; the server
decides the phase; the server broadcasts the result.

```lua
function on_phase_started(phase_name, state)
  if phase_name == "combat" then
    state.scores = {}
    game.broadcast("round_start", { phase = phase_name })
  end
  return state
end

function on_phase_ended(phase_name, state)
  if phase_name == "combat" then
    game.broadcast("round_over", { winner = leader(state) })
  end
  return state
end
```

`game.broadcast` is how the phase reaches your own clients with your own
shape. The two calls above arrive as `{"type": "match.round_start"}` and
`{"type": "match.round_over"}` (`world.*` from a world script); see
[Custom events](https://asobi.dev/docs/protocols/websocket#custom-events) for the naming rules.
See the callback reference for the full callback list.

### What the client sees on the wire

A **world** pushes `world.phase_changed` on every transition:

```json
{
  "type": "world.phase_changed",
  "payload": {
    "status": "active",
    "phase": "combat",
    "remaining_ms": 118400,
    "config": {},
    "timers": {},
    "world_id": "..."
  }
}
```

It also re-sends the phase info periodically, and what a client actually
receives is a **burst of identical frames**, not one frame every three seconds.
The gate is a wall-clock check evaluated inside the tick loop, so it passes on
every tick that falls in a qualifying second: at the default 20 Hz that is
roughly twenty copies, once every three seconds. A slower `tick_rate` sends
fewer, a faster one more.

Dedupe on the client. Keep the last `(phase, status)` you rendered and ignore a
frame that repeats it; use `remaining_ms` for the countdown rather than
counting frames.

Two other differences in the periodic frames worth handling: they carry no
`world_id` (only the transition frame merges it in), and a world whose phases
have all completed sends `{"status": "complete", "phase": "undefined"}` on
repeat - the string, not `null`.

A **match** does not push a phase event at all. The match server runs the phase
clock and your callbacks, but the client learns the phase by reading the `phase`
block on the listing and join reply - `status`, `phase`, `remaining_ms` and the
pending `start_condition`. Broadcast anything richer yourself from
`on_phase_started`.

See [WebSocket protocol](https://asobi.dev/docs/protocols/websocket#world-phase_changed-server-push)
for the frame envelope and [Lobbies](https://hexdocs.pm/asobi/lobbies.html) for `game.broadcast`.

### Erlang games

An Erlang match or world module implements the same three callbacks and has
the full phase feature set, including per-phase `timers`, an `end_condition`
predicate, and the `players_ratio` and `event` start conditions that the Lua
decoder does not expose.

```erlang
phases(_Config) ->
    [
        #{name => ~"warmup", duration => 10000},
        #{name => ~"combat", duration => 120000,
          timers => [#{id => ~"suddendeath", type => countdown, duration => 100000}]},
        #{name => ~"results", duration => 8000}
    ].

on_phase_started(~"combat", GameState) ->
    {ok, GameState#{scores => #{}}};
on_phase_started(_Name, GameState) ->
    {ok, GameState}.
```

### Limits when authoring in Lua

The Lua `phases()` decoder reads `name`, `duration`, `start` and `config`
only. From Lua you cannot declare per-phase `timers`, an `end_condition`
function, or the `players_ratio` and `event` start conditions - those need
an Erlang game module. If a phase needs a timer, drive it from your own tick
logic and `game.broadcast`, or move that game to Erlang.

### Three ways a phase list fails quietly

The decoder is forgiving, and three mistakes cost you a warning you will never
see:

- **A non-numeric `duration` becomes 0.** `duration = "10000"` is a string, so
  the phase starts and ends in the same tick. Only a Lua number works.
- **An unrecognised `start` falls back to `prev_ended`.** `start = "all-ready"`
  or `start = "players"` is not rejected; the phase simply begins when the
  previous one ends. The accepted values are exactly the table above.
- **A phase table with no `name` is dropped from the list.** The rest of the
  list still runs, so a three-phase game silently becomes a two-phase one.

Only a non-list return from `phases()` logs anything. Check the phase names on
the wire (`world.phase_changed`) or in the `phase` block on a listing before
concluding a phase never fired.

## Seasons

Seasons live in [`asobi_seasons`][seasons], an extension. asobi still creates
the `seasons` table - the extraction moved the code, not the migration history
- but the schema, the query API and the background manager that flips
`upcoming -> active -> ended` are all in that package now.

Add it to your release and read [its guide][seasons-guide].

[seasons-guide]: https://github.com/widgrensit/asobi_seasons/blob/main/guides/seasons.md

## Checkpoint

Phases, with a Lua world game running locally:

1. Add a `phases()` returning `warmup` (5000) then `active` (10000) to your
   world script.
2. Join the world over the WebSocket and watch the frames. Within a few
   seconds you see `world.phase_changed` with `"phase": "warmup"`, then
   after five seconds another with `"phase": "active"`. Expect repeats of the
   same frame in between; that is the periodic re-send, not a second
   transition.
3. Call `world.list`; the entry carries a `phase` block with the live
   `phase` and `remaining_ms`.

If the phase frames never arrive, confirm the game is a **world** (matches run
phases but do not push them) and that `phases()` returns a list. A non-list
logs a warning and is ignored. If some phases arrive and others do not, check
the [three silent decoder failures](#three-ways-a-phase-list-fails-quietly).

## Next

[Voting](https://asobi.dev/docs/voting) - run a vote inside a phase to let players pick what
happens in the next one.
""".
