-module(asobi_site_defold_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"defold-guide"}, Bindings), #{}}.

-spec render(map()) -> term().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}, {class, ~"guide-page"}], [
            {a, [{href, ~"/"}, {class, ~"guide-back"}], [~"\x{2190} Back to home"]},

            {'div', [{class, ~"guide-header"}], [
                {h1, [], [~"Defold SDK"]},
                {p, [], [
                    ~"Integrate Asobi into your Defold project. Pure Lua, no native extensions required."
                ]},
                {a,
                    [
                        {href, ~"https://github.com/widgrensit/asobi-defold"},
                        {class, ~"guide-github"}
                    ],
                    [
                        ~"View on GitHub"
                    ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Installation"]},
                {p, [], [~"Add as a library dependency in your game.project:"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"[project]\n",
                            ~"dependencies = https://github.com/widgrensit/asobi-defold/archive/main.zip"
                        ]}
                    ]}
                ]},
                {p, [], [~"Or: Project \x{2192} Fetch Libraries after adding the URL."]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Setup"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"local asobi = require(\"asobi.client\")\n\n",
                            ~"function init(self)\n",
                            ~"    self.client = asobi.create(\"localhost\", 8080)\n",
                            ~"end"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Authentication"]},
                {p, [], [~"All HTTP calls use callbacks with (data, error) signature:"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"-- Register\n",
                            ~"self.client.auth.register(self.client,\n",
                            ~"    \"player1\", \"secret123\", \"Player One\",\n",
                            ~"    function(data, err)\n",
                            ~"        if err then\n",
                            ~"            print(\"Error: \" .. err.error)\n",
                            ~"            return\n",
                            ~"        end\n",
                            ~"        print(\"Registered as: \" .. self.client.player_id)\n",
                            ~"    end)\n\n",
                            ~"-- Login\n",
                            ~"self.client.auth.login(self.client,\n",
                            ~"    \"player1\", \"secret123\",\n",
                            ~"    function(data, err)\n",
                            ~"        if not err then\n",
                            ~"            print(\"Logged in!\")\n",
                            ~"        end\n",
                            ~"    end)"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Real-Time Connection"]},
                {p, [], [~"Connect via WebSocket and subscribe to events:"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"-- Subscribe to events\n",
                            ~"self.client.realtime.on(\"connected\", function()\n",
                            ~"    print(\"Connected!\")\n",
                            ~"end)\n\n",
                            ~"self.client.realtime.on(\"match_state\", function(payload)\n",
                            ~"    -- Update game state\n",
                            ~"end)\n\n",
                            ~"self.client.realtime.on(\"matchmaker_matched\", function(payload)\n",
                            ~"    self.client.realtime.join_match(payload.match_id)\n",
                            ~"end)\n\n",
                            ~"-- Connect\n",
                            ~"self.client.realtime.connect()"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Matchmaking"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"-- Queue via WebSocket\n",
                            ~"self.client.realtime.add_to_matchmaker(\"arena\")\n\n",
                            ~"-- Or via REST\n",
                            ~"self.client.matchmaker.add(self.client, \"arena\",\n",
                            ~"    function(data, err)\n",
                            ~"        print(\"Ticket: \" .. data.ticket_id)\n",
                            ~"    end)"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Match Input"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"-- Send input (fire-and-forget)\n",
                            ~"self.client.realtime.send_match_input({\n",
                            ~"    action = \"move\",\n",
                            ~"    x = 1,\n",
                            ~"    y = 0\n",
                            ~"})\n\n",
                            ~"-- Leave match\n",
                            ~"self.client.realtime.leave_match()"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Leaderboards"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"-- Submit a score\n",
                            ~"self.client.leaderboards.submit_score(self.client,\n",
                            ~"    \"weekly\", 1500, 0,\n",
                            ~"    function(data, err)\n",
                            ~"        print(\"Score submitted!\")\n",
                            ~"    end)\n\n",
                            ~"-- Get top scores\n",
                            ~"self.client.leaderboards.get_top(self.client,\n",
                            ~"    \"weekly\", 10,\n",
                            ~"    function(data, err)\n",
                            ~"        for _, entry in ipairs(data.entries) do\n",
                            ~"            print(entry.player_id .. \": \" .. entry.score)\n",
                            ~"        end\n",
                            ~"    end)"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Chat"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"-- Listen for messages\n",
                            ~"self.client.realtime.on(\"chat_message\", function(payload)\n",
                            ~"    print(payload.content)\n",
                            ~"end)\n\n",
                            ~"-- Join channel and send message\n",
                            ~"self.client.realtime.join_chat(\"lobby\")\n",
                            ~"self.client.realtime.send_chat_message(\"lobby\", \"Hello!\")"
                        ]}
                    ]}
                ]}
            ]}
        ]}
    ).
