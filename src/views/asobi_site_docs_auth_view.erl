-module(asobi_site_docs_auth_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-auth", title => ~"Authentication — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Authentication"
            ]},
            {h1, [], [~"Authentication"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi supports username/password, ",
                {a, [{href, ~"#guest-anonymous"}], [~"guest (anonymous)"]},
                ~" accounts a player can upgrade later, OAuth/OIDC social login (Google, Apple, Microsoft, Discord), and Steam. ",
                ~"Players can link multiple providers to a single account."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Windows. "]},
                    ~"Run the ",
                    {code, [], [~"curl"]},
                    ~" examples in Git Bash or WSL, or use PowerShell's ",
                    {code, [], [~"Invoke-RestMethod"]},
                    ~" with the same URL and a JSON ",
                    {code, [], [~"-Body"]},
                    ~"; it parses the response for you. Authenticated calls add ",
                    {code, [], [~"-Headers @{ Authorization = 'Bearer <token>' }"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"Username & password"]},
            {p, [], [
                ~"The simplest method. Register to receive an access token and a refresh token:"
            ]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8084/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username": "player1", "password": "secret123"}'
"""
            ),
            code(
                ~"json",
                ~"""
{"player_id": "...", "access_token": "...", "refresh_token": "...", "username": "player1"}
"""
            ),
            {p, [], [~"Use the access token in subsequent REST calls:"]},
            code(
                ~"http",
                ~"""
Authorization: Bearer <access_token>
"""
            ),
            {p, [], [~"Login reuses the same shape at ", {code, [], [~"/api/v1/auth/login"]}, ~"."]},

            {h2, [], [~"Refresh & rotation"]},
            {p, [], [
                ~"Access tokens are short-lived. When one expires (a ",
                {code, [], [~"401"]},
                ~"), exchange the refresh token for a fresh pair at ",
                {code, [], [~"/api/v1/auth/refresh"]},
                ~". Rotation is single-use: the server burns the presented refresh token and returns a new access token ",
                {em, [], [~"and"]},
                ~" a new refresh token, so always store both from the response."
            ]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8084/api/v1/auth/refresh \
  -H 'Content-Type: application/json' \
  -d '{"refresh_token": "<refresh_token>"}'
# => {"access_token": "...", "refresh_token": "..."}
"""
            ),
            {p, [], [
                ~"The official SDKs persist the refresh token, attach the access token to every call, and refresh-and-retry on a 401 automatically."
            ]},

            {h2, [{id, ~"guest-anonymous"}], [~"Guest (anonymous)"]},
            {p, [], [
                ~"Guest auth lets a player start playing immediately - no email, no password, no social sign-in - and claim a real account later without losing progress. ",
                ~"It is the device-based option: the client generates a secret once, stores it on the device, and presents it to resume the same account on every launch."
            ]},
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Opt-in. "]},
                    ~"Guest auth is disabled by default. Both endpoints return ",
                    {code, [], [~"404 guest_auth_disabled"]},
                    ~" until you set ",
                    {code, [], [~"guest_auth"]},
                    ~" and a ",
                    {code, [], [~"guest_verifier_pepper"]},
                    ~" in ",
                    {code, [], [~"sys.config"]},
                    ~" - see ",
                    {a, [{href, ~"/docs/configuration#guest-auth"}, az_navigate], [
                        ~"Configuration"
                    ]},
                    ~"."
                ]}
            ]},

            {h3, [], [~"How it works"]},
            {ol, [], [
                {li, [], [
                    ~"On first launch the client generates a random ",
                    {code, [], [~"device_secret"]},
                    ~" (at least 32 bytes from a CSPRNG) and a stable ",
                    {code, [], [~"device_id"]},
                    ~", and stores both in secure device storage (Keychain on iOS, Keystore on Android)."
                ]},
                {li, [], [
                    ~"The client posts them to ",
                    {code, [], [~"POST /api/v1/auth/guest"]},
                    ~". Asobi creates a player, stores only a salted, peppered HMAC of the secret - never the secret itself - and returns a token pair."
                ]},
                {li, [], [
                    ~"On later launches the client posts the same pair. Asobi verifies the HMAC and resumes the ",
                    {em, [], [~"same"]},
                    ~" player (create-or-resume)."
                ]},
                {li, [], [
                    ~"When the player is ready, they call ",
                    {code, [], [~"POST /api/v1/auth/guest/upgrade"]},
                    ~" with a username and password. The account becomes a normal password account and the device secret is revoked."
                ]}
            ]},
            {p, [], [
                ~"Treat ",
                {code, [], [~"device_secret"]},
                ~" like a password: generate it with a cryptographic RNG, keep it in secure storage, and never log it or send it anywhere but this endpoint. ",
                ~"A guest account is only as safe as that secret, so it stays low-assurance until upgraded."
            ]},

            {h3, [], [~"Create or resume"]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8084/api/v1/auth/guest \
  -H 'Content-Type: application/json' \
  -d '{"device_id": "b64-device-id", "device_secret": "b64-32-random-bytes"}'
"""
            ),
            {p, [], [~"First call (new account):"]},
            code(
                ~"json",
                ~"""
{
  "player_id": "...",
  "access_token": "...",
  "refresh_token": "...",
  "username": "guest_019f615cbc4a",
  "created": true,
  "guest": true
}
"""
            ),
            {p, [], [
                ~"Later calls with the same credentials resume the same player and omit ",
                {code, [], [~"created"]},
                ~". A wrong secret for a known ",
                {code, [], [~"device_id"]},
                ~" returns ",
                {code, [], [~"401 invalid_device_secret"]},
                ~" and never creates a second account."
            ]},

            {h3, [], [~"Upgrade to a real account"]},
            {p, [], [
                ~"Requires the guest's own session (the token from the create-or-resume call). Only an unclaimed guest may upgrade - a password account, or an account with a non-guest provider, is refused."
            ]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8084/api/v1/auth/guest/upgrade \
  -H 'Authorization: Bearer <access_token>' \
  -H 'Content-Type: application/json' \
  -d '{"username": "player1", "password": "secret123"}'
"""
            ),
            code(
                ~"json",
                ~"""
{
  "player_id": "...",
  "access_token": "...",
  "refresh_token": "...",
  "username": "player1",
  "upgraded": true
}
"""
            ),
            {p, [], [
                ~"Upgrade revokes every token the guest held (the fresh pair above replaces them) and deletes the device verifier, so the old device secret can no longer sign in. ",
                ~"Player id, progress, wallets, and inventory are preserved."
            ]},

            {h3, [], [~"Errors"]},
            {'div', [{class, ~"docs-api"}], [
                {pre, [], [
                    {code, [], [
                        ~"""
 Status | error                   | Meaning
--------|-------------------------|--------------------------------------------------
 400    | missing_required_fields | device_id / device_secret (or username / password
        |                         | on upgrade) absent
 400    | weak_device_secret      | Secret decodes to fewer than 32 bytes, or exceeds
        |                         | the size cap
 400    | invalid_device_id       | device_id empty or over 255 bytes
 401    | invalid_device_secret   | Wrong secret for a known device
 401    | guest_revoked           | The device verifier was revoked
 401    | guest_upgraded          | Already claimed; log in with its real credentials
 404    | guest_auth_disabled     | Guest auth is not enabled in config
 404    | player_not_found        | Upgrade token resolves to no player
 409    | not_an_unclaimed_guest  | Upgrade target is not an unclaimed guest
 409    | username_taken          | Upgrade username is already in use
 422    | validation_failed       | Upgrade fields invalid (see `fields`)
 503    | guest_capacity_reached  | Global create limit or the unlinked-guest cap
        |                         | was hit
"""
                    ]}
                ]}
            ]},

            {h3, [], [~"SDK integration"]},
            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"guest-sdk",
                tabs => [
                    #{
                        label => ~"Lua",
                        lang => ~"lua",
                        body =>
                            ~"""
-- Defold (Lua). device_id / device_secret are yours to generate and persist.
client.auth.guest(client, device_id, device_secret, function(data, err)
    if err then print("guest sign-in failed: " .. tostring(err.error)) return end
    -- data.created is true on first sign-in, absent on resume.
    print("signed in as guest " .. tostring(data.player_id))
end)

-- Later, claim a permanent account. Keeps the same player_id.
client.auth.upgrade_guest(client, "player1", "secret123", function(data, err)
    if err then print("upgrade failed: " .. tostring(err.error)) return end
    print("upgraded to " .. tostring(data.username))
end)
"""
                    },
                    #{
                        label => ~"C#",
                        lang => ~"csharp",
                        body =>
                            ~"""
// Unity (C#). deviceId / deviceSecret are yours to generate and persist.
var resp = await client.Auth.GuestAsync(deviceId, deviceSecret);
Debug.Log(resp.created ? $"New guest {resp.player_id}" : $"Resumed {resp.player_id}");

// Later, claim a permanent account. Replaces the stored tokens.
var upgraded = await client.Auth.UpgradeGuestAsync("player1", "secret123");
Debug.Log($"Upgraded: {upgraded.upgraded}");
"""
                    }
                ]
            }),

            {h2, [], [~"OAuth / social login"]},
            {p, [], [
                ~"For game clients, Asobi uses server-side token validation. The client authenticates with the platform SDK, obtains an ID token (JWT), and sends it to Asobi:"
            ]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8084/api/v1/auth/oauth \
  -H 'Content-Type: application/json' \
  -d '{"provider": "google", "token": "eyJhbGciOiJSUzI1NiIs..."}'
"""
            ),
            {p, [], [
                ~"Flow: platform SDK → ID token → Asobi validates against provider JWKS → existing player (login) or new one (create + link)."
            ]},

            {h3, [], [~"Supported providers"]},
            {'div', [{class, ~"docs-api"}], [
                {pre, [], [
                    {code, [], [
                        ~"""
 Provider   | provider value | Issuer
------------|----------------|--------------------------------------------------
 Google     | "google"       | https://accounts.google.com
 Apple      | "apple"        | https://appleid.apple.com
 Microsoft  | "microsoft"    | https://login.microsoftonline.com/common/v2.0
 Discord    | "discord"      | https://discord.com
 Steam      | "steam"        | custom (Steam Web API session ticket)
"""
                    ]}
                ]}
            ]},

            {h3, [], [~"Provider configuration"]},
            {p, [], [~"Add credentials to ", {code, [], [~"sys.config"]}, ~":"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {oidc_providers, #{
        google => #{
            issuer => <<"https://accounts.google.com">>,
            client_id => <<"YOUR_CLIENT_ID">>,
            client_secret => <<"YOUR_CLIENT_SECRET">>
        },
        apple => #{
            issuer => <<"https://appleid.apple.com">>,
            client_id => <<"YOUR_CLIENT_ID">>,
            client_secret => <<"YOUR_CLIENT_SECRET">>
        }
    }}
]}
"""
            ),

            {h2, [], [~"Steam"]},
            {p, [], [
                ~"Steam uses session tickets rather than OIDC. The client calls ",
                {code, [], [~"ISteamUser::GetAuthSessionTicket"]},
                ~" and sends the hex-encoded ticket:"
            ]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8084/api/v1/auth/oauth \
  -H 'Content-Type: application/json' \
  -d '{"provider": "steam", "token": "14000000..."}'
"""
            ),
            {p, [], [~"Asobi validates via the Steam Web API. Config:"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {steam_api_key, <<"YOUR_STEAM_WEB_API_KEY">>},
    {steam_app_id, <<"YOUR_STEAM_APP_ID">>}
]}
"""
            ),

            {h2, [], [~"Linking providers"]},
            {p, [], [
                ~"Players can link additional providers to their existing account (Google + Steam on the same player, say). Requires an authenticated session:"
            ]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8084/api/v1/auth/link \
  -H 'Authorization: Bearer <access_token>' \
  -H 'Content-Type: application/json' \
  -d '{"provider": "discord", "token": "eyJhbGciOi..."}'
"""
            ),
            {p, [], [
                ~"Unlink via ",
                {code, [], [~"DELETE /api/v1/auth/unlink"]},
                ~". Asobi refuses to unlink the ",
                {em, [], [~"last"]},
                ~" auth method to avoid locking the player out."
            ]},

            {h2, [], [~"WebSocket authentication"]},
            {p, [], [
                ~"After obtaining an access token (via any method above), connect to the WebSocket and authenticate as the first message:"
            ]},
            code(
                ~"json",
                ~"""
{"type": "session.connect", "payload": {"token": "<access_token>"}}
"""
            ),
            {p, [], [
                ~"Token behaviour is provider-agnostic - it works the same regardless of which login path produced it."
            ]},

            {h2, [], [~"SDK integration"]},
            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"auth-sdk",
                tabs => [
                    #{
                        label => ~"Lua",
                        lang => ~"lua",
                        body =>
                            ~"""
-- Defold (Lua)
local id_token = google_sign_in.get_id_token()
asobi.auth.oauth("google", id_token, function(result)
    -- access token stored internally
end)
"""
                    },
                    #{
                        label => ~"C#",
                        lang => ~"csharp",
                        body =>
                            ~"""
// Unity (C#)
string idToken = googleSignIn.IdToken;
var response = await asobi.Auth.OAuth("google", idToken);
// access token stored internally
"""
                    }
                ]
            }),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/protocols/rest"}, az_navigate], [~"REST API reference"]},
                    ~" - every endpoint, including the auth routes."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                        ~"WebSocket protocol"
                    ]},
                    ~" - message shapes for real-time flows."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/economy"}, az_navigate], [~"Economy & IAP"]},
                    ~" - receipt validation for Apple and Google."
                ]}
            ]}
        ]}
    ).
code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
