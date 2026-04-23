-module(asobi_site_docs_erlang_matchmaker_strategies_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-matchmaker-strategies", title => ~"Matchmaker strategies"}, Bindings
        ),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Erlang / Matchmaker strategies"
            ]},
            {h1, [], [~"Custom matchmaker strategies"]},
            {p, [{class, ~"docs-lede"}], [
                ~"The matchmaker comes with ",
                {code, [], [~"fill"]},
                ~" (first-come-first-served) and ",
                {code, [], [~"skill_based"]},
                ~" (skill-banded) built-in. If neither fits, implement the ",
                {code, [], [~"asobi_matchmaker_strategy"]},
                ~" behaviour and point your game mode at your module \x{2014} one ",
                ~"callback, done."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Erlang only for now. "]},
                    ~"Strategies have to run in Erlang because they see every pending ticket \x{2014} ",
                    ~"this is a hot path. From Lua, pick one of the built-in strategies with ",
                    {code, [], [~"strategy = \"fill\""]},
                    ~" or ",
                    {code, [], [~"strategy = \"skill_based\""]},
                    ~" in your match config."
                ]}
            ]},

            {h2, [], [~"The contract"]},
            code(
                ~"erlang",
                ~"""
-callback match(Tickets :: [map()], Config :: map()) ->
    {Matched :: [[map()]], Unmatched :: [map()]}.
"""
            ),
            {p, [], [
                ~"One callback. ",
                {code, [], [~"Tickets"]},
                ~" is the current pending queue for this game mode; ",
                {code, [], [~"Config"]},
                ~" is the ",
                {code, [], [~"matchmaker"]},
                ~" block from the mode's config (typically ",
                {code, [], [~"match_size"]},
                ~" and whatever your strategy needs). Return:"
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"Matched"]},
                    ~" \x{2014} a list of groups. Each group is a list of tickets that will ",
                    ~"start a match together."
                ]},
                {li, [], [
                    {code, [], [~"Unmatched"]},
                    ~" \x{2014} tickets that stay in the queue until the next tick."
                ]}
            ]},

            {h2, [], [~"Reference: the fill strategy"]},
            {p, [], [
                ~"The built-in ",
                {code, [], [~"asobi_matchmaker_fill"]},
                ~" is 20 lines. Read it before writing your own:"
            ]},
            code(
                ~"erlang",
                ~"""
-module(asobi_matchmaker_fill).
-behaviour(asobi_matchmaker_strategy).
-export([match/2]).

match(Tickets, Config) ->
    Size = maps:get(match_size, Config, 2),
    group(Tickets, Size, []).

group(Remaining, Size, Matched) when length(Remaining) < Size ->
    {lists:reverse(Matched), Remaining};
group(Tickets, Size, Matched) ->
    {Group, Rest} = lists:split(Size, Tickets),
    group(Rest, Size, [Group | Matched]).
"""
            ),

            {h2, [], [~"Example: party-aware matching"]},
            {p, [], [
                ~"A common custom strategy: respect party groupings so friends stay together. ",
                ~"Assume every ticket has a ",
                {code, [], [~"party_id"]},
                ~" key (or ",
                {code, [], [~"solo"]},
                ~" for lone players) and a ",
                {code, [], [~"party_size"]},
                ~" key."
            ]},
            code(
                ~"erlang",
                ~"""
-module(my_game_party_matcher).
-behaviour(asobi_matchmaker_strategy).
-export([match/2]).

match(Tickets, Config) ->
    MatchSize = maps:get(match_size, Config, 4),
    Parties = group_by_party(Tickets),
    pack_parties(Parties, MatchSize, [], []).

group_by_party(Tickets) ->
    %% fold into #{PartyId => [Ticket]} then return list of parties
    F = fun(T, Acc) ->
        P = maps:get(party_id, T, solo),
        maps:update_with(P, fun(L) -> [T | L] end, [T], Acc)
    end,
    maps:values(lists:foldl(F, #{}, Tickets)).

pack_parties([], _Size, Current, Matched) when Current =:= [] ->
    {lists:reverse(Matched), []};
pack_parties([], _Size, Current, Matched) ->
    %% leftover current group is unmatched — wait for more parties
    {lists:reverse(Matched), lists:flatten(Current)};
pack_parties([Party | Rest], Size, Current, Matched) ->
    Filled = length(Current) + length(Party),
    if
        Filled =:= Size ->
            pack_parties(Rest, Size, [], [lists:flatten([Party | Current]) | Matched]);
        Filled < Size ->
            pack_parties(Rest, Size, [Party | Current], Matched);
        Filled > Size ->
            %% party doesn't fit — leave it in queue, close the current group if viable
            pack_parties(Rest, Size, Current, Matched)
    end.
"""
            ),

            {p, [], [
                ~"This keeps a 3-player party with a solo player (3+1) but refuses to break a ",
                ~"4-player party into a (3,1) split. Tighten or relax the rules to taste."
            ]},

            {h2, [], [~"Register the strategy"]},
            {p, [], [
                ~"In your game mode config, point the ",
                {code, [], [~"matchmaker.strategy"]},
                ~" key at your module:"
            ]},
            code(
                ~"erlang",
                ~"""
%% sys.config
{asobi, [
    {game_modes, #{
        ~"party_mode" => #{
            module => my_party_match,
            matchmaker => #{
                strategy => my_game_party_matcher,
                match_size => 4,
                tick_interval => 1000
            }
        }
    }}
]}
"""
            ),

            {h2, [], [~"Guidelines"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Stay pure. "]},
                    ~"The callback must be a pure function of its inputs. No process calls, ",
                    ~"no side effects \x{2014} the matchmaker tick runs hot and side effects ",
                    ~"will be unpredictable when queues are large."
                ]},
                {li, [], [
                    {strong, [], [~"Be ok with not matching. "]},
                    ~"If there's no good match right now, return the ticket in ",
                    {code, [], [~"Unmatched"]},
                    ~". Bands widen on the next tick (if you use ticket age); the ticket reappears."
                ]},
                {li, [], [
                    {strong, [], [~"Use ticket age. "]},
                    ~"Each ticket has a ",
                    {code, [], [~"queued_at"]},
                    ~" timestamp. Widen bands, loosen rules, or relax party requirements as a ",
                    ~"ticket ages so queues drain."
                ]},
                {li, [], [
                    {strong, [], [~"Test with property-based tests. "]},
                    ~"Strategies are pure \x{2014} they're an ideal candidate for PropEr or Erlang ",
                    ~"QuickCheck. Invariants: every ticket in the input appears in exactly one of ",
                    {code, [], [~"Matched"]},
                    ~" or ",
                    {code, [], [~"Unmatched"]},
                    ~"; every group in ",
                    {code, [], [~"Matched"]},
                    ~" has length ",
                    {code, [], [~"match_size"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/matchmaking"}, az_navigate], [~"Matchmaking overview"]},
                    ~" \x{2014} tickets, modes, and how the engine drives the matchmaker tick."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/erlang/api"}, az_navigate], [~"Erlang API reference"]},
                    ~" \x{2014} the full ticket and config shapes."
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
