-module(asobi_site_home_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"home"}, Bindings), #{}}.

-spec render(map()) -> term().
render(Bindings) ->
    DepSnippet = ~"{asobi, {git, \"https://github.com/widgrensit/asobi.git\", {branch, \"main\"}}}",
    ?html(
        {'div', [{id, ?get(id)}], [
            %% Nav
            {nav, [{class, ~"site-nav"}], [
                {'div', [{class, ~"nav-inner"}], [
                    {a, [{href, ~"/"}, {class, ~"nav-brand"}], [
                        {span, [{class, ~"brand-icon"}], [<<16#904A/utf8>>]},
                        {span, [{class, ~"brand-text"}], [~"asobi"]}
                    ]},
                    {'div', [{class, ~"nav-links"}], [
                        {a, [{href, ~"#features"}], [~"Features"]},
                        {a, [{href, ~"#sdks"}], [~"SDKs"]},
                        {a, [{href, ~"#why-beam"}], [~"Why BEAM"]},
                        {a, [{href, ~"#get-started"}], [~"Get Started"]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi"},
                                {class, ~"nav-github"}
                            ],
                            [
                                ~"GitHub"
                            ]}
                    ]}
                ]}
            ]},

            %% Hero
            {section, [{class, ~"hero"}], [
                {'div', [{class, ~"hero-inner"}], [
                    {span, [{class, ~"hero-badge"}], [~"Preview"]},
                    {p, [{class, ~"hero-eyebrow"}], [~"Open Source Game Backend"]},
                    {h1, [{class, ~"hero-title"}], [~"Your game never goes down."]},
                    {p, [{class, ~"hero-subtitle"}], [
                        ~"Asobi is a multiplayer game backend built on Erlang/OTP. ",
                        ~"Fault-tolerant by design. Zero-downtime deploys. ",
                        ~"100K+ concurrent connections per node."
                    ]},
                    {p, [{class, ~"hero-notice"}], [
                        ~"Asobi is early but fully open-source and ready to play with. Spin it up, prototype your next game, and help shape the future of game backends on the BEAM."
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

            %% Why BEAM
            {section, [{id, ~"why-beam"}, {class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"Built on the BEAM"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"The same virtual machine that powers WhatsApp, Discord, and RabbitMQ. ",
                        ~"Designed for millions of concurrent connections with predictable latency."
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
                    {h2, [{class, ~"section-title"}], [~"Everything you need"]},
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
                    {h2, [{class, ~"section-title"}], [~"SDKs for every engine"]},
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
                    {h2, [{class, ~"section-title"}], [~"Define your game logic"]},
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
                    {h2, [{class, ~"section-title"}], [~"How Asobi compares"]},
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
                    {h2, [{class, ~"section-title"}], [~"Get started in minutes"]},
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

            %% Footer
            {footer, [{class, ~"site-footer"}], [
                {'div', [{class, ~"footer-inner"}], [
                    {'div', [{class, ~"footer-brand"}], [
                        {span, [{class, ~"brand-icon"}], [<<16#904A/utf8>>]},
                        ~" asobi",
                        {p, [{class, ~"footer-tagline"}], [
                            ~"Open-source game backend for the BEAM"
                        ]}
                    ]},
                    {'div', [{class, ~"footer-links"}], [
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"Project"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"GitHub"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi/issues"}], [
                                ~"Issues"
                            ]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi/blob/main/LICENSE"}],
                                [~"License"]}
                        ]},
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"SDKs"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-unity"}], [~"Unity"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-godot"}], [~"Godot"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-defold"}], [
                                ~"Defold"
                            ]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi-dart"}], [
                                ~"Flutter / Dart / Flame"
                            ]}
                        ]},
                        {'div', [{class, ~"footer-col"}], [
                            {h4, [], [~"Ecosystem"]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi_admin"}], [
                                ~"Admin Dashboard"
                            ]},
                            {a, [{href, ~"https://github.com/widgrensit/asobi_arena"}], [
                                ~"Example: Arena"
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
                    {p, [], [~"Apache 2.0 \x{2014} widgrensit"]}
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
