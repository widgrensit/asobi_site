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
<p>asobi supports username/password, OAuth/OIDC social login (Google, Apple,
Microsoft, Discord), Steam, and anonymous <a href="#guest-anonymous">guest</a> accounts a
player can later upgrade to a real one. A player can link several providers to
one account.</p>
<p>Every auth endpoint returns the same four fields: <code>player_id</code>, <code>access_token</code>
(short-lived), <code>refresh_token</code> (used against <code>/auth/refresh</code>) and <code>username</code>.
Use <code>access_token</code> as the <code>Bearer</code> credential. There is no <code>session_token</code>
field anywhere in asobi.</p>
<p>Run the <code>curl</code> examples in Git Bash or WSL on Windows, or use PowerShell's
<code>Invoke-RestMethod</code> with the same URL and a JSON <code>-Body</code>. Authenticated calls
add <code>-Headers @{ Authorization = 'Bearer &lt;token&gt;' }</code>.</p>
<h2 id="username-and-password" tabindex="-1">Username and password</h2>
<p>Register to create an account and receive a token pair:</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{&quot;username&quot;: &quot;player1&quot;, &quot;password&quot;: &quot;secret123&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;player_id&quot;: &quot;...&quot;, &quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;, &quot;username&quot;: &quot;player1&quot;}
</code></pre>
<p>Log in to get a fresh pair for an existing account:</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{&quot;username&quot;: &quot;player1&quot;, &quot;password&quot;: &quot;secret123&quot;}'
</code></pre>
<p>The response is identical. A wrong username or password answers
<code>401 auth.invalid_credentials</code>; a missing field answers <code>400 missing_field</code>.</p>
<p>Use the access token in subsequent requests:</p>
<pre><code>Authorization: Bearer &lt;access_token&gt;
</code></pre>
<h2 id="refresh-and-rotation" tabindex="-1">Refresh and rotation</h2>
<p>Access tokens are short-lived. When one expires (a <code>401</code>), exchange the refresh
token for a fresh pair at <code>/api/v1/auth/refresh</code>. Rotation is single-use: the
server burns the presented refresh token and returns a new access token and a
new refresh token, so always store both from the response.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/refresh \
  -H 'Content-Type: application/json' \
  -d '{&quot;refresh_token&quot;: &quot;&lt;refresh_token&gt;&quot;}'
# =&gt; {&quot;access_token&quot;: &quot;...&quot;, &quot;refresh_token&quot;: &quot;...&quot;}
</code></pre>
<p>The official SDKs persist the refresh token, attach the access token to every
call, and refresh-and-retry on a 401 automatically.</p>
<h2 id="logout" tabindex="-1">Logout</h2>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/logout \
  -H 'Content-Type: application/json' \
  -d '{&quot;refresh_token&quot;: &quot;&lt;refresh_token&gt;&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;success&quot;: true}
</code></pre>
<p>Passing the refresh token revokes the whole <strong>refresh family</strong> - the chain of
tokens that rotation minted from the original login, not just the one presented</p>
<ul>
<li>so a stolen older token in that chain is dead too. The access token on the
request is revoked as well.</li>
</ul>
<p>Calling it with no body still revokes the access token on the request and
answers <code>200</code>. Logging out twice is not an error.</p>
<h2 id="oauth-and-social-login" tabindex="-1">OAuth and social login</h2>
<p>The game client authenticates with the platform SDK (Google Sign-In, Apple
Sign-In and so on) to obtain an ID token, then sends it to asobi for
server-side validation.</p>
<pre><code>POST /api/v1/auth/oauth
</code></pre>
<h3 id="flow" tabindex="-1">Flow</h3>
<ol>
<li>Player taps &quot;Sign in with Google&quot; in your game</li>
<li>Platform SDK returns an ID token (JWT)</li>
<li>The game client sends the token to asobi</li>
<li>asobi validates the JWT against the provider's JWKS</li>
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
  &quot;access_token&quot;: &quot;...&quot;,
  &quot;refresh_token&quot;: &quot;...&quot;,
  &quot;username&quot;: &quot;google_abc12345_4821&quot;,
  &quot;created&quot;: true
}
</code></pre>
<p>Returning player response:</p>
<pre><code class="language-json">{
  &quot;player_id&quot;: &quot;...&quot;,
  &quot;access_token&quot;: &quot;...&quot;,
  &quot;refresh_token&quot;: &quot;...&quot;,
  &quot;username&quot;: &quot;player1&quot;
}
</code></pre>
<h3 id="error-responses" tabindex="-1">Error responses</h3>
<table>
<thead>
<tr>
<th>Status</th>
<th><code>error.code</code></th>
<th>Cause</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>400</code></td>
<td><code>missing_field</code></td>
<td><code>provider</code> or <code>token</code> absent, or not a string</td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>auth.provider_rejected</code></td>
<td>The provider rejected the token. The specific reason is in <code>details.reason</code></td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>auth.unsupported_provider</code></td>
<td><code>provider</code> is not one of the values below, or the deployment configured no provider under that name</td>
</tr>
<tr>
<td><code>403</code></td>
<td><code>auth.registration_closed</code></td>
<td>New-account registration is closed for this deployment</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>auth.already_registering</code></td>
<td>Two first-sign-ins for the same provider identity raced; retry, and the retry logs in to the account the other request created</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>auth.provider_already_linked</code></td>
<td>On <code>/auth/link</code>: that provider account already belongs to another player</td>
</tr>
<tr>
<td><code>500</code></td>
<td><code>auth.registration_failed</code></td>
<td>Account creation failed for a reason other than the race above (logged server-side)</td>
</tr>
</tbody>
</table>
<p>Every provider-side rejection collapses to <code>auth.provider_rejected</code>, whatever
went wrong. A bad signature, an expired token, a wrong audience, an unreachable
JWKS and a Steam ticket the Steam Web API refused all produce that one code,
with the distinguishing reason in <code>details.reason</code>:</p>
<pre><code class="language-json">{&quot;error&quot;: {&quot;code&quot;: &quot;auth.provider_rejected&quot;, &quot;message&quot;: &quot;...&quot;, &quot;details&quot;: {&quot;reason&quot;: &quot;invalid_token&quot;}}}
</code></pre>
<p>Branch on the code, log the reason. The reason is a server-side label - for
Steam it is lifted from Steam's own error response - so it is not part of
asobi's contract and can be reworded.</p>
<h3 id="supported-providers" tabindex="-1">Supported providers</h3>
<p>The issuer column is the value <strong>you configure</strong>, not a default: asobi ships no
OIDC provider configuration at all, so social login is entirely off until you
add <code>oidc_providers</code>. These are the well-known issuers for each provider.</p>
<table>
<thead>
<tr>
<th>Provider</th>
<th><code>provider</code> value</th>
<th>Issuer to configure</th>
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
<td>not OIDC, see <a href="#steam">Steam</a> below</td>
</tr>
</tbody>
</table>
<p>A provider entry with no <code>issuer</code>, or with an issuer that is not <code>https://</code>,
is <strong>disabled at boot</strong>. The node logs <code>oidc provider is missing issuer</code> or
<code>oidc provider has a non-https issuer</code> naming the provider, then starts
normally with that one provider dropped. You do not get an error at request
time; you get <code>401 auth.unsupported_provider</code> for a provider you believe you
configured, and the reason is in the boot log. The https rule is not optional:
asobi pins the TLS trust anchor for the discovery and JWKS fetch, and a
plaintext issuer bypasses that pin entirely.</p>
<h3 id="configuration" tabindex="-1">Configuration</h3>
<p>Add provider credentials to your <code>sys.config</code>:</p>
<pre><code class="language-erlang">{asobi, [
    {oidc_providers, #{
        google =&gt; #{
            issuer =&gt; ~&quot;https://accounts.google.com&quot;,
            client_id =&gt; ~&quot;YOUR_CLIENT_ID&quot;,
            client_secret =&gt; ~&quot;YOUR_CLIENT_SECRET&quot;
        },
        apple =&gt; #{
            issuer =&gt; ~&quot;https://appleid.apple.com&quot;,
            client_id =&gt; ~&quot;YOUR_CLIENT_ID&quot;,
            client_secret =&gt; ~&quot;YOUR_CLIENT_SECRET&quot;
        }
    }}
]}
</code></pre>
<p>The map key is an atom and the value a map; anything else is logged and
dropped. Each provider needs a client id and secret from its developer console:</p>
<ul>
<li>Google: <a href="https://console.cloud.google.com/">Google Cloud Console</a>, APIs and Services, Credentials</li>
<li>Apple: <a href="https://developer.apple.com/">Apple Developer</a>, Certificates Identifiers and Profiles, Service IDs</li>
<li>Microsoft: <a href="https://portal.azure.com/">Azure Portal</a>, App registrations</li>
<li>Discord: <a href="https://discord.com/developers/applications">Discord Developer Portal</a>, OAuth2</li>
</ul>
<h2 id="steam" tabindex="-1">Steam</h2>
<p>Steam uses session tickets instead of OIDC. The game client obtains a ticket
via <code>ISteamUser::GetAuthSessionTicket</code> and sends the hex-encoded ticket.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/oauth \
  -H 'Content-Type: application/json' \
  -d '{&quot;provider&quot;: &quot;steam&quot;, &quot;token&quot;: &quot;14000000...&quot;}'
</code></pre>
<p>asobi validates the ticket via the Steam Web API and fetches the player's
display name from their Steam profile.</p>
<h3 id="configuration-1" tabindex="-1">Configuration</h3>
<pre><code class="language-erlang">{asobi, [
    {steam_api_key, ~&quot;YOUR_STEAM_WEB_API_KEY&quot;},
    {steam_app_id, ~&quot;YOUR_STEAM_APP_ID&quot;}
]}
</code></pre>
<p>Get your API key from the <a href="https://partner.steamgames.com/">Steam Partner site</a>.</p>
<h2 id="guest-anonymous" tabindex="-1">Guest (Anonymous)</h2>
<p>Guest auth lets a player start playing immediately - no email, no password, no
social sign-in - and claim a real account later without losing progress. It is
the &quot;device-based auth&quot; option: the client generates a secret once, stores it on
the device, and presents it to resume the same account on every launch.</p>
<p>Guest auth is <strong>opt-in</strong> and disabled by default. It turns on only when two
independent parties agree (see <a href="#configuration-2">Configuration</a>): the <strong>game</strong>
declares <code>guest_auth = true</code> in its Lua config, and the <strong>operator</strong> supplies a
verifier pepper. Either one alone leaves the endpoints returning
<code>403 guest.disabled</code>.</p>
<h3 id="how-it-works" tabindex="-1">How it works</h3>
<ol>
<li>On first launch the client generates a random <code>device_secret</code> (&gt;= 32 bytes
from a CSPRNG) and a stable <code>device_id</code>, and stores both on the device
(Keychain on iOS, Keystore on Android, etc.).</li>
<li>The client posts them to <code>POST /api/v1/auth/guest</code>. asobi creates a player
and stores only a <strong>salted, peppered HMAC</strong> of the secret - never the secret
itself - then returns a token pair.</li>
<li>On later launches the client posts the same <code>device_id</code> + <code>device_secret</code>.
asobi verifies the HMAC and resumes the <strong>same</strong> player (create-or-resume).</li>
<li>When the player is ready, they call <code>POST /api/v1/auth/guest/upgrade</code> with a
username and password. The account becomes a normal password account and the
device secret is revoked.</li>
</ol>
<p>The client must treat <code>device_secret</code> like a password: generate it with a
cryptographic RNG, store it in secure device storage, and never log or transmit
it anywhere but this endpoint. A guest account is only as safe as that secret,
so it is low-assurance until upgraded.</p>
<h3 id="managing-the-device-credential" tabindex="-1">Managing the device credential</h3>
<p>You do not have to generate or store the <code>{device_id, device_secret}</code> pair by
hand. Every SDK ships a device-credential helper that handles steps 1 and 3 for
you: it generates the pair with a CSPRNG on first run, persists it in the
platform's secure/save storage, and re-presents the same pair on later
launches. Prefer the helper over rolling your own storage.</p>
<pre><code class="language-lua">-- Create-or-resume with a managed credential: generates and persists on the
-- first run, reuses it afterwards. No device_id/device_secret handling in your
-- own code.
local data, err = asobi.auth.guest_device(client)
</code></pre>
<p>The lower-level pieces are exposed too: <code>generate</code> (a fresh in-memory pair),
<code>load_or_create</code> (load the persisted pair, or make and store one on first run),
and <code>clear</code> (forget the stored pair). Sign-out keeps the pair on purpose, so the
same guest resumes on the next launch; after an upgrade the server-side verifier
is already revoked, so call <code>clear</code> to drop the now-dead local pair.</p>
<p>Names vary by SDK: <code>guest_device</code> (the snake-case SDKs), <code>guestDevice</code> (Dart and
JS), <code>GuestDevice</code>/<code>GuestDeviceAsync</code> (Unreal and Unity). See the SDK's README
for the exact name and the storage location on each platform.</p>
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
  &quot;username&quot;: &quot;guest_9c41e0b7a2d5f318&quot;,
  &quot;created&quot;: true,
  &quot;guest&quot;: true
}
</code></pre>
<p>Later calls with the same credentials resume the same player and omit <code>created</code>.
A wrong secret for a known <code>device_id</code> returns <code>401 guest.invalid_device_secret</code>
and never creates a second account.</p>
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
<th><code>error.code</code></th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>400</code></td>
<td><code>missing_field</code></td>
<td><code>device_id</code> / <code>device_secret</code> (or <code>username</code> / <code>password</code> on upgrade) absent</td>
</tr>
<tr>
<td><code>400</code></td>
<td><code>guest.weak_device_secret</code></td>
<td>Secret decodes to fewer than 32 bytes (or exceeds the size cap)</td>
</tr>
<tr>
<td><code>400</code></td>
<td><code>guest.invalid_device_id</code></td>
<td><code>device_id</code> empty or over 255 bytes</td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>guest.invalid_device_secret</code></td>
<td>Wrong secret for a known device</td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>guest.revoked</code></td>
<td>The device verifier was revoked</td>
</tr>
<tr>
<td><code>401</code></td>
<td><code>guest.already_upgraded</code></td>
<td>The account was already claimed; log in with its real credentials</td>
</tr>
<tr>
<td><code>403</code></td>
<td><code>guest.disabled</code></td>
<td>Guest auth is off - the game did not declare <code>guest_auth</code>, or no pepper is present</td>
</tr>
<tr>
<td><code>403</code></td>
<td><code>auth.registration_closed</code></td>
<td>The deployment's registration posture refuses new accounts</td>
</tr>
<tr>
<td><code>403</code></td>
<td><code>auth.password_registration_disabled</code></td>
<td>From the shared registration guard. A closed deployment answers <code>auth.registration_closed</code> on the guest paths, so you should not see this one here</td>
</tr>
<tr>
<td><code>404</code></td>
<td><code>player.not_found</code></td>
<td>The upgrade token resolves to no player</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>guest.device_already_registered</code></td>
<td>Two creates for the same device raced; retry - the retry resumes the existing guest</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>guest.not_unclaimed</code></td>
<td>Upgrade target is not an unclaimed guest</td>
</tr>
<tr>
<td><code>409</code></td>
<td><code>auth.username_taken</code></td>
<td>Upgrade username is already in use</td>
</tr>
<tr>
<td><code>422</code></td>
<td><code>validation_failed</code></td>
<td>On upgrade: the new username or password failed validation. <code>details.fields</code> is per-field, for a form UI</td>
</tr>
<tr>
<td><code>500</code></td>
<td><code>guest.create_failed</code></td>
<td>The player row could not be created</td>
</tr>
<tr>
<td><code>500</code></td>
<td><code>internal</code></td>
<td>The device resolves to an identity whose player no longer exists, or another server-side failure</td>
</tr>
<tr>
<td><code>503</code></td>
<td><code>guest.capacity_reached</code></td>
<td>Global create limit or the unlinked-guest cap was hit</td>
</tr>
</tbody>
</table>
<h3 id="configuration-2" tabindex="-1">Configuration</h3>
<p>Guest auth is on only if both halves below are satisfied; either alone fails
closed with <code>403 guest.disabled</code>. The toggle belongs to the game, the pepper to
the operator (ADR 0004).</p>
<p><strong>1. The game declares the toggle.</strong> <code>guest_auth</code> is a boolean game global,
declared like <code>match_size</code> - in <code>match.lua</code> for a single-mode game, or
<code>config.lua</code> for a multi-mode game:</p>
<pre><code class="language-lua">guest_auth = true
</code></pre>
<p><strong>2. The operator supplies the pepper</strong> and any abuse controls:</p>
<pre><code class="language-erlang">{asobi, [
    %% Required. A key-id -&gt; pepper map, each pepper &gt;= 32 bytes. Keep old key
    %% ids for the guest retention window so existing guests still resume
    %% after a rotation.
    {guest_verifier_pepper, #{~&quot;v1&quot; =&gt; ~&quot;a-32-byte-or-longer-secret......&quot;}},
    {guest_verifier_key_id, ~&quot;v1&quot;},

    %% Optional abuse controls.
    {guest_unlinked_cap, 100000},        %% max unclaimed guests, or `infinity`

    %% Optional retention. Unset = permanent guests (never reaped). A number of
    %% seconds deletes unclaimed guests not seen for that long. Inactivity, not
    %% account age: a device that keeps resuming keeps its player forever.
    {guest_reap_after, 2592000}          %% e.g. 30 days since last resume
]}
</code></pre>
<p>A bare binary is accepted too, as shorthand for a single key: with
<code>{guest_verifier_pepper, ~&quot;a-32-byte-or-longer-secret......&quot;}</code> every verifier
uses it whatever key id is recorded. Prefer the map, because the bare form has
no way to rotate.</p>
<p><code>guest_verifier_key_id</code> defaults to <code>~&quot;v1&quot;</code>, so a map keyed <code>~&quot;v1&quot;</code> needs no
second setting. A pepper under 32 bytes is treated as absent and guest auth
stays off.</p>
<p><strong><code>guest_verifier_pepper</code> in <code>sys.config</code> is the only mechanism that works.</strong>
The image declares an <code>ASOBI_GUEST_VERIFIER_PEPPER</code> environment variable, but
nothing substitutes it into the rendered configuration and nothing reads it: a
deployment that sets only that variable gets <code>403 guest.disabled</code> on every
guest call, forever. Set the <code>sys.config</code> key.</p>
<p>The pepper is a server-side secret that makes a stolen table of verifiers
useless without it, so keep it out of source and out of your game bundle. Guest
creation is additionally bounded by a global rate limiter and the per-IP auth
limiter.</p>
<h2 id="linking-providers" tabindex="-1">Linking providers</h2>
<p>A player can link additional providers to an existing account and then sign in
from any of them.</p>
<h3 id="link-a-provider" tabindex="-1">Link a provider</h3>
<p>Requires an authenticated session.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/auth/link \
  -H 'Authorization: Bearer &lt;access_token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;provider&quot;: &quot;discord&quot;, &quot;token&quot;: &quot;eyJhbGciOi...&quot;}'
</code></pre>
<pre><code class="language-json">{&quot;provider&quot;: &quot;discord&quot;, &quot;provider_uid&quot;: &quot;123456789&quot;, &quot;linked&quot;: true}
</code></pre>
<p>A provider account already linked to someone else answers
<code>409 auth.provider_already_linked</code>.</p>
<h3 id="unlink-a-provider" tabindex="-1">Unlink a provider</h3>
<p><strong>The provider goes in the query string, not the body.</strong> A <code>DELETE</code> carrying a
JSON body is not read at all and answers <code>400 missing_field</code>.</p>
<pre><code class="language-bash">curl -X DELETE 'http://localhost:8084/api/v1/auth/unlink?provider=discord' \
  -H 'Authorization: Bearer &lt;access_token&gt;'
</code></pre>
<pre><code class="language-json">{&quot;success&quot;: true}
</code></pre>
<p>asobi refuses to unlink the last auth method, so a player cannot lock
themselves out: if the account has no password and no other linked provider,
the call answers <code>422 auth.last_auth_method</code>. An unlinked provider answers
<code>404 auth.identity_not_found</code>.</p>
<h2 id="websocket-authentication" tabindex="-1">WebSocket authentication</h2>
<p>After obtaining an access token from any auth method, connect to the WebSocket
and authenticate:</p>
<pre><code class="language-json">{
  &quot;type&quot;: &quot;session.connect&quot;,
  &quot;payload&quot;: {&quot;token&quot;: &quot;&lt;access_token&gt;&quot;}
}
</code></pre>
<p>The token works the same regardless of which provider issued it.</p>
<h2 id="sdk-integration" tabindex="-1">SDK integration</h2>
<p>Every SDK wraps these routes, stores the token pair and refreshes it on a 401.
The platform SDK returns an ID token; hand it to <code>auth.oauth</code> with the provider
name. See your SDK's README for the exact method names and the device-credential
helper covered under <a href="#guest-anonymous">Guest</a>.</p>
<h2 id="inspecting-players" tabindex="-1">Inspecting players</h2>
<p>The console has a Players screen, searchable by username and display name. It
shows the ops projection only: <code>id</code>, <code>username</code>, <code>display_name</code>, <code>avatar_url</code>,
<code>metadata</code>, <code>inserted_at</code> and <code>updated_at</code>. It does not show linked providers,
guest status, device verifiers or tokens, and it cannot ban, reset a password,
revoke a session or unlink anything - the ops plane is reads. See
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/economy">In-app purchases</a> - receipt validation for Apple and Google</li>
<li><a href="/docs/protocols/rest">REST API</a> - full API reference</li>
<li><a href="/docs/protocols/websocket">WebSocket protocol</a> - real-time message types</li>
</ul>
"""}
    ]}.
