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
