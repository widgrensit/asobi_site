-module(asobi_site_docs_voting_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-voting", title => ~"Voting — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Voting"
            ]},
            {h1, [], [~"Voting"]},
            {p, [{class, ~"docs-lede"}], [
                ~"In-match voting for roguelike-style group decisions: path choices, item picks, run modifiers, map votes. ",
                ~"Five methods, templates, spectator voting, async quorum, anti-tyranny mitigations."
            ]},

            {h2, [], [~"Flow"]},
            {ol, [], [
                {li, [], [~"Game mode (or match server) starts a vote with options + window."]},
                {li, [], [
                    ~"Eligible players receive ", {code, [], [~"match.vote_start"]}, ~" via WS."
                ]},
                {li, [], [
                    ~"Players cast votes during the window (may change up to ",
                    {code, [], [~"max_revotes"]},
                    ~" times)."
                ]},
                {li, [], [
                    ~"On close, votes are tallied; ",
                    {code, [], [~"match.vote_result"]},
                    ~" is broadcast."
                ]},
                {li, [], [~"Game mode receives ", {code, [], [~"vote_resolved/3"]}, ~"."]}
            ]},

            {h2, [], [~"Starting a vote"]},
            {p, [], [~"Two paths: automatic via callback, or manual via API."]},
            pair(
                ~"""
-- Lua: automatic
function game.vote_requested(state)
    if state.phase == "vote_pending" then
        return {
            template    = "path_choice",
            options     = { "jungle", "volcano", "caves" },
            window_ms   = 15000,
            method      = "plurality",
        }
    end
    return nil
end
""",
                ~"""
%% Erlang: manual
asobi_match_server:start_vote(MatchPid, #{
    template   => <<"path_choice">>,
    options    => [
        #{id => <<"jungle">>,  label => <<"Jungle Path">>},
        #{id => <<"volcano">>, label => <<"Volcano Path">>},
        #{id => <<"caves">>,   label => <<"Ice Caves">>}
    ],
    window_ms  => 15000,
    method     => <<"plurality">>,
    visibility => <<"live">>
}).
"""
            ),

            {h2, [], [~"Config keys"]},
            {pre, [], [
                {code, [], [
                    ~"""
 options              [map()]          required — [{id, label}, ...]
 template             binary()         "default" — reference to vote_templates
 window_ms            pos_integer()    15000
 method               binary()         "plurality" | "approval" | "weighted" | "ranked"
 visibility           binary()         "live" | "hidden"
 tie_breaker          binary()         "random" | "first"
 veto_enabled         boolean()        false
 weights              map()            per-voter weights for weighted method
 max_revotes          pos_integer()    3
 quorum               float()          fraction of eligible needed (async)
 default_votes        map()            fallback votes at resolution time
 delegation           map()            voter -> delegate
 window_type          binary()         "fixed" | "ready_up" | "hybrid" | "adaptive"
 supermajority        float()          0..1 threshold
 require_supermajority boolean()       no_consensus if not reached
"""
                ]}
            ]},

            {h2, [], [~"Methods"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Plurality"]},
                    ~" \x{2014} one option each; most votes wins. Ties use ",
                    {code, [], [~"tie_breaker"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Approval"]},
                    ~" \x{2014} submit a list of options you'd accept. Highest total approval wins. Good for \x{201C}avoid the worst\x{201D}."
                ]},
                {li, [], [
                    {strong, [], [~"Weighted"]},
                    ~" \x{2014} votes multiplied by per-voter weight. Defaults to 1 if not listed."
                ]},
                {li, [], [
                    {strong, [], [~"Ranked"]},
                    ~" \x{2014} submit a preference list. Iteratively eliminate lowest; transfer to next preference until majority."
                ]},
                {li, [], [
                    {strong, [], [~"Spectator-weighted"]},
                    ~" \x{2014} pass ",
                    {code, [], [~"spectators"]},
                    ~" + ",
                    {code, [], [~"spectator_weight"]},
                    ~" for a separate pool merged at a ratio."
                ]}
            ]},

            {h2, [], [~"Window types"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"fixed"]},
                    ~" (default): runs for ",
                    {code, [], [~"window_ms"]},
                    ~" then closes."
                ]},
                {li, [], [
                    {strong, [], [~"ready_up"]},
                    ~": closes when all eligible have voted (or timeout)."
                ]},
                {li, [], [
                    {strong, [], [~"hybrid"]},
                    ~": ready-up but enforce ",
                    {code, [], [~"min_window_ms"]},
                    ~" before early close."
                ]},
                {li, [], [
                    {strong, [], [~"adaptive"]},
                    ~": shrinks remaining time to 3s when supermajority is reached. Resets if lost."
                ]}
            ]},

            {h2, [], [~"Async voting"]},
            {p, [], [~"For non-real-time games \x{2014} not all players online at once."]},
            code(
                ~"erlang",
                ~"""
#{
    quorum         => 0.5,                             %% at least 50% must vote
    default_votes  => #{<<"p2">> => <<"opt_b">>},      %% fallback at resolution
    delegation     => #{<<"p3">> => <<"p1">>}          %% follows p1's choice
}
"""
            ),
            {p, [], [
                ~"If quorum isn't met, the result has ",
                {code, [], [~"winner => undefined"]},
                ~" and ",
                {code, [], [~"status => \"no_quorum\""]},
                ~"."
            ]},

            {h2, [], [~"Templates"]},
            {p, [], [
                ~"Reusable configs in ", {code, [], [~"sys.config"]}, ~"; per-call overrides win:"
            ]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {vote_templates, #{
        <<"boon_pick">>   => #{method => <<"plurality">>, window_ms => 15000},
        <<"path_choice">> => #{method => <<"approval">>,  visibility => <<"hidden">>},
        <<"weighted_pick">>=> #{method => <<"weighted">>, window_ms => 15000}
    }}
]}
"""
            ),

            {h2, [], [~"Anti-tyranny"]},
            {h3, [], [~"Frustration accumulator"]},
            {p, [], [
                ~"Losers get a cumulative weight bonus on future votes: ",
                {code, [], [~"1 + lost * frustration_bonus"]},
                ~". Resets on a win. Configured at match start:"
            ]},
            code(
                ~"erlang",
                ~"""
asobi_match_sup:start_match(#{
    game_module       => my_game,
    frustration_bonus => 0.5   %% default 0.5; 0 disables
}).
"""
            ),
            {h3, [], [~"Supermajority requirement"]},
            {p, [], [
                ~"Force 2/3 or 3/4 consensus; otherwise ",
                {code, [], [~"no_consensus"]},
                ~" and the game mode decides (re-vote, default, etc.)."
            ]},
            {h3, [], [~"Veto tokens"]},
            {p, [], [~"Give each player a limited number of vetoes per match:"]},
            code(
                ~"erlang",
                ~"""
#{veto_tokens_per_player => 2}
"""
            ),
            {p, [], [
                ~"Clients veto via ",
                {code, [], [~"{type: \"vote.veto\"}"]},
                ~". Match server enforces token accounting."
            ]},

            {h2, [], [~"Handling results"]},
            pair(
                ~"""
function game.vote_resolved(template, result, state)
    if template == "path_choice" then
        state.current_path = result.winner
    elseif template == "item_pick" then
        state = add_item(result.winner, state)
    end
    return state
end
""",
                ~"""
vote_resolved(<<"path_choice">>, #{winner := W}, State) ->
    {ok, State#{current_path => W}};
vote_resolved(<<"item_pick">>, #{winner := I}, State) ->
    {ok, add_item(I, State)}.
"""
            ),

            {h2, [], [~"WS + REST"]},
            {p, [], [
                ~"See the ",
                {a, [{href, ~"/docs/protocols/websocket#voting"}, az_navigate], [~"WebSocket voting messages"]},
                ~" for ",
                {code, [], [~"vote.cast"]},
                ~", ",
                {code, [], [~"vote.veto"]},
                ~", ",
                {code, [], [~"match.vote_start"]},
                ~", ",
                {code, [], [~"match.vote_tally"]},
                ~", ",
                {code, [], [~"match.vote_result"]},
                ~". REST: ",
                {code, [], [~"GET /api/v1/matches/:id/votes"]},
                ~", ",
                {code, [], [~"GET /api/v1/votes/:id"]},
                ~"."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Late-arriving votes: "]},
                    ~"a 500ms grace period after the window compensates for network latency \x{2014} casts that arrive just after close are still counted."
                ]}
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
