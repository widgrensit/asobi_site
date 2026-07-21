%% GENERATED from asobi guides/security-auth.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_security_auth_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

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
        {h1, [], [~"Authentication & rate limiting"]},
        {raw,
            ~"""
<p>This guide documents how asobi authenticates clients, validates
purchases, and bounds the brute-force surface. For the higher-level
trust assumptions see <a href="/docs/security/threat-model">Threat model</a>.</p>
<h2 id="session-bearer-tokens" tabindex="-1">Session bearer tokens</h2>
<p>Every authenticated route is gated by <code>asobi_auth_plugin:verify/1</code>,
which expects an <code>Authorization: Bearer &lt;token&gt;</code> header. Tokens are
issued by <code>nova_auth_refresh:generate_pair/2</code> (via
<code>asobi_auth_tokens:issue/2,3</code>) after a successful <code>register/1</code>,
<code>login/1</code>, <code>refresh/1</code>, or OAuth flow. The caller receives an access
token plus a single-use rotating refresh token. The plugin attaches
<code>auth_data =&gt; #{player_id =&gt; Id, ...}</code> to the request map — controllers
should pattern-match on that rather than parsing the header themselves.</p>
<p>On logout the presented access token is revoked via
<code>nova_auth_refresh:delete_access_token/2</code> (wrapped by
<code>asobi_auth_tokens:revoke_access/1</code>) so it cannot outlive the cache TTL.</p>
<h2 id="apple-storekit-2-jws-verification" tabindex="-1">Apple StoreKit 2 JWS verification</h2>
<p><code>asobi_iap:verify_apple/1</code> parses an Apple-signed JWS receipt and
verifies it end-to-end:</p>
<ol>
<li>Header <code>alg</code> is required to be <code>ES256</code>. Other algorithms are
rejected.</li>
<li>The <code>x5c</code> chain is decoded (DER-encoded certificates, base64'd in
JWS order: leaf → intermediate → root).</li>
<li>The chain is validated against a configured Apple Root CA via
<code>public_key:pkix_path_validation/3</code>. The root is not bundled: operators
point <code>apple_root_cert_path</code> (or <code>apple_root_certs</code>) at it, and
verification returns <code>apple_root_cert_not_configured</code> if neither is set.</li>
<li>The signature on <code>&lt;header&gt;.&lt;payload&gt;</code> is verified with the leaf
cert's public key. A bit-flipped signature, swapped signature, or
any chain mismatch fails the verification.</li>
</ol>
<p>Failures return <code>{error, Reason}</code> with a sanitised reason atom. The
controller (<code>asobi_iap_controller</code>) maps them to 400/401 responses
without leaking JWS internals to the client.</p>
<h2 id="steam-ticket-validation" tabindex="-1">Steam ticket validation</h2>
<p><code>asobi_steam:validate_ticket/1</code> validates a hex-encoded Steam session
ticket against the Steam Web API:</p>
<ol>
<li>The ticket character class is enforced (<code>[0-9a-fA-F]+</code>, max 4096
bytes). Anything else is rejected before any HTTP call.</li>
<li>All dynamic URL components (key, app id, ticket, steam id) are
passed through <code>uri_string:quote/1</code> so an <code>&amp;</code> or <code>=</code> in user input
cannot inject query parameters into the Steam call.</li>
</ol>
<p>The ticket validator is invoked from <code>asobi_oauth_controller</code> for
<code>provider = &quot;steam&quot;</code> flows.</p>
<h2 id="guest-device-verifiers" tabindex="-1">Guest device verifiers</h2>
<p>Anonymous/guest auth (<code>asobi_guest_controller</code>) lets a device create a
player from a <code>{device_id, device_secret}</code> pair without credentials. It
is secured to leak nothing useful even if the identity table is dumped:</p>
<ul>
<li><strong>Fails closed.</strong> The controller serves guest routes only when
<code>guest_auth</code> is <code>true</code> <strong>and</strong> a <code>guest_verifier_pepper</code> is
configured; otherwise every guest endpoint returns <code>403 guest_auth_disabled</code>.</li>
<li><strong>The device secret is never stored.</strong> The database holds a
<em>verifier</em>, not the secret. On creation the server draws a 16-byte
salt from <code>crypto:strong_rand_bytes/1</code> and combines it with a
server-side pepper (selected by key id) as
<code>crypto:mac(hmac, sha256, Pepper, &lt;&lt;Salt/binary, Secret/binary&gt;&gt;)</code>.
The result is stored in the identity's <code>provider_metadata</code>
(<code>salt</code> / <code>key_id</code> / <code>verifier</code> / <code>revoked</code>, all base64).</li>
<li><strong>Timing-safe comparison.</strong> Resume verifies with
<code>crypto:hash_equals/2</code> so a wrong secret can't be recovered by
timing.</li>
<li><strong>The pepper lives outside the database.</strong> It is a keyed secret
(env/secret manager), so a dumped verifier table is useless without
it, and it is rotatable: add a new key id, point
<code>guest_verifier_key_id</code> at it, and keep old key ids for the retention
window so existing guests still resume.</li>
<li><strong>Bounded input.</strong> The secret must base64-decode to at least 32 bytes
(under a fixed upper cap) and the <code>device_id</code> must be non-empty and
at most 255 bytes, so an unauthenticated caller can't force
multi-megabyte HMAC work.</li>
<li><strong>Upgrade is compromise-recovery.</strong> Claiming a guest
(<code>/auth/guest/upgrade</code>) calls <code>nova_auth_refresh:revoke_all/2</code> to kill
the entire token family a stolen device secret may have minted, then
deletes the guest identity so the secret can no longer resume the
now-claimed account.</li>
<li><strong>Safe reaping.</strong> The optional <code>asobi_guest_reaper</code> (off unless
<code>guest_reap_after</code> is set) re-checks that a guest is still unclaimed
<em>inside</em> its delete transaction, so a concurrent upgrade wins the
race. The unlinked-guest cap reads a short-TTL cached count and fails
closed if the count can't be read.</li>
</ul>
<div class="docs-callout docs-callout-warning"><p class="docs-callout-title">Assurance level</p><p>Treat guest accounts as low-assurance until they are upgraded. Anything
valuable - purchases, competitive ranking, cross-device identity -
should require a claimed account, not a guest session.</p>
</div>
<h2 id="registration-mode" tabindex="-1">Registration mode</h2>
<p>Registration is <strong>open by default</strong> and that is deliberate (see ADR 0002):
one asobi deployment serves one game, the endpoint URL is the game
identity, and a downloadable client cannot prove it is &quot;your&quot; client. The
<code>registration</code> app-env setting bounds anonymous signup as a <em>deployment</em>
decision:</p>
<pre><code class="language-erlang">{registration, open}         %% default
%% {registration, oauth_only}
%% {registration, closed}
</code></pre>
<table>
<thead>
<tr>
<th>Mode</th>
<th>Password register</th>
<th>OAuth first-time</th>
<th>Guest first-time</th>
<th>Existing players</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>open</code> (default)</td>
<td>✅</td>
<td>✅</td>
<td>✅ (if <code>guest_auth</code>)</td>
<td>✅</td>
</tr>
<tr>
<td><code>oauth_only</code></td>
<td>❌ <code>403</code></td>
<td>✅</td>
<td>governed by <code>guest_auth</code></td>
<td>✅</td>
</tr>
<tr>
<td><code>closed</code></td>
<td>❌ <code>403</code></td>
<td>❌ <code>403</code></td>
<td>❌ <code>403</code></td>
<td>✅ login/refresh/resume</td>
</tr>
</tbody>
</table>
<p><code>oauth_only</code> refuses only password registration; guest signup keeps
following its own <code>guest_auth</code> toggle. <code>closed</code> freezes every new-player
path while leaving all existing players able to authenticate. An
unrecognised value falls back to <code>open</code> and logs a warning.</p>
<blockquote>
<p><strong>Footgun (flip before release).</strong> The shipped <code>examples/</code> quickstarts
and <code>asobi_register_bench</code> register headless with username/password and
rely on the <code>open</code> default - do not change it in dev/CI. Choosing a
stricter posture is a production deployment decision, the same way Photon
documents flipping <code>AllowAnonymous</code> before release. asobi logs the active
mode at boot (<code>event =&gt; registration_mode</code>) so the posture is visible.</p>
</blockquote>
<h2 id="per-route-rate-limits" tabindex="-1">Per-route rate limits</h2>
<p><code>asobi_rate_limit_plugin</code> is wired as a <code>pre_request</code> plugin in
<code>config/{dev,prod}_sys.config.src</code>. It selects a Seki limiter group
based on the request path:</p>
<table>
<thead>
<tr>
<th>Path</th>
<th>Limiter</th>
<th>Default limit (req/sec/IP)</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>/api/v1/auth/register</code></td>
<td><code>asobi_register_limiter</code></td>
<td>3</td>
</tr>
<tr>
<td><code>/api/v1/auth/*</code> (login, refresh, ...)</td>
<td><code>asobi_auth_limiter</code></td>
<td>5</td>
</tr>
<tr>
<td><code>/api/v1/iap/*</code></td>
<td><code>asobi_iap_limiter</code></td>
<td>10</td>
</tr>
<tr>
<td>everything else</td>
<td><code>asobi_api_limiter</code></td>
<td>300</td>
</tr>
</tbody>
</table>
<p><code>/api/v1/auth/register</code> gets its own tighter bucket (asobi#157): it runs
the password KDF (pbkdf2_sha256, see <code>pbkdf2_iterations</code>) as its only
cost gate, so sharing the login bucket let a signup flood both starve
honest logins and amplify server CPU. The dedicated 3/sec cap isolates
register and bounds the per-IP KDF cost. This is per-IP only; distributed
abuse is deferred to the pre-auth gate in asobi#158.</p>
<p>The auth limiter is the brute-force gate for login: a 5/sec cap plus the
pbkdf2_sha256 cost on <code>nova_auth_accounts:authenticate/3</code> makes online
password guessing infeasible at internet scale. Operators can override
the limits via the <code>asobi, rate_limits</code> env in their sys config:</p>
<pre><code class="language-erlang">{rate_limits, #{
    auth     =&gt; #{limit =&gt; 10, window =&gt; 1000},
    register =&gt; #{limit =&gt; 5,  window =&gt; 1000},
    iap      =&gt; #{limit =&gt; 20, window =&gt; 1000},
    api      =&gt; #{limit =&gt; 600, window =&gt; 1000}
}}
</code></pre>
<p>The dev / test sys config bumps all three to 1000 because CT bursts
register/login calls against <code>127.0.0.1</code> and the production-default
auth cap would fail the suites.</p>
<h2 id="client-gate-pre-auth" tabindex="-1">Client gate (pre-auth)</h2>
<p><code>asobi_client_gate</code> is a pluggable &quot;is this traffic allowed in&quot; seam on the
anonymous auth-create routes (<code>/auth/register</code>, <code>/auth/oauth</code>,
<code>/auth/guest</code>). It is distinct from <code>asobi_auth_plugin</code> (&quot;who is the
player&quot;): a gate carries <strong>no</strong> player identity - its return type is
deliberately narrow so an implementation cannot leak or forge identity.</p>
<pre><code class="language-erlang">-callback verify(asobi_client_gate:context()) -&gt; skip | {deny, Reason :: binary()}.
</code></pre>
<p>The input is a <strong>minimized context</strong>, not the raw request - <code>#{ip, headers, path, token}</code>. The request map still holds the registration plaintext
password at this point, and a traffic gate has no need for it; handing over
only IP / headers / path / a <code>client_gate_token</code> field keeps a verbose or
buggy third-party gate from logging or forwarding credentials.</p>
<p>Wire an implementation with <code>{client_gate, my_gate_module}</code> in app env;
<strong>unset is a no-op</strong>, so bots, dedicated servers, CI, headless clients and
<code>asobi_register_bench</code> all keep working by default. <code>asobi_client_gate_plugin</code>
runs immediately after the rate limiter and before the password KDF, so a
denial (<code>403 registration_gate_denied</code>) never pays the pbkdf2 cost
(asobi#157), and a register flood is shed by the cheap in-memory limiter
before it can trigger an outbound siteverify.</p>
<p>A configured gate that <strong>crashes, hangs, or returns garbage fails closed</strong>
by default (<code>403 client_gate_unavailable</code>) - a security control that
silently fails open is bypassable by knocking over the vendor. The gate call
is bounded by <code>{client_gate_timeout, Ms}</code> (default 5000) so a stalled
siteverify cannot pin the request process. Trade strictness for availability
with <code>{client_gate_on_error, skip}</code>.</p>
<p>CAPTCHA / Turnstile / hCaptcha is the first <em>consumer</em> of this seam and
ships <strong>outside</strong> core (asobi_engine or a contrib plugin): a vendor-specific
external round-trip must not couple asobi's public request path to a SaaS.</p>
<h2 id="ddos-dos-surface-notes" tabindex="-1">DDoS / DoS surface notes</h2>
<p>These are the deliberate per-call upper bounds in the runtime that
exist purely to bound the cost of a single hostile request:</p>
<ul>
<li><strong>Cloud saves</strong> (<code>/saves/:slot</code>) — body capped at 256 KB; per-player
slot count capped at 10.</li>
<li><strong>Storage</strong> (<code>/storage/:collection/:key</code>) — <code>read_perm</code> /
<code>write_perm</code> whitelisted to <code>[&quot;public&quot;, &quot;owner&quot;]</code>; arbitrary strings
rejected with 400.</li>
<li><strong>Inventory consume</strong> — quantity range <code>[1, 1_000_000]</code>.</li>
<li><strong>Leaderboard</strong> <code>top</code> / <code>around</code> — <code>?limit</code> clamped to 100, <code>?range</code>
to 50 (mitigates an O(N) ETS scan attack).</li>
<li><strong>Chat history</strong> — <code>?limit</code> clamped to <code>[1, 200]</code>; channel
membership is enforced (DM participants, world joiners, group
members).</li>
<li><strong>DM send</strong> — content capped at 2000 bytes; non-binary or empty
content rejected.</li>
<li><strong>Group chat / WS <code>chat.join</code></strong> — channel id namespaced
(<code>dm:</code>, <code>world:</code>, <code>zone:</code>, <code>prox:</code>, <code>room:</code>); per-connection cap of
32 simultaneously joined channels; idle channels stop after 60s
with no live members.</li>
<li><strong>Per-player world creation</strong> — capped via pg group; default 5
worlds per player, 1000 globally. Tunable via <code>world_max_per_player</code>
/ <code>world_max</code> env.</li>
<li><strong>Matchmaker</strong> — ticket reads and cancellations require ownership, so
one player cannot read or cancel another's ticket. A ticket carries only
the submitting player, so it cannot pull a non-consenting player into a
match.</li>
</ul>
<h2 id="test-coverage" tabindex="-1">Test coverage</h2>
<p>Regressions for the items above live under <code>test/</code>:</p>
<ul>
<li><code>asobi_iap_SUITE.erl</code> — Apple JWS happy path + 14 negative cases
(bad alg, missing x5c, swapped signature, expired cert, untrusted
root, …).</li>
<li><code>asobi_world_lobby_SUITE.erl</code> — F-9 per-player + global world caps.</li>
<li><code>asobi_matchmaker_api_SUITE.erl</code> — ticket ownership + party-not-accepted
ownership.</li>
<li><code>asobi_social_api_SUITE.erl</code> — F-10 chat history membership (DM,
group, non-member denial).</li>
<li><code>asobi_dm_tests.erl</code> — F-11 length cap, empty-content rejection.</li>
<li><code>asobi_guest_SUITE.erl</code> — guest create-or-resume, wrong-secret
rejection, upgrade + token revocation.</li>
</ul>
<p>Run with <code>rebar3 ct,eunit</code>.</p>
"""}
    ]}.
