-module(asobi_site_docs_security_known_limits_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-known", title => ~"Known limitations — Asobi docs"},
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
                ~" / Known limitations"
            ]},
            {h1, [], [~"Known limitations"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Properties asobi does ",
                {strong, [], [~"not"]},
                ~" enforce. Operators who care about any of these should plan their deployment accordingly."
            ]},

            {h2, [], [~"Game-module trust assumption"]},
            {p, [], [
                ~"Loaded game modules (",
                {code, [], [~"Mod:tick/1"]},
                ~", ",
                {code, [], [~"Mod:join/2"]},
                ~", \x{2026}) run inline in the match gen_server and have full BEAM access. A malicious game module can read public ETS, spawn arbitrary processes, talk to clustered nodes, and crash the lobby. Treat the game-module source as part of the trusted compute base \x{2014} ship code reviews and signed releases the same way you would for the asobi binary itself."
            ]},
            {p, [], [
                ~"For untrusted scripting (community-submitted maps, modder content) use the ",
                {a, [{href, ~"/docs/security/lua-sandbox"}, az_navigate], [~"asobi_lua sandbox"]},
                ~"; Luerl runs scripts inside a hardened state with stripped-out OS/IO/code-loading APIs and a wall-clock budget per callback."
            ]},

            {h2, [], [~"Distributed Erlang defaults"]},
            {p, [], [
                ~"The shipped ",
                {code, [], [~"vm.args.src"]},
                ~" sets a node name and cookie but does not lock down the dist port range or bind EPMD to localhost. For single-node deploys, uncomment the localhost-bind line in ",
                {code, [], [~"vm.args.src"]},
                ~". For clustered deploys, set an explicit port range and enable TLS for distribution \x{2014} see the ",
                {a, [{href, ~"/docs/security/threat-model"}, az_navigate], [~"threat model"]},
                ~" for the exact lines."
            ]},

            {h2, [], [~"OS-level resource bounds"]},
            {p, [], [
                ~"asobi does not enforce per-process memory caps or BEAM-wide CPU caps. A malicious game module that allocates aggressively or spawns short-lived processes in a loop can pressure the OS allocator. If you run the engine alongside other workloads, isolate it via cgroups (",
                {code, [], [~"systemd"]},
                ~" slices, k8s ",
                {code, [], [~"resources.limits"]},
                ~") rather than relying on the runtime."
            ]},

            {h2, [], [~"Container release tree is writable"]},
            {p, [], [
                ~"The shipped Dockerfile runs as the non-root ",
                {code, [], [~"asobi"]},
                ~" user but does not declare ",
                {code, [], [~"--read-only"]},
                ~". The README example mounts ",
                {code, [], [~"/app/game"]},
                ~" as ",
                {code, [], [~":ro"]},
                ~"; that mode is the operator's responsibility, not the runtime's. We recommend ",
                {code, [], [~"docker run --read-only --tmpfs /tmp"]},
                ~" and chowning only the game directory to the runtime user (the rest of ",
                {code, [], [~"/app"]},
                ~" should stay root-owned + read-only)."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/security/threat-model"}, az_navigate], [~"Threat model"]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/security/lua-known-limitations"}, az_navigate], [
                        ~"Lua-side limitations"
                    ]}
                ]},
                {li, [], [{a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-host"]}]}
            ]}
        ]}
    ).
