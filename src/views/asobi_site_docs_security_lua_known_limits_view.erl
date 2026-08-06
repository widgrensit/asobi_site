%% GENERATED from asobi guides/security-lua-known-limitations.md - do not edit by hand.
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
        {h1, [], [~"Known limitations (Lua sandbox)"]},
        {raw,
            ~"""
<p>The Lua sandbox closes a deliberate set of attack surfaces, documented in
<a href="/docs/security/lua-sandbox">Sandbox model</a>. This page is the complement: what it does
not enforce. Plan the deployment around any of these that matter to you.</p>
<h2 id="resource-bounds" tabindex="-1">Resource bounds</h2>
<h3 id="the-cpu-bound-is-sampled-not-exact" tabindex="-1">The CPU bound is sampled, not exact</h3>
<p>Every callback that runs in a child process carries three bounds: a wall-clock
timeout, a per-eval heap cap and a reduction budget. The reduction budget is
the CPU bound, and it is needed because a timeout bounds latency, not work: a
script can soak its whole wall-clock budget every tick and be killed at the
deadline each time, burning a scheduler indefinitely.</p>
<p>The budget is <code>max_reductions_per_ms</code> (50,000 by default) multiplied by that
callback's own wall-clock budget, so it scales with the callback: <code>tick</code> at 500
ms gets 25,000,000 reductions, a bot's <code>think</code> at 50 ms gets 2,500,000.
Overrun surfaces as <code>{error, reductions_exhausted}</code>, distinct from <code>timeout</code>
and <code>heap_exhausted</code>. As with the other two, the result is discarded and the
previous Lua state is kept; a match or zone is never torn down because one
callback overran. Set the rate to <code>0</code> to disable the check.</p>
<p>Two limits are worth knowing:</p>
<ul>
<li>The parent samples the child's reduction count every 10 ms
(<code>?REDUCTION_POLL_MS</code>), so a script can overshoot by up to one interval's
work before it is killed. The budget bounds sustained CPU, not the
instantaneous peak.</li>
<li>asobi does not use <code>luerl_sandbox:run/3</code>, which offers the same idea
upstream. That function evaluates a chunk, whereas asobi's hot path is
<code>luerl:call_function/3</code> against an already-loaded state, so the polling loop
lives in <code>bounded_eval</code> in <code>asobi_lua_loader</code>, which had already spawned and
monitored the worker.</li>
</ul>
<p><code>handle_input/3</code> is the exception: it runs inline in the calling process with
no child, so none of the three bounds apply. Its cost is a hung match or zone
process, not a supervisor event - see <a href="/docs/security/lua-trust-model#handle-input-is-not-a-sandbox-boundary">handle-input is not a sandbox
boundary</a>.</p>
<h3 id="the-heap-cap-is-per-eval-not-per-script" tabindex="-1">The heap cap is per eval, not per script</h3>
<p>Each callback child carries <code>max_heap_size</code> with <code>kill =&gt; true</code>
(<code>max_heap_words</code>, 5,000,000 words by default), so one runaway allocation is
killed and surfaces as <code>{error, heap_exhausted}</code>. Nothing caps a script's
steady footprint: a state that sits just under the limit is copied into every
later eval, and the total across concurrent matches is unbounded. The decode
depth cap of 64 levels bounds recursion at the bridge boundary, not table size.</p>
<h3 id="the-per-callback-state-copy-is-linear" tabindex="-1">The per-callback state copy is linear</h3>
<p>Each bounded callback spawns a child that takes a full copy of the Luerl state.
Cost is linear in script-side allocation, so a script that deliberately builds
large stable tables makes every later callback pay the copy. Watch for
unexplained per-tick latency growth on long-lived matches.</p>
<h2 id="deployment-hygiene" tabindex="-1">Deployment hygiene</h2>
<h3 id="the-release-tree-in-the-container-is-writable" tabindex="-1">The release tree in the container is writable</h3>
<p>The published image runs as the non-root <code>asobi</code> user, but its Dockerfile
chowns all of <code>/app</code> to that user and the image does not declare <code>--read-only</code>.
Mounting the game directory <code>:ro</code> is the operator's move, not the runtime's.
<a href="/docs/security/known-limitations#the-release-tree-in-the-container-is-writable">Known limitations</a>
carries the run command that makes the rest of the tree read-only.</p>
<h3 id="symlinks-under-the-game-directory" tabindex="-1">Symlinks under the game directory</h3>
<p><code>require</code> refuses a symlink at resolve time, so a symlink at <code>&lt;base&gt;/foo.lua</code>
is not followed. That is defence in depth: keep the game directory mounted
read-only, and keep symlinks out of the build pipeline in the first place.</p>
<h2 id="behavioural" tabindex="-1">Behavioural</h2>
<h3 id="mid-callback-rollback-is-best-effort" tabindex="-1">Mid-callback rollback is best-effort</h3>
<p>If a callback is killed by its budget after it has already made a
side-effecting <code>game.*</code> call (<code>game.economy.debit</code>, say), the side effect
stands. The Lua state reverts to the previous tick; the asobi-side ledger does
not. Treat economy, leaderboard and storage mutations as best-effort committed.
For high-stakes flows, checkpoint state around the call so the next tick can
reconcile.</p>
<h3 id="a-failing-bot-think2-falls-back-to-the-built-in-ai" tabindex="-1">A failing bot <code>think/2</code> falls back to the built-in AI</h3>
<p>When <code>think/2</code> errors, <code>asobi_bot</code> substitutes the default AI and emits a
rate-limited warning, one line per bot per minute (<code>maybe_log_think_error</code>).
The match keeps running, so a broken bot script is visible in the logs but not
in the gameplay. Monitor for it if you rely on bot scripts.</p>
<h2 id="logging" tabindex="-1">Logging</h2>
<h3 id="the-require_failed-payload-is-truncated" tabindex="-1">The <code>require_failed</code> payload is truncated</h3>
<p>When <code>luerl:do/2</code> rejects a <code>require</code>d file - non-Lua content, invalid syntax -
the compiler error list is cut to the first three entries plus a <code>truncated</code>
marker before it propagates. A binary file placed under the game directory by
mistake therefore cannot dump arbitrary bytes into the structured log pipeline.</p>
<h2 id="related" tabindex="-1">Related</h2>
<ul>
<li><a href="/docs/security/lua-sandbox">Sandbox model</a> - what the sandbox removes, replaces and bounds.</li>
<li><a href="/docs/security/lua-trust-model">Trust model</a> - what it is and is not a boundary against.</li>
<li><a href="/docs/security/known-limitations">Known limitations</a> - the same for in-VM Erlang code.</li>
<li><a href="/docs/security/threat-model">Threat model</a> - the node-level trust boundaries.</li>
<li><a href="/docs/security/auth">Auth and rate limiting</a> - the request-side bounds.</li>
</ul>
"""}
    ]}.
