-module(asobi_site_docs_matchmaking_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-matchmaking", title => ~"Matchmaking — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(_Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
                ~" / Matchmaking"
            ]},
            {h1, [], [~"Matchmaking"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Query-based matchmaker running as a periodic tick (default 1 Hz). ",
                ~"Players submit tickets with properties and a query; when mutually compatible tickets exist, a match is spawned and players are notified."
            ]},

            {h2, [], [~"Submitting a ticket"]},
            pair(
                ~"""
-- WebSocket
{"type": "matchmaker.add",
 "payload": {
   "mode": "arena",
   "properties": {"skill": 1200, "region": "eu-west"},
   "query": "+region:eu-west skill:>=1000 skill:<=1400"
 }}
""",
                ~"""
%% Erlang API
{ok, TicketId} = asobi_matchmaker:add(PlayerId, #{
    mode       => <<"arena">>,
    properties => #{skill => 1200, region => <<"eu-west">>},
    query      => <<"+region:eu-west skill:>=1000 skill:<=1400">>
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
    "properties": {"skill": 1200, "region": "eu-west"},
    "query": "+region:eu-west skill:>=1000 skill:<=1400"
  }'
"""
            ),

            {h2, [], [~"Query language"]},
            {p, [], [
                ~"Tickets include a query describing acceptable opponents. Both sides must match each other's query for a pairing to form."
            ]},
            code(
                ~"text",
                ~"""
+region:eu-west mode:ranked skill:>=800 skill:<=1200
"""
            ),
            {ul, [], [
                {li, [], [{code, [], [~"key:value"]}, ~" \x{2014} exact match"]},
                {li, [], [{code, [], [~"+key:value"]}, ~" \x{2014} required (must match)"]},
                {li, [], [
                    {code, [], [~"key:>=N"]},
                    ~" / ",
                    {code, [], [~"key:<=N"]},
                    ~" \x{2014} numeric range"
                ]},
                {li, [], [~"Multiple conditions are AND-ed."]}
            ]},

            {h2, [], [~"Skill window expansion"]},
            {p, [], [
                ~"When a player waits too long, the matchmaker widens the skill window automatically. Each tick increments the ",
                {code, [], [~"expansion_level"]},
                ~" for unfilled tickets, relaxing numeric constraints. This trades strict skill-fairness for queue time."
            ]},

            {h2, [], [~"Parties"]},
            {p, [], [~"Queue together \x{2014} all party members land in the same match:"]},
            code(
                ~"json",
                ~"""
{"type": "matchmaker.add",
 "payload": {
   "mode": "arena",
   "party": ["player_id_2", "player_id_3"],
   "properties": {"skill": 1200},
   "query": "skill:>=1000 skill:<=1400"
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
                ~"The default strategy is the ",
                {code, [], [~"asobi_matchmaker_fill"]},
                ~" first-come-first-matched module. ",
                ~"For MMR-bucketed matching, use ",
                {code, [], [~"asobi_matchmaker_skill"]},
                ~". Write your own by implementing the ",
                {code, [], [~"asobi_matchmaker_strategy"]},
                ~" behaviour:"
            ]},
            code(
                ~"erlang",
                ~"""
-module(my_matchmaker).
-behaviour(asobi_matchmaker_strategy).

-export([group/2, compatible/3]).

%% group tickets into potential matches each tick
group(Tickets, _Cfg) ->
    lists:filter(fun ready_group/1,
        bucket_by(fun(#{properties := #{skill := S}}) -> S div 100 end, Tickets)).

%% return true if two tickets can play together
compatible(#{properties := A}, #{properties := B}, _Cfg) ->
    abs(maps:get(skill, A) - maps:get(skill, B)) =< 150.
"""
            ),
            {p, [], [~"Register it in config:"]},
            code(
                ~"erlang",
                ~"""
{asobi, [{matchmaker_strategy, my_matchmaker}]}
"""
            ),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/protocols/websocket"}], [
                        ~"WebSocket: matchmaker.* messages"
                    ]}
                ]},
                {li, [], [{a, [{href, ~"/docs/erlang/api"}], [~"Erlang API: asobi_matchmaker"]}]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(~"/docs/matchmaking", Content).

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
