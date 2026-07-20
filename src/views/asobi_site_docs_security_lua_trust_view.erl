%% GENERATED from asobi guides/security-trust-model.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_security_lua_trust_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

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
<p>asobi_lua treats the mounted <code>/app/game</code> Lua scripts as <strong>trusted</strong> in
the same sense your <code>/app/bin/asobi_lua</code> binary is trusted: you control
what files end up there. The sandbox protects against incidental
scripting bugs (infinite loops, missed nil checks, atom exhaustion via
untrusted player input) and makes it harder for a <em>compromised</em>
dependency or <code>require</code>'d module to escape. It is not a defence against
a deliberate, all-Erlang-aware adversary with the ability to write
<code>/app/game/match.lua</code>.</p>
<h2 id="verified-negative-results" tabindex="-1">Verified negative results</h2>
<p>These are properties prior security audits looked at and confirmed
hold. Documented here so future readers don't re-derive them.</p>
<h3 id="setmetatable_g-and-setmetatableos-are-still-allowed" tabindex="-1"><code>setmetatable(_G, ...)</code> and <code>setmetatable(os, ...)</code> are still allowed</h3>
<p>The strip pass calls <code>set_table_keys</code> with <code>nil</code>, which Luerl's
<code>set_table_key_key/4</code> <em>erases</em> the entry from the underlying ttdict —
the key becomes truly absent, not &quot;set to nil&quot;. A subsequent <code>__index</code>
metatable on <code>os</code> (or <code>_G</code>) would intercept lookups for the absent
keys. However, <code>__index</code> can only return values that exist in the
script's reach, and the actual Erlang function references for
<code>os.execute</code>, <code>os.exit</code>, etc. are stored exclusively inside the os
table dict that was just erased. Once erased there is no Lua-reachable
path to those function references — they are not stored elsewhere in
the Luerl state. So metatable manipulation cannot recover stripped
functions.</p>
<h3 id="_asobi_loaded-is-reachable-via-_g_asobi_loaded" tabindex="-1"><code>_ASOBI_LOADED</code> is reachable via <code>_G._ASOBI_LOADED</code></h3>
<p>The require cache is installed as a global, fully visible to Lua. A
script can iterate it, mutate it, delete entries. There's no privilege
boundary inside a single Luerl state, so this is by design and
acceptable. Cross-match isolation comes from each match having its own
state; a script that clobbers its own cache only DoSes itself. The internal
<code>lookup_loaded</code> helper in <code>asobi_lua_loader</code> handles a clobbered
cache cleanly rather than crashing with <code>case_clause</code>.</p>
<h3 id="atom-table-inflation-via-terrain_provider" tabindex="-1">Atom-table inflation via <code>terrain_provider</code></h3>
<p>A Lua script that returns <code>{ module = &quot;&lt;some_atom&gt;&quot;, ... }</code> from
<code>terrain_provider/1</code> cannot inflate the atom table — the bridge uses
<code>binary_to_existing_atom/1</code>. As of the F-* hardening pass the bridge
also requires the target module to be on an explicit allowlist
(<code>asobi_terrain_flat</code>, <code>asobi_terrain_perlin</code> by default; configurable
via <code>application:get_env(asobi_lua, terrain_providers, ...)</code>) so a
script that names an unrelated loaded module (<code>gen_server</code>, <code>rpc</code>,
etc.) is rejected with a <code>terrain_provider_not_allowed</code> warning.</p>
<h2 id="per-callback-isolation" tabindex="-1">Per-callback isolation</h2>
<p>Most Lua callbacks run inside a child process spawned by the loader's
<code>bounded_eval</code> wrapper with a wall-clock timeout and a
<code>max_heap_size: kill =&gt; true</code>. A runaway loop or a runaway allocation
in those callbacks crashes the child, the parent gen_server receives a
<code>{error, timeout | heap_exhausted}</code> result, and the match continues.</p>
<table>
<thead>
<tr>
<th>Callback</th>
<th>Bridge</th>
<th>Bounded?</th>
<th>Budget</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>init/1</code></td>
<td>match, world</td>
<td>yes</td>
<td>1000-2000 ms</td>
</tr>
<tr>
<td><code>tick/1</code>, <code>zone_tick/2</code></td>
<td>match, world</td>
<td>yes</td>
<td>500 ms</td>
</tr>
<tr>
<td><code>get_state/{1,2}</code></td>
<td>match, world</td>
<td>yes</td>
<td>100 ms</td>
</tr>
<tr>
<td><code>join/2</code>, <code>leave/2</code></td>
<td>match, world</td>
<td>yes</td>
<td>200 ms</td>
</tr>
<tr>
<td><code>vote_*</code></td>
<td>match</td>
<td>yes</td>
<td>200 ms</td>
</tr>
<tr>
<td><code>phases/1</code></td>
<td>world</td>
<td>yes</td>
<td>2000 ms</td>
</tr>
<tr>
<td><code>on_phase_*/2</code></td>
<td>world</td>
<td>yes</td>
<td>200 ms</td>
</tr>
<tr>
<td><code>terrain_provider/1</code></td>
<td>world</td>
<td>yes</td>
<td>2000 ms</td>
</tr>
<tr>
<td><strong><code>handle_input/3</code></strong></td>
<td><strong>match, world</strong></td>
<td><strong>NO</strong></td>
<td><strong>(see below)</strong></td>
</tr>
</tbody>
</table>
<p><code>handle_input/3</code> is the one callback that does <strong>not</strong> spawn-isolate.
At realistic input rates (one tick × N players × the message rate)
the per-call spawn cost dominated the actual Lua work (~30-50 µs spawn</p>
<ul>
<li>monitor + heap-cap setup vs ~50-200 µs of input handling). Removing
the wrapper recovered measured tail-latency wins of 35-45 % at 200
players × 10 Hz input. See ADR 0002.</li>
</ul>
<p>The trade is explicit: a <code>while true do end</code> inside <code>handle_input</code> now
hangs the match server until its caller's <code>gen_server:call/2</code> timeout
trips (5 s default). The match supervisor then restarts the match
process. Blast radius is one match.</p>
<p><code>handle_input/3</code> is therefore <strong>not a sandbox boundary</strong>. It is a hot
path for trusted-author scripts. Audit the inputs your match script
accepts and avoid pattern-matching dispatch on attacker-controlled
strings; otherwise, treat the same as you would any Erlang gen_server
handle_call/2 implementation. Per-tick safety remains owned by
<code>tick/1</code>, which still spawn-isolates and is the right place to
enforce wall-clock fairness across players.</p>
"""}
    ]}.
