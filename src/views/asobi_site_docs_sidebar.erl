-module(asobi_site_docs_sidebar).
-include("asobi_site_view.hrl").

-export([render/1]).

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    Sections = [
        {~"Start here", [
            {~"/docs", ~"Overview"},
            {~"/docs/cloud", ~"Quick start - Cloud (fastest)"},
            {~"/docs/quickstart", ~"Quick start - Self-host"},
            {~"/docs/concepts", ~"Core concepts"}
        ]},
        {~"Onboard your engine", [
            {~"/docs/quickstart/unity", ~"Unity"},
            {~"/docs/quickstart/godot", ~"Godot"},
            {~"/docs/quickstart/defold", ~"Defold"},
            {~"/docs/quickstart/unreal", ~"Unreal"},
            {~"/docs/quickstart/flame", ~"Flame"},
            {~"/docs/quickstart/js", ~"JavaScript / TypeScript"},
            {~"/docs/quickstart/dart", ~"Dart"},
            {~"/docs/quickstart/love2d", ~"LÖVE"}
        ]},
        {~"Learn", [
            {~"/docs/tutorials/tic-tac-toe", ~"Tic-tac-toe"},
            {~"/docs/tutorials/hot-reload", ~"Live-edit your game (hot reload)"},
            {~"/docs/samples", ~"Samples"}
        ]},
        {~"Build", [
            {~"/docs/matchmaking", ~"Matchmaking"},
            {~"/docs/world-server", ~"World server"},
            {~"/docs/large-worlds", ~"Large worlds"},
            {~"/docs/voting", ~"Voting"},
            {~"/docs/economy", ~"Economy & IAP"},
            {~"/docs/leaderboards", ~"Leaderboards & tournaments"},
            {~"/docs/authentication", ~"Authentication"}
        ]},
        {~"Reference", [
            {~"/docs/lua/api", ~"game.* API"},
            {~"/docs/lua/callbacks", ~"Callbacks"},
            {~"/docs/lua/bots", ~"Bots"},
            {~"/docs/erlang/api", ~"Erlang API (advanced)"},
            {~"/docs/protocols/websocket", ~"WebSocket protocol"},
            {~"/docs/protocols/rest", ~"REST API"},
            {~"/docs/configuration", ~"Configuration"},
            {~"/docs/errors", ~"Errors & status codes"}
        ]},
        {~"Tooling", [
            {~"/docs/tools/cli", ~"asobi CLI"},
            {~"/docs/tools/dev", ~"asobi dev (live loop)"},
            {~"/docs/tools/testing", ~"Testing"},
            {~"/docs/lua/cookbook", ~"Cookbook"}
        ]},
        {~"Operate", [
            {~"/docs/self-host", ~"Self-host (Docker, VPS, k8s)"},
            {~"/docs/clustering", ~"Clustering"},
            {~"/docs/performance", ~"Performance"}
        ]},
        {~"Security", [
            {~"/docs/security", ~"Overview"},
            {~"/docs/security/threat-model", ~"Threat model"},
            {~"/docs/security/auth", ~"Auth & rate limiting"},
            {~"/docs/security/known-limitations", ~"Known limitations"},
            {~"/docs/security/lua-sandbox", ~"Lua sandbox"},
            {~"/docs/security/lua-trust-model", ~"Lua trust model"},
            {~"/docs/security/lua-known-limitations", ~"Lua known limitations"}
        ]},
        {~"More", [
            {~"/docs/comparison", ~"How Asobi compares"},
            {group, ~"Migrate from", [
                {~"/docs/migrate/nakama", ~"Nakama"},
                {~"/docs/migrate/hathora", ~"Hathora"},
                {~"/docs/migrate/playfab", ~"PlayFab"}
            ]},
            {~"/docs/architecture", ~"Architecture"},
            {~"/docs/benchmarks", ~"Benchmarks"},
            {~"/docs/glossary", ~"Glossary"},
            {~"/docs/exit", ~"No lock-in"},
            {~"/docs/faq", ~"FAQ"},
            {~"/docs/best-practices", ~"Best practices"},
            {~"/docs/changelog", ~"Changelog"}
        ]}
    ],
    ?html(
        {aside,
            [
                {class, ~"docs-sidebar"},
                {az_hook, ~"PreserveScroll"},
                {'data-scroll-key', ~"docs-sidebar"}
            ],
            [
                {details, [{class, ~"docs-menu"}, {open, ~"open"}], [
                    {summary, [{class, ~"docs-menu-summary"}], [
                        {span, [{class, ~"docs-menu-label"}], [~"Docs menu"]},
                        {span, [{class, ~"docs-menu-caret"}, {'aria-hidden', ~"true"}], [
                            ~"\x{25BE}"
                        ]}
                    ]},
                    {nav, [{class, ~"docs-nav"}], [
                        ?each(
                            fun({Title, Links}) ->
                                {'div', [{class, ~"docs-nav-section"}], [
                                    {h3, [], [Title]},
                                    ?each(
                                        fun(Entry) -> entry(Entry, ?get(active_path)) end,
                                        Links
                                    )
                                ]}
                            end,
                            Sections
                        )
                    ]}
                ]}
            ]}
    ).

entry({group, SubTitle, SubLinks}, Active) ->
    ?html(
        {'div', [{class, ~"docs-nav-subgroup"}], [
            {span, [{class, ~"docs-nav-subheading"}], [SubTitle]},
            {'div', [{class, ~"docs-nav-sublinks"}], [
                ?each(fun(Link) -> entry(Link, Active) end, SubLinks)
            ]}
        ]}
    );
entry({Href, Label}, Active) ->
    ?html(
        {a, [{href, Href}, {class, link_class(Href, Active)}, az_navigate], [Label]}
    ).

link_class(Href, Href) -> ~"docs-nav-link active";
link_class(_, _) -> ~"docs-nav-link".
