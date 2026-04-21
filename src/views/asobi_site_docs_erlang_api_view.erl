-module(asobi_site_docs_erlang_api_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-erlang-api", title => ~"Erlang API — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Erlang / API"
            ]},
            {h1, [], [~"Erlang API reference"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi is a plain Erlang/OTP library. You can use it directly from Erlang (or any BEAM language) ",
                ~"without touching Lua \x{2014} Lua is just a convenience layer that dispatches to these same modules."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"When to use Erlang over Lua: "]},
                    ~"you want behaviour-level control (supervision trees, custom match state machines, direct ",
                    {code, [], [~"gen_statem"]},
                    ~" handling), or you're embedding Asobi in an existing Erlang application."
                ]}
            ]},

            {h2, [], [~"asobi_match \x{2014} the game behaviour"]},
            {p, [], [
                ~"Every game mode is an Erlang module that implements the ",
                {code, [], [~"asobi_match"]},
                ~" behaviour. This is the canonical contract \x{2014} the Lua adapter implements it on your behalf."
            ]},
            example(
                ~"erlang",
                ~"""
-module(my_card_game).
-behaviour(asobi_match).

-export([init/1, join/2, leave/2, handle_input/3, tick/1, get_state/2]).

init(Config) ->
    {ok, #{deck => shuffle(Config), players => #{}, pot => 0}}.

join(PlayerId, #{players := Players} = State) ->
    {ok, State#{players := Players#{PlayerId => starting_hand()}}}.

leave(PlayerId, #{players := Players} = State) ->
    {ok, State#{players := maps:remove(PlayerId, Players)}}.

handle_input(PlayerId, #{action := bet, amount := N}, State) ->
    {ok, place_bet(PlayerId, N, State)}.

tick(State) ->
    case round_complete(State) of
        true  -> {finished, summary(State), State};
        false -> {ok, State}
    end.

get_state(PlayerId, State) ->
    redact_for(PlayerId, State).
"""
            ),

            callback(
                ~"init/1",
                ~"""
-callback init(Config :: map()) -> {ok, GameState :: term()}.
""",
                ~"Called once when the match starts. Receives the config passed to `asobi_match_server:start_link/1`. Returns the initial game state."
            ),
            callback(
                ~"join/2, leave/2",
                ~"""
-callback join(PlayerId :: binary(), GameState :: term()) ->
    {ok, GameState1 :: term()} | {error, Reason :: term()}.

-callback leave(PlayerId :: binary(), GameState :: term()) ->
    {ok, GameState1 :: term()}.
""",
                ~"Player joined or left. `join` may reject with `{error, Reason}` (e.g. match full, banned); `leave` is best-effort and cannot fail."
            ),
            callback(
                ~"handle_input/3",
                ~"""
-callback handle_input(PlayerId :: binary(), Input :: map(), GameState :: term()) ->
    {ok, GameState1 :: term()} | {error, Reason :: term()}.
""",
                ~"Player action (click, move, ability). Inputs arrive asynchronously \x{2014} the match server serialises them onto the match process, so you never race on state."
            ),
            callback(
                ~"tick/1",
                ~"""
-callback tick(GameState :: term()) ->
    {ok, GameState1 :: term()} | {finished, Result :: map(), GameState1 :: term()}.
""",
                ~"Called on a fixed interval (default 10 Hz). Return `{finished, Result, State}` to end the match \x{2014} Asobi persists the result, broadcasts to clients, and tears down the process."
            ),
            callback(
                ~"get_state/2",
                ~"""
-callback get_state(PlayerId :: binary(), GameState :: term()) ->
    StateForPlayer :: map().
""",
                ~"Project the full match state into what ONE player sees. Use this to hide opponent hands, enemy positions outside of sight, etc."
            ),
            callback(
                ~"Optional: phases, voting",
                ~"""
-callback phases(Config :: map()) -> [asobi_phase:phase_def()].
-callback on_phase_started(PhaseName :: binary(), GameState :: term()) ->
    {ok, GameState1 :: term()}.
-callback on_phase_ended(PhaseName :: binary(), GameState :: term()) ->
    {ok, GameState1 :: term()}.
-callback vote_requested(GameState :: term()) ->
    {ok, VoteConfig :: map()} | none.
-callback vote_resolved(Template :: binary(), Result :: map(), GameState :: term()) ->
    {ok, GameState1 :: term()}.
""",
                ~"All optional. Implement `phases/1` to drive a phase state machine; implement the vote callbacks to react to in-match voting."
            ),

            {h2, [], [~"asobi_match_server \x{2014} match lifecycle"]},
            {p, [], [
                ~"Your behaviour module is ",
                {em, [], [~"hosted"]},
                ~" by ",
                {code, [], [~"asobi_match_server"]},
                ~", a ",
                {code, [], [~"gen_statem"]},
                ~" that drives the tick loop and routes player input. You rarely start one directly \x{2014} the matchmaker does that \x{2014} but you can for tests or custom lobbies."
            ]},

            api(
                ~"asobi_match_server:start_link(Config)",
                ~"Start a new match. Config must include `game_module` and may include `tick_rate`, `min_players`, `max_players`, `mode`.",
                ~"erlang",
                ~"""
{ok, Pid} = asobi_match_server:start_link(#{
    game_module => my_card_game,
    tick_rate   => 100,
    min_players => 2,
    max_players => 4,
    mode        => ~"ranked"
}).
"""
            ),
            api(
                ~"asobi_match_server:join/2, :leave/2, :handle_input/3",
                ~"Attach a player, detach, forward input. These are the hot-path calls \x{2014} input is a cast (fire-and-forget), join is a call (awaits accept/reject).",
                ~"erlang",
                ~"""
ok = asobi_match_server:join(Pid, <<"p_alice">>),
asobi_match_server:handle_input(Pid, <<"p_alice">>, #{action => bet, amount => 50}),
asobi_match_server:leave(Pid, <<"p_alice">>).
"""
            ),
            api(
                ~"asobi_match_server:pause/1, :resume/1, :cancel/1",
                ~"Administrative control. `pause` stops the tick and queues input; `resume` continues; `cancel` ends the match without a winner.",
                ~"erlang",
                ~""
            ),
            api(
                ~"asobi_match_server:whereis(MatchId)",
                ~"Locate the Pid for a given match ID. Uses the `pg` scope so this works across cluster nodes.",
                ~"erlang",
                ~"""
case asobi_match_server:whereis(MatchId) of
    {ok, Pid} -> asobi_match_server:handle_input(Pid, PlayerId, Input);
    {error, not_found} -> {error, match_gone}
end.
"""
            ),
            api(
                ~"asobi_match_server:start_vote/2, :cast_vote/4, :use_veto/3",
                ~"In-match voting. `start_vote` opens a ballot; players cast with `cast_vote`; holders of a veto token can cancel with `use_veto`.",
                ~"erlang",
                ~""
            ),

            {h2, [], [~"asobi_matchmaker \x{2014} queues"]},
            {p, [], [
                ~"Pluggable matchmaking. Add a ticket, the matchmaker groups compatible players via a strategy module, and spawns a match when a valid group forms."
            ]},

            api(
                ~"asobi_matchmaker:add(PlayerId, Params)",
                ~"Add a player to the queue. Params include the mode, skill, region, etc.; the strategy module decides how to use them.",
                ~"erlang",
                ~"""
{ok, TicketId} = asobi_matchmaker:add(<<"p_alice">>, #{
    mode => ~"ranked",
    skill => 1250,
    region => eu_west
}).
"""
            ),
            api(
                ~"asobi_matchmaker:remove(PlayerId, TicketId)",
                ~"Cancel a ticket. Safe to call even if already matched \x{2014} it's a cast.",
                ~"erlang",
                ~""
            ),
            api(
                ~"asobi_matchmaker:get_ticket(TicketId)",
                ~"Poll a ticket's status. Returns the full ticket map including `status` (`waiting` / `matched` / `expired`).",
                ~"erlang",
                ~"""
case asobi_matchmaker:get_ticket(TicketId) of
    {ok, #{status := matched, match_id := Id}} -> join_match(Id);
    {ok, #{status := waiting}}                 -> wait();
    {error, not_found}                         -> expired
end.
"""
            ),

            {h2, [], [~"asobi_world_server \x{2014} persistent worlds"]},
            {p, [], [
                ~"For games with a shared, persistent space (MMO, open-world, sandbox). ",
                ~"A world process orchestrates ",
                {em, [], [~"zones"]},
                ~" (spatial partitions) and routes player I/O."
            ]},

            api(
                ~"asobi_world_server:join(Pid, PlayerId)",
                ~"Attach a player to the world. The world picks their initial zone based on spawn rules or a saved position.",
                ~"erlang",
                ~""
            ),
            api(
                ~"asobi_world_server:move_player(Pid, PlayerId, {X, Y})",
                ~"Move a player. The world recomputes zone membership and updates subscriptions.",
                ~"erlang",
                ~"""
asobi_world_server:move_player(WorldPid, PlayerId, {1024, 768}).
"""
            ),
            api(
                ~"asobi_world_server:spawn_at/3, :spawn_at/4",
                ~"Spawn an entity from a template at a position. The optional 4th arg overrides template fields.",
                ~"erlang",
                ~"""
{ok, EntityId} = asobi_world_server:spawn_at(WorldPid,
    <<"goblin_warrior">>,
    {512, 512},
    #{hp => 150}).
"""
            ),

            {h2, [], [~"asobi_zone \x{2014} spatial partitions"]},
            {p, [], [
                ~"A zone is one Erlang process managing a rectangular region of the world. ",
                ~"Zones are lazy-spawned, reaped when empty, and crash-isolated."
            ]},

            api(
                ~"asobi_zone:subscribe(ZonePid, PlayerId)",
                ~"Subscribe a player to a zone's event stream. From now on they receive entity updates and chat from this zone.",
                ~"erlang",
                ~""
            ),
            api(
                ~"asobi_zone:query_radius(ZonePid, {X, Y}, Radius)",
                ~"Return all entities within `Radius` of a point. Uses the zone's internal spatial grid \x{2014} O(k) where k is matches, not total entities.",
                ~"erlang",
                ~"""
{ok, Entities} = asobi_zone:query_radius(ZonePid, {100, 200}, 50).
"""
            ),
            api(
                ~"asobi_zone:spawn_entity/3, :spawn_entity/4",
                ~"Spawn into a specific zone. Usually called via `asobi_world_server:spawn_at/3` which routes to the correct zone for you.",
                ~"erlang",
                ~""
            ),

            {h2, [], [~"asobi_spatial \x{2014} in-memory spatial queries"]},
            {p, [], [
                ~"Stateless helpers for querying a list of entities by position. Use these inside match state when you don't need the zone infrastructure."
            ]},

            api(
                ~"asobi_spatial:query_radius(Entities, {X, Y}, Radius)",
                ~"`Entities` is a map of `#{Id => EntityMap}` where each entity has `x`/`y`. Returns the subset within radius as `[{Id, Entity, Distance}]`.",
                ~"erlang",
                ~"""
Nearby = asobi_spatial:query_radius(Entities, {0, 0}, 100),
lists:foreach(fun({_Id, _E, _Dist}) -> notify(_E) end, Nearby).
"""
            ),
            api(
                ~"asobi_spatial:nearest(Entities, {X, Y}, N)",
                ~"Return the N nearest entities sorted by distance.",
                ~"erlang",
                ~""
            ),
            api(
                ~"asobi_spatial:in_range(A, B, Range) / :distance(A, B)",
                ~"Point-to-point helpers. `distance` is Euclidean; `in_range` avoids a sqrt.",
                ~"erlang",
                ~""
            ),

            {h2, [], [~"Under the hood"]},
            {p, [], [
                ~"The Lua layer (",
                {code, [], [~"asobi_lua"]},
                ~") is a thin adapter: each ",
                {code, [], [~"game.*"]},
                ~" function marshals arguments into BEAM terms and calls the Erlang APIs above. ",
                ~"Everything you can do from Lua you can do from Erlang \x{2014} usually with less marshalling."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua API reference"]},
                    ~" \x{2014} the same surface, for scripted games."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/concepts"}, az_navigate], [~"Core concepts"]},
                    ~" \x{2014} matches, zones, presence, phases, seasons."
                ]},
                {li, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"Source on GitHub"]},
                    ~" \x{2014} full API surface with ",
                    {code, [], [~"-moduledoc"]},
                    ~" and ",
                    {code, [], [~"-doc"]},
                    ~" annotations."
                ]}
            ]}
        ]}
    ).
api(Signature, Desc, Lang, Example) ->
    ?html(
        {'div', [{class, ~"docs-api"}], [
            {h3, [], [{code, [], [Signature]}]},
            {p, [], [Desc]},
            example(Lang, Example)
        ]}
    ).

callback(Name, Spec, Desc) ->
    ?html(
        {'div', [{class, ~"docs-api"}], [
            {h3, [], [{code, [], [Name]}]},
            example(~"erlang", Spec),
            {p, [], [Desc]}
        ]}
    ).

example(_Lang, <<>>) ->
    [];
example(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
