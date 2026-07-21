-module(asobi_site_docs_samples_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-samples", title => ~"Samples - Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Samples"
            ]},
            {h1, [], [~"Samples"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Complete, runnable games. Each one is two commands to your machine: scaffold it, then run its bundled backend locally. Self-host is free - no account, no keys."
            ]},

            {'div', [{class, ~"arena-play"}, {'data-backend', backend_host()}], [
                {h2, [], [~"Play a live match, right now"]},
                {p, [], [
                    ~"No install, no signup. This drops you into a live Asobi server running the Arena sample - move with WASD, aim with the mouse, click to shoot. You will be matched with bots in a moment."
                ]},
                {button, [{id, ~"arena-play-btn"}, {class, ~"btn btn-primary"}], [
                    ~"\x{25B6} Play a live match"
                ]},
                {p, [{id, ~"arena-status"}, {class, ~"arena-status"}], []},
                {canvas,
                    [
                        {id, ~"arena-canvas"},
                        {class, ~"arena-canvas"},
                        {width, ~"640"},
                        {height, ~"480"}
                    ],
                    []},
                {'div', [{class, ~"sample-source"}], [
                    {p, [], [
                        {strong, [], [~"Get the source. "]},
                        ~"The Lua backend runs with Docker only, no account:"
                    ]},
                    {pre, [], [
                        {code, [{class, ~"language-bash"}], [
                            ~"git clone https://github.com/widgrensit/asobi_arena_lua\ncd asobi_arena_lua && docker compose up -d"
                        ]}
                    ]},
                    {p, [], [
                        {a, [{href, ~"https://github.com/widgrensit/asobi_arena_lua"}], [
                            ~"asobi_arena_lua backend on GitHub \x{2192}"
                        ]}
                    ]},
                    {p, [], [
                        ~"The finished client for your engine: ",
                        {a, [{href, ~"https://github.com/widgrensit/asobi-defold-demo"}], [
                            ~"Defold"
                        ]},
                        ~", ",
                        {a, [{href, ~"https://github.com/widgrensit/asobi-godot-demo"}], [~"Godot"]},
                        ~", ",
                        {a, [{href, ~"https://github.com/widgrensit/asobi-unity-demo"}], [~"Unity"]},
                        ~", ",
                        {a, [{href, ~"https://github.com/widgrensit/asobi-flame-demo"}], [~"Flame"]},
                        ~"."
                    ]}
                ]}
            ]},

            {'div',
                [
                    {class, ~"livepatch-play"},
                    {'data-backend', livepatch_host()},
                    {'data-mode', ~"livepatch"}
                ],
                [
                    {h2, [], [~"Patch a live game - watch nobody reconnect"]},
                    {p, [], [
                        ~"This is a party trivia game whose scoring rule is hot-reloaded while you play. Answer a question, then the server's ",
                        {code, [], [~"score()"]},
                        ~" rule gets swapped underneath the running match - your score so far stays, the new rule applies from now on, and the connection never drops. No other game backend does this."
                    ]},
                    {button, [{id, ~"livepatch-btn"}, {class, ~"btn btn-primary"}], [
                        ~"\x{25B6} Play Live Patch"
                    ]},
                    {p, [{id, ~"livepatch-status"}, {class, ~"arena-status"}], []},
                    {'div', [{id, ~"livepatch-fallback"}, {class, ~"livepatch-fallback"}], [
                        {p, [], [
                            ~"The hosted demo isn't up yet. Run it yourself - Docker only, no account:"
                        ]},
                        {pre, [], [
                            {code, [{class, ~"language-bash"}], [
                                ~"git clone https://github.com/widgrensit/asobi_livepatch_lua\ncd asobi_livepatch_lua && docker compose up -d\n./patch.sh streak   # swap the scoring rule while a match runs"
                            ]}
                        ]},
                        {p, [], [
                            {a, [{href, ~"https://github.com/widgrensit/asobi_livepatch_lua"}], [
                                ~"asobi_livepatch_lua on GitHub \x{2192}"
                            ]}
                        ]}
                    ]},
                    {'div', [{id, ~"livepatch-game"}, {class, ~"livepatch-game"}], [
                        {'div', [{class, ~"livepatch-bar"}], [
                            {span, [{id, ~"livepatch-rule"}, {class, ~"livepatch-rule"}], []},
                            {span, [{id, ~"livepatch-flash"}, {class, ~"livepatch-flash"}], []}
                        ]},
                        {p, [{id, ~"livepatch-question"}, {class, ~"livepatch-question"}], []},
                        {'div', [{id, ~"livepatch-options"}, {class, ~"livepatch-options"}], []},
                        {'div', [{class, ~"livepatch-panels"}], [
                            {'div', [{id, ~"livepatch-scores"}, {class, ~"livepatch-scores"}], []},
                            {pre, [{class, ~"livepatch-code"}], [
                                {code, [{id, ~"livepatch-code"}, {class, ~"language-lua"}], []}
                            ]}
                        ]}
                    ]}
                ]},

            {'div',
                [
                    {class, ~"bestof3-play"},
                    {'data-backend', bestof3_host()},
                    {'data-mode', ~"bestof3"}
                ],
                [
                    {h2, [], [~"Best of 3 - a turn-based duel"]},
                    {p, [], [
                        ~"A four-player Rock-Paper-Scissors royale. Turn-based, not real-time: the round resolves only when everyone has thrown, and the server holds each throw secretly until the reveal. Empty seats fill with bots, so you start at once. This one runs as an ordinary game on managed Asobi cloud - no hot-reload needed."
                    ]},
                    {button, [{id, ~"bestof3-btn"}, {class, ~"btn btn-primary"}], [
                        ~"\x{25B6} Play Best of 3"
                    ]},
                    {p, [{id, ~"bestof3-status"}, {class, ~"arena-status"}], []},
                    {'div', [{id, ~"bestof3-fallback"}, {class, ~"livepatch-fallback"}], [
                        {p, [], [
                            ~"The hosted demo isn't up yet. Run it yourself - Docker only, no account:"
                        ]},
                        {pre, [], [
                            {code, [{class, ~"language-bash"}], [
                                ~"git clone https://github.com/widgrensit/asobi_rps_lua\ncd asobi_rps_lua && docker compose up -d"
                            ]}
                        ]},
                        {p, [], [
                            {a, [{href, ~"https://github.com/widgrensit/asobi_rps_lua"}], [
                                ~"asobi_rps_lua on GitHub \x{2192}"
                            ]}
                        ]}
                    ]},
                    {'div', [{id, ~"bestof3-game"}, {class, ~"bestof3-game"}], [
                        {'div', [{class, ~"bestof3-head"}], [
                            {span, [{id, ~"bestof3-round"}, {class, ~"bestof3-round"}], []},
                            {span, [{id, ~"bestof3-banner"}, {class, ~"bestof3-banner"}], []}
                        ]},
                        {'div', [{id, ~"bestof3-throws"}, {class, ~"bestof3-throws"}], []},
                        {'div', [{id, ~"bestof3-board"}, {class, ~"bestof3-board"}], []}
                    ]}
                ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"How this works. "]},
                    {code, [], [~"asobi init"]},
                    ~" copies the sample into a new folder; ",
                    {code, [], [~"asobi dev"]},
                    ~" runs its bundled Lua backend on localhost. When you want us to host it, ",
                    {a, [{href, ~"/docs/cloud"}, az_navigate], [
                        ~"deploy to a managed cloud environment"
                    ]},
                    ~" (paid) - the client code is identical either way."
                ]}
            ]},

            {'div', [{class, ~"samples-grid"}], [sample_card(S) || S <- samples()]},

            {script, [{src, ~"/assets/js/arena-play.js"}, {defer, true}], []},
            {script, [{src, ~"/assets/js/livepatch-play.js"}, {defer, true}], []},
            {script, [{src, ~"/assets/js/bestof3-play.js"}, {defer, true}], []}
        ]}
    ).

samples() ->
    Base = #{
        name => ~"Arena Shooter",
        blurb =>
            ~"Top-down co-op arena. Server-authoritative movement and combat at 10 Hz, matchmaking that fills empty slots with bots, boons, modifier voting between rounds, and a kills leaderboard.",
        media => ~"/assets/media/arena.gif",
        tags => [~"Matchmaking", ~"Realtime", ~"Bots", ~"Leaderboards", ~"Voting"],
        docs => ~"/docs/matchmaking"
    },
    [
        Base#{
            engine => ~"Godot",
            key => ~"godot",
            repo => ~"https://github.com/widgrensit/asobi-godot-demo"
        },
        Base#{
            engine => ~"Defold",
            key => ~"defold",
            repo => ~"https://github.com/widgrensit/asobi-defold-demo"
        },
        Base#{
            engine => ~"Unity",
            key => ~"unity",
            repo => ~"https://github.com/widgrensit/asobi-unity-demo"
        }
    ].

sample_card(S) ->
    #{
        name := Name,
        blurb := Blurb,
        media := Media,
        tags := Tags,
        docs := Docs,
        engine := Engine,
        key := Key,
        repo := Repo
    } = S,
    ?html(
        {'div', [{class, ~"sample-card"}], [
            {img,
                [
                    {class, ~"sample-media"},
                    {src, Media},
                    {alt, iolist_to_binary([Name, ~" (", Engine, ~")"])},
                    {loading, ~"lazy"}
                ],
                []},
            {'div', [{class, ~"sample-body"}], [
                {'div', [{class, ~"sample-head"}], [
                    {h3, [], [Name]},
                    {span, [{class, ~"sample-badge"}], [Engine]}
                ]},
                {p, [], [Blurb]},
                {'div', [{class, ~"sample-tags"}], [
                    {span, [{class, ~"sample-tag"}], [T]}
                 || T <- Tags
                ]},
                code(
                    ~"bash",
                    iolist_to_binary([~"asobi init arena --template ", Key, ~"\nasobi dev"])
                ),
                {'div', [{class, ~"sample-links"}], [
                    {a, [{href, Repo}], [~"Source"]},
                    {a, [{href, Docs}, az_navigate], [~"How it works"]},
                    {a, [{href, ~"/docs/cloud"}, az_navigate], [~"Deploy to cloud"]}
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).

%% Host of the shared showcase backend the live demo connects to. Override in
%% sys.config with {asobi_site, [{demo_backend_host, ~"demo.asobi.dev"}]} to
%% repoint the demo (e.g. to an asobi_saas-provisioned env) without code changes.
backend_host() ->
    application:get_env(asobi_site, demo_backend_host, ~"play.asobi.dev").

%% Host of the showcase backend the Live Patch demo connects to. Defaults to the
%% shared showcase host; override in sys.config to point at a dedicated
%% volume-mounted env (hot-reload needs mtime polling, so not a sealed bundle).
livepatch_host() ->
    application:get_env(asobi_site, livepatch_demo_host, ~"livepatch.asobi.dev").

%% Host of the managed-cloud env serving the Best of 3 mode. Override in
%% sys.config with the env's endpoint once it is deployed.
bestof3_host() ->
    application:get_env(asobi_site, bestof3_demo_host, ~"rps-lua-prod.asobi-studio.asobi.dev").
