-module(asobi_site_lua_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"lua-guide"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    HeroSnippet = asobi_site_snippets:get(hero_connect, lua),
    WorldSnippet = asobi_site_snippets:get(connect_world, lua),
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Lua SDK"]},
                    {p, [], [
                        ~"Server-side game modes written in Lua, hosted by asobi_lua. No client integration \x{2014} your game code runs on the asobi server."
                    ]},
                    {a,
                        [
                            {href, ~"https://github.com/widgrensit/asobi_lua"},
                            {class, ~"guide-github"}
                        ],
                        [~"View on GitHub"]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Installation"]},
                    {p, [], [~"Use the official Docker image:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"docker pull ghcr.io/widgrensit/asobi_lua:latest\n",
                                ~"docker run -p 8080:8080 -v $(pwd)/game:/app/game ghcr.io/widgrensit/asobi_lua"
                            ]}
                        ]}
                    ]},
                    {p, [], [
                        ~"Mount your Lua game-mode files under ",
                        {code, [], [~"/app/game"]},
                        ~". asobi_lua hot-reloads them on save."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Game mode skeleton"]},
                    {p, [], [~"A minimal match-mode Lua file:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [{code, [], [HeroSnippet]}]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"World mode"]},
                    {p, [], [
                        ~"Worlds are lazy-zoned and support terrain streaming. Your Lua code decides which zone a player spawns in; asobi manages the tick, reconnection, and broadcast."
                    ]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [{code, [], [WorldSnippet]}]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Reference"]},
                    {p, [], [
                        ~"See the ",
                        {a, [{href, ~"/docs/lua/api"}], [~"Lua API reference"]},
                        ~" and ",
                        {a, [{href, ~"/docs/lua/cookbook"}], [~"Lua cookbook"]},
                        ~" for the full ",
                        {code, [], [~"game.*"]},
                        ~" surface."
                    ]}
                ]}
            ]}
        ]}
    ).
