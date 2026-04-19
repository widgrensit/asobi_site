-module(asobi_site_unity_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"unity-guide"}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Unity SDK"]},
                    {p, [], [
                        ~"Integrate Asobi into your Unity project. Supports Unity 2021.3 and later."
                    ]},
                    {a,
                        [
                            {href, ~"https://github.com/widgrensit/asobi-unity"},
                            {class, ~"guide-github"}
                        ],
                        [
                            ~"View on GitHub"
                        ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Installation"]},
                    {p, [], [~"Add the SDK via Unity Package Manager using the git URL:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [{code, [], [~"https://github.com/widgrensit/asobi-unity.git"]}]}
                    ]},
                    {p, [], [
                        ~"In Unity: Window \x{2192} Package Manager \x{2192} + \x{2192} Add package from git URL."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Setup"]},
                    {p, [], [~"Create a client and connect to your Asobi server:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"using Asobi;\n\n",
                                ~"var client = new AsobiClient(\"localhost\", 8080);\n\n",
                                ~"// Or with SSL\n",
                                ~"var client = new AsobiClient(\"api.mygame.com\", 443, useSsl: true);"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Authentication"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"// Register a new player\n",
                                ~"var auth = await client.Auth.RegisterAsync(\n",
                                ~"    \"player1\", \"secret123\", \"Player One\");\n\n",
                                ~"// Login\n",
                                ~"var auth = await client.Auth.LoginAsync(\"player1\", \"secret123\");\n\n",
                                ~"// Session is stored automatically\n",
                                ~"Debug.Log($\"Logged in as {client.PlayerId}\");"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Real-Time Connection"]},
                    {p, [], [~"Connect via WebSocket for matchmaking, match state, and chat:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"// Connect\n",
                                ~"client.Realtime.OnConnected += () => Debug.Log(\"Connected!\");\n",
                                ~"await client.Realtime.ConnectAsync();\n\n",
                                ~"// Listen for match state updates\n",
                                ~"client.Realtime.OnMatchState += (state) => {\n",
                                ~"    // Update game objects from server state\n",
                                ~"};\n\n",
                                ~"// Listen for matchmaker results\n",
                                ~"client.Realtime.OnMatchmakerMatched += (data) => {\n",
                                ~"    Debug.Log(\"Match found!\");\n",
                                ~"};"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Matchmaking"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"// Queue for a match via WebSocket\n",
                                ~"await client.Realtime.AddToMatchmakerAsync(\"arena\");\n\n",
                                ~"// Or via REST API\n",
                                ~"var ticket = await client.Matchmaker.AddAsync(\"arena\");\n",
                                ~"var status = await client.Matchmaker.StatusAsync(ticket.Id);"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Match Input"]},
                    {p, [], [~"Send player input to the server-authoritative game loop:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"// Join a match\n",
                                ~"await client.Realtime.JoinMatchAsync(matchId);\n\n",
                                ~"// Send input (fire-and-forget for low latency)\n",
                                ~"await client.Realtime.SendMatchInputAsync(\n",
                                ~"    \"{\\\"action\\\":\\\"move\\\",\\\"x\\\":1,\\\"y\\\":0}\");\n\n",
                                ~"// Leave match\n",
                                ~"await client.Realtime.LeaveMatchAsync();"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Leaderboards"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"// Submit a score\n",
                                ~"await client.Leaderboards.SubmitScoreAsync(\"weekly\", 1500);\n\n",
                                ~"// Get top scores\n",
                                ~"var top = await client.Leaderboards.GetTopAsync(\"weekly\", limit: 10);\n\n",
                                ~"// Get scores around current player\n",
                                ~"var around = await client.Leaderboards.GetAroundSelfAsync(\"weekly\");"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Economy"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"// Check wallet balance\n",
                                ~"var wallets = await client.Economy.GetWalletsAsync();\n\n",
                                ~"// Browse store\n",
                                ~"var store = await client.Economy.GetStoreAsync();\n\n",
                                ~"// Purchase item\n",
                                ~"await client.Economy.PurchaseAsync(listingId);"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Demo Project"]},
                    {p, [], [
                        ~"Check out the full multiplayer arena shooter demo built with this SDK:"
                    ]},
                    {a,
                        [
                            {href, ~"https://github.com/widgrensit/asobi-unity-demo"},
                            {class, ~"guide-github"}
                        ],
                        [
                            ~"Unity Demo Project"
                        ]}
                ]}
            ]}
        ]}
    ).
