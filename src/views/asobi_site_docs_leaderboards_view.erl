-module(asobi_site_docs_leaderboards_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
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

-spec render(map()) -> arizona_template:template().
render(_Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
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
asobi_leaderboard:submit(<<"arena:weekly">>, PlayerId, Kills).
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
{ok, Top}  = asobi_leaderboard:top(<<"arena:weekly">>, 10),
{ok, Rank} = asobi_leaderboard:rank(<<"arena:weekly">>, PlayerId),
{ok, Near} = asobi_leaderboard:around(<<"arena:weekly">>, PlayerId, 5).
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

            {h2, [], [~"Definitions"]},
            {p, [], [~"Register leaderboards in ", {code, [], [~"sys.config"]}, ~":"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {leaderboards, #{
        <<"arena:weekly">> => #{
            mode    => monotonic,
            window  => {weekly, monday, 0},   %% reset Monday 00:00 UTC
            bucket  => <<"arena">>
        },
        <<"xp:lifetime">> => #{mode => cumulative}
    }}
]}
"""
            ),

            {h2, [], [~"Tournaments"]},
            {p, [], [
                ~"Tie a leaderboard to a season + bracket. Players join, submit scores during the window, and at close the tournament resolves brackets and distributes prizes."
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
{ok, TId} = asobi_tournament:create(#{
    leaderboard  => <<"arena:weekly">>,
    starts_at    => {{2026,4,22},{16,0,0}},
    ends_at      => {{2026,4,29},{16,0,0}},
    entry_fee    => #{currency => <<"gold">>, amount => 100},
    prize_pool   => #{<<"gold">> => 100000},
    distribution => [0.5, 0.3, 0.2]   %% top 3 split
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
                    {a, [{href, ~"/docs/economy"}], [~"Economy & IAP"]},
                    ~" \x{2014} prize distribution currencies."
                ]},
                {li, [], [{a, [{href, ~"/docs/lua/api"}], [~"Lua API: game.leaderboard.*"]}]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(~"/docs/leaderboards", Content).

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
