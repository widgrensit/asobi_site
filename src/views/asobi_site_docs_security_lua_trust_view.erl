%% GENERATED from asobi guides/security-trust-model.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_security_lua_trust_view).

-export([mount/1, render/1, markdown/0]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-lua-trust", title => ~"Lua trust model — Asobi docs"}, Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Security / Lua trust model"
        ]},
        {h1, [], [~"Trust model"]},
        {raw,
            ~"""
<p>asobi treats the Lua scripts mounted at <code>/app/game</code> as trusted in the same
sense the <code>/app/bin/asobi</code> binary is trusted: you control what files end up
there. The <a href="/docs/security/lua-sandbox">sandbox</a> protects against incidental scripting
bugs - infinite loops, missed nil checks, atom exhaustion driven by player
input - and makes it harder for a compromised dependency or a <code>require</code>d module
to escape. It is not a defence against a deliberate, Erlang-aware adversary who
can write <code>/app/game/match.lua</code>.</p>
<h2 id="documented-properties" tabindex="-1">Documented properties</h2>
<p>Three properties of the sandbox that are easy to re-derive wrongly, with where
to check them.</p>
<h3 id="metatables-cannot-recover-a-stripped-function" tabindex="-1">Metatables cannot recover a stripped function</h3>
<p><code>strip_dangerous_globals/1</code> in <code>asobi_lua_loader</code> sets each dangerous key to
<code>nil</code>, and Luerl's <code>set_table_key_key/4</code> erases the entry from the underlying
dict rather than storing a nil. So <code>setmetatable(_G, ...)</code> and
<code>setmetatable(os, ...)</code> remain allowed, and an <code>__index</code> metatable does
intercept lookups for the now-absent keys - but the Erlang function references
for <code>os.execute</code> and the rest lived only in the dict entry that was erased.
Nothing else in the Luerl state holds them, so there is no Lua-reachable path
back to them.</p>
<h3 id="_asobi_loaded-is-visible-to-script-code" tabindex="-1"><code>_ASOBI_LOADED</code> is visible to script code</h3>
<p>The require cache is installed as a global. A script can iterate it, mutate it
or delete entries. There is no privilege boundary inside a single Luerl state,
so this is by design: cross-match isolation comes from each match owning its
own state, and a script that clobbers its own cache only denies itself.
<code>lookup_loaded</code> in <code>asobi_lua_loader</code> turns a clobbered cache into a clean Lua
error rather than a <code>case_clause</code> crash.</p>
<h3 id="terrain_provider-cannot-inflate-the-atom-table" tabindex="-1"><code>terrain_provider</code> cannot inflate the atom table</h3>
<p>A script returning <code>{ module = &quot;&lt;name&gt;&quot;, ... }</code> from <code>terrain_provider/1</code>
cannot mint an atom: the bridge uses <code>binary_to_existing_atom/1</code>. It also
requires the module to be on an allowlist, so naming an unrelated loaded module
(<code>gen_server</code>, <code>rpc</code>) is rejected with a <code>terrain_provider_not_allowed</code>
warning. The default is <code>asobi_terrain_flat</code> and <code>asobi_terrain_perlin</code>, read
through <code>asobi_lua_env:get_env(terrain_providers, ...)</code>.</p>
<h2 id="per-callback-budgets" tabindex="-1">Per-callback budgets</h2>
<p>Almost every Lua callback runs inside a child process spawned by the
<code>bounded_eval</code> helper in <code>asobi_lua_loader</code>, with a wall-clock timeout,
<code>max_heap_size</code> with <code>kill =&gt; true</code>, and a reduction budget. A runaway loop or
allocation kills
the child, the parent gen_server sees <code>{error, timeout | heap_exhausted | reductions_exhausted}</code>, and the match or zone continues on its previous state.</p>
<table>
<thead>
<tr>
<th>Callback</th>
<th>Bridge</th>
<th>Bounded</th>
<th>Budget</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>init/1</code></td>
<td>match, world</td>
<td>yes</td>
<td>1000 ms match, 2000 ms world</td>
</tr>
<tr>
<td><code>generate_world/2</code></td>
<td>world</td>
<td>yes</td>
<td>5000 ms</td>
</tr>
<tr>
<td><code>tick/1</code>, <code>zone_tick/2</code>, <code>post_tick/2</code></td>
<td>match, world</td>
<td>yes</td>
<td>500 ms</td>
</tr>
<tr>
<td><code>join/2</code>, <code>leave/2</code></td>
<td>match, world</td>
<td>yes</td>
<td>200 ms</td>
</tr>
<tr>
<td><code>get_state/{1,2}</code></td>
<td>match, world</td>
<td>yes</td>
<td>100 ms</td>
</tr>
<tr>
<td><code>spawn_position/2</code></td>
<td>world</td>
<td>yes</td>
<td>100 ms</td>
</tr>
<tr>
<td><code>vote_requested/1</code>, <code>vote_resolved/3</code></td>
<td>match</td>
<td>yes</td>
<td>200 ms</td>
</tr>
<tr>
<td><code>phases/1</code></td>
<td>match, world</td>
<td>yes</td>
<td>1000 ms match, 2000 ms world</td>
</tr>
<tr>
<td><code>on_phase_started/2</code>, <code>on_phase_ended/2</code></td>
<td>match, world</td>
<td>yes</td>
<td>200 ms</td>
</tr>
<tr>
<td><code>on_zone_loaded/3</code>, <code>on_zone_unloaded/3</code></td>
<td>world</td>
<td>yes</td>
<td>200 ms</td>
</tr>
<tr>
<td><code>spawn_templates/1</code></td>
<td>world</td>
<td>yes</td>
<td>2000 ms</td>
</tr>
<tr>
<td><code>on_world_recovered/2</code></td>
<td>world</td>
<td>yes</td>
<td>2000 ms</td>
</tr>
<tr>
<td><code>terrain_provider/1</code></td>
<td>world</td>
<td>yes</td>
<td>2000 ms</td>
</tr>
<tr>
<td>bot <code>think/2</code></td>
<td>bot</td>
<td>yes</td>
<td>50 ms</td>
</tr>
<tr>
<td><code>handle_input/3</code></td>
<td>match, world</td>
<td><strong>no</strong></td>
<td>see below</td>
</tr>
</tbody>
</table>
<p>The macros are not all in one place. Match budgets are <code>?*_TIMEOUT</code> in
<code>asobi_lua_match.erl</code> and world budgets are <code>?*_TIMEOUT</code> in
<code>asobi_lua_world.erl</code>, but <code>get_state/1</code> on the shared-state path has its own
<code>?GET_STATE_TIMEOUT</code> in <code>asobi_lua_match_shared.erl</code>, and the bot <code>think</code>
budget is a literal <code>50</code> at the call site in <code>asobi_bot.erl</code> rather than a
macro. Grep for <code>asobi_lua_loader:call(</code> if you need the authoritative set.</p>
<h2 id="handle-input-is-not-a-sandbox-boundary" tabindex="-1">handle-input is not a sandbox boundary</h2>
<p><code>handle_input/3</code> is the one callback that does not spawn-isolate. At realistic
input rates - one tick times N players times the message rate - the per-call
spawn cost dominated the actual Lua work: roughly 30 to 50 microseconds of
spawn, monitor and heap-cap setup against 50 to 200 microseconds of input
handling. Removing the wrapper recovered measured tail-latency wins at 200
players and 10 Hz input.</p>
<p>What that costs is worth stating precisely, because it is not a supervisor
event. Input arrives as a cast and is queued; the queue is drained inside the tick,
by <code>apply_inputs/3</code> in <code>asobi_match_server</code> and in <code>asobi_zone</code>. There is no
<code>gen_server:call</code> behind it and no call timeout to trip. A
<code>while true do end</code> inside <code>handle_input</code> therefore hangs the match or
zone process indefinitely: the tick stops, no supervisor restart happens, and
every later call against that process times out in its own caller. Blast radius
is one match or one zone. Recovery is manual.</p>
<p>So treat <code>handle_input/3</code> as a hot path for trusted-author scripts, not as a
boundary. Audit the inputs your script accepts, avoid dispatching on
attacker-controlled strings, and treat it the way you would an Erlang
<code>handle_call/3</code> you wrote yourself. Per-tick safety belongs in <code>tick/1</code>, which
still spawn-isolates and is the right place to enforce fairness across players.</p>
<h2 id="related" tabindex="-1">Related</h2>
<ul>
<li><a href="/docs/security/lua-sandbox">Sandbox model</a> - what the sandbox removes, replaces and bounds.</li>
<li><a href="https://hexdocs.pm/asobi/security-lua-known-limitations.html">Known limitations (Lua)</a> - what it does not enforce.</li>
<li><a href="/docs/security/threat-model">Threat model</a> - the node-level trust boundaries.</li>
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
# Trust model

asobi treats the Lua scripts mounted at `/app/game` as trusted in the same
sense the `/app/bin/asobi` binary is trusted: you control what files end up
there. The [sandbox](https://asobi.dev/docs/security/lua-sandbox) protects against incidental scripting
bugs - infinite loops, missed nil checks, atom exhaustion driven by player
input - and makes it harder for a compromised dependency or a `require`d module
to escape. It is not a defence against a deliberate, Erlang-aware adversary who
can write `/app/game/match.lua`.

## Documented properties

Three properties of the sandbox that are easy to re-derive wrongly, with where
to check them.

### Metatables cannot recover a stripped function

`strip_dangerous_globals/1` in `asobi_lua_loader` sets each dangerous key to
`nil`, and Luerl's `set_table_key_key/4` erases the entry from the underlying
dict rather than storing a nil. So `setmetatable(_G, ...)` and
`setmetatable(os, ...)` remain allowed, and an `__index` metatable does
intercept lookups for the now-absent keys - but the Erlang function references
for `os.execute` and the rest lived only in the dict entry that was erased.
Nothing else in the Luerl state holds them, so there is no Lua-reachable path
back to them.

### `_ASOBI_LOADED` is visible to script code

The require cache is installed as a global. A script can iterate it, mutate it
or delete entries. There is no privilege boundary inside a single Luerl state,
so this is by design: cross-match isolation comes from each match owning its
own state, and a script that clobbers its own cache only denies itself.
`lookup_loaded` in `asobi_lua_loader` turns a clobbered cache into a clean Lua
error rather than a `case_clause` crash.

### `terrain_provider` cannot inflate the atom table

A script returning `{ module = "<name>", ... }` from `terrain_provider/1`
cannot mint an atom: the bridge uses `binary_to_existing_atom/1`. It also
requires the module to be on an allowlist, so naming an unrelated loaded module
(`gen_server`, `rpc`) is rejected with a `terrain_provider_not_allowed`
warning. The default is `asobi_terrain_flat` and `asobi_terrain_perlin`, read
through `asobi_lua_env:get_env(terrain_providers, ...)`.

## Per-callback budgets

Almost every Lua callback runs inside a child process spawned by the
`bounded_eval` helper in `asobi_lua_loader`, with a wall-clock timeout,
`max_heap_size` with `kill => true`, and a reduction budget. A runaway loop or
allocation kills
the child, the parent gen_server sees `{error, timeout | heap_exhausted |
reductions_exhausted}`, and the match or zone continues on its previous state.

| Callback | Bridge | Bounded | Budget |
|---|---|---|---|
| `init/1` | match, world | yes | 1000 ms match, 2000 ms world |
| `generate_world/2` | world | yes | 5000 ms |
| `tick/1`, `zone_tick/2`, `post_tick/2` | match, world | yes | 500 ms |
| `join/2`, `leave/2` | match, world | yes | 200 ms |
| `get_state/{1,2}` | match, world | yes | 100 ms |
| `spawn_position/2` | world | yes | 100 ms |
| `vote_requested/1`, `vote_resolved/3` | match | yes | 200 ms |
| `phases/1` | match, world | yes | 1000 ms match, 2000 ms world |
| `on_phase_started/2`, `on_phase_ended/2` | match, world | yes | 200 ms |
| `on_zone_loaded/3`, `on_zone_unloaded/3` | world | yes | 200 ms |
| `spawn_templates/1` | world | yes | 2000 ms |
| `on_world_recovered/2` | world | yes | 2000 ms |
| `terrain_provider/1` | world | yes | 2000 ms |
| bot `think/2` | bot | yes | 50 ms |
| `handle_input/3` | match, world | **no** | see below |

The macros are not all in one place. Match budgets are `?*_TIMEOUT` in
`asobi_lua_match.erl` and world budgets are `?*_TIMEOUT` in
`asobi_lua_world.erl`, but `get_state/1` on the shared-state path has its own
`?GET_STATE_TIMEOUT` in `asobi_lua_match_shared.erl`, and the bot `think`
budget is a literal `50` at the call site in `asobi_bot.erl` rather than a
macro. Grep for `asobi_lua_loader:call(` if you need the authoritative set.

## handle-input is not a sandbox boundary

`handle_input/3` is the one callback that does not spawn-isolate. At realistic
input rates - one tick times N players times the message rate - the per-call
spawn cost dominated the actual Lua work: roughly 30 to 50 microseconds of
spawn, monitor and heap-cap setup against 50 to 200 microseconds of input
handling. Removing the wrapper recovered measured tail-latency wins at 200
players and 10 Hz input.

What that costs is worth stating precisely, because it is not a supervisor
event. Input arrives as a cast and is queued; the queue is drained inside the tick,
by `apply_inputs/3` in `asobi_match_server` and in `asobi_zone`. There is no
`gen_server:call` behind it and no call timeout to trip. A
`while true do end` inside `handle_input` therefore hangs the match or
zone process indefinitely: the tick stops, no supervisor restart happens, and
every later call against that process times out in its own caller. Blast radius
is one match or one zone. Recovery is manual.

So treat `handle_input/3` as a hot path for trusted-author scripts, not as a
boundary. Audit the inputs your script accepts, avoid dispatching on
attacker-controlled strings, and treat it the way you would an Erlang
`handle_call/3` you wrote yourself. Per-tick safety belongs in `tick/1`, which
still spawn-isolates and is the right place to enforce fairness across players.

## Related

- [Sandbox model](https://asobi.dev/docs/security/lua-sandbox) - what the sandbox removes, replaces and bounds.
- [Known limitations (Lua)](https://hexdocs.pm/asobi/security-lua-known-limitations.html) - what it does not enforce.
- [Threat model](https://asobi.dev/docs/security/threat-model) - the node-level trust boundaries.
- [Known limitations](https://asobi.dev/docs/security/known-limitations) - the same for in-VM Erlang code.
- [Auth and rate limiting](https://asobi.dev/docs/security/auth) - the request-side bounds.
""".
