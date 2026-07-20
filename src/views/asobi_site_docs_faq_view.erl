-module(asobi_site_docs_faq_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-faq", title => ~"FAQ — Asobi docs"},
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
                ~" / FAQ"
            ]},
            {h1, [], [~"FAQ"]},

            {h2, [], [~"Does Asobi replace Nakama / Colyseus / PlayFab?"]},
            {p, [], [
                ~"For the indie and 2D multiplayer slot, yes. For AAA shooters that need per-match ",
                ~"dedicated UDP servers, no - pair Asobi with a UDP relay for that. See how it ",
                {a, [{href, ~"/docs/comparison"}, az_navigate], [~"compares"]},
                ~", or the migration guides for ",
                {a, [{href, ~"/docs/migrate/nakama"}, az_navigate], [~"Nakama"]},
                ~", ",
                {a, [{href, ~"/docs/migrate/hathora"}, az_navigate], [~"Hathora"]},
                ~", and ",
                {a, [{href, ~"/docs/migrate/playfab"}, az_navigate], [~"PlayFab"]},
                ~"."
            ]},

            {h2, [], [~"Can I write game logic in something other than Lua?"]},
            {p, [], [
                ~"Yes. Depend on Asobi as an Erlang library and write match code in Erlang, or call the ",
                {a, [{href, ~"/docs/protocols/rest"}, az_navigate], [~"REST"]},
                ~" / ",
                {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [~"WebSocket"]},
                ~" API from any language. Lua is the easy mode, not the only mode."
            ]},

            {h2, [], [~"Does it scale across machines?"]},
            {p, [], [
                ~"Asobi is single-node by design - one BEAM node handles tens of thousands of ",
                ~"connections. Shard at the app level (game-per-node, region-per-node) rather than ",
                ~"clustering a single match across hosts. See ",
                {a, [{href, ~"/docs/clustering"}, az_navigate], [~"Clustering"]},
                ~" and ",
                {a, [{href, ~"/docs/performance"}, az_navigate], [~"Performance"]},
                ~"."
            ]},

            {h2, [], [~"How do I turn on guest (anonymous) play?"]},
            {p, [], [
                ~"Declare ",
                {code, [], [~"guest_auth = true"]},
                ~" in your game's Lua config and have the operator supply a verifier pepper - it's on ",
                ~"only when both agree. Full details in ",
                {a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication"]},
                ~"."
            ]},

            {h2, [], [~"Should I self-host or use the managed cloud?"]},
            {p, [], [
                ~"Both run the same engine. ",
                {a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-host"]},
                ~" is free, Docker-only, no account. ",
                {a, [{href, ~"/docs/cloud"}, az_navigate], [~"Managed cloud"]},
                ~" runs it for you, EU-hosted. Your Lua bundle is identical either way, so you can move ",
                ~"between them."
            ]},

            {h2, [], [~"What happens if Asobi disappears?"]},
            {p, [], [
                ~"Apache-2 licensed, single-binary deploy, Postgres backing store - nothing in your ",
                ~"stack is load-bearing on us. The ",
                {a, [{href, ~"/docs/exit"}, az_navigate], [~"exit guide"]},
                ~" spells out exactly how you'd keep running without us."
            ]},

            {h2, [], [~"Which client SDK should I use?"]},
            {p, [], [
                ~"Whichever matches your engine - Unity, Godot, Defold, Unreal, Flame, plus JS/TS, Dart, ",
                ~"and LÖVE. Each has a ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"quickstart"]},
                ~". No engine? The REST + WebSocket protocol is public, so any language works."
            ]}
        ]}
    ).
