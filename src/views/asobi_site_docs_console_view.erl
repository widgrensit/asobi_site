%% GENERATED from asobi guides/console.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_console_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-console", title => ~"Operator console — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Operator console"
        ]},
        {h1, [], [~"Operator console and the ops API"]},
        {raw,
            ~"""
<p>asobi serves an operator console at <code>/console</code> and a game-operations HTTP API
at <code>/api/v1/ops/*</code>. One node, one listener: both answer on the same port the
game does - <code>8084</code> in the image - and ship in the same release.</p>
<p>Neither is on by default, and they are gated separately.</p>
<p><code>/console</code> is served only when <code>console</code> is true. Every console route answers
404 otherwise.</p>
<p><code>/api/v1/ops/*</code> is always mounted and admits nobody until an ops secret is
configured, so on a stock deployment every request to it answers 403. Turning
the console off does not close the ops plane; unsetting the secret does. (A
managed environment has a second credential - see
<a href="/docs/configuration#minted-tokens-managed-environments">Minted tokens</a> - which
needs <code>ops_token_secret</code> and <code>env_id</code>, neither set by default.)</p>
<p>The two look coupled because enabling the console with neither credential
configured turns the console back off, below.</p>
<p>This plane is reads plus account lifecycle - erasing and exporting one player.
If you came here for moderation actions, skip to
<a href="#what-it-cannot-do">What it cannot do</a> first.</p>
<h2 id="turning-it-on" tabindex="-1">Turning it on</h2>
<p>Two settings. The console flag, and a credential for it to check.</p>
<p>In the image, both come from the environment:</p>
<table>
<thead>
<tr>
<th>Variable</th>
<th>Sets</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>ASOBI_CONSOLE</code></td>
<td>Serve <code>/console</code>. <code>1</code>, <code>true</code>, <code>yes</code> or <code>on</code> enable it; anything else, including a typo, leaves it off</td>
</tr>
<tr>
<td><code>ASOBI_OPS_SECRET_FILE</code></td>
<td>The ops secret, read from a file. Preferred</td>
</tr>
<tr>
<td><code>ASOBI_OPS_SECRET</code></td>
<td>The ops secret, read from the variable itself</td>
</tr>
<tr>
<td><code>ASOBI_CONSOLE_LABEL</code></td>
<td>Names this deployment in the tab title and the console header</td>
</tr>
<tr>
<td><code>ASOBI_CONSOLE_PRODUCTION</code></td>
<td>Marks a deployment to be careful in. The console colours its label</td>
</tr>
</tbody>
</table>
<p>A file beats the variable, and it never falls back to it. A named file that is
missing, unreadable or empty logs <code>ops_secret_file_unreadable</code> or
<code>ops_secret_file_empty</code> and leaves the secret unset - a deployment that mounted
a secret and got the path wrong must not come up quietly using something else.
A trailing newline is stripped, so <code>openssl rand -hex 32 &gt; ops_secret.txt</code>
works as written.</p>
<p>Enabling the console with nothing that can sign in leaves the console <strong>off</strong>,
logs <code>console_disabled_without_credential</code> at error level, and starts the node
anyway. The game is the product; a misconfigured operator surface must not take
players offline. On success the node logs <code>console_enabled</code>.</p>
<p>&quot;Nothing that can sign in&quot; means neither credential. A managed environment
configures no <code>ops_secret</code> on purpose and passes this check on
<code>ops_token_secret</code> + <code>env_id</code> instead - see <a href="https://hexdocs.pm/asobi/cloud.html#the-console">Cloud</a>.</p>
<p>The compose fragment, matching the production compose in
<a href="https://hexdocs.pm/asobi/self-hosting.html">Self-hosting</a>:</p>
<pre><code class="language-yaml">services:
  asobi:
    image: ghcr.io/widgrensit/asobi:latest
    environment:
      ASOBI_CONSOLE: &quot;true&quot;
      ASOBI_OPS_SECRET_FILE: /run/secrets/ops_secret
      ASOBI_CONSOLE_LABEL: prod
      ASOBI_CONSOLE_PRODUCTION: &quot;true&quot;
    secrets: [ops_secret]

secrets:
  ops_secret:
    file: ./ops_secret.txt
</code></pre>
<p>The container runs as the unprivileged user <code>asobi</code>, so whatever mounts the
secret has to leave it readable by that user. A file mode that only the owner
can read, mounted with a different owner, produces
<code>ops_secret_file_unreadable</code> and a console that stays off.</p>
<p>Not using the image? The same two settings in a <code>sys.config</code>:</p>
<pre><code class="language-erlang">{asobi, [
    {console, true},
    {ops_secret, ~&quot;a-32-byte-or-longer-random-secret&quot;}
]}
</code></pre>
<p>An OS variable overrides <code>sys.config</code> only when it is set, so the two forms
coexist. <a href="/docs/configuration#operator-console">Configuration</a> has the full key
table, including the three keys that have no environment variable.</p>
<h2 id="signing-in" tabindex="-1">Signing in</h2>
<p>Browsing to <code>/console</code> on a node that has it enabled gives a sign-in screen
with two fields: <strong>Operator secret</strong>, which is the <code>ops_secret</code> value, and an
optional name that defaults to <code>operator</code> and becomes the label on the session.
The page posts the secret once and does not keep it.</p>
<p>Underneath, <code>POST /console/session</code> exchanges a credential for a session. Two
are accepted:</p>
<pre><code class="language-json">{&quot;secret&quot;: &quot;...&quot;, &quot;label&quot;: &quot;your name&quot;}
</code></pre>
<p>for the operator secret, and</p>
<pre><code class="language-json">{&quot;token&quot;: &quot;...&quot;}
</code></pre>
<p>for a short-lived token minted by a control plane. The managed path also
accepts the token as a form POST, and answers that with a redirect to
<code>/console</code> - which is how a dashboard hands a browser over without the token
ever entering a URL, a referrer or an access log.</p>
<p>Either way the response sets two cookies: an <code>HttpOnly</code> session cookie the page
cannot read, and a script-readable CSRF cookie it can. Every later ops read
needs <strong>both</strong> the session cookie and the value of the CSRF cookie sent back as
an <code>x-csrf-token</code> header. A cookie on its own is not a credential here, which
is what makes a cross-site request that arrives with the browser's cookies
attached answer 403 rather than data.</p>
<p><code>GET /console/session</code> reports the current actor - display name, source,
capability classes, and whether the identity behind it is attested. <code>DELETE /console/session</code> ends the session and clears both cookies; logging out twice
is not an error.</p>
<p>Sessions last 12 hours by default. <code>console_session_ttl</code> changes that and is
clamped to 60-86400 seconds. Expiry is absolute: reading does not extend it.</p>
<p>The session store and the secret the CSRF token is derived from are per node
and per boot. Restarting a node signs everyone out of it, and that is the
correct coupling rather than a gap - it is also the only revocation a session
has apart from logging out.</p>
<h2 id="what-the-console-shows" tabindex="-1">What the console shows</h2>
<p>Nine screens, all of them reads:</p>
<ul>
<li><strong>Overview</strong> - online players, node version, queue depth, installed
extensions, and the runtime panel from <code>/api/v1/ops/stats</code>, polled every two
seconds.</li>
<li><strong>Players</strong> - the player list, searchable across username and display name.</li>
<li><strong>Matches</strong> - the recorded match history, with the game-authored result on
the detail page. Core writes one row per match when it finishes, so every row
reads <code>finished</code> whatever the status filter offers.</li>
<li><strong>Matchmaker</strong> - one row per mode, deepest queue first, refreshed every three
seconds.</li>
<li><strong>Leaderboards</strong> - boards rather than scores, then one board's persisted
entries.</li>
<li><strong>Economy</strong> - the item catalogue and the store listings, side by side.</li>
<li><strong>Chat</strong> - the channels running on this node, then one channel's persisted
history, searchable by message content.</li>
<li><strong>Tournaments</strong> - the tournament rows, with a <code>live</code> column that says whether
a process is actually behind an <code>active</code> row.</li>
<li><strong>Notifications</strong> - the send history, filterable by read state.</li>
</ul>
<p>What a reader arriving from another console will look for and not find:</p>
<ul>
<li>No worlds screen, no votes screen, no IAP screen.</li>
<li>No wallets and no inventory. Both exist in the product; neither is on this
plane.</li>
<li>The players screen shows the ops projection only: <code>id</code>, <code>username</code>,
<code>display_name</code>, <code>avatar_url</code>, <code>metadata</code>, <code>inserted_at</code>, <code>updated_at</code>. No
linked providers, no guest status, no device verifiers.</li>
<li>The matches screen is the <strong>finished-match record</strong>. Live matches are visible
only through the player-facing <code>GET /api/v1/matches/live</code>.</li>
</ul>
<h2 id="what-it-cannot-do" tabindex="-1">What it cannot do</h2>
<p>Core's ops routes are reads apart from two account-lifecycle routes:</p>
<pre><code>GET  /api/v1/ops/players/:id/export     Everything held about one player
POST /api/v1/ops/players/:id/erase      Delete one player. Irreversible.
</code></pre>
<p>Both are covered in
<a href="/docs/protocols/rest#erasing-and-exporting-a-player">Erasing and exporting a player</a>.
They exist because an operator must be able to answer a deletion or access
request without a database shell, and because an Apache-2 self-hoster
otherwise inherits an obligation the library gives them no way to discharge.</p>
<p>Everything else is still absent: no ban, no grant, no refund, no broadcast, no
ticket cancel and no match end. If you arrived expecting Nakama Console,
PlayFab Game Manager or the Hathora console, that expectation gap is real and
this is where it is.</p>
<p>The third mutating route takes its method, its handler and its capability class
from an installed extension's manifest. The console cannot invoke it today;
that surface is HTTP only. See <a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a> for how an extension
declares one.</p>
<h2 id="capability-classes" tabindex="-1">Capability classes</h2>
<p>Four: <code>read</code>, <code>player_data</code>, <code>config</code> and <code>erasure</code>. Every route on the plane
carries exactly one, and membership of that class in the caller's capabilities
is the only authorisation decision anywhere in the plane. A route with no class
is denied, so an untagged or mis-mounted route is closed rather than open.</p>
<p>Core tags <code>read</code> on every route but two: the player export is <code>player_data</code>,
because it returns everything about one identified person rather than a list
view, and the player erasure is <code>erasure</code>. <code>config</code> exists for extension
actions and for the classes a minted token can carry.</p>
<p><code>erasure</code> is a class of its own for one reason, and it is not sensitivity:
it is the only one whose actions cannot be undone by a later call. A ban can
be lifted and a grant can be clawed back; an erased account is gone.</p>
<p>What proves what:</p>
<ul>
<li>The <strong>operator secret</strong> proves all four over a bearer header. One secret is
one privilege level: whoever holds it holds <code>config</code>.</li>
<li>A <strong>minted token</strong> proves only the classes it carries, and its lifetime is
capped at 900 seconds by the node that verifies it, not by whatever minted it.</li>
<li>A <strong>console session</strong> inherits its credential's classes and expires no later
than that credential does. A fifteen-minute token cannot buy a twelve-hour
session with wider capabilities.</li>
<li>A console session opened with the <strong>operator secret</strong> gets every class
<strong>except</strong> <code>erasure</code>. The secret proves it; the transport is what differs.
A bearer secret in a config file is a script an operator wrote; a session
cookie is a browser that can be XSS'd or clickjacked into posting once. Set
<code>console_erasure</code> to <code>true</code> to allow it anyway.</li>
</ul>
<p>Every rejection is <code>403</code> carrying the shared error object, whatever the cause:</p>
<pre><code class="language-json">{&quot;error&quot;: {&quot;code&quot;: &quot;forbidden&quot;, &quot;message&quot;: &quot;The caller may not perform this action.&quot;, &quot;details&quot;: {}}}
</code></pre>
<p>Nothing configured, wrong secret and wrong capability class are deliberately
indistinguishable to a caller guessing. Player bearer tokens never reach this
plane at all - it never consults the player token store.</p>
<h2 id="calling-the-ops-api-directly" tabindex="-1">Calling the ops API directly</h2>
<p>The same routes answer a bearer token, which is what CI, a CLI or a script
uses:</p>
<pre><code class="language-bash">curl -sS -H &quot;Authorization: Bearer $ASOBI_OPS_SECRET&quot; \
  &quot;https://game.example.com/api/v1/ops/players?limit=20&amp;sort=inserted_at&amp;order=desc&quot;
</code></pre>
<p><a href="/docs/protocols/rest#ops">REST API</a> has the per-route reference: the shared list
parameters, the sortable fields per endpoint, and the lookup shapes.
<a href="/docs/protocols/rest#ops-authentication">Ops authentication</a> covers <code>x-asobi-operator</code>,
the attribution label a shared secret cannot supply on its own.</p>
<p>One route belongs here rather than there, because it is the one an operator
reaches for first:</p>
<pre><code class="language-bash">curl -sS -H &quot;Authorization: Bearer $ASOBI_OPS_SECRET&quot; \
  https://game.example.com/api/v1/ops/stats
</code></pre>
<pre><code class="language-json">{
  &quot;data&quot;: {
    &quot;node&quot;: &quot;asobi@10.0.0.4&quot;,
    &quot;online_players&quot;: 412,
    &quot;process_count&quot;: 5183,
    &quot;process_limit&quot;: 1048576,
    &quot;run_queue&quot;: 0,
    &quot;scheduler_count&quot;: 8,
    &quot;memory_total&quot;: 184549376,
    &quot;memory_processes&quot;: 92274688,
    &quot;memory_ets&quot;: 12582912,
    &quot;memory_binary&quot;: 25165824,
    &quot;uptime_ms&quot;: 864000000
  }
}
</code></pre>
<p>It touches no database, so it still answers when Postgres is the thing that is
unwell - which is when you are most likely to be asking. <code>online_players</code> is
<code>null</code> rather than an error if presence is briefly unavailable; every other
field is a VM read that cannot fail.</p>
<h2 id="behind-more-than-one-node" tabindex="-1">Behind more than one node</h2>
<p>The session store and the CSRF secret are per node, so behind a round-robin
proxy roughly <code>(N-1)/N</code> of console requests answer 403 and drop the operator
back to the sign-in screen. Give <code>/console</code> and <code>/api/v1/ops</code> a sticky route,
or point the console at one node directly.</p>
<p>Every node needs the <strong>same</strong> ops secret. If they differ, which node answers
decides whether signing in works at all.</p>
<p><code>/api/v1/ops/features</code>, <code>/matchmaker</code> and <code>/chat/channels</code> read node-local
state; everything else on the plane reads Postgres and is cluster-consistent. A
chat channel running on another node is simply absent from the list, though the
member count beside a channel that is present is fleet-wide.
<code>/stats</code> reports <code>node</code> for exactly this reason - the numbers are that node's,
apart from <code>online_players</code>, which is fleet-wide because presence is a
cluster-wide process group. Summing it across nodes multiplies your concurrency
figure by <code>N</code>.</p>
<p><a href="/docs/clustering">Clustering</a> holds the complete list of what is per node.</p>
<h2 id="production-notes" tabindex="-1">Production notes</h2>
<p>The console shares the game port. Anyone who can reach your game can reach
<code>/console</code>, so put it behind TLS and restrict who reaches it - allowlist at the
proxy, or require another layer in front of <code>/console</code> and <code>/api/v1/ops</code>.</p>
<p><code>Secure</code> is set on both cookies when the request is HTTPS or arrives with
<code>x-forwarded-proto: https</code>. Behind a terminator that sends neither, set
<code>console_secure_cookie</code>. They are <code>SameSite=Lax</code> rather than <code>Strict</code>, because
the managed hand-off arrives as a cross-site POST and a <code>Strict</code> cookie would
not be sent on the redirect that follows it. <code>Lax</code> still refuses to send them
on a cross-site POST or an XHR, and the <code>x-csrf-token</code> header is the defence
doing the work.</p>
<p><code>console_secure_cookie</code>, <code>console_api_base</code> and <code>console_session_ttl</code> have no
environment variable and need a <code>sys.config</code>.</p>
<p><code>POST /console/session</code> shares the 5/s auth rate limiter, which is the bucket
that resists credential guessing. <code>/api/v1/ops/*</code> falls through to the 300/s
API limiter. Both are counted per node.</p>
<h2 id="troubleshooting" tabindex="-1">Troubleshooting</h2>
<p><strong><code>/console</code> returns 404.</strong> The console is not enabled on the node that
answered. Every console route answers the same 404 an unknown asset gets, so a
deployment with the console switched off is indistinguishable from one that has
it on and was asked for a file that does not exist.</p>
<p><strong><code>/console</code> returns 503.</strong> The console bundle is missing from the release.
This is a build problem, not a configuration one.</p>
<p><strong>The node is up but the console is off.</strong> Grep the boot log for
<code>console_disabled_without_credential</code>, <code>ops_secret_file_unreadable</code> and
<code>ops_secret_file_empty</code>. The line that says it worked is <code>console_enabled</code>.</p>
<p><strong>Every ops call answers 403.</strong> One of three things: no secret is configured,
the presented secret is wrong, or the credential does not carry the class the
route needs. The body is identical in all three cases, deliberately. Check the
node log for <code>ops request rejected: no ops_secret configured</code>, which is emitted
for the first case only.</p>
<p><strong>Sign-in works, then everything 403s a moment later.</strong> A round-robin proxy in
front of more than one node. Make the route sticky.</p>
<h2 id="next" tabindex="-1">Next</h2>
<ul>
<li><a href="/docs/protocols/rest#ops">REST API</a> - the per-route ops reference.</li>
<li><a href="/docs/configuration#operator-console">Configuration</a> - every console key.</li>
<li><a href="https://hexdocs.pm/asobi/self-hosting.html">Self-hosting</a> - the production compose this fits into.</li>
<li><a href="https://hexdocs.pm/asobi/cloud.html#the-console">Cloud</a> - how a managed environment reaches this
without an operator secret.</li>
<li><a href="/docs/clustering">Clustering</a> - what is per node.</li>
<li><a href="https://hexdocs.pm/asobi/extensions.html">Extensions</a> - declaring an operator action.</li>
</ul>
"""}
    ]}.
