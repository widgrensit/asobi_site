-module(asobi_site_docs_configuration_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-configuration", title => ~"Configuration — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
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
    {google_package_name, ~"com.example.game"},
    %% Apple StoreKit 2 receipt verification — root CA used for x5c chain validation.
    %% Defaults to priv/apple_root_ca.pem inside the asobi app.
    {apple_root_ca_path, ~"/etc/asobi/apple_root_ca.pem"}
]}
"""
            ),

            {h2, [], [~"Rate limits"]},
            {p, [], [
                ~"Per-route limits enforced by ",
                {code, [], [~"asobi_rate_limit_plugin"]},
                ~". Defaults: 5 req/sec/IP on auth, 10 on IAP, 300 elsewhere. The auth limiter is the brute-force gate \x{2014} a 5/sec cap plus the bcrypt cost on login makes online password guessing infeasible at internet scale."
            ]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {rate_limits, #{
        auth => #{limit => 5,   window => 1000},
        iap  => #{limit => 10,  window => 1000},
        api  => #{limit => 300, window => 1000}
    }}
]}
"""
            ),
            {p, [], [
                ~"The dev/test sys config bumps all three to 1000 because CT bursts register/login calls against ",
                {code, [], [~"127.0.0.1"]},
                ~"."
            ]},

            {h2, [], [~"World capacity"]},
            {p, [], [
                ~"Caps on persistent worlds (",
                {a, [{href, ~"/docs/world-server"}, az_navigate], [~"world server"]},
                ~"). When a player tries to create a world beyond the per-player cap, the API returns ",
                {code, [], [~"429"]},
                ~"; when the global cap is hit, ",
                {code, [], [~"503"]},
                ~"."
            ]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {world_max_per_player, 5},     %% default 5
    {world_max,            1000}   %% default 1000
]}
"""
            ),

            {h2, [], [~"Terrain provider allowlist (asobi_lua only)"]},
            {p, [], [
                ~"A Lua script returning ",
                {code, [], [~"{ module = \"<some_atom>\", ... }"]},
                ~" from ",
                {code, [], [~"terrain_provider/1"]},
                ~" must name a module on this allowlist. Defaults to the two built-in providers; widen explicitly if you ship a custom one."
            ]},
            code(
                ~"erlang",
                ~"""
{asobi_lua, [
    {terrain_providers, [asobi_terrain_flat, asobi_terrain_perlin]}
]}
"""
            ),

            {h2, [], [~"Per-call upper bounds"]},
            {p, [], [
                ~"These limits exist to bound the cost of a single hostile request and are not currently runtime-tunable. See the ",
                {a, [{href, ~"/docs/security/auth"}, az_navigate], [
                    ~"security guide"
                ]},
                ~" for the rationale."
            ]},
            {pre, [], [
                {code, [], [
                    ~"""
 Endpoint / surface          | Limit
-----------------------------|------------------------------------------------
 Cloud save body             | 256 KB
 Cloud save slots / player   | 10
 Inventory consume quantity  | 1 .. 1_000_000
 Leaderboard top ?limit      | 1 .. 100
 Leaderboard around ?range   | 1 .. 50
 Chat history ?limit         | 1 .. 200
 DM content                  | 2000 bytes
 WS chat channels / conn     | 32
 Idle channel timeout        | 60 s
 Lua decode depth            | 64 levels
"""
                ]}
            ]},

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
                {li, [], [{a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-host"]}]},
                {li, [], [{a, [{href, ~"/docs/clustering"}, az_navigate], [~"Clustering"]}]},
                {li, [], [
                    {a, [{href, ~"/docs/performance"}, az_navigate], [~"Performance tuning"]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/security"}, az_navigate], [~"Security"]},
                    ~" \x{2014} threat model and the rationale behind the caps above."
                ]}
            ]}
        ]}
    ).
code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
