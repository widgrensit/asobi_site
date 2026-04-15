-module(asobi_site_docs_configuration_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-configuration", title => ~"Configuration — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(_Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
                ~" / Configuration"
            ]},
            {h1, [], [~"Configuration reference"]},
            {p, [{class, ~"docs-lede"}], [
                ~"All Asobi config lives under the ",
                {code, [], [~"asobi"]},
                ~" OTP application. Set it via ",
                {code, [], [~"sys.config"]},
                ~" (releases), ",
                {code, [], [~"config.exs"]},
                ~"/",
                {code, [], [~"sys.config.src"]},
                ~" (env-var templating), or ",
                {code, [], [~"application:set_env/3"]},
                ~" at runtime."
            ]},

            {h2, [], [~"Database"]},
            code(
                ~"erlang",
                ~"""
{asobi_repo, [
    {database, <<"asobi">>},
    {username, <<"postgres">>},
    {password, <<"postgres">>},
    {host,     <<"localhost">>},
    {port,     5432},
    {pool_size, 10}
]}
"""
            ),
            {p, [], [
                ~"Environment variables: ",
                {code, [], [~"ASOBI_DB_HOST"]},
                ~", ",
                {code, [], [~"ASOBI_DB_PORT"]},
                ~", ",
                {code, [], [~"ASOBI_DB_NAME"]},
                ~", ",
                {code, [], [~"ASOBI_DB_USER"]},
                ~", ",
                {code, [], [~"ASOBI_DB_PASSWORD"]},
                ~"."
            ]},

            {h2, [], [~"HTTP / WebSocket"]},
            code(
                ~"erlang",
                ~"""
{nova, [
    {cowboy_options, [{port, 8080}, {max_connections, 10000}]}
]}
"""
            ),

            {h2, [], [~"Matches"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {match_defaults, #{
        tick_rate_ms => 100,
        min_players  => 2,
        max_players  => 10,
        waiting_timeout_ms => 60000
    }},
    {match_modes, #{
        <<"arena">>  => #{callback_module => arena_game,  tick_rate_ms => 50},
        <<"ranked">> => #{callback_module => ranked_game, tick_rate_ms => 100}
    }}
]}
"""
            ),

            {h2, [], [~"Matchmaker"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {matchmaker, #{
        tick_interval    => 1000,
        max_wait_seconds => 60
    }},
    {matchmaker_strategy, asobi_matchmaker_fill}
]}
"""
            ),

            {h2, [], [~"World server"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {world, #{
        zone_size            => 256,      %% units per side
        tick_rate_ms         => 50,       %% 20 Hz
        lazy_zones           => true,
        zone_idle_ms         => 60000,
        terrain_provider     => my_terrain_module,
        snapshot_interval_ms => 30000
    }}
]}
"""
            ),

            {h2, [], [~"Voting"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {vote_templates, #{
        <<"default">>   => #{method => <<"plurality">>, window_ms => 15000,
                             visibility => <<"live">>},
        <<"boon_pick">> => #{method => <<"plurality">>, window_ms => 15000}
    }}
]}
"""
            ),

            {h2, [], [~"Authentication"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {oidc_providers, #{
        google    => #{issuer => <<"https://accounts.google.com">>,
                       client_id => <<"...">>, client_secret => <<"...">>},
        apple     => #{issuer => <<"https://appleid.apple.com">>,
                       client_id => <<"...">>, client_secret => <<"...">>}
    }},
    {steam_api_key, <<"...">>},
    {steam_app_id,  <<"...">>},
    {apple_bundle_id, <<"com.example.game">>},
    {session_token_ttl_seconds, 2592000}   %% 30 days
]}
"""
            ),

            {h2, [], [~"Leaderboards"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {leaderboards, #{
        <<"arena:weekly">> => #{mode => monotonic,
                                window => {weekly, monday, 0}},
        <<"xp:lifetime">>  => #{mode => cumulative}
    }}
]}
"""
            ),

            {h2, [], [~"Lua runtime"]},
            code(
                ~"erlang",
                ~"""
{asobi_lua, [
    {bundle_dir,  <<"./game">>},
    {hot_reload,  true},
    {sandbox,     strict},             %% strict | permissive
    {instruction_limit, 1000000}       %% per-callback bytecode cap
]}
"""
            ),

            {h2, [], [~"Clustering"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {cluster, #{
        strategy => k8s_dns,
        service  => <<"asobi-headless">>,
        basename => <<"asobi">>
    }}
]}
"""
            ),

            {h2, [], [~"Telemetry & logs"]},
            code(
                ~"erlang",
                ~"""
{kernel, [
    {logger, [
        {handler, default, logger_std_h, #{
            level => info,
            formatter => {nova_jsonlogger_formatter, #{}}
        }}
    ]}
]}
"""
            ),

            {h2, [], [~"Common env vars"]},
            {pre, [], [
                {code, [], [
                    ~"""
 ASOBI_DB_*           Postgres connection (HOST/PORT/NAME/USER/PASSWORD)
 ASOBI_CLUSTER_SEEDS  Comma-separated node names to ping on boot
 ERLANG_COOKIE        Distribution cookie (required for clustering)
 NODE_NAME            Full node name, e.g. asobi@10.0.0.1
 PORT                 HTTP listen port (default 8080)
 ASOBI_BUNDLE_DIR     Where asobi_lua looks for game/*.lua
"""
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/docs/self-host"}], [~"Self-host"]}]},
                {li, [], [{a, [{href, ~"/docs/clustering"}], [~"Clustering"]}]},
                {li, [], [{a, [{href, ~"/docs/performance"}], [~"Performance tuning"]}]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(~"/docs/configuration", Content).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
