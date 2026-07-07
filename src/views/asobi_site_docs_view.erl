-module(asobi_site_docs_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs", title => ~"Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {h1, [], [~"Build multiplayer games with Asobi"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi is an open-source game backend built on Erlang/OTP. ",
                ~"Write your game logic in ",
                {strong, [], [~"Lua"]},
                ~", hot-reload it without kicking players, and run it your way: self-host it, or deploy to managed cloud. ",
                ~"Prefer the BEAM? Asobi is a plain Erlang library underneath, so you can use it directly too."
            ]},

            {h2, [], [~"Get a game running in minutes"]},
            {'div', [{class, ~"docs-grid"}], [
                {'div', [{class, ~"docs-card"}], [
                    {h3, [], [~"Self-host - no account needed"]},
                    {p, [], [
                        ~"Docker only. Runs fully local, no signup, no credentials. About 5 minutes."
                    ]},
                    code(
                        ~"bash",
                        ~"""
docker compose up -d
# your Lua game + Postgres, server on http://localhost:8084
"""
                    ),
                    {p, [], [
                        {a,
                            [
                                {href, ~"/docs/quickstart"},
                                {class, ~"btn btn-primary"},
                                az_navigate
                            ],
                            [~"Self-host quickstart \x{2192}"]}
                    ]}
                ]},
                {'div', [{class, ~"docs-card"}], [
                    {h3, [], [~"Deploy to cloud - we run it"]},
                    {p, [], [
                        ~"No Docker, no database to manage. EU-hosted, free trial. Spin up an environment and deploy in about 10 minutes."
                    ]},
                    code(
                        ~"bash",
                        ~"""
asobi login
asobi init mygame
asobi create prod
asobi deploy prod lua
"""
                    ),
                    {p, [], [
                        {a,
                            [
                                {href, ~"/docs/cloud"},
                                {class, ~"btn btn-primary"},
                                az_navigate
                            ],
                            [~"Cloud quickstart \x{2192}"]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"docs-cta-row"}], [
                {a, [{href, ~"/docs/quickstart"}, {class, ~"btn btn-primary"}, az_navigate], [
                    ~"Quick start \x{2192}"
                ]},
                {a,
                    [
                        {href, ~"/docs/tutorials/tic-tac-toe"},
                        {class, ~"btn btn-secondary"},
                        az_navigate
                    ],
                    [
                        ~"Tic-tac-toe tutorial"
                    ]},
                {a, [{href, ~"https://github.com/widgrensit/asobi"}, {class, ~"btn btn-ghost"}], [
                    ~"GitHub"
                ]}
            ]},

            {h2, [], [~"Start here"]},
            {'div', [{class, ~"docs-grid"}], [
                card(
                    ~"/docs/quickstart",
                    ~"Quick start",
                    ~"Run the server, write a Lua game, connect a client - about 10 minutes."
                ),
                card(
                    ~"/docs/concepts",
                    ~"Core concepts",
                    ~"Matches, worlds, zones, voting, phases. The primitives Asobi gives you."
                ),
                card(
                    ~"/docs/tutorials/tic-tac-toe",
                    ~"Tic-tac-toe",
                    ~"Your first Asobi game. Two players, one match, authoritative Lua."
                ),
                card(
                    ~"/docs/lua/api",
                    ~"Lua API",
                    ~"Full reference for the game.* API available in your Lua scripts."
                ),
                card(
                    ~"/docs/erlang/api",
                    ~"Erlang API (advanced)",
                    ~"Embedding Asobi in an OTP app? The native behaviours and modules."
                ),
                card(
                    ~"/docs/lua/cookbook",
                    ~"Cookbook",
                    ~"Copy-pasteable recipes for common patterns."
                ),
                card(
                    ~"/docs/self-host",
                    ~"Self-host",
                    ~"Run Asobi on your own infrastructure. Docker, bare metal, or k8s."
                )
            ]},

            {h2, [], [~"Why Asobi?"]},
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    ~"You write game logic in ",
                    {strong, [], [~"Lua"]},
                    ~" - fast iteration, what game devs already know - running on the BEAM, which gives you:"
                ]},
                {ul, [], [
                    {li, [], [
                        {strong, [], [~"Restart-free hot reload. "]},
                        ~"Deploy new code without disconnecting players. Works for both Lua bundles and Erlang beams. Nobody else on the market does this."
                    ]},
                    {li, [], [
                        {strong, [], [~"Fault tolerance. "]},
                        ~"Crash one match, others keep running. OTP supervision trees isolate failures."
                    ]},
                    {li, [], [
                        {strong, [], [~"Concurrency. "]},
                        ~"One process per match, one process per zone. Scales to hundreds of thousands on one node."
                    ]},
                    {li, [], [
                        {strong, [], [~"An Erlang escape hatch. "]},
                        ~"Need behaviour-level control for a hot loop? Drop into Erlang - your Lua and the native path call the same ",
                        {code, [], [~"asobi_match"]},
                        ~" behaviour underneath."
                    ]}
                ]}
            ]},

            {h2, [], [~"Hosting"]},
            {p, [], [
                ~"Asobi is fully self-hostable - see ",
                {a, [{href, ~"/docs/self-host"}, az_navigate], [~"the self-host guide"]},
                ~". If you'd rather we run it for you, managed cloud hosting is live at ",
                {a, [{href, ~"/cloud"}, az_navigate], [~"asobi.dev/cloud"]},
                ~"."
            ]},

            {h2, [], [~"Want something that isn't here?"]},
            {p, [], [
                ~"These docs are new and growing. If a page is missing, shallow, or wrong: ",
                {a, [{href, ~"https://github.com/widgrensit/asobi/issues/new"}], [~"open an issue"]},
                ~" or drop into ",
                {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"the Discord"]},
                ~"."
            ]}
        ]}
    ).
card(Href, Title, Desc) ->
    ?html(
        {a, [{href, Href}, {class, ~"docs-card"}, az_navigate], [
            {h3, [], [Title]},
            {p, [], [Desc]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
