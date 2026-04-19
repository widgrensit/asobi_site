-module(asobi_site_docs_leaderboards_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{
                id => ~"docs-leaderboards",
                title => ~"Leaderboards & tournaments — Asobi docs"
            },
            Bindings
        ),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Leaderboards & tournaments"
            ]},
            {h1, [], [~"Leaderboards & tournaments"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Score tables with multiple scoring modes and time windows. Tournaments wrap leaderboards with seasonal resets, brackets, and prize distribution."
            ]},

            {h2, [], [~"Leaderboard models"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Monotonic"]},
                    ~" \x{2014} keeps the highest score submitted per player (e.g. \x{201C}best lap\x{201D})."
                ]},
                {li, [], [
                    {strong, [], [~"Cumulative"]},
                    ~" \x{2014} sums submissions (e.g. \x{201C}total XP\x{201D})."
                ]},
                {li, [], [
                    {strong, [], [~"Windowed"]},
                    ~" \x{2014} same as above but with a rolling time window (weekly / monthly) that resets automatically."
                ]}
            ]},

            {h2, [], [~"Submitting scores"]},
            pair(
                ~"""
game.leaderboard.submit("arena:weekly", player_id, kills)
""",
                ~"""
asobi_leaderboard_server:submit(<<"arena:weekly">>, PlayerId, Kills).
"""
            ),

            {h2, [], [~"Reading"]},
            pair(
                ~"""
for _, e in ipairs(game.leaderboard.top("arena:weekly", 10)) do
    print(e.rank, e.player_id, e.score)
end
local my_rank = game.leaderboard.rank("arena:weekly", player_id)
local near    = game.leaderboard.around("arena:weekly", player_id, 5)
""",
                ~"""
Top        = asobi_leaderboard_server:top(<<"arena:weekly">>, 10),
{ok, Rank} = asobi_leaderboard_server:rank(<<"arena:weekly">>, PlayerId),
Near       = asobi_leaderboard_server:around(<<"arena:weekly">>, PlayerId, 5).
"""
            ),

            {h3, [], [~"REST"]},
            code(
                ~"bash",
                ~"""
GET  /api/v1/leaderboards/:id                  Top N entries
GET  /api/v1/leaderboards/:id/around/:player   Entries around a player
POST /api/v1/leaderboards/:id                  Submit a score
"""
            ),

            {h2, [], [~"Starting a board"]},
            {p, [], [
                ~"Boards are lazily spawned on first use \x{2014} the first call to ",
                {code, [], [~"submit"]},
                ~"/",
                {code, [], [~"top"]},
                ~"/",
                {code, [], [~"rank"]},
                ~" with a board ID starts a dedicated ",
                {code, [], [~"asobi_leaderboard_server"]},
                ~" process. You can also start one eagerly:"
            ]},
            code(
                ~"erlang",
                ~"""
{ok, _Pid} = asobi_leaderboard_sup:start_board(<<"arena:weekly">>).
"""
            ),

            {h2, [], [~"Tournaments"]},
            {p, [], [
                ~"A tournament wraps a leaderboard with a time window and prize pool. Tournaments are created by inserting a row via ",
                {code, [], [~"asobi_repo"]},
                ~" and then booting a server under ",
                {code, [], [~"asobi_tournament_sup"]},
                ~":"
            ]},
            code(
                ~"bash",
                ~"""
GET  /api/v1/tournaments               List active tournaments
GET  /api/v1/tournaments/:id           Get tournament details
POST /api/v1/tournaments/:id/join      Join a tournament
"""
            ),
            code(
                ~"erlang",
                ~"""
{ok, _Pid} = asobi_tournament_sup:start_tournament(#{
    tournament_id => <<"arena:2026-w17">>,
    leaderboard   => <<"arena:weekly">>
}).
"""
            ),

            {h2, [], [~"Seasons"]},
            {p, [], [
                ~"Seasons wrap longer lifecycles (weekly competitive, monthly events). When a season ends, leaderboards tied to it reset and archive snapshots are persisted for history queries."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/economy"}, az_navigate], [~"Economy & IAP"]},
                    ~" \x{2014} prize distribution currencies."
                ]},
                {li, [], [{a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua API: game.leaderboard.*"]}]}
            ]}
        ]}
    ).
pair(LuaBody, ErlBody) ->
    ?html(
        {'div', [{class, ~"docs-lang-pair"}], [
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Lua"]},
                code(~"lua", LuaBody)
            ]},
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Erlang"]},
                code(~"erlang", ErlBody)
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
