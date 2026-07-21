-module(asobi_site_docs_learn_bundle_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{
                id => ~"docs-learn-bundle",
                title => ~"Your backend bundle and folder layout - Asobi docs"
            },
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
                ~" / Learn / Your backend bundle"
            ]},
            {h1, [], [~"Your backend bundle and folder layout"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Understand what you actually ship to Asobi, scaffold it, and boot it locally so the server answers on your machine."
            ]},

            {p, [], [
                ~"You will not write a server. Asobi is the server. What you push is a ",
                {strong, [], [~"Lua bundle"]},
                ~": a small directory of game scripts that Asobi loads and runs. The bundle holds your rules; the platform supplies the database, authentication, matchmaking, and WebSockets around it."
            ]},
            {p, [], [
                ~"This is the server-authoritative half of the arena backend from ",
                {a, [{href, ~"/docs/learn/orientation"}, az_navigate], [~"Orientation"]},
                ~": the client will send intent, but your fighter only moves because a script in this bundle decides it moves."
            ]},

            {h2, [], [~"What is in the bundle"]},
            {p, [], [
                ~"A bundle is one folder. The simplest one has a single mode and looks like this:"
            ]},
            code(
                ~"text",
                ~"""
                my_arena/
                ├── lua/
                │   └── match.lua
                └── docker-compose.yml
                """
            ),
            {p, [], [
                {code, [], [~"lua/"]},
                ~" is the only part Asobi cares about. It is mounted into the runtime and becomes the search path for every callback and every ",
                {code, [], [~"require()"]},
                ~". The container is stateless apart from this folder."
            ]},
            {table, [], [
                {thead, [], [
                    {tr, [], [
                        {th, [], [~"File"]},
                        {th, [], [~"Role"]}
                    ]}
                ]},
                {tbody, [], [
                    {tr, [], [
                        {td, [], [{code, [], [~"lua/match.lua"]}]},
                        {td, [], [
                            ~"One game mode. Config globals at the top, then the callbacks Asobi calls (",
                            {code, [], [~"init"]},
                            ~", ",
                            {code, [], [~"join"]},
                            ~", ",
                            {code, [], [~"leave"]},
                            ~", ",
                            {code, [], [~"handle_input"]},
                            ~", ",
                            {code, [], [~"tick"]},
                            ~", ",
                            {code, [], [~"get_state"]},
                            ~"). With no ",
                            {code, [], [~"config.lua"]},
                            ~", this single file loads as the ",
                            {code, [], [~"\"default\""]},
                            ~" mode."
                        ]}
                    ]},
                    {tr, [], [
                        {td, [], [{code, [], [~"lua/config.lua"]}]},
                        {td, [], [
                            ~"Optional multi-mode manifest. Returns a table mapping mode names to match-script paths. When it exists, Asobi reads it ",
                            {strong, [], [~"instead of"]},
                            ~" a top-level ",
                            {code, [], [~"match.lua"]},
                            ~". Deployment-wide globals such as ",
                            {code, [], [~"guest_auth"]},
                            ~" live here, not in the per-mode scripts."
                        ]}
                    ]},
                    {tr, [], [
                        {td, [], [{code, [], [~"lua/world.lua"]}]},
                        {td, [], [
                            ~"A mode script for a persistent, zoned world instead of an ephemeral match. Same file role as ",
                            {code, [], [~"match.lua"]},
                            ~", but it sets the global ",
                            {code, [], [~"game_type = \"world\""]},
                            ~" and uses world callbacks."
                        ]}
                    ]},
                    {tr, [], [
                        {td, [], [{code, [], [~"lua/bots/*.lua"]}]},
                        {td, [], [
                            ~"Optional bot scripts, referenced from a mode's ",
                            {code, [], [~"bots = { script = \"bots/...\" }"]},
                            ~" global."
                        ]}
                    ]},
                    {tr, [], [
                        {td, [], [
                            ~"other ",
                            {code, [], [~".lua"]},
                            ~" files"
                        ]},
                        {td, [], [
                            ~"Shared modules you ",
                            {code, [], [~"require()"]},
                            ~", resolved relative to ",
                            {code, [], [~"lua/"]},
                            ~"."
                        ]}
                    ]}
                ]}
            ]},
            {p, [], [
                ~"There is no separate \"assets\" or static-file slot in the bundle: everything under ",
                {code, [], [~"lua/"]},
                ~" is code that Asobi executes or ",
                {code, [], [~"require()"]},
                ~"s. Static art and audio live with your client, not the backend."
            ]},
            {p, [], [~"Config is data at the top of a mode script, not a config file:"]},
            code(
                ~"lua",
                ~"""
                -- lua/match.lua
                match_size = 2
                max_players = 8
                """
            ),
            {p, [], [
                ~"For a single-mode game those globals sit in ",
                {code, [], [~"match.lua"]},
                ~". For a multi-mode game they sit in each mode's script, while deployment-wide settings move to ",
                {code, [], [~"config.lua"]},
                ~". The full list of globals and every callback signature are in the ",
                {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"Lua scripting guide"]},
                ~" and ",
                {a, [{href, ~"/docs/configuration"}, az_navigate], [~"Configuration"]},
                ~"; this track links into them rather than repeating them."
            ]},
            {p, [], [~"Multi-mode is just more of the same shape:"]},
            code(
                ~"text",
                ~"""
                my_arena/
                ├── lua/
                │   ├── config.lua
                │   ├── arena/
                │   │   └── match.lua
                │   └── world/
                │       └── match.lua
                └── docker-compose.yml
                """
            ),
            code(
                ~"lua",
                ~"""
                -- lua/config.lua
                return {
                  arena = "arena/match.lua",
                  world = "world/match.lua"
                }
                """
            ),
            {p, [], [
                ~"We start single-mode. You add ",
                {code, [], [~"config.lua"]},
                ~" later, in ",
                {a, [{href, ~"/docs/learn/match-setup"}, az_navigate], [
                    ~"Set up a match and modes"
                ]},
                ~", without moving any game logic."
            ]},

            {h2, [], [~"Scaffold it"]},
            code(
                ~"bash",
                ~"""
                asobi init my_arena
                cd my_arena
                """
            ),
            {p, [], [
                ~"This scaffolds a minimal bundle - ",
                {code, [], [~"lua/match.lua"]},
                ~" plus a ",
                {code, [], [~"README.md"]},
                ~" - that you can boot straight away."
            ]},

            {h2, [], [~"Run it locally"]},
            code(~"bash", ~"asobi dev\n"),
            {p, [], [
                {code, [], [~"asobi dev"]},
                ~" starts the server against a local Postgres and mounts your ",
                {code, [], [~"lua/"]},
                ~" folder live: edit a script, save, and the running server picks it up between ticks. It listens on port ",
                {strong, [], [~"8084"]},
                ~" for both HTTP and WebSocket."
            ]},
            {p, [], [
                ~"Under the bonnet that is nothing more than the ",
                {code, [], [~"asobi_lua"]},
                ~" image next to a Postgres, so if you would rather run it by hand, the same thing in ",
                {code, [], [~"docker-compose.yml"]},
                ~" is:"
            ]},
            code(
                ~"text",
                ~"""
                services:
                  postgres:
                    image: postgres:17
                    environment: { POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres, POSTGRES_DB: my_arena }
                    healthcheck: { test: ["CMD-SHELL", "pg_isready -U postgres"], interval: 5s }

                  asobi:
                    image: ghcr.io/widgrensit/asobi_lua:latest
                    depends_on: { postgres: { condition: service_healthy } }
                    ports: ["8084:8084"]
                    volumes: ["./lua:/app/game:ro"]
                    environment: { ASOBI_DB_HOST: postgres, ASOBI_DB_NAME: my_arena }
                """
            ),
            code(~"bash", ~"docker compose up -d\n"),
            {p, [], [
                ~"Either way you now have the same server your players will hit, running on your machine. Migrations run on first boot; there is nothing to set up in Postgres by hand."
            ]},

            {h2, [], [~"Deploy later (aside)"]},
            {p, [], [
                ~"You do not deploy anything yet. When you do, ",
                {strong, [], [~"the bundle is identical on both paths"]},
                ~" and so is every client call except the base URL. Only where it runs, and where its secrets and database come from, differs:"
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Cloud"]},
                    ~" (or push from ",
                    {a, [{href, ~"https://console.asobi.dev"}], [~"console.asobi.dev"]},
                    ~"): you upload the same ",
                    {code, [], [~"lua/"]},
                    ~" folder. The command names the target environment and the bundle directory:",
                    code(~"bash", ~"asobi deploy prod lua\n"),
                    {p, [], [
                        ~"The per-project Postgres and the guest-auth pepper are provisioned per environment automatically; you never touch a database or a secret. You write no config file at all."
                    ]}
                ]},
                {li, [], [
                    {strong, [], [~"Self-hosted"]},
                    ~" (your own release of ",
                    {code, [], [~"asobi"]},
                    ~" + ",
                    {code, [], [~"asobi_lua"]},
                    ~", your own Postgres): you run the ",
                    {code, [], [~"asobi_lua"]},
                    ~" image (or embed asobi as an Erlang dependency), point it at your Postgres, and set the ",
                    {code, [], [~"ASOBI_*"]},
                    ~" environment variables yourself. Guest auth additionally needs you to supply the pepper via ",
                    {code, [], [~"ASOBI_GUEST_VERIFIER_PEPPER"]},
                    ~". See ",
                    {a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-hosting"]},
                    ~" and ",
                    {a, [{href, ~"/docs/configuration"}, az_navigate], [~"Configuration"]},
                    ~"."
                ]}
            ]},

            checkpoint([
                {p, [], [
                    ~"Boot the server, then prove it answers. With ",
                    {code, [], [~"asobi dev"]},
                    ~" (or ",
                    {code, [], [~"docker compose up -d"]},
                    ~") running:"
                ]},
                code(
                    ~"bash",
                    ~"""
                    curl -s localhost:8084/api/v1/auth/register \
                      -H 'content-type: application/json' \
                      -d '{"username":"alice","password":"hunter2!"}'
                    """
                ),
                {p, [], [
                    ~"You should get JSON back with a ",
                    {code, [], [~"player_id"]},
                    ~":"
                ]},
                code(
                    ~"json",
                    ~"""
                    { "username": "alice", "player_id": "019de3...", ... }
                    """
                ),
                {p, [], [
                    ~"A ",
                    {code, [], [~"player_id"]},
                    ~" in the response means the bundle loaded, the database is wired up, and the server is reachable on your machine. That is the whole step."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/install-sdk",
                ~"Step 2 - Install the client SDK",
                ~"Learn how and when it talks to the server."
            )
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).

checkpoint(Children) ->
    ?html(
        {'div', [{class, ~"docs-callout docs-callout-success"}], [
            {p, [], [{strong, [], [~"Checkpoint"]}]} | Children
        ]}
    ).

nextstep(Href, Label, Blurb) ->
    ?html(
        {'div', [{class, ~"docs-next"}], [
            {p, [], [
                {strong, [], [~"Next: "]},
                {a, [{href, Href}, az_navigate], [Label]}
            ]},
            {p, [], [Blurb]}
        ]}
    ).
