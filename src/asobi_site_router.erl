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
                page(~"/", asobi_site_home_view, home),
                page(~"/cloud", asobi_site_cloud_view, cloud),
                page(~"/unreal", asobi_site_unreal_view, sdks),
                page(~"/unity", asobi_site_unity_view, sdks),
                page(~"/godot", asobi_site_godot_view, sdks),
                page(~"/defold", asobi_site_defold_view, sdks),
                page(~"/dart", asobi_site_dart_view, sdks),
                page(~"/js", asobi_site_js_view, sdks),
                page(~"/lua", asobi_site_lua_view, sdks),
                page(~"/migrate-from-hathora", asobi_site_migrate_hathora_view, none),
                page(~"/demo", asobi_site_demo_view, demo),
                page(~"/blog", asobi_site_blog_view, blog),
                {~"/blog/rss.xml", fun asobi_site_controller:blog_rss/1, #{methods => [get]}},
                page(~"/blog/:slug", asobi_site_blog_post_view, blog),
                docs(~"/docs", asobi_site_docs_view),
                docs(~"/docs/quickstart", asobi_site_docs_quickstart_view),
                docs(~"/docs/samples", asobi_site_docs_samples_view),
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
                docs(~"/docs/quickstart/unreal", asobi_site_docs_quickstart_unreal_view),
                docs(~"/docs/quickstart/js", asobi_site_docs_quickstart_js_view),
                docs(~"/docs/quickstart/dart", asobi_site_docs_quickstart_dart_view),
                docs(~"/docs/quickstart/flame", asobi_site_docs_quickstart_flame_view),
                docs(~"/docs/quickstart/love2d", asobi_site_docs_quickstart_love2d_view),
                docs(~"/docs/tools/cli", asobi_site_docs_tools_cli_view),
                docs(~"/docs/tools/dev", asobi_site_docs_tools_dev_view),
                docs(~"/docs/tools/testing", asobi_site_docs_tools_testing_view),
                docs(~"/docs/faq", asobi_site_docs_faq_view),
                docs(~"/docs/best-practices", asobi_site_docs_best_practices_view),
                docs(~"/docs/changelog", asobi_site_docs_changelog_view),
                docs(~"/docs/tutorials/hot-reload", asobi_site_docs_tutorial_hot_reload_view),
                docs(~"/docs/large-worlds", asobi_site_docs_large_worlds_view),
                docs(~"/docs/comparison", asobi_site_docs_comparison_view),
                docs(~"/docs/glossary", asobi_site_docs_glossary_view),
                docs(~"/docs/architecture", asobi_site_docs_architecture_view),
                docs(~"/docs/benchmarks", asobi_site_docs_benchmarks_view),
                docs(~"/docs/exit", asobi_site_docs_exit_view),
                docs(~"/docs/migrate/nakama", asobi_site_docs_migrate_nakama_view),
                docs(~"/docs/migrate/hathora", asobi_site_docs_migrate_hathora_view),
                docs(~"/docs/migrate/playfab", asobi_site_docs_migrate_playfab_view),
                page(~"/privacy", asobi_site_privacy_view, none),
                page(~"/terms", asobi_site_terms_view, none),
                page(~"/dpa", asobi_site_dpa_view, none),
                {~"/heartbeat", fun asobi_site_controller:heartbeat/1, #{methods => [get]}},
                {"/assets/[...]", "static/assets"}
            ]
        }
    ].

page(Path, View, Active) ->
    {Path, fun(Req) -> asobi_site_controller:page(Req, #{view => View, active => Active}) end, #{
        methods => [get]
    }}.

docs(Path, DocView) ->
    {Path,
        fun(Req) ->
            asobi_site_controller:page(Req, #{
                view => asobi_site_docs_page,
                active => docs,
                doc_view => DocView,
                active_path => Path
            })
        end,
        #{methods => [get]}}.
