-module(asobi_site_docs_security_threat_model_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-threat", title => ~"Threat model — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / ",
                {a, [{href, ~"/docs/security"}, az_navigate], [~"Security"]},
                ~" / Threat model"
            ]},
            {h1, [], [~"Threat model"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi is a ",
                {strong, [], [~"single-tenant, single-node"]},
                ~" game backend library by design. The trust assumptions and architectural constraints below follow from that."
            ]},

            {h2, [], [~"Trusted vs. untrusted code"]},
            {pre, [], [
                {code, [], [
                    ~"""
 Component                                    | Status     | Notes
----------------------------------------------|------------|--------------------------------------------------------------
 asobi library code                           | trusted    | this repo.
 Game module callbacks (Mod:tick/1, etc.)     | trusted    | run inline in the match gen_server. A crash restarts
                                              |            | the match (transient + intensity 10) and can take the lobby down.
 Loaded NIFs                                  | trusted    | NIFs run in-VM; a misbehaving NIF crashes the BEAM.
 Loaded plugins                               | trusted    | plugins observe/mutate every request and have full
                                              |            | access to public ETS.
 Lua scripts (via asobi_lua runtime)          | sandboxed  | see the Lua sandbox model. Sits ON TOP of the asobi-side
                                              |            | trust boundary; that is where untrusted-script hardening lives.
 HTTP request bodies / WS payloads            | untrusted  | input validation in controllers / asobi_ws_handler.
 Bearer tokens, OAuth claims, IAP receipts    | untrusted  | verified via asobi_auth_plugin, asobi_oauth_controller, asobi_iap.
"""
                ]}
            ]},

            {h2, [], [~"Single-node BEAM distribution"]},
            {p, [], [
                {code, [], [~"config/vm.args.src"]},
                ~" boots with ",
                {code, [], [~"-name"]},
                ~" and ",
                {code, [], [~"-setcookie"]},
                ~". EPMD binds to ",
                {code, [], [~"0.0.0.0:4369"]},
                ~" and the dist port range is unbounded. The cookie is the only protection."
            ]},
            {p, [], [
                ~"For single-node deploys (the default), uncomment the localhost-bind line in ",
                {code, [], [~"vm.args.src"]},
                ~":"
            ]},
            code(
                ~"shell",
                ~"""
-kernel inet_dist_use_interface "{127,0,0,1}"
"""
            ),
            {p, [], [
                ~"For clustered deploys (k8s DNS discovery), constrain the dist port range and enable TLS for distribution:"
            ]},
            code(
                ~"shell",
                ~"""
-kernel inet_dist_listen_min 9100 inet_dist_listen_max 9105
-proto_dist inet_tls
-ssl_dist_optfile /etc/asobi/ssl_dist.config
"""
            ),

            {h2, [], [~"Public ETS tables"]},
            {p, [], [
                ~"These named ETS tables are ",
                {code, [], [~"public"]},
                ~" and hold live game state:"
            ]},
            {ul, [], [
                {li, [], [{code, [], [~"asobi_world_state"]}]},
                {li, [], [{code, [], [~"asobi_player_worlds"]}]},
                {li, [], [{code, [], [~"asobi_match_state"]}]},
                {li, [], [{code, [], [~"asobi_chat_registry"]}]},
                {li, [], [{code, [], [~"asobi_zone_mgr"]}]}
            ]},
            {p, [], [
                ~"Anything in the same BEAM (game callbacks, plugins) can read, mutate, or delete entries. Asobi treats this as acceptable because all in-VM code is trusted. Sandboxed runtimes layered on top (",
                {code, [], [~"asobi_lua"]},
                ~") must keep their sandbox out of these tables \x{2014} Luerl is not given access to ETS."
            ]},

            {h2, [], [~"UUIDv7 and timestamp leakage"]},
            {p, [], [
                {code, [], [~"asobi_id:generate/0"]},
                ~" produces UUIDv7 ids that embed a millisecond timestamp in the high 48 bits. Match ids, world ids, ticket ids, and ",
                {code, [], [~"player.id"]},
                ~" all use this generator. ",
                {code, [], [~"player.id"]},
                ~" is the long-lived case: the timestamp inside it reveals account-creation time, which is acceptable for a game backend but worth knowing if you build features on top."
            ]},
            {p, [], [
                ~"If you ever need an unguessable, non-correlatable id (auth tokens, invite codes, etc.) generate them via ",
                {code, [], [~"crypto:strong_rand_bytes/1"]},
                ~" rather than ",
                {code, [], [~"asobi_id:generate/0"]},
                ~"."
            ]},

            {h2, [], [~"What the supervisor will tolerate"]},
            {p, [], [
                {code, [], [~"asobi_match_sup"]},
                ~" runs each match gen_server with ",
                {code, [], [~"transient"]},
                ~" restart and ",
                {code, [], [~"intensity 10 / period 60"]},
                ~". After 10 crashes in 60s the entire match supervisor falls over, intentionally taking the lobby with it so an obviously broken game module cannot keep churning silently."
            ]},
            {p, [], [
                {code, [], [~"asobi_world_lobby_server"]},
                ~" serializes ",
                {code, [], [~"find_or_create/1"]},
                ~" to close a documented TOCTOU race (two concurrent ",
                {code, [], [~"find_or_create"]},
                ~" for the same mode no longer spawn duplicate worlds)."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/security/auth"}, az_navigate], [
                        ~"Authentication & rate limiting"
                    ]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/security/known-limitations"}, az_navigate], [
                        ~"Known limitations"
                    ]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/security/lua-sandbox"}, az_navigate], [
                        ~"Lua sandbox model"
                    ]}
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
