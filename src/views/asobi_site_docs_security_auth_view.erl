-module(asobi_site_docs_security_auth_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-auth", title => ~"Auth & rate limiting — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / ",
                {a, [{href, ~"/docs/security"}, az_navigate], [~"Security"]},
                ~" / Authentication & rate limiting"
            ]},
            {h1, [], [~"Authentication & rate limiting"]},
            {p, [{class, ~"docs-lede"}], [
                ~"How Asobi authenticates clients, validates purchases, and bounds the brute-force surface. For the higher-level trust assumptions see the ",
                {a, [{href, ~"/docs/security/threat-model"}, az_navigate], [~"threat model"]},
                ~"."
            ]},

            {h2, [], [~"Session bearer tokens"]},
            {p, [], [
                ~"Every authenticated route is gated by ",
                {code, [], [~"asobi_auth_plugin:verify/1"]},
                ~", which expects an ",
                {code, [], [~"Authorization: Bearer <token>"]},
                ~" header. Tokens are issued by ",
                {code, [], [~"nova_auth_refresh:generate_pair/2"]},
                ~" (an access token plus a single-use rotating refresh token) after a successful register/login/refresh/OAuth flow. The plugin attaches ",
                {code, [], [~"auth_data => #{player_id => Id, ...}"]},
                ~" to the request map - controllers should pattern-match on that rather than parsing the header themselves."
            ]},
            {p, [], [
                ~"Tokens are stored in ",
                {code, [], [~"asobi_player_token"]},
                ~" and revocable via ",
                {code, [], [~"nova_auth_refresh:delete_access_token/2"]},
                ~"."
            ]},

            {h2, [], [~"Guest device verifiers"]},
            {p, [], [
                {a, [{href, ~"/docs/authentication#guest-anonymous"}, az_navigate], [
                    ~"Guest auth"
                ]},
                ~" trades a device-held secret for a session, so it is opt-in and fails closed: ",
                {code, [], [~"asobi_guest_controller"]},
                ~" refuses to serve unless ",
                {code, [], [~"guest_auth"]},
                ~" is true ",
                {em, [], [~"and"]},
                ~" a ",
                {code, [], [~"guest_verifier_pepper"]},
                ~" is configured. A misconfigured deployment returns ",
                {code, [], [~"404"]},
                ~" rather than minting unauthenticated accounts."
            ]},
            {p, [], [
                ~"The secret itself is never stored. What lands in the database is a verifier:"
            ]},
            {ul, [], [
                {li, [], [
                    ~"A per-identity 16-byte salt from ",
                    {code, [], [~"crypto:strong_rand_bytes/1"]},
                    ~", plus a server-side pepper selected by key id."
                ]},
                {li, [], [
                    {code, [], [~"crypto:mac(hmac, sha256, Pepper, <<Salt, Secret>>)"]},
                    ~" - written to the identity's ",
                    {code, [], [~"provider_metadata"]},
                    ~" (",
                    {code, [], [~"salt"]},
                    ~" / ",
                    {code, [], [~"key_id"]},
                    ~" / ",
                    {code, [], [~"verifier"]},
                    ~" / ",
                    {code, [], [~"revoked"]},
                    ~")."
                ]},
                {li, [], [
                    ~"Comparison goes through ",
                    {code, [], [~"crypto:hash_equals/2"]},
                    ~", so a wrong secret cannot be recovered by timing the response."
                ]},
                {li, [], [
                    ~"The pepper is keyed (",
                    {code, [], [~"key_id"]},
                    ~" -> pepper) so it can be rotated without stranding guests, and it lives outside the database - a dumped verifier table is useless without it."
                ]}
            ]},
            {p, [], [
                ~"Input is bounded before any crypto runs: the secret must decode to at least 32 bytes (and stay under a size cap), and ",
                {code, [], [~"device_id"]},
                ~" must be non-empty and at most 255 bytes."
            ]},
            {p, [], [
                ~"Upgrade is the compromise-recovery moment, so it is treated as one. ",
                {code, [], [~"nova_auth_refresh:revoke_all/2"]},
                ~" kills the entire token family before a fresh pair is issued, and the guest identity is deleted outright - a stolen device secret that already minted tokens loses both the tokens and the ability to re-authenticate."
            ]},
            {p, [], [
                ~"The optional reaper (",
                {code, [], [~"asobi_guest_reaper"]},
                ~", off unless ",
                {code, [], [~"guest_reap_after"]},
                ~" is set) re-checks that a guest is still unclaimed ",
                {em, [], [~"inside"]},
                ~" its delete transaction. A player who upgrades between the pre-check and the delete wins the race, so a concurrent upgrade can never be silently reaped. The unlinked-guest cap reads a short-TTL cached count so an unauthenticated create storm cannot force a full-table ",
                {code, [], [~"COUNT"]},
                ~" per request, and a failed count returns ",
                {code, [], [~"unknown"]},
                ~" so the cap fails closed."
            ]},
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Assurance level. "]},
                    ~"A guest is only as strong as a secret sitting in client storage, so treat guests as low-assurance until upgraded. ",
                    ~"Anything valuable - purchases, competitive ranking, cross-device identity - should require a claimed account."
                ]}
            ]},

            {h2, [], [~"Apple StoreKit 2 JWS verification"]},
            {p, [], [
                {code, [], [~"asobi_iap:verify_apple/1"]},
                ~" parses an Apple-signed JWS receipt and verifies it end-to-end:"
            ]},
            {ol, [], [
                {li, [], [
                    ~"Header ",
                    {code, [], [~"alg"]},
                    ~" is required to be ",
                    {code, [], [~"ES256"]},
                    ~". Other algorithms are rejected."
                ]},
                {li, [], [
                    ~"The ",
                    {code, [], [~"x5c"]},
                    ~" chain is decoded (DER-encoded certificates, base64'd in JWS order: leaf \x{2192} intermediate \x{2192} root)."
                ]},
                {li, [], [
                    ~"The chain is validated against a configured Apple Root CA via ",
                    {code, [], [~"public_key:pkix_path_validation/3"]},
                    ~". Operators ship the root in ",
                    {code, [], [~"priv/apple_root_ca.pem"]},
                    ~" (or override the path via ",
                    {code, [], [~"application:get_env(asobi, apple_root_cert_path, ...)"]},
                    ~")."
                ]},
                {li, [], [
                    ~"The signature on ",
                    {code, [], [~"<header>.<payload>"]},
                    ~" is verified with the leaf cert's public key. A bit-flipped signature, swapped signature, or any chain mismatch fails the verification."
                ]}
            ]},
            {p, [], [
                ~"Failures return ",
                {code, [], [~"{error, Reason}"]},
                ~" with a sanitised reason atom; the controller (",
                {code, [], [~"asobi_iap_controller"]},
                ~") maps them to 400/401 responses without leaking JWS internals to the client."
            ]},

            {h2, [], [~"Steam ticket validation"]},
            {p, [], [
                {code, [], [~"asobi_steam:validate_ticket/1"]},
                ~" validates a hex-encoded Steam session ticket against the Steam Web API:"
            ]},
            {ol, [], [
                {li, [], [
                    ~"The ticket character class is enforced (",
                    {code, [], [~"[0-9a-fA-F]+"]},
                    ~", max 4096 bytes). Anything else is rejected before any HTTP call."
                ]},
                {li, [], [
                    ~"All dynamic URL components (key, app id, ticket, steam id) are passed through ",
                    {code, [], [~"uri_string:quote/1"]},
                    ~" so an ",
                    {code, [], [~"&"]},
                    ~" or ",
                    {code, [], [~"="]},
                    ~" in user input cannot inject query parameters into the Steam call."
                ]}
            ]},

            {h2, [], [~"Per-route rate limits"]},
            {p, [], [
                {code, [], [~"asobi_rate_limit_plugin"]},
                ~" is wired as a ",
                {code, [], [~"pre_request"]},
                ~" plugin. It selects a Seki limiter group based on the request path:"
            ]},
            {pre, [], [
                {code, [], [
                    ~"""
 Path prefix       | Limiter             | Default limit (req/sec/IP)
-------------------|---------------------|-----------------------------
 /api/v1/auth/*    | asobi_auth_limiter  | 5
 /api/v1/iap/*     | asobi_iap_limiter   | 10
 everything else   | asobi_api_limiter   | 300
"""
                ]}
            ]},
            {p, [], [
                ~"The auth limiter is the brute-force gate: a 5/sec cap plus the bcrypt cost on ",
                {code, [], [~"nova_auth_accounts:authenticate/3"]},
                ~" makes online password guessing infeasible at internet scale."
            ]},
            {p, [], [
                ~"Operators can override limits via the ",
                {code, [], [~"asobi, rate_limits"]},
                ~" env in their sys config:"
            ]},
            code(
                ~"erlang",
                ~"""
{rate_limits, #{
    auth => #{limit => 10, window => 1000},
    iap  => #{limit => 20, window => 1000},
    api  => #{limit => 600, window => 1000}
}}
"""
            ),
            {p, [], [
                ~"The dev/test sys config bumps all three to 1000 because CT bursts register/login calls against ",
                {code, [], [~"127.0.0.1"]},
                ~" and the production-default auth cap would fail the suites."
            ]},

            {h2, [], [~"DDoS / DoS surface notes"]},
            {p, [], [
                ~"Deliberate per-call upper bounds in the runtime that exist purely to bound the cost of a single hostile request:"
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Cloud saves "]},
                    ~"(",
                    {code, [], [~"/saves/:slot"]},
                    ~") - body capped at 256 KB; per-player slot count capped at 10."
                ]},
                {li, [], [
                    {strong, [], [~"Storage "]},
                    ~"(",
                    {code, [], [~"/storage/:collection/:key"]},
                    ~") - ",
                    {code, [], [~"read_perm"]},
                    ~" / ",
                    {code, [], [~"write_perm"]},
                    ~" whitelisted to ",
                    {code, [], [~"[\"public\", \"owner\"]"]},
                    ~"; arbitrary strings rejected with 400."
                ]},
                {li, [], [
                    {strong, [], [~"Inventory consume "]},
                    ~"- quantity range ",
                    {code, [], [~"[1, 1_000_000]"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Leaderboard "]},
                    {code, [], [~"top"]},
                    ~" / ",
                    {code, [], [~"around"]},
                    ~" - ",
                    {code, [], [~"?limit"]},
                    ~" clamped to 100, ",
                    {code, [], [~"?range"]},
                    ~" to 50 (mitigates an O(N) ETS scan attack)."
                ]},
                {li, [], [
                    {strong, [], [~"Chat history "]},
                    ~"- ",
                    {code, [], [~"?limit"]},
                    ~" clamped to ",
                    {code, [], [~"[1, 200]"]},
                    ~"; channel membership is enforced (DM participants, world joiners, group members)."
                ]},
                {li, [], [
                    {strong, [], [~"DM send "]},
                    ~"- content capped at 2000 bytes; non-binary or empty content rejected."
                ]},
                {li, [], [
                    {strong, [], [~"Group chat / WS chat.join "]},
                    ~"- channel id namespaced (",
                    {code, [], [~"dm:"]},
                    ~", ",
                    {code, [], [~"world:"]},
                    ~", ",
                    {code, [], [~"zone:"]},
                    ~", ",
                    {code, [], [~"prox:"]},
                    ~", ",
                    {code, [], [~"room:"]},
                    ~"); per-connection cap of 32 simultaneously joined channels; idle channels stop after 60s with no live members."
                ]},
                {li, [], [
                    {strong, [], [~"Per-player world creation "]},
                    ~"- capped via pg group; default 5 worlds per player, 1000 globally. Tunable via ",
                    {code, [], [~"world_max_per_player"]},
                    ~" / ",
                    {code, [], [~"world_max"]},
                    ~" env."
                ]},
                {li, [], [
                    {strong, [], [~"Matchmaker "]},
                    ~"- party entries that don't match the requester are silently dropped; ticket reads / cancellations require ownership."
                ]}
            ]},

            {h2, [], [~"Test coverage"]},
            {p, [], [~"Regressions for the items above live under ", {code, [], [~"test/"]}, ~":"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"asobi_iap_SUITE.erl"]},
                    ~" - Apple JWS happy path + 14 negative cases."
                ]},
                {li, [], [
                    {code, [], [~"asobi_guest_SUITE.erl"]},
                    ~" - guest create-or-resume, wrong-secret rejection, upgrade + token revocation."
                ]},
                {li, [], [
                    {code, [], [~"asobi_world_lobby_SUITE.erl"]},
                    ~" - per-player + global world caps."
                ]},
                {li, [], [
                    {code, [], [~"asobi_matchmaker_api_SUITE.erl"]},
                    ~" - party consent + ticket ownership."
                ]},
                {li, [], [
                    {code, [], [~"asobi_social_api_SUITE.erl"]},
                    ~" - chat history membership."
                ]},
                {li, [], [
                    {code, [], [~"asobi_dm_tests.erl"]},
                    ~" - DM length cap + empty-content rejection."
                ]}
            ]},
            {p, [], [~"Run with ", {code, [], [~"rebar3 ct,eunit"]}, ~"."]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
