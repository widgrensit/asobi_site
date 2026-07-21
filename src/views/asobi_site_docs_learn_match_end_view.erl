-module(asobi_site_docs_learn_match_end_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-match-end", title => ~"End a match - Asobi docs"},
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
                ~" / Learn / End a match"
            ]},
            {h1, [], [~"End a match"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Goal: the server decides the arena round is over, computes a result, and both clients receive it."
            ]},

            {p, [], [
                ~"So far the round runs forever: clients send input, the server moves your fighter across the arena, the server broadcasts ",
                {code, [], [~"match.state"]},
                ~". Now the server ends the round on its own terms and hands every player a final result table."
            ]},
            {p, [], [
                ~"This is a server decision. A client never ends a round. The server detects the end condition inside the tick loop, builds the result, and the platform pushes ",
                {code, [], [~"match.finished"]},
                ~" to everyone."
            ]},

            {h2, [], [~"How an arena round finishes"]},
            {p, [], [
                ~"Your round ends the moment ",
                {code, [], [~"tick(state)"]},
                ~" marks the state finished. Set two fields on the state table:"
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"state._finished = true"]},
                    ~" - stop the round after this tick."
                ]},
                {li, [], [
                    {code, [], [~"state._result = {...}"]},
                    ~" - the result table sent to every player."
                ]}
            ]},
            {p, [], [
                ~"The platform reads those fields after ",
                {code, [], [~"tick"]},
                ~" returns, closes the round, and pushes ",
                {code, [], [~"_result"]},
                ~" to all players as the ",
                {code, [], [~"match.finished"]},
                ~" event. The table shape is yours; clients receive it as JSON."
            ]},

            {h2, [], [~"Compute a result for the arena"]},
            {p, [], [
                ~"Keep the through-line: one fighter in the arena, moved by player input. The arena is 16 by 16. Give the round an end condition and a score. Here the fighter chases a target cell, each player earns a point for the move that lands on it, and the round ends after a fixed number of ticks."
            ]},
            code(
                ~"lua",
                ~"""
                local ARENA = 16
                local MATCH_TICKS = 300

                function init(config)
                    return {
                        fighter = { x = 8, y = 8 },
                        target = { x = 3, y = 12 },
                        scores = {},
                        tick_count = 0
                    }
                end

                function join(player_id, state)
                    state.scores[player_id] = state.scores[player_id] or 0
                    return state
                end

                function handle_input(player_id, input, state)
                    local fighter = state.fighter
                    fighter.x = math.max(0, math.min(ARENA - 1, fighter.x + (input.move_x or 0)))
                    fighter.y = math.max(0, math.min(ARENA - 1, fighter.y + (input.move_y or 0)))

                    if fighter.x == state.target.x and fighter.y == state.target.y then
                        state.scores[player_id] = state.scores[player_id] + 1
                        state.target = { x = math.random(0, ARENA - 1), y = math.random(0, ARENA - 1) }
                    end
                    return state
                end

                function tick(state)
                    state.tick_count = state.tick_count + 1

                    if state.tick_count >= MATCH_TICKS then
                        state._finished = true
                        state._result = {
                            status = "completed",
                            scores = state.scores,
                            winner = top_scorer(state.scores)
                        }
                    end
                    return state
                end
                """
            ),

            {p, [], [
                {code, [], [~"top_scorer"]},
                ~" is plain Lua - no platform call:"
            ]},
            code(
                ~"lua",
                ~"""
                function top_scorer(scores)
                    local best_id, best_score = nil, -1
                    for player_id, score in pairs(scores) do
                        if score > best_score then
                            best_id, best_score = player_id, score
                        end
                    end
                    return best_id
                end
                """
            ),

            {p, [], [
                ~"At 10 ticks per second (the match default), ",
                {code, [], [~"MATCH_TICKS = 300"]},
                ~" ends the round after 30 seconds. Change the condition to whatever ends your game: a score cap, one fighter left, a captured flag."
            ]},

            {details, [], [
                {summary, [], [~"The Erlang form"]},
                {p, [], [
                    ~"If you write your match in Erlang instead of Lua, the same decision is a return value. ",
                    {code, [], [~"tick/1"]},
                    ~" returns ",
                    {code, [], [~"{finished, Result, State}"]},
                    ~" rather than the plain ",
                    {code, [], [~"State"]},
                    ~", and ",
                    {code, [], [~"Result"]},
                    ~" is the map delivered as ",
                    {code, [], [~"match.finished"]},
                    ~". The Lua ",
                    {code, [], [~"_finished"]},
                    ~"/",
                    {code, [], [~"_result"]},
                    ~" fields are the Lua-side spelling of that same signal."
                ]}
            ]},

            {h2, [], [~"Cloud and self-hosted are identical here"]},
            {p, [], [
                ~"Ending an arena round is pure game logic. It runs the same whether you deploy to Asobi Cloud with ",
                {code, [], [~"asobi deploy"]},
                ~" or run your own release of asobi + asobi_lua. There is no config, secret, or database difference for this step. Edit ",
                {code, [], [~"match.lua"]},
                ~", and the running server hot-reloads it between ticks."
            ]},

            {h2, [], [~"What the clients receive"]},
            {p, [], [~"Every player in the match gets one push:"]},
            code(
                ~"json",
                ~"""
                {"type": "match.finished", "payload": {"match_id": "...", "result": {"status": "completed", "scores": {"...": 3, "...": 1}, "winner": "..."}}}
                """
            ),
            {p, [], [
                {code, [], [~"result"]},
                ~" is your ",
                {code, [], [~"_result"]},
                ~" table verbatim. Handling it is the same SDK pattern you used for ",
                {code, [], [~"match.state"]},
                ~" in ",
                {a, [{href, ~"/docs/learn/match-run"}, az_navigate], [~"Run a match"]},
                ~": register a handler for the ",
                {code, [], [~"match.finished"]},
                ~" event before the round ends. See ",
                {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                    ~"WebSocket protocol - match.finished"
                ]},
                ~" for the full envelope."
            ]},

            checkpoint([
                {p, [], [
                    ~"With two clients still joined to the same round from the previous step:"
                ]},
                {ol, [], [
                    {li, [], [
                        ~"Let the round run to ",
                        {code, [], [~"MATCH_TICKS"]},
                        ~" (or lower the constant to end it sooner)."
                    ]},
                    {li, [], [
                        ~"On end, both clients receive one ",
                        {code, [], [~"match.finished"]},
                        ~" event."
                    ]},
                    {li, [], [
                        ~"The ",
                        {code, [], [~"result"]},
                        ~" payload carries the same ",
                        {code, [], [~"scores"]},
                        ~" map and ",
                        {code, [], [~"winner"]},
                        ~" on both clients."
                    ]}
                ]},
                {p, [], [~"Log the event on each client and confirm the two payloads match:"]},
                code(
                    ~"text",
                    ~"""
                    match.finished result={status=completed, scores={p1=3, p2=1}, winner=p1}
                    """
                ),
                {p, [], [
                    ~"If only the mover sees an end, check that you set ",
                    {code, [], [~"_finished"]},
                    ~" on the state you return from ",
                    {code, [], [~"tick"]},
                    ~", not on a local copy."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/world-create",
                ~"Create a world",
                ~"Arena rounds are ephemeral - they start, run, and finish. Next you meet worlds: persistent arenas that outlive any single session."
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
