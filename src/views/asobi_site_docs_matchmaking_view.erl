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
}</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">{ok, TicketId} = asobi_matchmaker:add(PlayerId, #{mode =&gt; &lt;&lt;"arena"&gt;&gt;, properties =&gt; #{skill =&gt; 1200, region =&gt; &lt;&lt;"eu-west"&gt;&gt;}}).</code></pre></div></div>
<p>A ticket supports <code>mode</code> and <code>properties</code>. A
query-language extension (numeric ranges, required keys, automatic skill
window expansion) is on the roadmap but not shipped — do that filtering
inside your strategy module instead.</p>
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
        max_wait_seconds =&gt; 60       %% max wait before timeout
    }}
]}
</code></pre>
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
