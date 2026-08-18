%% GENERATED from asobi guides/security-sandbox.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_security_lua_sandbox_view).

-export([mount/1, render/1, markdown/0]).

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
<p>asobi runs every Lua script in a hardened Luerl state. Sandbox construction
lives in <code>asobi_lua_loader:new/1</code> and <code>asobi_lua_loader:init_sandboxed/0</code>.</p>
<h2 id="removed-from-the-global-environment" tabindex="-1">Removed from the global environment</h2>
<p>These standard-library entries are erased (<code>strip_dangerous_globals/1</code> sets
them to <code>nil</code>, which removes the key from the underlying table) so a script
cannot reach them:</p>
<ul>
<li>OS escape hatches - <code>os.execute</code>, <code>os.exit</code>, <code>os.getenv</code>, <code>os.remove</code>,
<code>os.rename</code>, <code>os.tmpname</code></li>
<li>Code loading - <code>dofile</code>, <code>loadfile</code>, <code>load</code>, <code>loadstring</code></li>
<li>I/O - the whole <code>io</code> library</li>
<li>Package machinery - the whole <code>package</code> library, plus the default <code>require</code></li>
<li>Unstructured logging - <code>print</code> and <code>eprint</code>. Luerl's versions bypass the
structured logger and write straight to BEAM stdout. Use
<code>game.log(level, message[, meta])</code>, which routes a structured, size-bounded
line through the host logger behind a rate limit (per match or zone, plus a
node-wide backstop). See the Logging section of the Lua scripting guide.</li>
</ul>
<p><code>os.clock</code>, <code>os.date</code>, <code>os.difftime</code> and <code>os.time</code> stay, so games can timestamp.</p>
<h2 id="replaced" tabindex="-1">Replaced</h2>
<p><code>require/1</code> is asobi's own. A name must match
<code>[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*</code> - letters, digits and
underscores, with <code>.</code> separating segments. <code>../foo</code>, <code>/etc/passwd</code>, <code>foo/bar</code>,
<code>42</code> and <code>''</code> are all rejected, and the validator runs with the
<code>dollar_endonly</code> flag so <code>require(&quot;foo\n&quot;)</code> does not slip past the anchor. The
resolver joins the validated name to the directory of the loaded script
(<code>require(&quot;bots.chaser&quot;)</code> resolves to <code>&lt;base&gt;/bots/chaser.lua</code>) and reads it
with <code>file:read_file/1</code>. A symlink at the resolved path is refused before the
read. Results are cached in the state's <code>_ASOBI_LOADED</code> table, which
<code>asobi_lua_reload</code> clears on hot-reload so a changed module is picked up.</p>
<p><code>math.random</code> dispatches to <code>rand:uniform</code>. All three upstream forms work: no
argument returns a float in <code>[0, 1)</code>, <code>math.random(n)</code> returns an integer in
<code>[1, n]</code>, and <code>math.random(a, b)</code> returns an integer in <code>[a, b]</code>. An empty
interval raises a proper Lua error, so <code>pcall</code> traps it.</p>
<p><code>math.sqrt</code> dispatches to <code>math:sqrt/1</code>, and negative input returns <code>0.0</code>
rather than crashing the process (upstream Lua returns NaN).</p>
<h2 id="per-callback-budgets" tabindex="-1">Per-callback budgets</h2>
<p>Every Lua callback the bridges call runs in a child process with three bounds:
a wall-clock timeout, <code>max_heap_size</code> with <code>kill =&gt; true</code>, and a reduction
budget. A runaway script - <code>while true do end</code>, deep recursion, a huge
allocation - is killed, the parent logs a warning and keeps the previous Lua
state, and the match or zone carries on. Failures surface as
<code>{error, timeout}</code>, <code>{error, heap_exhausted}</code> or <code>{error, reductions_exhausted}</code>.</p>
<p>The budgets are per callback: see the <a href="/docs/security/lua-trust-model#per-callback-budgets">trust
model</a> for the full table and
where each macro lives.</p>
<p><code>handle_input/3</code> is the exception. It runs inline in the calling process, so
none of the three bounds apply to it. See <a href="/docs/security/lua-trust-model#handle-input-is-not-a-sandbox-boundary">what that
costs</a>.</p>
<p>The same wrapper covers the three places script-author-controlled code is
evaluated rather than called:</p>
<table>
<thead>
<tr>
<th>Path</th>
<th>Module</th>
<th>Budget</th>
</tr>
</thead>
<tbody>
<tr>
<td>Initial script body</td>
<td><code>asobi_lua_loader:new/3</code></td>
<td>the caller's init budget: 1000 ms for a match, 2000 ms for a world, 5000 ms when a zone VM boots</td>
</tr>
<tr>
<td>Hot-reload</td>
<td><code>asobi_lua_reload</code> (<code>?RELOAD_TIMEOUT_MS</code>)</td>
<td>5000 ms</td>
</tr>
<tr>
<td>Config manifest</td>
<td><code>asobi_lua_config</code> (<code>?CONFIG_TIMEOUT_MS</code>)</td>
<td>2000 ms</td>
</tr>
</tbody>
</table>
<p>So a <code>while true do end</code> at the top of <code>match.lua</code> cannot hang application
start or the match process.</p>
<h2 id="cross-script-isolation" tabindex="-1">Cross-script isolation</h2>
<p>Each match and each zone gets its own Luerl state. Globals, modules and the
require cache live inside that state, and no table reachable from script code
crosses a match boundary.</p>
<h2 id="atom-exhaustion" tabindex="-1">Atom exhaustion</h2>
<p><code>asobi_lua_api</code>'s <code>safe_to_atom</code> helper and the <code>terrain_provider</code> decoder both
use <code>binary_to_existing_atom/1</code>, so a Lua-supplied string cannot inflate the
global atom table. The terrain provider module is additionally matched against
an explicit allowlist, so a script cannot dispatch into an arbitrary loaded
module even when the atom already exists; a name outside the list is refused
with a <code>terrain_provider_not_allowed</code> warning.
<code>asobi_lua_sandbox_tests:atom_count_stable_under_unknown_keys_test/0</code> pins the
atom-table property, and <code>asobi_lua_world_tests</code> pins the allowlist.</p>
<p>The default list is <code>asobi_terrain_flat</code> and <code>asobi_terrain_perlin</code>, read
through <code>asobi_lua_env:get_env(terrain_providers, ...)</code>.</p>
<h2 id="decode-depth-cap" tabindex="-1">Decode depth cap</h2>
<p><code>asobi_lua_api</code>'s deep-decode helper recurses over Lua-side tables with a depth
cap of 64 levels; an over-deep subtree is replaced with the atom <code>too_deep</code>. A
script returning a 100k-deep table from a callback cannot blow the parent
process heap.</p>
<h2 id="related" tabindex="-1">Related</h2>
<ul>
<li><a href="/docs/security/lua-trust-model">Trust model</a> - what this sandbox is and is not a boundary against.</li>
<li><a href="https://hexdocs.pm/asobi/security-lua-known-limitations.html">Known limitations (Lua)</a> - what it does not enforce.</li>
<li><a href="/docs/security/threat-model">Threat model</a> - the node-level trust boundaries around it.</li>
<li><a href="/docs/security/known-limitations">Known limitations</a> - the same for in-VM Erlang code.</li>
<li><a href="/docs/security/auth">Auth and rate limiting</a> - the request-side bounds.</li>
</ul>
"""}
    ]}.

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Sandbox model

asobi runs every Lua script in a hardened Luerl state. Sandbox construction
lives in `asobi_lua_loader:new/1` and `asobi_lua_loader:init_sandboxed/0`.

## Removed from the global environment

These standard-library entries are erased (`strip_dangerous_globals/1` sets
them to `nil`, which removes the key from the underlying table) so a script
cannot reach them:

- OS escape hatches - `os.execute`, `os.exit`, `os.getenv`, `os.remove`,
  `os.rename`, `os.tmpname`
- Code loading - `dofile`, `loadfile`, `load`, `loadstring`
- I/O - the whole `io` library
- Package machinery - the whole `package` library, plus the default `require`
- Unstructured logging - `print` and `eprint`. Luerl's versions bypass the
  structured logger and write straight to BEAM stdout. Use
  `game.log(level, message[, meta])`, which routes a structured, size-bounded
  line through the host logger behind a rate limit (per match or zone, plus a
  node-wide backstop). See the Logging section of the Lua scripting guide.

`os.clock`, `os.date`, `os.difftime` and `os.time` stay, so games can timestamp.

## Replaced

`require/1` is asobi's own. A name must match
`[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*` - letters, digits and
underscores, with `.` separating segments. `../foo`, `/etc/passwd`, `foo/bar`,
`42` and `''` are all rejected, and the validator runs with the
`dollar_endonly` flag so `require("foo\n")` does not slip past the anchor. The
resolver joins the validated name to the directory of the loaded script
(`require("bots.chaser")` resolves to `<base>/bots/chaser.lua`) and reads it
with `file:read_file/1`. A symlink at the resolved path is refused before the
read. Results are cached in the state's `_ASOBI_LOADED` table, which
`asobi_lua_reload` clears on hot-reload so a changed module is picked up.

`math.random` dispatches to `rand:uniform`. All three upstream forms work: no
argument returns a float in `[0, 1)`, `math.random(n)` returns an integer in
`[1, n]`, and `math.random(a, b)` returns an integer in `[a, b]`. An empty
interval raises a proper Lua error, so `pcall` traps it.

`math.sqrt` dispatches to `math:sqrt/1`, and negative input returns `0.0`
rather than crashing the process (upstream Lua returns NaN).

## Per-callback budgets

Every Lua callback the bridges call runs in a child process with three bounds:
a wall-clock timeout, `max_heap_size` with `kill => true`, and a reduction
budget. A runaway script - `while true do end`, deep recursion, a huge
allocation - is killed, the parent logs a warning and keeps the previous Lua
state, and the match or zone carries on. Failures surface as
`{error, timeout}`, `{error, heap_exhausted}` or `{error, reductions_exhausted}`.

The budgets are per callback: see the [trust
model](https://asobi.dev/docs/security/lua-trust-model#per-callback-budgets) for the full table and
where each macro lives.

`handle_input/3` is the exception. It runs inline in the calling process, so
none of the three bounds apply to it. See [what that
costs](https://asobi.dev/docs/security/lua-trust-model#handle-input-is-not-a-sandbox-boundary).

The same wrapper covers the three places script-author-controlled code is
evaluated rather than called:

| Path | Module | Budget |
|---|---|---|
| Initial script body | `asobi_lua_loader:new/3` | the caller's init budget: 1000 ms for a match, 2000 ms for a world, 5000 ms when a zone VM boots |
| Hot-reload | `asobi_lua_reload` (`?RELOAD_TIMEOUT_MS`) | 5000 ms |
| Config manifest | `asobi_lua_config` (`?CONFIG_TIMEOUT_MS`) | 2000 ms |

So a `while true do end` at the top of `match.lua` cannot hang application
start or the match process.

## Cross-script isolation

Each match and each zone gets its own Luerl state. Globals, modules and the
require cache live inside that state, and no table reachable from script code
crosses a match boundary.

## Atom exhaustion

`asobi_lua_api`'s `safe_to_atom` helper and the `terrain_provider` decoder both
use `binary_to_existing_atom/1`, so a Lua-supplied string cannot inflate the
global atom table. The terrain provider module is additionally matched against
an explicit allowlist, so a script cannot dispatch into an arbitrary loaded
module even when the atom already exists; a name outside the list is refused
with a `terrain_provider_not_allowed` warning.
`asobi_lua_sandbox_tests:atom_count_stable_under_unknown_keys_test/0` pins the
atom-table property, and `asobi_lua_world_tests` pins the allowlist.

The default list is `asobi_terrain_flat` and `asobi_terrain_perlin`, read
through `asobi_lua_env:get_env(terrain_providers, ...)`.

## Decode depth cap

`asobi_lua_api`'s deep-decode helper recurses over Lua-side tables with a depth
cap of 64 levels; an over-deep subtree is replaced with the atom `too_deep`. A
script returning a 100k-deep table from a callback cannot blow the parent
process heap.

## Related

- [Trust model](https://asobi.dev/docs/security/lua-trust-model) - what this sandbox is and is not a boundary against.
- [Known limitations (Lua)](https://hexdocs.pm/asobi/security-lua-known-limitations.html) - what it does not enforce.
- [Threat model](https://asobi.dev/docs/security/threat-model) - the node-level trust boundaries around it.
- [Known limitations](https://asobi.dev/docs/security/known-limitations) - the same for in-VM Erlang code.
- [Auth and rate limiting](https://asobi.dev/docs/security/auth) - the request-side bounds.
""".
