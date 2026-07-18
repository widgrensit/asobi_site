%% GENERATED from asobi guides/security-known-limitations.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_security_lua_known_limits_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-lua-known", title => ~"Lua known limitations — Asobi docs"}, Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Security / Lua known limitations"
        ]},
        {h1, [], [~"Known limitations"]},
        {raw,
            ~"""
<p>The asobi_lua sandbox closes a deliberate set of attack surfaces
(documented in <a href="/docs/security/lua-sandbox">Sandbox model</a>). The list below is
the complement: properties the sandbox does <strong>not</strong> enforce. Operators
who care about any of these should plan their deployment accordingly.</p>
<h2 id="resource-bounds" tabindex="-1">Resource bounds</h2>
<h3 id="no-reduction-limit-hard-cpu-cap" tabindex="-1">No reduction limit / hard CPU cap</h3>
<p>The wall-clock timeout is the only resource bound today. A script can
soak its full per-callback budget every tick without being throttled.
Luerl upstream does not currently expose a &quot;reduction limit&quot; or
&quot;process-bound state&quot; knob; a future hardening pass may add a soft
budget on the Luerl scheduler.</p>
<h3 id="no-per-script-heap-cap" tabindex="-1">No per-script heap cap</h3>
<p>Lua tables grow inside the BEAM process heap. A pathological script
that allocates 100 MB of tables and drops them every tick will pressure
the OS memory allocator. The decode depth cap (64 levels) bounds
recursion at the bridge boundary, but does not bound table <em>size</em>.</p>
<h3 id="per-callback-state-copy-cost-is-linear" tabindex="-1">Per-callback state copy cost is linear</h3>
<p>Each timeout-wrapped callback spawns a child process that takes a full
copy of the Luerl state (<code>spawn(fun() -&gt; call(..., St) end)</code>). Cost is
linear in script-side allocation. A script that intentionally builds
large stable tables forces every later callback to pay the copy. Watch
for unexplained per-tick latency growth on long-lived matches.</p>
<h2 id="deployment-hygiene" tabindex="-1">Deployment hygiene</h2>
<h3 id="the-container-release-tree-is-writable" tabindex="-1">The container release tree is writable</h3>
<p>The shipped Dockerfile runs as the non-root <code>asobi</code> user but does not
declare <code>--read-only</code>. The README example mounts <code>/app/game</code> <code>:ro</code>;
that mode is the <strong>operator's</strong> responsibility, not the runtime's. We
recommend <code>docker run --read-only --tmpfs /tmp</code> and chowning only
<code>/app/game</code> to the runtime user (the rest of <code>/app</code> should stay
root-owned + read-only).</p>
<h3 id="symlinks-under-the-game-dir" tabindex="-1">Symlinks under the game dir</h3>
<p><code>require</code> rejects symlinks at resolve time, so a misplaced symlink
under <code>&lt;base&gt;/foo.lua</code> no longer slips through. This is defense in
depth: keep the game dir mounted read-only and the build pipeline
should not produce symlinks in the first place.</p>
<h2 id="behavioural" tabindex="-1">Behavioural</h2>
<h3 id="mid-callback-rollback-is-best-effort" tabindex="-1">Mid-callback rollback is best-effort</h3>
<p>If a callback is killed by its wall-clock timeout <em>after</em> it has
already issued a side-effecting <code>game.*</code> API call (e.g.
<code>game.economy.debit</code>), the side effect persists. The Lua-side state
reverts to the prior tick but the asobi-side ledger does not. Treat
economy / leaderboard / storage mutations as <strong>best-effort committed</strong>.
For high-stakes flows, checkpoint state before/after the API call so
the next tick reconciles, or wrap mutations in a transactional helper
tagged with the call's ref.</p>
<h3 id="bot-think2-errors-fall-back-to-the-built-in-default-ai" tabindex="-1">Bot <code>think/2</code> errors fall back to the built-in default AI</h3>
<p>A rate-limited <code>logger:warning</code> is emitted (one line per bot per
minute) when the fallback fires so persistently-broken scripts are
visible — see the <code>maybe_log_think_error</code> helper in <code>asobi_bot</code>.
Operators who rely on bot scripts should still monitor behaviour
externally; a silent fallback bot will keep playing the match without
ever calling your custom AI.</p>
<h2 id="logging" tabindex="-1">Logging</h2>
<h3 id="require_failed-error-payload-is-truncated" tabindex="-1"><code>require_failed</code> error payload is truncated</h3>
<p>When <code>luerl:do/2</code> rejects a <code>require</code>'d file (non-Lua content,
syntactically invalid Lua), the compiler error list is truncated to the
first three entries before propagating. This prevents a binary file
mistakenly placed under the game dir from dumping arbitrary bytes into
the structured log pipeline.</p>
"""}
    ]}.
