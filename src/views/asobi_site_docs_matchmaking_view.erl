-module(asobi_site_docs_matchmaking_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-matchmaking", title => ~"Matchmaking — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Matchmaking"
            ]},
            {h1, [], [~"Matchmaking"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Periodic-tick matchmaker (default 1 Hz). ",
                ~"Players submit tickets with a mode, optional properties, and an optional party; a per-mode strategy module groups tickets into matches and spawns them."
            ]},

            {h2, [], [~"Submitting a ticket"]},
            pair(
                ~"""
-- WebSocket
{"type": "matchmaker.add",
 "payload": {
   "mode": "arena",
   "properties": {"skill": 1200, "region": "eu-west"}
 }}
""",
                ~"""
%% Erlang API
{ok, TicketId} = asobi_matchmaker:add(PlayerId, #{
    mode       => <<"arena">>,
    properties => #{skill => 1200, region => <<"eu-west">>}
}).
"""
            ),
            {p, [], [~"REST equivalent:"]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8080/api/v1/matchmaker \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "mode": "arena",
    "properties": {"skill": 1200, "region": "eu-west"}
  }'
"""
            ),
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Ticket shape. "]},
                    ~"A ticket currently supports ",
                    {code, [], [~"mode"]},
                    ~", ",
                    {code, [], [~"properties"]},
                    ~", and ",
                    {code, [], [~"party"]},
                    ~". A query-language extension (numeric ranges, required keys, auto skill-window expansion) is on the roadmap but not shipped \x{2014} do the filtering inside your strategy module instead."
                ]}
            ]},

            {h2, [], [~"Skill-based matching"]},
            {p, [], [
                ~"Enable the built-in ",
                {code, [], [~"skill_based"]},
                ~" strategy per mode. Tickets are sorted by ",
                {code, [], [~"properties.skill"]},
                ~" and paired within an expanding window (configurable via ",
                {code, [], [~"skill_window"]},
                ~" + ",
                {code, [], [~"skill_expand_rate"]},
                ~")."
            ]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {game_modes, #{
        ~"ranked" => #{
            module            => my_arena,
            match_size        => 4,
            strategy          => skill_based,
            skill_window      => 200,
            skill_expand_rate => 50
        }
    }}
]}
"""
            ),

            {h2, [], [~"Parties"]},
            {p, [], [~"Queue together \x{2014} all party members land in the same match:"]},
            code(
                ~"json",
                ~"""
{"type": "matchmaker.add",
 "payload": {
   "mode": "arena",
   "party": ["player_id_2", "player_id_3"],
   "properties": {"skill": 1200}
 }}
"""
            ),

            {h2, [], [~"Cancelling"]},
            pair(
                ~"""
{"type": "matchmaker.remove", "payload": {"ticket_id": "..."}}
""",
                ~"""
asobi_matchmaker:remove(PlayerId, TicketId).
"""
            ),

            {h2, [], [~"Configuration"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {matchmaker, #{
        tick_interval    => 1000,   %% ms between matchmaker ticks
        max_wait_seconds => 60      %% max wait before timeout
    }}
]}
"""
            ),

            {h2, [], [~"Custom strategies"]},
            {p, [], [
                ~"The default strategy is ",
                {code, [], [~"asobi_matchmaker_fill"]},
                ~" (first-come-first-matched). For MMR-bucketed matching use ",
                {code, [], [~"asobi_matchmaker_skill"]},
                ~". Write your own by implementing the ",
                {code, [], [~"asobi_matchmaker_strategy"]},
                ~" behaviour (a single ",
                {code, [], [~"match/2"]},
                ~" callback):"
            ]},
            code(
                ~"erlang",
                ~"""
-module(my_matchmaker).
-behaviour(asobi_matchmaker_strategy).

-export([match/2]).

%% match(Tickets, ModeConfig) -> {Matched, Unmatched}
%% Matched is a list of groups (each group is a list of tickets).
match(Tickets, Config) ->
    Size = maps:get(match_size, Config, 4),
    %% Bucket by skill tier, form groups of Size, return leftovers.
    Buckets = bucket_by_skill(Tickets),
    {Groups, Leftover} = lists:foldl(
        fun(Bucket, {Gs, Left}) ->
            {Full, Rest} = take_full_groups(Bucket, Size),
            {Full ++ Gs, Rest ++ Left}
        end,
        {[], []},
        Buckets),
    {Groups, Leftover}.
"""
            ),
            {p, [], [
                ~"Strategy is selected per mode via the ",
                {code, [], [~"strategy"]},
                ~" key in ",
                {code, [], [~"game_modes"]},
                ~" (there is no top-level ",
                {code, [], [~"matchmaker_strategy"]},
                ~" config):"
            ]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {game_modes, #{
        ~"ranked" => #{module => my_arena, match_size => 4, strategy => my_matchmaker}
    }}
]}
"""
            ),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                        ~"WebSocket: matchmaker.* messages"
                    ]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/erlang/api"}, az_navigate], [
                        ~"Erlang API: asobi_matchmaker"
                    ]}
                ]}
            ]}
        ]}
    ).
pair(WsBody, ErlBody) ->
    ?html(
        {'div', [{class, ~"docs-lang-pair"}], [
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"JSON"]},
                {pre, [], [{code, [{class, ~"language-json"}], [WsBody]}]}
            ]},
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Erlang"]},
                {pre, [], [{code, [{class, ~"language-erlang"}], [ErlBody]}]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
