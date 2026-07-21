-module(asobi_site_docs_learn_orientation_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-orientation", title => ~"What you are building - Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Learn / What you are building"
            ]},
            {h1, [], [~"What you are building"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Understand the destination before you build it: you are building the movement core of the Arena Shooter sample, a top-down arena where the server moves your fighter and every client sees it move."
            ]},

            {h2, [], [~"The thing you will build"]},
            {p, [], [
                ~"The Arena Shooter sample is a top-down co-op arena: fighters move, aim, and shoot; matchmaking fills empty slots with bots; boons drop, players vote on a modifier between rounds, and a kills leaderboard tracks who is winning. You will build only the movement core. The full sample layers shooting, bots, boons, round voting, and the leaderboard on top of exactly this."
            ]},
            {p, [], [
                ~"An arena. One fighter. Every connected client sees the same arena and your fighter at the same position."
            ]},
            {p, [], [
                ~"A player presses a movement key. The client does not move the fighter. It sends the input to the server as an intent, a move_x/move_y delta. The server decides where the fighter goes and broadcasts the new position. Every client redraws."
            ]},
            {p, [], [
                ~"That is the whole track. Each step adds one piece and ends with a checkpoint you run to see it work. By the end you have a real backend: guests, stored state, matches, and worlds, all around this one arena."
            ]},

            {h2, [], [~"The two pieces"]},
            {p, [], [
                {strong, [], [~"1. A server bundle. "]},
                ~"A directory of Lua scripts that holds your game logic - who joins, what an input does, where the fighter ends up. You deploy this bundle; you do not run a server codebase. Asobi runs it for you."
            ]},
            {p, [], [
                {strong, [], [~"2. A client. "]},
                ~"Your game, using an Asobi SDK (Defold, Godot, Unity, Unreal, Dart, JavaScript, or LOVE). The client draws the arena, sends inputs, and renders whatever state the server sends back."
            ]},
            {p, [], [~"The client never owns the truth. It sends intent; it renders state."]},

            {h2, [], [~"The one rule: server-authoritative"]},
            code(
                ~"text",
                ~"""
client input  --->  server decides  --->  server broadcasts  --->  every client renders
"""
            ),
            {p, [], [
                ~"The fighter's position lives on the server. A client cannot place the fighter; it can only ask. This is what stops two players disagreeing about the game, and it is why the interesting code is in Lua, not in the client."
            ]},

            {h2, [], [~"Two ways to deploy (chosen later)"]},
            {p, [], [
                ~"The same bundle runs on both paths. You pick one when you deploy; the choice does not change any game logic."
            ]},
            {p, [], [
                {strong, [], [~"Cloud "]},
                ~"- the managed platform at ",
                {code, [], [~"console.asobi.dev"]},
                ~", deployed with ",
                {code, [], [~"asobi deploy"]},
                ~". Your per-environment Postgres database is provisioned for you, and the guest-auth pepper is generated per environment. You write no config file; you set a few environment knobs. See the ",
                {a, [{href, ~"/docs/configuration"}, az_navigate], [~"configuration"]},
                ~" guide."
            ]},
            {p, [], [
                {strong, [], [~"Self-hosted "]},
                ~"- your own release of ",
                {code, [], [~"asobi"]},
                ~" + ",
                {code, [], [~"asobi_lua"]},
                ~" against your own Postgres. You configure it with ",
                {code, [], [~"ASOBI_*"]},
                ~" environment variables (the Docker image) or ",
                {code, [], [~"sys.config"]},
                ~" (an embedded Erlang release), and you supply your own secrets. See the ",
                {a, [{href, ~"/docs/self-host"}, az_navigate], [~"self-host"]},
                ~" and ",
                {a, [{href, ~"/docs/configuration"}, az_navigate], [~"configuration"]},
                ~" guides."
            ]},
            {p, [], [
                ~"Every step in this track flags where Cloud and Self-hosted differ, labelled ",
                {strong, [], [~"Cloud"]},
                ~" and ",
                {strong, [], [~"Self-hosted"]},
                ~". Where a step is identical - all game logic, and every SDK call except the base server URL - it is written once and says so."
            ]},

            checkpoint([
                {p, [], [
                    ~"You do not deploy anything yet. Confirm your chosen path is reachable, so the later deploy step just works."
                ]},
                {p, [], [{strong, [], [~"Cloud"]}, ~" - log in to the platform:"]},
                code(~"bash", ~"asobi login\n"),
                {p, [], [
                    ~"The device-code prompt should complete and report you as authenticated."
                ]},
                {p, [], [{strong, [], [~"Self-hosted"]}, ~" - pull the runtime image:"]},
                code(~"bash", ~"docker pull ghcr.io/widgrensit/asobi_lua:latest\n"),
                {p, [], [
                    ~"The pull should finish without error. You are ready when one of these succeeds."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/bundle",
                ~"Step 1 - Your backend bundle and folder layout",
                ~"What a Lua bundle actually contains, and how to boot it locally."
            )
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).

checkpoint(Children) ->
    ?html(
        {'div', [{class, ~"docs-callout docs-callout-success"}], [
            {p, [], [{strong, [], [~"Checkpoint"]}]} | Children
        ]}
    ).

nextstep(Href, Label, Blurb) ->
    ?html(
        {'div', [{class, ~"docs-next"}], [
            {p, [], [
                {strong, [], [~"Next: "]},
                {a, [{href, Href}, az_navigate], [Label]}
            ]},
            {p, [], [Blurb]}
        ]}
    ).
