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
<p>asobi closes a deliberate set of attack surfaces, documented in <a href="/docs/security/threat-model">Threat
model</a> and <a href="/docs/security/auth">Auth and rate
limiting</a>. This page is the complement: what the runtime does
not enforce, and where the responsibility sits instead.</p>
<h2 id="a-crashing-game-module-takes-matches-with-it" tabindex="-1">A crashing game module takes matches with it</h2>
<p><code>asobi_match_server</code> calls game-module callbacks in Erlang (<code>Mod:join/2</code>,
<code>Mod:tick/1</code>, <code>Mod:handle_input/3</code>, phase and vote callbacks) inline, with no
<code>try/catch</code>. That is intentional:</p>
<ul>
<li>One VM owns the world processes, and there is no other game module to fail
over to.</li>
<li>A crash is a bug worth surfacing. The match restarts (<code>transient</code>), and past
10 crashes in 60 seconds <code>asobi_match_sup</code> exits and <code>asobi_sup</code> restarts it,
taking every live match on the node with it, rather than letting a broken
game churn quietly.</li>
</ul>
<p>Because these callbacks run inline with full BEAM access, a game module can
read public ETS, spawn processes, reach clustered nodes and crash the node.
Treat its source as part of the trusted compute base: review it and sign its
releases the way you would the asobi binary. If you need isolation inside your
own module, run the hot-path logic in a worker process so a crash is contained.</p>
<p>For untrusted scripting - community maps, modder content - write the game in
Lua instead. Luerl runs scripts in a hardened state with OS, I/O and
code-loading APIs stripped and a budget per callback: see <a href="/docs/security/lua-sandbox">Sandbox
model</a>.</p>
<h2 id="erlang-distribution-is-on-by-default" tabindex="-1">Erlang distribution is on by default</h2>
<p><code>config/vm.args.src</code> sets <code>-name asobi@${ASOBI_NODE_HOST}</code> and
<code>-setcookie ${ERLANG_COOKIE}</code>. EPMD listens on <code>0.0.0.0:4369</code>, the distribution
port range is unbounded, and the cookie is the only protection. The published
image ships a fixed, publicly known <code>ERLANG_COOKIE=asobi</code>, so any deployment
that exposes the distribution port must override it.</p>
<p>For a single node, uncomment the localhost bind in <code>vm.args.src</code>. For a
cluster, constrain <code>inet_dist_listen_min/max</code> and turn on TLS for
distribution. See <a href="/docs/security/threat-model#erlang-distribution">Threat model</a>.</p>
<h2 id="public-ets-is-reachable-from-any-in-vm-code" tabindex="-1">Public ETS is reachable from any in-VM code</h2>
<p><code>asobi_world_state</code>, <code>asobi_player_worlds</code>, <code>asobi_match_state</code>,
<code>asobi_chat_registry</code>, <code>asobi_zone_mgr</code> and <code>asobi_terrain_cache</code> are all
<code>public</code>. Plugins, game modules in Erlang and NIFs in the same BEAM can read or
mutate them. asobi accepts that because all in-VM code is trusted by design.
Lua has no ETS access; the <code>game.*</code> bridge is the only path from a script into
host state.</p>
<h2 id="uuidv7-ids-leak-a-creation-timestamp" tabindex="-1">UUIDv7 ids leak a creation timestamp</h2>
<p><code>asobi_id:generate/0</code> produces UUIDv7, whose high 48 bits are a millisecond
timestamp. <code>player.id</code> lives forever and so reveals account-creation time
wherever it is exposed. For unguessable, non-correlatable identifiers - auth
tokens, invite codes - use <code>crypto:strong_rand_bytes/1</code>.</p>
<h2 id="in-vm-compute-and-memory-bounds-are-the-oss-job" tabindex="-1">In-VM compute and memory bounds are the OS's job</h2>
<p>Per-request bounds exist (limits, body sizes, quantities: see <a href="/docs/security/auth">Auth and rate
limiting</a>), and Lua callbacks are separately bounded by a
wall-clock timeout, a heap cap and a reduction budget (see <a href="/docs/security/lua-sandbox#per-callback-budgets">Sandbox
model</a>). What is not bounded is
trusted in-VM Erlang code: a game module, a plugin or a NIF gets no reduction
count, no heap cap and no scheduler quota. Enforcement for those is at the OS
or container layer:</p>
<ul>
<li>Run with cgroup memory and CPU limits.</li>
<li><code>vm.args</code> already ships <code>+P 1048576</code> and <code>+Q 65536</code>. Those are ceilings sized
for a large node; lower them to something your cgroup can actually back, so
the BEAM refuses a new process instead of the OOM killer taking the node.</li>
<li>A plugin or game module that allocates without bound will pressure the OS
allocator before anything in the VM notices.</li>
</ul>
<h2 id="the-release-tree-in-the-container-is-writable" tabindex="-1">The release tree in the container is writable</h2>
<p>The published <code>ghcr.io/widgrensit/asobi</code> image runs as the non-root <code>asobi</code>
user, and its Dockerfile chowns all of <code>/app</code> to that user. So the release tree
is writable by the process that runs it, and the image does not declare
<code>--read-only</code>.</p>
<p>Making it read-only takes one extra step, because the boot script renders
<code>sys.config</code> and <code>vm.args</code> from their <code>.src</code> templates at start and writes the
result next to them. Add these flags to however you already run the image, on
top of the database variables from <a href="https://hexdocs.pm/asobi/self-hosting.html">Self-hosting</a>:</p>
<pre><code>docker run --read-only \
  --tmpfs /tmp \
  --tmpfs /run/asobi \
  -e RELX_OUT_FILE_PATH=/run/asobi \
  -v /srv/mygame:/app/game:ro \
  -p 8084:8084 \
  ghcr.io/widgrensit/asobi
</code></pre>
<p><code>RELX_OUT_FILE_PATH</code> must name a directory that already exists, or the script
falls back to writing into <code>/app/releases/&lt;vsn&gt;</code> and the boot fails on a
read-only filesystem. <code>/tmp</code> holds the pipe directory the release uses for
<code>bin/asobi remote_console</code>. Mount the game directory read-only unless your game
writes to it.</p>
<h2 id="related" tabindex="-1">Related</h2>
<ul>
<li><a href="/docs/security/threat-model">Threat model</a> - the trust assumptions these limits follow from.</li>
<li><a href="/docs/security/auth">Auth and rate limiting</a> - the per-request bounds that do exist.</li>
<li><a href="/docs/security/lua-sandbox">Sandbox model</a> - what the Lua sandbox removes, replaces and bounds.</li>
<li><a href="/docs/security/lua-trust-model">Trust model</a> - what that sandbox is and is not a boundary against.</li>
<li><a href="https://hexdocs.pm/asobi/security-lua-known-limitations.html">Known limitations (Lua)</a> - the sandbox's own sharp edges.</li>
</ul>
"""}
    ]}.
