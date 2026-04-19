-module(asobi_site_docs_lua_callbacks_view).
-include_lib("arizona/include/arizona_stateful.hrl").

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

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Lua / Callbacks"
            ]},
            {h1, [], [~"Game module callbacks"]},
            {p, [{class, ~"docs-lede"}], [
                ~"The functions ",
                {em, [], [~"you"]},
                ~" write in a game module. Asobi calls them at the right moments in the match lifecycle. ",
                ~"These mirror the ",
                {code, [], [~"asobi_match"]},
                ~" Erlang behaviour \x{2014} every Lua callback maps to an Erlang callback with the same name and arity."
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
function game.init(config)
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
                ~"A player is entering. Accept and attach them, or reject. ",
                ~"From Lua, return the new state (or ",
                {code, [], [~"nil, error"]},
                ~" to reject). From Erlang, return ",
                {code, [], [~"{ok, NewState}"]},
                ~" or ",
                {code, [], [~"{error, Reason}"]},
                ~"."
            ]},
            callback_pair(
                ~"""
function game.join(player_id, state)
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
function game.leave(player_id, state)
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
function game.handle_input(player_id, input, state)
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
                ~"Return the new state \x{2014} or ",
                {code, [], [~"{ finished = true, result = ... }"]},
                ~" (Lua) / ",
                {code, [], [~"{finished, Result, State}"]},
                ~" (Erlang) to end the match."
            ]},
            callback_pair(
                ~"""
function game.tick(state)
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
function game.get_state(player_id, state)
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
function game.vote_requested(state)
    if state.offer_boons then
        return {
            template  = "boon_pick",
            options   = { "fireball", "shield", "speed" },
            window_ms = 20000,
        }
    end
    return nil
end

function game.vote_resolved(_template, result, state)
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
                    {a, [{href, ~"/docs/tutorials/tic-tac-toe"}, az_navigate], [~"Tic-tac-toe tutorial"]},
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
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/lua/callbacks", Content).

callback_pair(LuaBody, ErlangBody) ->
    ?html(
        {'div', [{class, ~"docs-lang-pair"}], [
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Lua"]},
                code(~"lua", LuaBody)
            ]},
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Erlang"]},
                code(~"erlang", ErlangBody)
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
