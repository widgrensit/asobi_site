-module(asobi_site_docs_security_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-security", title => ~"Security — Asobi docs"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Security"
            ]},
            {h1, [], [~"Security overview"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi is built on a Erlang/OTP stack with a small, deliberate trust boundary between player input and server-side game state. ",
                ~"This section documents what the runtime defends against, what it does not, and how to deploy it safely."
            ]},

            {h2, [], [~"Reading order"]},
            {'div', [{class, ~"docs-grid"}], [
                {a, [{href, ~"/docs/security/threat-model"}, {class, ~"docs-card"}, az_navigate], [
                    {h3, [], [~"Threat model"]},
                    {p, [], [
                        ~"Trust boundaries, the player-input edge, distributed Erlang assumptions, and what \x{201C}trusted\x{201D} actually means for game-module code."
                    ]}
                ]},
                {a, [{href, ~"/docs/security/auth"}, {class, ~"docs-card"}, az_navigate], [
                    {h3, [], [~"Authentication & rate limiting"]},
                    {p, [], [
                        ~"Bearer-token verification, Apple StoreKit 2 JWS chain validation, Steam ticket validation, and the per-route rate-limit gate."
                    ]}
                ]},
                {a,
                    [
                        {href, ~"/docs/security/known-limitations"},
                        {class, ~"docs-card"},
                        az_navigate
                    ],
                    [
                        {h3, [], [~"Known limitations (asobi)"]},
                        {p, [], [
                            ~"Trust assumptions about game-module code, distributed Erlang defaults, OS-level resource bounds the runtime does not enforce."
                        ]}
                    ]},
                {a, [{href, ~"/docs/security/lua-sandbox"}, {class, ~"docs-card"}, az_navigate], [
                    {h3, [], [~"Lua sandbox model"]},
                    {p, [], [
                        ~"What asobi_lua removes, replaces, and time-budgets in the Luerl state hosting your game."
                    ]}
                ]},
                {a, [{href, ~"/docs/security/lua-trust-model"}, {class, ~"docs-card"}, az_navigate],
                    [
                        {h3, [], [~"Lua trust model"]},
                        {p, [], [
                            ~"Why mounted Lua scripts are trusted in the same sense as the binary, and audit results that confirm specific escape attempts fail."
                        ]}
                    ]},
                {a,
                    [
                        {href, ~"/docs/security/lua-known-limitations"},
                        {class, ~"docs-card"},
                        az_navigate
                    ],
                    [
                        {h3, [], [~"Lua known limitations"]},
                        {p, [], [
                            ~"Resource caps the Luerl sandbox does not enforce yet, deployment hygiene, and best-effort rollback behaviour."
                        ]}
                    ]}
            ]},

            {h2, [], [~"Reporting vulnerabilities"]},
            {p, [], [
                ~"Send reports to ",
                {a, [{href, ~"mailto:security@asobi.dev"}], [{code, [], [~"security@asobi.dev"]}]},
                ~" rather than opening a public issue. We aim to acknowledge within 72 hours and ship a fix or mitigation within 14 days for critical findings."
            ]}
        ]}
    ).
