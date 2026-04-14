-module(asobi_site_cloud_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"cloud"}, Bindings), #{}}.

-spec render(map()) -> term().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            %% Nav (same shape as home)
            {nav, [{class, ~"site-nav"}], [
                {'div', [{class, ~"nav-inner"}], [
                    {a, [{href, ~"/"}, {class, ~"nav-brand"}], [
                        {span, [{class, ~"brand-icon"}], [<<16#904A/utf8>>]},
                        {span, [{class, ~"brand-text"}], [~"asobi"]}
                    ]},
                    {input, [{type, ~"checkbox"}, {id, ~"nav-toggle"}, {class, ~"nav-toggle"}], []},
                    {label,
                        [{for, ~"nav-toggle"}, {class, ~"nav-hamburger"}, {'aria-label', ~"Menu"}],
                        [
                            {span, [], []},
                            {span, [], []},
                            {span, [], []}
                        ]},
                    {'div', [{class, ~"nav-links"}], [
                        {a, [{href, ~"/"}], [~"Home"]},
                        {a, [{href, ~"/demo"}], [~"Demo"]},
                        {a, [{href, ~"/cloud"}, {class, ~"nav-link-btn"}], [~"Cloud"]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi"},
                                {class, ~"nav-github"}
                            ],
                            [~"GitHub"]}
                    ]}
                ]}
            ]},

            %% Post-submit success banner (toggled by JS below when ?submitted=1).
            {'div',
                [
                    {id, ~"beta-success-banner"},
                    {class, ~"success-banner"},
                    {style, ~"display:none"},
                    {role, ~"status"},
                    {'aria-live', ~"polite"}
                ],
                [
                    {'div', [{class, ~"success-banner-inner"}], [
                        {span, [{class, ~"success-banner-icon"}], [~"\x{2713}"]},
                        {'div', [{class, ~"success-banner-text"}], [
                            {strong, [], [~"Thanks \x{2014} we've got your request."]},
                            {span, [], [
                                ~" We'll reply personally within a day. ",
                                ~"In the meantime, ",
                                {a, [{href, ~"https://github.com/widgrensit/asobi"}], [
                                    ~"star the repo"
                                ]},
                                ~" or ",
                                {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"join Discord"]},
                                ~"."
                            ]}
                        ]},
                        {button,
                            [
                                {type, ~"button"},
                                {class, ~"success-banner-close"},
                                {'aria-label', ~"Dismiss"},
                                {onclick,
                                    ~"document.getElementById('beta-success-banner').style.display='none'"}
                            ],
                            [~"\x{00D7}"]}
                    ]}
                ]},
            {script, [], [
                ~"if (new URLSearchParams(window.location.search).has('submitted')) {",
                ~"var b = document.getElementById('beta-success-banner');",
                ~"if (b) b.style.display = 'block';",
                ~"}"
            ]},

            %% Hero
            {section, [{class, ~"hero"}], [
                {'div', [{class, ~"hero-blob-left"}], []},
                {'div', [{class, ~"hero-blob-right"}], []},
                {'div', [{class, ~"hero-inner"}], [
                    {span, [{class, ~"hero-badge"}], [~"Closed beta \x{2014} Q3 2026"]},
                    {h1, [{class, ~"hero-title"}], [
                        ~"A game backend ",
                        {br, [], []},
                        ~"that won\x{2019}t rug-pull you."
                    ]},
                    {p, [{class, ~"hero-subtitle"}], [
                        ~"Managed Asobi, hosted in the EU. ",
                        ~"Open-source core so you can self-host the day we disappoint you. ",
                        ~"From \x{20AC}9/month."
                    ]},
                    {p, [{class, ~"hero-notice"}], [
                        ~"Hathora shut down on 5 May 2026. Stormgate, Splitgate 2 and Predecessor ",
                        ~"lost their servers. If your backend vanishes tomorrow, what is your plan B?"
                    ]},
                    {'div', [{class, ~"hero-actions"}], [
                        {a, [{href, ~"https://tally.so/r/0QJ44Z"}, {class, ~"btn btn-primary"}], [
                            ~"Request beta access"
                        ]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi"},
                                {class, ~"btn btn-secondary"}
                            ],
                            [~"Or self-host on GitHub"]}
                    ]}
                ]}
            ]},

            %% Why us — bento
            {section, [{id, ~"why-cloud"}, {class, ~"section section-alt"}], [
                {'div', [{class, ~"section-inner"}], [
                    {'div', [{class, ~"section-header-split"}], [
                        {'div', [], [
                            {p, [{class, ~"section-eyebrow"}], [~"Sovereignty"]},
                            {h2, [{class, ~"section-title"}], [~"EU-hosted. Not EU-washed."]}
                        ]},
                        {p, [{class, ~"section-subtitle"}], [
                            ~"Everything you run on Asobi Cloud stays on French-sovereign ",
                            ~"infrastructure. No US sub-processors. No CLOUD Act exposure. ",
                            ~"DPA ready from day one."
                        ]}
                    ]},
                    {'div', [{class, ~"bento-grid"}], [
                        {'div', [{class, ~"bento-card bento-card-wide"}], [
                            {h3, [], [~"Your backend cannot get acqui-hired"]},
                            {p, [], [
                                ~"The core engine is Apache-2 and lives on GitHub. ",
                                ~"If we close shop tomorrow, you pull the image, point DNS at ",
                                ~"your own server, and keep running. No lock-in. No cliff."
                            ]}
                        ]},
                        {'div', [{class, ~"bento-card"}], [
                            {h3, [], [~"French-sovereign by default"]},
                            {p, [], [
                                ~"Hosted on Clever Cloud (Nantes, France). ",
                                ~"SecNumCloud partner. Explicit CLOUD Act protection in contract."
                            ]}
                        ]},
                        {'div', [{class, ~"bento-card"}], [
                            {h3, [], [~"GDPR out of the box"]},
                            {p, [], [
                                ~"Data export and deletion endpoints per player. ",
                                ~"72-hour breach notification clause. ",
                                ~"DPA based on EU Standard Contractual Clauses."
                            ]}
                        ]},
                        {'div', [{class, ~"bento-card"}], [
                            {h3, [], [~"Built for indies, priced for indies"]},
                            {p, [], [
                                ~"From \x{20AC}9/month for Indie (10k MAU, 200 CCU). ",
                                ~"\x{20AC}29 for Studio. \x{20AC}79 for Pro. ",
                                ~"No per-seat surprises."
                            ]}
                        ]},
                        {'div', [{class, ~"bento-card bento-card-wide"}], [
                            {h3, [], [~"Hot-reload Lua. Ship during the playtest."]},
                            {p, [], [
                                ~"Your match logic is a Lua file running inside the BEAM. ",
                                ~"Upload a new version and it swaps in without restarting matches. ",
                                ~"Nakama\x{2019}s had this as an open issue since 2018."
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            %% Proof
            {section, [{id, ~"proof"}, {class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {'div', [{class, ~"section-header-split"}], [
                        {'div', [], [
                            {p, [{class, ~"section-eyebrow"}], [~"Proof, not promises"]},
                            {h2, [{class, ~"section-title"}], [
                                ~"Numbers we\x{2019}ve actually measured."
                            ]}
                        ]},
                        {p, [{class, ~"section-subtitle"}], [
                            ~"Real WebSocket load against a single 8-core BEAM node. ",
                            ~"Benchmark scripts are in the repo so you can reproduce them."
                        ]}
                    ]},
                    {'div', [{class, ~"bento-grid"}], [
                        {'div', [{class, ~"bento-card"}], [
                            {h3, [], [~"49 000 msg/sec"]},
                            {p, [], [
                                ~"WebSocket throughput, zero message drops, 10.7 ms p50 round-trip."
                            ]}
                        ]},
                        {'div', [{class, ~"bento-card"}], [
                            {h3, [], [~"4 613 WS connections"]},
                            {p, [], [
                                ~"Single node, zero failures, \x{2248} 15 KB RAM per connection."
                            ]}
                        ]},
                        {'div', [{class, ~"bento-card"}], [
                            {h3, [], [~"2 000 \x{00D7} 2 000 zones"]},
                            {p, [], [
                                ~"MMO-scale spatial grid, 500 players, 208 MB RAM, zero errors."
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            %% Beta signup
            {section, [{id, ~"beta"}, {class, ~"section section-alt"}], [
                {'div', [{class, ~"section-inner"}], [
                    {'div', [{class, ~"section-header-split"}], [
                        {'div', [], [
                            {p, [{class, ~"section-eyebrow"}], [~"Closed beta"]},
                            {h2, [{class, ~"section-title"}], [~"Want to try it?"]}
                        ]},
                        {p, [{class, ~"section-subtitle"}], [
                            ~"We\x{2019}re onboarding our first studios in Q3 2026. ",
                            ~"Leave your email and tell us which engine you use. ",
                            ~"We reply personally within a day."
                        ]}
                    ]},
                    {'div', [{class, ~"beta-cta"}], [
                        {a,
                            [
                                {href, ~"https://tally.so/r/0QJ44Z"},
                                {class, ~"btn btn-primary btn-large"}
                            ],
                            [~"Request beta access \x{2192}"]},
                        {p, [{class, ~"beta-cta-note"}], [
                            ~"Takes under a minute. No credit card, no sales call. ",
                            ~"We reply within a day."
                        ]}
                    ]}
                ]}
            ]},

            %% Footer (compact — reuses home classes)
            {footer, [{class, ~"site-footer"}], [
                {'div', [{class, ~"footer-inner"}], [
                    {'div', [{class, ~"footer-brand"}], [
                        {span, [{class, ~"brand-icon"}], [<<16#904A/utf8>>]},
                        {span, [{class, ~"brand-text"}], [~"asobi"]}
                    ]},
                    {'div', [{class, ~"footer-links"}], [
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"Product"]},
                            {a, [{href, ~"/"}], [~"Home"]},
                            {a, [{href, ~"/cloud"}], [~"Cloud"]},
                            {a, [{href, ~"/demo"}], [~"Demo"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"GitHub"]}
                        ]},
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"Legal"]},
                            {a, [{href, ~"/terms"}], [~"Terms"]},
                            {a, [{href, ~"/privacy"}], [~"Privacy"]},
                            {a, [{href, ~"/dpa"}], [~"DPA"]}
                        ]},
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"Company"]},
                            {p, [{class, ~"footer-note"}], [
                                ~"Widgrensit AB",
                                {br, [], []},
                                ~"Sweden"
                            ]}
                        ]}
                    ]}
                ]},
                {'div', [{class, ~"footer-bottom"}], [
                    {p, [], [~"Apache 2.0 \x{2014} widgrensit"]}
                ]}
            ]}
        ]}
    ).
