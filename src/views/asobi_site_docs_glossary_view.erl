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
<p>You'll see several &quot;asobi&quot; names in docs, repos, and the Discord. Here's what
each one is and when to reach for it. Read this page first if you're new —
the names look interchangeable and aren't.</p>
<h2 id="the-open-source-pieces" tabindex="-1">The open-source pieces</h2>
<p><strong>asobi</strong> — the public Erlang library published on
<a href="https://hex.pm/packages/asobi">Hex</a>. Depend on it in <code>rebar.config</code> if
you're writing your game backend directly in Erlang/OTP and want match,
matchmaking, world-server, voting, economy, and the rest as composable
OTP behaviours. This is the library underneath everything.</p>
<p><strong>asobi_lua</strong> — the batteries-included runtime that wraps the <code>asobi</code>
library with a <a href="https://github.com/rvirding/luerl">Luerl</a> VM so you can
write game logic in Lua without knowing Erlang. Ships as a Docker image at
<code>ghcr.io/widgrensit/asobi_lua</code>. Most people start here.</p>
<p><strong>Arena Shooter</strong> — the flagship end-to-end sample: a full multiplayer game
(server-authoritative movement and combat, matchmaking with bots, boons,
round voting, a leaderboard), not a snippet.</p>
<h2 id="client-sdks" tabindex="-1">Client SDKs</h2>
<p><strong>asobi-godot, asobi-defold, asobi-unity, asobi-unreal, asobi-js,
asobi-dart, flame_asobi</strong> — one per engine, all talking to asobi over
WebSocket + REST. See the <a href="../README.md#client-sdks">SDK table in the
README</a>.</p>
<h2 id="the-commercial-layer" tabindex="-1">The commercial layer</h2>
<p><strong>asobi.dev Cloud</strong> — managed hosting, opening later in 2026. Same binary
you can self-host today, with opinionated ops and flat per-container
pricing. Join the waitlist at <a href="https://asobi.dev/cloud">asobi.dev/cloud</a>.</p>
<p>If we disappear, the open-source pieces above are enough to run your game
forever. See <a href="https://hexdocs.pm/asobi/exit.html">exit.md</a> for the runbook.</p>
<h2 id="which-one-do-i-start-with" tabindex="-1">Which one do I start with?</h2>
<ul>
<li><strong>&quot;I want to write Lua.&quot;</strong> → <code>asobi_lua</code>. Pull the Docker image, write
<code>match.lua</code>, <code>docker compose up</code>.</li>
<li><strong>&quot;I want to write Erlang.&quot;</strong> → <code>asobi</code>. Add it to <code>rebar.config</code>,
implement the <code>asobi_match</code> behaviour.</li>
<li><strong>&quot;I want both.&quot;</strong> → <code>asobi_lua</code> hosts your Lua code and is itself built
on the <code>asobi</code> library. You can drop from Lua into an Erlang behaviour
for a hot loop without leaving the process.</li>
<li><strong>&quot;I just want hosting.&quot;</strong> → self-host <code>asobi_lua</code> today, or join the
<code>asobi.dev/cloud</code> waitlist.</li>
</ul>
<h2 id="concepts-not-projects" tabindex="-1">Concepts, not projects</h2>
<p>These are vocabulary, not repositories. You'll see them throughout the
docs:</p>
<ul>
<li><strong>Match</strong> — a short-lived gameplay session. 2 to N players, finite
duration, result persisted. Runs as a <code>gen_server</code> under a supervisor.</li>
<li><strong>World</strong> — a long-lived persistent environment. Players come and go,
state persists across disconnects. Think MMO zone, town, dungeon.</li>
<li><strong>Zone</strong> — a spatial partition inside a world. Used for sharding large
worlds into loadable chunks.</li>
<li><strong>Session</strong> — a player's authenticated connection. Survives
reconnection with a session token.</li>
<li><strong>Tenant</strong> — a studio or account in the managed cloud. You don't see
this when self-hosting.</li>
<li><strong>Game</strong> — the product you're shipping. One game may have many match
modes, worlds, and tenants.</li>
</ul>
<p>When two words compete (e.g. <em>match</em> vs <em>room</em>, <em>world</em> vs <em>realm</em>),
asobi uses the first one. The <a href="https://hexdocs.pm/asobi/migrate-from-nakama.html">Nakama migration
guide</a> and <a href="https://hexdocs.pm/asobi/migrate-from-hathora.html">Hathora migration
guide</a> include mapping tables from competitor
vocab to asobi vocab.</p>
"""}
    ]}.
