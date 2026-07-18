%% GENERATED from asobi guides/security-sandbox.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_security_lua_sandbox_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-lua-sandbox", title => ~"Lua sandbox — Asobi docs"}, Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Security / Lua sandbox"
        ]},
        {h1, [], [~"Sandbox model"]},
        {raw,
            ~"""
<p>asobi_lua runs every Lua script in a hardened Luerl state. Sandbox
construction lives in <code>asobi_lua_loader:new/1</code> and
<code>asobi_lua_loader:init_sandboxed/0</code>.</p>
<h2 id="removed-from-the-global-environment" tabindex="-1">Removed from the global environment</h2>
<p>The following standard-library entries are cleared (<code>= nil</code>) so a hostile
script cannot reach them:</p>
<ul>
<li><strong>OS escape hatches:</strong> <code>os.execute</code>, <code>os.exit</code>, <code>os.getenv</code>,
<code>os.remove</code>, <code>os.rename</code>, <code>os.tmpname</code></li>
<li><strong>Code loading:</strong> <code>dofile</code>, <code>loadfile</code>, <code>load</code>, <code>loadstring</code></li>
<li><strong>I/O:</strong> the entire <code>io</code> library</li>
<li><strong>Package machinery:</strong> the entire <code>package</code> library, plus the default
<code>require</code></li>
<li><strong>Unstructured logging:</strong> <code>print</code>, <code>eprint</code> — Luerl's defaults bypass
the structured logger and write straight to BEAM stdout. There is
currently no in-script logging API; surface diagnostics through game
state or broadcast events instead.</li>
</ul>
<p><code>os.clock</code>, <code>os.date</code>, <code>os.difftime</code>, and <code>os.time</code> remain available so
games can timestamp.</p>
<h2 id="replaced" tabindex="-1">Replaced</h2>
<ul>
<li><strong><code>require/1</code></strong> is provided by asobi_lua. Names must match
<code>[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*</code> — letters, digits,
underscores, with <code>.</code> separating segments. Names like <code>../foo</code>,
<code>/etc/passwd</code>, <code>foo/bar</code>, <code>42</code>, or <code>''</code> are rejected. The validator
uses the <code>dollar_endonly</code> regex flag so <code>require(&quot;foo\n&quot;)</code> does not
slip through. The resolver joins the validated name to the directory
of the script that was loaded (e.g. <code>require(&quot;bots.chaser&quot;)</code> →
<code>&lt;base&gt;/bots/chaser.lua</code>) and reads the file with <code>file:read_file/1</code>.
Symlinks at the resolved path are rejected before reading. Module
results are cached in the Luerl state's private <code>_ASOBI_LOADED</code>
table; <code>asobi_lua_match</code> clears that cache on hot-reload so changed
modules pick up.</li>
<li><strong><code>math.random</code></strong> dispatches to Erlang's <code>rand:uniform</code>. Single-arg
form returns an integer in <code>[1, N]</code>; no-arg form returns a float in
<code>[0, 1)</code>. The two-arg <code>math.random(a, b)</code> form upstream Lua exposes
is <strong>not</strong> supported.</li>
<li><strong><code>math.sqrt</code></strong> dispatches to Erlang's <code>math:sqrt/1</code>. Negative input
returns <code>0.0</code> (upstream Lua returns NaN; Erlang would crash).</li>
</ul>
<h2 id="per-callback-wall-clock-limits" tabindex="-1">Per-callback wall-clock limits</h2>
<p>Every Lua callback the bridges call (init, tick, join, leave,
get_state, vote_requested, vote_resolved, generate_world,
phases, spawn_templates, on_phase_started/ended, on_zone_loaded/unloaded,
on_world_recovered, terrain_provider, spawn_position, post_tick,
zone_tick, bot <code>think</code>) runs in a child process with a wall-clock
budget. A runaway script (<code>while true do end</code>, deep recursion, huge
allocation) is killed when its budget elapses; the parent gen_server
logs a warning and continues with the previous state. Limits are tuned
per callback — init/generate_world get more time, per-tick callbacks
get less. See the <code>?*_TIMEOUT</code> macros in <code>asobi_lua_match.erl</code> and
<code>asobi_lua_world.erl</code>.</p>
<p><strong><code>handle_input/3</code> is the exception: it is <em>not</em> wall-clock-bounded.</strong> It runs
inline for measured tail-latency wins at high input rates (ADR 0002), so a
<code>while true do end</code> there hangs the match until the gen_server timeout (5 s) and
the supervisor restarts the match — blast radius one match. It is not a sandbox
boundary; see the <a href="/docs/security/lua-trust-model#per-callback-isolation">trust model</a>.</p>
<p>The same wall-clock wrapper is applied to the <strong>initial script body</strong>
load (<code>asobi_lua_loader:new/1</code>), the <strong>hot-reload</strong> path (in
<code>asobi_lua_match</code>'s reload helper), and the <strong>config manifest</strong>
evaluator (in <code>asobi_lua_config</code>). A <code>while true do end</code> at the top
of <code>match.lua</code> therefore can no longer hang application start or the
match gen_server.</p>
<h2 id="cross-script-isolation" tabindex="-1">Cross-script isolation</h2>
<p>Each match and each zone gets its own Luerl state. Globals, modules,
and the require cache live inside that state — there is no shared
table reachable from script code that crosses match boundaries.</p>
<h2 id="atom-exhaustion" tabindex="-1">Atom exhaustion</h2>
<p><code>asobi_lua_api</code>'s <code>safe_to_atom</code> helper and <code>terrain_provider</code>
decoding both use <code>binary_to_existing_atom/1</code> so a Lua-supplied string
cannot inflate the global atom table. Additionally, the terrain
provider module name is matched against an explicit allowlist
(<code>asobi_terrain_flat</code>, <code>asobi_terrain_perlin</code> by default; configurable
via the <code>asobi_lua, terrain_providers</code> env) so a script cannot
dispatch into arbitrary loaded modules even if the underlying atom
already exists. There is a regression test in
<code>asobi_lua_sandbox_tests</code> that fails if the limit is widened.</p>
<h2 id="decode-depth-cap" tabindex="-1">Decode depth cap</h2>
<p><code>asobi_lua_api</code>'s deep-decode helper recurses on Lua-side tables;
depth is capped at 64 levels and over-deep subtrees are replaced with
the atom <code>too_deep</code>. A malicious script returning a 100k-deep table
from a callback can no longer blow the parent process heap.</p>
"""}
    ]}.
