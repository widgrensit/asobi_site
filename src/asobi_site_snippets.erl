%% @doc Single source of truth for per-SDK code snippets.
%%
%% This module prevents the doc drift that hit the SDK repos in
%% April 2026. All per-SDK code shown on the site comes from here,
%% so when the server protocol moves, we update ONE file, not 7+.
%%
%% == Coverage ==
%%
%% Every {Flow, SDK} pair in `flows/0' x `sdks/0' must have a clause
%% in `get/2'. `asobi_site_snippets_SUITE' enforces this and runs
%% protocol-keyword sanity checks. CI fails if coverage is incomplete
%% or a snippet is suspicious.
%%
%% == Adding a new flow ==
%%
%% 1. Add the flow name to `flows/0'.
%% 2. Add a clause in `get/2' for every SDK in `sdks/0'.
%% 3. Extend `asobi_site_snippets_SUITE:required_keywords/1' if the
%%    flow uses a new protocol message type.
%% 4. `rebar3 ct --suite=asobi_site_snippets_SUITE'.
%%
%% == Adding a new SDK ==
%%
%% 1. Add to `sdks/0' and `sdk_label/1'.
%% 2. Add a clause in `get/2' for every flow.
%% 3. Add the view + route.
-module(asobi_site_snippets).

-export([get/2, flows/0, sdks/0, sdk_label/1]).

-type flow() :: hero_connect | connect_world.
-type sdk() :: unreal | unity | godot | defold | js | dart | lua.

-export_type([flow/0, sdk/0]).

-spec flows() -> [flow()].
flows() -> [hero_connect, connect_world].

-spec sdks() -> [sdk()].
sdks() -> [unreal, unity, godot, defold, js, dart, lua].

-spec sdk_label(sdk()) -> binary().
sdk_label(unreal) -> ~"Unreal";
sdk_label(unity) -> ~"Unity";
sdk_label(godot) -> ~"Godot";
sdk_label(defold) -> ~"Defold";
sdk_label(js) -> ~"TypeScript";
sdk_label(dart) -> ~"Dart";
sdk_label(lua) -> ~"Lua".

%%====================================================================
%% Flow: hero_connect
%%
%% The canonical "connect to Asobi" flow shown on the homepage hero.
%% Each snippet shows: authenticate, open a WebSocket, queue for a
%% match, and log match.state updates. Roughly 15 lines each so the
%% tabs line up visually.
%%====================================================================

-spec get(flow(), sdk()) -> binary().
get(hero_connect, unreal) ->
    ~"""
    UAsobiClient* Client = NewObject<UAsobiClient>();
    Client->SetBaseUrl(TEXT("http://localhost:8080"));

    UAsobiAuth* Auth = NewObject<UAsobiAuth>();
    Auth->Init(Client);

    FOnAsobiAuthResponse OnLogin;
    OnLogin.BindDynamic(this, &AMyPawn::OnLoggedIn);
    Auth->Login(TEXT("player1"), TEXT("secret"), OnLogin);

    // After login:
    WebSocket->Connect(TEXT("ws://localhost:8080/ws"));
    WebSocket->Authenticate(Client->GetAuthToken());
    Matchmaker->Add(TEXT("arena"), {}, OnQueued);
    WebSocket->OnMatchState.AddDynamic(this, &AMyPawn::OnMatchState);
    """;
get(hero_connect, unity) ->
    ~"""
    var asobi = new AsobiClient("localhost", port: 8080);
    await asobi.Auth.LoginAsync("player1", "secret");

    asobi.Realtime.OnMatchState += state =>
        Debug.Log($"tick {state.tick}");

    await asobi.Realtime.ConnectAsync();
    await asobi.Matchmaker.AddAsync("arena");
    // When matched, server sends match.joined → match.state at tick rate.
    """;
get(hero_connect, godot) ->
    ~"""
    @onready var asobi: AsobiClient = $AsobiClient

    func _ready():
        await asobi.auth.login("player1", "secret")
        asobi.realtime.match_state.connect(_on_state)
        asobi.realtime.connect_to_server()
        asobi.realtime.add_to_matchmaker("arena")

    func _on_state(payload: Dictionary):
        print("tick ", payload.get("tick"))
    """;
get(hero_connect, defold) ->
    ~"""
    local asobi = require("asobi.client")
    local rt = require("asobi.realtime")

    asobi.auth.login("player1", "secret", function(res)
        rt.init(asobi)
        rt.on("match_state", function(payload)
            print("tick " .. payload.tick)
        end)
        rt.connect(function()
            rt.matchmaker_add("arena")
        end)
    end)
    """;
get(hero_connect, js) ->
    ~"""
    import { Asobi } from "@asobi/client";

    const asobi = new Asobi({ baseUrl: "http://localhost:8080" });
    const { access_token } = await asobi.auth.login({
        username: "player1", password: "secret",
    });
    asobi.client.setToken(access_token);

    const ws = asobi.websocket();
    ws.on("match.state", (s) => console.log("tick", s.tick));
    await ws.connect();
    await asobi.matchmaker.add({ mode: "arena" });
    """;
get(hero_connect, dart) ->
    ~"""
    final asobi = AsobiClient(host: 'localhost', port: 8080);
    await asobi.auth.login('player1', 'secret');

    asobi.realtime.onMatchState.listen((state) {
        print('tick ${state.tick}');
    });

    await asobi.realtime.connect();
    await asobi.matchmaker.add(mode: 'arena');
    """;
get(hero_connect, lua) ->
    ~"""
    -- Server-side game mode (runs inside asobi_lua)
    function on_player_joined(match, player)
        game.broadcast(match, "welcome", { player_id = player.id })
    end

    function on_match_input(match, player, input)
        player.x = player.x + (input.move_x or 0)
        player.y = player.y + (input.move_y or 0)
        -- match.state is diffed and broadcast automatically each tick.
    end
    """;

%%====================================================================
%% Flow: connect_world
%%
%% MMO-scale world: find-or-create, receive world.tick and
%% world.terrain chunks. Separate from hero_connect because Worlds
%% are the less-common but differentiating feature.
%%====================================================================

get(connect_world, unreal) ->
    ~"""
    WebSocket->OnWorldJoined.AddDynamic(this, &AMyPawn::OnWorldJoined);
    WebSocket->OnWorldTick.AddDynamic(this, &AMyPawn::OnWorldTick);
    WebSocket->OnWorldTerrain.AddDynamic(this, &AMyPawn::OnTerrain);

    // Find-or-create keeps players in the same world until it fills.
    WebSocket->WorldFindOrCreate(TEXT("open-world"));

    void AMyPawn::OnWorldTick(int64 Tick, const FString& UpdatesJson) {
        // Decode UpdatesJson into entity deltas and apply.
    }
    """;
get(connect_world, unity) ->
    ~"""
    asobi.Realtime.OnWorldJoined += info =>
        Debug.Log($"world {info.world_id} ({info.player_count}/{info.max_players})");
    asobi.Realtime.OnWorldTick += t => ApplyDeltas(t.updates);
    asobi.Realtime.OnWorldTerrain += chunk =>
        LoadChunk(chunk.CoordX, chunk.CoordY, chunk.data);

    await asobi.Realtime.ConnectAsync();
    await asobi.Worlds.FindOrCreateAsync("open-world");
    """;
get(connect_world, godot) ->
    ~"""
    asobi.realtime.world_joined.connect(_on_world_joined)
    asobi.realtime.world_tick.connect(_on_world_tick)
    asobi.realtime.world_terrain.connect(_on_terrain)

    asobi.realtime.connect_to_server()
    asobi.realtime.find_or_create_world("open-world")

    func _on_terrain(coords: Vector2i, data: String):
        var bytes := Marshalls.base64_to_raw(data)
        world.load_chunk(coords, bytes)
    """;
get(connect_world, defold) ->
    ~"""
    rt.on("world_joined", function(info) print("joined " .. info.world_id) end)
    rt.on("world_tick",   function(t) apply_deltas(t.updates) end)
    rt.on("world_terrain",function(chunk)
        load_chunk(chunk.coords[1], chunk.coords[2], chunk.data)
    end)

    rt.connect(function()
        rt.world_find_or_create("open-world")
    end)
    """;
get(connect_world, js) ->
    ~"""
    ws.on("world.joined", ({ world_id, player_count }) =>
        console.log(`joined ${world_id} (${player_count})`));
    ws.on("world.tick", ({ tick, updates }) => applyDeltas(updates));
    ws.on("world.terrain", ({ coords, data }) =>
        loadChunk(coords[0], coords[1], data));

    await ws.connect();
    ws.sendFire("world.find_or_create", { mode: "open-world" });
    """;
get(connect_world, dart) ->
    ~"""
    asobi.realtime.onWorldJoined.listen((info) =>
        print('joined ${info['world_id']}'));
    asobi.realtime.onWorldTick.listen((t) => applyDeltas(t.updates));
    asobi.realtime.onWorldTerrain.listen((chunk) =>
        loadChunk(chunk.coordX, chunk.coordY, chunk.base64Data));

    await asobi.realtime.connect();
    asobi.realtime.findOrCreateWorld('open-world');
    """;
get(connect_world, lua) ->
    ~"""
    -- Server-side world game mode
    function on_world_started(world)
        game.log("world started: " .. world.id)
    end

    function on_player_joined(world, player)
        -- Zone is picked automatically based on spawn position.
        game.broadcast_zone(world, player.zone, "welcome",
                            { player_id = player.id })
    end
    """.
