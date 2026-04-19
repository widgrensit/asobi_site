-module(asobi_site_router).
-behaviour(nova_router).

-export([routes/1]).

-spec routes(atom()) -> [map()].
routes(_Environment) ->
    [
        #{
            prefix => ~"",
            security => false,
            routes => [
                live(~"/", asobi_site_home_view),
                live(~"/cloud", asobi_site_cloud_view),
                live(~"/unity", asobi_site_unity_view),
                live(~"/godot", asobi_site_godot_view),
                live(~"/defold", asobi_site_defold_view),
                live(~"/dart", asobi_site_dart_view),
                live(~"/demo", asobi_site_demo_view),
                live(~"/blog", asobi_site_blog_view),
                {~"/blog/rss.xml", fun asobi_site_controller:blog_rss/1, #{methods => [get]}},
                live(~"/blog/:slug", asobi_site_blog_post_view),
                live(~"/docs", asobi_site_docs_view),
                live(~"/docs/quickstart", asobi_site_docs_quickstart_view),
                live(~"/docs/concepts", asobi_site_docs_concepts_view),
                live(~"/docs/self-host", asobi_site_docs_selfhost_view),
                live(~"/docs/lua/api", asobi_site_docs_lua_api_view),
                live(~"/docs/erlang/api", asobi_site_docs_erlang_api_view),
                live(~"/docs/lua/callbacks", asobi_site_docs_lua_callbacks_view),
                live(~"/docs/lua/cookbook", asobi_site_docs_lua_cookbook_view),
                live(~"/docs/tutorials/tic-tac-toe", asobi_site_docs_tictactoe_view),
                live(~"/docs/cloud", asobi_site_docs_cloud_view),
                live(~"/docs/authentication", asobi_site_docs_auth_view),
                live(~"/docs/protocols/websocket", asobi_site_docs_websocket_view),
                live(~"/docs/protocols/rest", asobi_site_docs_rest_view),
                live(~"/docs/matchmaking", asobi_site_docs_matchmaking_view),
                live(~"/docs/world-server", asobi_site_docs_world_server_view),
                live(~"/docs/voting", asobi_site_docs_voting_view),
                live(~"/docs/economy", asobi_site_docs_economy_view),
                live(~"/docs/leaderboards", asobi_site_docs_leaderboards_view),
                live(~"/docs/clustering", asobi_site_docs_clustering_view),
                live(~"/docs/configuration", asobi_site_docs_configuration_view),
                live(~"/docs/performance", asobi_site_docs_performance_view),
                live(~"/docs/lua/bots", asobi_site_docs_lua_bots_view),
                live(~"/privacy", asobi_site_privacy_view),
                live(~"/terms", asobi_site_terms_view),
                live(~"/dpa", asobi_site_dpa_view),
                {~"/ws", arizona_nova_ws, #{protocol => ws}},
                {~"/heartbeat", fun asobi_site_controller:heartbeat/1, #{methods => [get]}},
                {"/assets/[...]", "static/assets"}
            ]
        }
    ].

live(Path, View) ->
    arizona_nova_live:route(Path, View, #{layout => {asobi_site_layout, render}}).
