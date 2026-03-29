-module(asobi_site_dart_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"dart-guide"}, Bindings), #{}}.

-spec render(map()) -> term().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}, {class, ~"guide-page"}], [
            {a, [{href, ~"/"}, {class, ~"guide-back"}], [~"\x{2190} Back to home"]},

            {'div', [{class, ~"guide-header"}], [
                {h1, [], [~"Flutter / Dart SDK"]},
                {p, [], [
                    ~"Integrate Asobi into Flutter, Flame, or standalone Dart apps. ",
                    ~"Async/await API with stream-based real-time events."
                ]},
                {a, [{href, ~"https://github.com/widgrensit/asobi-dart"}, {class, ~"guide-github"}],
                    [
                        ~"View on GitHub"
                    ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Installation"]},
                {p, [], [~"Add to your pubspec.yaml:"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"dependencies:\n",
                            ~"  asobi:\n",
                            ~"    git:\n",
                            ~"      url: https://github.com/widgrensit/asobi-dart.git\n",
                            ~"      ref: main"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Setup"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"import 'package:asobi/asobi.dart';\n\n",
                            ~"final client = AsobiClient('localhost', port: 8080);\n\n",
                            ~"// With SSL\n",
                            ~"final client = AsobiClient('api.mygame.com', port: 443, useSsl: true);"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Authentication"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"// Register\n",
                            ~"await client.auth.register('player1', 'secret123',\n",
                            ~"    displayName: 'Player One');\n\n",
                            ~"// Login\n",
                            ~"await client.auth.login('player1', 'secret123');\n\n",
                            ~"// Session is stored automatically\n",
                            ~"print('Logged in as: ${client.playerId}');"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Real-Time Connection"]},
                {p, [], [~"Connect via WebSocket and listen using Dart streams:"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"// Connect\n",
                            ~"await client.realtime.connect();\n\n",
                            ~"// Listen for match state (broadcast stream)\n",
                            ~"client.realtime.onMatchState.stream.listen((state) {\n",
                            ~"  // Update game state from server\n",
                            ~"});\n\n",
                            ~"// Listen for matchmaker results\n",
                            ~"client.realtime.onMatchmakerMatched.stream.listen((data) {\n",
                            ~"  print('Match found: ${data[\"match_id\"]}');\n",
                            ~"});\n\n",
                            ~"// Chat messages\n",
                            ~"client.realtime.onChatMessage.stream.listen((msg) {\n",
                            ~"  print(msg['content']);\n",
                            ~"});"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Matchmaking"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"// Queue via WebSocket (recommended)\n",
                            ~"await client.realtime.addToMatchmaker(mode: 'arena');\n\n",
                            ~"// Or via REST\n",
                            ~"final ticket = await client.matchmaker.add('arena');\n",
                            ~"final status = await client.matchmaker.status(ticket.id);"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Match Input"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"// Join a match\n",
                            ~"await client.realtime.joinMatch(matchId);\n\n",
                            ~"// Send input (fire-and-forget for low latency)\n",
                            ~"client.realtime.sendMatchInput({'action': 'move', 'x': 1, 'y': 0});\n\n",
                            ~"// Leave match\n",
                            ~"await client.realtime.leaveMatch();"
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
                            ~"await client.leaderboards.submitScore('weekly', 1500);\n\n",
                            ~"// Get top scores\n",
                            ~"final top = await client.leaderboards.getTop('weekly', limit: 10);\n\n",
                            ~"// Get scores around current player\n",
                            ~"final around = await client.leaderboards.getAroundSelf('weekly');"
                        ]}
                    ]}
                ]}
            ]},

            {'div', [{class, ~"guide-section"}], [
                {h2, [], [~"Flame Engine"]},
                {p, [], [
                    ~"Flame is built on Flutter, so this SDK works out of the box. ",
                    ~"No separate Flame-specific package needed."
                ]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"import 'package:flame/game.dart';\n",
                            ~"import 'package:asobi/asobi.dart';\n\n",
                            ~"class MyGame extends FlameGame {\n",
                            ~"  late final AsobiClient client;\n\n",
                            ~"  @override\n",
                            ~"  Future<void> onLoad() async {\n",
                            ~"    client = AsobiClient('localhost', port: 8080);\n",
                            ~"    await client.auth.login('player1', 'secret123');\n",
                            ~"    await client.realtime.connect();\n\n",
                            ~"    client.realtime.onMatchState.stream.listen((state) {\n",
                            ~"      // Sync game components from server state\n",
                            ~"    });\n",
                            ~"  }\n\n",
                            ~"  @override\n",
                            ~"  void update(double dt) {\n",
                            ~"    super.update(dt);\n",
                            ~"    // Send player input each frame\n",
                            ~"    client.realtime.sendMatchInput({\n",
                            ~"      'action': 'move',\n",
                            ~"      'x': joystick.delta.x,\n",
                            ~"      'y': joystick.delta.y,\n",
                            ~"    });\n",
                            ~"  }\n",
                            ~"}"
                        ]}
                    ]}
                ]},
                {p, [], [~"Cleanup in your dispose method:"]},
                {'div', [{class, ~"guide-code"}], [
                    {pre, [], [
                        {code, [], [
                            ~"@override\n",
                            ~"void onRemove() {\n",
                            ~"  client.dispose();\n",
                            ~"  super.onRemove();\n",
                            ~"}"
                        ]}
                    ]}
                ]}
            ]}
        ]}
    ).
