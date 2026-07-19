-module(asobi_site_docs_best_practices_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-best-practices", title => ~"Best practices — Asobi docs"},
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
                ~" / Best practices"
            ]},
            {h1, [], [~"Best practices"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Cross-cutting advice that shows up across the guides, in one place. Each links to the ",
                ~"guide that covers it in depth."
            ]},

            {h2, [], [~"Keep the server authoritative"]},
            {p, [], [
                ~"Treat every client message as untrusted. Validate and apply input in your ",
                {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua match logic"]},
                ~"; compute outcomes server-side and broadcast state, rather than trusting a client's ",
                ~"claimed position or score. The client renders; the server decides."
            ]},

            {h2, [], [~"Guard secrets, persist tokens"]},
            {p, [], [
                ~"Keep peppers and keys out of source and out of Lua bundles - inject them as ",
                {a, [{href, ~"/docs/configuration"}, az_navigate], [~"configuration"]},
                ~" via env or a secret manager. On the client, persist the refresh token and the guest ",
                {code, [], [~"device_secret"]},
                ~" in secure storage, and handle ",
                {code, [], [~"auth_expired"]},
                ~" by re-authenticating and reconnecting (see ",
                {a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication"]},
                ~")."
            ]},

            {h2, [], [~"Deploy with hot reload"]},
            {p, [], [
                ~"Ship new Lua without disconnecting players: in-flight matches finish on the old code, ",
                ~"new matches pick up the new code. Lean on it for a tight loop locally (",
                {a, [{href, ~"/docs/tools/dev"}, az_navigate], [{code, [], [~"asobi dev"]}]},
                ~") and in production (",
                {a, [{href, ~"/docs/tutorials/hot-reload"}, az_navigate], [~"hot-reload tutorial"]},
                ~"). Keep bundles side-effect-safe so a reload mid-match is boring."
            ]},

            {h2, [], [~"Shard at the app level"]},
            {p, [], [
                ~"Asobi is single-node by design. Scale by running more nodes and partitioning work - ",
                ~"game-per-node, region-per-node - not by clustering a single match across hosts. ",
                {a, [{href, ~"/docs/clustering"}, az_navigate], [~"Clustering"]},
                ~" and ",
                {a, [{href, ~"/docs/performance"}, az_navigate], [~"Performance"]},
                ~" cover the sizing."
            ]},

            {h2, [], [~"Fail closed, rate-limit early"]},
            {p, [], [
                ~"Lean on the built-in per-IP and global limiters, and design new endpoints to deny by ",
                ~"default when a control is absent - the way guest auth stays off unless both the game ",
                ~"and the operator opt in. The ",
                {a, [{href, ~"/docs/security"}, az_navigate], [~"security section"]},
                ~" documents the threat model and the limits Asobi does and doesn't cover."
            ]},

            {h2, [], [~"Test against the real protocol"]},
            {p, [], [
                ~"For clients and integrations, run the canonical ",
                {a, [{href, ~"/docs/tools/testing"}, az_navigate], [~"test harness"]},
                ~" in CI so protocol drift breaks one test in one place, not silently in production."
            ]}
        ]}
    ).
