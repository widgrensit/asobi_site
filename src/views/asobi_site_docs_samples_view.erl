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
                    []}
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

            {script, [{src, ~"/assets/js/arena-play.js"}, {defer, true}], []}
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
