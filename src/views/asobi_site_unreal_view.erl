-module(asobi_site_unreal_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"unreal-guide"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    HeroSnippet = asobi_site_snippets:get(hero_connect, unreal),
    WorldSnippet = asobi_site_snippets:get(connect_world, unreal),
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Unreal Engine SDK"]},
                    {p, [], [
                        ~"Integrate Asobi into your Unreal Engine 5.7+ project. Blueprint-callable on every subsystem."
                    ]},
                    {a,
                        [
                            {href, ~"https://github.com/widgrensit/asobi-unreal"},
                            {class, ~"guide-github"}
                        ],
                        [~"View on GitHub"]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Installation"]},
                    {p, [], [~"Clone the SDK into your project's Plugins/ directory:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"cd YourProject/Plugins\n",
                                ~"git clone https://github.com/widgrensit/asobi-unreal.git AsobiSDK"
                            ]}
                        ]}
                    ]},
                    {p, [], [
                        ~"Regenerate project files, then enable \"Asobi SDK\" in Edit \x{2192} Plugins \x{2192} Networking."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Quickstart"]},
                    {p, [], [
                        ~"Authenticate, open the WebSocket, queue in matchmaker, and receive match.state:"
                    ]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [{code, [], [HeroSnippet]}]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Connect to a world"]},
                    {p, [], [
                        ~"For MMO-scale sessions, use the Worlds API. Clients subscribe to typed delegates for world.joined, world.tick, and world.terrain:"
                    ]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [{code, [], [WorldSnippet]}]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Demo project"]},
                    {p, [], [~"A minimal top-down arena demo is available:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"git clone --recursive https://github.com/widgrensit/asobi-unreal-demo.git"
                            ]}
                        ]}
                    ]},
                    {p, [], [
                        ~"Open AsobiUnrealDemo.uproject in UE 5.7+, hit Play. See ",
                        {a,
                            [{href, ~"https://github.com/widgrensit/asobi-unreal-demo"}],
                            [~"asobi-unreal-demo"]},
                        ~" on GitHub."
                    ]}
                ]}
            ]}
        ]}
    ).
