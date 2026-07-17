%% GENERATED from asobi guides/voting.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_voting_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-voting", title => ~"Voting — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Voting"
        ]},
        {h1, [], [~"Voting"]},
        {raw,
            ~"""
<p>Asobi includes an in-match voting system for roguelike-style group decisions
such as path selection, item picks, event choices, and run modifiers.</p>
<h2 id="how-it-works" tabindex="-1">How It Works</h2>
<ol>
<li>Game mode (or match server) starts a vote with options and a timed window</li>
<li>Eligible players receive a <code>match.vote_start</code> event via WebSocket</li>
<li>Players cast votes during the window</li>
<li>When the window expires, votes are tallied and the result is broadcast</li>
<li>The game mode receives the result via the <code>vote_resolved/3</code> callback</li>
</ol>
<h2 id="starting-a-vote" tabindex="-1">Starting a Vote</h2>
<p>There are two ways to start a vote:</p>
<h3 id="automatic-via-vote_requested-callback" tabindex="-1">Automatic (via <code>vote_requested</code> callback)</h3>
<p>The match server polls the <code>vote_requested/1</code> callback after every tick. Return
a vote config to start a vote, or <code>none</code>/<code>nil</code> to skip. This is the simplest
approach and works for both Erlang and Lua game modules. Votes can be triggered
at any point during gameplay - not just between rounds.</p>
<div class="tabbed-code"><input type="radio" name="vote-tab0" id="vote-tab0-1" checked><input type="radio" name="vote-tab0" id="vote-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="vote-tab0-1">Lua</label><label for="vote-tab0-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">function vote_requested(state)
    return { method = "plurality", options = {"map_a", "map_b"}, window_ms = 15000 }
end</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">vote_requested(#{phase := vote_pending} = _GameState) -&gt;
    {ok, #{
        template =&gt; ~"path_choice",
        options =&gt; [
            #{id =&gt; ~"jungle", label =&gt; ~"Jungle Path"},
            #{id =&gt; ~"volcano", label =&gt; ~"Volcano Path"}
        ],
        window_ms =&gt; 15000,
        method =&gt; ~"plurality"
    }};
vote_requested(_) -&gt;
    none.</code></pre></div></div>
<p>When a vote starts this way, the optional <code>vote_started/1</code> callback is called
to let the game module update its state (e.g. change phase).</p>
<h3 id="manual-via-match-server-api" tabindex="-1">Manual (via match server API)</h3>
<p>Votes can also be started explicitly from a game mode callback:</p>
<pre><code class="language-erlang">%% From inside a game module callback
asobi_match_server:start_vote(MatchPid, #{
    template =&gt; ~&quot;path_choice&quot;,
    options =&gt; [
        #{id =&gt; ~&quot;jungle&quot;, label =&gt; ~&quot;Jungle Path&quot;},
        #{id =&gt; ~&quot;volcano&quot;, label =&gt; ~&quot;Volcano Path&quot;},
        #{id =&gt; ~&quot;caves&quot;, label =&gt; ~&quot;Ice Caves&quot;}
    ],
    window_ms =&gt; 15000,
    method =&gt; ~&quot;plurality&quot;,
    visibility =&gt; ~&quot;live&quot;
}).
</code></pre>
<h3 id="config-options" tabindex="-1">Config Options</h3>
<table>
<thead>
<tr>
<th>Key</th>
<th>Type</th>
<th>Default</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>options</code></td>
<td><code>[map()]</code></td>
<td>required</td>
<td>List of <code>#{id, label}</code> option maps</td>
</tr>
<tr>
<td><code>template</code></td>
<td><code>binary()</code></td>
<td><code>&quot;default&quot;</code></td>
<td>Template name (resolved from config)</td>
</tr>
<tr>
<td><code>window_ms</code></td>
<td><code>pos_integer()</code></td>
<td><code>15000</code></td>
<td>Vote window in milliseconds</td>
</tr>
<tr>
<td><code>method</code></td>
<td><code>binary()</code></td>
<td><code>&quot;plurality&quot;</code></td>
<td><code>&quot;plurality&quot;</code>, <code>&quot;approval&quot;</code>, <code>&quot;weighted&quot;</code>, or <code>&quot;ranked&quot;</code></td>
</tr>
<tr>
<td><code>visibility</code></td>
<td><code>binary()</code></td>
<td><code>&quot;live&quot;</code></td>
<td><code>&quot;live&quot;</code> or <code>&quot;hidden&quot;</code></td>
</tr>
<tr>
<td><code>tie_breaker</code></td>
<td><code>binary()</code></td>
<td><code>&quot;random&quot;</code></td>
<td><code>&quot;random&quot;</code> or <code>&quot;first&quot;</code></td>
</tr>
<tr>
<td><code>veto_enabled</code></td>
<td><code>boolean()</code></td>
<td><code>false</code></td>
<td>Allow players to veto</td>
</tr>
<tr>
<td><code>weights</code></td>
<td><code>map()</code></td>
<td><code>#{}</code></td>
<td>Voter weights for <code>&quot;weighted&quot;</code> method</td>
</tr>
<tr>
<td><code>max_revotes</code></td>
<td><code>pos_integer()</code></td>
<td><code>3</code></td>
<td>Max times a voter can change their vote</td>
</tr>
</tbody>
</table>
<p>The match server automatically fills in <code>match_id</code>, <code>match_pid</code>, and
<code>eligible</code> (all current players) when starting the vote.</p>
<h2 id="voting-methods" tabindex="-1">Voting Methods</h2>
<h3 id="plurality" tabindex="-1">Plurality</h3>
<p>Each player picks exactly one option. The option with the most votes wins.
Ties are broken by the configured <code>tie_breaker</code> strategy.</p>
<h3 id="approval" tabindex="-1">Approval</h3>
<p>Each player submits a list of all options they approve of. The option with
the highest total approval count wins. Good for &quot;avoid the worst option&quot;
scenarios.</p>
<h3 id="weighted" tabindex="-1">Weighted</h3>
<p>Each vote is multiplied by the voter's weight. Pass weights via config:</p>
<pre><code class="language-erlang">asobi_match_server:start_vote(MatchPid, #{
    options =&gt; Options,
    method =&gt; ~&quot;weighted&quot;,
    weights =&gt; #{~&quot;player1&quot; =&gt; 3, ~&quot;player2&quot; =&gt; 1}
}).
</code></pre>
<p>Players not in the weights map default to weight 1. Useful for
performance-based voting or role-based voting.</p>
<h3 id="ranked-choice" tabindex="-1">Ranked Choice</h3>
<p>Each player submits a ranked list. The option with fewest first-choice votes
is eliminated each round, and those votes transfer to the next preference.
Continues until one option has a majority.</p>
<pre><code class="language-erlang">asobi_match_server:start_vote(MatchPid, #{
    options =&gt; Options,
    method =&gt; ~&quot;ranked&quot;
}).
</code></pre>
<p>Clients send a list for <code>option_id</code>:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.cast&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;, &quot;option_id&quot;: [&quot;jungle&quot;, &quot;caves&quot;, &quot;volcano&quot;]}}
</code></pre>
<p>Live tallies show first-choice counts. The final result includes the winner
after all elimination rounds.</p>
<h2 id="spectator-voting" tabindex="-1">Spectator Voting</h2>
<p>Spectators are a separate voter pool whose votes are merged with player
votes using a configurable weight ratio.</p>
<pre><code class="language-erlang">asobi_match_server:start_vote(MatchPid, #{
    options =&gt; Options,
    spectators =&gt; [~&quot;spec1&quot;, ~&quot;spec2&quot;, ~&quot;spec3&quot;],
    spectator_weight =&gt; 0.3  %% spectators get 30% influence, players 70%
}).
</code></pre>
<p>Both pools are tallied independently, normalized, then merged:
<code>score = player_normalized * (1 - spectator_weight) + spectator_normalized * spectator_weight</code></p>
<p>For spectator-only votes (audience decides), set <code>eligible =&gt; []</code> and
<code>spectator_weight =&gt; 1.0</code>.</p>
<h2 id="async-voting" tabindex="-1">Async Voting</h2>
<p>For non-real-time games where not all players are online simultaneously.</p>
<h3 id="quorum" tabindex="-1">Quorum</h3>
<p>Require a minimum fraction of eligible voters before the result is valid:</p>
<pre><code class="language-erlang">#{quorum =&gt; 0.5}  %% at least 50% must vote
</code></pre>
<p>If quorum is not met when the window expires, the result has
<code>winner =&gt; undefined</code> and <code>status =&gt; &quot;no_quorum&quot;</code>.</p>
<h3 id="default-votes" tabindex="-1">Default Votes</h3>
<p>Set fallback votes for players who don't participate:</p>
<pre><code class="language-erlang">#{default_votes =&gt; #{~&quot;player2&quot; =&gt; ~&quot;opt_b&quot;, ~&quot;player3&quot; =&gt; ~&quot;opt_a&quot;}}
</code></pre>
<p>Defaults are applied at resolution time only — they don't count as active
votes during the window. Players who vote explicitly override their default.</p>
<h3 id="delegation" tabindex="-1">Delegation</h3>
<p>Let a player's vote follow another player's choice:</p>
<pre><code class="language-erlang">#{delegation =&gt; #{~&quot;player3&quot; =&gt; ~&quot;player1&quot;}}
</code></pre>
<p>If player3 doesn't vote but player1 voted for <code>opt_a</code>, player3's vote
becomes <code>opt_a</code> at resolution time. If the delegate also didn't vote,
no vote is added.</p>
<h2 id="vote-templates" tabindex="-1">Vote Templates</h2>
<p>Define reusable vote configurations in your app config. Per-call config
overrides template defaults:</p>
<pre><code class="language-erlang">{asobi, [
    {vote_templates, #{
        ~&quot;boon_pick&quot; =&gt; #{method =&gt; ~&quot;plurality&quot;, window_ms =&gt; 15000, visibility =&gt; ~&quot;live&quot;},
        ~&quot;path_choice&quot; =&gt; #{method =&gt; ~&quot;approval&quot;, window_ms =&gt; 20000, visibility =&gt; ~&quot;hidden&quot;},
        ~&quot;weighted_pick&quot; =&gt; #{method =&gt; ~&quot;weighted&quot;, window_ms =&gt; 15000}
    }}
]}
</code></pre>
<p>Then start a vote with just the template name and options:</p>
<pre><code class="language-erlang">asobi_match_server:start_vote(MatchPid, #{
    template =&gt; ~&quot;boon_pick&quot;,
    options =&gt; Options
}).
</code></pre>
<h2 id="window-types" tabindex="-1">Window Types</h2>
<p>The <code>window_type</code> config controls when a vote closes. All types have a
maximum <code>window_ms</code> timeout as a safety net.</p>
<h3 id="fixed-default" tabindex="-1">Fixed (default)</h3>
<p>Vote runs for exactly <code>window_ms</code>, then closes. Simple and predictable.</p>
<pre><code class="language-erlang">#{window_type =&gt; ~&quot;fixed&quot;, window_ms =&gt; 15000}
</code></pre>
<h3 id="ready-up" tabindex="-1">Ready-up</h3>
<p>Closes as soon as all eligible voters have cast a vote, or when <code>window_ms</code>
expires. Best for small groups where everyone is engaged.</p>
<pre><code class="language-erlang">#{window_type =&gt; ~&quot;ready_up&quot;, window_ms =&gt; 30000}
</code></pre>
<h3 id="hybrid" tabindex="-1">Hybrid</h3>
<p>Like ready-up, but enforces a minimum <code>min_window_ms</code> before early close.
Prevents snap decisions while still closing early once everyone votes.</p>
<pre><code class="language-erlang">#{window_type =&gt; ~&quot;hybrid&quot;, window_ms =&gt; 30000, min_window_ms =&gt; 5000}
</code></pre>
<h3 id="adaptive" tabindex="-1">Adaptive</h3>
<p>Starts with full <code>window_ms</code>, but when a supermajority threshold is reached,
the remaining time shrinks to 3 seconds. Gives latecomers a last chance
without forcing everyone to wait.</p>
<pre><code class="language-erlang">#{window_type =&gt; ~&quot;adaptive&quot;, window_ms =&gt; 20000, supermajority =&gt; 0.75}
</code></pre>
<p>If the supermajority is lost (e.g. someone changes their vote), the timer
resets to the original remaining time.</p>
<h2 id="rate-limiting" tabindex="-1">Rate Limiting</h2>
<p>Voters can change their vote during the window, but are limited to
<code>max_revotes</code> changes (default 3). After that, <code>{error, rate_limited}</code> is
returned. The initial vote does not count against the limit.</p>
<h2 id="game-mode-integration" tabindex="-1">Game Mode Integration</h2>
<p>Implement the optional <code>asobi_match</code> callbacks to react to vote results:</p>
<pre><code class="language-erlang">-module(my_roguelike).
-behaviour(asobi_match).

%% ... init/1, join/2, leave/2, handle_input/3, get_state/2 ...

vote_resolved(~&quot;path_choice&quot;, #{winner := WinnerId}, GameState) -&gt;
    %% Apply the voted path to game state
    {ok, GameState#{current_path =&gt; WinnerId}};
vote_resolved(~&quot;item_pick&quot;, #{winner := ItemId}, GameState) -&gt;
    {ok, add_item(ItemId, GameState)}.
</code></pre>
<p>Both callbacks are optional. If <code>vote_resolved/3</code> is not implemented, the
vote still runs and broadcasts results to clients — the game mode just
doesn't react server-side.</p>
<h2 id="websocket-protocol" tabindex="-1">WebSocket Protocol</h2>
<h3 id="casting-a-vote-client-to-server" tabindex="-1">Casting a Vote (client to server)</h3>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;vote.cast&quot;,
  &quot;cid&quot;: &quot;v1&quot;,
  &quot;payload&quot;: {
    &quot;vote_id&quot;: &quot;...&quot;,
    &quot;option_id&quot;: &quot;jungle&quot;
  }
}
</code></pre>
<p>For approval voting, <code>option_id</code> is a list:</p>
<pre><code class="language-json">{&quot;option_id&quot;: [&quot;jungle&quot;, &quot;caves&quot;]}
</code></pre>
<p>Response:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.cast_ok&quot;, &quot;cid&quot;: &quot;v1&quot;, &quot;payload&quot;: {&quot;success&quot;: true}}
</code></pre>
<p>Players can change their vote by sending another <code>vote.cast</code> during the
window. The new vote replaces the previous one.</p>
<h3 id="server-push-events" tabindex="-1">Server Push Events</h3>
<p>All vote events are broadcast to match players as <code>match.*</code> events:</p>
<h4 id="matchvote_start" tabindex="-1"><code>match.vote_start</code></h4>
<p>A new vote has started.</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;match.vote_start&quot;,
  &quot;payload&quot;: {
    &quot;vote_id&quot;: &quot;...&quot;,
    &quot;options&quot;: [
      {&quot;id&quot;: &quot;jungle&quot;, &quot;label&quot;: &quot;Jungle Path&quot;},
      {&quot;id&quot;: &quot;volcano&quot;, &quot;label&quot;: &quot;Volcano Path&quot;},
      {&quot;id&quot;: &quot;caves&quot;, &quot;label&quot;: &quot;Ice Caves&quot;}
    ],
    &quot;window_ms&quot;: 15000,
    &quot;method&quot;: &quot;plurality&quot;
  }
}
</code></pre>
<h4 id="matchvote_tally" tabindex="-1"><code>match.vote_tally</code></h4>
<p>Running tally update (only with <code>&quot;live&quot;</code> visibility). Sent each time a vote
is cast.</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;match.vote_tally&quot;,
  &quot;payload&quot;: {
    &quot;vote_id&quot;: &quot;...&quot;,
    &quot;tallies&quot;: {&quot;jungle&quot;: 2, &quot;volcano&quot;: 1, &quot;caves&quot;: 0},
    &quot;time_remaining_ms&quot;: 8432,
    &quot;total_votes&quot;: 3
  }
}
</code></pre>
<h4 id="matchvote_result" tabindex="-1"><code>match.vote_result</code></h4>
<p>Vote has closed and the winner is determined.</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;match.vote_result&quot;,
  &quot;payload&quot;: {
    &quot;vote_id&quot;: &quot;...&quot;,
    &quot;winner&quot;: &quot;jungle&quot;,
    &quot;counts&quot;: {&quot;jungle&quot;: 2, &quot;volcano&quot;: 1, &quot;caves&quot;: 0},
    &quot;distribution&quot;: {&quot;jungle&quot;: 0.666, &quot;volcano&quot;: 0.333, &quot;caves&quot;: 0.0},
    &quot;total_votes&quot;: 3,
    &quot;turnout&quot;: 1.0
  }
}
</code></pre>
<h4 id="matchvote_vetoed" tabindex="-1"><code>match.vote_vetoed</code></h4>
<p>A player has vetoed the vote (when <code>veto_enabled</code> is true).</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;match.vote_vetoed&quot;,
  &quot;payload&quot;: {
    &quot;vote_id&quot;: &quot;...&quot;,
    &quot;vetoed_by&quot;: &quot;player_id&quot;
  }
}
</code></pre>
<h2 id="rest-api" tabindex="-1">REST API</h2>
<h3 id="list-votes-for-a-match" tabindex="-1">List votes for a match</h3>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/matches/&lt;match_id&gt;/votes \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<p>Returns the most recent 50 votes for the match, ordered by newest first.</p>
<h3 id="get-a-single-vote" tabindex="-1">Get a single vote</h3>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/votes/&lt;vote_id&gt; \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<h2 id="visibility-modes" tabindex="-1">Visibility Modes</h2>
<ul>
<li><strong><code>&quot;live&quot;</code></strong>: Running tallies are broadcast after each vote and included in
state queries. Creates excitement and enables strategic voting.</li>
<li><strong><code>&quot;hidden&quot;</code></strong>: Tallies are not shown until the vote closes. Prevents
bandwagon effects. Only total vote count is visible during the window.</li>
</ul>
<h2 id="veto" tabindex="-1">Veto</h2>
<p>When <code>veto_enabled</code> is true, any eligible voter can veto the vote. This
immediately cancels it and notifies all players. Use sparingly — typically
as a limited-use resource managed by the game mode.</p>
<h2 id="majority-tyranny-mitigations" tabindex="-1">Majority Tyranny Mitigations</h2>
<p>When the same majority always outvotes a minority, voting becomes
frustrating. Asobi provides three configurable mitigations.</p>
<h3 id="frustration-accumulator" tabindex="-1">Frustration Accumulator</h3>
<p>Players who vote for the losing option accumulate frustration. On the
next vote, their weight is boosted: <code>1 + frustration_count * frustration_bonus</code>.
When they finally win, their frustration resets to 0.</p>
<p>Configure at match level:</p>
<pre><code class="language-erlang">asobi_match_sup:start_match(#{
    game_module =&gt; MyGame,
    frustration_bonus =&gt; 0.5  %% default 0.5, set 0 to disable
}).
</code></pre>
<p>A player who lost 3 consecutive votes gets weight <code>1 + 3 * 0.5 = 2.5</code>,
making their vote count 2.5x. This only applies to weighted voting or
when frustration weights are merged (which happens automatically when
starting votes via the match server).</p>
<h3 id="supermajority-requirement" tabindex="-1">Supermajority Requirement</h3>
<p>Force high-stakes votes to require a supermajority. If no option reaches
the threshold, the result has <code>winner =&gt; undefined</code> and
<code>status =&gt; &quot;no_consensus&quot;</code>.</p>
<pre><code class="language-erlang">asobi_match_server:start_vote(MatchPid, #{
    options =&gt; Options,
    require_supermajority =&gt; true,
    supermajority =&gt; 0.75  %% 75% required
}).
</code></pre>
<p>The game mode's <code>vote_resolved/3</code> callback receives the no-consensus
result and can decide what to do (random pick, re-vote, default option).</p>
<h3 id="veto-tokens" tabindex="-1">Veto Tokens</h3>
<p>Give players a limited number of vetoes per match. When used, the current
vote is immediately cancelled. The game mode decides what happens next.</p>
<p>Configure at match level:</p>
<pre><code class="language-erlang">asobi_match_sup:start_match(#{
    game_module =&gt; MyGame,
    veto_tokens_per_player =&gt; 2  %% default 0 (disabled)
}).
</code></pre>
<p>Clients use veto tokens via WebSocket:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.veto&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;}}
</code></pre>
<p>The match server checks token availability before forwarding to the vote
server. Returns <code>{error, no_veto_tokens}</code> when exhausted.</p>
<h2 id="grace-period" tabindex="-1">Grace Period</h2>
<p>Votes arriving within 500ms after the window closes are still accepted to
compensate for network latency.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/websocket">WebSocket protocol</a> - the <code>match.vote_*</code> push messages.</li>
<li><a href="/docs/configuration">Configuration</a> - vote templates.</li>
</ul>
"""}
    ]}.
