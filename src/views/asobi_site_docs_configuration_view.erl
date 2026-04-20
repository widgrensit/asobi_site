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
{kura, [
    {repo,     asobi_repo},
    {host,     "localhost"},
    {port,     5432},
    {database, "asobi"},
    {user,     "postgres"},
    {password, "postgres"},
    {pool_size, 10}
]}
"""
            ),
            {p, [], [
                ~"Environment variables (consumed via ",
                {code, [], [~"sys.config.src"]},
                ~"): ",
                {code, [], [~"ASOBI_DB_HOST"]},
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
    {cowboy_configuration, #{port => 8080}},
    {plugins, [
        {pre_request, nova_cors_plugin, #{allow_origins => <<"*">>}}
        %% ... other pre/post request plugins
    ]}
]}
"""
            ),

            {h2, [], [~"Game modes (matches and worlds)"]},
            {p, [], [
                ~"All per-mode config \x{2014} whether a mode is a match or a world, which module implements it, match size, tick rate, bots, spatial config \x{2014} lives under the single ",
                {code, [], [~"game_modes"]},
                ~" map."
            ]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {game_modes, #{
        ~"arena" => #{
            module      => arena_game,
            match_size  => 4,
            max_players => 4,
            tick_rate   => 50,          %% ms per tick (default 100)
            strategy    => fill,        %% fill | skill_based | module()
            bots        => #{enabled => true, min_players => 4,
                             script => ~"bots/arena.lua"}
        },
        ~"world1" => #{
            type         => world,
            module       => {lua, ~"world1/match.lua"},
            grid_size    => 10,
            zone_size    => 200,
            view_radius  => 1,
            tick_rate    => 50,
            persistent   => false,
            lazy_zones   => true,
            zone_idle_timeout => 30000,
            max_active_zones  => 10000
        }
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
    }}
    %% Strategy is per-mode — see the `strategy` key under game_modes.
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
    {base_url, ~"https://api.example.com"},   %% used for OIDC redirects
    {oidc_providers, #{
        google => #{issuer => ~"https://accounts.google.com",
                    client_id => ~"...", client_secret => ~"..."},
        apple  => #{issuer => ~"https://appleid.apple.com",
                    client_id => ~"...", client_secret => ~"..."}
    }},
    {steam_api_key, ~"..."},
    {steam_app_id,  ~"..."},
    {apple_bundle_id,    ~"com.example.game"},
    {google_package_name, ~"com.example.game"}
]}
"""
            ),

            {h2, [], [~"Leaderboards"]},
            {p, [], [
                ~"Leaderboards are spawned per-board on demand \x{2014} there is no config map. Start one eagerly with ",
                {code, [], [~"asobi_leaderboard_sup:start_board/1"]},
                ~", or just call ",
                {code, [], [~"asobi_leaderboard_server:submit/3"]},
                ~" and the first hit will spawn it."
            ]},

            {h2, [], [~"Lua runtime"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {game_dir, "/app/game"}   %% where asobi_lua_config looks for match.lua / config.lua
]},
{asobi_lua, []}
"""
            ),

            {h2, [], [~"Clustering"]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {cluster, #{
        strategy       => dns,               %% dns | epmd
        dns_name       => ~"asobi-headless", %% DNS A record (for `dns`)
        hosts          => [],                %% list of hosts (for `epmd`)
        poll_interval  => 10000              %% ms between discovery polls
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
            {p, [], [
                ~"These are the variables consumed by the published ",
                {code, [], [~"asobi_lua"]},
                ~" image's ",
                {code, [], [~"sys.config.src"]},
                ~":"
            ]},
            {pre, [], [
                {code, [], [
                    ~"""
 ASOBI_PORT           HTTP/WebSocket listen port (required)
 ASOBI_DB_HOST        Postgres host
 ASOBI_DB_NAME        Postgres database name
 ASOBI_DB_USER        Postgres user
 ASOBI_DB_PASSWORD    Postgres password
 ASOBI_CORS_ORIGINS   Comma-separated allowed origins for CORS
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
