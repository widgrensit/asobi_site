-module(asobi_site_docs_learn_match_setup_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{
                id => ~"docs-learn-match-setup",
                title => ~"Set up a match and its modes - Asobi docs"
            },
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
                ~" / Learn / Set up a match and its modes"
            ]},
            {h1, [], [~"Set up a match and its modes"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Define a match server-side so the arena has a mode a client can create and join."
            ]},

            {p, [], [
                ~"A match is an arena round: an ephemeral, bounded fight that spins up, players join, the server runs the simulation, and it ends. Everything here is server-authoritative. The client sends intent, the server decides, the server broadcasts state. You define both halves of that in Lua: a mode name, and the script that implements it."
            ]},
            {p, [], [~"Two files do the work:"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"match.lua"]},
                    ~" implements the match: ",
                    {code, [], [~"join"]},
                    ~", ",
                    {code, [], [~"handle_input"]},
                    ~", ",
                    {code, [], [~"tick"]},
                    ~", and the rest of the callbacks."
                ]},
                {li, [], [
                    {code, [], [~"config.lua"]},
                    ~" is an optional manifest that maps a mode name to a match script. You only need it once you have more than one mode."
                ]}
            ]},

            {h2, [], [~"Single mode: just ", {code, [], [~"match.lua"]}]},
            {p, [], [
                ~"With no ",
                {code, [], [~"config.lua"]},
                ~", Asobi loads a top-level ",
                {code, [], [~"match.lua"]},
                ~" as the mode named ",
                {code, [], [~"\"default\""]},
                ~". That is the whole registration step - drop the file in and the mode exists."
            ]},
            {p, [], [
                ~"Here is the arena, server-side. Your fighter lives in shared match state, the server moves it in response to input, and every player sees the same arena."
            ]},
            code(
                ~"lua",
                ~"""
                -- lua/match.lua
                match_size = 2

                function init(config)
                    return {
                        arena_w = 16,
                        arena_h = 16,
                        fighter = { x = 8, y = 8 }
                    }
                end

                function join(player_id, state)
                    return state
                end

                function leave(player_id, state)
                    return state
                end

                function handle_input(player_id, input, state)
                    local f = state.fighter
                    f.x = math.max(1, math.min(state.arena_w, f.x + (input.move_x or 0)))
                    f.y = math.max(1, math.min(state.arena_h, f.y + (input.move_y or 0)))
                    return state
                end

                function tick(state)
                    return state
                end

                function get_state(player_id, state)
                    return { arena_w = state.arena_w, arena_h = state.arena_h, fighter = state.fighter }
                end
                """
            ),
            {p, [], [
                {code, [], [~"match_size = 2"]},
                ~" means the matchmaker pairs two queued players into one match, which is what the next step's \"two clients, one match\" checkpoint needs. Lower it to ",
                {code, [], [~"1"]},
                ~" for solo play, or raise it for larger rosters."
            ]},
            {p, [], [
                ~"Every match script must define ",
                {code, [], [~"init"]},
                ~", ",
                {code, [], [~"join"]},
                ~", ",
                {code, [], [~"leave"]},
                ~", ",
                {code, [], [~"handle_input"]},
                ~", ",
                {code, [], [~"tick"]},
                ~", and ",
                {code, [], [~"get_state"]},
                ~". ",
                {code, [], [~"tick"]},
                ~" runs at 10 Hz by default; here it is a no-op because your fighter only moves on input. The client sends ",
                {code, [], [~"move_x"]},
                ~"/",
                {code, [], [~"move_y"]},
                ~" deltas in ",
                {code, [], [~"{-1, 0, 1}"]},
                ~", and the server clamps your fighter to the arena. For the full callback contract, including the optional ",
                {code, [], [~"join/3"]},
                ~" context and vote hooks, see the ",
                {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"Lua scripting guide"]},
                ~". You will flesh out ",
                {code, [], [~"handle_input"]},
                ~" and ",
                {code, [], [~"tick"]},
                ~" in step 8; for now they just need to exist."
            ]},

            {h2, [], [~"Multiple modes: the ", {code, [], [~"config.lua"]}, ~" manifest"]},
            {p, [], [
                ~"To give the mode a real name, or to ship more than one, add a ",
                {code, [], [~"config.lua"]},
                ~" that maps mode names to scripts. When ",
                {code, [], [~"config.lua"]},
                ~" exists, Asobi reads it instead of looking for a top-level ",
                {code, [], [~"match.lua"]},
                ~"."
            ]},
            code(
                ~"lua",
                ~"""
                -- lua/config.lua
                return {
                    arena = "arena/match.lua"
                }
                """
            ),
            code(
                ~"text",
                ~"""
                my_arena/
                └── lua/
                    ├── config.lua
                    └── arena/
                        └── match.lua
                """
            ),
            {p, [], [
                ~"Now the mode is ",
                {code, [], [~"\"arena\""]},
                ~", not ",
                {code, [], [~"\"default\""]},
                ~", and that is the name a client will queue for. Add more rows to add more modes:"
            ]},
            code(
                ~"lua",
                ~"""
                -- lua/config.lua
                return {
                    arena = "arena/match.lua",
                    duel  = "duel/match.lua"
                }
                """
            ),
            {p, [], [
                ~"Each match script keeps its own per-mode globals (",
                {code, [], [~"match_size"]},
                ~", ",
                {code, [], [~"max_players"]},
                ~", ",
                {code, [], [~"strategy"]},
                ~") at the top of that script. Deployment-wide globals such as ",
                {code, [], [~"guest_auth"]},
                ~" go in ",
                {code, [], [~"config.lua"]},
                ~", not the per-mode scripts, because they describe the whole bundle rather than one mode. The full list of globals and matchmaking knobs lives in ",
                {a, [{href, ~"/docs/configuration"}, az_navigate], [~"Configuration"]},
                ~"."
            ]},

            {h2, [], [~"Deploy and boot"]},
            {p, [], [
                ~"The bundle above is identical on both paths - ",
                {code, [], [~"config.lua"]},
                ~", ",
                {code, [], [~"match.lua"]},
                ~", and every callback are byte-for-byte the same whether you run managed cloud or your own release. Only how you boot it and where you read the log differ."
            ]},
            {p, [], [
                {strong, [], [~"Cloud."]},
                ~" ",
                {code, [], [~"asobi deploy"]},
                ~" pushes the bundle; the mode is registered on each rollout. Read the boot log in the console at console.asobi.dev (or via the CLI log stream). The per-environment database and guest pepper are already provisioned, so there is nothing else to wire up."
            ]},
            {p, [], [
                {strong, [], [~"Self-hosted."]},
                ~" Bring up the ",
                {code, [], [~"asobi_lua"]},
                ~" Docker image with your game directory mounted at ",
                {code, [], [~"/app/game/"]},
                ~" (",
                {code, [], [~"docker compose up"]},
                ~"); the boot log prints to container stdout. Your own Postgres and any ",
                {code, [], [~"ASOBI_*"]},
                ~" env vars are configured as in ",
                {a, [{href, ~"/docs/configuration"}, az_navigate], [~"Configuration"]},
                ~"."
            ]},

            checkpoint([
                {p, [], [
                    ~"Boot the server (step 1) and watch the startup log. Asobi logs one line as it registers your modes:"
                ]},
                code(
                    ~"json",
                    ~"""
                    {"msg":"lua game config loaded","modes":["arena"]}
                    """
                ),
                {p, [], [
                    {code, [], [~"modes"]},
                    ~" lists exactly what you registered - ",
                    {code, [], [~"[\"arena\"]"]},
                    ~" for the manifest above, or ",
                    {code, [], [~"[\"default\"]"]},
                    ~" if you kept a single top-level ",
                    {code, [], [~"match.lua"]},
                    ~". Seeing your mode name there means the mode is registered and a match of that mode can now be created."
                ]},
                {p, [], [
                    ~"To confirm the server accepts the mode over REST, list live matches for it:"
                ]},
                code(
                    ~"text",
                    ~"""
                    GET /api/v1/matches/live?mode=arena
                    """
                ),
                {p, [], [
                    ~"The array is empty until a player actually creates a match, which is exactly what you do next."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/match-join",
                ~"Step 7 - Connect to a match",
                [
                    ~"connect a client to the mode with ",
                    {code, [], [~"match.join"]},
                    ~", and put two clients in the same match."
                ]
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
