%% GENERATED from asobi guides/security-threat-model.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_security_threat_model_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-sec-threat", title => ~"Threat model — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Security / Threat model"
        ]},
        {h1, [], [~"Threat model"]},
        {raw,
            ~"""
<p>asobi is a <strong>single-tenant, single-node</strong> game backend library by
design. The trust assumptions and architectural constraints below
follow from that.</p>
<h2 id="trusted-vs-untrusted-code" tabindex="-1">Trusted vs. untrusted code</h2>
<table>
<thead>
<tr>
<th>Component</th>
<th>Status</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td>asobi library code</td>
<td>trusted</td>
<td>this repo</td>
</tr>
<tr>
<td>Loaded game module (<code>Mod:tick/1</code>, <code>Mod:join/2</code>, …)</td>
<td><strong>trusted</strong></td>
<td>callbacks run inline in the match gen_server. A crash in a callback restarts the match (transient + intensity 10) and can take the lobby down.</td>
</tr>
<tr>
<td>Loaded NIFs</td>
<td>trusted</td>
<td>NIFs run in-VM; a misbehaving NIF crashes the BEAM.</td>
</tr>
<tr>
<td>Loaded plugins</td>
<td>trusted</td>
<td>plugins observe / mutate every request and have full access to public ETS.</td>
</tr>
<tr>
<td>Lua scripts (via <code>asobi_lua</code> runtime)</td>
<td>sandboxed</td>
<td>see <code>asobi_lua</code> SECURITY.md. The Lua sandbox sits <em>on top</em> of the asobi-side trust boundary; it is the place where untrusted-script hardening belongs.</td>
</tr>
<tr>
<td>HTTP request bodies / WS payloads</td>
<td>untrusted</td>
<td>input validation lives in controllers / <code>asobi_ws_handler</code>.</td>
</tr>
<tr>
<td>Bearer tokens, OAuth claims, IAP receipts</td>
<td>untrusted</td>
<td>verified via <code>asobi_auth_plugin</code>, <code>asobi_oauth_controller</code>, <code>asobi_iap</code>.</td>
</tr>
</tbody>
</table>
<h2 id="single-node-beam-distribution" tabindex="-1">Single-node BEAM distribution</h2>
<p><code>config/vm.args.src</code> boots with <code>-name</code> and <code>-setcookie</code>. EPMD binds to
<code>0.0.0.0:4369</code> and the dist port range is unbounded. The cookie is the
only protection.</p>
<p>For single-node deploys (the default), uncomment the localhost-bind
line in <code>vm.args.src</code>:</p>
<pre><code>-kernel inet_dist_use_interface &quot;{127,0,0,1}&quot;
</code></pre>
<p>For clustered deploys via <code>asobi_cluster.erl</code> (k8s DNS discovery),
constrain the dist port range and enable TLS for distribution:</p>
<pre><code>-kernel inet_dist_listen_min 9100 inet_dist_listen_max 9105
-proto_dist inet_tls
-ssl_dist_optfile /etc/asobi/ssl_dist.config
</code></pre>
<h2 id="public-ets-tables" tabindex="-1">Public ETS tables</h2>
<p>These named ETS tables are <code>public</code> and hold live game state:</p>
<ul>
<li><code>asobi_world_state</code> (<code>asobi_world_sup</code>)</li>
<li><code>asobi_player_worlds</code> (<code>asobi_world_sup</code>)</li>
<li><code>asobi_match_state</code> (<code>asobi_match_sup</code>)</li>
<li><code>asobi_chat_registry</code> (<code>asobi_chat_channel</code>)</li>
<li><code>asobi_zone_mgr</code> (<code>asobi_zone_manager</code>)</li>
</ul>
<p>Anything in the same BEAM (game callbacks, plugins) can read, mutate,
or delete entries. asobi treats this as acceptable because all in-VM
code is trusted (above). Any sandboxed runtime layered on top
(<code>asobi_lua</code>) MUST keep its sandbox out of these tables — Luerl is
not given access to ETS.</p>
<h2 id="uuidv7-and-timestamp-leakage" tabindex="-1">UUIDv7 and timestamp leakage</h2>
<p><code>asobi_id:generate/0</code> produces UUIDv7 ids that embed a millisecond
timestamp in the high 48 bits. Match ids, world ids, ticket ids, and
<code>player.id</code> all use this generator. <code>player.id</code> is the long-lived
case: the timestamp inside it reveals account-creation time, which is
acceptable for a game backend but worth knowing if you build features
on top.</p>
<p>If you ever need an unguessable, non-correlatable id (auth tokens,
invite codes, etc.) generate them via <code>crypto:strong_rand_bytes/1</code>
rather than <code>asobi_id:generate/0</code>.</p>
<h2 id="what-the-supervisor-will-tolerate" tabindex="-1">What the supervisor will tolerate</h2>
<p><code>asobi_match_sup</code> runs each match gen_server with <code>transient</code> restart
and <code>intensity 10 / period 60</code>. After 10 crashes in 60s the entire
match supervisor falls over, intentionally taking the lobby with it so
an obviously broken game module cannot keep churning silently.</p>
<p><code>asobi_world_lobby_server</code> serializes <code>find_or_create/1</code> to close a
documented TOCTOU race (two concurrent <code>find_or_create</code> for the same
mode no longer spawn duplicate worlds).</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/security/auth">Auth &amp; rate limiting</a> - how clients are authenticated and the brute-force surface is bounded.</li>
<li><a href="/docs/security/known-limitations">Known limitations</a> - the sharp edges this design accepts.</li>
</ul>
"""}
    ]}.
