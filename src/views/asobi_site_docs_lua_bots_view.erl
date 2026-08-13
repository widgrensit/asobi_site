%% GENERATED from asobi guides/lua-bots.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_lua_bots_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-lua-bots", title => ~"Lua bots — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Lua / Bots"
        ]},
        {h1, [], [~"Bots"]},
        {raw,
            ~"""
<p>Bots are server-side processes that join matches as ordinary players. There
are no fake clients and no network hop; a bot's decisions go through the same
<code>handle_input</code> path a human's do.</p>
<h2 id="when-to-use-bots" tabindex="-1">When to use bots</h2>
<ul>
<li>Fill empty slots so matches start instead of waiting for a full lobby.</li>
<li>A tutorial or single-player sandbox with scripted opponents.</li>
<li>Load-testing a tick loop without spawning real WebSocket sessions.</li>
<li>Replay and record-and-replay testing.</li>
</ul>
<p>There are two ways a bot gets into a match. <strong>Queue fill</strong> is automatic and
answers &quot;not enough humans are waiting&quot;. <strong><code>game.bots.add</code></strong> is your script
placing one deliberately, at any point in the match. They are independent:
leave <code>bots.enabled</code> off and nothing arrives that your script did not ask for.</p>
<h2 id="how-queue-fill-works" tabindex="-1">How queue fill works</h2>
<ol>
<li>A player queues for matchmaking.</li>
<li>Every 8 seconds the spawner looks at each mode with someone queued. If
fewer are queued than the mode's bot target, it queues bots for the
difference.</li>
<li>The matchmaker forms a match from the queue as usual, bots included.</li>
<li>Within about 2 seconds of the match appearing, the spawner starts an AI
process for each <code>bot_</code>-prefixed player in it.</li>
<li>That process calls <code>think(bot_id, state)</code> on its own fixed 100 ms loop and
sends the result as input.</li>
</ol>
<p>No waiting period gates any of this. The spawner's only test is &quot;are fewer
queued for this mode than its target&quot;, so with a target of 4 and one human
waiting, three bots are queued at the next 8-second check. A mode with nobody
queued is skipped, so bots never start a match on their own. The one wait
setting that exists, <code>max_wait_seconds</code> (60 by default, under <code>{asobi, [{matchmaker, #{max_wait_seconds =&gt; N}}]}</code>), expires an unmatched ticket
instead - it does not trigger bot fill.</p>
<p>Bot fill is per node, because the matchmaker queue is per node. Each node
fills its own queue from its own view. See <a href="/docs/clustering">Clustering</a>.</p>
<h2 id="placing-a-bot-from-a-match-script" tabindex="-1">Placing a bot from a match script</h2>
<pre><code class="language-lua">game.bots.add(&quot;Spark&quot;)        -- bot_Spark joins this match
game.bots.remove(&quot;bot_Spark&quot;) -- and leaves
</code></pre>
<p>This is the route to take when the <em>game</em> decides, not the queue: a co-op
mission that needs an escort, a boss that fights alongside the players, a
practice mode with no queue at all, a slot backfilled the moment a human
drops. It works in <code>waiting</code> and in <code>running</code>, so a bot can arrive mid-match.</p>
<p><code>name</code> is bare and gets the <code>bot_</code> prefix here, so the roster shows
<code>bot_Spark</code>; <code>remove</code> takes either form. Names are 1-32 characters of
<code>[A-Za-z0-9_-]</code>. The bot runs the mode's <code>bots.script</code> if the mode has one and
the built-in AI otherwise, so a mode can leave <code>bots.enabled</code> off - that flag
governs queue fill only - and still configure a script.</p>
<p>Both calls are asynchronous and neither fails at the call site. A match that is
full, already holds that bot, or is at the 64-bot ceiling is a no-op with a line
in the node log. The bot appears in your <code>players</code> table through the same <code>join</code>
callback a human goes through, so a script that rejects unknown players will
reject bots too.</p>
<h2 id="configuration" tabindex="-1">Configuration</h2>
<p>Add a <code>bots</code> table to the match script's globals, and a <code>names</code> list to the
bot script:</p>
<pre><code class="language-lua">-- match.lua
match_size = 4
max_players = 8
strategy = &quot;fill&quot;
bots = { script = &quot;bots/chaser.lua&quot;, min_players = 4 }
</code></pre>
<pre><code class="language-lua">-- bots/chaser.lua
names = {&quot;Spark&quot;, &quot;Blitz&quot;, &quot;Volt&quot;, &quot;Neon&quot;, &quot;Pulse&quot;}

function think(bot_id, state)
    -- AI logic here
end
</code></pre>
<p><code>bots.script</code> is resolved relative to the match script's own directory, and a
path that escapes it is rejected with a warning.</p>
<p><code>bots.min_players</code> is the fill target. From Lua it defaults to <code>match_size</code>.
It is clamped at 64, and a larger value is clamped with a warning in the log.
The target is also capped at the mode's <code>max_players</code>, so a
<code>match_size = 2</code> / <code>max_players = 2</code> mode never overshoots into a second,
bot-only match.</p>
<p><code>bots.enabled</code> defaults to <code>true</code>; declaring the table at all is the opt-in.
Set it to <code>false</code> to keep the table (to declare <code>min_players</code>, say) with fill
turned off.</p>
<p>Bot ids are <code>bot_</code> plus a name from the list, taken in order: <code>bot_Spark</code>,
<code>bot_Blitz</code>. Past the end of the list they fall back to their position in the
fill, so the sixth bot of a batch with five names is <code>bot_6</code> and the seventh
is <code>bot_7</code>. Give the list at least as many names as the largest fill you
expect.</p>
<p>With no <code>names</code> global, or none the platform can read, the defaults are
<code>Spark</code>, <code>Blitz</code>, <code>Volt</code>, <code>Neon</code> and <code>Pulse</code>.</p>
<p>A bot joins through the normal match join, so the script's
<code>join(player_id, state)</code> runs for it exactly as for a human.</p>
<h3 id="in-erlang" tabindex="-1">In Erlang</h3>
<pre><code class="language-erlang">{game_modes, #{
    ~&quot;arena&quot; =&gt; #{
        module =&gt; {lua, &quot;game/match.lua&quot;},
        match_size =&gt; 4,
        bots =&gt; #{
            enabled =&gt; true,
            min_players =&gt; 4,
            script =&gt; &lt;&lt;&quot;game/bots/chaser.lua&quot;&gt;&gt;
        }
    }
}}
</code></pre>
<p>Two differences from the Lua path. <code>min_players</code> here defaults to <strong>4</strong>, not
to <code>match_size</code>, when the key is absent. And <code>names</code> can be set directly in
the <code>bots</code> map, in which case the bot script's <code>names</code> global is never read:</p>
<pre><code class="language-erlang">bots =&gt; #{enabled =&gt; true, names =&gt; [~&quot;Ada&quot;, ~&quot;Grace&quot;], script =&gt; &lt;&lt;&quot;game/bots/chaser.lua&quot;&gt;&gt;}
</code></pre>
<p>The 64 clamp applies here too, at spawn time.</p>
<h2 id="writing-a-bot-ai-script" tabindex="-1">Writing a bot AI script</h2>
<p>A bot script defines one function: <code>think(bot_id, state)</code>. It receives the
current game state and returns an input table, in the same format a real
player would send. That is the whole callback surface: no <code>on_join</code>,
<code>on_leave</code> or <code>on_message</code> hooks, just the next input from the current state,
plus the optional <code>names</code> list.</p>
<p>Because a bot decides only from <code>state</code>, difficulty is a property of the
script rather than a config knob: throttle a reaction delay or degrade target
selection by keying per-bot state off <code>bot_id</code> in a module-level table.</p>
<h3 id="what-a-bot-script-gets" tabindex="-1">What a bot script gets</h3>
<p>A bot script loads into the same hardened Luerl state a match script starts
from, but <strong>without</strong> the <code>game.*</code> API. That namespace is installed only for
match, world and zone scripts; inside <code>think</code>, <code>game</code> is <code>nil</code>. There is no
<code>game.log</code>, <code>game.economy</code>, <code>game.storage</code> or <code>game.leaderboard</code> for a bot.</p>
<p>An installed <a href="https://hexdocs.pm/asobi/extensions.html">extension</a> cannot add one either. <code>bot</code> is not a
VM kind an extension's <code>lua/0</code> may name, and declaring it fails the build
rather than installing a binding that quietly does nothing.</p>
<p>What is available:</p>
<ul>
<li>The Lua standard library, minus what the sandbox clears. <code>io</code>, <code>package</code>,
<code>load</code>, <code>loadfile</code>, <code>loadstring</code>, <code>dofile</code>, <code>print</code>, <code>eprint</code> and
<code>os.execute</code> / <code>os.exit</code> / <code>os.getenv</code> / <code>os.remove</code> / <code>os.rename</code> /
<code>os.tmpname</code> are all <code>nil</code>. See <a href="/docs/security/lua-sandbox">Sandbox model</a>.</li>
<li><code>require(&quot;module&quot;)</code>, resolved relative to the bot script's own directory, so
<code>require(&quot;targeting&quot;)</code> reads <code>&lt;bot script dir&gt;/targeting.lua</code>. Dotted paths
work; parent traversal and absolute paths are rejected.</li>
<li><code>math.random</code> and <code>math.sqrt</code>, backed by the BEAM's <code>rand</code> and <code>math</code>.</li>
<li>The two arguments of <code>think(bot_id, state)</code>, plus whatever the script itself
defines at the top level. <code>state</code> is the match state as broadcast to
players, so a bot sees what a client sees and nothing more.</li>
</ul>
<p>Anything else has to come through the match script: put the value in the state
the match broadcasts and read it from <code>state</code>.</p>
<p>Bots work under both state strategies, and <code>think</code> sees the same <code>state</code>
either way. A mode that declares <code>state_strategy = &quot;shared&quot;</code> still calls
<code>get_state</code> once per tick and encodes once for the connected sessions; a bot
is handed the payload behind that frame as a term, so it decodes nothing and
costs the shared path no extra encode. The difference that remains is what
<code>state</code> contains, not whether it arrives: under <code>&quot;shared&quot;</code> every bot sees
exactly what every player sees, so a bot cannot be given information a client
is not also given. Use per-player <code>get_state</code> when a bot needs a filtered view
of its own - see <a href="/docs/performance">Performance tuning</a> for what each
path costs.</p>
<p>Each <code>think</code> call runs under a 50 ms wall-clock budget, a heap cap and a
reduction budget. A timeout, a heap or CPU overrun, an error, or a missing
<code>think</code> falls back to the built-in default AI below.</p>
<p>That fallback is silent to the client, so it is also logged: a persistently
broken <code>think</code> produces <code>bot_think_error_falling_back_to_default_ai</code> with the
bot id and the reason, once a minute per bot. Grep for it when a bot has
stopped behaving like your script and started behaving like the default AI.</p>
<pre><code class="language-lua">-- game/bots/chaser.lua

function think(bot_id, state)
    local players = state.players or {}
    local me = players[bot_id]
    if not me then return {} end

    local target = find_nearest(bot_id, me, players)
    if not target then
        return wander()
    end

    local dist = distance(me, target)
    return {
        right = target.x &gt; me.x,
        left = target.x &lt; me.x,
        down = target.y &gt; me.y,
        up = target.y &lt; me.y,
        shoot = dist &lt; 200,
        aim_x = target.x,
        aim_y = target.y
    }
end

function find_nearest(bot_id, me, players)
    local nearest, min_dist = nil, 99999
    for id, p in pairs(players) do
        if id ~= bot_id and p.hp and p.hp &gt; 0 then
            local d = distance(me, p)
            if d &lt; min_dist then
                nearest, min_dist = p, d
            end
        end
    end
    return nearest
end

function distance(a, b)
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

function wander()
    return {
        right = math.random(2) == 1,
        left = math.random(2) == 1,
        down = math.random(2) == 1,
        up = math.random(2) == 1,
        shoot = false
    }
end
</code></pre>
<h2 id="multiple-bot-types" tabindex="-1">Multiple bot types</h2>
<p>Every bot in a game mode runs the same script. To vary behaviour, branch
inside <code>think</code>:</p>
<pre><code class="language-lua">local STRATEGIES = { &quot;aggressive&quot;, &quot;defensive&quot;, &quot;random&quot; }

function think(bot_id, state)
    -- bot_id length picks a stable strategy per bot
    local strategy = STRATEGIES[(#bot_id % #STRATEGIES) + 1]

    if strategy == &quot;aggressive&quot; then
        return chase(bot_id, state)
    elseif strategy == &quot;defensive&quot; then
        return defend(bot_id, state)
    else
        return wander()
    end
end
</code></pre>
<h2 id="default-ai" tabindex="-1">Default AI</h2>
<p>With no bot script configured, or when <code>think</code> fails, bots run a built-in AI
that finds the nearest living enemy, moves towards it, shoots within 200
units with slight aim jitter, and wanders when nothing is alive to chase.</p>
<p>It reads <code>players</code>, and each player's <code>x</code>, <code>y</code> and <code>hp</code>, from the broadcast
state. A bot with no entry of its own under <code>players</code> sends an empty input;
one whose peers carry no <code>hp</code> finds nothing alive to chase and wanders
instead.</p>
<h2 id="boon-picking-and-voting" tabindex="-1">Boon picking and voting</h2>
<p>Bots handle two phases without any script code:</p>
<ul>
<li>Boon pick: the bot picks the first offered option immediately.</li>
<li>Voting: the bot casts a random vote after a delay of 1 to 4 seconds.</li>
</ul>
<p>The boon pick is driven by the broadcast state: the phase comes from
<code>state.phase</code> (<code>&quot;boon_pick&quot;</code>), and the offers from <code>state.boon_offers</code>. The
vote is not - it is driven by the <code>vote_start</code> match event, which carries the
vote id and the options the bot picks from. A <code>state.phase</code> of <code>&quot;voting&quot;</code> or
<code>&quot;vote_pending&quot;</code> only stops the bot sending input while the vote runs.</p>
<h2 id="bot-ids" tabindex="-1">Bot ids</h2>
<p>Bot player ids are <code>bot_</code> followed by the display name, so game logic can test
for them:</p>
<pre><code class="language-lua">function is_bot(player_id)
    return string.sub(player_id, 1, 4) == &quot;bot_&quot;
end
</code></pre>
<p>Clients receive bots in the normal game state. Whether to mark them in the UI
is up to the client.</p>
<h2 id="bots-and-presence" tabindex="-1">Bots and presence</h2>
<p>A bot is tracked with <code>asobi_presence:track_bot/2</code>, which makes it a delivery
target for everything the match server broadcasts (state, match events, votes)
exactly like a connected player session. Shared state reaches it too:
<code>asobi_presence:send_match_state/3</code> gives a session the pre-encoded frame and
a bot the same payload as a term, which is the one delivery that differs by
recipient kind - see <a href="#what-a-bot-script-gets">What a bot script gets</a>.</p>
<p>It deliberately does not make the bot <em>online</em>:</p>
<ul>
<li><code>asobi_presence:online_count/0</code> counts connected humans only. Bots are never
added to it, so the concurrency figure stays a real player count. Bot fill
does not read it: it reads the matchmaker queue, where the bots it queued
count like anyone else, which is what stops the fill feeding itself.</li>
<li>Bots emit no <code>player_online</code> / <code>player_offline</code> broadcasts, so friend lists
and presence subscribers never see a bot appear or disappear.</li>
</ul>
<p><code>asobi_presence:get_status/1</code> on a bot id does answer <code>online</code>, because that
function reports whether the id is addressable. Filter on the <code>bot_</code> prefix
if you need the human answer.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/tools/multiple-players">Testing with multiple players</a> - bot fill is why
two humans testing together each get their own match.</li>
<li><a href="https://hexdocs.pm/asobi/lua-api.html">The game.* API</a> - what match and world scripts can call, and
bots cannot (see <a href="#what-a-bot-script-gets">What a bot script gets</a>).</li>
<li><a href="/docs/lua/api">Lua scripting</a> - the match callbacks a bot's input feeds.</li>
<li><a href="/docs/security/lua-trust-model">Trust model</a> - a bot's <code>think</code> runs bounded, like
any callback.</li>
</ul>
"""}
    ]}.
