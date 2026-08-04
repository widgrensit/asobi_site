-module(asobi_site_showcase_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"showcase"}, Bindings), #{}}.

demos() ->
    [
        {
            ~"Godot",
            ~"Godot 4.x arena demo, GDScript client against a Lua match.",
            ~"https://github.com/widgrensit/asobi-godot-demo"
        },
        {
            ~"Defold",
            ~"Defold arena demo with the gui_script client.",
            ~"https://github.com/widgrensit/asobi-defold-demo"
        },
        {
            ~"Unity",
            ~"Unity arena demo, C# client, IL2CPP-safe.",
            ~"https://github.com/widgrensit/asobi-unity-demo"
        },
        {
            ~"Unreal",
            ~"UE5 project built on AsobiCore.",
            ~"https://github.com/widgrensit/asobi-unreal-demo"
        },
        {
            ~"Flame",
            ~"Flame and Flutter 2D arena demo in Dart.",
            ~"https://github.com/widgrensit/asobi-flame-demo"
        }
    ].

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}, {class, ~"showcase-page"}], [
            {section, [{class, ~"demo-hero"}], [
                {'div', [{class, ~"demo-hero-inner"}], [
                    {span, [{class, ~"hero-badge"}], [~"Showcase"]},
                    {h1, [{class, ~"hero-title"}], [
                        ~"Built with ",
                        {em, [], [~"asobi"]}
                    ]},
                    {p, [{class, ~"hero-subtitle"}], [
                        ~"Working projects you can clone, run and read. Every one of these talks to a real asobi backend."
                    ]}
                ]}
            ]},

            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"Official demos"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"One arena game, built once per engine, against the same server."
                    ]},
                    {'div', [{class, ~"showcase-grid"}], [
                        ?each(
                            fun({Name, Blurb, Url}) ->
                                {a, [{class, ~"showcase-card"}, {href, Url}], [
                                    {h3, [], [Name]},
                                    {p, [], [Blurb]},
                                    {span, [{class, ~"showcase-card-link"}], [~"View source"]}
                                ]}
                            end,
                            demos()
                        ),
                        {a, [{class, ~"showcase-card"}, {href, ~"/docs/samples"}, az_navigate], [
                            {h3, [], [~"In your browser"]},
                            {p, [], [
                                ~"A live match you can join now, no install, no account."
                            ]},
                            {span, [{class, ~"showcase-card-link"}], [~"Play the sample"]}
                        ]}
                    ]}
                ]}
            ]},

            {section, [{class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"Shipping something on asobi?"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"We would like to feature it here. It does not need to be finished or commercial, only real."
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"You decide how you are credited, whether your name appears at all, and you can ask us to take it down at any time without giving a reason."
                    ]},
                    {'div', [{class, ~"showcase-cta"}], [
                        {a,
                            [
                                {class, ~"btn btn-primary"},
                                {href, ~"https://discord.gg/vYSfYYyXpu"}
                            ],
                            [~"Tell us on Discord"]},
                        {a, [{class, ~"btn btn-ghost"}, {href, ~"/brand"}, az_navigate], [
                            ~"Brand assets"
                        ]}
                    ]}
                ]}
            ]}
        ]}
    ).
