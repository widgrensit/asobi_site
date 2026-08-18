%% GENERATED from asobi guides/authentication.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_auth_view).

-export([mount/1, render/1, markdown/0]).

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
<p>Because the pair identifies the device, two clients started on one machine share
it and resume the <em>same</em> player. That is correct behaviour and it is also the
first thing to trip over when testing multiplayer locally. See
<a href="/docs/tools/multiple-players">Testing with multiple players</a> for the ways round
it.</p>
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
<h3 id="delete-the-account" tabindex="-1">Delete the account</h3>
<p>Guest removal is not a guest route. <code>POST /api/v1/players/me/erase</code> erases the
calling player whatever kind of account it is, and a guest is simply the case
with no credential to re-confirm. See
<a href="/docs/protocols/rest#erasing-your-own-account">Erasing your own account</a> for the
contract; the guest-specific part is only that no <code>password</code> is required,
because a guest has none.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/players/me/erase \
  -H 'Authorization: Bearer &lt;access_token&gt;' \
  -H 'Content-Type: application/json' -d '{}'
</code></pre>
<p>It is the only erasure path that needs no operator credential at all - the
player's own token is the authority. A cloud tenant reaches the ops erasure
routes as well, through a console token minted for an <code>owner</code> or <code>admin</code>, and
sets <code>guest_reap_after</code> from the environment's <strong>Guests</strong> picker on the
dashboard.</p>
<p><strong>A device secret is now a destruction credential, not just an impersonation
one.</strong> Anyone holding it can resume the account and erase it, with no password
to stop them, because there is no password. That is a deliberate trade - the
alternative is a guest who can never delete their account - but it raises the
bar on where a shipping client stores the pair: treat it the way you would treat
a password, not a cache key.</p>
<p>A device pair written to disk once and reused does not need this route at all,
and that is what a shipping client should do. A fresh pair per launch is a
testing trick (see <a href="/docs/tools/multiple-players">Testing with multiple
players</a>), and it is the pattern that accumulates
accounts.</p>
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
<td><code>429</code></td>
<td><code>guest.rate_limited</code></td>
<td>The deployment-wide guest-create limiter is saturated. <code>details.retry_after</code> is seconds; retry then</td>
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
<td>The unlinked-guest cap is reached. Raise <code>guest_unlinked_cap</code>, set <code>guest_reap_after</code>, or have clients delete guests they abandon</td>
</tr>
<tr>
<td><code>503</code></td>
<td><code>guest.unavailable</code></td>
<td>The node could not count existing guests, so it refused rather than create without a bound. Not a full deployment - look for a database fault, and check the <code>guest_create_denied</code> log line</td>
</tr>
</tbody>
</table>
<p>The three refusals above are deliberately distinct. Until asobi#419 they shared
<code>guest.capacity_reached</code>, which reported a transient database fault as a
deployment that was full and gave an operator nothing to act on. Every denial
now logs <code>guest_create_denied</code> with a <code>reason</code> and, for the cap, the <code>count</code>
and <code>cap</code> it compared.</p>
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

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Authentication

asobi supports username/password, OAuth/OIDC social login (Google, Apple,
Microsoft, Discord), Steam, and anonymous [guest](#guest-anonymous) accounts a
player can later upgrade to a real one. A player can link several providers to
one account.

Every auth endpoint returns the same four fields: `player_id`, `access_token`
(short-lived), `refresh_token` (used against `/auth/refresh`) and `username`.
Use `access_token` as the `Bearer` credential. There is no `session_token`
field anywhere in asobi.

Run the `curl` examples in Git Bash or WSL on Windows, or use PowerShell's
`Invoke-RestMethod` with the same URL and a JSON `-Body`. Authenticated calls
add `-Headers @{ Authorization = 'Bearer <token>' }`.

## Username and password

Register to create an account and receive a token pair:

```bash
curl -X POST http://localhost:8084/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username": "player1", "password": "secret123"}'
```

```json
{"player_id": "...", "access_token": "...", "refresh_token": "...", "username": "player1"}
```

Log in to get a fresh pair for an existing account:

```bash
curl -X POST http://localhost:8084/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username": "player1", "password": "secret123"}'
```

The response is identical. A wrong username or password answers
`401 auth.invalid_credentials`; a missing field answers `400 missing_field`.

Use the access token in subsequent requests:

```
Authorization: Bearer <access_token>
```

## Refresh and rotation

Access tokens are short-lived. When one expires (a `401`), exchange the refresh
token for a fresh pair at `/api/v1/auth/refresh`. Rotation is single-use: the
server burns the presented refresh token and returns a new access token and a
new refresh token, so always store both from the response.

```bash
curl -X POST http://localhost:8084/api/v1/auth/refresh \
  -H 'Content-Type: application/json' \
  -d '{"refresh_token": "<refresh_token>"}'
# => {"access_token": "...", "refresh_token": "..."}
```

The official SDKs persist the refresh token, attach the access token to every
call, and refresh-and-retry on a 401 automatically.

## Logout

```bash
curl -X POST http://localhost:8084/api/v1/auth/logout \
  -H 'Content-Type: application/json' \
  -d '{"refresh_token": "<refresh_token>"}'
```

```json
{"success": true}
```

Passing the refresh token revokes the whole **refresh family** - the chain of
tokens that rotation minted from the original login, not just the one presented
- so a stolen older token in that chain is dead too. The access token on the
request is revoked as well.

Calling it with no body still revokes the access token on the request and
answers `200`. Logging out twice is not an error.

## OAuth and social login

The game client authenticates with the platform SDK (Google Sign-In, Apple
Sign-In and so on) to obtain an ID token, then sends it to asobi for
server-side validation.

```
POST /api/v1/auth/oauth
```

### Flow

1. Player taps "Sign in with Google" in your game
2. Platform SDK returns an ID token (JWT)
3. The game client sends the token to asobi
4. asobi validates the JWT against the provider's JWKS
5. If the identity exists, the player is logged in
6. If not, a new player account is created and linked

### Example

```bash
curl -X POST http://localhost:8084/api/v1/auth/oauth \
  -H 'Content-Type: application/json' \
  -d '{"provider": "google", "token": "eyJhbGciOiJSUzI1NiIs..."}'
```

First-time response (new account created):

```json
{
  "player_id": "...",
  "access_token": "...",
  "refresh_token": "...",
  "username": "google_abc12345_4821",
  "created": true
}
```

Returning player response:

```json
{
  "player_id": "...",
  "access_token": "...",
  "refresh_token": "...",
  "username": "player1"
}
```

### Error responses

| Status | `error.code` | Cause |
|---|---|---|
| `400` | `missing_field` | `provider` or `token` absent, or not a string |
| `401` | `auth.provider_rejected` | The provider rejected the token. The specific reason is in `details.reason` |
| `401` | `auth.unsupported_provider` | `provider` is not one of the values below, or the deployment configured no provider under that name |
| `403` | `auth.registration_closed` | New-account registration is closed for this deployment |
| `409` | `auth.already_registering` | Two first-sign-ins for the same provider identity raced; retry, and the retry logs in to the account the other request created |
| `409` | `auth.provider_already_linked` | On `/auth/link`: that provider account already belongs to another player |
| `500` | `auth.registration_failed` | Account creation failed for a reason other than the race above (logged server-side) |

Every provider-side rejection collapses to `auth.provider_rejected`, whatever
went wrong. A bad signature, an expired token, a wrong audience, an unreachable
JWKS and a Steam ticket the Steam Web API refused all produce that one code,
with the distinguishing reason in `details.reason`:

```json
{"error": {"code": "auth.provider_rejected", "message": "...", "details": {"reason": "invalid_token"}}}
```

Branch on the code, log the reason. The reason is a server-side label - for
Steam it is lifted from Steam's own error response - so it is not part of
asobi's contract and can be reworded.

### Supported providers

The issuer column is the value **you configure**, not a default: asobi ships no
OIDC provider configuration at all, so social login is entirely off until you
add `oidc_providers`. These are the well-known issuers for each provider.

| Provider | `provider` value | Issuer to configure |
|---|---|---|
| Google | `"google"` | `https://accounts.google.com` |
| Apple | `"apple"` | `https://appleid.apple.com` |
| Microsoft | `"microsoft"` | `https://login.microsoftonline.com/common/v2.0` |
| Discord | `"discord"` | `https://discord.com` |
| Steam | `"steam"` | not OIDC, see [Steam](#steam) below |

A provider entry with no `issuer`, or with an issuer that is not `https://`,
is **disabled at boot**. The node logs `oidc provider is missing issuer` or
`oidc provider has a non-https issuer` naming the provider, then starts
normally with that one provider dropped. You do not get an error at request
time; you get `401 auth.unsupported_provider` for a provider you believe you
configured, and the reason is in the boot log. The https rule is not optional:
asobi pins the TLS trust anchor for the discovery and JWKS fetch, and a
plaintext issuer bypasses that pin entirely.

### Configuration

Add provider credentials to your `sys.config`:

```erlang
{asobi, [
    {oidc_providers, #{
        google => #{
            issuer => ~"https://accounts.google.com",
            client_id => ~"YOUR_CLIENT_ID",
            client_secret => ~"YOUR_CLIENT_SECRET"
        },
        apple => #{
            issuer => ~"https://appleid.apple.com",
            client_id => ~"YOUR_CLIENT_ID",
            client_secret => ~"YOUR_CLIENT_SECRET"
        }
    }}
]}
```

The map key is an atom and the value a map; anything else is logged and
dropped. Each provider needs a client id and secret from its developer console:

- Google: [Google Cloud Console](https://console.cloud.google.com/), APIs and Services, Credentials
- Apple: [Apple Developer](https://developer.apple.com/), Certificates Identifiers and Profiles, Service IDs
- Microsoft: [Azure Portal](https://portal.azure.com/), App registrations
- Discord: [Discord Developer Portal](https://discord.com/developers/applications), OAuth2

## Steam

Steam uses session tickets instead of OIDC. The game client obtains a ticket
via `ISteamUser::GetAuthSessionTicket` and sends the hex-encoded ticket.

```bash
curl -X POST http://localhost:8084/api/v1/auth/oauth \
  -H 'Content-Type: application/json' \
  -d '{"provider": "steam", "token": "14000000..."}'
```

asobi validates the ticket via the Steam Web API and fetches the player's
display name from their Steam profile.

### Configuration

```erlang
{asobi, [
    {steam_api_key, ~"YOUR_STEAM_WEB_API_KEY"},
    {steam_app_id, ~"YOUR_STEAM_APP_ID"}
]}
```

Get your API key from the [Steam Partner site](https://partner.steamgames.com/).

## Guest (Anonymous)

Guest auth lets a player start playing immediately - no email, no password, no
social sign-in - and claim a real account later without losing progress. It is
the "device-based auth" option: the client generates a secret once, stores it on
the device, and presents it to resume the same account on every launch.

Guest auth is **opt-in** and disabled by default. It turns on only when two
independent parties agree (see [Configuration](#configuration-2)): the **game**
declares `guest_auth = true` in its Lua config, and the **operator** supplies a
verifier pepper. Either one alone leaves the endpoints returning
`403 guest.disabled`.

### How it works

1. On first launch the client generates a random `device_secret` (>= 32 bytes
   from a CSPRNG) and a stable `device_id`, and stores both on the device
   (Keychain on iOS, Keystore on Android, etc.).
2. The client posts them to `POST /api/v1/auth/guest`. asobi creates a player
   and stores only a **salted, peppered HMAC** of the secret - never the secret
   itself - then returns a token pair.
3. On later launches the client posts the same `device_id` + `device_secret`.
   asobi verifies the HMAC and resumes the **same** player (create-or-resume).
4. When the player is ready, they call `POST /api/v1/auth/guest/upgrade` with a
   username and password. The account becomes a normal password account and the
   device secret is revoked.

The client must treat `device_secret` like a password: generate it with a
cryptographic RNG, store it in secure device storage, and never log or transmit
it anywhere but this endpoint. A guest account is only as safe as that secret,
so it is low-assurance until upgraded.

### Managing the device credential

You do not have to generate or store the `{device_id, device_secret}` pair by
hand. Every SDK ships a device-credential helper that handles steps 1 and 3 for
you: it generates the pair with a CSPRNG on first run, persists it in the
platform's secure/save storage, and re-presents the same pair on later
launches. Prefer the helper over rolling your own storage.

```lua
-- Create-or-resume with a managed credential: generates and persists on the
-- first run, reuses it afterwards. No device_id/device_secret handling in your
-- own code.
local data, err = asobi.auth.guest_device(client)
```

The lower-level pieces are exposed too: `generate` (a fresh in-memory pair),
`load_or_create` (load the persisted pair, or make and store one on first run),
and `clear` (forget the stored pair). Sign-out keeps the pair on purpose, so the
same guest resumes on the next launch; after an upgrade the server-side verifier
is already revoked, so call `clear` to drop the now-dead local pair.

Names vary by SDK: `guest_device` (the snake-case SDKs), `guestDevice` (Dart and
JS), `GuestDevice`/`GuestDeviceAsync` (Unreal and Unity). See the SDK's README
for the exact name and the storage location on each platform.

Because the pair identifies the device, two clients started on one machine share
it and resume the *same* player. That is correct behaviour and it is also the
first thing to trip over when testing multiplayer locally. See
[Testing with multiple players](https://asobi.dev/docs/tools/multiple-players) for the ways round
it.

### Create or resume

```bash
curl -X POST http://localhost:8084/api/v1/auth/guest \
  -H 'Content-Type: application/json' \
  -d '{"device_id": "b64-device-id", "device_secret": "b64-32-random-bytes"}'
```

First call (new account):

```json
{
  "player_id": "...",
  "access_token": "...",
  "refresh_token": "...",
  "username": "guest_9c41e0b7a2d5f318",
  "created": true,
  "guest": true
}
```

Later calls with the same credentials resume the same player and omit `created`.
A wrong secret for a known `device_id` returns `401 guest.invalid_device_secret`
and never creates a second account.

### Upgrade to a real account

Requires the guest's own session (the token from the create-or-resume call).
Only an unclaimed guest may upgrade - a password account, or an account with a
non-guest provider, is refused.

```bash
curl -X POST http://localhost:8084/api/v1/auth/guest/upgrade \
  -H 'Authorization: Bearer <access_token>' \
  -H 'Content-Type: application/json' \
  -d '{"username": "player1", "password": "secret123"}'
```

```json
{
  "player_id": "...",
  "access_token": "...",
  "refresh_token": "...",
  "username": "player1",
  "upgraded": true
}
```

Upgrade revokes every token the guest held (a fresh pair is returned) and
deletes the device verifier, so the old device secret can no longer sign in.
Player id, progress, wallets, and inventory are preserved.

### Delete the account

Guest removal is not a guest route. `POST /api/v1/players/me/erase` erases the
calling player whatever kind of account it is, and a guest is simply the case
with no credential to re-confirm. See
[Erasing your own account](https://asobi.dev/docs/protocols/rest#erasing-your-own-account) for the
contract; the guest-specific part is only that no `password` is required,
because a guest has none.

```bash
curl -X POST http://localhost:8084/api/v1/players/me/erase \
  -H 'Authorization: Bearer <access_token>' \
  -H 'Content-Type: application/json' -d '{}'
```

It is the only erasure path that needs no operator credential at all - the
player's own token is the authority. A cloud tenant reaches the ops erasure
routes as well, through a console token minted for an `owner` or `admin`, and
sets `guest_reap_after` from the environment's **Guests** picker on the
dashboard.

**A device secret is now a destruction credential, not just an impersonation
one.** Anyone holding it can resume the account and erase it, with no password
to stop them, because there is no password. That is a deliberate trade - the
alternative is a guest who can never delete their account - but it raises the
bar on where a shipping client stores the pair: treat it the way you would treat
a password, not a cache key.

A device pair written to disk once and reused does not need this route at all,
and that is what a shipping client should do. A fresh pair per launch is a
testing trick (see [Testing with multiple
players](https://asobi.dev/docs/tools/multiple-players)), and it is the pattern that accumulates
accounts.

### Errors

| Status | `error.code` | Meaning |
|--------|--------------|---------|
| `400`  | `missing_field`                    | `device_id` / `device_secret` (or `username` / `password` on upgrade) absent |
| `400`  | `guest.weak_device_secret`         | Secret decodes to fewer than 32 bytes (or exceeds the size cap) |
| `400`  | `guest.invalid_device_id`          | `device_id` empty or over 255 bytes |
| `401`  | `guest.invalid_device_secret`      | Wrong secret for a known device |
| `401`  | `guest.revoked`                    | The device verifier was revoked |
| `401`  | `guest.already_upgraded`           | The account was already claimed; log in with its real credentials |
| `403`  | `guest.disabled`                   | Guest auth is off - the game did not declare `guest_auth`, or no pepper is present |
| `403`  | `auth.registration_closed`         | The deployment's registration posture refuses new accounts |
| `403`  | `auth.password_registration_disabled` | From the shared registration guard. A closed deployment answers `auth.registration_closed` on the guest paths, so you should not see this one here |
| `404`  | `player.not_found`                 | The upgrade token resolves to no player |
| `409`  | `guest.device_already_registered`  | Two creates for the same device raced; retry - the retry resumes the existing guest |
| `409`  | `guest.not_unclaimed`              | Upgrade target is not an unclaimed guest |
| `409`  | `auth.username_taken`              | Upgrade username is already in use |
| `422`  | `validation_failed`                | On upgrade: the new username or password failed validation. `details.fields` is per-field, for a form UI |
| `429`  | `guest.rate_limited`               | The deployment-wide guest-create limiter is saturated. `details.retry_after` is seconds; retry then |
| `500`  | `guest.create_failed`              | The player row could not be created |
| `500`  | `internal`                         | The device resolves to an identity whose player no longer exists, or another server-side failure |
| `503`  | `guest.capacity_reached`           | The unlinked-guest cap is reached. Raise `guest_unlinked_cap`, set `guest_reap_after`, or have clients delete guests they abandon |
| `503`  | `guest.unavailable`                | The node could not count existing guests, so it refused rather than create without a bound. Not a full deployment - look for a database fault, and check the `guest_create_denied` log line |

The three refusals above are deliberately distinct. Until asobi#419 they shared
`guest.capacity_reached`, which reported a transient database fault as a
deployment that was full and gave an operator nothing to act on. Every denial
now logs `guest_create_denied` with a `reason` and, for the cap, the `count`
and `cap` it compared.

### Configuration

Guest auth is on only if both halves below are satisfied; either alone fails
closed with `403 guest.disabled`. The toggle belongs to the game, the pepper to
the operator (ADR 0004).

**1. The game declares the toggle.** `guest_auth` is a boolean game global,
declared like `match_size` - in `match.lua` for a single-mode game, or
`config.lua` for a multi-mode game:

```lua
guest_auth = true
```

**2. The operator supplies the pepper** and any abuse controls:

```erlang
{asobi, [
    %% Required. A key-id -> pepper map, each pepper >= 32 bytes. Keep old key
    %% ids for the guest retention window so existing guests still resume
    %% after a rotation.
    {guest_verifier_pepper, #{~"v1" => ~"a-32-byte-or-longer-secret......"}},
    {guest_verifier_key_id, ~"v1"},

    %% Optional abuse controls.
    {guest_unlinked_cap, 100000},        %% max unclaimed guests, or `infinity`

    %% Optional retention. Unset = permanent guests (never reaped). A number of
    %% seconds deletes unclaimed guests not seen for that long. Inactivity, not
    %% account age: a device that keeps resuming keeps its player forever.
    {guest_reap_after, 2592000}          %% e.g. 30 days since last resume
]}
```

A bare binary is accepted too, as shorthand for a single key: with
`{guest_verifier_pepper, ~"a-32-byte-or-longer-secret......"}` every verifier
uses it whatever key id is recorded. Prefer the map, because the bare form has
no way to rotate.

`guest_verifier_key_id` defaults to `~"v1"`, so a map keyed `~"v1"` needs no
second setting. A pepper under 32 bytes is treated as absent and guest auth
stays off.

**`guest_verifier_pepper` in `sys.config` is the only mechanism that works.**
The image declares an `ASOBI_GUEST_VERIFIER_PEPPER` environment variable, but
nothing substitutes it into the rendered configuration and nothing reads it: a
deployment that sets only that variable gets `403 guest.disabled` on every
guest call, forever. Set the `sys.config` key.

The pepper is a server-side secret that makes a stolen table of verifiers
useless without it, so keep it out of source and out of your game bundle. Guest
creation is additionally bounded by a global rate limiter and the per-IP auth
limiter.

## Linking providers

A player can link additional providers to an existing account and then sign in
from any of them.

### Link a provider

Requires an authenticated session.

```bash
curl -X POST http://localhost:8084/api/v1/auth/link \
  -H 'Authorization: Bearer <access_token>' \
  -H 'Content-Type: application/json' \
  -d '{"provider": "discord", "token": "eyJhbGciOi..."}'
```

```json
{"provider": "discord", "provider_uid": "123456789", "linked": true}
```

A provider account already linked to someone else answers
`409 auth.provider_already_linked`.

### Unlink a provider

**The provider goes in the query string, not the body.** A `DELETE` carrying a
JSON body is not read at all and answers `400 missing_field`.

```bash
curl -X DELETE 'http://localhost:8084/api/v1/auth/unlink?provider=discord' \
  -H 'Authorization: Bearer <access_token>'
```

```json
{"success": true}
```

asobi refuses to unlink the last auth method, so a player cannot lock
themselves out: if the account has no password and no other linked provider,
the call answers `422 auth.last_auth_method`. An unlinked provider answers
`404 auth.identity_not_found`.

## WebSocket authentication

After obtaining an access token from any auth method, connect to the WebSocket
and authenticate:

```json
{
  "type": "session.connect",
  "payload": {"token": "<access_token>"}
}
```

The token works the same regardless of which provider issued it.

## SDK integration

Every SDK wraps these routes, stores the token pair and refreshes it on a 401.
The platform SDK returns an ID token; hand it to `auth.oauth` with the provider
name. See your SDK's README for the exact method names and the device-credential
helper covered under [Guest](#guest-anonymous).

## Inspecting players

The console has a Players screen, searchable by username and display name. It
shows the ops projection only: `id`, `username`, `display_name`, `avatar_url`,
`metadata`, `inserted_at` and `updated_at`. It does not show linked providers,
guest status, device verifiers or tokens, and it cannot ban, reset a password,
revoke a session or unlink anything - the ops plane is reads. See
[Operator console](https://hexdocs.pm/asobi/console.html).

## Next steps

- [In-app purchases](https://asobi.dev/docs/economy) - receipt validation for Apple and Google
- [REST API](https://asobi.dev/docs/protocols/rest) - full API reference
- [WebSocket protocol](https://asobi.dev/docs/protocols/websocket) - real-time message types
""".
