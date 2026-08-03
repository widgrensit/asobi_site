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
<p>Asobi ships a periodic-tick matchmaker (<code>asobi_matchmaker</code> gen_server) that
groups tickets into matches using a per-mode strategy module.</p>
<h2 id="how-it-works" tabindex="-1">How It Works</h2>
<ol>
<li>Player submits a matchmaking ticket with a mode and optional properties.</li>
<li>Matchmaker ticks periodically (default every 1 second).</li>
<li>Each tick groups tickets by mode, and the mode's strategy module decides which tickets form a match.</li>
<li>When a group is formed, a match is spawned.</li>
<li>Players are notified via WebSocket (<code>match.matched</code>).</li>
</ol>
<h2 id="submitting-a-ticket" tabindex="-1">Submitting a Ticket</h2>
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
}</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">{ok, TicketId, Meta} = asobi_matchmaker:add(PlayerId, #{mode =&gt; &lt;&lt;"arena"&gt;&gt;, properties =&gt; #{skill =&gt; 1200, region =&gt; &lt;&lt;"eu-west"&gt;&gt;}}).</code></pre></div></div>
<p>The reply (the <code>matchmaker.queued</code> message over WS, the JSON body over REST)
carries <code>ticket_id</code>, <code>status: &quot;pending&quot;</code>, and <strong><code>players_needed</code></strong> — the mode's
<code>match_size</code>, or <code>null</code> if the mode declares none. Show it as &quot;waiting for N
players&quot; so a queued client isn't staring at silence. The <code>Meta</code> map in the
Erlang return holds the same <code>players_needed</code>.</p>
<blockquote>
<p><strong>Testing solo?</strong> A match only forms once <code>match_size</code> players have queued
(default <strong>2</strong> if your mode doesn't set one). One client queuing alone gets
<code>players_needed: 1</code> and then waits forever — that's expected, not a bug. Set
<code>match_size = 1</code> in your mode script to match instantly by yourself, or run
two clients. See <a href="#configuration">Configuration</a> for where <code>match_size</code>
lives and why changing it needs a server restart.</p>
</blockquote>
<blockquote>
<p><strong>Always pass <code>mode</code> as a named/keyed field, never a bare positional
value</strong> — <code>{mode = &quot;arena&quot;}</code> in Lua, <code>mode: &quot;arena&quot;</code> in JSON/TS, a typed
<code>mode</code> parameter elsewhere. A malformed options shape (e.g. Lua's
<code>{&quot;arena&quot;}</code>, which sets index <code>1</code>, not a <code>mode</code> field) silently falls back
to <code>&quot;default&quot;</code> instead of erroring. A multi-mode game gets <code>400 unknown_mode</code>
for it - <code>default</code> is just another key, and a <code>config.lua</code> manifest never
maps it. A <strong>single-mode</strong> game does not: its loader registers <code>default</code>
automatically, so the malformed call silently queues for the only mode
there is, with no error at all - the SDK-level guards below are your only
protection in that case. The Lua SDKs (asobi-defold, asobi-love2d) now
raise a loud error on this exact mistake; the typed SDKs (Dart, Unity,
Unreal, Godot) prevent it at compile/parse time via a required <code>mode</code>
parameter. asobi-js's WS transport is intentionally schema-less (see its
README), so a hand-rolled WS payload there is not protected by any SDK —
double-check the key name if you're sending <code>matchmaker.add</code> by hand.</p>
</blockquote>
<p>A ticket supports <code>mode</code> and <code>properties</code>. A
query-language extension (numeric ranges, required keys, automatic skill
window expansion) is on the roadmap but not shipped — do that filtering
inside your strategy module instead.</p>
<p>The matchmaker holds <strong>one live ticket per player per mode</strong>: submitting again
while already queued returns your existing ticket rather than a second one, so a
double-tapped &quot;find match&quot; cannot match you with yourself. An unregistered
<code>mode</code> is rejected with <code>unknown_mode</code>, and a full queue with <code>queue_full</code>.</p>
<p>If a match cannot start (for example the game's Lua <code>init</code> crashes), the
matchmaker retries a few times, then sends the queued players a
<code>matchmaker_failed</code> event with <code>reason: &quot;match_start_failed&quot;</code> rather than leaving
them queued forever. Handle <code>matchmaker_failed</code> in your client.</p>
<h2 id="strategies" tabindex="-1">Strategies</h2>
<p>Strategy is selected per mode via the <code>strategy</code> key in <code>game_modes</code>. Two
are built in:</p>
<ul>
<li><code>fill</code> (default) — first-come-first-matched, groups players in submission
order until <code>match_size</code> is reached.</li>
<li><code>skill_based</code> — sorts tickets by <code>properties.skill</code> and pairs within an
expanding window (configurable via <code>skill_window</code> and
<code>skill_expand_rate</code>).</li>
</ul>
<p>Select one with the <code>strategy</code> global in your mode script:</p>
<pre><code class="language-lua">-- ranked.lua
match_size = 4
strategy   = &quot;skill_based&quot;   -- &quot;fill&quot; (default) or &quot;skill_based&quot;
</code></pre>
<p>The built-in strategies map to modules: <code>fill</code> is <code>asobi_matchmaker_fill</code>
and <code>skill_based</code> is <code>asobi_matchmaker_skill</code>. Strategy is configured per
game mode only - there is no top-level <code>matchmaker_strategy</code> key.</p>
<p><strong>Writing a new strategy is Erlang only.</strong> <code>strategy</code> takes either a
built-in name or an Erlang module name, and there is no Lua callback for
grouping tickets. If your matching rules do not fit <code>fill</code> or
<code>skill_based</code>, you need an Erlang module in the release alongside your Lua
scripts.</p>
<h2 id="custom-strategies-erlang" tabindex="-1">Custom Strategies (Erlang)</h2>
<p>Implement <code>asobi_matchmaker_strategy</code> (a single <code>match/2</code> callback):</p>
<pre><code class="language-erlang">-module(my_matchmaker).
-behaviour(asobi_matchmaker_strategy).

-export([match/2]).

-spec match([map()], map()) -&gt; {[[map()]], [map()]}.
match(Tickets, Config) -&gt;
    Size = maps:get(match_size, Config, 4),
    %% Return {Matched, Unmatched}, where Matched is a list of
    %% groups (each group a list of tickets that form a match).
    group_by_size(Tickets, Size).
</code></pre>
<p>Wire it up per mode:</p>
<div class="tabbed-code"><input type="radio" name="mm-tab1" id="mm-tab1-1" checked><div class="tabbed-code-labels" role="tablist"><label for="mm-tab1-1">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-erlang">{asobi, [
    {game_modes, #{
        ~"ranked" =&gt; #{
            module     =&gt; my_arena,
            match_size =&gt; 4,
            strategy   =&gt; my_matchmaker
        }
    }}
]}</code></pre></div></div>
<h2 id="configuration" tabindex="-1">Configuration</h2>
<pre><code class="language-erlang">{asobi, [
    {matchmaker, #{
        tick_interval =&gt; 1000,       %% ms between matchmaker ticks
        max_wait_seconds =&gt; 60,      %% max wait before timeout
        max_queue =&gt; 10000           %% max live tickets before add returns queue_full
    }}
]}
</code></pre>
<p><code>match_size</code>, <code>strategy</code>, and the rest of a mode's shape are read into
<code>game_modes</code> <strong>once at server boot</strong>. Editing them in a mode script and
hot-reloading does not change them for the matchmaker — restart the server to
pick up a new <code>match_size</code> (see the solo-testing note above if you just want
to test alone).</p>
<h2 id="playing-with-friends" tabindex="-1">Playing With Friends</h2>
<blockquote>
<p>Gathering players before a game starts is covered in <a href="https://hexdocs.pm/asobi/lobbies.html">Lobbies</a>.</p>
</blockquote>
<p>The matchmaker has no party grouping. It queues individual players, and a
ticket cannot bring other players with it.</p>
<p>To play with someone specific, skip the queue: create a match or world,
share its id or a join code out of band, and have them join directly. Gate
entry by implementing <code>join/3</code> in your game module and checking the join
context - see <a href="/docs/protocols/websocket#join-context">WebSocket Protocol</a>. To
let friends find your session in a browser instead, see
<a href="/docs/world-server">World Server</a>.</p>
<p>Matchmaker-mediated party grouping would mean weighting tickets by party
size, which changes what <code>match_size</code> means for every strategy module. It
is not shipped, and a <code>party</code> field on a ticket is not accepted.</p>
<h2 id="cancelling" tabindex="-1">Cancelling</h2>
<div class="tabbed-code"><input type="radio" name="mm-tab2" id="mm-tab2-1" checked><input type="radio" name="mm-tab2" id="mm-tab2-2"><div class="tabbed-code-labels" role="tablist"><label for="mm-tab2-1">WebSocket (JSON)</label><label for="mm-tab2-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-json">{"type": "matchmaker.remove", "payload": {"ticket_id": "..."}}</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">asobi_matchmaker:remove(PlayerId, TicketId).</code></pre></div></div>
<p>Or via REST:</p>
<pre><code class="language-bash">curl -X DELETE http://localhost:8084/api/v1/matchmaker/&lt;ticket_id&gt; \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/websocket">WebSocket protocol</a> - the <code>matchmaker.*</code> and <code>match.matched</code> messages.</li>
<li><a href="/docs/configuration">Configuration</a> - per-mode matchmaker tuning.</li>
</ul>
"""}
    ]}.
