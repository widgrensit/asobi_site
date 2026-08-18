%% GENERATED from asobi guides/security-auth.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_security_auth_view).

-export([mount/1, render/1, markdown/0]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-auth", title => ~"Auth & rate limiting — Asobi docs"}, Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Security / Authentication & rate limiting"
        ]},
        {h1, [], [~"Authentication and rate limiting"]},
        {raw,
            ~"""
<p>How asobi authenticates clients, validates purchases, and bounds what a single
hostile request or a single hostile caller can cost. For the trust assumptions
underneath, see <a href="/docs/security/threat-model">Threat model</a>.</p>
<h2 id="session-bearer-tokens" tabindex="-1">Session bearer tokens</h2>
<p>Every authenticated route is gated by <code>asobi_auth_plugin:verify/1</code>, which
expects an <code>Authorization: Bearer &lt;token&gt;</code> header. Tokens are issued by
<code>nova_auth_refresh:generate_pair/2</code> through <code>asobi_auth_tokens:issue/2,3</code> after
a successful register, login, refresh or provider flow. The caller receives
<code>player_id</code>, <code>access_token</code>, <code>refresh_token</code> and <code>username</code>; the refresh token
is single-use and rotates. The plugin attaches <code>auth_data =&gt; #{player_id =&gt; Id, ...}</code> to the request map, so controllers pattern-match on that rather than
parsing the header again.</p>
<p>On logout the presented access token is revoked through
<code>asobi_auth_tokens:revoke_access/1</code>, so it cannot outlive the cache TTL.</p>
<h2 id="apple-storekit-2-jws-verification" tabindex="-1">Apple StoreKit 2 JWS verification</h2>
<p><code>asobi_iap:verify_apple/1</code> parses an Apple-signed JWS receipt and verifies it
end to end:</p>
<ol>
<li>The header <code>alg</code> must be <code>ES256</code>. Every other algorithm is rejected.</li>
<li>The <code>x5c</code> chain is decoded (DER certificates, base64 in JWS order: leaf,
intermediate, root).</li>
<li>The chain is validated against a configured Apple root CA with
<code>public_key:pkix_path_validation/3</code>. The root is not bundled: set
<code>apple_root_cert_path</code> or <code>apple_root_certs</code>, or verification returns
<code>apple_root_cert_not_configured</code>.</li>
<li>The signature over <code>&lt;header&gt;.&lt;payload&gt;</code> is verified with the leaf
certificate's public key. Only then is the payload returned, and a bundle id
that is not the configured one fails with <code>bundle_id_mismatch</code>. Expiry is
reported as a <code>valid</code> flag on the result rather than rejected.</li>
</ol>
<p>Failures return <code>{error, Reason}</code> with a sanitised reason binary.
<code>asobi_iap_controller</code> returns them as
<code>{&quot;error&quot;: {&quot;code&quot;: &quot;iap.verification_failed&quot;, &quot;message&quot;: ..., &quot;details&quot;: {&quot;reason&quot;: ...}}}</code> without leaking JWS internals.</p>
<p>There is no Lua path to IAP verification. It is an Erlang-side call on the
purchase route.</p>
<h2 id="steam-ticket-validation" tabindex="-1">Steam ticket validation</h2>
<p><code>asobi_steam:validate_ticket/1</code> validates a hex-encoded session ticket against
the Steam Web API:</p>
<ol>
<li>The ticket must be <code>[0-9a-fA-F]+</code> and at most 4096 bytes. Anything else is
rejected before any HTTP call.</li>
<li>Every dynamic URL component (key, app id, ticket, steam id) goes through
<code>uri_string:quote/1</code>, so an <code>&amp;</code> or <code>=</code> in client input cannot inject a query
parameter into the Steam call.</li>
</ol>
<p>It is invoked from <code>asobi_oauth_controller</code> for <code>provider = &quot;steam&quot;</code>.</p>
<h2 id="guest-device-verifiers" tabindex="-1">Guest device verifiers</h2>
<p>Guest auth (<code>asobi_guest_controller</code>) lets a device create a player from a
<code>{device_id, device_secret}</code> pair with no credentials. It is built to leak
nothing useful even if the identity table is dumped.</p>
<ul>
<li>Fails closed. Guest routes serve only when <code>guest_auth</code> is true and a
<code>guest_verifier_pepper</code> is configured. Otherwise every guest endpoint returns
<code>guest.disabled</code> (403) and the misconfiguration is logged as
<code>guest_auth_misconfigured</code>.</li>
<li>The device secret is never stored. The row holds a verifier: a 16-byte random
salt plus <code>crypto:mac(hmac, sha256, Pepper, &lt;&lt;Salt/binary, Secret/binary&gt;&gt;)</code>,
kept in the identity's <code>provider_metadata</code> as <code>salt</code>, <code>key_id</code>, <code>verifier</code>
and <code>revoked</code>, with the salt and the verifier base64-encoded.</li>
<li>Resume compares with <code>crypto:hash_equals/2</code>, so a wrong secret is not
recoverable by timing.</li>
<li>The pepper lives outside the database, selected by key id. A dumped verifier
table is useless without it, and it rotates: add a key id, point
<code>guest_verifier_key_id</code> at it, keep the old ids for the retention window.
A pepper under 32 bytes is treated as absent, so a truncated value fails
closed rather than weakening the MAC.</li>
<li>Bounded input. The secret must base64-decode to between 32 and 128 bytes and
<code>device_id</code> is capped at 255 bytes, so an unauthenticated caller cannot force
multi-megabyte HMAC work.</li>
<li>Upgrade is compromise recovery. Claiming a guest calls
<code>nova_auth_refresh:revoke_all/2</code> to kill the token family a stolen device
secret may have minted, then deletes the guest identity so that secret can no
longer resume the claimed account.</li>
<li>Reaping is safe. The optional <code>asobi_guest_reaper</code> (off unless
<code>guest_reap_after</code> is set) re-checks that a guest is still unclaimed inside
its delete transaction, so a concurrent upgrade wins the race. It targets
guests that have not resumed for the configured window, not guests whose
accounts are simply old - a device that keeps playing is never reaped. It
deletes
through <code>asobi_player_erase</code>, the same code an operator-initiated erasure
runs, so a reaped guest leaves nothing behind and its cached access token
stops resolving immediately rather than at the next cache expiry.</li>
</ul>
<p>Treat guest accounts as low assurance until they are upgraded. Anything
valuable - purchases, competitive ranking, cross-device identity - should
require a claimed account.</p>
<h2 id="registration-mode" tabindex="-1">Registration mode</h2>
<p>Registration is open by default and that is deliberate (ADR 0002): one asobi
deployment serves one game, the endpoint URL is the game identity, and a
downloadable client cannot prove it is your client. <code>registration</code> bounds
anonymous signup as a deployment decision:</p>
<pre><code class="language-erlang">{registration, open}         %% default
%% {registration, oauth_only}
%% {registration, closed}
</code></pre>
<table>
<thead>
<tr>
<th>Mode</th>
<th>Password register</th>
<th>Provider first-time</th>
<th>Guest first-time</th>
<th>Existing players</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>open</code> (default)</td>
<td>allowed</td>
<td>allowed</td>
<td>allowed if <code>guest_auth</code></td>
<td>allowed</td>
</tr>
<tr>
<td><code>oauth_only</code></td>
<td>denied, <code>auth.password_registration_disabled</code></td>
<td>allowed</td>
<td>governed by <code>guest_auth</code></td>
<td>allowed</td>
</tr>
<tr>
<td><code>closed</code></td>
<td>denied, <code>auth.registration_closed</code></td>
<td>denied, <code>auth.registration_closed</code></td>
<td>denied, <code>auth.registration_closed</code></td>
<td>login, refresh and resume all still work</td>
</tr>
</tbody>
</table>
<p>A game bundle can also declare <code>script_registration</code>; the operator's
<code>registration</code> key wins wherever it is set, so a bundle can choose a posture
for a deployment that states none but can never widen one that does
(<code>asobi_registration</code>). An unrecognised value falls back to <code>open</code>, and
<code>log_mode/0</code> reports <code>invalid_registration_mode</code> at error level at boot.</p>
<p>The shipped <code>examples/</code> quickstarts and <code>asobi_register_bench</code> register
headless with a username and password, so leave <code>open</code> alone in dev and CI.
Choosing a stricter posture is a production decision. asobi logs the active
mode at boot as <code>event =&gt; registration_mode</code>.</p>
<h2 id="rate-limits" tabindex="-1">Rate limits</h2>
<p><code>asobi_rate_limit_plugin</code> runs as a <code>pre_request</code> plugin in
<code>config/{dev,prod}_sys.config.src</code> and picks a Seki limiter group from the
request path. Other limiters are checked at their own call sites. Every group
is registered by <code>register_limiters</code> in <code>asobi_sup</code>, and every bucket is
<strong>per node</strong>: in a cluster of N nodes an attacker gets N times the budget.</p>
<table>
<thead>
<tr>
<th>Group</th>
<th>Limiter</th>
<th>Keyed on</th>
<th>Default</th>
<th>Where</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>register</code></td>
<td><code>asobi_register_limiter</code></td>
<td>IP, or player id if the request carries a Bearer token</td>
<td>3 / sec</td>
<td><code>/api/v1/auth/register</code></td>
</tr>
<tr>
<td><code>auth</code></td>
<td><code>asobi_auth_limiter</code></td>
<td>same</td>
<td>5 / sec</td>
<td>the rest of <code>/api/v1/auth/*</code>, and <code>POST /console/session</code></td>
</tr>
<tr>
<td><code>iap</code></td>
<td><code>asobi_iap_limiter</code></td>
<td>same</td>
<td>10 / sec</td>
<td><code>/api/v1/iap/*</code></td>
</tr>
<tr>
<td><code>api</code></td>
<td><code>asobi_api_limiter</code></td>
<td>same</td>
<td>300 / sec</td>
<td>every other HTTP route</td>
</tr>
<tr>
<td><code>ws_connect</code></td>
<td><code>asobi_ws_connect_limiter</code></td>
<td>IP</td>
<td>60 / sec</td>
<td>the WebSocket upgrade, spent before the Origin check</td>
</tr>
<tr>
<td><code>join</code></td>
<td><code>asobi_join_limiter</code></td>
<td>player id</td>
<td>10 / 60 sec</td>
<td>the <code>match.join</code> and <code>world.join</code> WebSocket frames</td>
</tr>
<tr>
<td><code>guest_global</code></td>
<td><code>asobi_guest_global_limiter</code></td>
<td>one constant key</td>
<td>100 / sec</td>
<td>guest creation, node-wide</td>
</tr>
<tr>
<td><code>rehome</code></td>
<td><code>asobi_rehome_limiter</code></td>
<td>player id</td>
<td>5 / sec</td>
<td>world zone crossings</td>
</tr>
<tr>
<td><code>rehome_global</code></td>
<td><code>asobi_rehome_global_limiter</code></td>
<td>one constant key</td>
<td>200 / sec</td>
<td>world zone crossings, node-wide</td>
</tr>
<tr>
<td><code>script_log</code></td>
<td><code>asobi_script_log_limiter</code></td>
<td>the call site's own key</td>
<td>3 / 10 sec</td>
<td>repeated warning lines from a failing script or dropped input</td>
</tr>
</tbody>
</table>
<p><code>rate_limit_key/1</code> buckets an authenticated caller on <code>player_id</code> and everyone
else on the peer IP, so one abusive player throttles themselves rather than
everyone behind their NAT. Anything that is not a <code>Bearer</code> scheme, or that
reaches the plugin without <code>auth_data</code>, falls back to the IP bucket.</p>
<p>The two global buckets exist because a per-IP or per-player limit does not
bound the aggregate: guest rows are minted unauthenticated, and every zone
crossing calls into the one <code>asobi_terrain_store</code> the whole world shares, so N
attackers each within their own budget still scale the load linearly.</p>
<p><code>/api/v1/auth/register</code> gets the tighter bucket because it runs the password
KDF (pbkdf2_sha256, see <code>pbkdf2_iterations</code>) as its only cost gate. Sharing
login's bucket let a signup flood both starve honest logins and amplify CPU.
The auth bucket plus that same KDF on
<code>nova_auth_accounts:authenticate/3</code> is the brute-force gate for login, and it
is why <code>POST /console/session</code> shares it: same threat, same shape, one fewer
knob to leave unset. Neither route carries a session, so in practice both are
bucketed on the caller's IP, and distributed abuse is the client gate's
problem rather than the limiter's.</p>
<p>Override any group in your sys config:</p>
<pre><code class="language-erlang">{rate_limits, #{
    auth     =&gt; #{limit =&gt; 10, window =&gt; 1000},
    register =&gt; #{limit =&gt; 5,  window =&gt; 1000},
    iap      =&gt; #{limit =&gt; 20, window =&gt; 1000},
    api      =&gt; #{limit =&gt; 600, window =&gt; 1000}
}}
</code></pre>
<p>The dev and test config raises <code>auth</code>, <code>register</code>, <code>iap</code> and <code>api</code> to 1000
because CT fires bursts at <code>127.0.0.1</code> and the production auth cap would fail
the suites.</p>
<p>The Lua runtime registers two more groups of its own, <code>log</code> and <code>log_global</code>,
which bound <code>game.log</code> volume rather than abuse. They read the same
<code>rate_limits</code> key and their names are disjoint from the ones above, so one
merged map carries both.</p>
<h2 id="client-gate-pre-auth" tabindex="-1">Client gate (pre-auth)</h2>
<p><code>asobi_client_gate</code> is a pluggable &quot;is this traffic allowed in&quot; seam on the
three anonymous auth-create routes: <code>/api/v1/auth/register</code>,
<code>/api/v1/auth/oauth</code> and <code>/api/v1/auth/guest</code>. It is distinct from
<code>asobi_auth_plugin</code>, which answers &quot;who is the player&quot;: a gate carries no
player identity, and its return type is deliberately narrow so an
implementation cannot leak or forge one.</p>
<pre><code class="language-erlang">-callback verify(asobi_client_gate:context()) -&gt; skip | {deny, Reason :: binary()}.
</code></pre>
<p>The input is a minimised context, not the raw request: <code>#{ip, headers, path, token}</code>. The request map still holds the registration plaintext password at
that point, and a traffic gate has no use for it, so a verbose or buggy
third-party gate cannot log or forward credentials.</p>
<p>Wire an implementation with <code>{client_gate, my_gate_module}</code> in app env. Unset
is a no-op, so bots, dedicated servers, CI and headless clients keep working by
default. <code>asobi_client_gate_plugin</code> runs immediately after the rate limiter and
before the password KDF, so a denial (<code>client_gate_denied</code>, 403) never pays the
pbkdf2 cost and a register flood is shed by the cheap in-memory limiter before
it can trigger an outbound siteverify.</p>
<p>A configured gate that crashes, hangs or returns garbage fails closed with
<code>client_gate_denied</code> and a <code>client_gate_unavailable</code> reason: a control that
silently fails open is bypassable by knocking over the vendor. The call is
bounded by <code>{client_gate_timeout, Ms}</code> (default 5000) so a stalled siteverify
cannot pin the request process. Trade strictness for availability with
<code>{client_gate_on_error, skip}</code>.</p>
<p>CAPTCHA, Turnstile and hCaptcha are consumers of this seam and ship outside
core: a vendor round-trip must not couple asobi's request path to a SaaS.</p>
<h2 id="per-request-bounds" tabindex="-1">Per-request bounds</h2>
<p>Deliberate upper bounds that exist to cap what one hostile request costs:</p>
<ul>
<li>Request body - capped at 1 MiB by <code>asobi_body_cap_plugin</code>, before any bytes
are buffered onto the BEAM heap. A body with no <code>Content-Length</code> is rejected
with 411 <code>length_required</code>; over the cap is 413 <code>payload_too_large</code>.</li>
<li>WebSocket pre-auth - a socket that has not authenticated within 10 seconds is
closed with 1008 <code>idle_auth_timeout</code>. Override with
<code>asobi.ws_idle_auth_timeout_ms</code>.</li>
<li>Cloud saves (<code>/saves/:slot</code>) - 256 KB per save, 10 slots per player.</li>
<li>Storage (<code>/storage/:collection/:key</code>) - <code>read_perm</code> and <code>write_perm</code> limited
to <code>public</code> and <code>owner</code>; anything else is <code>storage.invalid_perm</code> (400). A
single object is capped at the same 256 KB as a save
(<code>storage.value_too_large</code>).</li>
<li>Inventory consume - quantity in <code>[1, 1000000]</code>.</li>
<li>Leaderboard <code>top</code> and <code>around</code> - <code>?limit</code> clamped to 100, <code>?range</code> to 50,
which bounds an O(N) scan.</li>
<li>Chat history - <code>?limit</code> clamped to <code>[1, 200]</code>, and channel membership is
enforced (DM participants, world joiners, group members).</li>
<li>Chat buffers - each channel keeps the last 100 messages in memory, and the
channel listing enumerates at most 1000 channels so the sort behind it stays
bounded.</li>
<li>DM send - content capped at 2000 bytes; empty or non-binary content rejected.</li>
<li>Chat channels - an id must be 1 to 256 bytes and carry one of six prefixes
(<code>global:</code>, <code>dm:</code>, <code>world:</code>, <code>zone:</code>, <code>prox:</code>, <code>room:</code>), a connection may
hold 32 joined channels at once, and an idle channel stops after 60 seconds
with no live members.</li>
<li>World creation - 5 worlds per player and 1000 overall by default, counted
through a <code>pg</code> group so the count follows world process lifetime. Tunable
with <code>world_max_per_player</code> and <code>world_max</code>. Over either, the caller gets
<code>world.player_limit_reached</code> or <code>world.capacity_reached</code>.</li>
<li>Matchmaker - reading or cancelling a ticket requires ownership, and a ticket
carries only the player who submitted it, so nobody can be pulled into a
match without consenting.</li>
</ul>
<h2 id="test-coverage" tabindex="-1">Test coverage</h2>
<p>Regressions for the above live under <code>test/</code>:</p>
<ul>
<li><code>asobi_iap_SUITE.erl</code> - 12 cases: 10 Apple (missing fields, not configured,
root not configured, invalid JWS, unsupported alg, missing <code>x5c</code>, invalid
signature, chain validation failure, wrong bundle id, valid receipt) and 2
Google (missing fields, not configured).</li>
<li><code>asobi_guest_SUITE.erl</code> - create or resume, wrong-secret rejection, upgrade
and token revocation.</li>
<li><code>asobi_world_lobby_SUITE.erl</code> - per-player and global world caps.</li>
<li><code>asobi_matchmaker_api_SUITE.erl</code> - ticket ownership.</li>
<li><code>asobi_social_api_SUITE.erl</code> - chat history membership (DM, group,
non-member).</li>
<li><code>asobi_dm_tests.erl</code> - DM length cap and empty-content rejection.</li>
<li><code>asobi_ops_auth_tests.erl</code> and <code>asobi_ops_token_tests.erl</code> - ops actor
resolution and minted-token verification.</li>
<li><code>asobi_console_SUITE.erl</code>, <code>asobi_console_session_tests.erl</code> and
<code>asobi_console_routes_tests.erl</code> - console login, session and CSRF, and the
routes staying 404 while the console is off.</li>
</ul>
<p>Run with <code>rebar3 ct,eunit</code>.</p>
<h2 id="related" tabindex="-1">Related</h2>
<ul>
<li><a href="/docs/security/threat-model">Threat model</a> - the trust boundaries these controls sit on.</li>
<li><a href="/docs/security/known-limitations">Known limitations</a> - what the runtime does not bound.</li>
<li><a href="https://hexdocs.pm/asobi/console.html">Operator console</a> - the console and ops credentials, and how to turn them on.</li>
<li><a href="/docs/security/lua-sandbox">Sandbox model</a> - the Lua side of the same story.</li>
</ul>
"""}
    ]}.

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Authentication and rate limiting

How asobi authenticates clients, validates purchases, and bounds what a single
hostile request or a single hostile caller can cost. For the trust assumptions
underneath, see [Threat model](https://asobi.dev/docs/security/threat-model).

## Session bearer tokens

Every authenticated route is gated by `asobi_auth_plugin:verify/1`, which
expects an `Authorization: Bearer <token>` header. Tokens are issued by
`nova_auth_refresh:generate_pair/2` through `asobi_auth_tokens:issue/2,3` after
a successful register, login, refresh or provider flow. The caller receives
`player_id`, `access_token`, `refresh_token` and `username`; the refresh token
is single-use and rotates. The plugin attaches `auth_data => #{player_id => Id,
...}` to the request map, so controllers pattern-match on that rather than
parsing the header again.

On logout the presented access token is revoked through
`asobi_auth_tokens:revoke_access/1`, so it cannot outlive the cache TTL.

## Apple StoreKit 2 JWS verification

`asobi_iap:verify_apple/1` parses an Apple-signed JWS receipt and verifies it
end to end:

1. The header `alg` must be `ES256`. Every other algorithm is rejected.
2. The `x5c` chain is decoded (DER certificates, base64 in JWS order: leaf,
   intermediate, root).
3. The chain is validated against a configured Apple root CA with
   `public_key:pkix_path_validation/3`. The root is not bundled: set
   `apple_root_cert_path` or `apple_root_certs`, or verification returns
   `apple_root_cert_not_configured`.
4. The signature over `<header>.<payload>` is verified with the leaf
   certificate's public key. Only then is the payload returned, and a bundle id
   that is not the configured one fails with `bundle_id_mismatch`. Expiry is
   reported as a `valid` flag on the result rather than rejected.

Failures return `{error, Reason}` with a sanitised reason binary.
`asobi_iap_controller` returns them as
`{"error": {"code": "iap.verification_failed", "message": ..., "details":
{"reason": ...}}}` without leaking JWS internals.

There is no Lua path to IAP verification. It is an Erlang-side call on the
purchase route.

## Steam ticket validation

`asobi_steam:validate_ticket/1` validates a hex-encoded session ticket against
the Steam Web API:

1. The ticket must be `[0-9a-fA-F]+` and at most 4096 bytes. Anything else is
   rejected before any HTTP call.
2. Every dynamic URL component (key, app id, ticket, steam id) goes through
   `uri_string:quote/1`, so an `&` or `=` in client input cannot inject a query
   parameter into the Steam call.

It is invoked from `asobi_oauth_controller` for `provider = "steam"`.

## Guest device verifiers

Guest auth (`asobi_guest_controller`) lets a device create a player from a
`{device_id, device_secret}` pair with no credentials. It is built to leak
nothing useful even if the identity table is dumped.

- Fails closed. Guest routes serve only when `guest_auth` is true and a
  `guest_verifier_pepper` is configured. Otherwise every guest endpoint returns
  `guest.disabled` (403) and the misconfiguration is logged as
  `guest_auth_misconfigured`.
- The device secret is never stored. The row holds a verifier: a 16-byte random
  salt plus `crypto:mac(hmac, sha256, Pepper, <<Salt/binary, Secret/binary>>)`,
  kept in the identity's `provider_metadata` as `salt`, `key_id`, `verifier`
  and `revoked`, with the salt and the verifier base64-encoded.
- Resume compares with `crypto:hash_equals/2`, so a wrong secret is not
  recoverable by timing.
- The pepper lives outside the database, selected by key id. A dumped verifier
  table is useless without it, and it rotates: add a key id, point
  `guest_verifier_key_id` at it, keep the old ids for the retention window.
  A pepper under 32 bytes is treated as absent, so a truncated value fails
  closed rather than weakening the MAC.
- Bounded input. The secret must base64-decode to between 32 and 128 bytes and
  `device_id` is capped at 255 bytes, so an unauthenticated caller cannot force
  multi-megabyte HMAC work.
- Upgrade is compromise recovery. Claiming a guest calls
  `nova_auth_refresh:revoke_all/2` to kill the token family a stolen device
  secret may have minted, then deletes the guest identity so that secret can no
  longer resume the claimed account.
- Reaping is safe. The optional `asobi_guest_reaper` (off unless
  `guest_reap_after` is set) re-checks that a guest is still unclaimed inside
  its delete transaction, so a concurrent upgrade wins the race. It targets
  guests that have not resumed for the configured window, not guests whose
  accounts are simply old - a device that keeps playing is never reaped. It
  deletes
  through `asobi_player_erase`, the same code an operator-initiated erasure
  runs, so a reaped guest leaves nothing behind and its cached access token
  stops resolving immediately rather than at the next cache expiry.

Treat guest accounts as low assurance until they are upgraded. Anything
valuable - purchases, competitive ranking, cross-device identity - should
require a claimed account.

## Registration mode

Registration is open by default and that is deliberate (ADR 0002): one asobi
deployment serves one game, the endpoint URL is the game identity, and a
downloadable client cannot prove it is your client. `registration` bounds
anonymous signup as a deployment decision:

```erlang
{registration, open}         %% default
%% {registration, oauth_only}
%% {registration, closed}
```

| Mode | Password register | Provider first-time | Guest first-time | Existing players |
|---|---|---|---|---|
| `open` (default) | allowed | allowed | allowed if `guest_auth` | allowed |
| `oauth_only` | denied, `auth.password_registration_disabled` | allowed | governed by `guest_auth` | allowed |
| `closed` | denied, `auth.registration_closed` | denied, `auth.registration_closed` | denied, `auth.registration_closed` | login, refresh and resume all still work |

A game bundle can also declare `script_registration`; the operator's
`registration` key wins wherever it is set, so a bundle can choose a posture
for a deployment that states none but can never widen one that does
(`asobi_registration`). An unrecognised value falls back to `open`, and
`log_mode/0` reports `invalid_registration_mode` at error level at boot.

The shipped `examples/` quickstarts and `asobi_register_bench` register
headless with a username and password, so leave `open` alone in dev and CI.
Choosing a stricter posture is a production decision. asobi logs the active
mode at boot as `event => registration_mode`.

## Rate limits

`asobi_rate_limit_plugin` runs as a `pre_request` plugin in
`config/{dev,prod}_sys.config.src` and picks a Seki limiter group from the
request path. Other limiters are checked at their own call sites. Every group
is registered by `register_limiters` in `asobi_sup`, and every bucket is
**per node**: in a cluster of N nodes an attacker gets N times the budget.

| Group | Limiter | Keyed on | Default | Where |
|---|---|---|---|---|
| `register` | `asobi_register_limiter` | IP, or player id if the request carries a Bearer token | 3 / sec | `/api/v1/auth/register` |
| `auth` | `asobi_auth_limiter` | same | 5 / sec | the rest of `/api/v1/auth/*`, and `POST /console/session` |
| `iap` | `asobi_iap_limiter` | same | 10 / sec | `/api/v1/iap/*` |
| `api` | `asobi_api_limiter` | same | 300 / sec | every other HTTP route |
| `ws_connect` | `asobi_ws_connect_limiter` | IP | 60 / sec | the WebSocket upgrade, spent before the Origin check |
| `join` | `asobi_join_limiter` | player id | 10 / 60 sec | the `match.join` and `world.join` WebSocket frames |
| `guest_global` | `asobi_guest_global_limiter` | one constant key | 100 / sec | guest creation, node-wide |
| `rehome` | `asobi_rehome_limiter` | player id | 5 / sec | world zone crossings |
| `rehome_global` | `asobi_rehome_global_limiter` | one constant key | 200 / sec | world zone crossings, node-wide |
| `script_log` | `asobi_script_log_limiter` | the call site's own key | 3 / 10 sec | repeated warning lines from a failing script or dropped input |

`rate_limit_key/1` buckets an authenticated caller on `player_id` and everyone
else on the peer IP, so one abusive player throttles themselves rather than
everyone behind their NAT. Anything that is not a `Bearer` scheme, or that
reaches the plugin without `auth_data`, falls back to the IP bucket.

The two global buckets exist because a per-IP or per-player limit does not
bound the aggregate: guest rows are minted unauthenticated, and every zone
crossing calls into the one `asobi_terrain_store` the whole world shares, so N
attackers each within their own budget still scale the load linearly.

`/api/v1/auth/register` gets the tighter bucket because it runs the password
KDF (pbkdf2_sha256, see `pbkdf2_iterations`) as its only cost gate. Sharing
login's bucket let a signup flood both starve honest logins and amplify CPU.
The auth bucket plus that same KDF on
`nova_auth_accounts:authenticate/3` is the brute-force gate for login, and it
is why `POST /console/session` shares it: same threat, same shape, one fewer
knob to leave unset. Neither route carries a session, so in practice both are
bucketed on the caller's IP, and distributed abuse is the client gate's
problem rather than the limiter's.

Override any group in your sys config:

```erlang
{rate_limits, #{
    auth     => #{limit => 10, window => 1000},
    register => #{limit => 5,  window => 1000},
    iap      => #{limit => 20, window => 1000},
    api      => #{limit => 600, window => 1000}
}}
```

The dev and test config raises `auth`, `register`, `iap` and `api` to 1000
because CT fires bursts at `127.0.0.1` and the production auth cap would fail
the suites.

The Lua runtime registers two more groups of its own, `log` and `log_global`,
which bound `game.log` volume rather than abuse. They read the same
`rate_limits` key and their names are disjoint from the ones above, so one
merged map carries both.

## Client gate (pre-auth)

`asobi_client_gate` is a pluggable "is this traffic allowed in" seam on the
three anonymous auth-create routes: `/api/v1/auth/register`,
`/api/v1/auth/oauth` and `/api/v1/auth/guest`. It is distinct from
`asobi_auth_plugin`, which answers "who is the player": a gate carries no
player identity, and its return type is deliberately narrow so an
implementation cannot leak or forge one.

```erlang
-callback verify(asobi_client_gate:context()) -> skip | {deny, Reason :: binary()}.
```

The input is a minimised context, not the raw request: `#{ip, headers, path,
token}`. The request map still holds the registration plaintext password at
that point, and a traffic gate has no use for it, so a verbose or buggy
third-party gate cannot log or forward credentials.

Wire an implementation with `{client_gate, my_gate_module}` in app env. Unset
is a no-op, so bots, dedicated servers, CI and headless clients keep working by
default. `asobi_client_gate_plugin` runs immediately after the rate limiter and
before the password KDF, so a denial (`client_gate_denied`, 403) never pays the
pbkdf2 cost and a register flood is shed by the cheap in-memory limiter before
it can trigger an outbound siteverify.

A configured gate that crashes, hangs or returns garbage fails closed with
`client_gate_denied` and a `client_gate_unavailable` reason: a control that
silently fails open is bypassable by knocking over the vendor. The call is
bounded by `{client_gate_timeout, Ms}` (default 5000) so a stalled siteverify
cannot pin the request process. Trade strictness for availability with
`{client_gate_on_error, skip}`.

CAPTCHA, Turnstile and hCaptcha are consumers of this seam and ship outside
core: a vendor round-trip must not couple asobi's request path to a SaaS.

## Per-request bounds

Deliberate upper bounds that exist to cap what one hostile request costs:

- Request body - capped at 1 MiB by `asobi_body_cap_plugin`, before any bytes
  are buffered onto the BEAM heap. A body with no `Content-Length` is rejected
  with 411 `length_required`; over the cap is 413 `payload_too_large`.
- WebSocket pre-auth - a socket that has not authenticated within 10 seconds is
  closed with 1008 `idle_auth_timeout`. Override with
  `asobi.ws_idle_auth_timeout_ms`.
- Cloud saves (`/saves/:slot`) - 256 KB per save, 10 slots per player.
- Storage (`/storage/:collection/:key`) - `read_perm` and `write_perm` limited
  to `public` and `owner`; anything else is `storage.invalid_perm` (400). A
  single object is capped at the same 256 KB as a save
  (`storage.value_too_large`).
- Inventory consume - quantity in `[1, 1000000]`.
- Leaderboard `top` and `around` - `?limit` clamped to 100, `?range` to 50,
  which bounds an O(N) scan.
- Chat history - `?limit` clamped to `[1, 200]`, and channel membership is
  enforced (DM participants, world joiners, group members).
- Chat buffers - each channel keeps the last 100 messages in memory, and the
  channel listing enumerates at most 1000 channels so the sort behind it stays
  bounded.
- DM send - content capped at 2000 bytes; empty or non-binary content rejected.
- Chat channels - an id must be 1 to 256 bytes and carry one of six prefixes
  (`global:`, `dm:`, `world:`, `zone:`, `prox:`, `room:`), a connection may
  hold 32 joined channels at once, and an idle channel stops after 60 seconds
  with no live members.
- World creation - 5 worlds per player and 1000 overall by default, counted
  through a `pg` group so the count follows world process lifetime. Tunable
  with `world_max_per_player` and `world_max`. Over either, the caller gets
  `world.player_limit_reached` or `world.capacity_reached`.
- Matchmaker - reading or cancelling a ticket requires ownership, and a ticket
  carries only the player who submitted it, so nobody can be pulled into a
  match without consenting.

## Test coverage

Regressions for the above live under `test/`:

- `asobi_iap_SUITE.erl` - 12 cases: 10 Apple (missing fields, not configured,
  root not configured, invalid JWS, unsupported alg, missing `x5c`, invalid
  signature, chain validation failure, wrong bundle id, valid receipt) and 2
  Google (missing fields, not configured).
- `asobi_guest_SUITE.erl` - create or resume, wrong-secret rejection, upgrade
  and token revocation.
- `asobi_world_lobby_SUITE.erl` - per-player and global world caps.
- `asobi_matchmaker_api_SUITE.erl` - ticket ownership.
- `asobi_social_api_SUITE.erl` - chat history membership (DM, group,
  non-member).
- `asobi_dm_tests.erl` - DM length cap and empty-content rejection.
- `asobi_ops_auth_tests.erl` and `asobi_ops_token_tests.erl` - ops actor
  resolution and minted-token verification.
- `asobi_console_SUITE.erl`, `asobi_console_session_tests.erl` and
  `asobi_console_routes_tests.erl` - console login, session and CSRF, and the
  routes staying 404 while the console is off.

Run with `rebar3 ct,eunit`.

## Related

- [Threat model](https://asobi.dev/docs/security/threat-model) - the trust boundaries these controls sit on.
- [Known limitations](https://asobi.dev/docs/security/known-limitations) - what the runtime does not bound.
- [Operator console](https://hexdocs.pm/asobi/console.html) - the console and ops credentials, and how to turn them on.
- [Sandbox model](https://asobi.dev/docs/security/lua-sandbox) - the Lua side of the same story.
""".
