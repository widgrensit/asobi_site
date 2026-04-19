-module(asobi_site_docs_sidebar).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1]).

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    Sections = [
        {~"Get started", [
            {~"/docs", ~"Overview"},
            {~"/docs/quickstart", ~"Quick start"},
            {~"/docs/concepts", ~"Core concepts"}
        ]},
        {~"Tutorials", [
            {~"/docs/tutorials/tic-tac-toe", ~"Tic-tac-toe (Lua + Erlang)"}
        ]},
        {~"Protocols & auth", [
            {~"/docs/protocols/websocket", ~"WebSocket"},
            {~"/docs/protocols/rest", ~"REST API"},
            {~"/docs/authentication", ~"Authentication"}
        ]},
        {~"Gameplay systems", [
            {~"/docs/matchmaking", ~"Matchmaking"},
            {~"/docs/world-server", ~"World server"},
            {~"/docs/voting", ~"Voting"}
        ]},
        {~"Commerce", [
            {~"/docs/economy", ~"Economy & IAP"},
            {~"/docs/leaderboards", ~"Leaderboards & tournaments"}
        ]},
        {~"Lua reference", [
            {~"/docs/lua/api", ~"game.* API"},
            {~"/docs/lua/callbacks", ~"Callbacks"},
            {~"/docs/lua/cookbook", ~"Cookbook"},
            {~"/docs/lua/bots", ~"Bots"}
        ]},
        {~"Erlang reference", [
            {~"/docs/erlang/api", ~"Erlang API"}
        ]},
        {~"Operate", [
            {~"/docs/self-host", ~"Self-host"},
            {~"/docs/configuration", ~"Configuration"},
            {~"/docs/clustering", ~"Clustering"},
            {~"/docs/performance", ~"Performance"},
            {~"/docs/cloud", ~"Cloud (coming soon)"}
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
            {nav, [{class, ~"docs-nav"}], [
                ?each(
                    fun({Title, Links}) ->
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [Title]},
                            ?each(
                                fun({Href, Label}) ->
                                    {a,
                                        [
                                            {href, Href},
                                            {class, link_class(Href, ?get(active_path))},
                                            az_navigate
                                        ],
                                        [Label]}
                                end,
                                Links
                            )
                        ]}
                    end,
                    Sections
                )
            ]}
        ]}
    ).

link_class(Href, Href) -> ~"docs-nav-link active";
link_class(_, _) -> ~"docs-nav-link".
