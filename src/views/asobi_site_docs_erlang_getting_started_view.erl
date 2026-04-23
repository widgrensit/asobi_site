-module(asobi_site_docs_erlang_getting_started_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-erlang-getting-started", title => ~"Erlang quick start"}, Bindings
        ),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Erlang / Quick start"
            ]},
            {h1, [], [~"Your first Erlang match module"]},
            {p, [{class, ~"docs-lede"}], [
                ~"You already write Erlang/OTP and want asobi as a library, not a runtime. ",
                ~"This walks you from ",
                {code, [], [~"rebar3 new app"]},
                ~" to a running match with hot-reload in about 20 minutes."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Prefer Lua? "]},
                    ~"See the ",
                    {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"bilingual quick start"]},
                    ~" \x{2014} it covers the Lua-on-Docker path and the Erlang path ",
                    ~"side-by-side. This page is the longer, Erlang-first tutorial."
                ]}
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Don't want to scaffold by hand? "]},
                    ~"The ",
                    {a,
                        [
                            {href,
                                ~"https://github.com/widgrensit/asobi/tree/main/examples/erlang-match"}
                        ],
                        [
                            {code, [], [~"examples/erlang-match/"]}
                        ]},
                    ~" folder in the asobi repo is this exact project, ready to ",
                    {code, [], [~"git clone && rebar3 shell"]},
                    ~"."
                ]}
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Prerequisites: "]},
                    ~"Erlang/OTP 28+, ",
                    {a, [{href, ~"https://rebar3.org"}], [~"rebar3"]},
                    ~", and Docker for Postgres. No other runtime needed."
                ]}
            ]},

            {h2, [], [~"1. Scaffold the project"]},
            {p, [], [
                ~"Create a new OTP application with rebar3, then add ",
                {code, [], [~"asobi"]},
                ~" as a dependency."
            ]},
            code(
                ~"bash",
                ~"""
rebar3 new app hello_game
cd hello_game
"""
            ),
            {p, [], [
                ~"Edit ",
                {code, [], [~"rebar.config"]},
                ~":"
            ]},
            code(
                ~"erlang",
                ~"""
{erl_opts, [debug_info]}.
{deps, [
    {asobi, "~> 0.25"}
]}.
{shell, [
    {apps, [hello_game]},
    {config, "./config/sys.config"}
]}.
"""
            ),

            {h2, [], [~"2. Implement the match behaviour"]},
            {p, [], [
                ~"Every match mode is a module implementing ",
                {code, [], [~"asobi_match"]},
                ~". Six callbacks: ",
                {code, [], [~"init/1"]},
                ~", ",
                {code, [], [~"join/2"]},
                ~", ",
                {code, [], [~"leave/2"]},
                ~", ",
                {code, [], [~"handle_input/3"]},
                ~", ",
                {code, [], [~"tick/1"]},
                ~", ",
                {code, [], [~"get_state/2"]},
                ~". Here's a complete click-counter:"
            ]},
            code(
                ~"erlang",
                ~"""
%% src/hello_game.erl
-module(hello_game).
-behaviour(asobi_match).

-export([init/1, join/2, leave/2, handle_input/3, tick/1, get_state/2]).

init(_Config) ->
    {ok, #{hits => 0, players => #{}}}.

join(PlayerId, #{players := Players} = State) ->
    {ok, State#{players := Players#{PlayerId => joined}}}.

leave(PlayerId, #{players := Players} = State) ->
    {ok, State#{players := maps:remove(PlayerId, Players)}}.

handle_input(_PlayerId, #{~"action" := ~"click"}, #{hits := H} = State) ->
    NewState = State#{hits := H + 1},
    asobi_match_server:broadcast_event(self(), ~"update", #{hits => H + 1}),
    {ok, NewState};
handle_input(_PlayerId, _Input, State) ->
    {ok, State}.

tick(State) ->
    {ok, State}.

get_state(_PlayerId, #{hits := H}) ->
    #{hits => H}.
"""
            ),
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"About those callbacks. "]},
                    ~"Returns are ",
                    {code, [], [~"{ok, NewState}"]},
                    ~" on success or ",
                    {code, [], [~"{error, Reason}"]},
                    ~" to reject a join/input. ",
                    {code, [], [~"tick/1"]},
                    ~" fires on the match tick cadence (default 20Hz). ",
                    {code, [], [~"get_state/2"]},
                    ~" projects per-player views on demand \x{2014} useful ",
                    ~"for hiding opponent hands in a card game, for example. ",
                    ~"Three more callbacks (",
                    {code, [], [~"phases/1"]},
                    ~", ",
                    {code, [], [~"on_phase_started/2"]},
                    ~", ",
                    {code, [], [~"on_phase_ended/2"]},
                    ~") are optional \x{2014} see the ",
                    {a, [{href, ~"/docs/erlang/api"}, az_navigate], [~"Erlang API reference"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"3. Configure the engine"]},
            {p, [], [
                ~"asobi is hosted by Nova. Create ",
                {code, [], [~"config/sys.config"]},
                ~" to wire Nova \x{2192} kura (Postgres) \x{2192} shigoto ",
                ~"(jobs) \x{2192} asobi and register your game mode:"
            ]},
            code(
                ~"erlang",
                ~"""
%% config/sys.config
[
    {nova, [
        {environment, dev},
        {dev_mode, true},
        {bootstrap_application, asobi},
        {json_lib, json},
        {cowboy_configuration, #{port => 8080}},
        {plugins, [
            {pre_request, nova_request_plugin, #{
                decode_json_body => true,
                parse_qs => true
            }},
            {pre_request, nova_cors_plugin, #{allow_origins => ~"*"}},
            {pre_request, nova_correlation_plugin, #{}}
        ]}
    ]},
    {kura, [
        {repo, asobi_repo},
        {host, "localhost"},
        {port, 5432},
        {database, "hello_game_dev"},
        {user, "postgres"},
        {password, "postgres"},
        {pool_size, 10}
    ]},
    {shigoto, [
        {pool, asobi_repo},
        {poll_interval, 200},
        {queues, [{~"default", 10}]}
    ]},
    {asobi, [
        {game_modes, #{~"hello" => hello_game}},
        {matchmaker, #{tick_interval => 1000, max_wait_seconds => 60}},
        {session, #{token_ttl => 900, refresh_ttl => 2592000}}
    ]},
    {pg, [{scope, [nova_scope, asobi_presence, asobi_chat]}]}
].
"""
            ),
            {p, [], [
                ~"The ",
                {code, [], [~"{bootstrap_application, asobi}"]},
                ~" key tells Nova which app owns the router. Without it the release ",
                ~"dies at boot with ",
                {code, [], [~"{error, no_nova_app_defined}"]},
                ~"."
            ]},

            {h2, [], [~"4. Start Postgres"]},
            code(
                ~"bash",
                ~"""
docker run -d --name hello-pg \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=hello_game_dev \
  -p 5432:5432 postgres:17
"""
            ),

            {h2, [], [~"5. Boot the engine"]},
            code(
                ~"bash",
                ~"""
rebar3 shell
"""
            ),
            {p, [], [
                ~"rebar3 pulls deps, runs kura's migrations against ",
                {code, [], [~"hello_game_dev"]},
                ~", starts supervision, and drops you into an Erlang shell with ",
                {code, [], [~"hello_game"]},
                ~" loaded. You should see ",
                {code, [], [~"Nova application started"]},
                ~" in the logs. The WebSocket + REST endpoint is now live on ",
                {code, [], [~"localhost:8080"]},
                ~"."
            ]},

            {h2, [], [~"6. Verify with curl"]},
            {p, [], [
                ~"Register a player so you have a session token:"
            ]},
            code(
                ~"bash",
                ~"""
curl -s localhost:8080/api/v1/auth/register \
  -H 'content-type: application/json' \
  -d '{"username":"alice","password":"hunter-2026"}' | jq
"""
            ),
            code(
                ~"json",
                ~"""
{
  "player_id": "01HX...",
  "session_token": "eyJ...",
  "username": "alice"
}
"""
            ),
            {p, [], [
                ~"If you see that, auth + database + REST + your match module are all wired up."
            ]},

            {h2, [], [~"7. Play through a WebSocket"]},
            {p, [], [
                ~"Any WebSocket client works. Quick test with ",
                {code, [], [~"wscat"]},
                ~":"
            ]},
            code(
                ~"bash",
                ~"""
npm install -g wscat
wscat -c ws://localhost:8080/ws
> {"type":"session.connect","payload":{"token":"eyJ..."}}
> {"type":"matchmaker.add","payload":{"mode":"hello"}}
# server replies with matchmaker.matched { match_id: "<id>" }
> {"type":"match.join","payload":{"match_id":"<id>"}}
> {"type":"match.input","payload":{"action":"click"}}
"""
            ),
            {p, [], [
                ~"You'll see ",
                {code, [], [~"{\"type\":\"match.state\",\"payload\":{\"hits\":1}}"]},
                ~" \x{2014} every click bumps the counter."
            ]},

            {h2, [], [~"8. Hot-reload your module"]},
            {p, [], [
                ~"Edit ",
                {code, [], [~"src/hello_game.erl"]},
                ~" \x{2014} say, change the broadcast event name from ",
                {code, [], [~"update"]},
                ~" to ",
                {code, [], [~"tick"]},
                ~". Back in the running rebar3 shell:"
            ]},
            code(
                ~"erlang",
                ~"""
1> r3:compile().
%% or, to reload just one module you've already compiled:
1> l(hello_game).
"""
            ),
            {p, [], [
                ~"The running match picks up the new module. Connected players stay connected. ",
                ~"In-flight match processes running the old code continue on the old version until ",
                ~"they finish \x{2014} new matches bind the new code. Same semantics as the Lua path, ",
                ~"same guarantee: ",
                {strong, [], [~"no dropped connections on deploy"]},
                ~". In production, use ",
                {a, [{href, ~"/docs/self-host"}, az_navigate], [~"release upgrades"]},
                ~" for atomic cluster-wide reloads."
            ]},

            {'div', [{class, ~"docs-callout docs-callout-success"}], [
                {p, [], [
                    {strong, [], [~"That's it. "]},
                    ~"You have a live asobi engine running your own match mode, with hot-reload, ",
                    ~"on PostgreSQL, talking WebSocket on port 8080."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/erlang/api"}, az_navigate], [~"Erlang API reference"]},
                    ~" \x{2014} every public module, behaviour, and callback."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/concepts"}, az_navigate], [~"Core concepts"]},
                    ~" \x{2014} matches, worlds, zones, voting, phases."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/matchmaking"}, az_navigate], [~"Matchmaking"]},
                    ~" \x{2014} tickets, strategies (",
                    {code, [], [~"fill"]},
                    ~", ",
                    {code, [], [~"skill_based"]},
                    ~"), and how to write your own ",
                    {code, [], [~"asobi_matchmaker_strategy"]},
                    ~" behaviour."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-host"]},
                    ~" \x{2014} release packaging, clustering, observability."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/tutorials/tic-tac-toe"}, az_navigate], [
                        ~"Tic-tac-toe tutorial"
                    ]},
                    ~" \x{2014} a second, slightly larger example with win detection."
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
