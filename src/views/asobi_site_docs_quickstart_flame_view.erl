-module(asobi_site_docs_quickstart_flame_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-flame", title => ~"Flame quickstart — Asobi docs"},
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
                ~" / Quick start - Flame"
            ]},
            {h1, [], [~"Quick start - Flame"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Wire an Asobi backend into a Flame game. Flame games use ",
                {code, [], [~"flame_asobi"]},
                ~" - a thin binding that re-exports the ",
                {a, [{href, ~"/docs/quickstart/dart"}, az_navigate], [~"Dart SDK"]},
                ~" plus Flame glue for input and state sync. No server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first."
            ]},

            {h2, [], [~"1. Add the binding"]},
            {p, [], [
                ~"Add ",
                {code, [], [~"flame_asobi"]},
                ~" - it pulls in the ",
                {code, [], [~"asobi"]},
                ~" Dart package transitively, so it's the only asobi dependency you declare."
            ]},
            code(
                ~"yaml",
                ~"""
dependencies:
  flame: ^1.22.0
  flame_asobi:
    git:
      url: https://github.com/widgrensit/flame_asobi.git
      ref: main
"""
            ),

            {h2, [], [~"2. Hold one shared client"]},
            {p, [], [
                ~"Auth and the WebSocket session live on a single ",
                {code, [], [~"AsobiClient"]},
                ~" reused across every screen and the game. Authenticate (guest) and queue for a match ",
                ~"from your lobby, before entering the Flame game - see the ",
                {a, [{href, ~"/docs/quickstart/dart"}, az_navigate], [~"Dart quickstart"]},
                ~" for the underlying ",
                {code, [], [~"connect"]},
                ~" / ",
                {code, [], [~"addToMatchmaker"]},
                ~" flow."
            ]},
            code(
                ~"dart",
                ~"""
class GameConfig {
  static final client = AsobiClient('localhost', port: 8084);
  static const gameMode = 'default';
}

// in your lobby, before starting the game:
await GameConfig.client.auth.guest(deviceId, deviceSecret);
await GameConfig.client.realtime.connect();
GameConfig.client.realtime.addToMatchmaker(mode: GameConfig.gameMode);
"""
            ),

            {h2, [], [~"3. Drive the game from asobi state"]},
            {p, [], [
                {code, [], [~"flame_asobi"]},
                ~" gives you two pieces. ",
                {strong, [], [~"Input out:"]},
                ~" the ",
                {code, [], [~"HasAsobiInput"]},
                ~" mixin on your ",
                {code, [], [~"FlameGame"]},
                ~" turns Flame input into ",
                {code, [], [~"match.input"]},
                ~" each frame. ",
                {strong, [], [~"State in:"]},
                ~" the ",
                {code, [], [~"AsobiNetworkSync"]},
                ~" component (added to ",
                {code, [], [~"world"]},
                ~") bridges the match-state stream into the game loop and spawns/updates your components."
            ]},
            code(
                ~"dart",
                ~"""
class ArenaGame extends FlameGame with HasAsobiInput {
  @override AsobiClient get inputClient => GameConfig.client;
  @override Map<String, dynamic>? buildMatchInput({...}) => {'move_x': dx, 'move_y': dy};

  @override
  Future<void> onLoad() async {
    world.add(AsobiNetworkSync(
      client: GameConfig.client,
      playerBuilder: (id, {required isLocal}) => ShipComponent(id, isLocal: isLocal),
      onStateUpdate: (state) => _hud.timeLeft = state.timeRemaining,
    ));
  }
}
"""
            ),
            {p, [], [
                ~"Read snapshots through ",
                {code, [], [~"onStateUpdate"]},
                ~" and the sync's ",
                {code, [], [~"localPlayer"]},
                ~"; don't also subscribe to ",
                {code, [], [~"onMatchState"]},
                ~" yourself, or you double-process state."
            ]},

            {h2, [], [~"Gotchas"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"One client, shared statically. "]},
                    ~"Auth, the WS session, and ",
                    {code, [], [~"playerId"]},
                    ~" all live on that instance - reach it via ",
                    {code, [], [~"inputClient => GameConfig.client"]},
                    ~", never a new client per screen."
                ]},
                {li, [], [
                    {strong, [], [~"Let the sync component own the stream. "]},
                    ~"Lobby/UI code listens to raw ",
                    {code, [], [~".stream"]},
                    ~"s; inside Flame, ",
                    {code, [], [~"AsobiNetworkSync"]},
                    ~" subscribes and mutates on the Flame thread for you."
                ]},
                {li, [], [
                    {strong, [], [~"Cancel subscriptions. "]},
                    ~"Cancel every ",
                    {code, [], [~"StreamSubscription"]},
                    ~" in ",
                    {code, [], [~"dispose()"]},
                    ~" / ",
                    {code, [], [~"onRemove()"]},
                    ~" across the lobby -> game -> results navigation."
                ]}
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi-flame-demo"}], [
                        ~"asobi-flame-demo"
                    ]},
                    ~" - a full Flame arena game."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/quickstart/dart"}, az_navigate], [~"Dart quickstart"]},
                    ~" - the underlying client API."
                ]},
                {li, [], [{a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication"]}]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
