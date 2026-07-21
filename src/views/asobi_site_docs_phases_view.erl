%% GENERATED from asobi guides/phases.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_phases_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

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
        {h1, [], [~"Phases and seasons"]},
        {raw,
            ~"""
<p>Two clocks, different scopes.</p>
<p>A <strong>phase</strong> is a stage in one session's lifecycle - lobby, then play, then
results - inside a single match or world. It starts and ends with that
session and is authored in the game script.</p>
<p>A <strong>season</strong> is a wall-clock window across the whole deployment - a
fortnight of ranked play, a themed event - shared by every session. It
lives in the database and is read by game logic.</p>
<p>They do not interact. This guide covers both because a reader who sees
<code>phase</code> on a <code>world.list</code> response, or hears &quot;season&quot;, lands here.</p>
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
shape. See the callback reference for the full callback list.</p>
<h3 id="what-the-client-sees-on-the-wire" tabindex="-1">What the client sees on the wire</h3>
<p>A <strong>world</strong> pushes <code>world.phase_changed</code> on every transition and again
roughly every three seconds while a phase runs. The payload is the phase
info block:</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;world.phase_changed&quot;,
  &quot;payload&quot;: {
    &quot;status&quot;: &quot;active&quot;,
    &quot;phase&quot;: &quot;combat&quot;,
    &quot;remaining_ms&quot;: 118400,
    &quot;config&quot;: {},
    &quot;world_id&quot;: &quot;...&quot;
  }
}
</code></pre>
<p>A <strong>match</strong> does not push a phase event. The match server runs the phase
clock and your callbacks, but the client learns the phase by reading the
<code>phase</code> block on the listing and join reply - <code>status</code>, <code>phase</code>,
<code>remaining_ms</code> and the pending <code>start_condition</code>. Broadcast anything richer
yourself from <code>on_phase_started</code>.</p>
<p>See <a href="/docs/protocols/websocket#worldphase_changed-server-push">WebSocket protocol</a>
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
<h2 id="seasons" tabindex="-1">Seasons</h2>
<p>A season is a named, dated window stored in the <code>seasons</code> table. A
background manager checks the clock once a minute and moves each season
<code>upcoming -&gt; active -&gt; ended</code> as its <code>starts_at</code> and <code>ends_at</code> pass. Exactly
the parts of a game you want gated on &quot;the current event&quot; - a ranked ladder,
a reward set - key off the active season.</p>
<p>Seasons are a server-side primitive today. There is no Lua binding, no
WebSocket event and no REST endpoint. You seed a season row into the
database and read it from Erlang game logic.</p>
<h3 id="seed-a-season" tabindex="-1">Seed a season</h3>
<p>A season is one row. <code>starts_at</code> and <code>ends_at</code> are millisecond epochs.</p>
<pre><code class="language-erlang">Now = erlang:system_time(millisecond),
CS = kura_changeset:cast(asobi_season, #{}, #{
    name      =&gt; ~&quot;Spring Ladder&quot;,
    starts_at =&gt; Now,
    ends_at   =&gt; Now + 14 * 24 * 60 * 60 * 1000,
    status    =&gt; ~&quot;active&quot;,
    config    =&gt; #{theme =&gt; ~&quot;spring&quot;},
    rewards   =&gt; #{top10 =&gt; ~&quot;gold_frame&quot;}
}, [name, starts_at, ends_at, status, config, rewards]),
{ok, _} = asobi_repo:insert(CS).
</code></pre>
<p>Where that row goes differs by deployment:</p>
<p><strong>Cloud.</strong> The per-project database is provisioned for you and the <code>seasons</code>
table already exists. Open a console against your project
(<code>console.asobi.dev</code>) and insert the row - or run the snippet above from a
release remote shell attached to your project's node.</p>
<p><strong>Self-hosted.</strong> Point <code>ASOBI_*</code> at your own Postgres, apply migrations so
the <code>seasons</code> table exists (<code>rebar3 kura migrate</code>), then insert the row from
your release's remote shell. See <a href="/docs/configuration">Configuration</a> for the
<code>ASOBI_*</code> database variables.</p>
<p>Once the row exists the season manager runs the same on both: it flips
<code>status</code> by wall clock with no further action from you.</p>
<h3 id="read-the-active-season-from-game-logic" tabindex="-1">Read the active season from game logic</h3>
<pre><code class="language-erlang">case asobi_season:current() of
    {ok, #{name := Name, rewards := Rewards}} -&gt;
        %% gate ranked play, pick the reward table, etc.
        {ranked, Name, Rewards};
    {error, no_active_season} -&gt;
        casual
end.
</code></pre>
<p>Other queries: <code>asobi_season:config(Key)</code> pulls one key from the active
season's <code>config</code>; <code>upcoming/0</code> and <code>history/0</code> list scheduled and past
seasons; <code>time_remaining/0</code> returns milliseconds left in the active season
(or <code>infinity</code> if none is active).</p>
<p>To surface the season to players, read it in your game module and put it in
the state you already send - there is no season frame to subscribe to.</p>
<h2 id="checkpoint" tabindex="-1">Checkpoint</h2>
<p>Phases, with a Lua world game running locally:</p>
<ol>
<li>Add a <code>phases()</code> returning <code>warmup</code> (5000) then <code>active</code> (10000) to your
world script.</li>
<li>Join the world over the WebSocket and watch the frames. Within a few
seconds you see <code>world.phase_changed</code> with <code>&quot;phase&quot;: &quot;warmup&quot;</code>, then
after five seconds another with <code>&quot;phase&quot;: &quot;active&quot;</code>.</li>
<li>Call <code>world.list</code>; the entry carries a <code>phase</code> block with the live
<code>phase</code> and <code>remaining_ms</code>.</li>
</ol>
<p>Seasons:</p>
<ol>
<li>Insert a season row with <code>status = &quot;active&quot;</code> and an <code>ends_at</code> a minute
out (cloud console, or self-hosted remote shell as above).</li>
<li>From a remote shell, <code>asobi_season:current()</code> returns <code>{ok, Season}</code> and
<code>asobi_season:time_remaining()</code> counts down.</li>
<li>Wait past <code>ends_at</code>; within a minute the manager logs <code>season_ended</code> and
<code>current()</code> returns <code>{error, no_active_season}</code>.</li>
</ol>
<p>If the phase frames never arrive, confirm the game is a <strong>world</strong> (matches
run phases but do not push them) and that <code>phases()</code> returns a list. A
non-list logs a warning and is ignored.</p>
<h2 id="next" tabindex="-1">Next</h2>
<p><a href="/docs/voting">Voting</a> - run a vote inside a phase to let players pick what
happens in the next one.</p>
"""}
    ]}.
