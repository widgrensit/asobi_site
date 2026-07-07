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
                ~"Asobi supports username/password, OAuth/OIDC social login (Google, Apple, Microsoft, Discord), Steam, and device auth. ",
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
