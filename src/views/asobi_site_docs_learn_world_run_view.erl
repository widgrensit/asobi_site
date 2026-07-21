-module(asobi_site_docs_learn_world_run_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-world-run", title => ~"Run a world - Asobi docs"},
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
                ~" / Learn / Run a world"
            ]},
            {h1, [], [~"Run a world: ticks and deltas"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Move your fighter in one client and watch the change arrive on every other client, streamed as per-tick deltas from the server."
            ]},

            {p, [], [
                ~"In step 11 you joined a world and received the initial snapshot. Now you run the loop. It is the same server-authoritative rule as an arena round: the client sends intent, the server decides, the server broadcasts state. The only difference is the shape of the broadcast. A persistent arena does not resend the whole arena every tick. It sends ",
                {strong, [], [~"deltas"]},
                ~" - just what changed - and it sends them ",
                {strong, [], [~"per zone"]},
                ~", so a client only hears about the part of the arena it is standing in."
            ]},

            {h2, [], [~"The loop"]},
            {ol, [], [
                {li, [], [
                    ~"Client sends ",
                    {code, [], [~"world.input"]},
                    ~" - the intent (e.g. \"move right\")."
                ]},
                {li, [], [
                    ~"Server applies it to your entity, in whichever zone owns that entity."
                ]},
                {li, [], [
                    ~"Server ticks the world (default ",
                    {strong, [], [~"20 Hz"]},
                    ~", one tick every 50 ms)."
                ]},
                {li, [], [
                    ~"Each zone computes what changed and broadcasts a ",
                    {code, [], [~"world.tick"]},
                    ~" delta to its subscribers."
                ]},
                {li, [], [
                    ~"Clients apply the delta to what they already have on screen."
                ]}
            ]},
            {p, [], [
                ~"You never tell the server which zone you are in. ",
                {code, [], [~"world.input"]},
                ~" carries only your intent; the server routes it to the zone that currently owns your entity, and recomputes your zone membership as you move. See ",
                {a, [{href, ~"/docs/large-worlds"}, az_navigate], [~"large-worlds"]},
                ~" for how zones and the 3x3 interest neighbourhood work, and ",
                {a, [{href, ~"/docs/world-server"}, az_navigate], [~"world-server"]},
                ~" for the server ",
                {code, [], [~"world.lua"]},
                ~" callbacks that move the fighter."
            ]},

            {h2, [], [~"The delta shape"]},
            {p, [], [
                ~"Every ",
                {code, [], [~"world.tick"]},
                ~" after the first carries a ",
                {code, [], [~"tick"]},
                ~" number and an ",
                {code, [], [~"updates"]},
                ~" list. Each update has an ",
                {code, [], [~"op"]},
                ~" code:"
            ]},
            code(
                ~"json",
                ~"""
{
  "type": "world.tick",
  "payload": {
    "tick": 42,
    "updates": [
      { "id": "01j8x...07", "op": "a", "x": 120, "y": 80 },
      { "id": "01j8x...02", "op": "u", "x": 121 },
      { "id": "01j8x...05", "op": "r" }
    ]
  }
}
"""
            ),
            {ul, [], [
                {li, [], [
                    {code, [], [~"op: \"a\""]},
                    ~" - ",
                    {strong, [], [~"added"]},
                    ~". A full entity state; a fighter just entered your view."
                ]},
                {li, [], [
                    {code, [], [~"op: \"u\""]},
                    ~" - ",
                    {strong, [], [~"updated"]},
                    ~". Only the changed fields; here the fighter moved one cell right."
                ]},
                {li, [], [
                    {code, [], [~"op: \"r\""]},
                    ~" - ",
                    {strong, [], [~"removed"]},
                    ~". The id only; a fighter left your view or was deleted."
                ]}
            ]},
            {p, [], [
                ~"Apply each op against a local table keyed by entity id: insert on ",
                {code, [], [~"a"]},
                ~", patch on ",
                {code, [], [~"u"]},
                ~", delete on ",
                {code, [], [~"r"]},
                ~". The ",
                {strong, [], [~"first"]},
                ~" ",
                {code, [], [~"world.tick"]},
                ~" after ",
                {code, [], [~"world.joined"]},
                ~" is the full snapshot you handled in step 11, so the same handler covers both."
            ]},
            {p, [], [
                ~"Register the ",
                {code, [], [~"world.tick"]},
                ~" handler ",
                {strong, [], [~"before"]},
                ~" you join, or you will miss that first snapshot. This holds for every SDK below."
            ]},

            {h2, [], [~"The server side is unchanged"]},
            {p, [], [
                ~"The fighter is moved in ",
                {code, [], [~"world.lua"]},
                ~", which you wrote in Part 6. The client sends ",
                {code, [], [~"world.input"]},
                ~"; the server maps it to the player's entity and updates its position; the delta falls out of the zone diff automatically. You do not write the delta encoding. See ",
                {a, [{href, ~"/docs/world-server"}, az_navigate], [~"world-server"]},
                ~" for the input-to-entity handling and ",
                {a, [{href, ~"/docs/large-worlds"}, az_navigate], [~"large-worlds"]},
                ~" for zone routing. Nothing on the server changes between cloud and self-hosting."
            ]},

            {h2, [], [~"Base server URL - the only thing that differs per deployment"]},
            {p, [], [
                ~"Every SDK call in this step is identical on cloud and self-hosted. The single difference is the base URL your client already connected to in step 2:"
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Cloud:"]},
                    ~" the ",
                    {code, [], [~"wss://"]},
                    ~" URL of your deployed environment, shown by ",
                    {code, [], [~"asobi deploy"]},
                    ~" and in the console.asobi.dev environment view. Database and guest pepper were auto-provisioned; you configure nothing here."
                ]},
                {li, [], [
                    {strong, [], [~"Self-hosted:"]},
                    ~" your own host and port, ",
                    {code, [], [~"ws(s)://<your-host>:8084/ws"]},
                    ~" (default port 8084, single ",
                    {code, [], [~"/ws"]},
                    ~" endpoint), backed by your own Postgres."
                ]}
            ]},
            {p, [], [
                ~"Because you are already connected, the calls below are written ",
                {strong, [], [~"once"]},
                ~" and are byte-for-byte the same on both."
            ]},

            {h2, [], [~"Send input and render deltas - per SDK"]},
            {p, [], [
                ~"Three moves per tab: register the ",
                {code, [], [~"world.tick"]},
                ~" handler, join the world, then send ",
                {code, [], [~"world.input"]},
                ~" when the player acts. ",
                {code, [], [~"connect"]},
                ~" and ",
                {code, [], [~"join"]},
                ~" come from steps 3 and 11; they are repeated only for orientation."
            ]},
            {p, [], [
                {strong, [], [~"Unity: "]},
                {code, [], [~"OnWorldTick"]},
                ~" hands you the raw JSON envelope string; parse it yourself."
            ]},
            {p, [], [
                {strong, [], [~"Unreal: "]},
                {code, [], [~"OnWorldTick"]},
                ~" is a dynamic multicast delegate; the handler must be a ",
                {code, [], [~"UFUNCTION"]},
                ~" and receives the tick number plus the ",
                {code, [], [~"updates"]},
                ~" array as a raw JSON string."
            ]},
            {p, [], [
                {strong, [], [~"Dart: "]},
                {code, [], [~"onWorldTick"]},
                ~" is a broadcast stream of typed ",
                {code, [], [~"WorldTick"]},
                ~" values."
            ]},
            {p, [], [
                {strong, [], [~"JS: "]},
                ~"Raw transport: subscribe to the wire name, and the input payload IS the intent map (no ",
                {code, [], [~"data"]},
                ~" wrapper)."
            ]},
            {p, [], [
                {strong, [], [~"LÖVE: "]},
                ~"Mapped callback name, and the transport needs a manual per-frame pump or no callbacks fire."
            ]},
            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"learn-world-run",
                tabs => [
                    #{
                        label => ~"Defold",
                        lang => ~"lua",
                        body =>
                            ~"""
local rt = client.realtime

rt:on("world_tick", function(payload)
  for _, u in ipairs(payload.updates) do
    apply_delta(u.id, u.op, u)
  end
end)

rt:connect()
rt:join_world(world_id)

rt:send_world_input({ move_x = 1, move_y = 0 })
"""
                    },
                    #{
                        label => ~"Godot",
                        lang => ~"gdscript",
                        body =>
                            ~"""
func _on_world_tick(payload: Dictionary) -> void:
    for u in payload["updates"]:
        apply_delta(u["id"], u["op"], u)

Asobi.realtime.world_tick.connect(_on_world_tick)
Asobi.realtime.connect_to_server()
Asobi.realtime.world_join(world_id)

Asobi.realtime.world_input({ "move_x": 1, "move_y": 0 })
"""
                    },
                    #{
                        label => ~"Unity",
                        lang => ~"csharp",
                        body =>
                            ~"""
client.Realtime.OnWorldTick += rawJson => {
    // parse rawJson, then apply each update in payload.updates
};

await client.Realtime.ConnectAsync();
await client.Realtime.WorldJoinAsync(worldId);

await client.Realtime.WorldInputAsync("{\"move_x\":1,\"move_y\":0}");
"""
                    },
                    #{
                        label => ~"Unreal",
                        lang => ~"cpp",
                        body =>
                            ~"""
// UFUNCTION(); signature: (int64 Tick, const FString& UpdatesJson)
WebSocket->OnWorldTick.AddDynamic(this, &UMyClass::HandleWorldTick);

WebSocket->Connect(Url);        // then Authenticate(Token) in your OnConnected handler
WebSocket->WorldJoin(WorldId);

WebSocket->WorldInput(TEXT("{\"move_x\":1,\"move_y\":0}"));
"""
                    },
                    #{
                        label => ~"Dart",
                        lang => ~"dart",
                        body =>
                            ~"""
client.realtime.onWorldTick.stream.listen((WorldTick tick) {
  for (final u in tick.updates) {
    applyDelta(u);
  }
});

await client.realtime.connect(autoReconnect: false);
await client.realtime.joinWorld(worldId);

client.realtime.sendWorldInput({'move_x': 1, 'move_y': 0});
"""
                    },
                    #{
                        label => ~"JS",
                        lang => ~"typescript",
                        body =>
                            ~"""
const ws = asobi.websocket({ token });

ws.on("world.tick", (payload) => {
  for (const u of payload.updates) applyDelta(u.id, u.op, u);
});

await ws.connect();
await ws.send("world.join", { world_id });

ws.sendFire("world.input", { move_x: 1, move_y: 0 });
"""
                    },
                    #{
                        label => ~"LÖVE",
                        lang => ~"lua",
                        body =>
                            ~"""
client.realtime:on("world_tick", function(payload)
  for _, u in ipairs(payload.updates) do
    apply_delta(u.id, u.op, u)
  end
end)

client.realtime:connect()
client.realtime:join_world(world_id)

client.realtime:send_world_input({ move_x = 1, move_y = 0 })

function love.update(dt)
  client.realtime:update()   -- required every frame
end
"""
                    }
                ]
            }),

            checkpoint([
                {p, [], [
                    ~"Run two clients joined to the same world (step 11), each with its ",
                    {code, [], [~"world.tick"]},
                    ~" handler registered before joining."
                ]},
                {ol, [], [
                    {li, [], [
                        ~"In client A, send one ",
                        {code, [], [~"world.input"]},
                        ~" that moves your fighter."
                    ]},
                    {li, [], [
                        ~"In client B, watch a ",
                        {code, [], [~"world.tick"]},
                        ~" arrive with an ",
                        {code, [], [~"op: \"u\""]},
                        ~" update carrying the new position for A's entity id."
                    ]},
                    {li, [], [
                        ~"Move A across a zone boundary. B, if it is in the neighbouring zone, receives an ",
                        {code, [], [~"op: \"a\""]},
                        ~" (A entered its view) or ",
                        {code, [], [~"op: \"r\""]},
                        ~" (A left it) - proof the server is routing by zone, not broadcasting to everyone."
                    ]}
                ]},
                {p, [], [
                    ~"If the delta lands on the other client, the loop is closed: intent in, authoritative state out, streamed as deltas."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/world-end",
                ~"13. End a world",
                ~"world.finished, the empty-grace timer, and finishing from post_tick."
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
