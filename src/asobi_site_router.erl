-module(asobi_site_router).
-behaviour(nova_router).

-export([routes/1]).

-spec routes(atom()) -> [map()].
routes(_Environment) ->
    Layout = {asobi_site_layout, render},
    [
        #{
            prefix => ~"",
            security => false,
            routes => [
                arizona_nova_live:route(~"/", asobi_site_home_view, #{layout => Layout}),
                arizona_nova_live:route(~"/cloud", asobi_site_cloud_view, #{layout => Layout}),
                arizona_nova_live:route(~"/unity", asobi_site_unity_view, #{layout => Layout}),
                arizona_nova_live:route(~"/godot", asobi_site_godot_view, #{layout => Layout}),
                arizona_nova_live:route(~"/defold", asobi_site_defold_view, #{layout => Layout}),
                arizona_nova_live:route(~"/dart", asobi_site_dart_view, #{layout => Layout}),
                arizona_nova_live:route(~"/demo", asobi_site_demo_view, #{layout => Layout}),
                arizona_nova_live:route(~"/docs", asobi_site_docs_view, #{layout => Layout}),
                arizona_nova_live:route(
                    ~"/docs/quickstart", asobi_site_docs_quickstart_view, #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/concepts", asobi_site_docs_concepts_view, #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/self-host", asobi_site_docs_selfhost_view, #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/lua/api", asobi_site_docs_lua_api_view, #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/erlang/api", asobi_site_docs_erlang_api_view, #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/lua/callbacks",
                    asobi_site_docs_lua_callbacks_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/lua/cookbook",
                    asobi_site_docs_lua_cookbook_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/tutorials/tic-tac-toe",
                    asobi_site_docs_tictactoe_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/cloud", asobi_site_docs_cloud_view, #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/authentication",
                    asobi_site_docs_auth_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/protocols/websocket",
                    asobi_site_docs_websocket_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/protocols/rest",
                    asobi_site_docs_rest_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/matchmaking",
                    asobi_site_docs_matchmaking_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/world-server",
                    asobi_site_docs_world_server_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/voting",
                    asobi_site_docs_voting_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/economy",
                    asobi_site_docs_economy_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/leaderboards",
                    asobi_site_docs_leaderboards_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/clustering",
                    asobi_site_docs_clustering_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/configuration",
                    asobi_site_docs_configuration_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/performance",
                    asobi_site_docs_performance_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/docs/lua/bots",
                    asobi_site_docs_lua_bots_view,
                    #{layout => Layout}
                ),
                arizona_nova_live:route(
                    ~"/privacy", asobi_site_privacy_view, #{layout => Layout}
                ),
                arizona_nova_live:route(~"/terms", asobi_site_terms_view, #{layout => Layout}),
                arizona_nova_live:route(~"/dpa", asobi_site_dpa_view, #{layout => Layout}),
                {~"/ws", arizona_nova_ws, #{protocol => ws}},
                {~"/heartbeat", fun asobi_site_controller:heartbeat/1, #{methods => [get]}},
                {"/assets/[...]", "static/assets"}
            ]
        }
    ].
