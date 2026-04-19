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
                live(~"/", asobi_site_home_view, home),
                live(~"/cloud", asobi_site_cloud_view, cloud),
                live(~"/unity", asobi_site_unity_view, sdks),
                live(~"/godot", asobi_site_godot_view, sdks),
                live(~"/defold", asobi_site_defold_view, sdks),
                live(~"/dart", asobi_site_dart_view, sdks),
                live(~"/demo", asobi_site_demo_view, demo),
                live(~"/blog", asobi_site_blog_view, blog),
                {~"/blog/rss.xml", fun asobi_site_controller:blog_rss/1, #{methods => [get]}},
                live(~"/blog/:slug", asobi_site_blog_post_view, blog),
                live(~"/docs", asobi_site_docs_view, docs),
                live(~"/docs/quickstart", asobi_site_docs_quickstart_view, docs),
                live(~"/docs/concepts", asobi_site_docs_concepts_view, docs),
                live(~"/docs/self-host", asobi_site_docs_selfhost_view, docs),
                live(~"/docs/lua/api", asobi_site_docs_lua_api_view, docs),
                live(~"/docs/erlang/api", asobi_site_docs_erlang_api_view, docs),
                live(~"/docs/lua/callbacks", asobi_site_docs_lua_callbacks_view, docs),
                live(~"/docs/lua/cookbook", asobi_site_docs_lua_cookbook_view, docs),
                live(~"/docs/tutorials/tic-tac-toe", asobi_site_docs_tictactoe_view, docs),
                live(~"/docs/cloud", asobi_site_docs_cloud_view, docs),
                live(~"/docs/authentication", asobi_site_docs_auth_view, docs),
                live(~"/docs/protocols/websocket", asobi_site_docs_websocket_view, docs),
                live(~"/docs/protocols/rest", asobi_site_docs_rest_view, docs),
                live(~"/docs/matchmaking", asobi_site_docs_matchmaking_view, docs),
                live(~"/docs/world-server", asobi_site_docs_world_server_view, docs),
                live(~"/docs/voting", asobi_site_docs_voting_view, docs),
                live(~"/docs/economy", asobi_site_docs_economy_view, docs),
                live(~"/docs/leaderboards", asobi_site_docs_leaderboards_view, docs),
                live(~"/docs/clustering", asobi_site_docs_clustering_view, docs),
                live(~"/docs/configuration", asobi_site_docs_configuration_view, docs),
                live(~"/docs/performance", asobi_site_docs_performance_view, docs),
                live(~"/docs/lua/bots", asobi_site_docs_lua_bots_view, docs),
                live(~"/privacy", asobi_site_privacy_view, none),
                live(~"/terms", asobi_site_terms_view, none),
                live(~"/dpa", asobi_site_dpa_view, none),
                {~"/ws", arizona_nova_ws, #{protocol => ws}},
                {~"/heartbeat", fun asobi_site_controller:heartbeat/1, #{methods => [get]}},
                {"/assets/[...]", "static/assets"}
            ]
        }
    ].

live(Path, View, Active) ->
    arizona_nova_live:route(Path, asobi_site_page, #{
        layout => {asobi_site_layout, render},
        bindings => #{
            id => ~"page",
            view => View,
            view_id => atom_to_binary(View),
            active => Active
        }
    }).
