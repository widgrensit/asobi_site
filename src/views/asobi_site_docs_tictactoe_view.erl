-module(asobi_site_docs_tictactoe_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-tictactoe", title => ~"Tic-tac-toe tutorial — Asobi docs"},
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
                ~" / Tutorials / Tic-tac-toe"
            ]},
            {h1, [], [~"Tic-tac-toe tutorial"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Build a complete two-player tic-tac-toe game end to end: state, inputs, win detection, broadcasting, and reconnect. ",
                ~"Every step is shown in ",
                {strong, [], [~"both Lua and Erlang"]},
                ~" so you can pick either path."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Prerequisites: "]},
                    ~"finish the ",
                    {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"quick start"]},
                    ~" first (engine running, CLI installed)."
                ]}
            ]},

            {h2, [], [~"What we're building"]},
            {ul, [], [
                {li, [], [~"Two players, authoritative server."]},
                {li, [], [~"3\x{00D7}3 board, alternating turns, input validation."]},
                {li, [], [~"Server detects a win or a draw and ends the match."]},
                {li, [], [
                    ~"State view is projected per-player so each side sees ",
                    {em, [], [~"their"]},
                    ~" mark."
                ]}
            ]},

            {h2, [], [~"1. Shape the state"]},
            {p, [], [
                ~"We need: a board (9 cells), whose turn it is, the two players' ids and their marks, and a ",
                {code, [], [~"started"]},
                ~" flag so late-joiners get rejected."
            ]},
            pair(
                ~"""
-- game/ttt.lua
local game = {}

function game.init(_config)
    return {
        board   = { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        turn    = "x",
        players = {},
        started = false,
        result  = nil,  -- set when finished
    }
end
""",
                ~"""
%% src/ttt_game.erl
-module(ttt_game).
-behaviour(asobi_match).
-export([init/1, join/2, leave/2, handle_input/3, tick/1, get_state/2]).

init(_Config) ->
    {ok, #{
        board   => [0,0,0,0,0,0,0,0,0],
        turn    => <<"x">>,
        players => #{},
        started => false,
        result  => undefined
    }}.
"""
            ),

            {h2, [], [~"2. Accept players"]},
            {p, [], [
                ~"First player gets ",
                {code, [], [~"x"]},
                ~", second gets ",
                {code, [], [~"o"]},
                ~", third is rejected. Once we have two, the match is started and we broadcast ",
                {code, [], [~"go"]},
                ~"."
            ]},
            pair(
                ~"""
function game.join(player_id, state)
    if state.started then
        return nil, "match_full"
    end
    local count = 0
    for _ in pairs(state.players) do count = count + 1 end
    local mark = (count == 0) and "x" or "o"
    state.players[player_id] = mark
    game.send(player_id, { kind = "welcome", mark = mark })

    if count + 1 == 2 then
        state.started = true
        game.broadcast("go", { turn = state.turn })
    end
    return state
end
""",
                ~"""
join(_PlayerId, #{started := true}) ->
    {error, match_full};
join(PlayerId, #{players := P} = State) ->
    Mark = case maps:size(P) of 0 -> <<"x">>; _ -> <<"o">> end,
    NewP = P#{PlayerId => Mark},
    %% Per-player welcome is a Lua-only helper; from Erlang use game logic
    %% to project the mark into get_state/2 instead.
    State1 = State#{players := NewP},
    case maps:size(NewP) of
        2 ->
            asobi_match_server:broadcast_event(
              self(), <<"go">>, #{turn => maps:get(turn, State)}),
            {ok, State1#{started := true}};
        _ ->
            {ok, State1}
    end.
"""
            ),

            {h2, [], [~"3. Validate and apply moves"]},
            {p, [], [
                ~"Three rules: the player must be in the match, it must be their turn, and the target cell must be empty. ",
                ~"Anything else is silently ignored \x{2014} never trust the client."
            ]},
            pair(
                ~"""
function game.handle_input(player_id, input, state)
    if not state.started or state.result then return state end

    local mark = state.players[player_id]
    if not mark or mark ~= state.turn then return state end

    local cell = tonumber(input.cell)
    if not cell or cell < 1 or cell > 9 or state.board[cell] ~= 0 then
        return state
    end

    state.board[cell] = mark
    state.turn = (mark == "x") and "o" or "x"
    game.broadcast("move", { cell = cell, mark = mark })
    return state
end
""",
                ~"""
handle_input(_PlayerId, _Input, #{started := false} = State) ->
    {ok, State};
handle_input(_PlayerId, _Input, #{result := R} = State) when R =/= undefined ->
    {ok, State};
handle_input(PlayerId, #{<<"cell">> := Cell},
             #{players := P, turn := Turn, board := Board} = State) ->
    case {maps:get(PlayerId, P, undefined), is_integer(Cell), Cell} of
        {Turn, true, C} when C >= 1, C =< 9 ->
            case lists:nth(C, Board) of
                0 ->
                    NewBoard = set_nth(C, Turn, Board),
                    asobi_match_server:broadcast_event(
                      self(), <<"move">>, #{cell => C, mark => Turn}),
                    {ok, State#{board := NewBoard, turn := other(Turn)}};
                _ ->
                    {ok, State}
            end;
        _ ->
            {ok, State}
    end.

set_nth(1, V, [_|T]) -> [V|T];
set_nth(I, V, [H|T]) -> [H | set_nth(I - 1, V, T)].

other(<<"x">>) -> <<"o">>;
other(<<"o">>) -> <<"x">>.
"""
            ),

            {h2, [], [~"4. Detect a winner"]},
            {p, [], [
                ~"Eight winning lines, same for both players. Run them every tick: cheap enough that we don't need to optimise, clear enough to audit."
            ]},
            pair(
                ~"""
local LINES = {
    {1,2,3},{4,5,6},{7,8,9},  -- rows
    {1,4,7},{2,5,8},{3,6,9},  -- cols
    {1,5,9},{3,5,7},          -- diagonals
}

local function winner(board)
    for _, l in ipairs(LINES) do
        local a, b, c = board[l[1]], board[l[2]], board[l[3]]
        if a ~= 0 and a == b and b == c then return a end
    end
    return nil
end

local function is_full(board)
    for i = 1, 9 do if board[i] == 0 then return false end end
    return true
end

function game.tick(state)
    if state._finished or not state.started then return state end
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
-define(LINES, [
    {1,2,3},{4,5,6},{7,8,9},
    {1,4,7},{2,5,8},{3,6,9},
    {1,5,9},{3,5,7}
]).

tick(#{result := R} = State) when R =/= undefined ->
    {ok, State};
tick(#{started := false} = State) ->
    {ok, State};
tick(#{board := Board} = State) ->
    case winner(Board) of
        none ->
            case is_full(Board) of
                true  -> finish(#{draw => true}, State);
                false -> {ok, State}
            end;
        W -> finish(#{winner => W}, State)
    end.

winner(Board) ->
    Lines = [ {lists:nth(A, Board),
               lists:nth(B, Board),
               lists:nth(C, Board)} || {A,B,C} <- ?LINES ],
    case [ X || {X, X, X} = {X,_,_} <- Lines, X =/= 0 ] of
        [W|_] -> W;
        []    -> none
    end.

is_full(B) -> not lists:member(0, B).

finish(Result, State) ->
    {finished, Result, State#{result := Result}}.
"""
            ),

            {h2, [], [~"5. Hide opponent info (there is none, but...)"]},
            {p, [], [
                ~"Tic-tac-toe is fully observable \x{2014} both players see the whole board. We still implement ",
                {code, [], [~"get_state"]},
                ~" so reconnects work: the client can ask the server for the current view at any time."
            ]},
            pair(
                ~"""
function game.get_state(player_id, state)
    return {
        board     = state.board,
        turn      = state.turn,
        started   = state.started,
        your_mark = state.players[player_id],
        result    = state._result,  -- nil if still playing
    }
end

function game.leave(player_id, state)
    state.players[player_id] = nil
    if state.started and not state._finished then
        state._finished = true
        state._result   = { forfeit = player_id }
    end
    return state
end
""",
                ~"""
get_state(PlayerId, State) ->
    #{
        board     => maps:get(board, State),
        turn      => maps:get(turn,  State),
        started   => maps:get(started, State),
        your_mark => maps:get(PlayerId, maps:get(players, State), undefined),
        result    => maps:get(result, State)
    }.

leave(PlayerId, #{players := P, started := true, result := undefined} = State) ->
    Res = #{forfeit => PlayerId},
    {finished, Res, State#{
        players := maps:remove(PlayerId, P),
        result  := Res
    }};
leave(PlayerId, #{players := P} = State) ->
    {ok, State#{players := maps:remove(PlayerId, P)}}.
"""
            ),

            {h2, [], [~"6. Deploy and play"]},
            {p, [], [
                ~"Lua path \x{2014} drop the file in your bundle and deploy:"
            ]},
            code(
                ~"bash",
                ~"""
asobi deploy ./game
"""
            ),
            {p, [], [
                ~"Erlang path \x{2014} compile and restart your release (or use ",
                {code, [], [~"rebar3 shell"]},
                ~" during development):"
            ]},
            code(
                ~"bash",
                ~"""
rebar3 compile
"""
            ),
            {p, [], [
                ~"Then start two WebSocket clients and matchmake into a game:"
            ]},
            code(
                ~"bash",
                ~"""
# terminal 1
wscat -c ws://localhost:8080/ws
> {"type":"session.connect","payload":{"token":"alice-token"}}
> {"type":"matchmaker.add","payload":{"mode":"ttt"}}
# server replies with matchmaker.matched { match_id: "<id>" }
> {"type":"match.join","payload":{"match_id":"<id>"}}

# terminal 2
wscat -c ws://localhost:8080/ws
> {"type":"session.connect","payload":{"token":"bob-token"}}
> {"type":"matchmaker.add","payload":{"mode":"ttt"}}
> {"type":"match.join","payload":{"match_id":"<id>"}}

# either terminal
> {"type":"match.input","payload":{"cell":5}}
"""
            ),

            {'div', [{class, ~"docs-callout docs-callout-success"}], [
                {p, [], [
                    {strong, [], [~"Done. "]},
                    ~"You have an authoritative, two-player, reconnect-safe tic-tac-toe on Asobi in roughly 70 lines."
                ]}
            ]},

            {h2, [], [~"Exercises"]},
            {ul, [], [
                {li, [], [
                    ~"Add a rematch flow: on ",
                    {code, [], [~"input.action == \"rematch\""]},
                    ~", reset state and broadcast ",
                    {code, [], [~"go"]},
                    ~"."
                ]},
                {li, [], [
                    ~"Add a per-player move timer \x{2014} forfeit if a player takes longer than 30 seconds."
                ]},
                {li, [], [
                    ~"Add a spectator role that can see the board but cannot submit inputs."
                ]},
                {li, [], [
                    ~"Submit the winner to a leaderboard via ",
                    {code, [], [~"game.leaderboard.submit"]},
                    ~" (Lua) or ",
                    {code, [], [~"asobi_leaderboard_server:submit/3"]},
                    ~" (Erlang)."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"Game module callbacks"]},
                    ~" \x{2014} the full shape of what you can hook into."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua API reference"]},
                    ~" / ",
                    {a, [{href, ~"/docs/erlang/api"}, az_navigate], [~"Erlang API reference"]},
                    ~" \x{2014} everything the runtime exposes."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/cookbook"}, az_navigate], [~"Cookbook"]},
                    ~" \x{2014} recipes for more ambitious games."
                ]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/tutorials/tic-tac-toe", Content).

pair(LuaBody, ErlangBody) ->
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
