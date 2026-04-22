-module(asobi_site_migrate_hathora_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"migrate-hathora"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Migrate from Hathora to Asobi"]},
                    {p, [], [
                        ~"Hathora shuts down 2026-05-05. Asobi is the Apache-2, ",
                        ~"self-hostable backend you move to once, then never again."
                    ]},
                    {a,
                        [
                            {href,
                                ~"https://github.com/widgrensit/asobi/blob/main/guides/migrate-from-hathora.md"},
                            {class, ~"guide-github"}
                        ],
                        [~"Read the full migration guide"]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Why you're here"]},
                    {p, [], [
                        ~"In February 2026 Hathora announced a pivot to AI ",
                        ~"infrastructure and set a shutdown date for the game-hosting ",
                        ~"product. If you have a live game on hathora.dev or ",
                        ~"hathora.cloud, you need a new backend by May — and you ",
                        ~"probably don't want the next one to disappear the same way."
                    ]},
                    {p, [], [
                        ~"Asobi is built for that. Apache-2.0 licensed, ",
                        ~"self-hostable, Postgres-backed, single Docker container. ",
                        ~"If we ever pivot, your game keeps running — the code is ",
                        ~"yours forever."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Hathora → Asobi at a glance"]},
                    {'div', [{class, ~"comparison-table-wrap"}], [
                        {table, [{class, ~"comparison-table"}], [
                            {thead, [], [
                                {tr, [], [
                                    {th, [], [~"Capability"]},
                                    {th, [], [~"Hathora"]},
                                    {th, [{class, ~"highlight"}], [~"Asobi"]}
                                ]}
                            ]},
                            {tbody, [], [
                                ?each(
                                    fun({Cap, Hath, Aso}) ->
                                        {tr, [], [
                                            {td, [{class, ~"row-label"}], [Cap]},
                                            {td, [], [Hath]},
                                            {td, [{class, ~"highlight"}], [Aso]}
                                        ]}
                                    end,
                                    [
                                        {
                                            ~"License",
                                            ~"Proprietary managed service",
                                            ~"Apache-2.0, self-hostable"
                                        },
                                        {
                                            ~"Rooms / matches",
                                            ~"One container per room",
                                            ~"Thousands of matches per container (BEAM processes)"
                                        },
                                        {
                                            ~"Matchmaker",
                                            ~"Matchmaker 2.0",
                                            ~"Pluggable strategies (fill, skill-based, custom)"
                                        },
                                        {
                                            ~"Lobbies",
                                            ~"Public / private lobbies",
                                            ~"Ticket-based + matches in \"waiting\" phase"
                                        },
                                        {
                                            ~"Auth",
                                            ~"Anonymous, Google, Discord, SIWE",
                                            ~"Username/password, OAuth/OIDC, JWT sessions"
                                        },
                                        {
                                            ~"Leaderboards",
                                            ~"Not built-in",
                                            ~"Built-in, scoped per board"
                                        },
                                        {
                                            ~"Economy / inventory",
                                            ~"Not built-in",
                                            ~"Built-in (wallets, items, IAP receipts)"
                                        },
                                        {
                                            ~"Chat",
                                            ~"Not built-in",
                                            ~"Built-in, per-channel pub/sub"
                                        },
                                        {
                                            ~"Per-match dedicated UDP",
                                            ~"Yes",
                                            ~"No — WebSocket/TCP only. Pair with a UDP relay if sub-3ms physics matter."
                                        },
                                        {
                                            ~"Region ping / autoplacement",
                                            ~"Yes",
                                            ~"No — deploy one container per region, pick client-side."
                                        },
                                        {
                                            ~"Pricing",
                                            ~"CCU-based + compute",
                                            ~"Flat per-container (Cloud) or free (self-host)"
                                        },
                                        {
                                            ~"Hot reload",
                                            ~"No",
                                            ~"Edit Lua, save, running matches pick it up"
                                        }
                                    ]
                                )
                            ]}
                        ]}
                    ]},
                    {p, [], [
                        ~"We're honest about the UDP gap: if you run a twitch-FPS ",
                        ~"with per-match dedicated servers, Asobi alone isn't a ",
                        ~"drop-in. Most Hathora games on turn-based, MMO, co-op, or ",
                        ~"casual loops migrate cleanly."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Migration in four steps"]},
                    {p, [], [
                        ~"The full guide on GitHub covers endpoint-by-endpoint ",
                        ~"mapping, WebSocket handshake, and a before/after of a ",
                        ~"typical Hathora client. The short version:"
                    ]},
                    {ol, [], [
                        {li, [], [
                            ~"Your existing game-server process keeps running. ",
                            ~"Bring up an asobi_lua container alongside it."
                        ]},
                        {li, [], [
                            ~"Port the Hathora calls (createLobby, getRoomInfo, ",
                            ~"loginAnonymous, listActivePublicLobbies) to the ",
                            ~"Asobi REST + WebSocket equivalents."
                        ]},
                        {li, [], [
                            ~"Once auth / matchmaking / lobbies run on Asobi, drop ",
                            ~"Hathora. Keep your game-server container on Hetzner, ",
                            ~"Fly, Scaleway — wherever."
                        ]},
                        {li, [], [
                            ~"Optional: fold your game-server logic into a ",
                            ~"match.lua script and let Asobi host that too. No ",
                            ~"game-server container at all."
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"The exit story — why this won't happen again"]},
                    {p, [], [
                        ~"Asobi is Apache-2.0 and self-hostable. If the managed ",
                        ~"Cloud service ever goes away, you run the same container ",
                        ~"on your own hardware and your game keeps working. No ",
                        ~"re-architecture, no emergency migration, no \"we're ",
                        ~"pivoting to AI\" email."
                    ]},
                    {p, [], [
                        ~"The ",
                        {a,
                            [
                                {href,
                                    ~"https://github.com/widgrensit/asobi/blob/main/guides/exit.md"}
                            ],
                            [~"exit guide"]},
                        ~" is a one-page runbook: how to move off Asobi Cloud to ",
                        ~"your own hardware, how to keep a self-hosted fork alive ",
                        ~"if the project stalls, what data lives where."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Next steps"]},
                    {p, [], [
                        ~"Easiest path: join ",
                        {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                        ~" and drop into #migrations. We'll walk through your ",
                        ~"specific Hathora setup rather than you fighting docs in ",
                        ~"the dark."
                    ]},
                    {p, [], [
                        ~"Prefer async? The ",
                        {a,
                            [
                                {href,
                                    ~"https://github.com/widgrensit/asobi/blob/main/guides/migrate-from-hathora.md"}
                            ],
                            [~"full migration guide"]},
                        ~" on GitHub has the endpoint-by-endpoint mapping."
                    ]},
                    {p, [], [
                        ~"Want the managed version from day one? ",
                        {a, [{href, ~"/cloud"}, az_navigate], [~"Asobi Cloud"]},
                        ~" opens for First-10 signups during Launch Week ",
                        ~"(June 16–20, 2026) — €9/mo Indie tier, EU-sovereign, ",
                        ~"same open-source core."
                    ]}
                ]}
            ]}
        ]}
    ).
