-module(asobi_site_home_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"home"}, Bindings), #{}}.

-spec render(map()) -> term().
render(Bindings) ->
    DepSnippet = ~"{asobi, \"~> 0.1\"}",
    ?html(
        {'div', [{id, ?get(id)}], [
            %% Nav
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
                        {a, [{href, ~"#why"}], [~"Why Erlang?"]},
                        {a, [{href, ~"#features"}], [~"Features"]},
                        {a, [{href, ~"#sdks"}], [~"SDKs"]},
                        {a, [{href, ~"/demo"}], [~"Demo"]},
                        {a, [{href, ~"https://play.asobi.dev"}, {class, ~"nav-link-play"}], [
                            <<16#1F3AE/utf8>>, ~" Play"
                        ]},
                        {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}, {class, ~"nav-link-btn"}], [
                            ~"Discord"
                        ]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi"},
                                {class, ~"nav-github"}
                            ],
                            [~"GitHub"]}
                    ]}
                ]}
            ]},

            %% Hero
            {section, [{class, ~"hero"}], [
                {'div', [{class, ~"hero-blob-left"}], []},
                {'div', [{class, ~"hero-blob-right"}], []},
                {'div', [{class, ~"hero-inner"}], [
                    {span, [{class, ~"hero-badge"}], [~"Preview"]},
                    {h1, [{class, ~"hero-title"}], [
                        ~"A multiplayer game backend ",
                        {br, [], []},
                        ~"that doesn't fall over."
                    ]},
                    {p, [{class, ~"hero-subtitle"}], [
                        ~"Erlang/OTP was built for systems that never go down ",
                        ~"and handle massive concurrency. ",
                        ~"That sounded like a game server to me."
                    ]},
                    {p, [{class, ~"hero-notice"}], [
                        ~"Asobi is early. Things will change. But it's open-source, ",
                        ~"it works, and I'd love your help making it better."
                    ]},
                    {'div', [{class, ~"hero-actions"}], [
                        {a, [{href, ~"#get-started"}, {class, ~"btn btn-primary"}], [
                            ~"Get Started"
                        ]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi"},
                                {class, ~"btn btn-secondary"}
                            ],
                            [~"View on GitHub"]}
                    ]}
                ]}
            ]},

            %% Built on the BEAM — Bento Grid
            {section, [{id, ~"why"}, {class, ~"section section-alt"}], [
                {'div', [{class, ~"section-inner"}], [
                    {'div', [{class, ~"section-header-split"}], [
                        {'div', [], [
                            {p, [{class, ~"section-eyebrow"}], [~"Infrastructure"]},
                            {h2, [{class, ~"section-title"}], [~"Built on the BEAM."]}
                        ]},
                        {p, [{class, ~"section-subtitle"}], [
                            ~"The same VM that runs WhatsApp and Discord. ",
                            ~"Designed for millions of concurrent connections with predictable latency."
                        ]}
                    ]},
                    {'div', [{class, ~"bento-grid"}], [
                        %% Wide card: Preemptive Scheduling
                        {'div', [{class, ~"bento-card bento-card-wide"}], [
                            {span, [{class, ~"bento-icon bento-icon-primary"}], [<<16#2699/utf8>>]},
                            {h3, [], [~"Preemptive Scheduling"]},
                            {p, [], [
                                ~"A single heavy request won't freeze your game. ",
                                ~"The BEAM ensures fair execution time for every player connection, ",
                                ~"so a runaway game loop can't starve the matchmaker or auth system."
                            ]}
                        ]},
                        %% Per-Process GC
                        {'div', [{class, ~"bento-card"}], [
                            {span, [{class, ~"bento-icon bento-icon-secondary"}], [<<16#26A1/utf8>>]},
                            {h3, [], [~"Per-Process GC"]},
                            {p, [], [
                                ~"No stop-the-world pauses. Each match manages its own memory, ",
                                ~"keeping frame rates smooth."
                            ]}
                        ]},
                        %% OTP Supervision
                        {'div', [{class, ~"bento-card"}], [
                            {span, [{class, ~"bento-icon bento-icon-tertiary"}], [<<16#1F6E1/utf8>>]},
                            {h3, [], [~"OTP Supervision"]},
                            {p, [], [
                                ~"Self-healing. If a match process crashes, it restarts to a clean state. ",
                                ~"The rest of the server doesn't notice."
                            ]}
                        ]},
                        %% Gradient card: Behaviour Engine + code preview
                        {'div', [{class, ~"bento-card-gradient"}], [
                            {'div', [{class, ~"bento-card-gradient-inner"}], [
                                {'div', [{class, ~"bento-text"}], [
                                    {h3, [{style, ~"font-family:'Space Grotesk',sans-serif;font-size:1.35rem;font-weight:700;color:#fff;margin-bottom:8px"}], [
                                        ~"Behaviour Engine"
                                    ]},
                                    {p, [{style, ~"color:#c9c4d7;font-size:0.92rem;line-height:1.7;margin-bottom:8px"}], [
                                        ~"Write custom match logic using OTP behaviours. ",
                                        ~"Focus on your game, not the protocol."
                                    ]},
                                    {ul, [{class, ~"bento-check-list"}], [
                                        {li, [], [~"Rolling zero-downtime deploys"]},
                                        {li, [], [~"Binary protocol serialization"]}
                                    ]}
                                ]},
                                {'div', [{class, ~"bento-code-preview"}], [
                                    {pre, [], [
                                        {span, [{class, ~"kw"}], [~"-module"]},
                                        ~"(arena_match).\n",
                                        {span, [{class, ~"kw"}], [~"-behaviour"]},
                                        ~"(asobi_match).\n\n",
                                        {span, [{class, ~"fn"}], [~"init"]},
                                        ~"(Opts) ->\n",
                                        ~"  #{max_players => 8,\n",
                                        ~"    tick_rate   => 10}.\n\n",
                                        {span, [{class, ~"fn"}], [~"handle_join"]},
                                        ~"(Id, _Meta, State) ->\n",
                                        ~"  {ok, add_player(Id, State)}."
                                    ]}
                                ]}
                            ]}
                        ]},
                        %% Cloud Native
                        {'div', [{class, ~"bento-card"}], [
                            {span, [{class, ~"bento-icon bento-icon-secondary"}], [<<16#2601/utf8>>]},
                            {h3, [], [~"Cloud Native"]},
                            {p, [], [
                                ~"Graceful shutdown, health endpoints, rolling deploys. ",
                                ~"Built for Fly.io, Kubernetes, or any orchestrator."
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            %% Why Erlang — prose
            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title section-title-center"}], [
                        ~"Why Erlang for game servers?"
                    ]},
                    {'div', [{class, ~"why-prose"}], [
                        {p, [], [
                            ~"Most game backends are built on Go or Node.js. They work. ",
                            ~"But they weren't designed for this."
                        ]},
                        {p, [], [
                            ~"Erlang was built at Ericsson in the 80s to run telephone switches \x{2014} ",
                            ~"systems that needed to handle millions of concurrent calls, never go down, ",
                            ~"and be upgraded without disconnecting anyone. ",
                            ~"Sound familiar? That's a game server."
                        ]},
                        {p, [], [
                            ~"Every match in Asobi is an Erlang process. If it crashes, ",
                            ~"only that match is affected. The rest of the server doesn't notice. ",
                            ~"Each process has its own garbage collector, so one laggy match ",
                            ~"can't cause frame drops in another. And because the BEAM VM ",
                            ~"preemptively schedules processes, a runaway game loop can't ",
                            ~"starve the matchmaker or auth system."
                        ]},
                        {p, [], [
                            ~"This is the same tech stack behind WhatsApp (2 million connections per server) ",
                            ~"and Discord (millions of concurrent users). ",
                            ~"It's not new or experimental \x{2014} it's battle-tested for exactly this kind of work."
                        ]}
                    ]}
                ]}
            ]},

            %% What's in the box
            {section, [{id, ~"features"}, {class, ~"section section-alt"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title section-title-center"}], [~"What's in the box"]},
                    {p, [{class, ~"section-subtitle section-subtitle-center"}], [
                        ~"One ",
                        {code, [], [~"rebar3 release"]},
                        ~" gives you all of this. No Redis, no Kafka, no microservice sprawl."
                    ]},
                    {'div', [{class, ~"feature-grid"}], [
                        {'div', [{class, ~"feature-card"}], [
                            {'div', [{class, ~"feature-icon feature-icon-primary"}], [<<16#1F511/utf8>>]},
                            {h3, [], [~"Authentication"]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {'div', [{class, ~"feature-icon feature-icon-secondary"}], [<<16#1F465/utf8>>]},
                            {h3, [], [~"Matchmaking"]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {'div', [{class, ~"feature-icon feature-icon-tertiary"}], [<<16#1F504/utf8>>]},
                            {h3, [], [~"Real-Time Sync"]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {'div', [{class, ~"feature-icon feature-icon-error"}], [<<16#1F4BE/utf8>>]},
                            {h3, [], [~"State Persistence"]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {'div', [{class, ~"feature-icon feature-icon-primary"}], [<<16#1F4AC/utf8>>]},
                            {h3, [], [~"Chat"]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {'div', [{class, ~"feature-icon feature-icon-secondary"}], [<<16#1F3C6/utf8>>]},
                            {h3, [], [~"Leaderboards"]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {'div', [{class, ~"feature-icon feature-icon-tertiary"}], [<<16#1F392/utf8>>]},
                            {h3, [], [~"Inventory"]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {'div', [{class, ~"feature-icon feature-icon-error"}], [<<16#1F4CA/utf8>>]},
                            {h3, [], [~"Live Telemetry"]}
                        ]}
                    ]}
                ]}
            ]},

            %% Code example
            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title section-title-center"}], [
                        ~"This is all the server code you write"
                    ]},
                    {p, [{class, ~"section-subtitle section-subtitle-center"}], [
                        ~"Implement the ",
                        {code, [], [~"asobi_match"]},
                        ~" behaviour. Asobi handles connections, ",
                        ~"broadcasting, tick scheduling, and crash recovery."
                    ]},
                    {'div', [{class, ~"code-block"}], [
                        {pre, [], [{code, [], [code_snippet()]}]}
                    ]}
                ]}
            ]},

            %% Status / Roadmap
            {section, [{class, ~"section section-alt"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title section-title-center"}], [~"Where things stand"]},
                    {p, [{class, ~"section-subtitle section-subtitle-center"}], [
                        ~"Honest status. No \x{201c}enterprise-ready\x{201d} hand-waving."
                    ]},
                    {'div', [{class, ~"status-grid"}], [
                        {'div', [{class, ~"status-card status-done"}], [
                            {span, [{class, ~"status-indicator"}], [~"Solid"]},
                            {h3, [], [~"Core loop"]},
                            {p, [], [~"Match lifecycle, tick scheduling, WebSocket sync, player join/leave/reconnect."]}
                        ]},
                        {'div', [{class, ~"status-card status-done"}], [
                            {span, [{class, ~"status-indicator"}], [~"Solid"]},
                            {h3, [], [~"Auth & sessions"]},
                            {p, [], [~"Registration, login, JWT, OAuth flows."]}
                        ]},
                        {'div', [{class, ~"status-card status-done"}], [
                            {span, [{class, ~"status-indicator"}], [~"Solid"]},
                            {h3, [], [~"Matchmaking"]},
                            {p, [], [~"Queue-based pairing, lobbies, custom game modes."]}
                        ]},
                        {'div', [{class, ~"status-card status-wip"}], [
                            {span, [{class, ~"status-indicator"}], [~"WIP"]},
                            {h3, [], [~"Economy & inventory"]},
                            {p, [], [~"Wallets and transactions work. Store UI and item definitions are still rough."]}
                        ]},
                        {'div', [{class, ~"status-card status-wip"}], [
                            {span, [{class, ~"status-indicator"}], [~"WIP"]},
                            {h3, [], [~"Admin dashboard"]},
                            {p, [], [~"Player management works. Match inspection and economy tools coming."]}
                        ]},
                        {'div', [{class, ~"status-card status-planned"}], [
                            {span, [{class, ~"status-indicator"}], [~"Planned"]},
                            {h3, [], [~"Clustering"]},
                            {p, [], [~"Multi-node distribution with automatic match migration. The BEAM makes this possible \x{2014} just haven't built it yet."]}
                        ]}
                    ]}
                ]}
            ]},

            %% SDKs
            {section, [{id, ~"sdks"}, {class, ~"section section-deep"}], [
                {'div', [{class, ~"section-inner"}], [
                    {'div', [{class, ~"sdk-outer-card"}], [
                        {'div', [{class, ~"sdk-layout"}], [
                            {'div', [], [
                                {h2, [{class, ~"section-title"}], [~"Client SDKs"]},
                                {p, [{class, ~"section-subtitle"}], [
                                    ~"Pick your engine. All SDKs share the same API surface."
                                ]},
                                {'div', [{class, ~"sdk-chips"}], [
                                    {a, [{href, ~"/unity"}, {class, ~"sdk-chip"}], [
                                        ~"Unity",
                                        {span, [{class, ~"sdk-chip-lang"}], [~"C#"]}
                                    ]},
                                    {a, [{href, ~"/unreal"}, {class, ~"sdk-chip"}], [
                                        ~"Unreal",
                                        {span, [{class, ~"sdk-chip-lang"}], [~"C++"]}
                                    ]},
                                    {a, [{href, ~"/godot"}, {class, ~"sdk-chip"}], [
                                        ~"Godot",
                                        {span, [{class, ~"sdk-chip-lang"}], [~"GDScript"]}
                                    ]},
                                    {a, [{href, ~"/defold"}, {class, ~"sdk-chip"}], [
                                        ~"Defold",
                                        {span, [{class, ~"sdk-chip-lang"}], [~"Lua"]}
                                    ]},
                                    {a, [{href, ~"/dart"}, {class, ~"sdk-chip"}], [
                                        ~"Dart / Flutter",
                                        {span, [{class, ~"sdk-chip-lang"}], [~"Dart"]}
                                    ]},
                                    {a, [{href, ~"/js"}, {class, ~"sdk-chip"}], [
                                        ~"JavaScript",
                                        {span, [{class, ~"sdk-chip-lang"}], [~"JS/TS"]}
                                    ]}
                                ]}
                            ]},
                            {'div', [{class, ~"code-block"}], [
                                {pre, [], [{code, [], [sdk_snippet()]}]}
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            %% Showcase: Try the game
            {section, [{id, ~"showcase"}, {class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title section-title-center"}], [
                        ~"See it in action"
                    ]},
                    {p, [{class, ~"section-subtitle section-subtitle-center"}], [
                        ~"Don't take our word for it. Play a live multiplayer game ",
                        ~"running on Asobi right now \x{2014} no download, no sign-up."
                    ]},
                    {'div', [{class, ~"cta-card cta-card-play"}], [
                        {'div', [{class, ~"play-cta-inner"}], [
                            {'div', [{class, ~"play-cta-text"}], [
                                {span, [{class, ~"hero-badge"}], [~"Live"]},
                                {h3, [], [~"Asobi Arena"]},
                                {p, [], [
                                    ~"Top-down arena shooter with character progression and voting. ",
                                    ~"WASD to move, mouse to aim, click to shoot. ",
                                    ~"Built with three Erlang modules and ~500 lines of game logic."
                                ]},
                                {'div', [{class, ~"hero-actions"}], [
                                    {a,
                                        [
                                            {href, ~"https://play.asobi.dev"},
                                            {class, ~"btn btn-primary btn-lg"},
                                            {target, ~"_blank"}
                                        ],
                                        [<<16#1F3AE/utf8>>, ~" Play Now"]},
                                    {a,
                                        [{href, ~"/demo"}, {class, ~"btn btn-secondary"}],
                                        [~"How it works"]}
                                ]}
                            ]},
                            {'div', [{class, ~"play-cta-details"}], [
                                {'div', [{class, ~"play-detail"}], [
                                    {span, [{class, ~"play-detail-icon"}], [<<16#1F310/utf8>>]},
                                    {span, [], [~"Runs in your browser"]}
                                ]},
                                {'div', [{class, ~"play-detail"}], [
                                    {span, [{class, ~"play-detail-icon"}], [<<16#26A1/utf8>>]},
                                    {span, [], [~"Real-time WebSocket"]}
                                ]},
                                {'div', [{class, ~"play-detail"}], [
                                    {span, [{class, ~"play-detail-icon"}], [<<16#1F1EA/utf8, 16#1F1FA/utf8>>]},
                                    {span, [], [~"Hosted in EU (Stockholm)"]}
                                ]}
                            ]}
                        ]}
                    ]},
                    {'div', [{class, ~"showcase-more"}], [
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi_arena"},
                                {class, ~"showcase-demo-card"}
                            ],
                            [
                                {span, [{class, ~"showcase-demo-icon"}], [<<16#1F4BB/utf8>>]},
                                {'div', [], [
                                    {strong, [], [~"View the source"]},
                                    {p, [], [~"Three Erlang modules. ~500 lines. Full multiplayer arena."]}
                                ]}
                            ]}
                    ]}
                ]}
            ]},

            %% Comparison
            {section, [{class, ~"section section-alt"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title section-title-center"}], [~"The honest comparison"]},
                    {p, [{class, ~"section-subtitle section-subtitle-center"}], [
                        ~"Nakama and Colyseus are great projects. Here's where the runtimes actually differ."
                    ]},
                    {'div', [{class, ~"comparison-table-wrap"}], [
                        {table, [{class, ~"comparison-table"}], [
                            {thead, [], [
                                {tr, [], [
                                    {th, [], []},
                                    {th, [{class, ~"highlight"}], [~"Asobi"]},
                                    {th, [], [~"Nakama"]},
                                    {th, [], [~"Colyseus"]}
                                ]}
                            ]},
                            {tbody, [], [
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"Runtime"]},
                                    {td, [{class, ~"highlight"}], [~"BEAM (Erlang/OTP)"]},
                                    {td, [], [~"Go"]},
                                    {td, [], [~"Node.js"]}
                                ]},
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"Garbage Collection"]},
                                    {td, [{class, ~"highlight"}], [~"Per-process, isolated"]},
                                    {td, [], [~"Stop-the-world"]},
                                    {td, [], [~"Stop-the-world"]}
                                ]},
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"Fault Tolerance"]},
                                    {td, [{class, ~"highlight"}], [~"OTP supervision trees"]},
                                    {td, [], [~"Manual recovery"]},
                                    {td, [], [~"Manual recovery"]}
                                ]},
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"Pub/Sub"]},
                                    {td, [{class, ~"highlight"}], [~"Built-in (pg module)"]},
                                    {td, [], [~"Requires Redis"]},
                                    {td, [], [~"Built-in"]}
                                ]},
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"Zero-Downtime Deploys"]},
                                    {td, [{class, ~"highlight"}], [~"Rolling upgrades, graceful shutdown"]},
                                    {td, [], [~"Basic support"]},
                                    {td, [], [~"Manual setup"]}
                                ]},
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"Maturity"]},
                                    {td, [{class, ~"highlight"}], [~"Early / preview"]},
                                    {td, [], [~"Production-proven"]},
                                    {td, [], [~"Production-proven"]}
                                ]},
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"License"]},
                                    {td, [{class, ~"highlight"}], [~"Apache 2.0"]},
                                    {td, [], [~"Apache 2.0"]},
                                    {td, [], [~"MIT"]}
                                ]}
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            %% Getting started — CTA card
            {section, [{id, ~"get-started"}, {class, ~"section section-alt"}], [
                {'div', [{class, ~"section-inner"}], [
                    {'div', [{class, ~"cta-card"}], [
                        {h2, [{class, ~"section-title"}], [~"Try it"]},
                        {'div', [{class, ~"steps"}], [
                            {'div', [{class, ~"step"}], [
                                {'div', [{class, ~"step-number"}], [~"1"]},
                                {'div', [{class, ~"step-content"}], [
                                    {h3, [], [~"Scaffold a project"]},
                                    {p, [], [{code, [], [~"rebar3 nova new my_game fullstack"]}]}
                                ]}
                            ]},
                            {'div', [{class, ~"step"}], [
                                {'div', [{class, ~"step-number"}], [~"2"]},
                                {'div', [{class, ~"step-content"}], [
                                    {h3, [], [~"Add asobi"]},
                                    {p, [], [{code, [], [DepSnippet]}]}
                                ]}
                            ]},
                            {'div', [{class, ~"step"}], [
                                {'div', [{class, ~"step-number"}], [~"3"]},
                                {'div', [{class, ~"step-content"}], [
                                    {h3, [], [~"Write a match module"]},
                                    {p, [], [
                                        ~"Implement ",
                                        {code, [], [~"asobi_match"]},
                                        ~" \x{2014} init, join, input, tick, leave"
                                    ]}
                                ]}
                            ]},
                            {'div', [{class, ~"step"}], [
                                {'div', [{class, ~"step-number"}], [~"4"]},
                                {'div', [{class, ~"step-content"}], [
                                    {h3, [], [~"Run it"]},
                                    {p, [], [{code, [], [~"rebar3 nova serve"]}]}
                                ]}
                            ]}
                        ]},
                        {'div', [{class, ~"steps-cta"}], [
                            {a,
                                [
                                    {href, ~"https://github.com/widgrensit/asobi"},
                                    {class, ~"btn btn-primary"}
                                ],
                                [~"Read the Docs"]}
                        ]}
                    ]}
                ]}
            ]},

            %% Community
            {section, [{id, ~"community"}, {class, ~"section"}], [
                {'div', [{class, ~"section-inner community-section"}], [
                    {h2, [{class, ~"section-title section-title-center"}], [~"Come hang out"]},
                    {p, [{class, ~"section-subtitle section-subtitle-center"}], [
                        ~"I'm building this in the open. If you're into Erlang, ",
                        ~"game dev, or just curious \x{2014} come say hi."
                    ]},
                    {a,
                        [
                            {href, ~"https://discord.gg/vYSfYYyXpu"},
                            {class, ~"btn btn-primary btn-lg"}
                        ],
                        [~"Discord"]}
                ]}
            ]},

            %% Footer
            {footer, [{class, ~"site-footer"}], [
                {'div', [{class, ~"footer-inner"}], [
                    {'div', [{class, ~"footer-brand"}], [
                        {span, [{class, ~"brand-icon"}], [<<16#904A/utf8>>]},
                        ~" asobi",
                        {p, [{class, ~"footer-tagline"}], [
                            ~"Open-source game backend on the BEAM"
                        ]}
                    ]},
                    {'div', [{class, ~"footer-links"}], [
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"Project"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"GitHub"]},
                            {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi/issues"}], [
                                ~"Issues"
                            ]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi/blob/main/LICENSE"}],
                                [~"License"]}
                        ]},
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"SDKs"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-unity"}], [~"Unity"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-unreal"}], [~"Unreal"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-godot"}], [~"Godot"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-defold"}], [~"Defold"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-dart"}], [
                                ~"Flutter / Dart / Flame"
                            ]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-js"}], [~"JavaScript"]}
                        ]},
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"Ecosystem"]},
                            {a, [{href, ~"https://play.asobi.dev"}], [
                                ~"Arena (live demo)"
                            ]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi_admin"}], [
                                ~"Admin Dashboard"
                            ]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi_arena"}], [
                                ~"Arena Source"
                            ]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-unity-demo"}], [
                                ~"Unity Demo"
                            ]}
                        ]},
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"Built With"]},
                            {a, [{href, ~"https://github.com/novaframework/nova"}], [~"Nova"]},
                            {a, [{href, ~"https://github.com/arizona-framework/arizona"}], [
                                ~"Arizona"
                            ]},
                            {a, [{href, ~"https://github.com/Taure/kura"}], [~"Kura"]}
                        ]}
                    ]}
                ]},
                {'div', [{class, ~"footer-bottom"}], [
                    {p, [], [~"Apache 2.0 \x{2014} widgrensit"]},
                    {span, [{class, ~"footer-status"}], [~"Open Source"]}
                ]}
            ]}
        ]}
    ).

%%----------------------------------------------------------------------
%% Code snippets
%%----------------------------------------------------------------------

-spec code_snippet() -> binary().
code_snippet() ->
    ~"""
    -module(arena_match).
    -behaviour(asobi_match).

    -export([init/1, handle_join/3, handle_input/3,
             handle_tick/2, handle_leave/3]).

    init(Opts) ->
        #{max_players => maps:get(max_players, Opts, 8),
          tick_rate   => 10,
          players     => #{},
          projectiles => []}.

    handle_join(PlayerId, _Metadata, State) ->
        Spawn = random_spawn_point(),
        Player = #{pos => Spawn, hp => 100, score => 0},
        {ok, State#{players := maps:put(PlayerId, Player,
                               maps:get(players, State))}}.

    handle_input(PlayerId, #{<<"action">> := <<"fire">>} = Input, State) ->
        Projectile = spawn_projectile(PlayerId, Input),
        {ok, State#{projectiles := [Projectile |
                        maps:get(projectiles, State)]}}.

    handle_tick(_DeltaMs, State) ->
        S1 = move_projectiles(State),
        S2 = detect_collisions(S1),
        {broadcast, S2}.
    """.

-spec sdk_snippet() -> binary().
sdk_snippet() ->
    ~"""
    // Connect from any engine
    var client = new AsobiClient("wss://my-game.fly.dev");
    await client.Auth.Login("player@example.com", "...");

    // Join matchmaking
    var match = await client.Matchmaking.Join("arena", new {
        skill = 1200
    });

    // Send input
    match.SendInput(new { action = "fire", angle = 45.0 });

    // Receive state updates
    match.OnStateUpdate += (state) => {
        UpdateWorld(state);
    };
    """.
