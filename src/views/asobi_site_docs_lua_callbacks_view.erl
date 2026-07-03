-module(asobi_site_docs_lua_callbacks_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-lua-callbacks", title => ~"Game module callbacks — Asobi docs"},
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
                ~" / Lua / Callbacks"
            ]},
            {h1, [], [~"Game module callbacks"]},
            {p, [{class, ~"docs-lede"}], [
                ~"The functions ",
                {em, [], [~"you"]},
                ~" write in a game module. Asobi calls them at the right moments in the match lifecycle. ",
                ~"If you write in Erlang instead, these map 1:1 to the ",
                {code, [], [~"asobi_match"]},
                ~" behaviour - see the ",
                {a, [{href, ~"/docs/erlang/api"}, az_navigate], [~"Erlang API"]},
                ~"."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"End-of-match from Lua: "]},
                    ~"to finish a match from ",
                    {code, [], [~"tick"]},
                    ~" or ",
                    {code, [], [~"leave"]},
                    ~", set ",
                    {code, [], [~"state._finished = true"]},
                    ~" and ",
                    {code, [], [~"state._result = {...}"]},
                    ~", then return the state. Returning ",
                    {code, [], [~"{ finished = true, ... }"]},
                    ~" does nothing."
                ]}
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Required: "]},
                    {code, [], [~"init"]},
                    ~", ",
                    {code, [], [~"join"]},
                    ~", ",
                    {code, [], [~"leave"]},
                    ~", ",
                    {code, [], [~"handle_input"]},
                    ~", ",
                    {code, [], [~"get_state"]},
                    ~". ",
                    {strong, [], [~"Optional: "]},
                    {code, [], [~"tick"]},
                    ~", ",
                    {code, [], [~"phases"]},
                    ~", ",
                    {code, [], [~"on_phase_started"]},
                    ~", ",
                    {code, [], [~"on_phase_ended"]},
                    ~", ",
                    {code, [], [~"vote_requested"]},
                    ~", ",
                    {code, [], [~"vote_resolved"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"init(config)"]},
            {p, [], [
                ~"Called once when the match is created. Receives the config map the match was started with (mode-specific). Return the initial state."
            ]},
            callback_pair(
                ~"""
function init(config)
    return {
        board    = { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        turn     = "x",
        players  = {},
        started  = false,
    }
end
""",
                ~"""
init(_Config) ->
    {ok, #{
        board   => [0,0,0,0,0,0,0,0,0],
        turn    => <<"x">>,
        players => #{},
        started => false
    }}.
"""
            ),

            {h2, [], [~"join(player_id, state)"]},
            {p, [], [
                ~"A player is entering. Accept and attach them, or reject. Return the new state, or ",
                {code, [], [~"nil, error"]},
                ~" to reject."
            ]},
            callback_pair(
                ~"""
function join(player_id, state)
    if state.started then
        return nil, "match_in_progress"
    end
    state.players[player_id] = (next(state.players) == nil) and "x" or "o"
    if #state.players == 2 then state.started = true end
    game.send(player_id, { kind = "welcome", mark = state.players[player_id] })
    return state
end
""",
                ~"""
join(_PlayerId, #{started := true}) ->
    {error, match_in_progress};
join(PlayerId, #{players := P} = State) ->
    Mark = case maps:size(P) of 0 -> <<"x">>; _ -> <<"o">> end,
    NewP = P#{PlayerId => Mark},
    Started = maps:size(NewP) =:= 2,
    %% Per-player send is a Lua-only helper (game.send). From Erlang,
    %% expose the mark via get_state/2 instead.
    {ok, State#{players := NewP, started := Started}}.
"""
            ),

            {h2, [], [~"leave(player_id, state)"]},
            {p, [], [
                ~"A player disconnected or was removed. Cannot fail. Use this to stop timers, release reservations, or mark the slot empty."
            ]},
            callback_pair(
                ~"""
function leave(player_id, state)
    state.players[player_id] = nil
    if state.started then
        state._finished = true
        state._result   = { forfeit = player_id }
    end
    return state
end
""",
                ~"""
leave(PlayerId, #{players := P, started := Started} = State) ->
    NewState = State#{players := maps:remove(PlayerId, P)},
    case Started of
        true  -> {finished, #{forfeit => PlayerId}, NewState};
        false -> {ok, NewState}
    end.
"""
            ),

            {h2, [], [~"handle_input(player_id, input, state)"]},
            {p, [], [
                ~"A player action arrived over WebSocket. Validate and apply. Inputs are serialised onto the match process \x{2014} ",
                ~"you can mutate state here without worrying about races."
            ]},
            callback_pair(
                ~"""
function handle_input(player_id, input, state)
    local mark = state.players[player_id]
    if not mark or mark ~= state.turn then return state end
    local cell = tonumber(input.cell)
    if not cell or state.board[cell] ~= 0 then return state end
    state.board[cell] = mark
    state.turn = (mark == "x") and "o" or "x"
    game.broadcast("move", { cell = cell, mark = mark })
    return state
end
""",
                ~"""
handle_input(PlayerId, #{<<"cell">> := Cell},
             #{players := P, turn := Turn, board := Board} = State) ->
    case maps:get(PlayerId, P, undefined) of
        Turn when is_integer(Cell), Cell >= 1, Cell =< 9 ->
            case lists:nth(Cell, Board) of
                0 ->
                    NewBoard  = set_nth(Cell, Turn, Board),
                    NextTurn  = other(Turn),
                    asobi_match_server:broadcast_event(
                      self(), <<"move">>, #{cell => Cell, mark => Turn}),
                    {ok, State#{board := NewBoard, turn := NextTurn}};
                _ -> {ok, State}
            end;
        _ -> {ok, State}
    end.
"""
            ),

            {h2, [], [~"tick(state)"]},
            {p, [], [
                ~"Called on a fixed interval (default 10 Hz, configurable per mode). Advance time, resolve AI, check win conditions. ",
                ~"Return the new state; to end the match, set ",
                {code, [], [~"state._finished = true"]},
                ~" and ",
                {code, [], [~"state._result"]},
                ~" first (see the callout above)."
            ]},
            callback_pair(
                ~"""
function tick(state)
    local w = winner(state.board)
    if w then
        state._finished = true
        state._result   = { winner = w }
    elseif is_full(state.board) then
        state._finished = true
        state._result   = { draw = true }
    end
    return state
end
""",
                ~"""
tick(#{board := Board} = State) ->
    case winner(Board) of
        none when ?is_full(Board) -> {finished, #{draw => true}, State};
        none                      -> {ok, State};
        W                         -> {finished, #{winner => W}, State}
    end.
"""
            ),

            {h2, [], [~"get_state(player_id, state)"]},
            {p, [], [
                ~"Project the full match state into what ",
                {em, [], [~"this player"]},
                ~" should see. Hide opponent cards, enemy positions out of sight, hidden rolls. ",
                ~"Called whenever a client asks for the current state (on reconnect, on view refresh)."
            ]},
            callback_pair(
                ~"""
function get_state(player_id, state)
    return {
        board    = state.board,
        turn     = state.turn,
        your_mark = state.players[player_id],
    }
end
""",
                ~"""
get_state(PlayerId, #{players := P} = State) ->
    #{
        board     => maps:get(board, State),
        turn      => maps:get(turn,  State),
        your_mark => maps:get(PlayerId, P, undefined)
    }.
"""
            ),

            {h2, [], [~"Optional: phases (Erlang match mode, Lua world mode)"]},
            {p, [], [
                ~"Declare named phases (lobby, active, results...) and hook into their transitions. ",
                ~"Phases are ",
                {strong, [], [~"supported for Erlang match games and for Lua world games"]},
                ~". Lua ",
                {em, [], [~"match"]},
                ~" games cannot use ",
                {code, [], [~"phases/1"]},
                ~" yet \x{2014} model them inside ",
                {code, [], [~"tick"]},
                ~" using explicit state fields."
            ]},
            code(
                ~"erlang",
                ~"""
phases(_Config) ->
    [
        #{name => <<"lobby">>,   duration => 30000},
        #{name => <<"active">>,  duration => 180000},
        #{name => <<"results">>, duration => 15000}
    ].

on_phase_started(Name, State) ->
    asobi_match_server:broadcast_event(self(), <<"phase">>, #{name => Name}),
    {ok, State}.

on_phase_ended(_Name, State) -> {ok, State}.
"""
            ),

            {h2, [], [~"Optional: voting"]},
            {p, [], [
                ~"Hook into in-match voting \x{2014} provide vote config on request, react to results."
            ]},
            callback_pair(
                ~"""
function vote_requested(state)
    if state.offer_boons then
        return {
            template  = "boon_pick",
            options   = { "fireball", "shield", "speed" },
            window_ms = 20000,
        }
    end
    return nil
end

function vote_resolved(_template, result, state)
    state.picked_boon = result.winner
    return state
end
""",
                ~"""
vote_requested(#{offer_boons := true}) ->
    {ok, #{
        template  => <<"boon_pick">>,
        method    => plurality,
        options   => [<<"fireball">>, <<"shield">>, <<"speed">>],
        window_ms => 20000
    }};
vote_requested(_State) ->
    none.

vote_resolved(_Template, #{winner := W}, State) ->
    {ok, State#{picked_boon => W}}.
"""
            ),

            {h2, [], [~"World-mode callbacks"]},
            {p, [], [
                ~"A game with ",
                {code, [], [~"game_type = \"world\""]},
                ~" runs on the world server and implements a different callback set. ",
                {code, [], [~"init"]},
                ~", ",
                {code, [], [~"join"]},
                ~", ",
                {code, [], [~"leave"]},
                ~", ",
                {code, [], [~"get_state"]},
                ~", ",
                {code, [], [~"phases"]},
                ~" and the ",
                {code, [], [~"on_phase_*"]},
                ~" hooks carry over; the rest are world-specific. Worked examples live on the ",
                {a, [{href, ~"/docs/world-server"}, az_navigate], [~"world server"]},
                ~" page."
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"generate_world(seed, config)"]},
                    ~" - return the initial per-zone state map, keyed by ",
                    {code, [], [~"\"x,y\""]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"spawn_templates(config)"]},
                    ~" - declare the entity templates ",
                    {code, [], [~"game.zone.spawn"]},
                    ~" draws from."
                ]},
                {li, [], [
                    {code, [], [~"spawn_position(player_id, state)"]},
                    ~" - where a joining player enters the world."
                ]},
                {li, [], [
                    {code, [], [~"zone_tick(entities, zone_state)"]},
                    ~" - per-zone simulation step; return ",
                    {code, [], [~"entities, zone_state"]},
                    ~". Replaces ",
                    {code, [], [~"tick"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"handle_input(player_id, input, entities)"]},
                    ~" - apply a player action; return the entities table."
                ]},
                {li, [], [
                    {code, [], [~"post_tick(tick_n, state)"]},
                    ~" - world-level step after all zones tick (boss phases, votes, finish)."
                ]},
                {li, [], [
                    {code, [], [~"on_world_recovered(snapshots, state)"]},
                    ~", ",
                    {code, [], [~"on_zone_loaded(cx, cy, state)"]},
                    ~", ",
                    {code, [], [~"on_zone_unloaded(cx, cy, state)"]},
                    ~" - lazy-zone and snapshot lifecycle hooks."
                ]}
            ]},

            {h2, [], [~"Pattern: minimum viable game"]},
            {p, [], [
                ~"The smallest correct game implements ",
                {code, [], [~"init"]},
                ~", ",
                {code, [], [~"join"]},
                ~", ",
                {code, [], [~"leave"]},
                ~", ",
                {code, [], [~"handle_input"]},
                ~", ",
                {code, [], [~"get_state"]},
                ~". ",
                {code, [], [~"tick"]},
                ~" is optional \x{2014} if you don't need a fixed time step, skip it."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/tutorials/tic-tac-toe"}, az_navigate], [
                        ~"Tic-tac-toe tutorial"
                    ]},
                    ~" \x{2014} all the callbacks in context."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* API reference"]},
                    ~" \x{2014} what you call ",
                    {em, [], [~"from"]},
                    ~" these callbacks."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/cookbook"}, az_navigate], [~"Cookbook"]},
                    ~" \x{2014} recipes for common patterns."
                ]}
            ]}
        ]}
    ).
callback_pair(LuaBody, _ErlangBody) ->
    ?html(code(~"lua", LuaBody)).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
