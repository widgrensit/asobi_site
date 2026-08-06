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
<p>asobi is one Erlang/OTP node holding the game backend, the Lua runtime and the
operator console. One VM owns the match and world processes, the public ETS
tables and the console session store. Single-node is the default posture and
the assumptions below are written for it; <a href="#what-changes-under-a-cluster">what a cluster
changes</a> is a short list further down.</p>
<h2 id="trusted-and-untrusted" tabindex="-1">Trusted and untrusted</h2>
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
<td>asobi code</td>
<td>trusted</td>
<td>this repo</td>
</tr>
<tr>
<td>Game module in Erlang (<code>Mod:tick/1</code>, <code>Mod:join/2</code>, ...)</td>
<td>trusted</td>
<td>callbacks run inline in the match process. A crash restarts the match (<code>transient</code>, intensity 10 / period 60)</td>
</tr>
<tr>
<td>NIFs</td>
<td>trusted</td>
<td>a misbehaving NIF crashes the BEAM</td>
</tr>
<tr>
<td>Plugins</td>
<td>trusted</td>
<td>plugins see every request and can reach public ETS</td>
</tr>
<tr>
<td>Lua under <code>/app/game</code></td>
<td>sandboxed, author-trusted</td>
<td>mechanics in <a href="/docs/security/lua-sandbox">Sandbox model</a>, boundary in <a href="/docs/security/lua-trust-model">Trust model</a></td>
</tr>
<tr>
<td>HTTP bodies and WebSocket payloads</td>
<td>untrusted</td>
<td>validated in the controllers and <code>asobi_ws_handler</code></td>
</tr>
<tr>
<td>Bearer tokens, provider claims, IAP receipts</td>
<td>untrusted</td>
<td>verified by <code>asobi_auth_plugin</code>, <code>asobi_oauth_controller</code>, <code>asobi_iap</code></td>
</tr>
<tr>
<td>Console bundle at <code>/console</code></td>
<td>unauthenticated by design</td>
<td>the console route group in <code>asobi_router</code> is declared <code>security =&gt; false</code>: an index document, content-hashed assets and the login endpoint. No game data passes through it</td>
</tr>
<tr>
<td>Ops callers on <code>/api/v1/ops/*</code></td>
<td>untrusted until an actor resolves</td>
<td><code>asobi_ops_auth:verify/1</code> resolves an actor or returns 403 with one body for every cause</td>
</tr>
</tbody>
</table>
<p>The ops plane admits three credential sources, all resolving to the same actor
shape: the operator secret presented as a bearer token (<code>static_secret</code>), a
console session cookie plus its <code>x-csrf-token</code> header (<code>local_user</code>), and a
short-lived token minted by asobi_saas (<code>cloud</code>). A player bearer token is
never one of them - <code>asobi_ops_auth</code> does not consult the player auth cache at
all. The mechanism, the environment variables and the credential handling live
in <a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<p>Both surfaces answer on the game port, and they are gated separately. <code>console</code>
gates <code>/console</code> alone. The ops routes are always mounted and the credential is
the only thing standing in front of them, so an <code>ops_secret</code> set for any reason
exposes <code>/api/v1/ops/*</code> whether or not the console is on. Unsetting the secret
is what closes the plane; a stock node has none. Core's ops routes are all
reads, so the blast radius of a leaked secret is disclosure plus whatever
actions an installed extension declares behind
<code>/api/v1/ops/ext/:extension/:action</code>.</p>
<h2 id="erlang-distribution" tabindex="-1">Erlang distribution</h2>
<p><code>config/vm.args.src</code> boots with <code>-name</code> and <code>-setcookie</code>. EPMD listens on
<code>0.0.0.0:4369</code>, the distribution port range is unbounded, and the cookie is the
only protection: anyone who can reach the port with the right cookie has code
execution in the VM.</p>
<p>The published image ships a fixed, publicly known <code>ERLANG_COOKIE=asobi</code>
(<code>Dockerfile</code>). It is set because relx renders an empty value otherwise and
<code>bin/asobi rpc</code> stops working, not because it is a secret. Any deployment that
exposes the distribution port must override it.</p>
<p>For a single node, uncomment the localhost bind in <code>vm.args.src</code>:</p>
<pre><code>-kernel inet_dist_use_interface &quot;{127,0,0,1}&quot;
</code></pre>
<h2 id="what-changes-under-a-cluster" tabindex="-1">What changes under a cluster</h2>
<p>Clustering is opt-in through <code>asobi_cluster</code>. It moves three things in this
model:</p>
<ul>
<li>Distribution stops being optional, so the cookie and the dist port range
become load-bearing. Constrain the range and turn on TLS for distribution:
<code>-kernel inet_dist_listen_min 9100 inet_dist_listen_max 9105</code>,
<code>-proto_dist inet_tls</code>, <code>-ssl_dist_optfile /etc/asobi/ssl_dist.config</code>.</li>
<li>Several bounds in this model are per node, so a cluster of N multiplies them
by N. Rate-limit buckets are the ones with security weight.</li>
<li>Console sessions and their CSRF secret are per node, so the console needs a
sticky route.</li>
</ul>
<p><a href="/docs/clustering">Clustering</a> holds the complete list of what is and is not
shared between nodes.</p>
<h2 id="public-ets-tables" tabindex="-1">Public ETS tables</h2>
<p>These tables are <code>public</code> and hold live game state:</p>
<table>
<thead>
<tr>
<th>Table</th>
<th>Created by</th>
<th>Named</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>asobi_world_state</code></td>
<td><code>asobi_world_sup</code></td>
<td>yes</td>
</tr>
<tr>
<td><code>asobi_player_worlds</code></td>
<td><code>asobi_world_sup</code></td>
<td>yes</td>
</tr>
<tr>
<td><code>asobi_match_state</code></td>
<td><code>asobi_match_sup</code></td>
<td>yes</td>
</tr>
<tr>
<td><code>asobi_chat_registry</code></td>
<td><code>asobi_chat_sup</code></td>
<td>yes</td>
</tr>
<tr>
<td><code>asobi_zone_mgr</code></td>
<td><code>asobi_zone_manager</code></td>
<td>only when a <code>name</code> option is passed, and then under that atom. Otherwise the table is unnamed and reached by reference</td>
</tr>
<tr>
<td><code>asobi_terrain_cache</code></td>
<td><code>asobi_terrain_store</code></td>
<td>no</td>
</tr>
</tbody>
</table>
<p>Anything in the same BEAM - game callbacks in Erlang, plugins, NIFs - can read,
mutate or delete entries. asobi accepts that because all in-VM code is trusted
above. Lua never reaches them: Luerl scripts are not given ETS access, and the
<code>game.*</code> bridge is the only path from a script into host state.</p>
<h2 id="uuidv7-ids-carry-a-timestamp" tabindex="-1">UUIDv7 ids carry a timestamp</h2>
<p><code>asobi_id:generate/0</code> produces UUIDv7 (<code>jhn_uuid</code>), which embeds a millisecond
timestamp in the high 48 bits. Match ids, world ids, ticket ids and <code>player.id</code>
all use it. <code>player.id</code> is the long-lived case: the timestamp inside it reveals
account-creation time. That is acceptable for a game backend, but worth knowing
before you build a feature on top of it.</p>
<p>For an unguessable, non-correlatable id - auth tokens, invite codes - use
<code>crypto:strong_rand_bytes/1</code>, not <code>asobi_id:generate/0</code>.</p>
<h2 id="what-the-supervisors-tolerate" tabindex="-1">What the supervisors tolerate</h2>
<p><code>asobi_match_sup</code> runs each match with <code>restart =&gt; transient</code> under
<code>intensity 10 / period 60</code>. Past 10 crashes in 60 seconds the match supervisor
itself exits and <code>asobi_sup</code> restarts it, taking every live match on the node
with it. That is deliberate: an obviously broken game module should stop, not
churn quietly.</p>
<p><code>asobi_world_lobby_server</code> serialises <code>find_or_create/1</code> through a single
process so two concurrent calls for the same mode cannot both create a world.</p>
<h2 id="related" tabindex="-1">Related</h2>
<ul>
<li><a href="/docs/security/auth">Auth and rate limiting</a> - how clients authenticate and what bounds a single hostile request.</li>
<li><a href="/docs/security/known-limitations">Known limitations</a> - the sharp edges this design accepts.</li>
<li><a href="/docs/security/lua-sandbox">Sandbox model</a> - what the Lua sandbox removes, replaces and bounds.</li>
<li><a href="/docs/security/lua-trust-model">Trust model</a> - what the Lua sandbox is and is not a boundary against.</li>
<li><a href="https://hexdocs.pm/asobi/security-lua-known-limitations.html">Known limitations (Lua)</a> - the sandbox's own sharp edges.</li>
<li><a href="https://hexdocs.pm/asobi/console.html">Operator console</a> - turning the console and ops API on, and the credentials they check.</li>
</ul>
"""}
    ]}.
