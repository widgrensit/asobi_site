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
                live(~"/unreal", asobi_site_unreal_view, sdks),
                live(~"/unity", asobi_site_unity_view, sdks),
                live(~"/godot", asobi_site_godot_view, sdks),
                live(~"/defold", asobi_site_defold_view, sdks),
                live(~"/dart", asobi_site_dart_view, sdks),
                live(~"/js", asobi_site_js_view, sdks),
                live(~"/lua", asobi_site_lua_view, sdks),
                live(~"/migrate-from-hathora", asobi_site_migrate_hathora_view, none),
                live(~"/demo", asobi_site_demo_view, demo),
                live(~"/blog", asobi_site_blog_view, blog),
                {~"/blog/rss.xml", fun asobi_site_controller:blog_rss/1, #{methods => [get]}},
                live(~"/blog/:slug", asobi_site_blog_post_view, blog),
                docs(~"/docs", asobi_site_docs_view),
                docs(~"/docs/quickstart", asobi_site_docs_quickstart_view),
                docs(~"/docs/concepts", asobi_site_docs_concepts_view),
                docs(~"/docs/self-host", asobi_site_docs_selfhost_view),
                docs(~"/docs/lua/api", asobi_site_docs_lua_api_view),
                docs(~"/docs/erlang/api", asobi_site_docs_erlang_api_view),
                docs(~"/docs/lua/callbacks", asobi_site_docs_lua_callbacks_view),
                docs(~"/docs/lua/cookbook", asobi_site_docs_lua_cookbook_view),
                docs(~"/docs/tutorials/tic-tac-toe", asobi_site_docs_tictactoe_view),
                docs(~"/docs/cloud", asobi_site_docs_cloud_view),
                docs(~"/docs/authentication", asobi_site_docs_auth_view),
                docs(~"/docs/protocols/websocket", asobi_site_docs_websocket_view),
                docs(~"/docs/protocols/rest", asobi_site_docs_rest_view),
                docs(~"/docs/matchmaking", asobi_site_docs_matchmaking_view),
                docs(~"/docs/world-server", asobi_site_docs_world_server_view),
                docs(~"/docs/voting", asobi_site_docs_voting_view),
                docs(~"/docs/economy", asobi_site_docs_economy_view),
                docs(~"/docs/leaderboards", asobi_site_docs_leaderboards_view),
                docs(~"/docs/clustering", asobi_site_docs_clustering_view),
                docs(~"/docs/configuration", asobi_site_docs_configuration_view),
                docs(~"/docs/performance", asobi_site_docs_performance_view),
                docs(~"/docs/lua/bots", asobi_site_docs_lua_bots_view),
                docs(~"/docs/errors", asobi_site_docs_errors_view),
                docs(~"/docs/security", asobi_site_docs_security_view),
                docs(~"/docs/security/threat-model", asobi_site_docs_security_threat_model_view),
                docs(~"/docs/security/auth", asobi_site_docs_security_auth_view),
                docs(
                    ~"/docs/security/known-limitations",
                    asobi_site_docs_security_known_limits_view
                ),
                docs(~"/docs/security/lua-sandbox", asobi_site_docs_security_lua_sandbox_view),
                docs(~"/docs/security/lua-trust-model", asobi_site_docs_security_lua_trust_view),
                docs(
                    ~"/docs/security/lua-known-limitations",
                    asobi_site_docs_security_lua_known_limits_view
                ),
                docs(~"/docs/quickstart/unity", asobi_site_docs_quickstart_unity_view),
                docs(~"/docs/quickstart/godot", asobi_site_docs_quickstart_godot_view),
                docs(~"/docs/quickstart/defold", asobi_site_docs_quickstart_defold_view),
                docs(~"/docs/tutorials/hot-reload", asobi_site_docs_tutorial_hot_reload_view),
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

docs(Path, DocView) ->
    arizona_nova_live:route(Path, asobi_site_page, #{
        layout => {asobi_site_layout, render},
        bindings => #{
            id => ~"page",
            view => asobi_site_docs_page,
            view_id => ~"docs-page",
            active => docs,
            doc_view => DocView,
            doc_view_id => atom_to_binary(DocView),
            active_path => Path
        }
    }).
