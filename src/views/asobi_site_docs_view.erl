-module(asobi_site_docs_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"docs", title => ~"Asobi docs"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {h1, [], [~"Build multiplayer games with Asobi"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi is an open-source game backend built on Erlang/OTP. ",
                ~"Write your game logic in ",
                {strong, [], [~"Lua or Erlang"]},
                ~" \x{2014} both are first-class. Hot-reload it without kicking players. ",
                ~"Self-host it or \x{2014} soon \x{2014} let us host it for you."
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
                    ~"Install Asobi, spin up the engine, deploy a Lua game \x{2014} all in 15 minutes."
                ),
                card(
                    ~"/docs/glossary",
                    ~"Project glossary",
                    ~"asobi vs asobi_lua vs asobi.dev Cloud. Read this first if the names blur."
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
                    ~"Erlang API",
                    ~"Behaviours, modules, and specs for writing games directly in Erlang."
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
                    ~"Write game logic in ",
                    {strong, [], [~"Lua"]},
                    ~" (fast iteration, what game devs already know) or ",
                    {strong, [], [~"Erlang"]},
                    ~" (behaviour-level control, maximum perf). Both run on the BEAM, giving you:"
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
                        {strong, [], [~"Mix-and-match. "]},
                        ~"A mostly-Lua game can drop into Erlang for a hot loop. Both call the same ",
                        {code, [], [~"asobi_match"]},
                        ~" behaviour underneath."
                    ]}
                ]}
            ]},

            {h2, [], [~"Hosting"]},
            {p, [], [
                ~"Asobi is fully self-hostable today \x{2014} see ",
                {a, [{href, ~"/docs/self-host"}, az_navigate], [~"the self-host guide"]},
                ~". If you'd rather we run it for you, managed cloud hosting is coming at ",
                {a, [{href, ~"/cloud"}, az_navigate], [~"asobi.dev/cloud"]},
                ~" \x{2014} join the waitlist there."
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
