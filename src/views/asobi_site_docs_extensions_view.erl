%% GENERATED from asobi guides/extensions.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_extensions_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-extensions", title => ~"Extensions — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Extensions"
        ]},
        {h1, [], [~"Extensions"]},
        {raw,
            ~"""
<p>An extension is an ordinary OTP application that depends on asobi, added as a
dependency of your release, plus one small module telling asobi the few things
it cannot discover.</p>
<p>No new packaging concept, no new lifecycle, nothing to learn beyond OTP.</p>
<p>This contract is experimental. The wire freezes, because SDK users vendor by
copying source. The manifest does not, until a real second consumer has said
what it is missing.</p>
<h2 id="installing-one" tabindex="-1">Installing one</h2>
<pre><code class="language-erlang">%% your_game_app/rebar.config
{deps, [
    {asobi, &quot;~&gt; 0.68&quot;},
    {asobi_quests, {git, &quot;https://github.com/you/asobi_quests.git&quot;, {tag, &quot;v1.0.0&quot;}}}
]}.

{relx, [{release, {your_game, &quot;1.0.0&quot;},
         [your_game_app, asobi_quests, asobi, sasl]}]}.
</code></pre>
<p>Two lines. Removing an extension is deleting them; its tables survive until
deliberately purged, because destroying player progress on a dependency change
is the wrong default.</p>
<p><code>asobi_quests</code> depends on <code>asobi</code> and your app depends on both. asobi never
depends on an extension, so the reverse edge is a cycle relx sorts into a build
failure and Hex rejects outright.</p>
<p>Validate the set before you boot it:</p>
<pre><code class="language-erlang">{project_plugins, [{asobi, {git, &quot;https://github.com/widgrensit/asobi.git&quot;, {tag, &quot;v0.68.2&quot;}}}]}.
</code></pre>
<pre><code class="language-sh">rebar3 asobi check
</code></pre>
<p>Pin the plugin to the same tag as the dependency. Core's reserved names come
from the plugin's own copy of asobi, so a skewed pin validates against the
wrong reserved set.</p>
<p>This is the gate. asobi validates the same set again at boot, but a boot-time
failure is raised from inside Nova's route compilation and surfaces with Nova's
crash context rather than a legible asobi error.</p>
<p>The published image <code>ghcr.io/widgrensit/asobi</code> runs a release built from a
fixed application set at image build time, so installing a third-party
extension means building your own release from the Hex package.</p>
<h2 id="who-calls-an-extension" tabindex="-1">Who calls an extension</h2>
<table>
<thead>
<tr>
<th>Caller</th>
<th>Path</th>
<th>For</th>
</tr>
</thead>
<tbody>
<tr>
<td>Game logic, in-match, server-side</td>
<td><code>game.quests.progress(player_id, 1)</code></td>
<td>&quot;player killed something, +1&quot;</td>
</tr>
<tr>
<td>Game client, over the network</td>
<td>an <code>rpc.call</code> frame - <code>ws.rpc(...)</code> in JS, <code>rpc_call(...)</code> in Godot, <code>realtime:rpc(...)</code> in Defold and LÖVE</td>
<td>&quot;give me my reward&quot;</td>
</tr>
<tr>
<td>An operator, on the ops plane</td>
<td><code>POST /api/v1/ops/ext/quests/define</code></td>
<td>&quot;add a daily quest&quot;</td>
</tr>
</tbody>
</table>
<p>An extension with only the wire cannot observe gameplay; one with only Lua
cannot be triggered by a player action from the client. The third is a
different audience, not a third way to reach the same one: <code>rpc/0</code> is
player-scoped, and no player ever holds an operator capability.</p>
<h2 id="what-you-declare" tabindex="-1">What you declare</h2>
<pre><code class="language-erlang">-module(asobi_quests_extension).
-behaviour(asobi_extension).
-export([info/0, rpc/0, lua/0, sup/0, owns/0, codes/0, ops/0, erase_player/1]).

info() -&gt; #{name =&gt; quests, extension_version =&gt; 1}.

rpc()  -&gt; #{~&quot;quests.list&quot;  =&gt; {asobi_quests_rpc, list,  2},
            ~&quot;quests.claim&quot; =&gt; {asobi_quests_rpc, claim, 2}}.

lua()  -&gt; #{~&quot;quests&quot; =&gt;
              #{~&quot;progress&quot; =&gt; #{mfa     =&gt; {asobi_quests_lua, progress, 2},
                                 args    =&gt; [binary, integer],
                                 effects =&gt; write,
                                 vms     =&gt; [match, world]}}}.

sup()  -&gt; [#{id    =&gt; asobi_quests_tracker,
             start =&gt; {asobi_quests_tracker, start_link, []}}].

owns() -&gt; #{tables =&gt; [~&quot;quests&quot;, ~&quot;quest_progress&quot;],
            rpc    =&gt; [~&quot;quests&quot;],
            lua    =&gt; [~&quot;quests&quot;],
            queues =&gt; [~&quot;quests&quot;]}.

codes() -&gt; #{~&quot;quests.already_claimed&quot; =&gt;
               #{status =&gt; 409, message =&gt; ~&quot;This quest was already claimed.&quot;}}.

ops()  -&gt; #{~&quot;define&quot; =&gt; #{method =&gt; post,
                           mfa    =&gt; {asobi_quests_ops, define, 2},
                           class  =&gt; config}}.
</code></pre>
<p>Discovery looks for a module literally named <code>&lt;app&gt;_extension</code> in the
application's own module list (<code>application:get_key(App, modules)</code>). The
<code>-behaviour</code> attribute is not what makes it found; the name is. Depending on
asobi is not the filter either, or every game embedding asobi would be an
extension.</p>
<p>Only <code>info/0</code> is required. The rest default to nothing.</p>
<ul>
<li><code>rpc/0</code> - core cannot guess that <code>quests.claim</code> is <code>{asobi_quests_rpc, claim, 2}</code>.
The arity is always 2; see <a href="#writing-an-rpc-handler">Writing an RPC handler</a>.</li>
<li><code>lua/0</code> - the <code>game.&lt;ns&gt;.*</code> surface a Lua game calls. See
<a href="#writing-a-lua-binding">Writing a Lua binding</a>.</li>
<li><code>sup/0</code> - child specs, if you want asobi supervising them.</li>
<li><code>owns/0</code> - the closed statement of what this extension claims. See
<a href="#namespaces">Namespaces</a>.</li>
<li><code>codes/0</code> - the error codes this extension mints. See
<a href="#error-codes">Error codes</a>.</li>
<li><code>ops/0</code> - operator actions, reached on the ops plane rather than by a player.
See <a href="#writing-an-operator-action">Writing an operator action</a>.</li>
<li><code>erase_player/1</code> - how to erase one player, when your rows do not cascade.
See <a href="#deleting-a-player">Deleting a player</a>.</li>
<li><code>info/0</code> - <code>name</code> is the extension's identity and the root of everything it
owns. <code>extension_version</code> is recorded in the registry and printed by
<code>rebar3 asobi check</code>; nothing enforces it, and no behaviour changes with it.</li>
</ul>
<h2 id="writing-an-rpc-handler" tabindex="-1">Writing an RPC handler</h2>
<p>A client calls a declared method over the WebSocket:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;rpc.call&quot;, &quot;cid&quot;: &quot;c-1&quot;,
 &quot;payload&quot;: {&quot;protocol&quot;: 1, &quot;method&quot;: &quot;quests.claim&quot;, &quot;params&quot;: {&quot;quest_key&quot;: &quot;daily_kills&quot;}}}
</code></pre>
<p>and gets back one of:</p>
<pre><code class="language-json">{&quot;type&quot;: &quot;rpc.ok&quot;,    &quot;cid&quot;: &quot;c-1&quot;, &quot;payload&quot;: {&quot;result&quot;: {&quot;quest_key&quot;: &quot;daily_kills&quot;, &quot;currency&quot;: &quot;gold&quot;, &quot;amount&quot;: 100}}}
{&quot;type&quot;: &quot;rpc.error&quot;, &quot;cid&quot;: &quot;c-1&quot;, &quot;payload&quot;: {&quot;error&quot;: {&quot;code&quot;: &quot;quests.already_claimed&quot;, &quot;message&quot;: &quot;...&quot;, &quot;details&quot;: {}}}}
</code></pre>
<p>See <a href="/docs/protocols/websocket">WebSocket protocol</a> for the frames either side of
this one. <code>cid</code> is required here and validated server-side (1-64 printable
ASCII bytes), unlike the optional echo the rest of the socket takes: it is the
only way a client pairs a reply with the call it made. <code>params</code> and <code>result</code>
are always objects, so either can grow a field without breaking a shipped
client.</p>
<p><code>protocol</code> is core's RPC payload version, currently <code>1</code>, and is unrelated to
your <code>extension_version</code>. Any other value answers <code>rpc.unsupported_protocol</code>
with <code>details.supported</code> listing what this node speaks. A node reports its own
from <code>asobi_rpc:protocol/0</code>.</p>
<p>You rarely build that frame by hand. Every client SDK wraps it, generates the
<code>cid</code> and correlates the reply for you:</p>
<pre><code class="language-js">// asobi-js: resolves with `result`, rejects with an AsobiRpcError
try {
  const { currency, amount } = await ws.rpc(&quot;quests.claim&quot;, { quest_key: &quot;daily_kills&quot; });
} catch (e) {
  if (e.code === &quot;quests.already_claimed&quot;) { /* domain outcome */ }
}
</code></pre>
<pre><code class="language-gdscript"># asobi-godot: the reply arrives on the callable, keyed by the returned cid
realtime.rpc_call(&quot;quests.claim&quot;, {&quot;quest_key&quot;: &quot;daily_kills&quot;}, func(ok, data):
    if ok: print(data[&quot;amount&quot;], data[&quot;currency&quot;])
    else:  print(data[&quot;code&quot;]))
</code></pre>
<p>Without an SDK - to check a method by hand, or from a language with no asobi
SDK yet - it is two frames on the socket. RPC rides the game WebSocket, so this
is <code>websocat</code> rather than <code>curl</code>, and the socket must be authenticated first:
an <code>rpc.call</code> on an unauthenticated socket is rejected, because <code>rpc/0</code> is
player-scoped and there is no player yet.</p>
<pre><code class="language-bash">TOKEN=$(curl -sX POST https://your-host/api/v1/auth/login \
  -H 'content-type: application/json' \
  -d '{&quot;username&quot;:&quot;alice&quot;,&quot;password&quot;:&quot;...&quot;}' | jq -r .access_token)

printf '%s\n%s\n' \
  &quot;{\&quot;type\&quot;:\&quot;session.connect\&quot;,\&quot;cid\&quot;:\&quot;1\&quot;,\&quot;payload\&quot;:{\&quot;token\&quot;:\&quot;$TOKEN\&quot;}}&quot; \
  '{&quot;type&quot;:&quot;rpc.call&quot;,&quot;cid&quot;:&quot;2&quot;,&quot;payload&quot;:{&quot;protocol&quot;:1,&quot;method&quot;:&quot;quests.claim&quot;,&quot;params&quot;:{&quot;quest_key&quot;:&quot;daily_kills&quot;}}}' \
  | websocat wss://your-host/ws
</code></pre>
<p>The reply carries the <code>cid</code> you sent, which is what lets several calls be in
flight at once:</p>
<pre><code class="language-json">{&quot;type&quot;:&quot;rpc.ok&quot;,&quot;cid&quot;:&quot;2&quot;,&quot;payload&quot;:{&quot;result&quot;:{&quot;reward&quot;:100}}}
</code></pre>
<p>Branch on <code>code</code>, never on <code>message</code>. The shape is the same in every SDK - a
method name, a params object, and a reply that is either a result object or the
shared error object - so a method you declare here is callable from all of them
without a per-engine server change. <code>flame_asobi</code> is a Flame bridge over the
Dart SDK rather than a protocol implementation of its own, so it inherits
<code>rpc</code> from it.</p>
<p>The handler is <code>(Params, Ctx)</code>, which is why the arity in <code>rpc/0</code> is always 2:</p>
<pre><code class="language-erlang">-spec claim(asobi_rpc:params(), asobi_rpc:ctx()) -&gt; asobi_rpc:reply().
claim(#{~&quot;quest_key&quot; := QuestKey}, #{player_id := PlayerId}) -&gt;
    case asobi_quests:claim(PlayerId, QuestKey) of
        {ok, #{currency := C, amount := A}} -&gt;
            {ok, #{quest_key =&gt; QuestKey, currency =&gt; C, amount =&gt; A}};
        {error, already_claimed} -&gt; {error, ~&quot;quests.already_claimed&quot;};
        {error, {no_such, Key}}  -&gt; {error, ~&quot;quests.not_found&quot;, #{quest_key =&gt; Key}}
    end.
</code></pre>
<p><code>{ok, map()} | {error, Code} | {error, Code, Details}</code>.</p>
<p>The failure half is a code, never a status and never an object you build
yourself. Both are derived from the code - <code>asobi_error:status/1</code> and
<code>asobi_error:object/2</code> - so two call sites cannot answer the same code
differently, and a code you declared in <code>codes/0</code> reaches the client as
itself. It is the same dialect core's own controllers speak
(<code>{asobi_error, Code, Details}</code>), so there is one shape to learn.</p>
<p><code>Ctx</code> is <code>#{player_id, session, method}</code>. It may gain keys: match the ones you
need with <code>:=</code> and never match it exhaustively.</p>
<p>Everything else is a defect and answers <code>internal</code> with one logged line naming
the method: a handler that raises, one that returns outside the contract, one
declared at an arity other than 2, a result that cannot be JSON-encoded, and a
code you did not declare in <code>codes/0</code>. The last one is how the closed code set
survives a surface where the code is a runtime term the handler could have
built out of <code>params</code>.</p>
<h3 id="what-the-seam-answers" tabindex="-1">What the seam answers</h3>
<table>
<thead>
<tr>
<th>Code</th>
<th>Status</th>
<th>When</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>rpc.unknown_method</code></td>
<td>404</td>
<td>no installed extension declares that method, or <code>method</code> is not a string</td>
</tr>
<tr>
<td><code>rpc.invalid_cid</code></td>
<td>400</td>
<td><code>cid</code> missing, empty, over 64 bytes, or not printable ASCII</td>
</tr>
<tr>
<td><code>rpc.invalid_params</code></td>
<td>400</td>
<td><code>params</code> is not a JSON object</td>
</tr>
<tr>
<td><code>invalid_payload</code></td>
<td>400</td>
<td><code>payload</code> is not a JSON object</td>
</tr>
<tr>
<td><code>rpc.unsupported_protocol</code></td>
<td>400</td>
<td><code>protocol</code> is not this node's version</td>
</tr>
<tr>
<td><code>unauthenticated</code></td>
<td>401</td>
<td>the socket has not completed <code>session.connect</code></td>
</tr>
<tr>
<td><code>not_ready</code></td>
<td>503</td>
<td>migrations have not finished on this node</td>
</tr>
<tr>
<td><code>internal</code></td>
<td>500</td>
<td>the handler is at fault; see above</td>
</tr>
</tbody>
</table>
<p>A rejected <code>cid</code> comes back on a frame carrying no <code>cid</code> at all, because there
is nothing trustworthy to echo. That one reply cannot be correlated: a client
that sends a malformed <code>cid</code> gets an answer it must match by shape, not by id.</p>
<h3 id="before-dispatch" tabindex="-1">Before dispatch</h3>
<p>The socket applies two limits ahead of any of the above, so a chatty method has
to be sized against them:</p>
<ul>
<li>64 KiB per text frame. A larger frame answers <code>payload_too_large</code>.</li>
<li>60 messages per second per connection, in a fixed one-second window. Over it
answers <code>rate_limited</code>.</li>
</ul>
<p>Both answer on the legacy <code>error</code> frame with no <code>cid</code>, so neither is
correlatable either. The budget is per connection, held in the socket's own
state: it counts every frame the socket carries, not just <code>rpc.call</code>, and
adding nodes does not widen it. The buckets that are counted per node are the
HTTP and connect limiters - see <a href="/docs/clustering">Clustering</a>.</p>
<h3 id="every-declared-method-is-player-scoped" tabindex="-1">Every declared method is player-scoped</h3>
<p>The caller is the authenticated player on that socket; an unauthenticated
socket is refused before the method is looked up. There is deliberately no
per-method capability class: <code>read | player_data | config | erasure</code> is an operator
vocabulary that a player never holds, so tagging a socket method with one would
make it deniable for every caller the dispatcher has. An operator-only method
goes in <code>ops/0</code> instead.</p>
<h2 id="writing-an-operator-action" tabindex="-1">Writing an operator action</h2>
<p><code>rpc/0</code> is player-scoped, so an admin action - defining a quest, correcting a
counter, anything a player must never call - has no home there. <code>ops/0</code> is that
home, reached on the ops plane by an operator credential:</p>
<pre><code class="language-erlang">-spec ops() -&gt; asobi_extension:ops().
ops() -&gt;
    #{~&quot;define&quot; =&gt; #{method =&gt; post,
                     mfa    =&gt; {asobi_quests_ops, define, 2},
                     class  =&gt; config},
      ~&quot;summary&quot; =&gt; #{method =&gt; get,
                      mfa    =&gt; {asobi_quests_ops, summary, 2},
                      class  =&gt; read}}.
</code></pre>
<pre><code>POST /api/v1/ops/ext/quests/define
GET  /api/v1/ops/ext/quests/summary?filter=active
</code></pre>
<p><code>/api/v1/ops/ext/:extension/:action</code> is the extension seam on the ops plane,
and this is what puts something behind it. Core's own routes there are reads
apart from erasing and exporting a player. You still declare no routes: core
owns <code>/ext/:extension/:action</code> and dispatches every declared action behind it,
the same way it owns one WebSocket frame type and dispatches <code>rpc/0</code> behind
that.</p>
<p>Know what gates it. On a stock deployment there is no <code>ops_secret</code>, so every
bearer request is denied 403 and none of this is reachable. Once a secret is
set, these routes are live whether or not the console is - <code>console</code> gates
<code>/console</code> only, never the ops plane. A holder of the secret holds every
capability class, so declaring <code>class =&gt; config</code> restricts which <em>minted</em> tokens
reach an action, not which secret-holders do. <code>erasure</code> is the one class a
console session does not get by default, so declaring it also keeps an action
out of a browser unless the operator set <code>console_erasure</code>. See
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<p>The console cannot invoke an ops action today. The surface is HTTP only, and
<code>ops</code> is not among the capabilities <code>/api/v1/ops/features</code> reports for an
extension - it reports <code>lua</code>, <code>rpc</code> and <code>tables</code>.</p>
<p>Same handler shape as <code>rpc/0</code>:</p>
<pre><code class="language-erlang">-spec define(map(), asobi_ops_extension:ctx()) -&gt; asobi_rpc:reply().
define(#{~&quot;key&quot; := Key}, #{actor := #{id := ActorId}}) -&gt;
    case asobi_quests:define(Key, ActorId) of
        {ok, Quest}          -&gt; {ok, #{quest =&gt; Quest}};
        {error, name_taken}  -&gt; {error, ~&quot;quests.name_taken&quot;}
    end.
</code></pre>
<p><code>Params</code> is the decoded JSON body for a write and the parsed query string for
a <code>get</code>. <code>Ctx</code> is <code>#{actor, extension, action}</code>, so recording who asked and
what they reached needs no second lookup.</p>
<p>Readiness guards this plane as well as the socket: until migrations finish,
every action answers <code>not_ready</code> (503).</p>
<p>Three things are core's, not yours:</p>
<ul>
<li><code>class</code> is the whole authorisation. <code>read | player_data | config | erasure</code> is
the same vocabulary core's own ops routes carry. An action is admitted when its class
is in the caller's capabilities and never otherwise. There is nothing to
check inside your handler.</li>
<li>An undeclared action is denied, not 404. It has no class, and a route with no
class is refused - so an unknown extension, an unknown action and a method
the action does not answer all answer 403. Which extensions are installed is
not something an unauthorised caller gets to enumerate.</li>
<li>Every method but <code>get</code> is audited. Core runs your function inside
<code>asobi_ops_audit:mutation/4</code> and writes the row from what it returned. You
cannot opt out, and declaring a method other than <code>get</code> is what opts in.</li>
</ul>
<h3 id="what-the-audit-records-today" tabindex="-1">What the audit records today</h3>
<p>The audit path understands <code>{ok, Succeeded, Failed} | {error, Reason}</code>. An ops
handler returns <code>{ok, map()} | {error, Code} | {error, Code, Details}</code>, so only
the two-element <code>{error, Code}</code> matches. Everything else raises inside the
audit write, which is caught and downgraded to an error-level log line naming
the action, the exception class and the reason.</p>
<p>So today, a failing action returning <code>{error, Code}</code> records a durable row; a
successful mutation and a raising one are logged, not recorded. The response to
the caller is unaffected either way. Tracked as an open issue; do not build a
compliance story on the row until it is closed.</p>
<h3 id="manifest-validation" tabindex="-1">Manifest validation</h3>
<p>Each of these is a build failure at <code>rebar3 asobi check</code>, and again at boot:</p>
<ul>
<li>the action is one non-empty path segment, with no <code>/ . ? # %</code></li>
<li><code>method</code> is <code>get</code>, <code>post</code>, <code>put</code> or <code>delete</code></li>
<li><code>class</code> is <code>read</code>, <code>player_data</code> or <code>config</code></li>
<li><code>mfa</code> is <code>{Module, Function, 2}</code></li>
</ul>
<h2 id="writing-a-lua-binding" tabindex="-1">Writing a Lua binding</h2>
<p>A game script calls the namespace as an ordinary part of <code>game</code>:</p>
<pre><code class="language-lua">function on_player_kill(player_id, state)
    local result = game.quests.progress(player_id, 1)
    if result.error then
        game.log(&quot;warning&quot;, &quot;quest progress failed: &quot; .. result.error)
    end
end
</code></pre>
<p>The binding takes the declared arguments positionally, already decoded to the
types <code>args</code> names, and returns the same envelope every persistence-style
<code>game.*</code> call returns:</p>
<pre><code class="language-erlang">-spec progress(binary(), integer()) -&gt; {ok, term()} | {error, binary()}.
progress(PlayerId, Amount) -&gt;
    case asobi_quests:progress(PlayerId, Amount) of
        {ok, Count} -&gt; {ok, Count};
        {error, _}  -&gt; {error, ~&quot;progress failed&quot;}
    end.
</code></pre>
<p>Lua reads <code>result.ok</code> or <code>result.error</code>. Nothing is ever silently nil: a wrong
or missing argument is <code>{ error = &quot;argument 2 must be a integer&quot; }</code> at the
script's own call site, and a binding that raises or returns outside the
contract is an error result plus one logged line naming the function.</p>
<p><code>args</code> types are <code>binary</code>, <code>integer</code>, <code>number</code>, <code>boolean</code>, <code>table</code> and <code>any</code>,
one per <code>mfa</code> argument. Lua has a single number type, so a script writing <code>1</code>
may hand over <code>1.0</code>; a whole float satisfies <code>integer</code>.</p>
<p><code>effects</code> is <code>write</code> or <code>none</code>, and it is not decoration: probe VMs re-run the
whole script body to ask <code>phases()</code> and swap every <code>write</code> function for an
inert stub, so a <code>write</code> declared <code>none</code> fires twice on every match creation.</p>
<p><code>vms</code> decides which VM kinds see the binding, and may name <code>match</code>, <code>world</code> or
<code>zone</code>. A <code>match</code> binding is absent from a world's zone VMs, and its namespace
table is not even created there.</p>
<p><code>bot</code> is refused at <code>rebar3 asobi check</code>, not ignored. A bot script is loaded
with no <code>game</code> table at all - see <a href="https://hexdocs.pm/asobi/lua-bots.html">Bots</a> - so a binding declaring
<code>bot</code> would install nothing, and a declaration that silently does nothing is a
defect. Making it work was rejected: a bot has no <code>players.id</code>, so the argument
every extension binding takes cannot be supplied. A bot decides from the state
the match broadcasts and nothing more; put what it needs in that state.</p>
<p>Core calls <code>{M, F, A}</code> fully qualified rather than holding a fun, so a code
upgrade takes effect without waiting for every live match VM to end.</p>
<h2 id="most-of-it-is-discovered" tabindex="-1">Most of it is discovered</h2>
<table>
<thead>
<tr>
<th>Thing</th>
<th>How asobi finds it</th>
<th>You declare</th>
</tr>
</thead>
<tbody>
<tr>
<td>Migrations</td>
<td><code>application:get_key(App, modules)</code>, matched on <code>m&lt;14 digits&gt;_</code></td>
<td>nothing</td>
</tr>
<tr>
<td>Schemas</td>
<td>Same module list, filtered by &quot;exports <code>table/0</code> and <code>fields/0</code>&quot;</td>
<td>nothing</td>
</tr>
<tr>
<td>Background jobs</td>
<td>Nothing at all. The job row names the worker module</td>
<td>nothing</td>
</tr>
<tr>
<td>Domain logic</td>
<td>Nothing. They are modules; other code calls them</td>
<td>nothing</td>
</tr>
<tr>
<td>RPC handlers</td>
<td>Cannot be inferred</td>
<td><code>rpc/0</code></td>
</tr>
<tr>
<td>Lua namespace</td>
<td>Cannot be inferred</td>
<td><code>lua/0</code></td>
</tr>
<tr>
<td>Operator actions</td>
<td>Cannot be inferred</td>
<td><code>ops/0</code></td>
</tr>
<tr>
<td>Error codes</td>
<td>Cannot be inferred; the core set is closed</td>
<td><code>codes/0</code></td>
</tr>
<tr>
<td>Supervised processes</td>
<td>Optional</td>
<td><code>sup/0</code></td>
</tr>
<tr>
<td>Namespace ownership</td>
<td>Cannot be inferred</td>
<td><code>owns/0</code></td>
</tr>
</tbody>
</table>
<p><code>rebar3 asobi check</code> warns that an extension declaring neither <code>rpc/0</code> nor
<code>lua/0</code> is &quot;reachable by nobody&quot;. The check counts those two only, so the
warning also fires for an extension whose entire surface is <code>ops/0</code>, which is
reachable. It is spurious for that case and safe to ignore; tracked as an open
issue.</p>
<h2 id="prefer-a-library-application" tabindex="-1">Prefer a library application</h2>
<p>If your extension has processes, omit <code>mod</code> from your <code>.app.src</code> and declare
children via <code>sup/0</code>.</p>
<pre><code>asobi_sup  (one_for_one, 10/60)
  `- asobi_extension_sup       (one_for_one, 3/60)
       |- quests               (own restart budget)
       `- clans
</code></pre>
<p>Applications in a release are permanent by default, and in OTP a permanent
application terminating takes the whole runtime with it. So a normal OTP app
whose supervisor exceeds its restart intensity kills the node - matchmaking,
presence, every live match. Under <code>asobi_extension_sup</code> an extension that
exhausts its own budget goes dark, core logs which one, and the node survives.
This is the ordinary BEAM pattern: Ecto repos, Oban and Phoenix endpoints are
all started in the host's tree rather than by the library.</p>
<p>An application with its own <code>mod</code> also works; you then own the failure mode,
and the operator has to mark it non-permanent in the release. With no <code>mod</code>
there is no <code>start/2</code> for one-time setup: ETS tables and config validation move
into the <code>init/1</code> of a supervised worker.</p>
<p>Per-extension restart limits default to 5 in 60 and are settable:</p>
<pre><code class="language-erlang">{asobi, [{extension_restart, #{intensity =&gt; 5, period =&gt; 60}}]}
</code></pre>
<p><code>sup/0</code> children are per node. A supervised <code>gen_server</code> holding state holds N
copies of it across an N-node cluster, one per node, with nothing synchronising
them; and matches and worlds do not migrate between nodes. See
<a href="/docs/clustering">Clustering</a>.</p>
<h2 id="boot-order-and-readiness" tabindex="-1">Boot order and readiness</h2>
<p>The route table compiles during Nova's boot, inside <code>nova_sup:init/1</code>;
migrations run afterwards, from <code>asobi_app:start/2</code>. An extension endpoint is
therefore reachable before its tables exist, so both seams fail closed until
migrations finish: every RPC call and every ops action answers <code>not_ready</code>
(503) until then. You get this for free - there is nothing to call.</p>
<pre><code class="language-erlang">case asobi_readiness:guard() of
    ok -&gt; dispatch(Extension, Action, Actor, Req);
    {error, _Object} -&gt; {asobi_error, ~&quot;not_ready&quot;}
end.
</code></pre>
<p>Your <code>sup/0</code> children are on the other side of that seam and get two
guarantees, so none of them needs a retry path:</p>
<ul>
<li>They start in the order <code>sup/0</code> returns them, and after the children of every
extension your application depends on. That is OTP's own child order and
<code>asobi_extensions:resolve/0</code>'s dependency order; nothing sorts either.</li>
<li><code>init/1</code> may query. Extension children start after migrations have run to
completion, so the pool is up and every table - core's and yours - exists.</li>
</ul>
<p>Two failure modes are worth stating plainly:</p>
<ul>
<li>An invalid manifest set stops the node. <code>asobi_extensions:resolve/0</code> raises
<code>{asobi_extensions, Problems}</code> after logging each problem in prose, from
inside Nova's route compilation. The node does not start. This is why
<code>rebar3 asobi check</code> is the gate.</li>
<li>If migrations did not complete, <code>asobi_extension_sup</code> starts no extension at
all and logs which ones it did not start, and every extension seam answers
503. The alternative is every extension crash-looping into its own restart
budget and going dark anyway. The marker is written once, before this
supervisor exists, so it cannot flip later and there is nothing to retry.</li>
</ul>
<h2 id="namespaces" tabindex="-1">Namespaces</h2>
<p><code>owns/0</code> reserves names. Two extensions claiming the same table, RPC prefix,
Lua namespace or job queue is a build failure naming both claimants, and so is
claiming a name core reserves.</p>
<p>The claim set is <code>owns/0</code> plus what your own code already implies, and every
kind derives:</p>
<table>
<thead>
<tr>
<th>Kind</th>
<th>Derived from</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>rpc</code></td>
<td>the prefixes in <code>rpc/0</code> and the domains in <code>codes/0</code></td>
</tr>
<tr>
<td><code>lua</code></td>
<td>the namespaces in <code>lua/0</code></td>
</tr>
<tr>
<td><code>tables</code></td>
<td><code>table/0</code> on your <code>kura_schema</code> modules</td>
</tr>
<tr>
<td><code>queues</code></td>
<td><code>queue/0</code> on your <code>shigoto_worker</code> modules</td>
</tr>
</tbody>
</table>
<p>So a collision is caught even before either extension has bothered with
<code>owns/0</code>, and a queue you actually run is claimed whether or not you remembered
to say so. That leaves <code>owns/0</code> one job: the closed-set assertion. Naming a
kind at all says &quot;this is the whole set&quot;, so anything derived outside it is a
build failure - which is what catches a worker on <code>quests</code> under an <code>owns/0</code>
saying <code>quest</code>.</p>
<p>Core's reserved names derive from core itself by the same rules: Lua namespaces
from <code>asobi_lua_surface:reserved_namespaces/0</code>, tables from core's schemas,
queues from core's shigoto workers.</p>
<p>Reserved RPC prefixes are the domains of <code>asobi_error:core_codes/0</code> plus every
core Lua namespace, because an RPC prefix and an error-code domain are the same
token. So <code>game</code>, <code>economy</code>, <code>leaderboard</code>, <code>storage</code>, <code>chat</code>, <code>spatial</code>,
<code>zone</code> and <code>terrain</code> are all refused as RPC prefixes as well as Lua
namespaces - owning <code>storage</code> would mint codes inside core's closed code set.</p>
<h2 id="error-codes" tabindex="-1">Error codes</h2>
<p><code>asobi_error</code>'s set is closed, so a code you have not declared answers 500 and
logs as a core defect. Declare yours:</p>
<pre><code class="language-erlang">codes() -&gt; #{~&quot;quests.already_claimed&quot; =&gt;
               #{status =&gt; 409, message =&gt; ~&quot;This quest was already claimed.&quot;},
             ~&quot;quests.not_found&quot; =&gt;
               #{status =&gt; 404, message =&gt; ~&quot;No quest exists with this id.&quot;}}.
</code></pre>
<p><code>{asobi_error, ~&quot;quests.already_claimed&quot;}</code> then answers 409 with the shared
object and logs nothing.</p>
<p>Every code must be <code>&lt;domain&gt;.&lt;name&gt;</code> with the domain an RPC prefix you own, so
<code>rebar3 asobi check</code> refuses a code in core's namespace or another extension's,
and refuses a bare one. <code>status</code> must be 100-599 and <code>message</code> non-empty. The
set is read once at boot, from the manifest, so it stays closed per
deployment - a string arriving in a request or a Lua script cannot become a
code.</p>
<h2 id="tables" tabindex="-1">Tables</h2>
<p>Three distinct things, and only one creates a table:</p>
<ol>
<li>The schema - a <code>kura_schema</code> module. Describes.</li>
<li>The migration - generated by <code>rebar3 kura compile</code>, never hand-written.
Creates.</li>
<li><code>owns/0</code> - reserves the name. Creates nothing.</li>
</ol>
<p>Rules:</p>
<ul>
<li>An extension may foreign-key into core. Core never foreign-keys into an
extension.</li>
<li>Extensions never alter core tables. Use a sidecar table keyed on
<code>player_id</code>. Two extensions both adding <code>level</code> to <code>players</code> is
unrecoverable, and core adding the same column later is worse.</li>
<li>An extension FK into <code>players.id</code> must cascade or declare an erase path. A
blanket cascade was rejected: cascading <code>players</code> into <code>iap_transactions</code>
would destroy real-money purchase records that a refund or chargeback
dispute still needs.</li>
</ul>
<p>Your migrations run from your own application: kura discovers them through
<code>asobi_repo:migration_apps/0</code>, inside core's transaction and under one
advisory lock.</p>
<h3 id="a-table-extracted-out-of-core" tabindex="-1">A table extracted out of core</h3>
<p><code>owns/0</code> and the migration that creates a table are separable, and one case
needs them separate: a table that used to be core's.</p>
<p><code>asobi_seasons</code> owns <code>seasons</code>, but the <code>CREATE TABLE</code> sits in an asobi
migration that has already run against live databases, and shares a file with a
table core kept. So the extension ships a schema and no migration, and asobi
keeps the history it cannot honestly disown. Ownership is the manifest's job;
history is append-only.</p>
<p>The operational consequence: core has no <code>seasons</code> schema, so <code>rebar3 kura compile</code> will offer to drop the table. Decline it. The same applies to any
table extracted this way, and this is the shape of every future extraction. It
only applies to a table core once created: a table an extension invents is
created by the extension's own migration, like <code>quests</code>.</p>
<h2 id="deleting-a-player" tabindex="-1">Deleting a player</h2>
<p>Cascade or declare an erase path - and an undeclared <code>on_delete</code> lowers to
<code>no_action</code>, so the foreign key <code>rebar3 kura compile</code> generates refuses the
delete until you have picked one. The first row your extension writes for a
player makes that player undeletable otherwise. The symptom of declaring
neither is guests quietly ceasing to be reaped.</p>
<p>Cascade is one line on the association:</p>
<pre><code class="language-erlang">#kura_assoc{
    name = player, type = belongs_to, schema = asobi_player,
    foreign_key = player_id, on_delete = cascade
}
</code></pre>
<p><code>rebar3 kura compile</code> carries that into the generated migration as
<code>ON DELETE CASCADE</code>, and there is nothing else to write.</p>
<p>Cascade is right for progress rows and wrong for a financial or audit row -
the case that rejected a blanket cascade in the first place. Implement
<code>erase_player/1</code> instead:</p>
<pre><code class="language-erlang">-spec erase_player(binary()) -&gt; ok | {error, term()}.
erase_player(PlayerId) -&gt;
    {ok, _} = asobi_repo:delete_all(by_player(asobi_quest_progress, PlayerId)),
    ok.
</code></pre>
<h3 id="who-calls-it-and-when" tabindex="-1">Who calls it, and when</h3>
<p><code>asobi_player_erase</code> does. That is the single place core deletes a player, and
it has two entry points: <code>asobi_player_erase:run/1</code> from an Erlang shell, and
<code>POST /api/v1/ops/players/:id/erase</code> on the ops plane. The guest reaper is one
more caller of the same code rather than a second implementation of it, so
there is one erasure path and your callback is on it whichever way the deletion
was asked for.</p>
<p>Core calls it inside its own transaction, before deleting any of its own rows,
once per installed extension in dependency order. Do not open a transaction of
your own. Extensions run before core so an erase path can still read the
player's core rows.</p>
<p>Erasure is atomic across every extension. Returning <code>{error, Reason}</code> or
raising aborts the whole deletion - no extension's rows go, core's rows stay,
the player survives, and one logged line names the extension and the reason. So
an erase path doing work the transaction cannot undo, such as deleting a remote
object, must be idempotent: a later extension's failure rolls back everything
around it and the deletion is retried.</p>
<p>Omit <code>erase_player/1</code> when your rows cascade: it is the alternative to that
declaration, not a second copy of it. Cascade lives on the column because the
database is what enforces it, which is why this is a callback and not an
<code>owns/0</code> key.</p>
<h3 id="the-third-option-sever-the-reference" tabindex="-1">The third option: sever the reference</h3>
<p>Delete the rows, or null the player reference and keep the row. Core does both
in one function and it is worth reading as the worked example, because a
receipts table is exactly where authors get stuck.</p>
<p><code>asobi_player_erase:steps/1</code> deletes eleven tables and severs two:</p>
<ul>
<li><code>iap_transactions.player_id</code> is set to <code>NULL</code>. The receipt carries a
provider, a store transaction id and a product id, and a refund or chargeback
dispute needs it long after the account is gone. Statutory retention beats
erasure for that row.</li>
<li><code>groups.creator_id</code> is set to <code>NULL</code>. Deleting the group to free the key
would destroy every other member's data.</li>
</ul>
<p>Everything else goes. That <em>is</em> the anonymisation: every player-referencing
table in core stores a bare uuid and nothing else about the person, so once
<code>players</code> and <code>player_identities</code> are gone the surviving id resolves to nobody.
Core does not mint a tombstone player row, and neither should you - a tombstone
is a record about a person you were told to erase.</p>
<p>Core's own foreign keys are all <code>no_action</code> and its erasure enumerates its
children explicitly rather than delegating to the database. That is deliberate,
and it is the reason a blanket <code>ON DELETE CASCADE</code> migration is refused rather
than merely discouraged: a database cascade fires below the transaction's
control flow, so <code>erase_player/1</code> would never be called at all and the receipts
would be destroyed silently.</p>
<h3 id="there-is-no-export_player1" tabindex="-1">There is no <code>export_player/1</code></h3>
<p>Core exports a player - <code>GET /api/v1/ops/players/:id/export</code> - and the payload
covers core's tables only. Extensions do not contribute to it, and that is a
decision rather than a gap.</p>
<p><code>erase_player/1</code> earns its keep because the foreign key forces you to answer:
skip it and the player row physically cannot be deleted. An export callback has
no such forcing function, so an extension that skipped it would produce a
silently incomplete export and nothing would fail - a worse contract than no
contract. If one ever ships, core will have to name in the payload which
installed extensions contributed and which did not.</p>
<h2 id="counters" tabindex="-1">Counters</h2>
<p><code>update_all/2</code> SETs literals and kura's <code>on_conflict</code> overwrites, so neither
accumulates. <code>asobi_repo:increment/3</code> is the primitive for the counter every
progress-shaped extension needs:</p>
<pre><code class="language-erlang">{ok, Row} = asobi_repo:increment(
    asobi_quest_progress,
    #{player_id =&gt; PlayerId, quest_id =&gt; QuestId},
    #{counter =&gt; 1}
).
</code></pre>
<p>One statement, roughly
<code>INSERT ... ON CONFLICT (...) DO UPDATE SET &quot;counter&quot; = &quot;quest_progress&quot;.&quot;counter&quot; + EXCLUDED.&quot;counter&quot;</code>,
so two concurrent callers both land and the row is created if it is missing.
The conflict target must be a primary key or covered by a unique index, and a
field cannot be both a key and a counter.</p>
<p>There is no general <code>query/2</code>. Every identifier <code>increment/3</code> interpolates is
a field of the schema you pass and every value is a bound parameter, which is
a promise raw SQL through the seam could not make.</p>
<h2 id="testing" tabindex="-1">Testing</h2>
<p>Core's suites under <code>test/extensions/</code> are the worked examples.</p>
<p>A fixture extension needs no <code>.app</code> file and no separate build.
<code>asobi_fixture_app:install/3</code> hands <code>application:load/1</code> an application spec
directly, with your manifest module in its <code>modules</code> list - exactly what
discovery reads. <code>asobi_fixture_quests_extension</code> declares all of <code>rpc/0</code>,
<code>lua/0</code>, <code>ops/0</code>, <code>codes/0</code> and <code>owns/0</code>; <code>asobi_fixture_minimal_extension</code> is
the <code>info/0</code>-only case; <code>asobi_fixture_clans_extension</code> is a second extension
whose application depends on the first, so start order is observable.</p>
<p>Exercise <code>rpc/0</code> without a socket by calling the dispatcher directly.
<code>asobi_rpc:handle(Cid, Payload, Caller)</code> takes the payload map and a caller of
<code>#{player_id, session}</code> or the atom <code>unauthenticated</code>, and returns
<code>{Cid, Outcome}</code> - no cowboy, no connection. <code>asobi_rpc_tests</code> is the pattern:
reset the registry, install the fixture, <code>asobi_extensions:resolve()</code>,
<code>asobi_readiness:mark_ready()</code>, call, assert. Reset both in teardown, because
the registry and the readiness marker are <code>persistent_term</code>.
<code>asobi_ops_extension:handle/1</code> takes a <code>cowboy_req</code> map, so the ops seam is
tested from a hand-built map carrying <code>bindings</code> and <code>auth_data</code>;
<code>asobi_ops_extension_tests</code> shows the shape.</p>
<p><code>rebar3 asobi check</code> belongs in your host release's CI, not the extension's
own: it validates a whole installed set, and an extension built alone has
nothing to collide with. Run it after <code>compile</code> (the provider already depends
on it) and before anything boots the node.</p>
<h2 id="where-the-logic-goes" tabindex="-1">Where the logic goes</h2>
<pre><code>asobi_quests/
  src/
    asobi_quests.app.src           applications: [kernel, stdlib, asobi]
    asobi_quests_extension.erl     the declarations
    asobi_quests.erl               THE DOMAIN LOGIC - plain Erlang
    asobi_quests_rpc.erl           thin: decode, call domain, encode
    schemas/     asobi_quest.erl, asobi_quest_progress.erl
    migrations/  m20260803174500_create_quests.erl   (generated)
    workers/     asobi_quests_rollover_worker.erl
</code></pre>
<p><code>asobi_quests.erl</code> knows nothing about HTTP, RPC, Lua or the console. Each of
those is a thin adapter over it, which is what makes one implementation
reachable from a client call, a background job and a Lua binding.</p>
<h2 id="not-sandboxed" tabindex="-1">Not sandboxed</h2>
<p>An extension runs in the same node, the same supervision tree and with the same
database credentials as core. <code>asobi_repo</code> is unrestricted, and <code>os:cmd/1</code>,
<code>open_port/2</code> and <code>load_nif/2</code> are all reachable. Its migrations run with full
DDL privilege. Treat installing one as you would treat any dependency with
production credentials.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/protocols/websocket">WebSocket protocol</a> - the frame <code>rpc.call</code> lives in.</li>
<li><a href="https://hexdocs.pm/asobi/console.html">Operator console</a> - turning the ops plane on.</li>
<li><a href="/docs/clustering">Clustering</a> - what is per node and what is not.</li>
<li><a href="https://hexdocs.pm/asobi/lua-api.html">Lua API</a> - the <code>game.*</code> surface your namespace joins.</li>
</ul>
"""}
    ]}.
