-module(asobi_site_demo_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"demo"}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}, {class, ~"demo-page"}], [

            %% Hero
            {section, [{class, ~"demo-hero"}], [
                {'div', [{class, ~"demo-hero-inner"}], [
                    {span, [{class, ~"hero-badge"}], [~"Live Example"]},
                    {h1, [{class, ~"hero-title"}], [~"Asobi Arena"]},
                    {p, [{class, ~"hero-subtitle"}], [
                        ~"A multiplayer top-down arena shooter. ",
                        ~"Move, shoot, and survive. Built entirely on the ",
                        {code, [], [~"asobi_match"]},
                        ~" behaviour."
                    ]},
                    {'div', [{class, ~"hero-actions"}], [
                        {a,
                            [
                                {href, ~"https://play.asobi.dev/"},
                                {class, ~"btn btn-primary"}
                            ],
                            [~"Play now \x{2192}"]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi_arena"},
                                {class, ~"btn btn-secondary"}
                            ],
                            [~"View Source"]},
                        {a,
                            [
                                {href, ~"/#get-started"},
                                {class, ~"btn btn-ghost"},
                                az_navigate
                            ],
                            [~"Build Your Own"]}
                    ]}
                ]}
            ]},

            %% Game mechanics
            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"How it works"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"One Erlang module. ~270 lines. Full multiplayer arena."
                    ]},
                    {'div', [{class, ~"demo-mechanics"}], [
                        {'div', [{class, ~"mechanic-card"}], [
                            {'div', [{class, ~"mechanic-icon"}], [<<16#1F3AE/utf8>>]},
                            {h3, [], [~"800\x{00D7}600 Arena"]},
                            {p, [], [
                                ~"Bounded play area with random spawn points. Players can't leave the arena."
                            ]}
                        ]},
                        {'div', [{class, ~"mechanic-card"}], [
                            {'div', [{class, ~"mechanic-icon"}], [<<16#1F4A5/utf8>>]},
                            {h3, [], [~"Projectile Combat"]},
                            {p, [], [
                                ~"Aim and shoot with cooldown. Projectiles travel at 8 units/tick with collision detection."
                            ]}
                        ]},
                        {'div', [{class, ~"mechanic-card"}], [
                            {'div', [{class, ~"mechanic-icon"}], [<<16#2764/utf8>>]},
                            {h3, [], [~"100 HP / 25 Damage"]},
                            {p, [], [
                                ~"Four hits to eliminate. Kills and deaths tracked per player."
                            ]}
                        ]},
                        {'div', [{class, ~"mechanic-card"}], [
                            {'div', [{class, ~"mechanic-icon"}], [<<16#23F1/utf8>>]},
                            {h3, [], [~"90-Second Matches"]},
                            {p, [], [
                                ~"Timed rounds with automatic scoring. Last player standing or highest kills wins."
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            %% Architecture
            {section, [{class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"Architecture"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Each match runs as an isolated OTP process. The game module implements callbacks for the full lifecycle."
                    ]},
                    {'div', [{class, ~"demo-arch"}], [
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"1"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"init/1"]},
                                {p, [], [
                                    ~"Set up arena state: empty player map, projectile list, match timer."
                                ]}
                            ]}
                        ]},
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"2"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"join/2 & leave/2"]},
                                {p, [], [
                                    ~"Spawn players at random positions with 100 HP. Clean up on disconnect."
                                ]}
                            ]}
                        ]},
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"3"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"handle_input/3"]},
                                {p, [], [
                                    ~"Process movement (WASD) and shooting (aim + fire) from each client."
                                ]}
                            ]}
                        ]},
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"4"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"tick/1"]},
                                {p, [], [
                                    ~"Server tick: move projectiles, detect collisions, remove out-of-bounds, check win condition."
                                ]}
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            %% Code snippet
            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"The full match module"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"This is the actual game logic. Asobi handles networking, matchmaking, and state sync."
                    ]},
                    {'div', [{class, ~"code-block"}], [
                        {pre, [], [{code, [], [code_snippet()]}]}
                    ]}
                ]}
            ]},

            %% Client demos
            {section, [{class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"Play it in your engine"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Each client demo connects to the same Asobi Arena backend. Pick your engine and try it out."
                    ]},
                    {'div', [{class, ~"demo-client-grid"}], [
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi-unity-demo"},
                                {class, ~"demo-client-card"}
                            ],
                            [
                                {'div', [{class, ~"demo-client-engine"}], [~"Unity"]},
                                {span, [{class, ~"sdk-lang"}], [~"C#"]},
                                {p, [], [
                                    ~"Full arena shooter with sprites, projectile rendering, and HUD. Unity 2021.3+."
                                ]},
                                {span, [{class, ~"sdk-link"}], [~"View on GitHub"]}
                            ]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi-godot-demo"},
                                {class, ~"demo-client-card"}
                            ],
                            [
                                {'div', [{class, ~"demo-client-engine"}], [~"Godot"]},
                                {span, [{class, ~"sdk-lang"}], [~"GDScript"]},
                                {p, [], [
                                    ~"Godot 4.x client with scene-based player and projectile nodes."
                                ]},
                                {span, [{class, ~"sdk-link"}], [~"View on GitHub"]}
                            ]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi-flame-demo"},
                                {class, ~"demo-client-card"}
                            ],
                            [
                                {'div', [{class, ~"demo-client-engine"}], [~"Flame"]},
                                {span, [{class, ~"sdk-lang"}], [~"Dart"]},
                                {p, [], [
                                    ~"Flutter 2D arena client with Flame engine. Cross-platform mobile and desktop."
                                ]},
                                {span, [{class, ~"sdk-link"}], [~"View on GitHub"]}
                            ]}
                    ]},
                    {p, [{class, ~"demo-client-note"}], [
                        ~"More engine demos coming soon. ",
                        {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Join Discord"]},
                        ~" to get notified."
                    ]}
                ]}
            ]},

            %% CTA
            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner community-section"}], [
                    {h2, [{class, ~"section-title"}], [~"Build your own game"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Asobi Arena is just one example. Implement the ",
                        {code, [], [~"asobi_match"]},
                        ~" behaviour and build anything \x{2014} racing, puzzle, RTS, battle royale."
                    ]},
                    {'div', [{class, ~"hero-actions"}], [
                        {a, [{href, ~"/#get-started"}, {class, ~"btn btn-primary"}, az_navigate], [
                            ~"Get Started"
                        ]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi"},
                                {class, ~"btn btn-secondary"}
                            ],
                            [~"Read the Docs"]}
                    ]}
                ]}
            ]},

            %% Try it yourself
            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"Try it yourself"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Get the arena running locally in a few minutes. You need Erlang/OTP 27+, PostgreSQL, and one of the game engines above."
                    ]},
                    {'div', [{class, ~"demo-arch"}], [
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"1"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"Start the backend"]},
                                {pre, [], [
                                    {code, [], [
                                        ~"git clone https://github.com/widgrensit/asobi_arena\ncd asobi_arena\ndocker compose up -d\nrebar3 shell"
                                    ]}
                                ]}
                            ]}
                        ]},
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"2"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"Clone a client demo"]},
                                {pre, [], [
                                    {code, [], [
                                        ~"# Pick your engine:\ngit clone https://github.com/widgrensit/asobi-godot-demo\n# or: asobi-unity-demo, asobi-defold-demo, asobi-flame-demo"
                                    ]}
                                ]}
                            ]}
                        ]},
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"3"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"Open the project and play"]},
                                {p, [], [
                                    ~"Open the demo in your engine, hit play, and register a player. Open a second window to matchmake against yourself. WASD to move, mouse to aim, click to shoot."
                                ]}
                            ]}
                        ]}
                    ]},
                    {p, [{class, ~"demo-client-note"}], [
                        ~"The backend runs on port 8084 by default. Check each demo's README for engine-specific setup."
                    ]}
                ]}
            ]}
        ]}
    ).

%%----------------------------------------------------------------------
%% Code snippet — condensed version of asobi_arena_game
%%----------------------------------------------------------------------

-spec code_snippet() -> binary().
code_snippet() ->
    ~"""
    -module(asobi_arena_game).
    -behaviour(asobi_match).

    -export([init/1, join/2, leave/2, handle_input/3, tick/1, get_state/2]).

    -define(ARENA_W, 800).
    -define(ARENA_H, 600).
    -define(MAX_HP, 100).
    -define(DAMAGE, 25).
    -define(GAME_DURATION, 90000).

    init(_Config) ->
        {ok, #{players => #{}, projectiles => [],
               next_proj_id => 1, started_at => undefined}}.

    join(PlayerId, #{players := Players} = State) ->
        Player = #{x => rand:uniform(700) + 50,
                   y => rand:uniform(500) + 50,
                   hp => ?MAX_HP, kills => 0, deaths => 0},
        {ok, State#{players => Players#{PlayerId => Player}}}.

    handle_input(PlayerId, Input, State) ->
        %% Apply movement + shooting per client tick
        Player1 = apply_movement(Input, get_player(PlayerId, State)),
        {State1, Player2} = maybe_shoot(PlayerId, Input, Player1, State),
        {ok, put_player(PlayerId, Player2, State1)}.

    tick(#{players := Players, projectiles := Projs} = State) ->
        Projs1 = move_projectiles(Projs),
        {Projs2, Players1} = check_collisions(Projs1, Players),
        State1 = State#{players => Players1,
                        projectiles => remove_oob(Projs2)},
        case time_up(State1) orelse one_standing(Players1) of
            true  -> {finished, build_result(Players1), State1};
            false -> {ok, State1}
        end.
    """.
