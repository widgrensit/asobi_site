%% GENERATED from asobi guides/authentication.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_auth_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-auth", title => ~"Authentication — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Authentication"
        ]},
        {h1, [], [~"Authentication"]},
        {raw,
            ~"""
<p>Asobi supports multiple authentication methods: username/password, OAuth/OIDC
social login (Google, Apple, Microsoft, Discord), Steam, and anonymous
<a href="#guest-anonymous">guest</a> accounts that a player can later upgrade to a real one.</p>
<p>Players can link multiple providers to a single account.</p>
<blockquote>
<p>Auth endpoints return an <code>access_token</code> (short-lived) and a <code>refresh_token</code>
(used against <code>/auth/refresh</code>). The <code>session_token</code> shown in the shorthand
examples below is the access token; use it as the <code>Bearer</code> credential.</p>
</blockquote>
<div class="docs-callout docs-callout-info"><p class="docs-callout-title">Windows</p><p>Run the <code>curl</code> examples in Git Bash or WSL, or use PowerShell's
<code>Invoke-RestMethod</code> with the same URL and a JSON <code>-Body</code>. Authenticated calls
add <code>-Headers @{ Authorization = 'Bearer &lt;token&gt;' }</code>.</p>
</div>
<h2 id="username-password" tabindex="-1">Username &amp; Password</h2>
<p>The simplest method. Register and login to receive a session token:</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{&quot;username&quot;: &quot;player1&quot;, &quot;password&quot;: &quot;secret123&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;player_id&quot;: &quot;...&quot;, &quot;session_token&quot;: &quot;...&quot;, &quot;username&quot;: &quot;player1&quot;}
</code></pre>
<p>Use the session token in subsequent requests:</p>
<pre><code>Authorization: Bearer &lt;session_token&gt;
</code></pre>
<h2 id="refresh-rotation" tabindex="-1">Refresh &amp; Rotation</h2>
<p>Access tokens are short-lived. When one expires (a <code>401</code>), exchange the refresh
token for a fresh pair at <code>/api/v1/auth/refresh</code>. Rotation is single-use: the
server burns the presented refresh token and returns a new access token <em>and</em> a
new refresh token, so always store both from the response.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/refresh \
  -H 'Content-Type: application/json' \
  -d '{&quot;refresh_token&quot;: &quot;&lt;refresh_token&gt;&quot;}'
# =&gt; {&quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;}
</code></pre>
<p>The official SDKs persist the refresh token, attach the access token to every
call, and refresh-and-retry on a 401 automatically.</p>
<h2 id="oauth-social-login" tabindex="-1">OAuth / Social Login</h2>
<p>For game clients, Asobi uses server-side token validation. The game client
authenticates with the platform SDK (Google Sign-In, Apple Sign-In, etc.)
to obtain an ID token, then sends it to Asobi for validation.</p>
<pre><code>POST /api/v1/auth/oauth
</code></pre>
<h3 id="flow" tabindex="-1">Flow</h3>
<ol>
<li>Player taps &quot;Sign in with Google&quot; in your game</li>
<li>Platform SDK returns an ID token (JWT)</li>
<li>Game client sends the token to Asobi</li>
<li>Asobi validates the JWT against the provider's JWKS</li>
<li>If the identity exists, the player is logged in</li>
<li>If not, a new player account is created and linked</li>
</ol>
<h3 id="example" tabindex="-1">Example</h3>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/oauth \
  -H 'Content-Type: application/json' \
  -d '{&quot;provider&quot;: &quot;google&quot;, &quot;token&quot;: &quot;eyJhbGciOiJSUzI1NiIs...&quot;}'
</code></pre>
<p>First-time response (new account created):</p>
<pre><code class="language-json">{
  &quot;player_id&quot;: &quot;...&quot;,
  &quot;session_token&quot;: &quot;...&quot;,
  &quot;username&quot;: &quot;google_abc12345_4821&quot;,
  &quot;created&quot;: true
}
</code></pre>
<p>Returning player response:</p>
<pre><code class="language-json">{
  &quot;player_id&quot;: &quot;...&quot;,
  &quot;session_token&quot;: &quot;...&quot;,
  &quot;username&quot;: &quot;player1&quot;
}
</code></pre>
<h3 id="supported-providers" tabindex="-1">Supported Providers</h3>
<table>
<thead>
<tr>
<th>Provider</th>
<th><code>provider</code> value</th>
<th>Issuer</th>
</tr>
</thead>
<tbody>
<tr>
<td>Google</td>
<td><code>&quot;google&quot;</code></td>
<td><code>https://accounts.google.com</code></td>
</tr>
<tr>
<td>Apple</td>
<td><code>&quot;apple&quot;</code></td>
<td><code>https://appleid.apple.com</code></td>
</tr>
<tr>
<td>Microsoft</td>
<td><code>&quot;microsoft&quot;</code></td>
<td><code>https://login.microsoftonline.com/common/v2.0</code></td>
</tr>
<tr>
<td>Discord</td>
<td><code>&quot;discord&quot;</code></td>
<td><code>https://discord.com</code></td>
</tr>
<tr>
<td>Steam</td>
<td><code>&quot;steam&quot;</code></td>
<td>N/A (custom, see below)</td>
</tr>
</tbody>
</table>
<h3 id="configuration" tabindex="-1">Configuration</h3>
<p>Add provider credentials to your <code>sys.config</code>:</p>
<pre><code class="language-erlang">{asobi, [
    {oidc_providers, #{
        google =&gt; #{
            issuer =&gt; &lt;&lt;&quot;https://accounts.google.com&quot;&gt;&gt;,
            client_id =&gt; &lt;&lt;&quot;YOUR_CLIENT_ID&quot;&gt;&gt;,
            client_secret =&gt; &lt;&lt;&quot;YOUR_CLIENT_SECRET&quot;&gt;&gt;
        },
        apple =&gt; #{
            issuer =&gt; &lt;&lt;&quot;https://appleid.apple.com&quot;&gt;&gt;,
            client_id =&gt; &lt;&lt;&quot;YOUR_CLIENT_ID&quot;&gt;&gt;,
            client_secret =&gt; &lt;&lt;&quot;YOUR_CLIENT_SECRET&quot;&gt;&gt;
        }
    }}
]}
</code></pre>
<p>Each provider needs a client ID and secret from the respective developer console:</p>
<ul>
<li><strong>Google</strong>: <a href="https://console.cloud.google.com/">Google Cloud Console</a> → APIs &amp; Services → Credentials</li>
<li><strong>Apple</strong>: <a href="https://developer.apple.com/">Apple Developer</a> → Certificates, Identifiers &amp; Profiles → Service IDs</li>
<li><strong>Microsoft</strong>: <a href="https://portal.azure.com/">Azure Portal</a> → App registrations</li>
<li><strong>Discord</strong>: <a href="https://discord.com/developers/applications">Discord Developer Portal</a> → OAuth2</li>
</ul>
<h2 id="steam" tabindex="-1">Steam</h2>
<p>Steam uses session tickets instead of OIDC. The game client obtains a ticket
via <code>ISteamUser::GetAuthSessionTicket</code> and sends the hex-encoded ticket.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/oauth \
  -H 'Content-Type: application/json' \
  -d '{&quot;provider&quot;: &quot;steam&quot;, &quot;token&quot;: &quot;14000000...&quot;}'
</code></pre>
<p>Asobi validates the ticket via the Steam Web API and fetches the player's
display name from their Steam profile.</p>
<h3 id="configuration-1" tabindex="-1">Configuration</h3>
<pre><code class="language-erlang">{asobi, [
    {steam_api_key, &lt;&lt;&quot;YOUR_STEAM_WEB_API_KEY&quot;&gt;&gt;},
    {steam_app_id, &lt;&lt;&quot;YOUR_STEAM_APP_ID&quot;&gt;&gt;}
]}
</code></pre>
<p>Get your API key from the <a href="https://partner.steamgames.com/">Steam Partner site</a>.</p>
<h2 id="guest-anonymous" tabindex="-1">Guest (Anonymous)</h2>
<p>Guest auth lets a player start playing immediately - no email, no password, no
social sign-in - and claim a real account later without losing progress. It is
the &quot;device-based auth&quot; option: the client generates a secret once, stores it on
the device, and presents it to resume the same account on every launch.</p>
<p>Guest auth is <strong>opt-in</strong> and disabled by default. Enable it in <code>sys.config</code>
(see <a href="#configuration-2">Configuration</a>) before the endpoints respond.</p>
<h3 id="how-it-works" tabindex="-1">How it works</h3>
<ol>
<li>On first launch the client generates a random <code>device_secret</code> (&gt;= 32 bytes
from a CSPRNG) and a stable <code>device_id</code>, and stores both on the device
(Keychain on iOS, Keystore on Android, etc.).</li>
<li>The client posts them to <code>POST /api/v1/auth/guest</code>. Asobi creates a player
and stores only a <strong>salted, peppered HMAC</strong> of the secret - never the secret
itself - then returns a token pair.</li>
<li>On later launches the client posts the same <code>device_id</code> + <code>device_secret</code>.
Asobi verifies the HMAC and resumes the <strong>same</strong> player (create-or-resume).</li>
<li>When the player is ready, they call <code>POST /api/v1/auth/guest/upgrade</code> with a
username and password. The account becomes a normal password account and the
device secret is revoked.</li>
</ol>
<p>The client must treat <code>device_secret</code> like a password: generate it with a
cryptographic RNG, store it in secure device storage, and never log or transmit
it anywhere but this endpoint. A guest account is only as safe as that secret,
so it is low-assurance until upgraded.</p>
<h3 id="create-or-resume" tabindex="-1">Create or resume</h3>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/guest \
  -H 'Content-Type: application/json' \
  -d '{&quot;device_id&quot;: &quot;b64-device-id&quot;, &quot;device_secret&quot;: &quot;b64-32-random-bytes&quot;}'
</code></pre>
<p>First call (new account):</p>
<pre><code class="language-json">{
  &quot;player_id&quot;: &quot;...&quot;,
  &quot;access_token&quot;: &quot;...&quot;,
  &quot;refresh_token&quot;: &quot;...&quot;,
  &quot;username&quot;: &quot;guest_019f615cbc4a&quot;,
  &quot;created&quot;: true,
  &quot;guest&quot;: true
}
</code></pre>
<p>Later calls with the same credentials resume the same player and omit <code>created</code>.
A wrong secret for a known <code>device_id</code> returns <code>401 invalid_device_secret</code> and
never creates a second account.</p>
<h3 id="upgrade-to-a-real-account" tabindex="-1">Upgrade to a real account</h3>
<p>Requires the guest's own session (the token from the create-or-resume call).
Only an unclaimed guest may upgrade - a password account, or an account with a
non-guest provider, is refused.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/guest/upgrade \
  -H 'Authorization: Bearer &lt;access_token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;username&quot;: &quot;player1&quot;, &quot;password&quot;: &quot;secret123&quot;}'
</code></pre>
<pre><code class="language-json">{
  &quot;player_id&quot;: &quot;...&quot;,
  &quot;access_token&quot;: &quot;...&quot;,
  &quot;refresh_token&quot;: &quot;...&quot;,
  &quot;username&quot;: &quot;player1&quot;,
  &quot;upgraded&quot;: true
}
</code></pre>
<p>Upgrade revokes every token the guest held (a fresh pair is returned) and
deletes the device verifier, so the old device secret can no longer sign in.
Player id, progress, wallets, and inventory are preserved.</p>
<h3 id="errors" tabindex="-1">Errors</h3>
<table>
<thead>
<tr>
<th>Status</th>
<th><code>error</code></th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>400</code></td>
<td><code>missing_required_fields</code></td>
<td><code>device_id</code> / <code>device_secret</code> (or <code>username</code> / <code>password</code> on upgrade) absent</td>
</tr>
<tr>
<td><code>400</code></td>
<td><code>weak_device_secret</code></td>
<td>Secret decodes to fewer than 32 bytes (or exceeds the size cap)</td>
</tr>
<tr>
<td><code>400</code></td>
<td><code>invalid_device_id</code></td>
<td><code>device_id</code> empty or over 255 bytes</td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>invalid_device_secret</code></td>
<td>Wrong secret for a known device</td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>guest_revoked</code></td>
<td>The device verifier was revoked</td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>guest_upgraded</code></td>
<td>The account was already claimed; log in with its real credentials</td>
</tr>
<tr>
<td><code>403</code></td>
<td><code>guest_auth_disabled</code></td>
<td>Guest auth is not enabled in config</td>
</tr>
<tr>
<td><code>404</code></td>
<td><code>player_not_found</code></td>
<td>The upgrade token resolves to no player</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>device_already_registered</code></td>
<td>Two creates for the same device raced; retry - the retry resumes the existing guest</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>not_an_unclaimed_guest</code></td>
<td>Upgrade target is not an unclaimed guest</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>username_taken</code></td>
<td>Upgrade username is already in use</td>
</tr>
<tr>
<td><code>422</code></td>
<td><code>validation_failed</code></td>
<td>Upgrade fields invalid (see <code>fields</code>)</td>
</tr>
<tr>
<td><code>500</code></td>
<td><code>guest_create_failed</code></td>
<td>The player row could not be created</td>
</tr>
<tr>
<td><code>500</code></td>
<td><code>guest_player_missing</code></td>
<td>The device resolves to an identity whose player no longer exists</td>
</tr>
<tr>
<td><code>503</code></td>
<td><code>guest_capacity_reached</code></td>
<td>Global create limit or the unlinked-guest cap was hit</td>
</tr>
</tbody>
</table>
<h3 id="configuration-2" tabindex="-1">Configuration</h3>
<pre><code class="language-erlang">{asobi, [
    {guest_auth, true},
    %% Required. A key-id -&gt; pepper map (&gt;= 32 bytes each). Keep old keys for the
    %% guest retention window so existing guests can still resume after rotation.
    {guest_verifier_pepper, #{&lt;&lt;&quot;v1&quot;&gt;&gt; =&gt; &lt;&lt;&quot;a-32-byte-or-longer-secret......&quot;&gt;&gt;}},
    {guest_verifier_key_id, &lt;&lt;&quot;v1&quot;&gt;&gt;},

    %% Optional abuse controls.
    {guest_unlinked_cap, 100000},        %% max unclaimed guests, or `infinity`

    %% Optional retention. Unset = permanent guests (never reaped). Set to a
    %% number of seconds to delete unclaimed guests older than that.
    {guest_reap_after, 2592000}          %% e.g. 30 days
]}
</code></pre>
<p>The pepper is a server-side secret that makes a stolen database of verifiers
useless without it - store it like any other secret (env/secret manager), not in
source. Guest creation is additionally bounded by a global rate limiter and the
per-IP auth limiter.</p>
<h2 id="linking-providers" tabindex="-1">Linking Providers</h2>
<p>Players can link additional providers to their existing account. This allows
them to sign in from different platforms (e.g., link both Google and Steam to
the same player).</p>
<h3 id="link-a-provider" tabindex="-1">Link a Provider</h3>
<p>Requires an authenticated session.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/link \
  -H 'Authorization: Bearer &lt;session_token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;provider&quot;: &quot;discord&quot;, &quot;token&quot;: &quot;eyJhbGciOi...&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;provider&quot;: &quot;discord&quot;, &quot;provider_uid&quot;: &quot;123456789&quot;, &quot;linked&quot;: true}
</code></pre>
<h3 id="unlink-a-provider" tabindex="-1">Unlink a Provider</h3>
<p>Asobi prevents unlinking the last auth method to avoid locking the player out.</p>
<pre><code class="language-bash">curl -X DELETE http://localhost:8084/api/v1/auth/unlink \
  -H 'Authorization: Bearer &lt;session_token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;provider&quot;: &quot;discord&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;success&quot;: true}
</code></pre>
<h2 id="websocket-authentication" tabindex="-1">WebSocket Authentication</h2>
<p>After obtaining a session token (from any auth method), connect to the
WebSocket and authenticate:</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;session.connect&quot;,
  &quot;payload&quot;: {&quot;token&quot;: &quot;&lt;session_token&gt;&quot;}
}
</code></pre>
<p>The token works the same regardless of which provider was used to obtain it.</p>
<h2 id="sdk-integration" tabindex="-1">SDK Integration</h2>
<p>The same Google sign-in flow across the SDKs. The platform SDK returns an ID
token; hand it to Asobi and the session token is stored internally.</p>
<div class="tabbed-code"><input type="radio" name="auth-tab0" id="auth-tab0-1" checked><input type="radio" name="auth-tab0" id="auth-tab0-2"><input type="radio" name="auth-tab0" id="auth-tab0-3"><input type="radio" name="auth-tab0" id="auth-tab0-4"><div class="tabbed-code-labels" role="tablist"><label for="auth-tab0-1">Unity (C#)</label><label for="auth-tab0-2">Godot (GDScript)</label><label for="auth-tab0-3">Dart / Flutter / Flame</label><label for="auth-tab0-4">Defold (Lua)</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-csharp">string idToken = googleSignIn.IdToken;
var response = await asobi.Auth.OAuth("google", idToken);
// response.SessionToken is now set automatically</code></pre><pre class="tabbed-code-panel"><code class="language-gdscript">var id_token = google_sign_in.get_id_token()
var result = await asobi.auth.oauth("google", id_token)
# Session token is stored internally</code></pre><pre class="tabbed-code-panel"><code class="language-dart">final idToken = googleSignIn.currentUser!.authentication.idToken!;
final result = await asobi.auth.oauth('google', idToken);
// Session token is stored internally</code></pre><pre class="tabbed-code-panel"><code class="language-lua">local id_token = google_sign_in.get_id_token()
asobi.auth.oauth("google", id_token, function(result)
    -- Session token is stored internally
end)</code></pre></div></div>
<h2 id="next-steps" tabindex="-1">Next Steps</h2>
<ul>
<li><a href="/docs/economy">In-App Purchases</a> -- receipt validation for Apple and Google</li>
<li><a href="/docs/protocols/rest">REST API</a> -- full API reference</li>
<li><a href="/docs/protocols/websocket">WebSocket Protocol</a> -- real-time message types</li>
</ul>
"""}
    ]}.
