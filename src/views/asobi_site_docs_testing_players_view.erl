%% GENERATED from asobi guides/testing-multiple-players.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_testing_players_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{
                id => ~"docs-testing-players",
                title => ~"Testing with multiple players — Asobi docs"
            },
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Testing with multiple players"
        ]},
        {h1, [], [~"Testing with multiple players"]},
        {raw,
            ~"""
<p>Running two clients on one machine is the first thing you do after the
quickstart, and it is where most first sessions go wrong: both windows sign in
as the same player, matchmaking refuses to pair them, and the two views drift
apart.</p>
<p>Nothing is broken. A guest account belongs to the <strong>device</strong>, not to the window.</p>
<h2 id="why-the-second-client-is-the-same-player" tabindex="-1">Why the second client is the same player</h2>
<p>Guest sign-in is create-or-resume on a <code>{device_id, device_secret}</code> pair. The
same pair always resumes the same player, which is the whole point: a player who
reinstalls keeps their progress. The SDK helper persists that pair for you:</p>
<table>
<thead>
<tr>
<th>SDK</th>
<th>Where the pair is stored</th>
</tr>
</thead>
<tbody>
<tr>
<td>Defold</td>
<td><code>sys.get_save_file(&quot;asobi&quot;, &quot;guest_device&quot;)</code></td>
</tr>
<tr>
<td>Godot</td>
<td><code>user://asobi_device.json</code></td>
</tr>
<tr>
<td>JS</td>
<td><code>localStorage</code>, key <code>asobi.guest_device</code></td>
</tr>
</tbody>
</table>
<p>Two instances of the same project on one machine read the same file, so
<code>guest_device()</code> hands both of them the same credentials and the server resumes
one player twice. Two browser tabs on the same origin and profile share
<code>localStorage</code> and collapse the same way.</p>
<p>Print <code>player_id</code> in both clients after sign-in. If it is the same id, this page
is your problem. If the ids differ, skip to
<a href="#two-players-two-matches">Two players, two matches</a>.</p>
<h3 id="what-one-player-with-two-connections-looks-like" tabindex="-1">What one player with two connections looks like</h3>
<p>asobi assumes one live connection per player, so the two clients quietly
interfere:</p>
<ul>
<li>The matchmaker keeps one live ticket per player and mode. The second queue
call returns the first client's ticket, and a group that repeats a player is
rejected, so the two can never be paired with each other.</li>
<li>Server-to-player messages are addressed by player id and reach <strong>both</strong>
connections, so each client sees the other's match traffic.</li>
<li>Closing one client tears down presence for the player the other one is still
using.</li>
</ul>
<h2 id="the-quickest-fix-a-throwaway-guest-per-launch" tabindex="-1">The quickest fix: a throwaway guest per launch</h2>
<p><code>generate</code> mints a pair without persisting it, so every launch is a brand-new
player. Two lines, no storage plumbing, no per-instance setup. This is the right
default for a dev build.</p>
<div class="tabbed-code"><input type="radio" name="testplayers-tab0" id="testplayers-tab0-1" checked><input type="radio" name="testplayers-tab0" id="testplayers-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="testplayers-tab0-1">Defold</label><label for="testplayers-tab0-2">Godot</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">local asobi = require("asobi.client")
local device = require("asobi.device")

function init(self)
	local client = asobi.create("localhost", 8084)

	-- Dev only: a fresh pair per launch, never written to disk, so every
	-- instance you start is a different player.
	local device_id, device_secret = device.generate()
	client.auth.guest(client, device_id, device_secret, function(data, err)
		if err then
			print("guest sign-in failed: " .. tostring(err.error))
			return
		end
		print("player_id: " .. data.player_id)
		client.realtime:connect()
	end)
end</code></pre><pre class="tabbed-code-panel"><code class="language-gdscript">func _ready() -&gt; void:
	Asobi.host = "localhost"
	Asobi.port = 8084

	# Dev only: a fresh pair per launch, never written to user://, so every
	# instance you start is a different player.
	var creds := AsobiDevice.generate()
	var resp := await Asobi.auth.guest(creds["device_id"], creds["device_secret"])
	if resp.has("error"):
		push_error("guest sign-in failed: %s" % resp.error)
		return
	print("player_id: %s" % resp.player_id)
	Asobi.realtime.connect_to_server()</code></pre></div></div>
<p>Every run leaves another guest account on the node. That is harmless locally,
and <code>guest_reap_after</code> clears unclaimed guests on a real deployment. Ship
<code>guest_device</code> in the build players actually install.</p>
<h2 id="stable-test-players-across-runs" tabindex="-1">Stable test players across runs</h2>
<p>A throwaway guest has no history, so it is no use for testing progression,
leaderboards or an inventory. Give each instance its own storage slot instead
and the same players come back every run.</p>
<h3 id="defold" tabindex="-1">Defold</h3>
<p>The engine takes <code>--config=</code> overrides for any <code>game.project</code> key, and Lua reads
them back, which gives you a per-instance slot without touching the code between
runs:</p>
<pre><code class="language-lua">local slot = sys.get_config_string(&quot;asobi.player_slot&quot;, &quot;1&quot;)

client.auth.guest_device(client, { file = &quot;guest_device_&quot; .. slot }, function(data, err)
	if err then
		print(&quot;guest sign-in failed: &quot; .. tostring(err.error))
		return
	end
	print(&quot;slot &quot; .. slot .. &quot; is &quot; .. data.player_id)
end)
</code></pre>
<p>The editor's Build runs one instance, so bundle the game once (Project &gt;
Bundle) and launch the executable twice:</p>
<pre><code class="language-bash">./MyGame &amp;                                # slot 1
./MyGame --config=asobi.player_slot=2 &amp;   # slot 2
</code></pre>
<h3 id="godot" tabindex="-1">Godot</h3>
<p>Godot can launch several instances itself. Open Debug &gt; Customize Run
Instances..., raise the instance count, and give each instance its own Launch
Arguments (<code>-- player=2</code> for the second one). Arguments after <code>--</code> come back
from <code>OS.get_cmdline_user_args()</code>:</p>
<pre><code class="language-gdscript">func _player_slot() -&gt; String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(&quot;player=&quot;):
			return arg.trim_prefix(&quot;player=&quot;)
	return &quot;1&quot;

func _ready() -&gt; void:
	var slot := _player_slot()
	var resp := await Asobi.auth.guest_device({&quot;path&quot;: &quot;user://asobi_device_%s.json&quot; % slot})
	if resp.has(&quot;error&quot;):
		push_error(&quot;guest sign-in failed: %s&quot; % resp.error)
		return
	print(&quot;slot %s is %s&quot; % [slot, resp.player_id])
</code></pre>
<p>To swap players inside a running client instead, call the SDK's <code>clear</code> and sign
in again: the next <code>guest_device</code> mints a new guest and returns <code>created = true</code>.
<code>clear</code> is local only and does not delete the account on the server.</p>
<h2 id="two-players-two-matches" tabindex="-1">Two players, two matches</h2>
<p>Distinct players can still land in separate matches. In order of how often it
happens:</p>
<ul>
<li><strong>Bots got there first.</strong> The bot spawner checks every 8 seconds and tops each
mode up to its target, so one human waiting more than 8 seconds is matched
with a bot, and the second human then gets a match of their own. Drop the
<code>bots</code> line from the match script while testing human against human. See
<a href="/docs/lua/bots">Lua bots</a>.</li>
<li><strong>Different modes.</strong> Tickets are grouped per mode, and a typo in the mode
string is two queues of one.</li>
<li><strong><code>match_size = 1</code>.</strong> Every ticket spawns its own match by definition.</li>
<li><strong><code>match_size</code> above the number of clients you are running.</strong> The tickets wait
until <code>max_wait_seconds</code> expires them.</li>
</ul>
<h2 id="checklist" tabindex="-1">Checklist</h2>
<ol>
<li>Print <code>player_id</code> in every client. Different ids, or nothing else here
matters.</li>
<li>Use <code>generate</code> in dev builds, or one storage slot per instance.</li>
<li>Turn bots off while you are testing that two humans pair.</li>
<li>Queue both clients for the same mode, within a few seconds of each other.</li>
</ol>
<p>See <a href="/docs/authentication#guest-anonymous">Authentication</a> for the guest contract
itself, and <a href="/docs/matchmaking">Matchmaking</a> for ticket and strategy behaviour.</p>
"""}
    ]}.
