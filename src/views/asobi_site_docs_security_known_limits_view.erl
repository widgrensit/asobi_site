%% GENERATED from asobi guides/security-known-limitations.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_security_known_limits_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-known", title => ~"Known limitations — Asobi docs"}, Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Security / Known limitations"
        ]},
        {h1, [], [~"Known limitations"]},
        {raw,
            ~"""
<p>The asobi runtime closes a deliberate set of attack surfaces
(documented in <a href="/docs/security/threat-model">Threat model</a> and
<a href="/docs/security/auth">Authentication &amp; rate limiting</a>). The list below
is the complement: properties the runtime does <strong>not</strong> enforce, and
where the responsibility lies.</p>
<h2 id="game-module-crashes-can-take-the-lobby-down" tabindex="-1">Game module crashes can take the lobby down</h2>
<p><code>asobi_match_server</code> calls game-module callbacks (<code>Mod:join/2</code>,
<code>Mod:tick/1</code>, <code>Mod:handle_input/3</code>, phase / vote callbacks) inline and
<strong>without</strong> wrapping them in <code>try/catch</code>. This is intentional:</p>
<ul>
<li>asobi is single-tenant by design — one VM owns the world processes
and there is no other game module to fail over to.</li>
<li>A crash is treated as a <strong>bug</strong> worth surfacing (transient restart,
intensity 10 / period 60). After 10 crashes in 60s the entire
<code>asobi_match_sup</code> falls over, intentionally taking the lobby with it
so an obviously broken game cannot keep churning silently.</li>
<li>For multi-tenant or sandboxed scenarios, layer <code>asobi_lua</code> or your
own sandbox on top — that is the place to put callback hardening.</li>
</ul>
<p>Because callbacks run inline with full BEAM access, a game module can read
public ETS, spawn arbitrary processes, reach clustered nodes, and crash the
lobby. Treat the game-module source as part of the trusted compute base — code
review and sign its releases the same way you would the asobi binary itself. For
untrusted scripting (community maps, modder content), use the
<a href="https://github.com/widgrensit/asobi_lua/blob/main/guides/security-sandbox.md">Lua sandbox</a>:
Luerl runs scripts in a hardened state with OS/IO/code-loading APIs stripped and
a wall-clock budget per callback.</p>
<p>If you need callback isolation in your custom game module, run the
hot-path logic in a worker process so a crash is contained.</p>
<h2 id="erlang-distribution-is-enabled-by-default" tabindex="-1">Erlang distribution is enabled by default</h2>
<p><code>config/vm.args.src</code> sets <code>-name asobi@${ASOBI_NODE_HOST}</code> and
<code>-setcookie ${ERLANG_COOKIE}</code>. EPMD binds to <code>0.0.0.0:4369</code> and dist
ports are unbounded; the cookie is the only protection. If the cookie
leaks (env var, container snapshot, k8s secret), anyone with network
reach to the dist port has full code-execution.</p>
<p>For single-node deploys, uncomment the localhost-bind line in
<code>vm.args.src</code>. For clusters, configure <code>inet_dist_listen_min/max</code> and
TLS for distribution. See <a href="/docs/security/threat-model">Threat model</a>.</p>
<h2 id="public-ets-tables-are-reachable-from-any-in-vm-code" tabindex="-1">Public ETS tables are reachable from any in-VM code</h2>
<p><code>asobi_world_state</code>, <code>asobi_player_worlds</code>, <code>asobi_match_state</code>,
<code>asobi_chat_registry</code>, <code>asobi_zone_mgr</code> are all <code>public</code> named ETS
tables. Plugins, custom game modules, and NIFs in the same BEAM can
read or mutate them. asobi treats this as acceptable because all in-VM
code is trusted by design (see <a href="/docs/security/threat-model">Threat model</a>).</p>
<p>Any Lua sandbox layered on top (<code>asobi_lua</code>) MUST keep its sandbox out
of these tables.</p>
<h2 id="uuidv7-ids-leak-creation-timestamp" tabindex="-1">UUIDv7 ids leak creation timestamp</h2>
<p><code>asobi_id:generate/0</code> produces UUIDv7. The high 48 bits are a
millisecond timestamp. <code>player.id</code> lives forever and reveals account
creation time when exposed. For unguessable, non-correlatable
identifiers (auth tokens, invite codes, session secrets) use
<code>crypto:strong_rand_bytes/1</code> — never <code>asobi_id:generate/0</code>.</p>
<h2 id="compute-memory-bounds-are-best-effort" tabindex="-1">Compute / memory bounds are best-effort</h2>
<p>The runtime caps individual <em>requests</em> (limits, body sizes, quantities;
see <a href="/docs/security/auth">Authentication &amp; rate limiting</a>). It does <strong>not</strong>
enforce a per-process reduction count, heap cap, or scheduler quota.
Enforcement of those happens at the OS / container layer:</p>
<ul>
<li>Production deployments should run with cgroup memory + CPU limits.</li>
<li>Set <code>+P</code> (process limit) and <code>+Q</code> (port limit) in <code>vm.args</code> to
bound BEAM-level resources.</li>
<li>A long-running plugin or game module that allocates without bound
will pressure the OS allocator before any in-VM mechanism notices.</li>
</ul>
<h2 id="container-release-tree-is-writable" tabindex="-1">Container release tree is writable</h2>
<p>The published <code>asobi_lua</code> image runs as the non-root <code>asobi</code> user but does not
declare <code>--read-only</code>. The README example mounts <code>/app/game</code> as <code>:ro</code>, but that
is the operator's responsibility, not the runtime's. For a hardened deployment,
run with <code>docker run --read-only --tmpfs /tmp</code> and chown only the game directory
to the runtime user — the rest of <code>/app</code> should stay root-owned and read-only.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/security/threat-model">Threat model</a> - the trust assumptions this page's limits follow from.</li>
<li><a href="/docs/security/auth">Auth &amp; rate limiting</a> - the per-request bounds the runtime does enforce.</li>
</ul>
"""}
    ]}.
