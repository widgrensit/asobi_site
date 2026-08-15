%% GENERATED from asobi guides/voting.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_voting_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1, markdown/0]).

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
<p>An in-session voting system for group decisions: path selection, item picks,
event choices, run modifiers. It runs inside a match or a world.</p>
<h2 id="the-namespace-follows-the-session" tabindex="-1">The namespace follows the session</h2>
<p>Worlds run votes exactly as matches do, and the frames a client receives are
named after the session it is in:</p>
<table>
<thead>
<tr>
<th>Session</th>
<th>Push frames</th>
</tr>
</thead>
<tbody>
<tr>
<td>Match</td>
<td><code>match.vote_start</code>, <code>match.vote_tally</code>, <code>match.vote_result</code>, <code>match.vote_vetoed</code></td>
</tr>
<tr>
<td>World</td>
<td><code>world.vote_start</code>, <code>world.vote_tally</code>, <code>world.vote_result</code>, <code>world.vote_vetoed</code></td>
</tr>
</tbody>
</table>
<p>A world client listening for <code>match.vote_start</code> receives nothing at all. Listen
for the namespace your game runs in.</p>
<h2 id="how-it-works" tabindex="-1">How it works</h2>
<ol>
<li>The game asks for a vote, with options and a timed window.</li>
<li>Eligible players receive <code>vote_start</code> in their session's namespace.</li>
<li>Players cast votes during the window with the <code>vote.cast</code> frame.</li>
<li>The window closes, votes are tallied and the result is broadcast.</li>
<li>The game module's optional <code>vote_resolved</code> callback receives the result.</li>
</ol>
<h2 id="starting-a-vote-from-lua" tabindex="-1">Starting a vote from Lua</h2>
<p>There are two Lua triggers, one per session type. Both are polled by the server
after every tick.</p>
<p><strong>A match script</strong> implements <code>vote_requested(state)</code>. Return a config table to
start a vote, or <code>nil</code> to skip:</p>
<pre><code class="language-lua">function vote_requested(state)
  if state.boss_defeated and not state.boon_picked then
    return {
      template  = &quot;boon_pick&quot;,
      options   = { { id = &quot;shield&quot;, label = &quot;Shield&quot; },
                    { id = &quot;speed&quot;,  label = &quot;Speed&quot; } },
      method    = &quot;plurality&quot;,
      window_ms = 15000
    }
  end
  return nil
end
</code></pre>
<p>Returning <code>nil</code>, <code>false</code> or an empty table skips.</p>
<p>An Erlang match module may also implement <code>vote_started/1</code>, which fires when a
vote starts this way. The Lua bridge does not export it, so a Lua
<code>vote_started</code> function is never called. Set your own flag inside
<code>vote_requested</code> instead.</p>
<p><strong>A world script</strong> sets <code>state._vote</code> inside <code>post_tick</code>, because a world has no
<code>vote_requested</code> callback:</p>
<pre><code class="language-lua">function post_tick(tick, state)
  if state.boss_hp &lt;= 0 then
    state._vote = {
      template  = &quot;boon_pick&quot;,
      options   = { { id = &quot;shield&quot;, label = &quot;Shield&quot; },
                    { id = &quot;speed&quot;,  label = &quot;Speed&quot; } },
      method    = &quot;plurality&quot;,
      window_ms = 15000
    }
    state.boss_hp = 10000    -- clear the trigger so it does not re-fire
  end
  return state
end
</code></pre>
<p>Clear whatever condition set <code>_vote</code>, or the next tick sets it again.</p>
<p>Before asobi v0.87.0 neither trigger worked. The decoded table reached the vote
server with string keys where it reads atom ones, so the vote failed to start
and the failure was swallowed at both call sites - no <code>vote_start</code> frame, no log
line naming the script. If you are on an older server, a vote has to be started
from Erlang.</p>
<h2 id="starting-a-vote-from-erlang" tabindex="-1">Starting a vote from Erlang</h2>
<p>A game module written in Erlang calls <code>asobi_match_server:start_vote/2</code> or
<code>asobi_world_server:start_vote/2</code> directly, with the session pid and a config
map. A Lua script does not need this - return the config from <code>vote_requested</code>
instead, as above.</p>
<pre><code class="language-erlang">asobi_match_server:start_vote(MatchPid, #{
    template   =&gt; ~&quot;path_choice&quot;,
    options    =&gt; [
        #{id =&gt; ~&quot;jungle&quot;,  label =&gt; ~&quot;Jungle Path&quot;},
        #{id =&gt; ~&quot;volcano&quot;, label =&gt; ~&quot;Volcano Path&quot;},
        #{id =&gt; ~&quot;caves&quot;,   label =&gt; ~&quot;Ice Caves&quot;}
    ],
    window_ms  =&gt; 15000,
    method     =&gt; ~&quot;plurality&quot;,
    visibility =&gt; ~&quot;live&quot;
}).
</code></pre>
<p>An Erlang game module can also implement <code>vote_requested/1</code>, returning
<code>{ok, Config}</code> or <code>none</code>, which the match server polls after every tick.</p>
<p>The server fills in <code>match_id</code>, <code>match_pid</code>, <code>eligible</code> (every current player)
and merged <code>weights</code> before the vote starts, so a caller never supplies them.</p>
<p>Starting a vote in a match that has not started yet answers
<code>{error, match_not_started}</code>, and in a paused match <code>{error, match_paused}</code>.</p>
<h2 id="config-reference" tabindex="-1">Config reference</h2>
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
<td>Template name, resolved from <code>vote_templates</code></td>
</tr>
<tr>
<td><code>vote_id</code></td>
<td><code>binary()</code></td>
<td>generated</td>
<td>Override the vote id</td>
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
<td><code>&quot;plurality&quot;</code>, <code>&quot;approval&quot;</code>, <code>&quot;weighted&quot;</code> or <code>&quot;ranked&quot;</code></td>
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
<td>Allow an eligible voter to veto</td>
</tr>
<tr>
<td><code>weights</code></td>
<td><code>map()</code></td>
<td><code>#{}</code></td>
<td><code>#{voter_id =&gt; number()}</code> for <code>&quot;weighted&quot;</code></td>
</tr>
<tr>
<td><code>max_revotes</code></td>
<td><code>pos_integer()</code></td>
<td><code>3</code></td>
<td>Times a voter may change their vote</td>
</tr>
<tr>
<td><code>window_type</code></td>
<td><code>binary()</code></td>
<td><code>&quot;fixed&quot;</code></td>
<td><code>&quot;fixed&quot;</code>, <code>&quot;ready_up&quot;</code>, <code>&quot;hybrid&quot;</code> or <code>&quot;adaptive&quot;</code></td>
</tr>
<tr>
<td><code>min_window_ms</code></td>
<td><code>pos_integer()</code></td>
<td><code>5000</code></td>
<td>Minimum window before <code>&quot;hybrid&quot;</code> may close early</td>
</tr>
<tr>
<td><code>supermajority</code></td>
<td><code>float()</code></td>
<td><code>0.75</code></td>
<td>Threshold for <code>&quot;adaptive&quot;</code> early close and for <code>require_supermajority</code></td>
</tr>
<tr>
<td><code>require_supermajority</code></td>
<td><code>boolean()</code></td>
<td><code>false</code></td>
<td>Winner must reach <code>supermajority</code> or the result is no-consensus</td>
</tr>
<tr>
<td><code>spectators</code></td>
<td><code>[binary()]</code></td>
<td><code>[]</code></td>
<td>Spectator voter ids, a separate pool</td>
</tr>
<tr>
<td><code>spectator_weight</code></td>
<td><code>float()</code></td>
<td><code>0.3</code></td>
<td>Spectator share of the merged score, 0.0-1.0</td>
</tr>
<tr>
<td><code>quorum</code></td>
<td><code>float()</code></td>
<td><code>0.0</code></td>
<td>Minimum fraction of eligible voters for a valid result. 0.0 disables</td>
</tr>
<tr>
<td><code>default_votes</code></td>
<td><code>map()</code></td>
<td><code>#{}</code></td>
<td><code>#{voter_id =&gt; option_id}</code> applied at resolution for absentees</td>
</tr>
<tr>
<td><code>delegation</code></td>
<td><code>map()</code></td>
<td><code>#{}</code></td>
<td><code>#{delegator_id =&gt; delegate_id}</code></td>
</tr>
</tbody>
</table>
<p><code>match_id</code>, <code>match_pid</code> and <code>eligible</code> are also config keys, but the session
server supplies all three.</p>
<h2 id="voting-methods" tabindex="-1">Voting methods</h2>
<p><strong>Plurality.</strong> Each player picks one option; most votes wins. Ties go to
<code>tie_breaker</code>.</p>
<p><strong>Approval.</strong> Each player submits a list of options they approve of; highest
total approval wins. Good for &quot;avoid the worst option&quot;.</p>
<p><strong>Weighted.</strong> Each vote is multiplied by the voter's weight. Voters absent from
the <code>weights</code> map count as 1.</p>
<pre><code class="language-erlang">#{method =&gt; ~&quot;weighted&quot;, weights =&gt; #{~&quot;player1&quot; =&gt; 3, ~&quot;player2&quot; =&gt; 1}}
</code></pre>
<p><strong>Ranked.</strong> Each player submits a ranked list. The option with the fewest
first-choice votes is eliminated each round and its votes transfer to the next
preference, until one option has a majority. Clients send a list for
<code>option_id</code>:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.cast&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;, &quot;option_id&quot;: [&quot;jungle&quot;, &quot;caves&quot;, &quot;volcano&quot;]}}
</code></pre>
<p>Live tallies show first-choice counts; the final result is the winner after all
elimination rounds.</p>
<h2 id="window-types" tabindex="-1">Window types</h2>
<p>Every type has <code>window_ms</code> as a hard upper bound.</p>
<table>
<thead>
<tr>
<th><code>window_type</code></th>
<th>Closes when</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>&quot;fixed&quot;</code></td>
<td><code>window_ms</code> elapses. Simple and predictable</td>
</tr>
<tr>
<td><code>&quot;ready_up&quot;</code></td>
<td>Every eligible voter has voted, or <code>window_ms</code> elapses</td>
</tr>
<tr>
<td><code>&quot;hybrid&quot;</code></td>
<td>As <code>ready_up</code>, but not before <code>min_window_ms</code></td>
</tr>
<tr>
<td><code>&quot;adaptive&quot;</code></td>
<td>On reaching <code>supermajority</code> the remaining time shrinks to 3 seconds, giving latecomers a last chance. A later cast that breaks the supermajority does not restore the original window - the shortened timer keeps running</td>
</tr>
</tbody>
</table>
<h2 id="spectator-voting" tabindex="-1">Spectator voting</h2>
<p>Spectators are a separate pool merged with player votes:</p>
<pre><code class="language-erlang">#{spectators =&gt; [~&quot;spec1&quot;, ~&quot;spec2&quot;], spectator_weight =&gt; 0.3}
</code></pre>
<p>Both pools are tallied independently, normalised, then merged:</p>
<pre><code>score = player_normalised * (1 - spectator_weight) + spectator_normalised * spectator_weight
</code></pre>
<p>For an audience-decides vote, set <code>eligible =&gt; []</code> and
<code>spectator_weight =&gt; 1.0</code>.</p>
<h2 id="async-voting" tabindex="-1">Async voting</h2>
<p>For games where not everyone is online at once.</p>
<p><strong>Quorum.</strong> <code>#{quorum =&gt; 0.5}</code> requires half the eligible voters to
participate. Short of that, the result carries <code>winner =&gt; undefined</code> and
<code>status =&gt; &quot;no_quorum&quot;</code>.</p>
<p><strong>Default votes.</strong> <code>#{default_votes =&gt; #{~&quot;player2&quot; =&gt; ~&quot;opt_b&quot;}}</code> applies a
fallback at resolution time only. Defaults never count as active votes during
the window, and an explicit vote overrides them.</p>
<p><strong>Delegation.</strong> <code>#{delegation =&gt; #{~&quot;player3&quot; =&gt; ~&quot;player1&quot;}}</code> makes player3's
vote follow player1's at resolution time. If the delegate did not vote either,
no vote is added.</p>
<h2 id="vote-templates" tabindex="-1">Vote templates</h2>
<p>Reusable configurations in app config. Per-call config overrides the template:</p>
<pre><code class="language-erlang">{asobi, [
    {vote_templates, #{
        ~&quot;boon_pick&quot;   =&gt; #{method =&gt; ~&quot;plurality&quot;, window_ms =&gt; 15000, visibility =&gt; ~&quot;live&quot;},
        ~&quot;path_choice&quot; =&gt; #{method =&gt; ~&quot;approval&quot;, window_ms =&gt; 20000, visibility =&gt; ~&quot;hidden&quot;}
    }}
]}
</code></pre>
<pre><code class="language-erlang">asobi_match_server:start_vote(MatchPid, #{template =&gt; ~&quot;boon_pick&quot;, options =&gt; Options}).
</code></pre>
<h2 id="reacting-to-the-result" tabindex="-1">Reacting to the result</h2>
<div class="tabbed-code"><input type="radio" name="vote-tab0" id="vote-tab0-1" checked><input type="radio" name="vote-tab0" id="vote-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="vote-tab0-1">Lua</label><label for="vote-tab0-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">function vote_resolved(template, result, state)
  if template == "path_choice" then
    state.current_path = result.winner
  end
  return state
end</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">vote_resolved(~"path_choice", #{winner := WinnerId}, GameState) -&gt;
    {ok, GameState#{current_path =&gt; WinnerId}}.</code></pre></div></div>
<p>The callback is optional. Without it the vote still runs and broadcasts, the
game just does not react server-side.</p>
<p>The Lua form works for a <strong>match</strong> script only. The world bridge does not
export <code>vote_resolved/3</code>, so a Lua world script's <code>vote_resolved</code> is never
called; an Erlang world module's is.</p>
<h2 id="majority-tyranny-mitigations" tabindex="-1">Majority tyranny mitigations</h2>
<p><strong>Frustration accumulator.</strong> A player who votes for the losing option
accumulates frustration; on the next vote their weight becomes
<code>1 + frustration_count * frustration_bonus</code>, and winning resets it to 0. Three
consecutive losses give a weight of 2.5. <code>frustration_bonus</code> defaults to <code>0.5</code>
and the merged weights are attached to every vote the session starts, but only
<code>method =&gt; &quot;weighted&quot;</code> reads them - plurality, approval and ranked count
ballots, not weights. So the accumulator is armed by default and inert until a
vote asks for weighting.</p>
<p><strong>Supermajority requirement.</strong> <code>require_supermajority =&gt; true</code> with a
<code>supermajority</code> threshold. If no option reaches it, the result carries
<code>winner =&gt; undefined</code> and <code>status =&gt; &quot;no_consensus&quot;</code>, and <code>vote_resolved</code>
decides what happens next.</p>
<p><strong>Veto tokens.</strong> <code>veto_tokens_per_player</code> defaults to <code>0</code>, which disables veto
tokens. A player spends one with the <code>vote.veto</code> frame, which cancels the
current vote immediately. Exhausted tokens answer <code>no_veto_tokens</code>.</p>
<p><code>frustration_bonus</code> and <code>veto_tokens_per_player</code> are read from the map that
starts the <strong>session</strong>, not from the vote config and not from <code>game_modes</code>.
Nothing in the shipped create paths passes them: a matchmaker-spawned match and
every world get the defaults above. Only Erlang code calling
<code>asobi_match_sup:start_match/1</code> directly can set them.</p>
<pre><code class="language-erlang">asobi_match_sup:start_match(#{
    mode                   =&gt; ~&quot;arena&quot;,
    game_module            =&gt; my_arena,
    game_config            =&gt; #{},
    min_players            =&gt; 4,
    max_players            =&gt; 4,
    frustration_bonus      =&gt; 0,
    veto_tokens_per_player =&gt; 2
}).
</code></pre>
<h2 id="client-protocol" tabindex="-1">Client protocol</h2>
<h3 id="casting-a-vote" tabindex="-1">Casting a vote</h3>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;vote.cast&quot;,
  &quot;cid&quot;: &quot;v1&quot;,
  &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;, &quot;option_id&quot;: &quot;jungle&quot;}
}
</code></pre>
<p>For approval and ranked voting, <code>option_id</code> is a list.</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.cast_ok&quot;, &quot;cid&quot;: &quot;v1&quot;, &quot;payload&quot;: {&quot;success&quot;: true}}
</code></pre>
<p>Sending <code>vote.cast</code> again during the window replaces the previous vote, up to
<code>max_revotes</code> changes. The initial vote does not count against the limit.</p>
<h3 id="vetoing" tabindex="-1">Vetoing</h3>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.veto&quot;, &quot;cid&quot;: &quot;v2&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;}}
</code></pre>
<pre><code class="language-json">{&quot;type&quot;: &quot;vote.veto_ok&quot;, &quot;cid&quot;: &quot;v2&quot;, &quot;payload&quot;: {&quot;success&quot;: true}}
</code></pre>
<h3 id="errors" tabindex="-1">Errors</h3>
<p>Both frames answer a <code>{&quot;type&quot;: &quot;error&quot;}</code> frame carrying the shared error object
plus a <code>reason</code> field.</p>
<table>
<thead>
<tr>
<th><code>reason</code></th>
<th><code>error.code</code></th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>not_in_match</code></td>
<td><code>match.not_in_match</code></td>
<td>The connection is not joined to a match</td>
</tr>
<tr>
<td><code>vote_not_found</code></td>
<td><code>ws.request_failed</code></td>
<td>No live vote with that id in this session</td>
</tr>
<tr>
<td><code>not_eligible</code></td>
<td><code>ws.request_failed</code></td>
<td>The voter is not in the eligible or spectator pool</td>
</tr>
<tr>
<td><code>invalid_option</code></td>
<td><code>ws.request_failed</code></td>
<td><code>option_id</code> is not one of the vote's options</td>
</tr>
<tr>
<td><code>rate_limited</code></td>
<td><code>rate_limited</code></td>
<td><code>max_revotes</code> changes already used</td>
</tr>
<tr>
<td><code>vote_closed</code></td>
<td><code>ws.request_failed</code></td>
<td>The window and its 500ms grace period have passed</td>
</tr>
<tr>
<td><code>veto_disabled</code></td>
<td><code>ws.request_failed</code></td>
<td><code>veto_enabled</code> is false for this vote</td>
</tr>
<tr>
<td><code>no_veto_tokens</code></td>
<td><code>ws.request_failed</code></td>
<td>The player has spent every veto token</td>
</tr>
</tbody>
</table>
<p><strong>A world player always gets <code>not_in_match</code>.</strong> Both frames route on the
session's <code>match_pid</code>, and joining a world sets <code>world_pid</code> instead, so a world
vote can be started and broadcast but not cast from a client today. This is the
same defect class as the Lua config above. Report both if they block you.</p>
<h3 id="grace-period" tabindex="-1">Grace period</h3>
<p>Votes arriving within 500ms of the window closing are still accepted, to absorb
network latency.</p>
<h2 id="server-push-frames" tabindex="-1">Server push frames</h2>
<p>Shown here in the <code>match.</code> namespace; a world sends the same payloads under
<code>world.</code>.</p>
<p><code>match.vote_start</code>:</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;match.vote_start&quot;,
  &quot;payload&quot;: {
    &quot;vote_id&quot;: &quot;...&quot;,
    &quot;options&quot;: [{&quot;id&quot;: &quot;jungle&quot;, &quot;label&quot;: &quot;Jungle Path&quot;}],
    &quot;window_ms&quot;: 15000,
    &quot;method&quot;: &quot;plurality&quot;
  }
}
</code></pre>
<p><code>match.vote_tally</code>, sent on every cast, and only with <code>&quot;live&quot;</code> visibility:</p>
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
<p><code>match.vote_result</code>:</p>
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
<p><code>match.vote_vetoed</code>:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;match.vote_vetoed&quot;, &quot;payload&quot;: {&quot;vote_id&quot;: &quot;...&quot;, &quot;vetoed_by&quot;: &quot;player_id&quot;}}
</code></pre>
<h2 id="visibility" tabindex="-1">Visibility</h2>
<ul>
<li><code>&quot;live&quot;</code> - running tallies are broadcast after each cast and included in
state queries.</li>
<li><code>&quot;hidden&quot;</code> - no <code>vote_tally</code> frame is sent at all; the tallies arrive only in
<code>vote_result</code> when the vote closes, which prevents bandwagoning.</li>
</ul>
<p>Visibility governs the live frames only. It is not recorded on the persisted
row, so a resolved hidden vote's per-voter ballots are readable in the history
below exactly like a live one's.</p>
<h2 id="reading-vote-history" tabindex="-1">Reading vote history</h2>
<p>There is no votes screen on the console. Two REST routes cover it, and both
read the <code>votes</code> table, which is written <strong>only when a vote resolves</strong> - a vote
in progress appears in neither.</p>
<p>Every vote for a match, most recent 50, newest first:</p>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/matches/&lt;match_id&gt;/votes \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<pre><code class="language-json">{&quot;votes&quot;: [{&quot;id&quot;: &quot;...&quot;, &quot;match_id&quot;: &quot;...&quot;, &quot;template&quot;: &quot;...&quot;, &quot;method&quot;: &quot;plurality&quot;, &quot;options&quot;: [], &quot;votes_cast&quot;: {}, &quot;result&quot;: {}, &quot;distribution&quot;: {}, &quot;turnout&quot;: 1.0, &quot;eligible_count&quot;: 3, &quot;window_ms&quot;: 15000, &quot;opened_at&quot;: &quot;...&quot;, &quot;closed_at&quot;: &quot;...&quot;, &quot;inserted_at&quot;: &quot;...&quot;}]}
</code></pre>
<p>Restricted to participants of that match: anyone else gets <code>403 forbidden</code>.
A world's votes are stored under the world id in the same <code>match_id</code> column, so
the same route takes a world id - but only after the world finishes and writes
its record, and only for the players still in it at that moment. While the
world is live the participant check finds neither a record nor a match server
and answers <code>403</code>.</p>
<p>One vote by id:</p>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/votes/&lt;vote_id&gt; \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<p>Unknown ids answer <code>404 vote.not_found</code>. This route is authenticated but not
participant-scoped. See <a href="https://hexdocs.pm/asobi/console.html">Operator console</a> for what the console
does cover.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/websocket">WebSocket protocol</a> - the frame envelope.</li>
<li><a href="/docs/phases">Phases</a> - run a vote to decide what the next phase does.</li>
<li><a href="/docs/configuration">Configuration</a> - vote templates.</li>
</ul>
"""}
    ]}.

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Voting

An in-session voting system for group decisions: path selection, item picks,
event choices, run modifiers. It runs inside a match or a world.

## The namespace follows the session

Worlds run votes exactly as matches do, and the frames a client receives are
named after the session it is in:

| Session | Push frames |
|---|---|
| Match | `match.vote_start`, `match.vote_tally`, `match.vote_result`, `match.vote_vetoed` |
| World | `world.vote_start`, `world.vote_tally`, `world.vote_result`, `world.vote_vetoed` |

A world client listening for `match.vote_start` receives nothing at all. Listen
for the namespace your game runs in.

## How it works

1. The game asks for a vote, with options and a timed window.
2. Eligible players receive `vote_start` in their session's namespace.
3. Players cast votes during the window with the `vote.cast` frame.
4. The window closes, votes are tallied and the result is broadcast.
5. The game module's optional `vote_resolved` callback receives the result.

## Starting a vote from Lua

There are two Lua triggers, one per session type. Both are polled by the server
after every tick.

**A match script** implements `vote_requested(state)`. Return a config table to
start a vote, or `nil` to skip:

```lua
function vote_requested(state)
  if state.boss_defeated and not state.boon_picked then
    return {
      template  = "boon_pick",
      options   = { { id = "shield", label = "Shield" },
                    { id = "speed",  label = "Speed" } },
      method    = "plurality",
      window_ms = 15000
    }
  end
  return nil
end
```

Returning `nil`, `false` or an empty table skips.

An Erlang match module may also implement `vote_started/1`, which fires when a
vote starts this way. The Lua bridge does not export it, so a Lua
`vote_started` function is never called. Set your own flag inside
`vote_requested` instead.

**A world script** sets `state._vote` inside `post_tick`, because a world has no
`vote_requested` callback:

```lua
function post_tick(tick, state)
  if state.boss_hp <= 0 then
    state._vote = {
      template  = "boon_pick",
      options   = { { id = "shield", label = "Shield" },
                    { id = "speed",  label = "Speed" } },
      method    = "plurality",
      window_ms = 15000
    }
    state.boss_hp = 10000    -- clear the trigger so it does not re-fire
  end
  return state
end
```

Clear whatever condition set `_vote`, or the next tick sets it again.

Before asobi v0.87.0 neither trigger worked. The decoded table reached the vote
server with string keys where it reads atom ones, so the vote failed to start
and the failure was swallowed at both call sites - no `vote_start` frame, no log
line naming the script. If you are on an older server, a vote has to be started
from Erlang.

## Starting a vote from Erlang

A game module written in Erlang calls `asobi_match_server:start_vote/2` or
`asobi_world_server:start_vote/2` directly, with the session pid and a config
map. A Lua script does not need this - return the config from `vote_requested`
instead, as above.

```erlang
asobi_match_server:start_vote(MatchPid, #{
    template   => ~"path_choice",
    options    => [
        #{id => ~"jungle",  label => ~"Jungle Path"},
        #{id => ~"volcano", label => ~"Volcano Path"},
        #{id => ~"caves",   label => ~"Ice Caves"}
    ],
    window_ms  => 15000,
    method     => ~"plurality",
    visibility => ~"live"
}).
```

An Erlang game module can also implement `vote_requested/1`, returning
`{ok, Config}` or `none`, which the match server polls after every tick.

The server fills in `match_id`, `match_pid`, `eligible` (every current player)
and merged `weights` before the vote starts, so a caller never supplies them.

Starting a vote in a match that has not started yet answers
`{error, match_not_started}`, and in a paused match `{error, match_paused}`.

## Config reference

| Key | Type | Default | Description |
|---|---|---|---|
| `options` | `[map()]` | required | List of `#{id, label}` option maps |
| `template` | `binary()` | `"default"` | Template name, resolved from `vote_templates` |
| `vote_id` | `binary()` | generated | Override the vote id |
| `window_ms` | `pos_integer()` | `15000` | Vote window in milliseconds |
| `method` | `binary()` | `"plurality"` | `"plurality"`, `"approval"`, `"weighted"` or `"ranked"` |
| `visibility` | `binary()` | `"live"` | `"live"` or `"hidden"` |
| `tie_breaker` | `binary()` | `"random"` | `"random"` or `"first"` |
| `veto_enabled` | `boolean()` | `false` | Allow an eligible voter to veto |
| `weights` | `map()` | `#{}` | `#{voter_id => number()}` for `"weighted"` |
| `max_revotes` | `pos_integer()` | `3` | Times a voter may change their vote |
| `window_type` | `binary()` | `"fixed"` | `"fixed"`, `"ready_up"`, `"hybrid"` or `"adaptive"` |
| `min_window_ms` | `pos_integer()` | `5000` | Minimum window before `"hybrid"` may close early |
| `supermajority` | `float()` | `0.75` | Threshold for `"adaptive"` early close and for `require_supermajority` |
| `require_supermajority` | `boolean()` | `false` | Winner must reach `supermajority` or the result is no-consensus |
| `spectators` | `[binary()]` | `[]` | Spectator voter ids, a separate pool |
| `spectator_weight` | `float()` | `0.3` | Spectator share of the merged score, 0.0-1.0 |
| `quorum` | `float()` | `0.0` | Minimum fraction of eligible voters for a valid result. 0.0 disables |
| `default_votes` | `map()` | `#{}` | `#{voter_id => option_id}` applied at resolution for absentees |
| `delegation` | `map()` | `#{}` | `#{delegator_id => delegate_id}` |

`match_id`, `match_pid` and `eligible` are also config keys, but the session
server supplies all three.

## Voting methods

**Plurality.** Each player picks one option; most votes wins. Ties go to
`tie_breaker`.

**Approval.** Each player submits a list of options they approve of; highest
total approval wins. Good for "avoid the worst option".

**Weighted.** Each vote is multiplied by the voter's weight. Voters absent from
the `weights` map count as 1.

```erlang
#{method => ~"weighted", weights => #{~"player1" => 3, ~"player2" => 1}}
```

**Ranked.** Each player submits a ranked list. The option with the fewest
first-choice votes is eliminated each round and its votes transfer to the next
preference, until one option has a majority. Clients send a list for
`option_id`:

```json
{"type": "vote.cast", "payload": {"vote_id": "...", "option_id": ["jungle", "caves", "volcano"]}}
```

Live tallies show first-choice counts; the final result is the winner after all
elimination rounds.

## Window types

Every type has `window_ms` as a hard upper bound.

| `window_type` | Closes when |
|---|---|
| `"fixed"` | `window_ms` elapses. Simple and predictable |
| `"ready_up"` | Every eligible voter has voted, or `window_ms` elapses |
| `"hybrid"` | As `ready_up`, but not before `min_window_ms` |
| `"adaptive"` | On reaching `supermajority` the remaining time shrinks to 3 seconds, giving latecomers a last chance. A later cast that breaks the supermajority does not restore the original window - the shortened timer keeps running |

## Spectator voting

Spectators are a separate pool merged with player votes:

```erlang
#{spectators => [~"spec1", ~"spec2"], spectator_weight => 0.3}
```

Both pools are tallied independently, normalised, then merged:

```
score = player_normalised * (1 - spectator_weight) + spectator_normalised * spectator_weight
```

For an audience-decides vote, set `eligible => []` and
`spectator_weight => 1.0`.

## Async voting

For games where not everyone is online at once.

**Quorum.** `#{quorum => 0.5}` requires half the eligible voters to
participate. Short of that, the result carries `winner => undefined` and
`status => "no_quorum"`.

**Default votes.** `#{default_votes => #{~"player2" => ~"opt_b"}}` applies a
fallback at resolution time only. Defaults never count as active votes during
the window, and an explicit vote overrides them.

**Delegation.** `#{delegation => #{~"player3" => ~"player1"}}` makes player3's
vote follow player1's at resolution time. If the delegate did not vote either,
no vote is added.

## Vote templates

Reusable configurations in app config. Per-call config overrides the template:

```erlang
{asobi, [
    {vote_templates, #{
        ~"boon_pick"   => #{method => ~"plurality", window_ms => 15000, visibility => ~"live"},
        ~"path_choice" => #{method => ~"approval", window_ms => 20000, visibility => ~"hidden"}
    }}
]}
```

```erlang
asobi_match_server:start_vote(MatchPid, #{template => ~"boon_pick", options => Options}).
```

## Reacting to the result

**Lua**
```lua
function vote_resolved(template, result, state)
  if template == "path_choice" then
    state.current_path = result.winner
  end
  return state
end
```
**Erlang**
```erlang
vote_resolved(~"path_choice", #{winner := WinnerId}, GameState) ->
    {ok, GameState#{current_path => WinnerId}}.
```

The callback is optional. Without it the vote still runs and broadcasts, the
game just does not react server-side.

The Lua form works for a **match** script only. The world bridge does not
export `vote_resolved/3`, so a Lua world script's `vote_resolved` is never
called; an Erlang world module's is.

## Majority tyranny mitigations

**Frustration accumulator.** A player who votes for the losing option
accumulates frustration; on the next vote their weight becomes
`1 + frustration_count * frustration_bonus`, and winning resets it to 0. Three
consecutive losses give a weight of 2.5. `frustration_bonus` defaults to `0.5`
and the merged weights are attached to every vote the session starts, but only
`method => "weighted"` reads them - plurality, approval and ranked count
ballots, not weights. So the accumulator is armed by default and inert until a
vote asks for weighting.

**Supermajority requirement.** `require_supermajority => true` with a
`supermajority` threshold. If no option reaches it, the result carries
`winner => undefined` and `status => "no_consensus"`, and `vote_resolved`
decides what happens next.

**Veto tokens.** `veto_tokens_per_player` defaults to `0`, which disables veto
tokens. A player spends one with the `vote.veto` frame, which cancels the
current vote immediately. Exhausted tokens answer `no_veto_tokens`.

`frustration_bonus` and `veto_tokens_per_player` are read from the map that
starts the **session**, not from the vote config and not from `game_modes`.
Nothing in the shipped create paths passes them: a matchmaker-spawned match and
every world get the defaults above. Only Erlang code calling
`asobi_match_sup:start_match/1` directly can set them.

```erlang
asobi_match_sup:start_match(#{
    mode                   => ~"arena",
    game_module            => my_arena,
    game_config            => #{},
    min_players            => 4,
    max_players            => 4,
    frustration_bonus      => 0,
    veto_tokens_per_player => 2
}).
```

## Client protocol

### Casting a vote

```json
{
  "type": "vote.cast",
  "cid": "v1",
  "payload": {"vote_id": "...", "option_id": "jungle"}
}
```

For approval and ranked voting, `option_id` is a list.

```json
{"type": "vote.cast_ok", "cid": "v1", "payload": {"success": true}}
```

Sending `vote.cast` again during the window replaces the previous vote, up to
`max_revotes` changes. The initial vote does not count against the limit.

### Vetoing

```json
{"type": "vote.veto", "cid": "v2", "payload": {"vote_id": "..."}}
```

```json
{"type": "vote.veto_ok", "cid": "v2", "payload": {"success": true}}
```

### Errors

Both frames answer a `{"type": "error"}` frame carrying the shared error object
plus a `reason` field.

| `reason` | `error.code` | Meaning |
|---|---|---|
| `not_in_match` | `match.not_in_match` | The connection is not joined to a match |
| `vote_not_found` | `ws.request_failed` | No live vote with that id in this session |
| `not_eligible` | `ws.request_failed` | The voter is not in the eligible or spectator pool |
| `invalid_option` | `ws.request_failed` | `option_id` is not one of the vote's options |
| `rate_limited` | `rate_limited` | `max_revotes` changes already used |
| `vote_closed` | `ws.request_failed` | The window and its 500ms grace period have passed |
| `veto_disabled` | `ws.request_failed` | `veto_enabled` is false for this vote |
| `no_veto_tokens` | `ws.request_failed` | The player has spent every veto token |

**A world player always gets `not_in_match`.** Both frames route on the
session's `match_pid`, and joining a world sets `world_pid` instead, so a world
vote can be started and broadcast but not cast from a client today. This is the
same defect class as the Lua config above. Report both if they block you.

### Grace period

Votes arriving within 500ms of the window closing are still accepted, to absorb
network latency.

## Server push frames

Shown here in the `match.` namespace; a world sends the same payloads under
`world.`.

`match.vote_start`:

```json
{
  "type": "match.vote_start",
  "payload": {
    "vote_id": "...",
    "options": [{"id": "jungle", "label": "Jungle Path"}],
    "window_ms": 15000,
    "method": "plurality"
  }
}
```

`match.vote_tally`, sent on every cast, and only with `"live"` visibility:

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

`match.vote_result`:

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

`match.vote_vetoed`:

```json
{"type": "match.vote_vetoed", "payload": {"vote_id": "...", "vetoed_by": "player_id"}}
```

## Visibility

- `"live"` - running tallies are broadcast after each cast and included in
  state queries.
- `"hidden"` - no `vote_tally` frame is sent at all; the tallies arrive only in
  `vote_result` when the vote closes, which prevents bandwagoning.

Visibility governs the live frames only. It is not recorded on the persisted
row, so a resolved hidden vote's per-voter ballots are readable in the history
below exactly like a live one's.

## Reading vote history

There is no votes screen on the console. Two REST routes cover it, and both
read the `votes` table, which is written **only when a vote resolves** - a vote
in progress appears in neither.

Every vote for a match, most recent 50, newest first:

```bash
curl http://localhost:8084/api/v1/matches/<match_id>/votes \
  -H 'Authorization: Bearer <token>'
```

```json
{"votes": [{"id": "...", "match_id": "...", "template": "...", "method": "plurality", "options": [], "votes_cast": {}, "result": {}, "distribution": {}, "turnout": 1.0, "eligible_count": 3, "window_ms": 15000, "opened_at": "...", "closed_at": "...", "inserted_at": "..."}]}
```

Restricted to participants of that match: anyone else gets `403 forbidden`.
A world's votes are stored under the world id in the same `match_id` column, so
the same route takes a world id - but only after the world finishes and writes
its record, and only for the players still in it at that moment. While the
world is live the participant check finds neither a record nor a match server
and answers `403`.

One vote by id:

```bash
curl http://localhost:8084/api/v1/votes/<vote_id> \
  -H 'Authorization: Bearer <token>'
```

Unknown ids answer `404 vote.not_found`. This route is authenticated but not
participant-scoped. See [Operator console](https://hexdocs.pm/asobi/console.html) for what the console
does cover.

## Next steps

- [WebSocket protocol](https://asobi.dev/docs/protocols/websocket) - the frame envelope.
- [Phases](https://asobi.dev/docs/phases) - run a vote to decide what the next phase does.
- [Configuration](https://asobi.dev/docs/configuration) - vote templates.
""".
