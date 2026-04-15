-module(asobi_site_docs_auth_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-auth", title => ~"Authentication — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(_Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
                ~" / Authentication"
            ]},
            {h1, [], [~"Authentication"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi supports username/password, OAuth/OIDC social login (Google, Apple, Microsoft, Discord), Steam, and device auth. ",
                ~"Players can link multiple providers to a single account."
            ]},

            {h2, [], [~"Username & password"]},
            {p, [], [~"The simplest method. Register to receive a session token:"]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8082/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username": "player1", "password": "secret123"}'
"""
            ),
            code(
                ~"json",
                ~"""
{"player_id": "...", "session_token": "...", "username": "player1"}
"""
            ),
            {p, [], [~"Use the session token in subsequent REST calls:"]},
            code(
                ~"http",
                ~"""
Authorization: Bearer <session_token>
"""
            ),
            {p, [], [~"Login reuses the same shape at ", {code, [], [~"/api/v1/auth/login"]}, ~"."]},

            {h2, [], [~"OAuth / social login"]},
            {p, [], [
                ~"For game clients, Asobi uses server-side token validation. The client authenticates with the platform SDK, obtains an ID token (JWT), and sends it to Asobi:"
            ]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8082/api/v1/auth/oauth \
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
curl -X POST http://localhost:8082/api/v1/auth/oauth \
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
curl -X POST http://localhost:8082/api/v1/auth/link \
  -H 'Authorization: Bearer <session_token>' \
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
                ~"After obtaining a session token (via any method above), connect to the WebSocket and authenticate as the first message:"
            ]},
            code(
                ~"json",
                ~"""
{"type": "session.connect", "payload": {"token": "<session_token>"}}
"""
            ),
            {p, [], [
                ~"Token behaviour is provider-agnostic \x{2014} it works the same regardless of which login path produced it."
            ]},

            {h2, [], [~"SDK integration"]},
            pair(
                ~"""
-- Defold (Lua)
local id_token = google_sign_in.get_id_token()
asobi.auth.oauth("google", id_token, function(result)
    -- session token stored internally
end)
""",
                ~"""
// Unity (C#)
string idToken = googleSignIn.IdToken;
var response = await asobi.Auth.OAuth("google", idToken);
// session token stored internally
"""
            ),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/protocols/rest"}], [~"REST API reference"]},
                    ~" \x{2014} every endpoint, including the auth routes."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/protocols/websocket"}], [~"WebSocket protocol"]},
                    ~" \x{2014} message shapes for real-time flows."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/economy"}], [~"Economy & IAP"]},
                    ~" \x{2014} receipt validation for Apple and Google."
                ]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(~"/docs/authentication", Content).

pair(LangALabel, LangBLabel) ->
    ?html(
        {'div', [{class, ~"docs-lang-pair"}], [
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Lua"]},
                code(~"lua", LangALabel)
            ]},
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"C#"]},
                code(~"csharp", LangBLabel)
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
