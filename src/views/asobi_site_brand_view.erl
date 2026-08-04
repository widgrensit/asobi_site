-module(asobi_site_brand_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"brand"}, Bindings), #{}}.

logos() ->
    [
        {
            ~"Mark",
            ~"/assets/img/logo-mark.png",
            ~"409 x 409",
            ~"Square. Use this on splash screens and anywhere small."
        },
        {
            ~"Full",
            ~"/assets/img/logo-full.png",
            ~"1686 x 556",
            ~"Mark and wordmark, horizontal. Use where there is room."
        },
        {
            ~"Stacked",
            ~"/assets/img/logo-stacked.png",
            ~"435 x 459",
            ~"Mark above the wordmark, for narrow columns."
        },
        {
            ~"Wordmark",
            ~"/assets/img/logo-head.png",
            ~"1364 x 335",
            ~"Type only, for places the mark would be too busy."
        }
    ].

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}, {class, ~"brand-page"}], [
            {section, [{class, ~"demo-hero"}], [
                {'div', [{class, ~"demo-hero-inner"}], [
                    {span, [{class, ~"hero-badge"}], [~"Brand"]},
                    {h1, [{class, ~"hero-title"}], [~"Logos and credit"]},
                    {p, [{class, ~"hero-subtitle"}], [
                        ~"For anyone crediting asobi in a game, a talk, a post or an article. Take what you need, no permission required."
                    ]}
                ]}
            ]},

            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"Logos"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"PNG with transparency. Right-click to save, or link them directly."
                    ]},
                    {'div', [{class, ~"brand-grid"}], [
                        ?each(
                            fun({Name, Src, Size, Note}) ->
                                {'div', [{class, ~"brand-card"}], [
                                    {'div', [{class, ~"brand-preview"}], [
                                        {img, [{src, Src}, {alt, Name}]}
                                    ]},
                                    {h3, [], [Name]},
                                    {p, [{class, ~"brand-size"}], [Size]},
                                    {p, [], [Note]},
                                    {a, [{href, Src}, {download, true}], [~"Download PNG"]}
                                ]}
                            end,
                            logos()
                        )
                    ]}
                ]}
            ]},

            {section, [{class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"Splash screens"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Crediting asobi in your game is welcome and entirely optional. Nothing in the licence asks for it, and nothing changes if you leave it out."
                    ]},
                    {ul, [{class, ~"brand-rules"}], [
                        {li, [], [
                            ~"Use the mark or the full logo. Keep clear space around it of at least half the mark's height."
                        ]},
                        {li, [], [~"Render it at 96px tall or more so it stays legible."]},
                        {li, [], [
                            ~"Both artworks carry their own colour. Put them on a background that keeps them readable rather than recolouring them."
                        ]},
                        {li, [], [
                            ~"Two seconds is plenty. Let players skip it. A splash nobody can dismiss annoys players and reflects on you, not on us."
                        ]}
                    ]},
                    {h3, [{class, ~"brand-subhead"}], [~"Credit line"]},
                    {p, [], [~"If you would rather use text than a logo:"]},
                    {pre, [{class, ~"brand-credit"}], [
                        {code, [], [~"Multiplayer powered by asobi - asobi.dev"]}
                    ]}
                ]}
            ]},

            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"What not to do"]},
                    {ul, [{class, ~"brand-rules"}], [
                        {li, [], [
                            ~"Do not stretch, rotate, recolour or add effects to the artwork."
                        ]},
                        {li, [], [
                            ~"Do not use the logo as your own app icon, or as part of your own logo."
                        ]},
                        {li, [], [
                            ~"Do not imply that we built, endorse or support your game. Crediting the backend is fine, a partnership claim is not."
                        ]}
                    ]},
                    {p, [{class, ~"brand-legal"}], [
                        ~"asobi is Apache 2.0. The asobi name and logo belong to Widgrens IT AB and are not covered by that licence. Using them to say your game runs on asobi is fine. If you are unsure, ask on Discord."
                    ]}
                ]}
            ]}
        ]}
    ).
