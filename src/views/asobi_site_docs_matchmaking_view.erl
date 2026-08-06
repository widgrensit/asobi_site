%% GENERATED from asobi guides/matchmaking.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_matchmaking_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-matchmaking", title => ~"Matchmaking — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Matchmaking"
        ]},
        {h1, [], [~"Matchmaking"]},
        {raw,
            ~"""
<p>asobi ships a periodic-tick matchmaker (<code>asobi_matchmaker</code>) that groups tickets
into matches using a per-mode strategy module.</p>
<h2 id="how-it-works" tabindex="-1">How it works</h2>
<ol>
<li>A player submits a ticket with a mode and optional properties.</li>
<li>The matchmaker ticks every <code>tick_interval</code> (1 second by default).</li>
<li>Each tick groups tickets by mode, and the mode's strategy decides which
tickets form a match.</li>
<li>When a group forms, a match or a world is spawned.</li>
<li>Players are notified over the WebSocket as <code>match.matched</code>.</li>
</ol>
<h2 id="submitting-a-ticket" tabindex="-1">Submitting a ticket</h2>
<h3 id="via-rest" tabindex="-1">Via REST</h3>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/matchmaker \
  -H 'Authorization: Bearer &lt;token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{
    &quot;mode&quot;: &quot;arena&quot;,
    &quot;properties&quot;: {&quot;skill&quot;: 1200, &quot;region&quot;: &quot;eu-west&quot;}
  }'
</code></pre>
<h3 id="via-websocket" tabindex="-1">Via WebSocket</h3>
<div class="tabbed-code"><input type="radio" name="mm-tab0" id="mm-tab0-1" checked><input type="radio" name="mm-tab0" id="mm-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="mm-tab0-1">WebSocket (JSON)</label><label for="mm-tab0-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-json">{
  "type": "matchmaker.add",
  "payload": {
    "mode": "arena",
    "properties": {"skill": 1200, "region": "eu-west"}
  }
}</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">{ok, TicketId, Meta} = asobi_matchmaker:add(PlayerId, #{mode =&gt; ~"arena", properties =&gt; #{skill =&gt; 1200, region =&gt; ~"eu-west"}}).</code></pre></div></div>
<p>The reply - the <code>matchmaker.queued</code> frame over WS, the JSON body over REST -
carries <code>ticket_id</code>, <code>status: &quot;pending&quot;</code> and <code>players_needed</code>: the mode's
<code>match_size</code>, or <code>null</code> if the mode declares none. Show it as &quot;waiting for N
players&quot; so a queued client is not staring at silence. The <code>Meta</code> map in the
Erlang return holds the same <code>players_needed</code>.</p>
<h3 id="testing-solo" tabindex="-1">Testing solo</h3>
<p>A match forms only once <code>match_size</code> players have queued, and a mode that
declares no <code>match_size</code> groups in twos: <code>fill</code> falls back to 2, and
<code>players_needed</code> comes back <code>null</code> because the mode itself declared nothing.
One client queuing alone therefore waits.</p>
<p>It does not wait forever. After <code>max_wait_seconds</code> (60 by default) the ticket
expires and that player receives</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.matchmaker_expired&quot;, &quot;payload&quot;: {&quot;ticket_id&quot;: &quot;...&quot;}}
</code></pre>
<p>Handle that frame - a client that only listens for <code>match.matched</code> looks hung
for a minute and then stays hung. To match instantly by yourself, set
<code>match_size = 1</code> in your mode script; the change is picked up within about a
second and a half (see <a href="#configuration">Configuration</a>).</p>
<h3 id="always-pass-mode-as-a-named-field" tabindex="-1">Always pass <code>mode</code> as a named field</h3>
<p><code>{mode = &quot;arena&quot;}</code> in Lua, <code>mode: &quot;arena&quot;</code> in JSON/TS, a typed <code>mode</code> parameter
elsewhere. A malformed options shape - Lua's <code>{&quot;arena&quot;}</code>, which sets index <code>1</code>
rather than a <code>mode</code> field - silently falls back to <code>&quot;default&quot;</code>.</p>
<p>A multi-mode game gets <code>matchmaker.unknown_mode</code> for it: <code>default</code> is just
another key, and a <code>config.lua</code> manifest never maps it. A single-mode game does
not, because its loader registers <code>default</code> automatically, so the malformed call
silently queues for the only mode there is. The Lua SDKs (asobi-defold,
asobi-love2d) raise a loud error on this exact mistake; the typed SDKs (Dart,
Unity, Unreal, Godot) prevent it at compile time via a required <code>mode</code>
parameter. asobi-js's WS transport is intentionally schema-less, so a
hand-rolled <code>matchmaker.add</code> payload there is not protected by any SDK.</p>
<p>A ticket supports <code>mode</code> and <code>properties</code> only. There is no query language for
numeric ranges, required keys or automatic skill-window expansion - do that
filtering inside your strategy module.</p>
<p>The matchmaker holds one live ticket per player per mode: submitting again while
already queued returns the existing ticket rather than a second one, so a
double-tapped &quot;find match&quot; cannot match you with yourself. An unregistered mode
is rejected with <code>matchmaker.unknown_mode</code>, and a full queue with
<code>matchmaker.queue_full</code>.</p>
<h2 id="checking-a-ticket" tabindex="-1">Checking a ticket</h2>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/matchmaker/&lt;ticket_id&gt; \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<pre><code class="language-json">{&quot;id&quot;: &quot;...&quot;, &quot;mode&quot;: &quot;arena&quot;, &quot;status&quot;: &quot;pending&quot;, &quot;properties&quot;: {}, &quot;submitted_at&quot;: 1711700000000}
</code></pre>
<p>The lookup is owner-scoped: another player's ticket id answers <code>403 forbidden</code>,
an unknown one <code>404 matchmaker.ticket_not_found</code>.</p>
<h2 id="when-formation-fails" tabindex="-1">When formation fails</h2>
<p>Two different stories, because matches and worlds are spawned differently.</p>
<p>A <strong>match</strong> that fails to spawn - the game's Lua <code>init</code> crashed, say - is
re-queued and retried. After three attempts the group is given up on and each
player receives <code>match.matchmaker_failed</code>.</p>
<p>A <strong>world</strong> spawn is detached from the matchmaker tick so a slow world cannot
stall the queue, which leaves no handle to re-queue the group. Worlds therefore
fail fast: the first error or crash notifies the players once, with no retry.</p>
<p>Both paths use one of two coarse reasons, and neither ever carries the raw
crash:</p>
<table>
<thead>
<tr>
<th><code>reason</code></th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>match_start_failed</code></td>
<td>The match or world could not be started, or the join fan-out crashed</td>
</tr>
<tr>
<td><code>no_game_module</code></td>
<td>The mode resolves to no game module - unconfigured, or a Lua mode in a release with no scripting runtime</td>
</tr>
</tbody>
</table>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.matchmaker_failed&quot;, &quot;payload&quot;: {&quot;reason&quot;: &quot;match_start_failed&quot;}}
</code></pre>
<p>Handle <code>match.matchmaker_failed</code> in your client alongside
<code>match.matchmaker_expired</code>.</p>
<h2 id="strategies" tabindex="-1">Strategies</h2>
<p>Strategy is selected per mode via the <code>strategy</code> key. Two are built in:</p>
<ul>
<li><code>fill</code> (default) - first-come-first-matched, grouping players in submission
order until <code>match_size</code> is reached.</li>
<li><code>skill_based</code> - sorts tickets by <code>properties.skill</code> and pairs within an
expanding window (<code>skill_window</code>, <code>skill_expand_rate</code>).</li>
</ul>
<pre><code class="language-lua">-- ranked.lua
match_size = 4
strategy   = &quot;skill_based&quot;   -- &quot;fill&quot; (default) or &quot;skill_based&quot;
</code></pre>
<p>The names map to <code>asobi_matchmaker_fill</code> and <code>asobi_matchmaker_skill</code>. Strategy
is per game mode only; there is no top-level <code>matchmaker_strategy</code> key.</p>
<p>Writing a new strategy is Erlang only. <code>strategy</code> takes either a built-in name
or an Erlang module name, and there is no Lua callback for grouping tickets. If
your rules fit neither built-in, you need a module in the release alongside your
Lua scripts.</p>
<h3 id="in-erlang" tabindex="-1">In Erlang</h3>
<p>Implement <code>asobi_matchmaker_strategy</code>, a single <code>match/2</code> callback:</p>
<pre><code class="language-erlang">-module(my_matchmaker).
-behaviour(asobi_matchmaker_strategy).

-export([match/2]).

-spec match([map()], map()) -&gt; {[[map()]], [map()]}.
match(Tickets, Config) -&gt;
    Size = maps:get(match_size, Config, 4),
    %% {Matched, Unmatched}, where Matched is a list of groups and each
    %% group is a list of tickets that form one match.
    group_by_size(Tickets, Size).
</code></pre>
<p>Wire it up per mode, from Erlang:</p>
<pre><code class="language-erlang">{asobi, [
    {game_modes, #{
        ~&quot;ranked&quot; =&gt; #{
            module     =&gt; my_arena,
            match_size =&gt; 4,
            strategy   =&gt; my_matchmaker
        }
    }}
]}
</code></pre>
<p>A Lua <code>strategy</code> global resolves <code>&quot;fill&quot;</code> and <code>&quot;skill_based&quot;</code> and nothing else.
Any other name stays a string, misses the module lookup and falls back to
<code>fill</code> without a word, so a custom strategy cannot be named from a mode
script.</p>
<p>A group that repeats the same player is dropped back to the queue rather than
spawning a degenerate self-match, whatever a strategy returns.</p>
<h2 id="configuration" tabindex="-1">Configuration</h2>
<pre><code class="language-erlang">{asobi, [
    {matchmaker, #{
        tick_interval =&gt; 1000,       %% ms between matchmaker ticks
        max_wait_seconds =&gt; 60,      %% ticket lifetime before it expires
        max_queue =&gt; 10000           %% live tickets before add returns queue_full
    }}
]}
</code></pre>
<p><code>match_size</code>, <code>strategy</code> and the rest of a mode's shape are read into
<code>game_modes</code> at boot, and a config watcher polls the manifest and each mode
script for changes. With the default reload mode, editing <code>match_size</code> in a
mode script is picked up for <strong>new</strong> matches within about 1.5 seconds. Matches
already running keep the <code>match_size</code> they formed with.</p>
<p>A restart is needed in two cases: a sealed bundle, where <code>reload_mode</code> is <code>off</code>
or <code>ASOBI_LUA_RELOAD=off</code> and the watcher never polls at all; and a game whose
<code>game_modes</code> live in an Erlang <code>sys.config</code> rather than in Lua, which nothing
rescans.</p>
<h2 id="per-node" tabindex="-1">Per node</h2>
<p>The matchmaker queue is per node. Tickets live in one gen_server's own state -
there is no ticket table in Postgres - so players queuing against different
nodes never match each other, and a restart drops every waiting ticket. Behind a
load balancer this is the fact that decides whether matchmaking works at all;
see <a href="/docs/clustering">Clustering</a>.</p>
<h2 id="playing-with-friends" tabindex="-1">Playing with friends</h2>
<p>Gathering players before a game starts is covered in <a href="https://hexdocs.pm/asobi/lobbies.html">Lobbies</a>.</p>
<p>The matchmaker has no party grouping. It queues individual players, a ticket
cannot bring others with it, and a <code>party</code> field on a ticket is not accepted.
Party weighting would change what <code>match_size</code> means for every strategy module,
which is why it is not shipped. A game that needs it can add the grouping call
as an extension method and reach it over the <code>rpc.call</code> frame - see
<a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</p>
<p>To play with someone specific, skip the queue. <strong>Worlds are the only session a
client can create</strong>: <code>world.create</code> over the WebSocket, or
<code>POST /api/v1/worlds</code>. Share the returned <code>world_id</code> or a join code out of band
and have them <code>world.join</code> it. Matches are created by the matchmaker or by an
Erlang caller inside the release, and by nothing else - there is no
<code>match.create</code> frame and no <code>POST /api/v1/matches</code>.</p>
<p>Gate entry by implementing <code>join/3</code> in your game module and checking the join
context - see <a href="/docs/protocols/websocket#join-context">WebSocket protocol</a>. To let
friends find your session in a browser instead, see
<a href="/docs/world-server">World server</a>.</p>
<h2 id="cancelling" tabindex="-1">Cancelling</h2>
<div class="tabbed-code"><input type="radio" name="mm-tab1" id="mm-tab1-1" checked><input type="radio" name="mm-tab1" id="mm-tab1-2"><div class="tabbed-code-labels" role="tablist"><label for="mm-tab1-1">WebSocket (JSON)</label><label for="mm-tab1-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-json">{"type": "matchmaker.remove", "payload": {"ticket_id": "..."}}</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">asobi_matchmaker:remove(PlayerId, TicketId).</code></pre></div></div>
<p>Or over REST:</p>
<pre><code class="language-bash">curl -X DELETE http://localhost:8084/api/v1/matchmaker/&lt;ticket_id&gt; \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<h2 id="watching-the-queue" tabindex="-1">Watching the queue</h2>
<p>The console has a Matchmaker screen: one row per mode, deepest queue first. It
reads the queue and cannot act on it - there is no cancel-ticket button, and the
numbers are this node's queue only. See <a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/websocket">WebSocket protocol</a> - the <code>matchmaker.*</code> and <code>match.*</code> frames.</li>
<li><a href="/docs/configuration">Configuration</a> - per-mode matchmaker tuning.</li>
<li><a href="/docs/clustering">Clustering</a> - what a second node does to the queue.</li>
</ul>
"""}
    ]}.
