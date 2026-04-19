-module(asobi_site_home_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"home"}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    DepSnippet = ~"{asobi, \"~> 0.1\"}",
    ?html(
        {'div', [{id, ?get(id)}], [
            %% Hero
            {section, [{class, ~"hero"}], [
                {figure, [{class, ~"hero-mascot"}], [
                    {img, [
                        {src, ~"/assets/img/mascot.png"},
                        {alt, ~"The Asobi tanuki, cloaked and holding a controller"},
                        {class, ~"hero-mascot-img"},
                        {loading, ~"eager"},
                        {decoding, ~"async"}
                    ]},
                    {figcaption, [{class, ~"hero-mascot-caption"}], [
                        ~"Your matches are in ",
                        {em, [], [~"these paws."]}
                    ]}
                ]},
                {'div', [{class, ~"hero-inner"}], [
                    {span, [{class, ~"hero-badge"}], [~"Preview \x{2014} v0.1"]},
                    {p, [{class, ~"hero-eyebrow"}], [
                        {span, [{class, ~"marker"}], [~"\x{00A7} 01"]},
                        ~" \x{2002}Open-source game backend on the BEAM"
                    ]},
                    {h1, [{class, ~"hero-title"}], [
                        ~"Your game ",
                        {br, [], []},
                        ~"never goes ",
                        {em, [], [~"down."]}
                    ]},
                    {p, [{class, ~"hero-subtitle"}], [
                        ~"A multiplayer game backend built on Erlang/OTP. ",
                        ~"Fault-tolerant by design. Zero-downtime deploys. ",
                        ~"100K+ concurrent connections per node."
                    ]},
                    {p, [{class, ~"hero-notice"}], [
                        ~"Asobi is early but fully open-source and ready to play with. ",
                        ~"Spin it up, prototype your next game, ",
                        ~"and help shape the future of game backends on the BEAM."
                    ]},
                    {'div', [{class, ~"hero-actions"}], [
                        {a, [{href, ~"#get-started"}, {class, ~"btn btn-primary"}], [
                            ~"Get started",
                            {span, [{class, ~"arrow"}], [~" \x{2192}"]}
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

            %% Why BEAM
            {section, [{id, ~"why-beam"}, {class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {p, [{class, ~"section-marker"}], [~"02 / Runtime"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"Built on the ",
                        {em, [], [~"BEAM"]}
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"The same virtual machine that powers WhatsApp, Discord, and RabbitMQ. ",
                        ~"Designed for millions of concurrent connections with predictable latency."
                    ]},

                    %% Process-isolation metaphor — 20x4 dot grid. Two dots
                    %% cycle through a crash/restart loop; the rest stay up.
                    {'div', [{class, ~"process-dots"}, {'aria-hidden', ~"true"}], [
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot fault-1"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot fault-2"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []},
                        {'div', [{class, ~"process-dot"}], []}
                    ]},
                    {p, [{class, ~"process-caption"}], [
                        {span, [{class, ~"ok"}], [~"\x{25A0} 58 processes up"]},
                        ~"\x{2003}\x{00B7}\x{2003}",
                        {span, [{class, ~"fail"}], [~"\x{25A0} 2 supervised restart"]},
                        ~"\x{2003}\x{00B7}\x{2003}",
                        ~"zero impact to neighbours"
                    ]},

                    {'div', [{class, ~"beam-grid"}], [
                        {'div', [{class, ~"beam-card"}], [
                            {'div', [{class, ~"beam-card-icon"}], [<<16#2699/utf8>>]},
                            {h3, [], [~"Per-Process GC"]},
                            {p, [], [
                                ~"Each match runs in its own process with isolated garbage collection. No stop-the-world pauses affecting other players."
                            ]}
                        ]},
                        {'div', [{class, ~"beam-card"}], [
                            {'div', [{class, ~"beam-card-icon"}], [<<16#26A1/utf8>>]},
                            {h3, [], [~"Preemptive Scheduling"]},
                            {p, [], [
                                ~"The BEAM scheduler ensures fair CPU time for every match. One expensive operation cannot starve others."
                            ]}
                        ]},
                        {'div', [{class, ~"beam-card"}], [
                            {'div', [{class, ~"beam-card-icon"}], [<<16#1F6E1/utf8>>]},
                            {h3, [], [~"OTP Supervision"]},
                            {p, [], [
                                ~"If a match process crashes, it restarts automatically. Players reconnect to a fresh state. The server is unaffected."
                            ]}
                        ]},
                        {'div', [{class, ~"beam-card"}], [
                            {'div', [{class, ~"beam-card-icon"}], [<<16#2601/utf8>>]},
                            {h3, [], [~"Cloud Native"]},
                            {p, [], [
                                ~"Graceful shutdown, health endpoints, and rolling deploys out of the box. Built for Kubernetes, Fly.io, and any container orchestrator."
                            ]}
                        ]},
                        {'div', [{class, ~"beam-card"}], [
                            {'div', [{class, ~"beam-card-icon"}], [<<16#1F4C8/utf8>>]},
                            {h3, [], [~"100K+ Connections"]},
                            {p, [], [
                                ~"Lightweight processes and efficient I/O multiplexing. Handle half a million concurrent WebSocket connections per node."
                            ]}
                        ]},
                        {'div', [{class, ~"beam-card"}], [
                            {'div', [{class, ~"beam-card-icon"}], [<<16#1F4CA/utf8>>]},
                            {h3, [], [~"Built-in Observability"]},
                            {p, [], [
                                ~"OpenTelemetry integration, structured logging, and Telemetry events. Monitor every match, queue, and connection."
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            %% Features
            {section, [{id, ~"features"}, {class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {p, [{class, ~"section-marker"}], [~"03 / Kit"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"Everything you ",
                        {em, [], [~"need"]}
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"A complete backend for multiplayer games. One release, no external dependencies."
                    ]},
                    {'div', [{class, ~"feature-grid"}], [
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Authentication"]},
                            {p, [], [
                                ~"Player registration, login, sessions, and OAuth. Built on nova_auth."
                            ]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Matchmaking"]},
                            {p, [], [
                                ~"Automatic player pairing with configurable rules. Lobby and queue support."
                            ]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Real-Time Sync"]},
                            {p, [], [
                                ~"WebSocket-based state synchronization at configurable tick rates."
                            ]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Leaderboards"]},
                            {p, [], [
                                ~"Ranked scoring with ETS-backed storage. Per-game, per-season, global."
                            ]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Virtual Economy"]},
                            {p, [], [~"Wallets, transactions, inventory, and in-game store."]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Social"]},
                            {p, [], [~"Friends, groups, chat, and notifications."]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Cloud Saves"]},
                            {p, [], [~"Persistent player data storage with versioning."]}
                        ]},
                        {'div', [{class, ~"feature-card"}], [
                            {h3, [], [~"Admin Dashboard"]},
                            {p, [], [~"Web-based management UI for players, matches, and economy."]}
                        ]}
                    ]}
                ]}
            ]},

            %% SDKs
            {section, [{id, ~"sdks"}, {class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {p, [{class, ~"section-marker"}], [~"04 / Clients"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"SDKs for ",
                        {em, [], [~"every"]},
                        ~" engine"
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Official client libraries with full API coverage. Pick your engine and start building."
                    ]},
                    {'div', [{class, ~"sdk-grid"}], [
                        {a, [{href, ~"/unity"}, {class, ~"sdk-card-link"}], [
                            {'div', [{class, ~"sdk-card"}], [
                                {h3, [], [~"Unity"]},
                                {span, [{class, ~"sdk-lang"}], [~"C#"]},
                                {p, [], [~"Unity 2021.3+. Install via UPM git URL."]},
                                {span, [{class, ~"sdk-link"}], [~"View guide"]}
                            ]}
                        ]},
                        {a, [{href, ~"/godot"}, {class, ~"sdk-card-link"}], [
                            {'div', [{class, ~"sdk-card"}], [
                                {h3, [], [~"Godot"]},
                                {span, [{class, ~"sdk-lang"}], [~"GDScript"]},
                                {p, [], [~"Godot 4.x addon. Enable in Project Settings."]},
                                {span, [{class, ~"sdk-link"}], [~"View guide"]}
                            ]}
                        ]},
                        {a, [{href, ~"/defold"}, {class, ~"sdk-card-link"}], [
                            {'div', [{class, ~"sdk-card"}], [
                                {h3, [], [~"Defold"]},
                                {span, [{class, ~"sdk-lang"}], [~"Lua"]},
                                {p, [], [~"Add as dependency in game.project."]},
                                {span, [{class, ~"sdk-link"}], [~"View guide"]}
                            ]}
                        ]},
                        {a, [{href, ~"/dart"}, {class, ~"sdk-card-link"}], [
                            {'div', [{class, ~"sdk-card"}], [
                                {h3, [], [~"Flutter / Dart"]},
                                {span, [{class, ~"sdk-lang"}], [~"Dart"]},
                                {p, [], [~"Works with Flutter, Flame, and standalone Dart."]},
                                {span, [{class, ~"sdk-link"}], [~"View guide"]}
                            ]}
                        ]}
                    ]},
                    {p, [{class, ~"sdk-note"}], [
                        ~"All SDKs cover auth, matchmaking, real-time, leaderboards, economy, social, storage, and more."
                    ]}
                ]}
            ]},

            %% Code example
            {section, [{class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {p, [{class, ~"section-marker"}], [~"05 / Contract"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"Define your ",
                        {em, [], [~"game logic"]}
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Implement the ",
                        {code, [], [~"asobi_match"]},
                        ~" behaviour. Asobi handles the rest."
                    ]},
                    {'div', [{class, ~"code-block"}], [
                        {pre, [], [{code, [], [code_snippet()]}]}
                    ]}
                ]}
            ]},

            %% Comparison
            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {p, [{class, ~"section-marker"}], [~"06 / Position"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"How Asobi ",
                        {em, [], [~"compares"]}
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Honest accounting against the engines you\x{2019}d otherwise pick."
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
                                    {td, [{class, ~"row-label"}], [~"Cloud/K8s"]},
                                    {td, [{class, ~"highlight"}], [
                                        ~"Graceful shutdown, health checks"
                                    ]},
                                    {td, [], [~"Basic support"]},
                                    {td, [], [~"Manual setup"]}
                                ]},
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"Pub/Sub"]},
                                    {td, [{class, ~"highlight"}], [~"Built-in (pg module)"]},
                                    {td, [], [~"Requires Redis"]},
                                    {td, [], [~"Built-in"]}
                                ]},
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"Connections/Node"]},
                                    {td, [{class, ~"highlight"}], [~"100K+"]},
                                    {td, [], [~"~50K"]},
                                    {td, [], [~"~10K"]}
                                ]},
                                {tr, [], [
                                    {td, [{class, ~"row-label"}], [~"Observability"]},
                                    {td, [{class, ~"highlight"}], [~"OpenTelemetry + Telemetry"]},
                                    {td, [], [~"Prometheus"]},
                                    {td, [], [~"Custom metrics"]}
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

            %% Getting started
            {section, [{id, ~"get-started"}, {class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {p, [{class, ~"section-marker"}], [~"07 / Start"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"Get started in ",
                        {em, [], [~"minutes"]}
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Four commands between you and a running multiplayer game."
                    ]},
                    {'div', [{class, ~"steps"}], [
                        {'div', [{class, ~"step"}], [
                            {'div', [{class, ~"step-number"}], [~"1"]},
                            {'div', [{class, ~"step-content"}], [
                                {h3, [], [~"Create a new project"]},
                                {p, [], [{code, [], [~"rebar3 nova new my_game fullstack"]}]}
                            ]}
                        ]},
                        {'div', [{class, ~"step"}], [
                            {'div', [{class, ~"step-number"}], [~"2"]},
                            {'div', [{class, ~"step-content"}], [
                                {h3, [], [~"Add asobi as a dependency"]},
                                {p, [], [{code, [], [DepSnippet]}]}
                            ]}
                        ]},
                        {'div', [{class, ~"step"}], [
                            {'div', [{class, ~"step-number"}], [~"3"]},
                            {'div', [{class, ~"step-content"}], [
                                {h3, [], [~"Implement your match logic"]},
                                {p, [], [
                                    ~"Define a module with the ",
                                    {code, [], [~"asobi_match"]},
                                    ~" behaviour"
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
            ]},

            %% Community
            {section, [{id, ~"community"}, {class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner community-section"}], [
                    {p, [{class, ~"section-marker"}], [~"08 / People"]},
                    {h2, [{class, ~"section-title"}], [
                        ~"Join the ",
                        {em, [], [~"community"]}
                    ]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Ask questions, share what you're building, and help shape Asobi."
                    ]},
                    {a,
                        [
                            {href, ~"https://discord.gg/vYSfYYyXpu"},
                            {class, ~"btn btn-primary btn-lg"}
                        ],
                        [
                            ~"Join us on Discord"
                        ]}
                ]}
            ]}
        ]}
    ).

%%----------------------------------------------------------------------
%% Code snippet
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
