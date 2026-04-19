-module(asobi_site_godot_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"godot-guide"}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Godot SDK"]},
                    {p, [], [
                        ~"Integrate Asobi into your Godot 4.x project. Install as an editor addon."
                    ]},
                    {a,
                        [
                            {href, ~"https://github.com/widgrensit/asobi-godot"},
                            {class, ~"guide-github"}
                        ],
                        [
                            ~"View on GitHub"
                        ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Installation"]},
                    {p, [], [~"Copy the addon into your project:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"# Clone or download into your project\n",
                                ~"git clone https://github.com/widgrensit/asobi-godot.git\n",
                                ~"cp -r asobi-godot/addons/asobi your_project/addons/asobi"
                            ]}
                        ]}
                    ]},
                    {p, [], [
                        ~"Then enable the plugin: Project \x{2192} Project Settings \x{2192} Plugins \x{2192} Asobi."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Setup"]},
                    {p, [], [~"Add an AsobiClient node to your scene and configure it:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"# asobi_client is an autoload or node in your scene\n",
                                ~"@onready var asobi: AsobiClient = $AsobiClient\n\n",
                                ~"# Configure in the inspector or via code:\n",
                                ~"# host: \"localhost\"\n",
                                ~"# port: 8080\n",
                                ~"# use_ssl: false"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Authentication"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"# Register\n",
                                ~"var resp = await asobi.auth.register(\"player1\", \"secret123\", \"Player One\")\n\n",
                                ~"# Login\n",
                                ~"var resp = await asobi.auth.login(\"player1\", \"secret123\")\n\n",
                                ~"# Session token is stored automatically\n",
                                ~"print(\"Logged in as: \", asobi.player_id)"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Real-Time Connection"]},
                    {p, [], [~"Connect via WebSocket and listen for events using signals:"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"# Connect signals\n",
                                ~"asobi.realtime.connected.connect(_on_connected)\n",
                                ~"asobi.realtime.match_state.connect(_on_match_state)\n",
                                ~"asobi.realtime.matchmaker_matched.connect(_on_matched)\n\n",
                                ~"# Connect to server\n",
                                ~"asobi.realtime.connect_to_server()\n\n",
                                ~"func _on_connected():\n",
                                ~"    print(\"Connected!\")\n\n",
                                ~"func _on_match_state(payload: Dictionary):\n",
                                ~"    # Update game state from server\n",
                                ~"    pass\n\n",
                                ~"func _on_matched(payload: Dictionary):\n",
                                ~"    var match_id = payload[\"match_id\"]\n",
                                ~"    asobi.realtime.join_match(match_id)"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Matchmaking"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"# Queue via WebSocket (recommended)\n",
                                ~"asobi.realtime.add_to_matchmaker(\"arena\")\n\n",
                                ~"# Or via REST\n",
                                ~"var ticket = await asobi.matchmaker.add(\"arena\")\n",
                                ~"var status = await asobi.matchmaker.status(ticket[\"ticket_id\"])"
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
                                ~"# Send input (fire-and-forget)\n",
                                ~"asobi.realtime.send_match_input({\"action\": \"move\", \"x\": 1, \"y\": 0})\n\n",
                                ~"# Send shooting input\n",
                                ~"asobi.realtime.send_match_input({\n",
                                ~"    \"action\": \"fire\",\n",
                                ~"    \"aim_x\": mouse_pos.x,\n",
                                ~"    \"aim_y\": mouse_pos.y\n",
                                ~"})"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Leaderboards"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"# Submit a score\n",
                                ~"await asobi.leaderboards.submit_score(\"weekly\", 1500)\n\n",
                                ~"# Get top scores\n",
                                ~"var top = await asobi.leaderboards.get_top(\"weekly\", 10)\n\n",
                                ~"# Get scores around current player\n",
                                ~"var around = await asobi.leaderboards.get_around_self(\"weekly\")"
                            ]}
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Chat"]},
                    {'div', [{class, ~"guide-code"}], [
                        {pre, [], [
                            {code, [], [
                                ~"# Listen for messages\n",
                                ~"asobi.realtime.chat_message.connect(_on_chat)\n\n",
                                ~"# Join a channel and send a message\n",
                                ~"asobi.realtime.join_chat(\"lobby\")\n",
                                ~"asobi.realtime.send_chat_message(\"lobby\", \"Hello!\")\n\n",
                                ~"func _on_chat(payload: Dictionary):\n",
                                ~"    print(payload[\"content\"])"
                            ]}
                        ]}
                    ]}
                ]}
            ]}
        ]}
    ).
