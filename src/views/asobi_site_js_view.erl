-module(asobi_site_js_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"js-guide"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    HeroSnippet = asobi_site_snippets:get(hero_connect, js),
    WorldSnippet = asobi_site_snippets:get(connect_world, js),
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"TypeScript / JavaScript SDK"]},
                    {p, [], [
                        ~"Browser and Node.js 18+ client for Asobi. Event-emitter API over WebSocket, typed REST APIs, auto-reconnect."
                    ]},
                    {a,
                        [
                            {href, ~"https://github.com/widgrensit/asobi-js"},
                            {class, ~"guide-github"}
                        ],
                        [~"View on GitHub"]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Installation"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"npm install @asobi/client"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Quickstart"]},
                    {p, [], [
                        ~"Authenticate, open a WebSocket, queue in matchmaker, and subscribe to match.state:"
                    ]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [{code, [], [HeroSnippet]}]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Connect to a world"]},
                    {p, [], [
                        ~"Use the WebSocket event emitter for world.* events. The ",
                        {code, [], [~"world.terrain"]},
                        ~" event delivers base64-encoded chunks at specific grid coordinates \x{2014} decode once per chunk and cache."
                    ]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [{code, [], [WorldSnippet]}]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Reference"]},
                    {p, [], [
                        ~"All submodules (auth, players, matches, matchmaker, worlds, dm, leaderboards, economy, inventory, social, chat, tournaments, votes, notifications, storage) are typed and exported from ",
                        {code, [], [~"@asobi/client"]},
                        ~"."
                    ]}
                ]}
            ]}
        ]}
    ).
