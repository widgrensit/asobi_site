-module(asobi_site_cloud_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"cloud"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            %% Hero
            {section, [{class, ~"hero"}], [
                {'div', [{class, ~"hero-inner"}], [
                    {span, [{class, ~"hero-badge"}], [~"Live \x{00B7} console.asobi.dev"]},
                    {p, [{class, ~"hero-eyebrow"}], [
                        {span, [{class, ~"marker"}], [~"\x{00A7} Cloud"]},
                        ~" \x{2002}EU-sovereign managed Asobi"
                    ]},
                    {h1, [{class, ~"hero-title"}], [
                        ~"A game backend ",
                        {br, [], []},
                        ~"that won\x{2019}t ",
                        {em, [], [~"rug-pull"]},
                        ~" you."
                    ]},
                    {p, [{class, ~"hero-subtitle"}], [
                        ~"Managed Asobi, hosted in the EU. ",
                        ~"Open-source core so you can self-host the day we disappoint you. ",
                        ~"Create your environment and deploy in minutes. ",
                        ~"Invite-only for now - an invite is a Discord message away."
                    ]},
                    {p, [{class, ~"hero-notice"}], [
                        ~"Hathora shut down on 5 May 2026. Stormgate, Splitgate 2 and ",
                        ~"Predecessor lost their servers. ",
                        ~"If your backend vanishes tomorrow, what is your plan B?"
                    ]},
                    {'div', [{class, ~"hero-actions"}], [
                        {a, [{href, ~"https://console.asobi.dev"}, {class, ~"btn btn-primary"}], [
                            ~"Create your environment",
                            {span, [{class, ~"arrow"}], [~" \x{2192}"]}
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

            %% Why us
            {section, [{id, ~"why-cloud"}, {class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {p, [{class, ~"section-marker"}], [~"01 / Sovereignty"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"EU-hosted. Not ",
                        {em, [], [~"EU-washed."]}
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Everything you run on Asobi Cloud stays on French-sovereign ",
                        ~"infrastructure. No US sub-processors. No CLOUD Act exposure. ",
                        ~"DPA ready from day one."
                    ]},
                    {'div', [{class, ~"feature-grid"}], [
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Your backend cannot get acqui-hired"]},
                            {p, [], [
                                ~"The core engine is Apache-2 and lives on GitHub. ",
                                ~"If we close shop tomorrow, you pull the image, point DNS at ",
                                ~"your own server, and keep running. No lock-in. No cliff."
                            ]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"French-sovereign by default"]},
                            {p, [], [
                                ~"Hosted on Scaleway, a French cloud provider, in EU regions. ",
                                ~"Explicit CLOUD Act protection in contract."
                            ]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"GDPR out of the box"]},
                            {p, [], [
                                ~"Data export and deletion endpoints per player. ",
                                ~"72-hour breach notification clause. ",
                                ~"DPA based on EU Standard Contractual Clauses."
                            ]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Built for indies, priced for indies"]},
                            {p, [], [
                                ~"Flat per-environment pricing, no per-seat surprises. ",
                                ~"See current plans on ",
                                {a, [{href, ~"https://console.asobi.dev"}], [~"the console"]},
                                ~"."
                            ]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
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

            %% Proof — benchmark scoreboard
            {section, [{id, ~"proof"}, {class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {p, [{class, ~"section-marker"}], [~"02 / Proof"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"Numbers we\x{2019}ve ",
                        {em, [], [~"actually"]},
                        ~" measured"
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Real WebSocket load against a single 8-core BEAM node. ",
                        ~"Benchmark scripts are in the repo so you can reproduce them."
                    ]},
                    {'div', [{class, ~"bench"}], [
                        {'div', [{class, ~"bench-cell"}], [
                            {p, [{class, ~"bench-cell-label"}], [~"Throughput"]},
                            {p, [{class, ~"bench-cell-value"}], [
                                ~"49,000",
                                {span, [{class, ~"unit"}], [~"msg/sec"]}
                            ]},
                            {p, [{class, ~"bench-cell-note"}], [
                                ~"Zero drops. 10.7 ms p50 round-trip. Single 8-core node."
                            ]}
                        ]},
                        {'div', [{class, ~"bench-cell"}], [
                            {p, [{class, ~"bench-cell-label"}], [~"Concurrency"]},
                            {p, [{class, ~"bench-cell-value"}], [
                                ~"4,613",
                                {span, [{class, ~"unit"}], [~"ws conns"]}
                            ]},
                            {p, [{class, ~"bench-cell-note"}], [
                                ~"Zero failures. ~15 KB RAM per connection. Room for 100K+."
                            ]}
                        ]},
                        {'div', [{class, ~"bench-cell"}], [
                            {p, [{class, ~"bench-cell-label"}], [~"World scale"]},
                            {p, [{class, ~"bench-cell-value"}], [
                                ~"2,000\x{00D7}2,000",
                                {span, [{class, ~"unit"}], [~"zone grid"]}
                            ]},
                            {p, [{class, ~"bench-cell-note"}], [
                                ~"MMO-scale spatial grid, 500 players, 208 MB RAM, zero errors."
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            %% Get started
            {section, [{id, ~"beta"}, {class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {p, [{class, ~"section-marker"}], [~"03 / Start"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"Ready to ",
                        {em, [], [~"ship"]},
                        ~"?"
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Asobi Cloud is invite-only while we onboard each studio personally - ",
                        ~"ask on Discord and we'll set you up, usually the same day. ",
                        ~"We aim to open signup more widely toward the end of 2026. ",
                        ~"Already invited? Create an environment and deploy your Lua with the ",
                        {code, [], [~"asobi"]},
                        ~" CLI. New to Asobi? The quick start walks you through it end to end."
                    ]},
                    {'div', [{class, ~"beta-cta"}], [
                        {'div', [{class, ~"beta-cta-actions"}], [
                            {a,
                                [
                                    {href, ~"https://console.asobi.dev"},
                                    {class, ~"btn btn-primary btn-lg"}
                                ],
                                [~"Create your environment \x{2192}"]},
                            {a,
                                [
                                    {href, ~"https://discord.gg/vYSfYYyXpu"},
                                    {class, ~"btn btn-secondary btn-lg"}
                                ],
                                [~"Or ask us on Discord"]}
                        ]},
                        {p, [{class, ~"beta-cta-note"}], [
                            ~"Then follow the ",
                            {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"quick start"]},
                            ~" to deploy your first game. Want to try Cloud before ",
                            ~"paying? Ping us on ",
                            {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                            ~" and we\x{2019}ll set you up with an environment."
                        ]}
                    ]}
                ]}
            ]}
        ]}
    ).
