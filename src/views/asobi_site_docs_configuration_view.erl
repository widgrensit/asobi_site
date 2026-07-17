-module(asobi_site_docs_configuration_view).
-include("asobi_site_view.hrl").

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

-spec render(map()) -> asobi_site_html:html().
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

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Do you even need this file? "]},
                    ~"It depends how you run Asobi. On ",
                    {strong, [], [~"Asobi Cloud"]},
                    ~" (",
                    {code, [], [~"asobi deploy"]},
                    ~") and with the ",
                    {strong, [], [~"asobi_lua Docker image"]},
                    ~" (",
                    {code, [], [~"asobi dev"]},
                    ~" / ",
                    {code, [], [~"docker compose up"]},
                    ~") you do not write any config file - the platform owns it, or the container is tuned by the ",
                    {code, [], [~"ASOBI_*"]},
                    ~" environment variables (see ",
                    {a, [{href, ~"#common-env-vars"}], [~"Common env vars"]},
                    ~"). You only edit ",
                    {code, [], [~"sys.config"]},
                    ~" when you ",
                    {a, [{href, ~"/docs/self-host"}, az_navigate], [
                        ~"build the release from source"
                    ]},
                    ~". The blocks below are that file's keys."
                ]}
            ]},

            {h2, [], [~"Where the file lives"]},
            {p, [], [
                ~"In a self-host release the config file is ",
                {code, [], [~"config/sys.config"]},
                ~" in the Asobi source tree (or ",
                {code, [], [~"config/prod_sys.config.src"]},
                ~" when you want env-var templating). ",
                {code, [], [~"rebar3 release"]},
                ~" bakes it into the release at ",
                {code, [], [~"releases/<vsn>/sys.config"]},
                ~", which the BEAM reads at boot. A complete file assembles the blocks documented below:"
            ]},
            code(
                ~"erlang",
                ~"""
%% config/sys.config - a complete self-host example.
[
    {kura, [
        {repo, asobi_repo}, {backend, kura_backend_postgres},
        {host, "localhost"}, {port, 5432}, {database, "asobi"},
        {user, "postgres"}, {password, "postgres"}, {pool_size, 10}
    ]},
    {nova, [
        {cowboy_configuration, #{port => 8084}}
    ]},
    {asobi, [
        {game_dir, "/app/game"},   %% where match.lua / config.lua are read from
        {game_modes, #{
            ~"default" => #{module => {lua, ~"match.lua"}, match_size => 2}
        }},
        {rate_limits, #{
            auth => #{limit => 5,   window => 1000},
            iap  => #{limit => 10,  window => 1000},
            api  => #{limit => 300, window => 1000}
        }}
    ]},
    {asobi_lua, []},
    {kernel, [
        {logger, [
            {handler, default, logger_std_h,
                #{formatter => {nova_jsonlogger_formatter, #{}}}}
        ]}
    ]}
].
"""
            ),

            {h2, [], [~"Database"]},
            code(
                ~"erlang",
                ~"""
{kura, [
    {repo,     asobi_repo},
    {backend,  kura_backend_postgres},
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
                ~"Asobi runs on ",
                {a, [{href, ~"https://github.com/Taure/kura"}], [~"Kura"]},
                ~" 2.x with pluggable backends. Add ",
                {code, [], [~"kura_postgres"]},
                ~" to your ",
                {code, [], [~"rebar.config"]},
                ~" deps and the ",
                {code, [], [~"backend"]},
                ~" key tells Kura which one to use. Swap to ",
                {code, [], [~"kura_backend_sqlite"]},
                ~" for an embedded setup."
            ]},
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
    {cowboy_configuration, #{port => 8084}},
    {plugins, [
        {pre_request, nova_cors_plugin, #{allow_origins => <<"*">>}}
        %% ... other pre/post request plugins
    ]}
]}
"""
            ),

            {h2, [], [~"Game modes (matches and worlds)"]},
            {p, [], [
                ~"All per-mode config - whether a mode is a match or a world, which module implements it, match size, tick rate, bots, spatial config - lives under the single ",
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
    {apple_root_cert_path, ~"/etc/asobi/apple_root_ca.pem"}
]}
"""
            ),

            {h2, [{id, ~"guest-auth"}], [~"Guest (anonymous) auth"]},
            {p, [], [
                ~"Opt-in and fail-closed: ",
                {a, [{href, ~"/docs/authentication#guest-anonymous"}, az_navigate], [
                    ~"guest auth"
                ]},
                ~" stays off until ",
                {code, [], [~"guest_auth"]},
                ~" is true ",
                {em, [], [~"and"]},
                ~" a pepper is configured. Without both, the endpoints return ",
                {code, [], [~"404 guest_auth_disabled"]},
                ~"."
            ]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {guest_auth, true},

    %% Required. A key-id -> pepper map (>= 32 bytes each). Keep old keys for the
    %% guest retention window so existing guests can still resume after rotation.
    {guest_verifier_pepper, #{~"v1" => ~"a-32-byte-or-longer-secret......"}},
    {guest_verifier_key_id, ~"v1"},

    %% Optional abuse control: max unclaimed guests, or `infinity`.
    {guest_unlinked_cap, 100000},

    %% Optional retention. Unset = permanent guests (never reaped). Set to a
    %% number of seconds to delete unclaimed guests older than that.
    {guest_reap_after, 2592000}   %% e.g. 30 days
]}
"""
            ),
            {p, [], [
                ~"The pepper is a server-side secret that makes a stolen database of verifiers useless without it - store it like any other secret (env or secret manager), never in source. ",
                ~"Rotating it means adding a new key id and pointing ",
                {code, [], [~"guest_verifier_key_id"]},
                ~" at it while the old key stays in the map; drop the old key only once no guest can still be resuming with it."
            ]},
            {p, [], [
                ~"Guest creation is additionally bounded by the per-IP auth limiter below and a global create limit."
            ]},

            {h2, [{id, ~"rate-limits"}], [~"Rate limits"]},
            {p, [], [
                ~"Per-route limits enforced by ",
                {code, [], [~"asobi_rate_limit_plugin"]},
                ~". Defaults: 5 req/sec/IP on auth, 10 on IAP, 300 elsewhere. The auth limiter is the brute-force gate - a 5/sec cap plus the bcrypt cost on login makes online password guessing infeasible at internet scale."
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
                ~"Leaderboards are spawned per-board on demand - there is no config map. Start one eagerly with ",
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

            {h2, [{id, ~"common-env-vars"}], [~"Common env vars"]},
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
                    ~" - threat model and the rationale behind the caps above."
                ]}
            ]}
        ]}
    ).
code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
