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
<p>Asobi includes built-in bot support. Bots run as server-side processes that
join matches as regular players -- no fake clients, no network overhead. The
AI logic runs in the same tick loop as the game.</p>
<h2 id="when-to-use-bots" tabindex="-1">When to use bots</h2>
<ul>
<li>Fill empty slots so matches start immediately instead of waiting for a full lobby.</li>
<li>A tutorial or single-player sandbox with scripted opponents.</li>
<li>Load-testing your tick loop without spawning real WebSocket sessions.</li>
<li>Replay / record-and-replay testing.</li>
</ul>
<h2 id="how-it-works" tabindex="-1">How It Works</h2>
<ol>
<li>A player queues for matchmaking</li>
<li>If no match is found within the configured wait time, Asobi adds bots</li>
<li>Bots join the match like regular players</li>
<li>Each tick, the bot calls a <code>think()</code> function to decide its input</li>
<li>Bot input goes through the same <code>handle_input</code> path as real players</li>
</ol>
<h2 id="configuration" tabindex="-1">Configuration</h2>
<h3 id="lua-docker" tabindex="-1">Lua (Docker)</h3>
<p>Enable bots by adding <code>bots</code> to your match script globals and a <code>names</code>
list to your bot script:</p>
<pre><code class="language-lua">-- match.lua
match_size = 4
max_players = 8
strategy = &quot;fill&quot;
bots = { script = &quot;bots/chaser.lua&quot; }
</code></pre>
<pre><code class="language-lua">-- bots/chaser.lua
names = {&quot;Spark&quot;, &quot;Blitz&quot;, &quot;Volt&quot;, &quot;Neon&quot;, &quot;Pulse&quot;}

function think(bot_id, state)
    -- AI logic here
end
</code></pre>
<p>The platform reads <code>names</code> from your bot script at runtime. Bot names are
prefixed with <code>bot_</code> (e.g., <code>bot_Spark</code>).</p>
<p>The spawner checks the queue every 8 seconds (a fixed interval, not tunable) and
fills a waiting match with bots up to the mode's <code>min_players</code>. Both settings
below live in the game mode's <code>bots</code> map — there are no bot environment
variables.</p>
<h3 id="erlang-sysconfig" tabindex="-1">Erlang (sys.config)</h3>
<p>For Erlang OTP projects, configure bots in <code>sys.config</code>:</p>
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
<p>Bot names are read from the bot script's <code>names</code> global. If not defined,
defaults to <code>[&quot;Spark&quot;, &quot;Blitz&quot;, &quot;Volt&quot;, &quot;Neon&quot;, &quot;Pulse&quot;]</code>.</p>
<h2 id="writing-a-bot-ai-script" tabindex="-1">Writing a Bot AI Script</h2>
<p>A bot script defines a single function: <code>think(bot_id, state)</code>. It receives
the current game state and returns an input table -- the same format a real
player would send. That is the whole callback surface: a bot script has no
<code>on_join</code> / <code>on_leave</code> / <code>on_message</code> hooks; it only ever produces the next
input from the current state (plus an optional <code>names</code> list, below).</p>
<p>Since the bot only decides from <code>state</code>, difficulty is a property of the
script, not a config knob: throttle a reaction-time delay or degrade the target
selection by keying private per-bot state off <code>bot_id</code> in a module-level table.</p>
<pre><code class="language-lua">-- game/bots/chaser.lua

function think(bot_id, state)
    local players = state.players or {}
    local me = players[bot_id]
    if not me then return {} end

    -- Find nearest enemy
    local target = find_nearest(bot_id, me, players)
    if not target then
        return wander()
    end

    -- Chase and shoot
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
<h2 id="multiple-bot-types" tabindex="-1">Multiple Bot Types</h2>
<p>Create different AI scripts for different playstyles:</p>
<pre><code>game/bots/
├── chaser.lua    -- rushes nearest player
├── sniper.lua    -- stays back, long range
├── healer.lua    -- supports teammates
└── camper.lua    -- holds position, ambushes
</code></pre>
<p>Currently, all bots in a game mode use the same script. To vary behavior,
add randomization inside your <code>think()</code> function:</p>
<pre><code class="language-lua">local STRATEGIES = { &quot;aggressive&quot;, &quot;defensive&quot;, &quot;random&quot; }

function think(bot_id, state)
    -- Use bot_id hash to pick consistent strategy per bot
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
<p>If no bot script is configured, bots use a built-in default AI that:</p>
<ul>
<li>Finds the nearest living enemy</li>
<li>Moves toward them</li>
<li>Shoots when within range (200 units)</li>
<li>Adds slight aim randomization</li>
<li>Wanders randomly if no targets are alive</li>
</ul>
<p>This works for most arena-style games out of the box.</p>
<h2 id="auto-boon-pick-and-voting" tabindex="-1">Auto Boon Pick and Voting</h2>
<p>Bots automatically handle game phases:</p>
<ul>
<li><strong>Boon pick</strong>: Bots pick the first available option immediately</li>
<li><strong>Voting</strong>: Bots cast a random vote after a 1-3 second delay</li>
</ul>
<p>This behavior is built-in and doesn't require any bot script code.</p>
<h2 id="bot-ids" tabindex="-1">Bot IDs</h2>
<p>Bot player IDs are prefixed with <code>bot_</code> followed by their display name
(e.g., <code>bot_Spark</code>, <code>bot_Blitz</code>). Your game logic can check for bots:</p>
<pre><code class="language-lua">function is_bot(player_id)
    return string.sub(player_id, 1, 4) == &quot;bot_&quot;
end
</code></pre>
<p>Clients receive bot players in the normal game state. Whether to show them
differently (e.g., &quot;AI&quot; tag) is up to the client.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/lua/api">Lua scripting</a> - the <code>game.*</code> API a bot's <code>think</code> shares with match logic.</li>
<li><a href="/docs/security/lua-trust-model">Trust model</a> - a bot's <code>think</code> runs bounded, like any callback.</li>
</ul>
"""}
    ]}.
