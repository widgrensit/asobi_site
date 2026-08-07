%% GENERATED from asobi guides/glossary.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_glossary_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-glossary", title => ~"Glossary — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Glossary"
        ]},
        {h1, [], [~"Project glossary"]},
        {raw,
            ~"""
<p>Names you will meet across the docs, the repos and the Discord. Read this first
if they blur together.</p>
<h2 id="asobi" tabindex="-1">asobi</h2>
<p>One project with two front doors.</p>
<p><strong>As a runnable node.</strong> The image <code>ghcr.io/widgrensit/asobi</code> is a complete
game backend: the match and world servers, matchmaking, economy, social, chat,
leaderboards, the Lua runtime and the operator console, in one Erlang/OTP
release. The binary inside it is <code>bin/asobi</code>. Write <code>match.lua</code>, point the node
at it, <code>docker compose up</code>.</p>
<p><strong>As a Hex library.</strong> <a href="https://hex.pm/packages/asobi"><code>asobi</code> on Hex</a> is the
same code as a dependency. Add <code>{asobi, &quot;~&gt; 0.68&quot;}</code> to <code>rebar.config</code> and
implement the <code>asobi_match</code> behaviour when you want a callback in Erlang rather
than Lua.</p>
<p>Lua is not a wrapper, an add-on or a separate runtime. It ships in the node.
The <code>asobi_lua</code> repo is retired and its code lives here, under <code>src/lua/</code>.</p>
<p><code>asobi_lua</code> still appears in three places that are correct and must not be
renamed: module names (<code>asobi_lua_config</code>, <code>asobi_lua_api</code>, <code>asobi_lua_loader</code>
and friends), the <code>ASOBI_LUA_RELOAD</code> variable, and <code>{asobi_lua, [...]}</code> config
blocks, which are still read - see
<a href="/docs/configuration#which-application-key">Which application key</a>.</p>
<p>The one stale <code>asobi_lua</code> is the image name. <code>ghcr.io/widgrensit/asobi_lua</code>
is no longer rebuilt: tags already published keep working and are never
deleted, but they receive no fixes. Use <code>ghcr.io/widgrensit/asobi</code>.</p>
<h2 id="client-sdks" tabindex="-1">Client SDKs</h2>
<p>One per engine, all speaking the same WebSocket and REST protocol:
<a href="https://github.com/widgrensit/asobi-love2d">asobi-love2d</a> (LÖVE),
<a href="https://github.com/widgrensit/asobi-defold">asobi-defold</a>,
<a href="https://github.com/widgrensit/asobi-godot">asobi-godot</a>,
<a href="https://github.com/widgrensit/asobi-unity">asobi-unity</a>,
<a href="https://github.com/widgrensit/asobi-unreal">asobi-unreal</a>,
<a href="https://github.com/widgrensit/asobi-js">asobi-js</a>,
<a href="https://github.com/widgrensit/asobi-dart">asobi-dart</a> and
<a href="https://github.com/widgrensit/flame_asobi">flame_asobi</a>. Full table with docs
and demos in the <a href="../README.md#client-sdks">README</a>.</p>
<h2 id="the-commercial-layer" tabindex="-1">The commercial layer</h2>
<p><strong>asobi.dev Cloud</strong> - managed hosting, running the same core as the node
described above. <strong>Invite-only</strong>: an account is created only from an operator
allowlist or an approved waitlist request. Join the waitlist at
<a href="https://console.asobi.dev">console.asobi.dev</a>.</p>
<p>The differences are operational, not functional. A cloud environment is created
and fed Lua through the <code>asobi</code> CLI rather than a mounted <code>/app/game</code>, its
console is reached from the dashboard rather than by holding an operator secret,
and the environment's <code>sys.config</code> is not yours to write - which rules out
platform sign-in, IAP receipt verification, extensions and runtime tuning.
Everything about the game itself - callbacks, protocol, error codes - is
identical. <a href="https://hexdocs.pm/asobi/cloud.html">Cloud</a> has the full list of what each side gets.</p>
<p>If it disappears, the open-source node above is enough to run your game
forever. See <a href="https://hexdocs.pm/asobi/exit.html">exit.md</a>.</p>
<h2 id="which-one-do-i-start-with" tabindex="-1">Which one do I start with?</h2>
<p>Run the image and write Lua. That is the default path and it needs no Erlang.</p>
<p>Depend on the Hex package if you are writing Erlang callbacks - a hot loop, a
custom matchmaking strategy, an extension.</p>
<p>You do not choose between them. The same node serves both, plus the console.</p>
<h2 id="concepts-not-projects" tabindex="-1">Concepts, not projects</h2>
<p>Vocabulary you will meet throughout the docs.</p>
<ul>
<li><strong>Match</strong> - a short-lived gameplay session. 2 to N players, finite duration,
result persisted. One <code>gen_statem</code> under <code>asobi_match_sup</code>, ticking on a
state timeout.</li>
<li><strong>World</strong> - a long-lived environment. Players come and go, state persists
across disconnects. Think MMO zone, town, dungeon. One world lives entirely
on one node.</li>
<li><strong>Zone</strong> - a spatial partition inside a world, used to shard a large world
into separately ticked chunks.</li>
<li><strong>Session</strong> - one process per connection, started when the socket sends
<code>session.connect</code> and ended when the socket closes. It does not survive the
connection: a reconnecting client presents the same token and gets a new
session.</li>
<li><strong>Console</strong> - the operator UI this node serves at <code>/console</code>. Off until
<code>console</code> is set. See <a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</li>
<li><strong>Ops plane</strong> - the HTTP API at <code>/api/v1/ops/*</code> that the console reads. Its
own credential, separate from the console flag, and reads apart from player
erasure, player export and extension actions.</li>
<li><strong>Capability class</strong> - what an ops route is allowed to touch: <code>read</code>,
<code>player_data</code>, <code>config</code> or <code>erasure</code>. Every core ops route carries one.
<code>erasure</code> is separate because it is the only one that cannot be undone.</li>
<li><strong>Erasure</strong> - deleting a player and everything core holds about them, in one
transaction. <code>asobi_player_erase:run/1</code> from a shell, or
<code>POST /api/v1/ops/players/:id/erase</code>. See <a href="/docs/protocols/rest">REST API</a>.</li>
<li><strong>Extension</strong> - an OTP application that depends on asobi, added to your
release, declaring a manifest. It can add RPC methods, workers, schemas and
ops actions without forking asobi. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a>.</li>
<li><strong>RPC method</strong> - how a client calls an extension. One WebSocket frame type:
<code>rpc.call</code> in with a <code>method</code> and <code>params</code>, <code>rpc.ok</code> or <code>rpc.error</code> back,
paired by <code>cid</code>.</li>
<li><strong>Tenant</strong> - a studio or account in the managed cloud. Not a concept when
self-hosting. See <a href="https://hexdocs.pm/asobi/cloud.html">Cloud</a>.</li>
<li><strong>Bundle</strong> - the zip of <code>.lua</code> files the CLI uploads to a cloud environment,
which the engine fetches and extracts at boot. The cloud equivalent of a
mounted <code>/app/game</code>. Not a concept when self-hosting.</li>
<li><strong>Game</strong> - the product you are shipping. One game may have many match modes
and worlds.</li>
</ul>
<p>When two words compete (<em>match</em> against <em>room</em>, <em>world</em> against <em>realm</em>),
asobi uses the first. The <a href="https://hexdocs.pm/asobi/migrate-from-nakama.html">Nakama</a>,
<a href="https://hexdocs.pm/asobi/migrate-from-playfab.html">PlayFab</a> and <a href="https://hexdocs.pm/asobi/migrate-from-hathora.html">Hathora</a>
migration guides carry mapping tables from competitor vocabulary.</p>
"""}
    ]}.
